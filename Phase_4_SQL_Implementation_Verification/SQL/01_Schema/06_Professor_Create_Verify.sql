-- Extracted from UniversityManagementDB(2).sql; source lines 288-398.
USE [UniversityManagementDB];
GO
-----02_Create_Tables_06_Professor

USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.Professor', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Professor
    (
        ProfessorID INT NOT NULL,
        [Name] NVARCHAR(150) NOT NULL,
        DepartmentID INT NOT NULL,
        AdvisorProfessorID INT NULL,

        CONSTRAINT PK_Professor
            PRIMARY KEY CLUSTERED (ProfessorID),

        CONSTRAINT UQ_Professor_ID_Department
            UNIQUE (ProfessorID, DepartmentID),

        CONSTRAINT FK_Professor_Department
            FOREIGN KEY (DepartmentID)
            REFERENCES dbo.Department (DepartmentID),

        CONSTRAINT CK_Professor_NoSelfAdvice
            CHECK (
                AdvisorProfessorID IS NULL
                OR AdvisorProfessorID <> ProfessorID
            ),

        CONSTRAINT FK_Professor_AdvisorSameDepartment
            FOREIGN KEY (AdvisorProfessorID, DepartmentID)
            REFERENCES dbo.Professor
                (ProfessorID, DepartmentID)
    );

    PRINT 'Professor table created successfully.';
END
ELSE
BEGIN
    PRINT 'Professor already exists. No changes made; verify its schema.';
END;
GO
--------------------------------
----04_Verify_Professor
----اختبار الأعمدة — Test 1
USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Professor'
ORDER BY ORDINAL_POSITION;
-------------------------
------اختبار المفاتيح — Test 2
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
      OBJECT_ID(N'dbo.Professor', N'U')
  AND kc.type IN ('PK', 'UQ')
  AND ic.key_ordinal > 0
ORDER BY kc.name, ic.key_ordinal;
------------------------------------------------
------اختبار العلاقات الخارجية — Test 3
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
    ON pc.object_id = fk.parent_object_id
   AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
    ON rc.object_id = fk.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id =
      OBJECT_ID(N'dbo.Professor', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
---------------------------------------------------
------اختبار CHECK Constraint — Test 4
SELECT
    cc.name AS CheckConstraintName,
    cc.definition AS CheckDefinition,
    cc.is_disabled AS IsDisabled,
    cc.is_not_trusted AS IsNotTrusted
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id =
      OBJECT_ID(N'dbo.Professor', N'U');
      ----------------------------------------------
GO
