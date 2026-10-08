from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
RUTA_SALIDA = RAIZ / "data" / "raw" / "divipola.csv"

URL = "https://www.datos.gov.co/resource/gdxc-w37w.csv?$limit=2000"


def main():
    df = pd.read_csv(URL, dtype=str)
    df.to_csv(RUTA_SALIDA, index=False, encoding="utf-8-sig")
    print(f"Guardado: {RUTA_SALIDA} ({len(df):,} filas)")


if __name__ == "__main__":
    main()