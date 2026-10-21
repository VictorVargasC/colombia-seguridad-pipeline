# Proyecto: Pipeline de datos de seguridad en Colombia

> Este archivo le da a Claude Code el contexto del proyecto y el punto exacto donde quedamos.
> Ubícalo en la raíz del repositorio (`colombia-seguridad-pipeline/`).

## Quién soy y qué busco
- Estoy estudiando para conseguir mi primer trabajo como **ingeniero de datos** (segundo plano: analista de datos). No tengo experiencia laboral en el área.
- Quiero armar un portafolio de proyectos completos, de punta a punta, que terminen en un **dashboard de Power BI**, porque la parte visual llama la atención de los reclutadores.
- Quiero que el primer proyecto trate un tema **relevante para Colombia**.
- También estoy practicando cómo funciona Claude Code.

## Cómo quiero que me ayudes
- Escríbeme en **español**.
- Guíame **paso a paso**, un paso a la vez. Para cada paso dime: **qué hacer, cómo hacerlo y qué herramienta usar**.
- Explica brevemente qué hace cada comando o cambio que propongas, porque estoy aprendiendo.
- Pídeme confirmación antes de borrar archivos, mover carpetas o instalar cosas fuera del entorno virtual.
- Soy principiante: prefiere soluciones simples y claras antes que sofisticadas.

## Herramientas y entorno
- Sistema: **Windows**, terminal **PowerShell**.
- Uso: **VS Code**, **SSMS (SQL Server)**, **Power BI**, Python.
- Ya ejecuté `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` para poder activar el entorno virtual.
- Ruta del proyecto: **`C:\proyectos\colombia-seguridad-pipeline`** (fuera de OneDrive, porque `.venv` y los datos tienen muchos archivos y OneDrive los sincroniza). La copia vieja en `OneDrive\Documentos` ya no se usa.
- `requirements.txt` se genera en ASCII: `pip freeze | Out-File -Encoding ascii requirements.txt` (con `>` PowerShell 5.1 lo guarda en UTF-16).
- Entorno virtual: `.venv` en la raíz del repo. Activar con `.venv\Scripts\Activate.ps1`.
- Paquetes principales: `pandas`, `openpyxl`, `jupyter`, `ipykernel`, `requests`, `pyodbc`, `SQLAlchemy`. Dependencias completas en `requirements.txt`.
- SQL Server 2022 Express en `.\SQLEXPRESS` con Autenticación de Windows (sin contraseñas en el código). Base de datos: `ColombiaSeguridad`.
- Los archivos `.sql` se crean y editan en **VS Code** (UTF-8), no en SSMS: SSMS los guarda en una codificación antigua y dañaba las tildes.

## El proyecto
**Objetivo:** pipeline completo de datos de delitos en Colombia.

**Flujo:** archivo de la Policía Nacional (registro de delitos) → Python (pandas) → tabla de staging en SQL Server → modelo estrella → dashboard en Power BI.

**Preguntas que debe responder el dashboard:**
1. ¿Cómo evolucionan los delitos por año y mes, y cuál es la tasa por cada 100.000 habitantes por departamento y municipio?
2. ¿Qué días de la semana y qué horas concentran más casos?
3. ¿Qué modalidades o armas predominan en cada tipo de delito?
4. ¿Qué municipios empeoraron o mejoraron frente al año anterior?

**Por qué este tema:** hay bastante cobertura reciente. Por ejemplo, el Ministerio de Defensa reportó 3.391 homicidios en el primer trimestre de 2026, la cifra más alta desde 2015 (dato publicado por El Colombiano en abril de 2026).

## Fuentes de datos
- **Policía Nacional, estadística delictiva:** https://www.policia.gov.co/estadistica-delictiva
  - Sección "Información de delitos a nivel de registro" (un archivo Excel por año, 2020-2026). Empezar con **2025** (los datos pasan a definitivos en marzo del año siguiente).
  - También hay "cuadros de salida" mensuales con totales por delito, departamento y municipio.
  - El formato cambió en 2025 (nuevo modelo estadístico y clasificación ICCS del DANE). **No asumir nombres de columnas: verificarlos en el archivo.**
- **DANE:** proyecciones de población por municipio (para calcular tasas por 100.000) y códigos DIVIPOLA (para unir municipios sin depender de nombres).
- **datos.gov.co**, categoría "Seguridad y Defensa": conjuntos complementarios con API (por ejemplo "Reporte Hurto por Modalidades Policía Nacional").

## Modelo estrella (implementado en `sql/03_crear_modelo_estrella.sql`)
```
fact_delitos (grano: fecha × ubicación × delito × modalidad × víctima)
  fecha_key, ubicacion_key, delito_key, modalidad_key, victima_key, cantidad
  -> 360.837 filas; 'cantidad' suma los casos repetidos (773.950 casos en 2025)

dim_fecha      calendario completo de 2025 (365 días), día de la semana, fin de semana
dim_ubicacion  codigo_dane, municipio, departamento, tipo_unidad (1.124 filas, nace del catálogo DIVIPOLA)
dim_delito     iccs, delito (18)
dim_modalidad  arma_medio (45)
dim_victima    genero, grupo_edad (10; baja calidad según la Policía)

fact_poblacion (grano: ubicación × año): habitantes   -> para la tasa por 100.000
```
Ajustes frente al diseño inicial: el archivo no trae hora ni zona urbana/rural, así que la pregunta 2 solo se responde por día de la semana. Detalles y decisiones en `docs/hallazgos_dia1.md`.

