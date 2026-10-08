from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
RUTA_ENTRADA = RAIZ / "data" / "raw" / "delitos_2025.xlsx"
RUTA_SALIDA = RAIZ / "data" / "interim" / "delitos_2025_limpio.csv"

# Columnas que son códigos: se leen como texto para no perder los ceros iniciales
COLUMNAS_TEXTO = {"MES": str, "CODIGO DANE": str, "ICCS": str}

NOMBRES_NUEVOS = {
    "ARMAS MEDIOS": "arma_medio",
    "DEPARTAMENTO": "departamento",
    "MUNICIPIO": "municipio",
    "FECHA HECHO": "fecha_hecho",
    "GENERO": "genero",
    "*AGRUPA EDAD PERSONA*": "grupo_edad",
    "CODIGO DANE": "codigo_dane",
    "DELITOS": "delito",
    "MES": "mes",
    "CANTIDAD": "cantidad",
    "ICCS": "iccs",
}


def leer_crudo(ruta):
    """Lee el Excel de la Policía: el encabezado real está en la fila 12 (índice 11)."""
    return pd.read_excel(ruta, header=11, dtype=COLUMNAS_TEXTO)


def quitar_notas(df):
    """Elimina las filas de notas del final: no tienen departamento."""
    return df.dropna(subset=["DEPARTAMENTO"])


def estandarizar(df):
    """Convierte la fecha a tipo fecha y renombra las columnas a snake_case."""
    df = df.copy()
    df["FECHA HECHO"] = pd.to_datetime(df["FECHA HECHO"])
    df["CANTIDAD"] = df["CANTIDAD"].astype(int)
    return df.rename(columns=NOMBRES_NUEVOS)


def rellenar_no_reportado(df):
    """Etiqueta como NO REPORTADO los vacíos de género y edad (baja calidad según la Policía)."""
    df = df.copy()
    for columna in ["genero", "grupo_edad"]:
        df[columna] = df[columna].fillna("NO REPORTADO")
    return df


def main():
    df = leer_crudo(RUTA_ENTRADA)
    df = quitar_notas(df)
    df = estandarizar(df)
    df = rellenar_no_reportado(df)
    df.to_csv(RUTA_SALIDA, index=False, encoding="utf-8-sig")
    print(f"Guardado: {RUTA_SALIDA} ({len(df):,} filas)")


if __name__ == "__main__":
    main()