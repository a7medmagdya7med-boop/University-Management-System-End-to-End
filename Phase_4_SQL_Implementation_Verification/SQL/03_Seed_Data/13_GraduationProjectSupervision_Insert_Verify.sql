-- Extracted from UniversityManagementDB(2).sql; source lines 5878-6289.
USE [UniversityManagementDB];
GO
--Table 13 — GraduationProjectSupervision
---Phase4_13_Insert_GraduationProjectSupervision
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Expected TABLE
(
    GraduationProjectID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (GraduationProjectID, ProfessorID)
);
INSERT INTO @Expected (GraduationProjectID, ProfessorID)
VALUES
    (1001, 101),
    (1001, 102),
    (1002, 103),
    (1003, 201),
    (1003, 202),
    (1004, 203),
    (1005, 301),
    (1005, 302),
    (1006, 303),
    (1007, 401),
    (1007, 402),
    (1008, 403),
    (1009, 501),
    (1009, 502),
    (1010, 503),
    (1011, 601),
    (1011, 602),
    (1012, 603),
    (1013, 701),
    (1013, 702),
    (1014, 703),
    (1015, 801),
    (1015, 802),
    (1016, 803);

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51300, 'Wrong database. Stop without changes.', 1;
IF OBJECT_ID(N'dbo.GraduationProjectSupervision', N'U') IS NULL
    THROW 51301, 'Approved target table is missing. Stop without changes.', 1;
IF OBJECT_ID(N'dbo.GraduationProject', N'U') IS NULL
    THROW 51302, 'GraduationProject parent table is missing.', 1;
IF OBJECT_ID(N'dbo.Professor', N'U') IS NULL
    THROW 51303, 'Professor parent table is missing.', 1;

-- Refuse to proceed if the target does not match the approved two-column design.
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.GraduationProjectSupervision', N'U')) <> 2
   OR NOT EXISTS
      (SELECT 1 FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
       WHERE c.object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
         AND c.column_id=1 AND c.name=N'GraduationProjectID' AND t.name=N'int' AND c.is_nullable=0)
   OR NOT EXISTS
      (SELECT 1 FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
       WHERE c.object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
         AND c.column_id=2 AND c.name=N'ProfessorID' AND t.name=N'int' AND c.is_nullable=0)
    THROW 51304, 'Target column schema does not match approved DDL.', 1;

IF NOT EXISTS
    (SELECT 1 FROM sys.key_constraints
     WHERE parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision', N'U')
       AND type='PK' AND name=N'PK_GraduationProjectSupervision')
    THROW 51305, 'Approved composite primary key is missing.', 1;
IF (SELECT COUNT(*) FROM sys.foreign_keys
    WHERE parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
      AND is_disabled=0 AND is_not_trusted=0
      AND name IN (N'FK_GradProjectSupervision_GraduationProject',
                   N'FK_GradProjectSupervision_Professor')) <> 2
    THROW 51306, 'Approved FKs are missing, disabled, or untrusted.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Exclusive table lock prevents concurrent writes from bypassing this safety check.
    IF EXISTS (SELECT 1 FROM dbo.GraduationProjectSupervision WITH (TABLOCKX, HOLDLOCK))
        THROW 51307, 'Target is not empty. Existing data are protected; nothing inserted.', 1;

    IF (SELECT COUNT(*) FROM dbo.GraduationProject) <> 16
       OR (SELECT COUNT(*) FROM dbo.Professor) <> 32
        THROW 51308, 'Parent seed baselines (16 projects, 32 professors) differ. No insert.', 1;

    IF EXISTS
    (
        SELECT 1 FROM @Expected e
        LEFT JOIN dbo.GraduationProject g ON g.GraduationProjectID=e.GraduationProjectID
        LEFT JOIN dbo.Professor p ON p.ProfessorID=e.ProfessorID
        WHERE g.GraduationProjectID IS NULL OR p.ProfessorID IS NULL
           OR g.DepartmentID<>p.DepartmentID
    )
        THROW 51309, 'Proposed pairs have missing parents or mismatched departments.', 1;

    IF EXISTS
    (
        SELECT g.GraduationProjectID FROM dbo.GraduationProject g
        EXCEPT
        SELECT e.GraduationProjectID FROM @Expected e
    )
        THROW 51310, 'At least one existing graduation project has no proposed supervisor.', 1;

    INSERT INTO dbo.GraduationProjectSupervision (GraduationProjectID, ProfessorID)
    SELECT GraduationProjectID, ProfessorID FROM @Expected;

    IF (SELECT COUNT_BIG(*) FROM dbo.GraduationProjectSupervision) <> 24
        THROW 51311, 'Inserted row count differs from 24.', 1;

    IF EXISTS
       (SELECT GraduationProjectID, ProfessorID FROM @Expected
        EXCEPT
        SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision)
       OR EXISTS
       (SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision
        EXCEPT
        SELECT GraduationProjectID, ProfessorID FROM @Expected)
        THROW 51312, 'Exact expected/actual row-set mismatch. Rolling back.', 1;

    COMMIT TRANSACTION;
    PRINT 'PASS: 24 GraduationProjectSupervision rows inserted and committed.';
    PRINT 'All 16 graduation projects are covered. No previously approved table was modified.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
