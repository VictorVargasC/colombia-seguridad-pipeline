"""Descarga el catálogo DIVIPOLA (códigos oficiales de municipios) de datos.gov.co.

Fuente: conjunto "DIVIPOLA - Códigos municipios" del DANE, vía la API de datos.gov.co.
Guarda el original sin modificar en data/raw/divipola.csv.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/descarga_divipola.py
"""

from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
RUTA_SALIDA = RAIZ / "data" / "raw" / "divipola.csv"

# La API devuelve solo 1.000 filas por defecto y el catálogo tiene 1.122:
# $limit=2000 evita perder registros sin que nadie lo note.
URL = "https://www.datos.gov.co/resource/gdxc-w37w.csv?$limit=2000"


def main():
    # dtype=str: todo como texto, para conservar los ceros iniciales de los códigos (05001).
    df = pd.read_csv(URL, dtype=str)
    # utf-8-sig: el archivo abre bien en Excel, con sus tildes y ñ.
    df.to_csv(RUTA_SALIDA, index=False, encoding="utf-8-sig")
    print(f"Guardado: {RUTA_SALIDA} ({len(df):,} filas)")


if __name__ == "__main__":
    main()
