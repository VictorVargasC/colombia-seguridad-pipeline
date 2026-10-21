# Hallazgos del día 1: exploración del archivo de delitos 2025

**Archivo:** `data/raw/delitos_2025.xlsx` (Policía Nacional, "Información de delitos a nivel de registro", entregado el 20 de agosto de 2026).
**Notebook:** `notebooks/01_exploracion.ipynb`

## 1. Tamaño y estructura

| Dato | Valor |
|---|---|
| Hojas | 1 (`Hoja1`) |
| Registros reales | **773.950** |
| Columnas | 11 |
| Fila del encabezado | Fila 12 del Excel (`header=11` en pandas) |
| Filas de notas al final | 11 (se eliminan) |

El archivo es un reporte pensado para leerse, no para procesarse: tiene un título y filas vacías arriba, y notas de fuente al final. Al leerlo con `pd.read_excel(..., header=11)` y quitar las filas sin `DEPARTAMENTO`, quedan solo los registros.

**Grano de la tabla:** cada fila es **un caso registrado**. La columna `CANTIDAD` vale 1 en las 773.950 filas, por lo que la suma de `CANTIDAD` es igual al número de filas.

## 2. Diccionario de columnas

| Columna | Significado | Tipo en pandas |
|---|---|---|
| `ARMAS MEDIOS` | Arma o medio empleado (45 categorías) | texto |
| `DEPARTAMENTO` | Departamento donde ocurrió el hecho (33 valores) | texto |
| `MUNICIPIO` | Municipio del hecho | texto |
| `FECHA HECHO` | Fecha del hecho, formato `AAAA/MM/DD` | texto (convertir a fecha) |
| `GENERO` | Género de la víctima | texto |
| `*AGRUPA EDAD PERSONA*` | Grupo de edad de la víctima (3 grupos) | texto |
| `CODIGO DANE` | Código DIVIPOLA del municipio (5 dígitos) | **texto** |
| `DELITOS` | Delito, con su código ICCS entre paréntesis (18 valores) | texto |
| `MES` | Mes del hecho (`01` a `12`) | **texto** |
| `CANTIDAD` | Número de casos de la fila (siempre 1) | número |
| `ICCS` | Código de la clasificación internacional del delito (DANE 2022) | **texto** |

Las columnas de código (`CODIGO DANE`, `MES`, `ICCS`) se leen como **texto** porque son identificadores, no cantidades: no se suman ni se promedian, se usan para unir tablas. Como número perderían los ceros iniciales (`05001` pasaría a `5001`).

## 3. Valores nulos

| Columna | Nulos | Comentario |
|---|---|---|
| `GENERO` | 30.296 | 3,9 % de los registros |
| `*AGRUPA EDAD PERSONA*` | 4.160 | 0,5 % de los registros |
| `MUNICIPIO` | 7 | Todos con `CODIGO DANE` = `52000` (Nariño) |
| Las demás 8 columnas | 0 | |

## 4. Rango de fechas

Del **2025-01-01** al **2025-12-31**. Ninguna fecha inválida, y la columna `MES` coincide con el mes de `FECHA HECHO` en el 100 % de los registros.

## 5. Problemas de calidad y decisiones

1. **Encabezado desplazado y notas al final.** Se resuelve al leer con `header=11` y eliminar las filas sin `DEPARTAMENTO`.
2. **Códigos que pierden ceros.** Se resuelve leyendo `MES`, `CODIGO DANE` e `ICCS` con `dtype=str`. Importante: al leer el CSV intermedio también hay que pasar `dtype`.
3. **Género y edad de baja calidad.** La propia Policía advierte en las notas del archivo que estas variables "no cuentan con la calidad en cuanto a completitud" y están en proceso de revisión. Recomienda usar los "cuadros de salida" para cifras validadas.
   - **Decisión:** la dimensión de víctima (sexo y grupo de edad) se tratará como secundaria. Los vacíos se etiquetarán como `NO REPORTADO`, sin descartar los registros. Los cuadros de salida son una fuente a evaluar más adelante.
4. **`NO REPORTADO` en `ARMAS MEDIOS`:** 15.727 registros (2,0 %). Es una categoría válida que se conserva y se muestra tal cual.
5. **Nombres de municipio repetidos (homónimos).** Hay 1.020 nombres distintos pero 1.110 códigos DANE. Ejemplo: `La Unión` existe en Antioquia (05400), Nariño (52399), Sucre (70400) y Valle (76400).
   - **Comprobado:** cada código DANE pertenece a un solo nombre y a un solo departamento (0 excepciones).
   - **Decisión:** el municipio se identifica **siempre por `CODIGO DANE`**, nunca por nombre.
