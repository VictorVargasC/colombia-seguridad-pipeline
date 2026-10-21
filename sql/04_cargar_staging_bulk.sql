-- =====================================================================
-- 04_cargar_staging_bulk.sql
--
-- Forma ALTERNATIVA de llenar stg.delitos usando solo SQL (BULK INSERT),
-- en vez del script de Python (src/carga_staging.py). Usa uno u otro, no
-- hace falta ejecutar los dos.
--
-- Es más rápido que Python (unos 7 s frente a 44 s con 773.950 filas), pero:
--   * la ruta es ABSOLUTA y la lee el servicio de SQL Server, no tu usuario:
--     ajústala a donde esté el proyecto y comprueba que el servicio tenga permiso;
--   * no valida el número de filas (hazlo con un SELECT COUNT(*) después);
--   * es más difícil de integrar en un pipeline automatizado.
-- =====================================================================

USE ColombiaSeguridad;
GO

-- Vaciar primero para poder repetir la carga sin duplicar filas.
TRUNCATE TABLE stg.delitos;
GO

BULK INSERT stg.delitos
FROM 'C:\proyectos\colombia-seguridad-pipeline\data\interim\delitos_2025_limpio.csv'
WITH (
    FORMAT = 'CSV',            -- entiende el formato CSV estándar
    FIRSTROW = 2,              -- la fila 1 es el encabezado
    CODEPAGE = '65001',        -- el archivo está en UTF-8 (tildes y ñ)
    FIELDTERMINATOR = ',',
    KEEPNULLS,                 -- las celdas vacías entran como NULL
    TABLOCK                    -- bloquea la tabla durante la carga: más rápido
);
GO

-- Verificación: debe dar 773950.
SELECT COUNT(*) AS filas_en_staging FROM stg.delitos;
GO
