-- Extracted from UniversityManagementDB(2).sql; source lines 1923-2168.
USE [UniversityManagementDB];
GO
----02_Create_Tables_21_ResearchCollaboration
      USE [UniversityManagementDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
------------------
         IF OBJECT_ID(N'dbo.ResearchCollaboration', N'U') IS NULL
BEGIN
    IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Professor', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Department', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchParticipation', N'U') IS NULL
    BEGIN
        THROW 51021,
              'Missing prerequisite: Student, Professor, ResearchProject, Department or ResearchParticipation.',
              1;
    END;

    CREATE TABLE dbo.ResearchCollaboration
    (
        StudentID INT NOT NULL,
        ProfessorID INT NOT NULL,
        ResearchProjectID INT NOT NULL,
        CollaborationDepartmentID INT NOT NULL,

        CONSTRAINT PK_ResearchCollaboration
            PRIMARY KEY CLUSTERED
            (StudentID, ProfessorID, ResearchProjectID, CollaborationDepartmentID),

        CONSTRAINT FK_ResearchCollaboration_Student
            FOREIGN KEY (StudentID)
            REFERENCES dbo.Student (StudentID),

        CONSTRAINT FK_ResearchCollaboration_Professor
            FOREIGN KEY (ProfessorID)
            REFERENCES dbo.Professor (ProfessorID),

        CONSTRAINT FK_ResearchCollaboration_ResearchProject
            FOREIGN KEY (ResearchProjectID)
            REFERENCES dbo.ResearchProject (ResearchProjectID),

        CONSTRAINT FK_ResearchCollaboration_CollaborationDepartment
            FOREIGN KEY (CollaborationDepartmentID)
            REFERENCES dbo.Department (DepartmentID),

        CONSTRAINT FK_ResearchCollaboration_ResearchParticipation
            FOREIGN KEY (StudentID, ResearchProjectID)
            REFERENCES dbo.ResearchParticipation (StudentID, ResearchProjectID)
    );

    PRINT 'ResearchCollaboration table created successfully.';
END
ELSE
BEGIN
    PRINT 'ResearchCollaboration already exists. No changes made. Run verification.';
END;
GO
-----------------------------------
---04_Verify_21_ResearchCollaboration
-- Test 0: Table existence (one row; expect EXISTS).
SELECT CASE WHEN OBJECT_ID(N'dbo.ResearchCollaboration', N'U') IS NOT NULL
            THEN 'EXISTS' ELSE 'NOT FOUND' END AS TableStatus;
GO
-----------------
-- Test 1: Four columns, correct order, type and NOT NULL.
SELECT COLUMN_NAME AS ColumnName,
       DATA_TYPE AS DataType,
       CHARACTER_MAXIMUM_LENGTH AS MaxLength,
       IS_NULLABLE AS IsNullable,
       ORDINAL_POSITION AS ColumnOrder
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ResearchCollaboration'
ORDER BY ORDINAL_POSITION;
GO
---------------------------------
-- Test 2: PK_ResearchCollaboration (four rows, ordinal 1..4).
SELECT kc.name AS PrimaryKeyName,
       c.name AS PrimaryKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
  ON ic.object_id = kc.parent_object_id
 AND ic.index_id = kc.unique_index_id
 AND ic.key_ordinal > 0
JOIN sys.columns AS c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
  AND kc.type = 'PK'
ORDER BY ic.key_ordinal;
GO
----------------------------------
-- Test 3: 5 FK names across 6 column rows; all enabled/trusted (0/0).
SELECT fk.name AS ForeignKeyName,
       fkc.constraint_column_id AS ColumnOrder,
       pc.name AS ParentColumn,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,
       fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
  ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns AS pc
  ON pc.object_id = fkc.parent_object_id
 AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
  ON rc.object_id = fkc.referenced_object_id
 AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
--------------------------------------
-- Test 4: Dedicated verification of composite FK to ResearchParticipation.
-- Expect exactly two rows: StudentID, then ResearchProjectID.
SELECT fk.name AS ForeignKeyName,
       fkc.constraint_column_id AS ColumnOrder,
       pc.name AS ParentColumn,
       rc.name AS ReferencedColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
  ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns AS pc
  ON pc.object_id = fkc.parent_object_id
 AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
  ON rc.object_id = fkc.referenced_object_id
 AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
  AND fk.name = N'FK_ResearchCollaboration_ResearchParticipation'
ORDER BY fkc.constraint_column_id;
GO
--------------------------------------
-- Test 5: Automated strict structural audit.
-- PASS requires exact four INT NOT NULL columns, the ordered four-column PK,
-- five precisely named FK constraints (six mappings), enabled/trusted,
-- and no additional unique keys/indexes beyond the PK.
WITH ActualColumns AS
(
    SELECT c.name, t.name AS type_name, c.is_nullable, c.column_id
    FROM sys.columns AS c
    JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
),
ActualPK AS
(
    SELECT kc.name AS constraint_name, c.name AS column_name, ic.key_ordinal
    FROM sys.key_constraints AS kc
    JOIN sys.index_columns AS ic
      ON ic.object_id = kc.parent_object_id
     AND ic.index_id = kc.unique_index_id
     AND ic.key_ordinal > 0
    JOIN sys.columns AS c
      ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
      AND kc.type = 'PK'
),
ActualFK AS
(
    SELECT fk.object_id AS fk_id, fk.name AS fk_name,
           fkc.constraint_column_id AS column_order,
           pc.name AS parent_col,
           OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ref_schema,
           OBJECT_NAME(fk.referenced_object_id) AS ref_table,
           rc.name AS ref_col, fk.is_disabled, fk.is_not_trusted
    FROM sys.foreign_keys AS fk
    JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.columns AS pc ON pc.object_id = fkc.parent_object_id
       AND pc.column_id = fkc.parent_column_id
    JOIN sys.columns AS rc ON rc.object_id = fkc.referenced_object_id
       AND rc.column_id = fkc.referenced_column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
)
SELECT CASE WHEN
    OBJECT_ID(N'dbo.ResearchCollaboration', N'U') IS NOT NULL
    AND (SELECT COUNT(*) FROM ActualColumns) = 4
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'StudentID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 1)
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'ProfessorID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 2)
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'ResearchProjectID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 3)
    AND EXISTS (SELECT 1 FROM ActualColumns WHERE name = 'CollaborationDepartmentID' AND type_name = 'int' AND is_nullable = 0 AND column_id = 4)
    AND (SELECT COUNT(*) FROM ActualPK) = 4
    AND EXISTS (SELECT 1 FROM ActualPK WHERE constraint_name = 'PK_ResearchCollaboration' AND column_name = 'StudentID' AND key_ordinal = 1)
    AND EXISTS (SELECT 1 FROM ActualPK WHERE constraint_name = 'PK_ResearchCollaboration' AND column_name = 'ProfessorID' AND key_ordinal = 2)
    AND EXISTS (SELECT 1 FROM ActualPK WHERE constraint_name = 'PK_ResearchCollaboration' AND column_name = 'ResearchProjectID' AND key_ordinal = 3)
    AND EXISTS (SELECT 1 FROM ActualPK WHERE constraint_name = 'PK_ResearchCollaboration' AND column_name = 'CollaborationDepartmentID' AND key_ordinal = 4)
    AND (SELECT COUNT(DISTINCT fk_id) FROM ActualFK) = 5
    AND (SELECT COUNT(*) FROM ActualFK) = 6
    AND NOT EXISTS (SELECT 1 FROM ActualFK WHERE is_disabled <> 0 OR is_not_trusted <> 0)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_Student' AND parent_col = 'StudentID' AND ref_schema = 'dbo' AND ref_table = 'Student' AND ref_col = 'StudentID' AND column_order = 1)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_Professor' AND parent_col = 'ProfessorID' AND ref_schema = 'dbo' AND ref_table = 'Professor' AND ref_col = 'ProfessorID' AND column_order = 1)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_ResearchProject' AND parent_col = 'ResearchProjectID' AND ref_schema = 'dbo' AND ref_table = 'ResearchProject' AND ref_col = 'ResearchProjectID' AND column_order = 1)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_CollaborationDepartment' AND parent_col = 'CollaborationDepartmentID' AND ref_schema = 'dbo' AND ref_table = 'Department' AND ref_col = 'DepartmentID' AND column_order = 1)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_ResearchParticipation' AND parent_col = 'StudentID' AND ref_schema = 'dbo' AND ref_table = 'ResearchParticipation' AND ref_col = 'StudentID' AND column_order = 1)
    AND EXISTS (SELECT 1 FROM ActualFK WHERE fk_name = 'FK_ResearchCollaboration_ResearchParticipation' AND parent_col = 'ResearchProjectID' AND ref_schema = 'dbo' AND ref_table = 'ResearchParticipation' AND ref_col = 'ResearchProjectID' AND column_order = 2)
    AND NOT EXISTS
    (
        SELECT 1 FROM sys.indexes AS i
        WHERE i.object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
          AND i.is_unique = 1 AND i.is_primary_key = 0
    )
  THEN 'PASS' ELSE 'FAIL' END AS StructuralAudit;
