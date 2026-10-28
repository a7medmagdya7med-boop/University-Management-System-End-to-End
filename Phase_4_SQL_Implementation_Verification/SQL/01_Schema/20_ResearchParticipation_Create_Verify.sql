-- Extracted from UniversityManagementDB(2).sql; source lines 1775-1922.
USE [UniversityManagementDB];
GO
USE [UniversityManagementDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
---------------------
---02_Create_Tables_20_ResearchParticipation
IF OBJECT_ID(N'dbo.ResearchParticipation', N'U') IS NULL
BEGIN
    IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
    BEGIN
        THROW 51020,
              'Prerequisite table dbo.Student or dbo.ResearchProject does not exist.',
              1;
    END;

    CREATE TABLE dbo.ResearchParticipation
    (
        StudentID INT NOT NULL,
        ResearchProjectID INT NOT NULL,

        CONSTRAINT PK_ResearchParticipation
            PRIMARY KEY CLUSTERED (StudentID, ResearchProjectID),

        CONSTRAINT FK_ResearchParticipation_Student
            FOREIGN KEY (StudentID)
            REFERENCES dbo.Student (StudentID),

        CONSTRAINT FK_ResearchParticipation_ResearchProject
            FOREIGN KEY (ResearchProjectID)
            REFERENCES dbo.ResearchProject (ResearchProjectID)
    );

    PRINT 'ResearchParticipation table created successfully.';
END
ELSE
BEGIN
    PRINT 'ResearchParticipation already exists. No changes made.';
END;
GO
----------------------
---Verification
-- Test 0: existence (one row = EXISTS).
SELECT CASE WHEN OBJECT_ID(N'dbo.ResearchParticipation', N'U') IS NOT NULL
            THEN 'EXISTS' ELSE 'NOT FOUND' END AS TableStatus;
GO
-----------------------------------
-- Test 1: expected columns, types and nullability (two rows).
SELECT COLUMN_NAME AS ColumnName,
       DATA_TYPE AS DataType,
       CHARACTER_MAXIMUM_LENGTH AS MaxLength,
       IS_NULLABLE AS IsNullable,
       ORDINAL_POSITION AS ColumnOrder
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ResearchParticipation'
ORDER BY ORDINAL_POSITION;
GO
----------------------------------
-- Test 2: composite PK name, exact key and order (two rows).
SELECT kc.name AS PrimaryKeyName,
       c.name AS PrimaryKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
  ON kc.parent_object_id = ic.object_id
 AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
  ON ic.object_id = c.object_id
 AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchParticipation', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0
ORDER BY ic.key_ordinal;
GO
---------------------------------------------
-- Test 3: both FK relationships including enabled and trusted (two rows).
SELECT fk.name AS ForeignKeyName,
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
  ON pc.object_id = fkc.parent_object_id
 AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
  ON rc.object_id = fkc.referenced_object_id
 AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchParticipation', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
-------------------------------------------
-- Test 4: automated *structural* audit: PASS only for intended schema.
-- Checks both column definitions, correct ordered PK, and both trusted FKs.
WITH ActualColumns AS
(
    SELECT c.name, t.name AS type_name, c.is_nullable, c.column_id
    FROM sys.columns AS c
    JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.ResearchParticipation', N'U')
),
ActualPK AS
(
    SELECT c.name, ic.key_ordinal
    FROM sys.key_constraints AS kc
    JOIN sys.index_columns AS ic
      ON ic.object_id = kc.parent_object_id
     AND ic.index_id = kc.unique_index_id
     AND ic.key_ordinal > 0
    JOIN sys.columns AS c
      ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchParticipation', N'U')
      AND kc.type = 'PK'
      AND kc.name = N'PK_ResearchParticipation'
),
ActualFK AS
(
    SELECT fk.name, pc.name AS parent_col,
           OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ref_schema,
           OBJECT_NAME(fk.referenced_object_id) AS ref_table,
           rc.name AS ref_col, fk.is_disabled, fk.is_not_trusted
    FROM sys.foreign_keys AS fk
    JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.columns AS pc ON pc.object_id = fkc.parent_object_id
       AND pc.column_id = fkc.parent_column_id
    JOIN sys.columns AS rc ON rc.object_id = fkc.referenced_object_id
       AND rc.column_id = fkc.referenced_column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchParticipation', N'U')
)
SELECT CASE WHEN
    (SELECT COUNT(*) FROM ActualColumns) = 2
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'StudentID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 1)
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'ResearchProjectID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 2)
    AND (SELECT COUNT(*) FROM ActualPK) = 2
    AND EXISTS (SELECT 1 FROM ActualPK WHERE name = 'StudentID' AND key_ordinal = 1)
    AND EXISTS (SELECT 1 FROM ActualPK WHERE name = 'ResearchProjectID' AND key_ordinal = 2)
    AND (SELECT COUNT(*) FROM ActualFK) = 2
    AND EXISTS (SELECT 1 FROM ActualFK WHERE name = 'FK_ResearchParticipation_Student' AND parent_col = 'StudentID' AND ref_schema = 'dbo' AND ref_table = 'Student' AND ref_col = 'StudentID' AND is_disabled = 0 AND is_not_trusted = 0)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE name = 'FK_ResearchParticipation_ResearchProject' AND parent_col = 'ResearchProjectID' AND ref_schema = 'dbo' AND ref_table = 'ResearchProject' AND ref_col = 'ResearchProjectID' AND is_disabled = 0 AND is_not_trusted = 0)
  THEN 'PASS' ELSE 'FAIL' END AS StructuralAudit;
GO
------------------------------------------
GO
