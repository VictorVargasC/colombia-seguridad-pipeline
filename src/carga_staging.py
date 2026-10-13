
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

RAIZ = Path(__file__).resolve().parent.parent
RUTA_CSV = RAIZ / "data" / "interim" / "delitos_2025_limpio.csv"

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

    engine = create_engine(URL, fast_executemany=True)
    cargadas = cargar_staging(df, engine)
    print(f"Cargadas en stg.delitos: {cargadas:,} filas")

    if cargadas != len(df):
        raise ValueError(f"Se esperaban {len(df):,} filas y hay {cargadas:,}")
    print("Carga verificada: el número de filas coincide.")


if __name__ == "__main__":
    main()