## Estructura del repositorio
```
data/raw/        datos originales sin tocar (NO se suben a GitHub)
data/interim/    copias intermedias (NO se suben a GitHub)
notebooks/       exploración (01_exploracion, 02_exploracion_poblacion)
src/             scripts de Python del pipeline
sql/             scripts SQL numerados, se ejecutan en orden
docs/            documentación y hallazgos
```
`.gitignore` incluye `data/` y `.venv/`.

## Cómo reconstruir todo desde cero
1. Descargar los datos: poner `delitos_2025.xlsx` en `data/raw/` (descarga manual de la Policía), y ejecutar `python src/descarga_divipola.py` y `python src/descarga_poblacion.py`.
2. Limpiar: `python src/limpieza.py` y `python src/limpieza_poblacion.py`.
3. En SSMS, ejecutar `sql/01_crear_base_de_datos.sql`, `02_crear_staging.sql` y `03_crear_modelo_estrella.sql`.
4. Cargar el staging: `python src/carga_staging.py` y `python src/carga_staging_referencia.py` (alternativa para delitos: `sql/04_cargar_staging_bulk.sql`).
5. En SSMS, ejecutar `sql/05_cargar_dimensiones.sql`, `06_cargar_hechos.sql` y `07_cargar_poblacion.sql`. Cada uno muestra una verificación al final.
`python src/probar_conexion.py` comprueba la conexión a SQL Server.

## Progreso (plan de la semana 1)
- [x] **Paso 1:** verificar Git, Python y extensiones de VS Code (Python y Jupyter).
- [x] **Paso 2:** crear el repositorio `colombia-seguridad-pipeline` en GitHub y clonarlo.
- [x] **Paso 3:** crear la estructura de carpetas y ajustar `.gitignore`.
- [x] **Paso 4:** crear el entorno virtual `.venv`, instalar paquetes y generar `requirements.txt`.
- [x] **Paso 5:** descargar el archivo de delitos a nivel de registro **2025** y guardarlo como `data/raw/delitos_2025.xlsx` (sin tildes ni espacios).
- [x] **Paso 6:** crear `notebooks/01_exploracion.ipynb` y explorar el archivo: hojas, forma (`shape`), tipos (`dtypes`), primeras filas, nulos y valores distintos de las columnas categóricas. Si el encabezado no está en la primera fila, usar `header=N`. Guardar una copia en `data/interim/delitos_2025.csv`.
- [x] **Paso 7:** escribir `docs/hallazgos_dia1.md`: filas y columnas, significado de cada columna, nulos, nombres inconsistentes de municipios o delitos, y rango de fechas.
- [x] **Paso 8:** `git add .`, `git commit` y `git push`.

**Estamos en:** final del **Día 5**. El modelo estrella está diseñado, cargado y verificado. Falta calcular la tasa por 100.000 y conectar Power BI.

## Plan de los siguientes días
- [x] **Día 2:** documentar problemas de calidad de datos y decidir cómo tratarlos (script `src/limpieza.py`, catálogo DIVIPOLA).
- [x] **Día 3:** base de datos `ColombiaSeguridad`, tablas de staging y del modelo estrella.
- [x] **Día 4:** scripts de Python que cargan los datos a staging con `SQLAlchemy` y `pyodbc` (y alternativa con `BULK INSERT`).
- [x] **Día 5:** dimensiones, hechos y población del DANE cargados; scripts SQL consolidados y probados reconstruyendo todo desde cero.
- [ ] **Siguiente:** vista o consulta de la tasa por 100.000 habitantes, conexión de Power BI al modelo y primer dashboard.
- [ ] **Fin de semana:** diagrama de arquitectura y README con el problema y las preguntas (el README aún está vacío).
- [ ] **Más adelante:** agregar el archivo de 2024 (y otros años) para la pregunta 4 (comparación con el año anterior).

## Cuidados que debemos tener presentes
- Los delitos **registrados** no son los delitos **ocurridos**: muchos no se denuncian. Debe mencionarse en el dashboard y el README.
- El archivo a nivel de registro puede traer sexo y edad de víctimas. Publicar **solo información agregada**.
- No subir a GitHub los datos ni el entorno virtual.

## Proyectos siguientes (contexto)
1. **Este proyecto:** ETL básico con datos de seguridad → SQL Server → Power BI.
2. **Proyecto 2:** pipeline automatizado (Airflow en Docker, PostgreSQL, capas bronze/silver/gold) con una fuente que se actualice sola, por ejemplo precios de alimentos (SIPSA/IPC del DANE) o la TRM.
3. **Proyecto 3:** versión en la nube (Azure) con dbt.
