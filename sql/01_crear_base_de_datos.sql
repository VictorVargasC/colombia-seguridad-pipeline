-- =====================================================================
-- 01_crear_base_de_datos.sql
--
-- Crea la base de datos del proyecto y sus dos esquemas, que funcionan
-- como "carpetas" para ordenar las tablas:
--   stg : staging. Datos casi crudos, tal como llegan de los archivos.
--   dw  : modelo estrella (data warehouse). Es lo que consume Power BI.
--
-- Ejecutar una sola vez, conectado a la instancia .\SQLEXPRESS.
--
-- Para reconstruir todo desde cero, borra la base y vuelve a ejecutar los
-- scripts en orden (descomenta con cuidado: elimina TODOS los datos):
--   USE master;
--   ALTER DATABASE ColombiaSeguridad SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--   DROP DATABASE ColombiaSeguridad;
-- =====================================================================

CREATE DATABASE ColombiaSeguridad;
GO

-- Cambiar a la base nueva. Sin este paso, los esquemas se crearían en 'master'.
USE ColombiaSeguridad;
GO

CREATE SCHEMA stg;
GO

CREATE SCHEMA dw;
GO
