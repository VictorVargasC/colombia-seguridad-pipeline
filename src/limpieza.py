"""Limpia el archivo de delitos de la Policía Nacional (2025) y lo deja listo para cargar.

Pasos, en este orden (el orden importa):
  1. Leer el Excel: el encabezado real está en la fila 12, no en la primera.
  2. Quitar las filas de notas del final del archivo.
  3. Convertir la fecha, pasar la cantidad a entero y renombrar las columnas.
  4. Etiquetar como NO REPORTADO los vacíos de género y edad.
  5. Agregar los nombres oficiales del DANE, uniendo por código DIVIPOLA.

Entrada:  data/raw/delitos_2025.xlsx y data/raw/divipola.csv
Salida:   data/interim/delitos_2025_limpio.csv

Los hallazgos que justifican cada paso están en docs/hallazgos_dia1.md.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/limpieza.py
"""

from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
RUTA_ENTRADA = RAIZ / "data" / "raw" / "delitos_2025.xlsx"
RUTA_SALIDA = RAIZ / "data" / "interim" / "delitos_2025_limpio.csv"
RUTA_DIVIPOLA = RAIZ / "data" / "raw" / "divipola.csv"

# Columnas que son códigos: se leen como texto para no perder los ceros iniciales
COLUMNAS_TEXTO = {"MES": str, "CODIGO DANE": str, "ICCS": str}

# Nombres originales de la Policía -> nombres en snake_case (sin espacios, tildes ni asteriscos)
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
    df = df.copy()  # evita modificar el DataFrame original sin querer
    df["FECHA HECHO"] = pd.to_datetime(df["FECHA HECHO"])
    # CANTIDAD venía como decimal por los vacíos de las filas de notas; ya sin ellas puede ser entero.
    # Por eso esta función va después de quitar_notas.
    df["CANTIDAD"] = df["CANTIDAD"].astype(int)
    return df.rename(columns=NOMBRES_NUEVOS)


def rellenar_no_reportado(df):
    """Etiqueta como NO REPORTADO los vacíos de género y edad (baja calidad según la Policía)."""
    df = df.copy()
    for columna in ["genero", "grupo_edad"]:
        df[columna] = df[columna].fillna("NO REPORTADO")
    return df


def agregar_divipola(df, ruta=RUTA_DIVIPOLA):
    """Agrega los nombres oficiales y el tipo de unidad del DANE, uniendo por código DIVIPOLA."""
    divipola = pd.read_csv(ruta, dtype=str)
    divipola = divipola[["cod_mpio", "nom_mpio", "dpto", "tipo_municipio"]]
    # Se renombran para que no choquen con las columnas 'municipio' y 'departamento' de la Policía.
    divipola = divipola.rename(
        columns={
            "nom_mpio": "municipio_oficial",
            "dpto": "departamento_oficial",
            "tipo_municipio": "tipo_unidad",
        }
    )
    # how="left" conserva todos los delitos; los 8 sin código en el catálogo quedan con vacíos.
    df = df.merge(divipola, how="left", left_on="codigo_dane", right_on="cod_mpio")
    return df.drop(columns=["cod_mpio"])  # duplicado de codigo_dane


def main():
    df = leer_crudo(RUTA_ENTRADA)
    df = quitar_notas(df)
    df = estandarizar(df)
    df = rellenar_no_reportado(df)
    df = agregar_divipola(df)
    # utf-8-sig: el CSV abre bien en Excel, con sus tildes y ñ.
    df.to_csv(RUTA_SALIDA, index=False, encoding="utf-8-sig")
    print(f"Guardado: {RUTA_SALIDA} ({len(df):,} filas)")


if __name__ == "__main__":
    main()
