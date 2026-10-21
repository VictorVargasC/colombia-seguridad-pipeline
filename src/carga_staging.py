"""Carga el CSV limpio de delitos en la tabla de staging stg.delitos (SQL Server).

Es idempotente: vacía la tabla antes de cargar, así que se puede ejecutar varias
veces sin duplicar filas. Todo ocurre en una sola transacción: si algo falla a
mitad de la carga, SQL Server deshace todo y la tabla queda como estaba.

Requisitos: haber ejecutado src/limpieza.py y sql/02_crear_staging.sql.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/carga_staging.py
"""

from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

RAIZ = Path(__file__).resolve().parent.parent
RUTA_CSV = RAIZ / "data" / "interim" / "delitos_2025_limpio.csv"

# Conexión con Autenticación de Windows: no hay usuario ni contraseña en el código.
# Otros scripts de src/ importan esta URL para no repetirla.
URL = (
    "mssql+pyodbc://@localhost\\SQLEXPRESS/ColombiaSeguridad"
    "?driver=ODBC+Driver+17+for+SQL+Server"
    "&trusted_connection=yes"
    "&TrustServerCertificate=yes"
)

# Los códigos se leen como texto para conservar los ceros iniciales
COLUMNAS_TEXTO = {"mes": str, "codigo_dane": str, "iccs": str}


def leer_csv(ruta):
    """Lee el CSV limpio con los tipos correctos."""
    return pd.read_csv(ruta, dtype=COLUMNAS_TEXTO, parse_dates=["fecha_hecho"])


def cargar_staging(df, engine):
    """Vacía stg.delitos y la llena con el DataFrame, todo en una sola transacción."""
    with engine.begin() as conexion:
        conexion.execute(text("TRUNCATE TABLE stg.delitos"))
        # if_exists="append" agrega filas a la tabla que ya existe (creada con tipos precisos
        # en sql/02_crear_staging.sql). Con "replace", pandas la recrearía con sus propios tipos.
        # chunksize: envía las filas en bloques de 10.000 en vez de todas de una vez.
        df.to_sql(
            "delitos",
            conexion,
            schema="stg",
            if_exists="append",
            index=False,
            chunksize=10_000,
        )
        cargadas = conexion.execute(text("SELECT COUNT(*) FROM stg.delitos")).scalar()
    return cargadas


def main():
    df = leer_csv(RUTA_CSV)
    print(f"Leídas del CSV: {len(df):,} filas")

    # fast_executemany: envía cada bloque como un lote; acelera mucho la carga en SQL Server.
    engine = create_engine(URL, fast_executemany=True)
    cargadas = cargar_staging(df, engine)
    print(f"Cargadas en stg.delitos: {cargadas:,} filas")

    # Validación: un pipeline debe comprobar sus propios resultados.
    if cargadas != len(df):
        raise ValueError(f"Se esperaban {len(df):,} filas y hay {cargadas:,}")
    print("Carga verificada: el número de filas coincide.")


if __name__ == "__main__":
    main()
