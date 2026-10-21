-- =====================================================================
-- 08_crear_vistas_tasa.sql
--
-- Vistas con la tasa de delitos por cada 100.000 habitantes.
--   dw.vw_tasa_municipio_anual     : una fila por territorio y año
--   dw.vw_tasa_departamento_anual  : una fila por departamento y año
--
-- Una vista es una consulta guardada con nombre: no almacena datos, los
-- calcula cada vez que se consulta, así que siempre refleja las tablas.
--
-- Requisitos: dimensiones, hechos de delitos y hechos de población cargados.
-- Se puede repetir (CREATE OR ALTER reemplaza la vista si ya existe).
-- =====================================================================

USE ColombiaSeguridad;
GO

-- Tasa por territorio. Parte de dim_ubicacion para que aparezcan TODOS los
-- territorios, incluso los que no tienen delitos registrados (casos = 0).
-- Solo incluye los años que existen en dim_fecha (los años con delitos cargados).
CREATE OR ALTER VIEW dw.vw_tasa_municipio_anual AS
SELECT
    u.ubicacion_key,
    u.codigo_dane,
    u.municipio,
    u.departamento,
    u.tipo_unidad,
    a.anio,
    ISNULL(h.casos, 0) AS casos,
    p.habitantes,
    -- NULLIF convierte un 0 en NULL: dividir entre NULL da NULL y no un error.
    -- Pasa con territorios sin población (por ejemplo, Mapiripana desde 2020).
    CAST(ISNULL(h.casos, 0) * 100000.0 / NULLIF(p.habitantes, 0) AS DECIMAL(10, 1)) AS tasa_100k
FROM dw.dim_ubicacion AS u
CROSS JOIN (SELECT DISTINCT anio FROM dw.dim_fecha) AS a
LEFT JOIN (
    SELECT f.ubicacion_key, d.anio, SUM(f.cantidad) AS casos
    FROM dw.fact_delitos AS f
    JOIN dw.dim_fecha AS d ON d.fecha_key = f.fecha_key
    GROUP BY f.ubicacion_key, d.anio
) AS h ON h.ubicacion_key = u.ubicacion_key AND h.anio = a.anio
LEFT JOIN dw.fact_poblacion AS p ON p.ubicacion_key = u.ubicacion_key AND p.anio = a.anio;
GO

-- Tasa por departamento. Se calcula sumando casos y habitantes y dividiendo DESPUÉS:
-- la tasa de un departamento NO es el promedio de las tasas de sus municipios.
CREATE OR ALTER VIEW dw.vw_tasa_departamento_anual AS
SELECT
    departamento,
    anio,
    SUM(casos)      AS casos,
    SUM(habitantes) AS habitantes,
    CAST(SUM(casos) * 100000.0 / NULLIF(SUM(habitantes), 0) AS DECIMAL(10, 1)) AS tasa_100k
FROM dw.vw_tasa_municipio_anual
GROUP BY departamento, anio;
GO