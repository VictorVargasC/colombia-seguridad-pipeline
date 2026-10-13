

USE ColombiaSeguridad;
GO

CREATE TABLE stg.delitos (
    arma_medio           NVARCHAR(60)   NOT NULL,
    departamento         NVARCHAR(50)   NOT NULL,
    municipio            NVARCHAR(60)   NULL,
    fecha_hecho          DATE           NOT NULL,
    genero               NVARCHAR(20)   NOT NULL,
    grupo_edad           NVARCHAR(30)   NOT NULL,
    codigo_dane          CHAR(5)        NOT NULL,
    delito               NVARCHAR(150)  NOT NULL,
    mes                  CHAR(2)        NOT NULL,
    cantidad             INT            NOT NULL,
    iccs                 VARCHAR(6)     NOT NULL,
    municipio_oficial    NVARCHAR(80)   NULL,
    departamento_oficial NVARCHAR(100)  NULL,
    tipo_unidad          NVARCHAR(30)   NULL
);
GO
