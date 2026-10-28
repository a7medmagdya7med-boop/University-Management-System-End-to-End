-- NEW helper; not extracted from source. Creates an empty database only.
USE master;
GO
IF DB_ID(N'UniversityManagementDB') IS NULL
 EXEC(N'CREATE DATABASE [UniversityManagementDB]');
GO
