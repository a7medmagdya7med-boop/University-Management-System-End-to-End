-- Extracted from UniversityManagementDB(2).sql; source lines 1223-1323.
USE [UniversityManagementDB];
GO
----CREATE TABLE — UniversityIDCard
USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.UniversityIDCard', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UniversityIDCard
    (
        CardNumber NVARCHAR(32) NOT NULL,
        StudentID INT NOT NULL,
        IssueDate DATE NOT NULL,

        CONSTRAINT PK_UniversityIDCard
            PRIMARY KEY CLUSTERED (CardNumber),

        CONSTRAINT UQ_UniversityIDCard_StudentID
            UNIQUE (StudentID),

        CONSTRAINT FK_UniversityIDCard_Student
            FOREIGN KEY (StudentID)
            REFERENCES dbo.Student (StudentID)
    );

    PRINT 'UniversityIDCard table created successfully.';
END
ELSE
BEGIN
    PRINT 'UniversityIDCard already exists. No changes made; verify its schema.';
END;
GO
--------------------------------------------------
---Verification — Four Tests
-- Test 1: Expected three columns and their nullability.
SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'UniversityIDCard'
ORDER BY ORDINAL_POSITION;
GO
-----------------------------------
-- Test 2: Primary key on CardNumber only.
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
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0
ORDER BY ic.key_ordinal;
GO
------------------------------------------------------
-- Test 3: UNIQUE constraint on StudentID.
SELECT
    kc.name AS UniqueConstraintName,
    c.name AS UniqueColumn,
    ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
  AND kc.type = 'UQ'
  AND ic.key_ordinal > 0
ORDER BY kc.name, ic.key_ordinal;
GO
---------------------------------------------------
-- Test 4: FK toward Student.StudentID, enabled and trusted.
SELECT
    fk.name AS ForeignKeyName,
    pc.name AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    rc.name AS ReferencedColumn,
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
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
-------------------------------------------------------
GO
