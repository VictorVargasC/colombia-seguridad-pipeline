

USE ColombiaSeguridad;
GO

-- Vaciar el modelo para poder repetir la carga: primero los hechos, luego las dimensiones.
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
WITH calendario AS (
    SELECT CAST('2025-01-01' AS DATE) AS fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, fecha) FROM calendario WHERE fecha < '2025-12-31'
)
INSERT INTO dw.dim_fecha
    (fecha_key, fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia_semana, es_fin_de_semana)
SELECT
    YEAR(fecha) * 10000 + MONTH(fecha) * 100 + DAY(fecha),
    fecha,
    YEAR(fecha),
    DATEPART(QUARTER, fecha),
    MONTH(fecha),
    CHOOSE(MONTH(fecha), N'enero', N'febrero', N'marzo', N'abril', N'mayo', N'junio',
                         N'julio', N'agosto', N'septiembre', N'octubre', N'noviembre', N'diciembre'),
    DAY(fecha),
    d.dia_semana,
    CHOOSE(d.dia_semana, N'lunes', N'martes', N'miércoles', N'jueves', N'viernes', N'sábado', N'domingo'),
    CASE WHEN d.dia_semana >= 6 THEN 1 ELSE 0 END
FROM calendario
CROSS APPLY (SELECT (DATEPART(WEEKDAY, fecha) + @@DATEFIRST - 2) % 7 + 1 AS dia_semana) AS d
OPTION (MAXRECURSION 400);
GO

-- dim_ubicacion: una fila por código DANE, con el nombre oficial del catálogo.
-- Si el código no está en el catálogo, se usa el nombre que trae la Policía.
INSERT INTO dw.dim_ubicacion (codigo_dane, municipio, departamento, tipo_unidad)
SELECT
    codigo_dane,
    COALESCE(MAX(municipio_oficial), MAX(municipio)),
    COALESCE(MAX(departamento_oficial), MAX(departamento)),
    COALESCE(MAX(tipo_unidad), N'Sin clasificar')
FROM stg.delitos
GROUP BY codigo_dane;
GO

-- dim_delito: un registro por código ICCS.
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

