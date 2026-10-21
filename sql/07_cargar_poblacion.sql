-- =====================================================================
-- 07_cargar_poblacion.sql
--
-- Llena fact_poblacion con las proyecciones de población del DANE.
--
-- Requisitos: dim_ubicacion cargada (05_cargar_dimensiones.sql) y
-- stg.poblacion cargada (python src/carga_staging_referencia.py).
-- Se puede repetir: vacía la tabla antes de cargar.
-- =====================================================================

USE ColombiaSeguridad;
GO

DELETE FROM dw.fact_poblacion;
GO

-- Cambia el código DANE por la llave de la dimensión de ubicación.
INSERT INTO dw.fact_poblacion (ubicacion_key, anio, habitantes)
SELECT u.ubicacion_key, p.anio, p.habitantes
FROM stg.poblacion AS p
JOIN dw.dim_ubicacion AS u ON u.codigo_dane = p.codigo_dane;
GO

-- Verificación: ambas cifras deben ser iguales (28075). Si fact_poblacion tuviera
-- menos, algún código de población no existe en dim_ubicacion.
SELECT
    (SELECT COUNT(*) FROM stg.poblacion)     AS filas_en_staging,
    (SELECT COUNT(*) FROM dw.fact_poblacion) AS filas_en_hechos;
GO