---------------------------
----Phase4_13_Verify_GraduationProjectSupervision.
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51320, 'Wrong database. Verification stopped.', 1;
IF OBJECT_ID(N'dbo.GraduationProjectSupervision', N'U') IS NULL
    THROW 51321, 'GraduationProjectSupervision is missing.', 1;

DECLARE @Expected TABLE
(
    GraduationProjectID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (GraduationProjectID, ProfessorID)
);
INSERT INTO @Expected (GraduationProjectID, ProfessorID)
VALUES
    (1001, 101),
    (1001, 102),
    (1002, 103),
    (1003, 201),
    (1003, 202),
    (1004, 203),
    (1005, 301),
    (1005, 302),
    (1006, 303),
    (1007, 401),
    (1007, 402),
    (1008, 403),
    (1009, 501),
    (1009, 502),
    (1010, 503),
    (1011, 601),
    (1011, 602),
    (1012, 603),
    (1013, 701),
    (1013, 702),
    (1014, 703),
    (1015, 801),
    (1015, 802),
    (1016, 803);

DECLARE @Checks TABLE
(
   CheckID INT IDENTITY(1,1) PRIMARY KEY,
   Item NVARCHAR(220) NOT NULL,
   Result VARCHAR(4) NOT NULL
);

-- 1. Exactly two approved INT NOT NULL columns in approved order.
INSERT @Checks(Item,Result)
SELECT N'Exactly two INT NOT NULL columns in approved order',
 CASE WHEN (SELECT COUNT(*) FROM sys.columns
            WHERE object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U'))=2
       AND EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
                   WHERE c.object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
                     AND c.column_id=1 AND c.name=N'GraduationProjectID'
                     AND t.name='int' AND c.is_nullable=0)
       AND EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
                   WHERE c.object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
                     AND c.column_id=2 AND c.name=N'ProfessorID'
                     AND t.name='int' AND c.is_nullable=0)
      THEN 'PASS' ELSE 'FAIL' END;

-- 2. Correct named composite PK, exactly two keys in correct order.
INSERT @Checks(Item,Result)
SELECT N'Composite PK (GraduationProjectID, ProfessorID) in correct order',
 CASE WHEN
     (SELECT COUNT(*) FROM sys.key_constraints kc
      WHERE kc.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
        AND kc.type='PK' AND kc.name=N'PK_GraduationProjectSupervision')=1
     AND (SELECT COUNT(*) FROM sys.key_constraints kc
          JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                                  AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
          WHERE kc.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
            AND kc.type='PK')=2
     AND EXISTS(SELECT 1 FROM sys.key_constraints kc
        JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
        JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE kc.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
          AND kc.type='PK' AND ic.key_ordinal=1 AND c.name=N'GraduationProjectID')
     AND EXISTS(SELECT 1 FROM sys.key_constraints kc
        JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
        JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE kc.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
          AND kc.type='PK' AND ic.key_ordinal=2 AND c.name=N'ProfessorID')
     THEN 'PASS' ELSE 'FAIL' END;

-- 3. Exactly the two approved, enabled + trusted FK mappings.
INSERT @Checks(Item,Result)
SELECT N'Exactly two approved FKs, enabled and trusted',
 CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys fk
            WHERE fk.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U'))=2
 AND (SELECT COUNT(*) FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
       JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
       JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
       WHERE fk.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
          AND fk.is_disabled=0 AND fk.is_not_trusted=0
          AND ( (fk.name=N'FK_GradProjectSupervision_GraduationProject'
                  AND fkc.constraint_column_id=1 AND pc.name=N'GraduationProjectID'
                  AND fk.referenced_object_id=OBJECT_ID(N'dbo.GraduationProject',N'U')
                  AND rc.name=N'GraduationProjectID')
             OR (fk.name=N'FK_GradProjectSupervision_Professor'
                  AND fkc.constraint_column_id=1 AND pc.name=N'ProfessorID'
                  AND fk.referenced_object_id=OBJECT_ID(N'dbo.Professor',N'U')
                  AND rc.name=N'ProfessorID') ))=2
 THEN 'PASS' ELSE 'FAIL' END;

