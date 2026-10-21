-- =====================================================================
-- 05_cargar_dimensiones.sql
--
-- Llena las cinco dimensiones del modelo estrella.
--
-- Requisitos: stg.delitos, stg.divipola y stg.poblacion ya cargadas.
-- Se puede repetir: vacía el modelo antes de cargar. Después hay que volver
-- a ejecutar 06_cargar_hechos.sql y 07_cargar_poblacion.sql, porque los
-- hechos se borran aquí.
-- =====================================================================

USE ColombiaSeguridad;
GO

-- Vaciar el modelo para poder repetir la carga. Primero los hechos (que apuntan
-- a las dimensiones) y luego las dimensiones. No se usa TRUNCATE porque SQL Server
-- no lo permite en tablas a las que apuntan llaves foráneas.
DELETE FROM dw.fact_poblacion;
DELETE FROM dw.fact_delitos;
DELETE FROM dw.dim_fecha;
DELETE FROM dw.dim_ubicacion;
DELETE FROM dw.dim_delito;
DELETE FROM dw.dim_modalidad;
DELETE FROM dw.dim_victima;

-- Reiniciar los contadores IDENTITY para que las llaves vuelvan a empezar en 1.
DBCC CHECKIDENT ('dw.dim_ubicacion', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dw.dim_delito',    RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dw.dim_modalidad', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dw.dim_victima',   RESEED, 0) WITH NO_INFOMSGS;
GO

-- dim_fecha: un calendario completo de 2025 (incluye días sin delitos registrados).
-- La consulta recursiva parte del 1 de enero y suma un día cada vez.
-- Para agregar otros años, cambia las dos fechas.
WITH calendario AS (
    SELECT CAST('2025-01-01' AS DATE) AS fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, fecha) FROM calendario WHERE fecha < '2025-12-31'
)
INSERT INTO dw.dim_fecha
    (fecha_key, fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia_semana, es_fin_de_semana)
SELECT
    YEAR(fecha) * 10000 + MONTH(fecha) * 100 + DAY(fecha),   -- 2025-01-01 -> 20250101
    fecha,
    YEAR(fecha),
    DATEPART(QUARTER, fecha),
    MONTH(fecha),
    -- CHOOSE en vez de DATENAME: DATENAME depende del idioma de la sesión de SQL Server.
    CHOOSE(MONTH(fecha), N'enero', N'febrero', N'marzo', N'abril', N'mayo', N'junio',
                         N'julio', N'agosto', N'septiembre', N'octubre', N'noviembre', N'diciembre'),
    DAY(fecha),
    d.dia_semana,
    CHOOSE(d.dia_semana, N'lunes', N'martes', N'miércoles', N'jueves', N'viernes', N'sábado', N'domingo'),
    CASE WHEN d.dia_semana >= 6 THEN 1 ELSE 0 END
FROM calendario
-- Día de la semana con lunes = 1, sin importar el valor de @@DATEFIRST (depende del idioma).
CROSS APPLY (SELECT (DATEPART(WEEKDAY, fecha) + @@DATEFIRST - 2) % 7 + 1 AS dia_semana) AS d
OPTION (MAXRECURSION 400);   -- el límite por defecto es 100 repeticiones y necesitamos 365
GO

-- dim_ubicacion: una fila por cada territorio del catálogo oficial DIVIPOLA (aunque no
-- tenga delitos registrados, para que aparezca con tasa 0 y no desaparezca del dashboard),
-- más los códigos que aparecen en los delitos y no están en el catálogo
-- (52000 y 94663), con el nombre que trae la Policía.
INSERT INTO dw.dim_ubicacion (codigo_dane, municipio, departamento, tipo_unidad)
SELECT cod_mpio, nom_mpio, dpto, tipo_municipio
FROM stg.divipola
UNION ALL
SELECT
    d.codigo_dane,
    COALESCE(MAX(d.municipio_oficial), MAX(d.municipio)),         -- MAX ignora los NULL
    COALESCE(MAX(d.departamento_oficial), MAX(d.departamento)),
    N'Sin clasificar'
FROM stg.delitos AS d
WHERE NOT EXISTS (SELECT 1 FROM stg.divipola AS c WHERE c.cod_mpio = d.codigo_dane)
GROUP BY d.codigo_dane;
GO

-- dim_delito: un registro por código ICCS. Como iccs es UNIQUE, si algún código
-- tuviera dos nombres distintos la carga fallaría en vez de ocultarlo.
INSERT INTO dw.dim_delito (iccs, delito)
SELECT DISTINCT iccs, delito
FROM stg.delitos;
GO

-- dim_modalidad: un registro por arma o medio.
INSERT INTO dw.dim_modalidad (arma_medio)
SELECT DISTINCT arma_medio
FROM stg.delitos;
GO

-- dim_victima: un registro por combinación de género y grupo de edad.
INSERT INTO dw.dim_victima (genero, grupo_edad)
SELECT DISTINCT genero, grupo_edad
FROM stg.delitos;
GO

-- Verificación: filas de cada dimensión. Esperado con los datos de 2025:
-- fecha 365, ubicación 1124, delito 18, modalidad 45, víctima 10.
SELECT 'dim_fecha' AS tabla, COUNT(*) AS filas FROM dw.dim_fecha
UNION ALL SELECT 'dim_ubicacion', COUNT(*) FROM dw.dim_ubicacion
UNION ALL SELECT 'dim_delito',    COUNT(*) FROM dw.dim_delito
UNION ALL SELECT 'dim_modalidad', COUNT(*) FROM dw.dim_modalidad
UNION ALL SELECT 'dim_victima',   COUNT(*) FROM dw.dim_victima;
GO