6. **Un mismo municipio con varios códigos.** Aun combinando departamento y municipio, hay dos casos con más de un código: `Leticia` (Amazonas) con 7 códigos e `Inírida` (Guainía) con 2.
   - **Confirmado con el catálogo DIVIPOLA** (`data/raw/divipola.csv`, datos.gov.co): los códigos adicionales de Leticia son **áreas no municipalizadas** de Amazonas (El Encanto, La Chorrera, La Pedrera, Miriti-Paraná, Puerto Santander y Tarapacá, 23 registros en total) que la Policía registra bajo el nombre de la capital.
   - En Guainía, el código `94663` (1 registro) **no existe en el catálogo DIVIPOLA**. Según el archivo de población del DANE corresponde a **Mapiripana**, pero la Policía lo registró con el nombre **Inírida**, cuyo código real es `94001`. Es probable un error de captura, pero no se puede confirmar. Se conserva con el nombre de la Policía y `tipo_unidad = 'Sin clasificar'`.
   - **Decisión:** el nombre del municipio se tomará del catálogo oficial, según el `codigo_dane`.
7. **7 registros sin municipio** (código `52000`, de departamento completo). Se conservarán para los totales por departamento, pero no se pueden ubicar en un municipio.
8. **Nombres de departamento y municipio inconsistentes con el catálogo oficial.**
   - Departamentos: `BOGOTA` (oficial `BOGOTÁ, D.C.`), `VALLE` (`VALLE DEL CAUCA`), `GUAJIRA` (`LA GUAJIRA`) y `SAN ANDRÉS` (`ARCHIPIÉLAGO DE SAN ANDRÉS, PROVIDENCIA Y SANTA CATALINA`).
   - Municipios: 60 códigos tienen un nombre distinto al oficial, casi siempre por tildes o ñ faltantes (`Itagui` / `ITAGÜÍ`, `Sonson` / `SONSÓN`) o por abreviaturas (`Cartagena` / `CARTAGENA DE INDIAS`, `Mompós` / `SANTA CRUZ DE MOMPOX`).
   - **Decisión:** se usarán los nombres oficiales del DIVIPOLA, unidos por `codigo_dane`.
9. **Filas idénticas: no son duplicados.** Hay 413.113 filas exactamente iguales a otra, pero como cada fila es un caso (`CANTIDAD` = 1), dos casos con la misma fecha, lugar, arma y víctima son sucesos distintos.
   - **Decisión:** **no se eliminan**. Borrarlas reduciría el total de delitos en más de la mitad.

## 6. Códigos ICCS

Los 18 delitos tienen un código ICCS único, y el código coincide con el que aparece entre paréntesis en `DELITOS`. Los códigos tienen longitudes distintas por diseño (`0101` Homicidio intencional, `02011` Lesiones personales, `020222` Secuestro), y es correcto. Al guardarlos como texto se conservan tal cual.

## 7. Impacto en las preguntas del dashboard

| Pregunta | ¿Se puede responder? |
|---|---|
| 1. Evolución por año y mes; tasa por 100.000 habitantes | **Sí** para 2025, por mes y con tasa (la población del DANE ya está en el modelo). La evolución anual necesita otros años. |
| 2. Días de la semana y **horas** | **Parcial.** Hay fecha, por lo que se puede ver el día de la semana, pero **no hay columna de hora**. |
| 3. Modalidades o armas por delito | **Sí**, con `ARMAS MEDIOS` y `DELITOS`. |
| 4. Municipios que empeoraron o mejoraron | **Todavía no.** Requiere el archivo de 2024, cuyo formato puede ser distinto. |

## 8. Población del DANE

Fuente: proyecciones de población municipal 2018-2042, por área (`data/raw/poblacion_dane_2018_2042.xlsx`, publicada el 8 de agosto de 2025).

1. **Estructura del archivo.** Tiene 3 hojas (portada, notas y datos). En la hoja de datos el encabezado está en el índice 7 y hay notas al final.
2. **Tres filas por municipio y año** (cabecera, centros poblados y rural disperso, y total). La fila `Total` ya incluye las otras dos.
   - **Decisión:** usar solo `Total`. Sumar las tres contaría la población dos veces (el total de Colombia en 2025 saldría por encima de 106 millones, en vez de 53.057.212).
3. **Cobertura:** 1.123 territorios × 25 años = 28.075 filas, sin duplicados. De los 1.110 códigos de los delitos, solo `52000` (7 registros) no tiene población.
4. **Territorios con 0 habitantes:** `94663` (Mapiripana) desde 2020, porque desde diciembre de 2019 el DANE lo cuenta dentro del nuevo municipio de Barrancominas (`94343`); y `27493` (Nuevo Belén de Bajirá) entre 2018 y 2023, antes de su creación.
   - **Decisión:** los ceros se conservan, porque son información real del DANE. Al calcular la tasa se usa `NULLIF(habitantes, 0)` para evitar la división entre cero.
5. **14 territorios con población y sin ningún delito registrado en 2025:** 2 municipios (Nuevo Belén de Bajirá y Barrancominas) y 12 áreas no municipalizadas.
   - **Decisión:** la dimensión de ubicación se construye desde el catálogo DIVIPOLA completo y no desde los delitos. Así esos territorios aparecen en el dashboard con tasa 0 en vez de desaparecer.

## 9. Próximos pasos

- Calcular la tasa por 100.000 habitantes y conectar Power BI al modelo.
- Revisar el archivo de 2024 y comparar su formato, para la pregunta de municipios que mejoraron o empeoraron.
- Evaluar los "cuadros de salida" de la Policía como fuente validada de género y edad.
