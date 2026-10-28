-- Extracted from UniversityManagementDB(2).sql; source lines 480-576.
USE [UniversityManagementDB];
GO
---ResearchProject

USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ResearchProject
    (
        ResearchProjectID INT NOT NULL,
        ProjectTitle NVARCHAR(255) NOT NULL,
        LeadDepartmentID INT NOT NULL,

        CONSTRAINT PK_ResearchProject
            PRIMARY KEY CLUSTERED (ResearchProjectID),

        CONSTRAINT FK_ResearchProject_LeadDepartment
            FOREIGN KEY (LeadDepartmentID)
            REFERENCES dbo.Department (DepartmentID)
    );

    PRINT 'ResearchProject table created successfully.';
END
ELSE
BEGIN
    PRINT 'ResearchProject already exists. No changes made.';
END;
GO
------------------------------------
---Table Existence
USE [UniversityManagementDB];
GO

SELECT
    CASE
        WHEN OBJECT_ID(N'dbo.ResearchProject', N'U')
             IS NOT NULL
        THEN 'EXISTS'
        ELSE 'NOT FOUND'
    END AS TableStatus;
    -------------
    --اختبار الأعمدة — Columns & Data Types
    
USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ResearchProject'
ORDER BY ORDINAL_POSITION;

---------------------------------
----Primary Key

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
      OBJECT_ID(N'dbo.ResearchProject', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0;
  ----------------------------------
  --Foreign Key
  
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
      OBJECT_ID(N'dbo.ResearchProject', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
------------------------------------------
GO
