-- Extracted from UniversityManagementDB(2).sql; source lines 177-231.
USE [UniversityManagementDB];
GO
-----02_Create_Tables_04_Library

USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.Library', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Library
    (
        LibraryID INT NOT NULL,
        LibraryName NVARCHAR(150) NOT NULL,

        CONSTRAINT PK_Library
            PRIMARY KEY CLUSTERED (LibraryID)
    );

    PRINT 'Library table created successfully.';
END
ELSE
BEGIN
    PRINT 'Library already exists. No changes made.';
END;
GO
-----------------------------------------------------
----04_Verify_Library
USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Library'
ORDER BY ORDINAL_POSITION;
------------------------------
------Primary Key
SELECT
    kc.name AS PrimaryKeyName,
    c.name AS PrimaryKeyColumn
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.parent_object_id =
      OBJECT_ID(N'dbo.Library', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0;

  ------------------------------
GO
