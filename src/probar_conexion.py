"""Prueba la conexión de Python con SQL Server.

Úsalo antes de cargar datos: si la conexión falla, es mejor enterarse con esta
prueba corta que después de esperar una carga larga.

Uso (desde la raíz del proyecto, con el .venv activo):
    python src/probar_conexion.py
"""

from sqlalchemy import create_engine, text

# Conexión con Autenticación de Windows: no hay usuario ni contraseña en el código.
# Las dos barras \\ son una sola barra invertida escrita dentro de un texto de Python.
# TrustServerCertificate=yes es necesario en un servidor local de desarrollo, cuyo
# certificado de seguridad Windows no reconoce.
URL = (
    "mssql+pyodbc://@localhost\\SQLEXPRESS/ColombiaSeguridad"
    "?driver=ODBC+Driver+17+for+SQL+Server"
    "&trusted_connection=yes"
    "&TrustServerCertificate=yes"
)

engine = create_engine(URL)

# 'with' cierra la conexión al terminar, incluso si hay un error.
with engine.connect() as conexion:
    base = conexion.execute(text("SELECT DB_NAME()")).scalar()
    filas = conexion.execute(text("SELECT COUNT(*) FROM stg.delitos")).scalar()
    print(f"Conectado a: {base} | filas en stg.delitos: {filas}")
