-- =====================================================================
-- 06_cargar_hechos.sql
--
-- Llena fact_delitos agrupando los casos de stg.delitos.
--
-- Requisitos: las dimensiones ya cargadas (05_cargar_dimensiones.sql).
-- Se puede repetir: vacía la tabla antes de cargar.
-- =====================================================================

USE ColombiaSeguridad;
GO

DELETE FROM dw.fact_delitos;
GO

-- Grano: fecha + ubicación + delito + modalidad + víctima.
-- 'cantidad' suma los casos que comparten esa combinación (773.950 filas -> 360.837).
-- Cada JOIN traduce un texto (por ejemplo el código DANE) a la llave numérica de su
-- dimensión. Son JOIN internos: si una llave no existiera en una dimensión, la fila
-- se descartaría sin avisar. Por eso se verifica la suma de casos al final.
INSERT INTO dw.fact_delitos (fecha_key, ubicacion_key, delito_key, modalidad_key, victima_key, cantidad)
SELECT
    f.fecha_key,
    u.ubicacion_key,
    d.delito_key,
    m.modalidad_key,
    v.victima_key,
    SUM(s.cantidad)
FROM stg.delitos AS s
JOIN dw.dim_fecha      AS f ON f.fecha        = s.fecha_hecho
JOIN dw.dim_ubicacion  AS u ON u.codigo_dane  = s.codigo_dane
JOIN dw.dim_delito     AS d ON d.iccs         = s.iccs
JOIN dw.dim_modalidad  AS m ON m.arma_medio   = s.arma_medio
JOIN dw.dim_victima    AS v ON v.genero       = s.genero AND v.grupo_edad = s.grupo_edad
GROUP BY f.fecha_key, u.ubicacion_key, d.delito_key, m.modalidad_key, v.victima_key;
GO

-- Verificación: las dos primeras cifras deben ser iguales (773950 casos).
SELECT
    (SELECT SUM(cantidad) FROM stg.delitos)     AS casos_en_staging,
    (SELECT SUM(cantidad) FROM dw.fact_delitos) AS casos_en_hechos,
    (SELECT COUNT(*) FROM dw.fact_delitos)      AS filas_en_hechos;
GO
