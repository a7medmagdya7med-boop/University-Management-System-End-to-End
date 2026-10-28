-- Extracted from UniversityManagementDB(2).sql; source lines 399-479.
USE [UniversityManagementDB];
GO
--------02_Create_Tables_07_GraduationProject
USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.GraduationProject', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GraduationProject
    (
        GraduationProjectID INT NOT NULL,
        ProjectTitle NVARCHAR(255) NOT NULL,
        DepartmentID INT NOT NULL,

        CONSTRAINT PK_GraduationProject
            PRIMARY KEY CLUSTERED (GraduationProjectID),

        CONSTRAINT FK_GraduationProject_Department
            FOREIGN KEY (DepartmentID)
            REFERENCES dbo.Department (DepartmentID)
    );

    PRINT 'GraduationProject table created successfully.';
END
ELSE
BEGIN
    PRINT 'GraduationProject already exists. No changes made; verify its schema.';
END;
GO
------------------------------
----04_Verify_GraduationProject
-- Test 1: existence and 3 required columns
SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'GraduationProject'
ORDER BY ORDINAL_POSITION;
GO
-----------------------------
-- Test 2: primary key must be PK_GraduationProject on GraduationProjectID
SELECT
    kc.name AS PrimaryKeyName,
    c.name AS PrimaryKeyColumn,
    ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0
ORDER BY ic.key_ordinal;
GO
---------------------------------------------
-- Test 3: FK from DepartmentID to Department.DepartmentID; trusted/enabled
SELECT
    fk.name AS ForeignKeyName,
    pc.name AS ParentColumn,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    rc.name AS ReferencedColumn,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns AS pc
    ON pc.object_id = fk.parent_object_id
   AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
    ON rc.object_id = fk.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
-----------------
GO
