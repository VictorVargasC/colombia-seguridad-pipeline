

USE ColombiaSeguridad;
GO

-- Dimensión de fechas: una fila por día. La llave es la fecha escrita como número AAAAMMDD.
CREATE TABLE dw.dim_fecha (
    fecha_key          INT           NOT NULL PRIMARY KEY,
    fecha              DATE          NOT NULL UNIQUE,
    anio               SMALLINT      NOT NULL,
    trimestre          TINYINT       NOT NULL,
    mes                TINYINT       NOT NULL,
    nombre_mes         NVARCHAR(15)  NOT NULL,
    dia                TINYINT       NOT NULL,
    dia_semana         TINYINT       NOT NULL,   -- 1 = lunes ... 7 = domingo
    nombre_dia_semana  NVARCHAR(15)  NOT NULL,
    es_fin_de_semana   BIT           NOT NULL
);
GO

-- Dimensión de ubicación: una fila por código DANE.
CREATE TABLE dw.dim_ubicacion (
    ubicacion_key  INT IDENTITY(1,1) PRIMARY KEY,
    codigo_dane    CHAR(5)        NOT NULL UNIQUE,
    municipio      NVARCHAR(80)   NULL,
    departamento   NVARCHAR(100)  NULL,
    tipo_unidad    NVARCHAR(30)   NULL
);
GO

-- Dimensión de delitos: una fila por código ICCS.
CREATE TABLE dw.dim_delito (
    delito_key  INT IDENTITY(1,1) PRIMARY KEY,
    iccs        VARCHAR(6)     NOT NULL UNIQUE,
    delito      NVARCHAR(150)  NOT NULL
);
GO

-- Dimensión de modalidad: una fila por arma o medio empleado.
CREATE TABLE dw.dim_modalidad (
    modalidad_key  INT IDENTITY(1,1) PRIMARY KEY,
    arma_medio     NVARCHAR(60)  NOT NULL UNIQUE
);
GO

-- Dimensión de víctima: una fila por combinación de género y grupo de edad.
CREATE TABLE dw.dim_victima (
    victima_key  INT IDENTITY(1,1) PRIMARY KEY,
    genero       NVARCHAR(20)  NOT NULL,
    grupo_edad   NVARCHAR(30)  NOT NULL,
    CONSTRAINT uq_dim_victima UNIQUE (genero, grupo_edad)
);
GO

-- Tabla de hechos. Grano: una fila por fecha + ubicación + delito + modalidad + víctima.
-- 'cantidad' es el número de casos registrados con esa combinación.
CREATE TABLE dw.fact_delitos (
    fecha_key       INT  NOT NULL,
    ubicacion_key   INT  NOT NULL,
    delito_key      INT  NOT NULL,
    modalidad_key   INT  NOT NULL,
    victima_key     INT  NOT NULL,
    cantidad        INT  NOT NULL,
    CONSTRAINT pk_fact_delitos PRIMARY KEY (fecha_key, ubicacion_key, delito_key, modalidad_key, victima_key),
    CONSTRAINT fk_fact_fecha      FOREIGN KEY (fecha_key)      REFERENCES dw.dim_fecha (fecha_key),
    CONSTRAINT fk_fact_ubicacion  FOREIGN KEY (ubicacion_key)  REFERENCES dw.dim_ubicacion (ubicacion_key),
    CONSTRAINT fk_fact_delito     FOREIGN KEY (delito_key)     REFERENCES dw.dim_delito (delito_key),
    CONSTRAINT fk_fact_modalidad  FOREIGN KEY (modalidad_key)  REFERENCES dw.dim_modalidad (modalidad_key),
    CONSTRAINT fk_fact_victima    FOREIGN KEY (victima_key)    REFERENCES dw.dim_victima (victima_key)
);
GO



SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dw' ORDER BY TABLE_NAME;