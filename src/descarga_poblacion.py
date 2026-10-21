"""Descarga las proyecciones de población municipal del DANE (2018-2042).

Fuente: DANE, "Serie municipal de población por área, para el periodo 2018-2042"
(publicada el 8 de agosto de 2025). Guarda el Excel original, sin modificar, en
data/raw/poblacion_dane_2018_2042.xlsx.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/descarga_poblacion.py
"""

from pathlib import Path

import requests

RAIZ = Path(__file__).resolve().parent.parent
RUTA_SALIDA = RAIZ / "data" / "raw" / "poblacion_dane_2018_2042.xlsx"

URL = (
    "https://www.dane.gov.co/files/censo2018/proyecciones-de-poblacion/"
    "Municipal/PPED-AreaMun-2018-2042_VP.xlsx"
)


def main():
    # User-Agent: algunos sitios del gobierno rechazan peticiones que no parecen venir de un navegador.
    # timeout: si no hay respuesta en 60 segundos, falla en vez de quedarse esperando.
    respuesta = requests.get(URL, headers={"User-Agent": "Mozilla/5.0"}, timeout=60)
    # Si el servidor responde con error (403, 404...), lanza una excepción en vez de guardar
    # una página de error como si fuera el Excel.
    respuesta.raise_for_status()
    RUTA_SALIDA.write_bytes(respuesta.content)
    print(f"Guardado: {RUTA_SALIDA} ({len(respuesta.content) / 1_000_000:.1f} MB)")


if __name__ == "__main__":
    main()