GO
---------------------------------
-- Test 6: Orphan diagnostics; expected zero rows.
SELECT rc.StudentID, rc.ProfessorID, rc.ResearchProjectID,
       rc.CollaborationDepartmentID
FROM dbo.ResearchCollaboration AS rc
WHERE NOT EXISTS (SELECT 1 FROM dbo.Student AS s WHERE s.StudentID = rc.StudentID)
   OR NOT EXISTS (SELECT 1 FROM dbo.Professor AS p WHERE p.ProfessorID = rc.ProfessorID)
   OR NOT EXISTS (SELECT 1 FROM dbo.ResearchProject AS r WHERE r.ResearchProjectID = rc.ResearchProjectID)
   OR NOT EXISTS (SELECT 1 FROM dbo.Department AS d WHERE d.DepartmentID = rc.CollaborationDepartmentID)
   OR NOT EXISTS
   (
       SELECT 1 FROM dbo.ResearchParticipation AS rp
       WHERE rp.StudentID = rc.StudentID
         AND rp.ResearchProjectID = rc.ResearchProjectID
   );
GO
------------------------------
-- Test 7: Duplicate quad associations; expected zero rows.
SELECT StudentID, ProfessorID, ResearchProjectID,
       CollaborationDepartmentID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.ResearchCollaboration
GROUP BY StudentID, ProfessorID, ResearchProjectID, CollaborationDepartmentID
HAVING COUNT_BIG(*) > 1;
GO
------------------------------------
-- Test 8: No extra UNIQUE indexes (including forbidden triplet uniqueness).
-- Expected zero rows. Primary key is intentionally excluded.
SELECT i.name AS UnexpectedUniqueIndex,
       i.is_unique AS IsUnique,
       i.is_primary_key AS IsPrimaryKey,
       i.has_filter AS HasFilter
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'dbo.ResearchCollaboration', N'U')
  AND i.is_unique = 1
  AND i.is_primary_key = 0;
GO
-------------------------------------
GO
