-- =====================================================================
-- 02_crear_staging.sql
--
-- Crea las tablas de staging: la zona de aterrizaje de los datos.
-- Cada tabla replica el CSV correspondiente, sin transformar, para poder
-- reconstruir el modelo estrella sin volver a leer los archivos originales.
--
-- Cómo se llenan (src/): carga_staging.py (delitos) y
-- carga_staging_referencia.py (divipola y poblacion).
-- =====================================================================

USE ColombiaSeguridad;
GO

-- Delitos 2025 de la Policía Nacional, ya limpios (salida de src/limpieza.py).
-- Una fila por caso registrado: 'cantidad' vale 1 en todas.
-- Las columnas *_oficial y tipo_unidad vienen del catálogo DIVIPOLA y quedan
-- vacías cuando el código DANE no está en el catálogo (8 registros).
CREATE TABLE stg.delitos (
    arma_medio           NVARCHAR(60)   NOT NULL,
    departamento         NVARCHAR(50)   NOT NULL,
    municipio            NVARCHAR(60)   NULL,        -- 7 registros de Nariño sin municipio (código 52000)
    fecha_hecho          DATE           NOT NULL,
    genero               NVARCHAR(20)   NOT NULL,    -- los vacíos del origen quedan como 'NO REPORTADO'
    grupo_edad           NVARCHAR(30)   NOT NULL,    -- ídem
    codigo_dane          CHAR(5)        NOT NULL,    -- texto: conserva el cero inicial (05001)
    delito               NVARCHAR(150)  NOT NULL,
    mes                  CHAR(2)        NOT NULL,
    cantidad             INT            NOT NULL,
    iccs                 VARCHAR(6)     NOT NULL,    -- longitud variable: 4, 5 o 6 dígitos según el delito
    municipio_oficial    NVARCHAR(80)   NULL,
    departamento_oficial NVARCHAR(100)  NULL,
    tipo_unidad          NVARCHAR(30)   NULL
);
GO

-- Catálogo oficial DIVIPOLA del DANE (códigos y nombres de territorios).
-- De aquí nace la dimensión de ubicación, para incluir también los
-- territorios sin delitos registrados.
CREATE TABLE stg.divipola (
    cod_dpto        CHAR(2)        NOT NULL,
    dpto            NVARCHAR(100)  NOT NULL,
    cod_mpio        CHAR(5)        NOT NULL,
    nom_mpio        NVARCHAR(100)  NOT NULL,
    tipo_municipio  NVARCHAR(40)   NOT NULL         -- Municipio, Área no municipalizada o Isla
);
GO

-- Proyecciones de población del DANE: una fila por territorio y año (solo el total).
-- Algunos territorios tienen 0 habitantes en ciertos años (por ejemplo, Mapiripana
-- desde 2020, que el DANE cuenta dentro de Barrancominas).
CREATE TABLE stg.poblacion (
    codigo_dane  CHAR(5)   NOT NULL,
    anio         SMALLINT  NOT NULL,
    habitantes   INT       NOT NULL
);
GO