-- 4. No unexpected extra unique indexes, which could prohibit valid many-to-many pairs.
INSERT @Checks(Item,Result)
SELECT N'No unapproved UNIQUE index outside primary key',
 CASE WHEN NOT EXISTS (SELECT 1 FROM sys.indexes
                       WHERE object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
                         AND is_unique=1 AND is_primary_key=0)
 THEN 'PASS' ELSE 'FAIL' END;

-- 5. Exactly 24 rows, no extras, no missing / altered associations.
INSERT @Checks(Item,Result)
SELECT N'Exact deterministic 24-row seed; no extra or missing pairs',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.GraduationProjectSupervision)=24
 AND NOT EXISTS (SELECT GraduationProjectID, ProfessorID FROM @Expected
                 EXCEPT SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision)
 AND NOT EXISTS (SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision
                 EXCEPT SELECT GraduationProjectID, ProfessorID FROM @Expected)
 THEN 'PASS' ELSE 'FAIL' END;

-- 6. Parents: approved 16 graduation projects and 32 professors.
INSERT @Checks(Item,Result)
SELECT N'Parent baseline: 16 projects and 32 professors',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.GraduationProject)=16
           AND (SELECT COUNT_BIG(*) FROM dbo.Professor)=32
 THEN 'PASS' ELSE 'FAIL' END;

-- 7. Each parent graduation project has >=1 supervisor (minimum participation).
INSERT @Checks(Item,Result)
SELECT N'Every graduation project has at least one supervisor',
 CASE WHEN NOT EXISTS
  (SELECT 1 FROM dbo.GraduationProject gp
   WHERE NOT EXISTS (SELECT 1 FROM dbo.GraduationProjectSupervision gps
                     WHERE gps.GraduationProjectID=gp.GraduationProjectID))
 THEN 'PASS' ELSE 'FAIL' END;

-- 8. Exactly 8 projects with one supervisor and 8 with two.
INSERT @Checks(Item,Result)
SELECT N'8 single-supervisor projects and 8 two-supervisor projects',
 CASE WHEN (SELECT COUNT(*) FROM
              (SELECT GraduationProjectID, COUNT_BIG(*) AS n
               FROM dbo.GraduationProjectSupervision GROUP BY GraduationProjectID) t
            WHERE n=1)=8
 AND (SELECT COUNT(*) FROM
              (SELECT GraduationProjectID, COUNT_BIG(*) AS n
               FROM dbo.GraduationProjectSupervision GROUP BY GraduationProjectID) t
            WHERE n=2)=8
 THEN 'PASS' ELSE 'FAIL' END;

-- 9. All project/professor associations refer to existing parents.
INSERT @Checks(Item,Result)
SELECT N'No invalid project or professor references',
 CASE WHEN NOT EXISTS
 (SELECT 1 FROM dbo.GraduationProjectSupervision gps
  LEFT JOIN dbo.GraduationProject gp ON gp.GraduationProjectID=gps.GraduationProjectID
  LEFT JOIN dbo.Professor p ON p.ProfessorID=gps.ProfessorID
  WHERE gp.GraduationProjectID IS NULL OR p.ProfessorID IS NULL)
 THEN 'PASS' ELSE 'FAIL' END;

-- 10. Seed pairing keeps project and professor in the same department.
INSERT @Checks(Item,Result)
SELECT N'All seeded supervisor pairings match project department',
 CASE WHEN NOT EXISTS
 (SELECT 1 FROM dbo.GraduationProjectSupervision gps
  JOIN dbo.GraduationProject gp ON gp.GraduationProjectID=gps.GraduationProjectID
  JOIN dbo.Professor p ON p.ProfessorID=gps.ProfessorID
  WHERE gp.DepartmentID<>p.DepartmentID)
 THEN 'PASS' ELSE 'FAIL' END;

-- 11. Each of the 8 departments has 2 projects / 3 supervision links.
INSERT @Checks(Item,Result)
SELECT N'Each of 8 departments has 2 projects and 3 supervision links',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Department)=8
 AND NOT EXISTS
 (SELECT 1 FROM dbo.Department d
  LEFT JOIN dbo.GraduationProject gp ON gp.DepartmentID=d.DepartmentID
  LEFT JOIN dbo.GraduationProjectSupervision gps ON gps.GraduationProjectID=gp.GraduationProjectID
  GROUP BY d.DepartmentID
  HAVING COUNT(DISTINCT gp.GraduationProjectID)<>2 OR COUNT(gps.ProfessorID)<>3)
 THEN 'PASS' ELSE 'FAIL' END;

