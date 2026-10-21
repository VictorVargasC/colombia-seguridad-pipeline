"""Carga en SQL Server las tablas de referencia: stg.divipola y stg.poblacion.

  * stg.divipola : catálogo oficial de territorios (data/raw/divipola.csv)
  * stg.poblacion: proyecciones de población (data/interim/poblacion_limpia.csv)

Igual que carga_staging.py, es idempotente (vacía cada tabla antes de cargar) y
comprueba que el número de filas cargadas coincida con el del archivo.

Requisitos: sql/02_crear_staging.sql ejecutado, y haber corrido
src/descarga_divipola.py, src/descarga_poblacion.py y src/limpieza_poblacion.py.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/carga_staging_referencia.py
"""

from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

# Se reutiliza la URL de conexión del otro script. Funciona porque, al ejecutar
# 'python src/archivo.py', Python agrega la carpeta src a su ruta de búsqueda.
from carga_staging import URL

RAIZ = Path(__file__).resolve().parent.parent
RUTA_DIVIPOLA = RAIZ / "data" / "raw" / "divipola.csv"
RUTA_POBLACION = RAIZ / "data" / "interim" / "poblacion_limpia.csv"

# Columnas de stg.divipola; el CSV trae además longitud y latitud, que no se usan.
COLUMNAS_DIVIPOLA = ["cod_dpto", "dpto", "cod_mpio", "nom_mpio", "tipo_municipio"]


def leer_divipola(ruta):
    """Lee el catálogo DIVIPOLA como texto (conserva los ceros) y se queda con las columnas de staging."""
    return pd.read_csv(ruta, dtype=str)[COLUMNAS_DIVIPOLA]


def leer_poblacion(ruta):
    """Lee la población limpia; el código DANE va como texto."""
    return pd.read_csv(ruta, dtype={"codigo_dane": str})


def cargar_tabla(df, nombre, engine):
    """Vacía stg.<nombre>, la llena con el DataFrame y comprueba el número de filas."""
    # Una sola transacción: si algo falla, la tabla queda como estaba.
    with engine.begin() as conexion:
        conexion.execute(text(f"TRUNCATE TABLE stg.{nombre}"))
        df.to_sql(nombre, conexion, schema="stg", if_exists="append", index=False)
        cargadas = conexion.execute(text(f"SELECT COUNT(*) FROM stg.{nombre}")).scalar()
    if cargadas != len(df):
        raise ValueError(f"stg.{nombre}: se esperaban {len(df):,} filas y hay {cargadas:,}")
    return cargadas


def main():
    engine = create_engine(URL, fast_executemany=True)

    divipola = leer_divipola(RUTA_DIVIPOLA)
    print(f"stg.divipola: {cargar_tabla(divipola, 'divipola', engine):,} filas")

    poblacion = leer_poblacion(RUTA_POBLACION)
    print(f"stg.poblacion: {cargar_tabla(poblacion, 'poblacion', engine):,} filas")


if __name__ == "__main__":
    main()
