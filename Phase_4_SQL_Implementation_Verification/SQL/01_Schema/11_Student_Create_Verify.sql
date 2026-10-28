-- Extracted from UniversityManagementDB(2).sql; source lines 755-843.
USE [UniversityManagementDB];
GO
---02_Create_Tables_11_Student

USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Student
    (
        StudentID INT NOT NULL,
        [Name] NVARCHAR(150) NOT NULL,
        DateOfBirth DATE NOT NULL,
        Email NVARCHAR(254) NOT NULL,
        GraduationProjectID INT NULL,

        CONSTRAINT PK_Student
            PRIMARY KEY CLUSTERED (StudentID),

        CONSTRAINT FK_Student_GraduationProject
            FOREIGN KEY (GraduationProjectID)
            REFERENCES dbo.GraduationProject
                (GraduationProjectID)
    );

    PRINT 'Student table created successfully.';
END
ELSE
BEGIN
    PRINT 'Student already exists. No changes made; verify its schema.';
END;
GO
---------------
---Verification
---Test 1 — Columns & Data Types


USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Student'
ORDER BY ORDINAL_POSITION;

----------------------------------------
---Test 2 — Primary Key

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
      OBJECT_ID(N'dbo.Student', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0;
  -------------------------------------
  ----Test 3 — Foreign Key
  
SELECT
    fk.name AS ForeignKeyName,
    pc.name AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id)
        AS ReferencedTable,
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
WHERE fk.parent_object_id =
      OBJECT_ID(N'dbo.Student', N'U');
      -----------------------------------------------
GO
