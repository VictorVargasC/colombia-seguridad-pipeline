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
   - **Hipótesis (pendiente de verificar con el catálogo DIVIPOLA del DANE):** los códigos adicionales corresponden a áreas no municipalizadas, que la Policía registra bajo el nombre de la capital.
7. **7 registros sin municipio** (código `52000`, de departamento completo). Se conservarán para los totales por departamento, pero no se pueden ubicar en un municipio.
8. **Nombres de departamento inconsistentes:** `BOGOTA` sin tilde frente a `ATLÁNTICO`, `BOYACÁ`, etc., y nombres abreviados como `VALLE`, `GUAJIRA` y `SAN ANDRÉS`. Se normalizarán con el catálogo DIVIPOLA.
9. **Filas idénticas: no son duplicados.** Hay 413.113 filas exactamente iguales a otra, pero como cada fila es un caso (`CANTIDAD` = 1), dos casos con la misma fecha, lugar, arma y víctima son sucesos distintos.
   - **Decisión:** **no se eliminan**. Borrarlas reduciría el total de delitos en más de la mitad.

## 6. Códigos ICCS

Los 18 delitos tienen un código ICCS único, y el código coincide con el que aparece entre paréntesis en `DELITOS`. Los códigos tienen longitudes distintas por diseño (`0101` Homicidio intencional, `02011` Lesiones personales, `020222` Secuestro), y es correcto. Al guardarlos como texto se conservan tal cual.

## 7. Impacto en las preguntas del dashboard

| Pregunta | ¿Se puede responder? |
|---|---|
| 1. Evolución por año y mes; tasa por 100.000 habitantes | **Sí** para el mes de 2025. Para evolución anual y tasas faltan otros años y la población del DANE. |
| 2. Días de la semana y **horas** | **Parcial.** Hay fecha, por lo que se puede ver el día de la semana, pero **no hay columna de hora**. |
| 3. Modalidades o armas por delito | **Sí**, con `ARMAS MEDIOS` y `DELITOS`. |
| 4. Municipios que empeoraron o mejoraron | **Todavía no.** Requiere el archivo de 2024, cuyo formato puede ser distinto. |

## 8. Próximos pasos

- Día 2: decidir el tratamiento definitivo de los problemas anteriores.
- Descargar el catálogo DIVIPOLA y las proyecciones de población del DANE.
- Revisar el archivo de 2024 y comparar su formato.
