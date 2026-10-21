"""Limpia las proyecciones de población del DANE y las deja listas para cargar.

El archivo del DANE trae, para cada municipio y año, tres filas: cabecera, resto
(centros poblados y rural disperso) y total. Aquí se deja solo el total, porque
sumar las tres contaría la población dos veces.

Entrada:  data/raw/poblacion_dane_2018_2042.xlsx
Salida:   data/interim/poblacion_limpia.csv (codigo_dane, anio, habitantes)

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/limpieza_poblacion.py
"""

from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
RUTA_ENTRADA = RAIZ / "data" / "raw" / "poblacion_dane_2018_2042.xlsx"
RUTA_SALIDA = RAIZ / "data" / "interim" / "poblacion_limpia.csv"

# El Excel tiene 3 hojas (portada, notas y datos); los datos están en esta.
HOJA = "PobMunicipalxÁrea"

# Los códigos se leen como texto para conservar los ceros iniciales
COLUMNAS_TEXTO = {"DP": str, "MPIO": str}

NOMBRES_NUEVOS = {"MPIO": "codigo_dane", "AÑO": "anio", "TOTAL": "habitantes"}


def leer_crudo(ruta):
    """Lee la hoja de datos del DANE: el encabezado real está en el índice 7."""
    return pd.read_excel(ruta, sheet_name=HOJA, header=7, dtype=COLUMNAS_TEXTO)


def quitar_notas(df):
    """Elimina la fila vacía del inicio y las notas del final: no tienen código de municipio."""
    return df.dropna(subset=["MPIO"])


def solo_totales(df):
    """Deja solo las filas 'Total': las otras dos áreas ya están sumadas en ellas."""
    return df[df["ÁREA GEOGRÁFICA"] == "Total"]


def estandarizar(df):
    """Se queda con las columnas necesarias, las renombra y convierte los números a enteros."""
    df = df[["MPIO", "AÑO", "TOTAL"]].rename(columns=NOMBRES_NUEVOS)
    # Los números venían como decimal por los vacíos de las notas; ya sin ellas pueden ser enteros.
    return df.astype({"anio": int, "habitantes": int})


def validar(df):
    """Comprueba que no haya códigos de longitud rara ni filas repetidas."""
    if not (df["codigo_dane"].str.len() == 5).all():
        raise ValueError("Hay códigos DANE que no tienen 5 dígitos")
    if df.duplicated(["codigo_dane", "anio"]).any():
        raise ValueError("Hay municipios repetidos en un mismo año")


def main():
    df = leer_crudo(RUTA_ENTRADA)
    df = quitar_notas(df)
    df = solo_totales(df)
    df = estandarizar(df)
    validar(df)
    # Nota: algunos territorios tienen 0 habitantes en ciertos años (Mapiripana desde 2020,
    # que el DANE cuenta dentro de Barrancominas). Se conservan: es información real.
    df.to_csv(RUTA_SALIDA, index=False)
    print(f"Guardado: {RUTA_SALIDA} ({len(df):,} filas)")
    print(f"Población de Colombia en 2025: {df[df['anio'] == 2025]['habitantes'].sum():,}")


if __name__ == "__main__":
    main()
