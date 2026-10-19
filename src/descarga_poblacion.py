
from pathlib import Path

import requests

RAIZ = Path(__file__).resolve().parent.parent
RUTA_SALIDA = RAIZ / "data" / "raw" / "poblacion_dane_2018_2042.xlsx"

URL = (
    "https://www.dane.gov.co/files/censo2018/proyecciones-de-poblacion/"
    "Municipal/PPED-AreaMun-2018-2042_VP.xlsx"
)


def main():
    respuesta = requests.get(URL, headers={"User-Agent": "Mozilla/5.0"}, timeout=60)
    respuesta.raise_for_status()
    RUTA_SALIDA.write_bytes(respuesta.content)
    print(f"Guardado: {RUTA_SALIDA} ({len(respuesta.content) / 1_000_000:.1f} MB)")


if __name__ == "__main__":
    main()