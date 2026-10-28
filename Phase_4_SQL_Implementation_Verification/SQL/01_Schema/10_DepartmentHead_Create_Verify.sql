-- Extracted from UniversityManagementDB(2).sql; source lines 661-754.
USE [UniversityManagementDB];
GO
----02_Create_Tables_10_DepartmentHead
USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.DepartmentHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DepartmentHead
    (
        DepartmentID INT NOT NULL,
        ProfessorID INT NOT NULL,

        CONSTRAINT PK_DepartmentHead
            PRIMARY KEY CLUSTERED (DepartmentID),

        CONSTRAINT UQ_DepartmentHead_Professor
            UNIQUE (ProfessorID),

        CONSTRAINT FK_DepartmentHead_Department
            FOREIGN KEY (DepartmentID)
            REFERENCES dbo.Department (DepartmentID),

        CONSTRAINT FK_DepartmentHead_ProfessorSameDepartment
            FOREIGN KEY (ProfessorID, DepartmentID)
            REFERENCES dbo.Professor
                (ProfessorID, DepartmentID)
    );

    PRINT 'DepartmentHead table created successfully.';
END
ELSE
BEGIN
    PRINT 'DepartmentHead already exists. No changes made; verify its schema.';
END;
GO
-------------------------------------------------------
----Verification
----Test 1 — Columns & Data Types

USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'DepartmentHead'
ORDER BY ORDINAL_POSITION;
----------------------------------
---Test 2 — Primary Key & UNIQUE

SELECT
    kc.name AS ConstraintName,
    kc.type_desc AS ConstraintType,
    c.name AS ColumnName,
    ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.parent_object_id =
      OBJECT_ID(N'dbo.DepartmentHead', N'U')
  AND kc.type IN ('PK', 'UQ')
  AND ic.key_ordinal > 0
ORDER BY kc.name, ic.key_ordinal;
---------------------------------------------------
----Test 3 — Foreign Keys

SELECT
    fk.name AS ForeignKeyName,
    pc.name AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id)
        AS ReferencedTable,
    rc.name AS ReferencedColumn,
    fkc.constraint_column_id AS ColumnOrder,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns AS pc
    ON pc.object_id = fkc.parent_object_id
   AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
    ON rc.object_id = fkc.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id =
      OBJECT_ID(N'dbo.DepartmentHead', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
---------------------------------------------------------
GO
