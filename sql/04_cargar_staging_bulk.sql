

-- Forma alternativa de cargar datos en la tabla de staging usando SQL en vez de un script de Python.

USE ColombiaSeguridad;
GO

TRUNCATE TABLE stg.delitos;
GO

BULK INSERT stg.delitos
FROM 'C:\proyectos\colombia-seguridad-pipeline\data\interim\delitos_2025_limpio.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    FIELDTERMINATOR = ',',
    KEEPNULLS,
    TABLOCK
);
GO