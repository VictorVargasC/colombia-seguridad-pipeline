
from sqlalchemy import create_engine, text

URL = (
    "mssql+pyodbc://@localhost\\SQLEXPRESS/ColombiaSeguridad"
    "?driver=ODBC+Driver+17+for+SQL+Server"
    "&trusted_connection=yes"
    "&TrustServerCertificate=yes"
)

engine = create_engine(URL)

with engine.connect() as conexion:
    base = conexion.execute(text("SELECT DB_NAME()")).scalar()
    filas = conexion.execute(text("SELECT COUNT(*) FROM stg.delitos")).scalar()
    print(f"Conectado a: {base} | filas en stg.delitos: {filas}")