-- 12. 24 distinct active supervising professors.
INSERT @Checks(Item,Result)
SELECT N'24 distinct active supervising professors',
 CASE WHEN (SELECT COUNT(DISTINCT ProfessorID)
            FROM dbo.GraduationProjectSupervision)=24
 THEN 'PASS' ELSE 'FAIL' END;

-- 13. 8 professors deliberately have no graduation supervision in this seed.
INSERT @Checks(Item,Result)
SELECT N'8 professors have no graduation-supervision assignment',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Professor p
            WHERE NOT EXISTS
             (SELECT 1 FROM dbo.GraduationProjectSupervision gps
              WHERE gps.ProfessorID=p.ProfessorID))=8
 THEN 'PASS' ELSE 'FAIL' END;

-- 14. No repeated pair even if constraints had been bypassed.
INSERT @Checks(Item,Result)
SELECT N'No duplicate (GraduationProjectID, ProfessorID) pairs',
 CASE WHEN NOT EXISTS
 (SELECT 1 FROM dbo.GraduationProjectSupervision
  GROUP BY GraduationProjectID, ProfessorID HAVING COUNT_BIG(*)>1)
 THEN 'PASS' ELSE 'FAIL' END;

-- Overall verification summary, followed by the tests and audit evidence.
SELECT N'GraduationProjectSupervision: Exact Row Set + Schema + PK + FK' AS VerificationTest,
       CASE WHEN NOT EXISTS(SELECT 1 FROM @Checks WHERE Result='FAIL')
            THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.GraduationProjectSupervision) AS ActualRows,
       (SELECT COUNT_BIG(*) FROM @Expected) AS ExpectedRows,
       (SELECT COUNT(*) FROM @Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM @Checks WHERE Result='FAIL') AS FailedChecks;

SELECT CheckID, Item, Result FROM @Checks ORDER BY CheckID;

-- All associated projects, named supervisors and department information.
SELECT gps.GraduationProjectID, gp.ProjectTitle,
       gps.ProfessorID, p.[Name] AS SupervisorName,
       gp.DepartmentID, d.DepartmentName
FROM dbo.GraduationProjectSupervision gps
JOIN dbo.GraduationProject gp ON gp.GraduationProjectID=gps.GraduationProjectID
JOIN dbo.Professor p ON p.ProfessorID=gps.ProfessorID
JOIN dbo.Department d ON d.DepartmentID=gp.DepartmentID
ORDER BY gps.GraduationProjectID, gps.ProfessorID;

-- Project supervision counts (16 expected rows).
SELECT gp.GraduationProjectID, gp.ProjectTitle, gp.DepartmentID,
       COUNT(gps.ProfessorID) AS SupervisorCount
FROM dbo.GraduationProject gp
LEFT JOIN dbo.GraduationProjectSupervision gps
  ON gps.GraduationProjectID=gp.GraduationProjectID
GROUP BY gp.GraduationProjectID, gp.ProjectTitle, gp.DepartmentID
ORDER BY gp.GraduationProjectID;

-- Department overview (8 expected rows, 2 projects / 3 links each).
SELECT d.DepartmentID, d.DepartmentName,
       COUNT(DISTINCT gp.GraduationProjectID) AS ProjectCount,
       COUNT(gps.ProfessorID) AS SupervisionLinks
FROM dbo.Department d
LEFT JOIN dbo.GraduationProject gp ON gp.DepartmentID=d.DepartmentID
LEFT JOIN dbo.GraduationProjectSupervision gps
  ON gps.GraduationProjectID=gp.GraduationProjectID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY d.DepartmentID;

-- Missing / unexpected seed associations (BOTH expected ZERO rows).
SELECT GraduationProjectID, ProfessorID FROM @Expected
EXCEPT
SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision;

SELECT GraduationProjectID, ProfessorID FROM dbo.GraduationProjectSupervision
EXCEPT
SELECT GraduationProjectID, ProfessorID FROM @Expected;

-- Approved column metadata and foreign key metadata.
SELECT c.column_id AS ColumnOrder, c.name AS ColumnName,
       t.name AS DataType, c.is_nullable AS IsNullable
FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
ORDER BY c.column_id;

SELECT fk.name AS ForeignKeyName,
       pc.name AS ParentColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,
       fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.GraduationProjectSupervision',N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
--------------------------
GO
