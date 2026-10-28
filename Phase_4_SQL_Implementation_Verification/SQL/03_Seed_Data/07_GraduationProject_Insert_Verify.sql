-- Extracted from UniversityManagementDB(2).sql; source lines 3637-3943.
USE [UniversityManagementDB];
GO
--Table 07 GraduationProject
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.GraduationProject', N'U') IS NULL
    THROW 51071, 'STOP: dbo.GraduationProject does not exist. Nothing inserted.', 1;

IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
    THROW 51072, 'STOP: dbo.Department does not exist. Nothing inserted.', 1;

-- Exact approved three-column definition.
IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')) <> 3
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND name = N'GraduationProjectID' AND column_id = 1
          AND system_type_id = 56 AND is_nullable = 0
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND name = N'ProjectTitle' AND column_id = 2
          AND system_type_id = 231 AND max_length = 510 AND is_nullable = 0
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND name = N'DepartmentID' AND column_id = 3
          AND system_type_id = 56 AND is_nullable = 0
    )
    OR (SELECT COUNT_BIG(*) FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND type = 'PK') <> 1
    OR NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints kc
        JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id
                                 AND ic.index_id = kc.unique_index_id
        JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND kc.name = N'PK_GraduationProject' AND kc.type = 'PK'
          AND ic.key_ordinal = 1 AND c.name = N'GraduationProjectID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.index_columns ic2
              WHERE ic2.object_id = kc.parent_object_id
                AND ic2.index_id = kc.unique_index_id AND ic2.key_ordinal > 1
          )
    )
    OR (SELECT COUNT_BIG(*) FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')) <> 1
    OR NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
        JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id
                           AND pc.column_id = fkc.parent_column_id
        JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id
                           AND rc.column_id = fkc.referenced_column_id
        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND fk.name = N'FK_GraduationProject_Department'
          AND fk.referenced_object_id = OBJECT_ID(N'dbo.Department', N'U')
          AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
          AND fkc.constraint_column_id = 1
          AND pc.name = N'DepartmentID' AND rc.name = N'DepartmentID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.foreign_key_columns fkc2
              WHERE fkc2.constraint_object_id = fk.object_id
                AND fkc2.constraint_column_id > 1
          )
    )
    OR EXISTS (
        SELECT 1 FROM sys.indexes i
        WHERE i.object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
          AND i.is_unique = 1 AND i.is_primary_key = 0
    )
    THROW 51073, 'STOP: GraduationProject schema or constraints differ from approved definition.', 1;

-- The eight approved parent departments must already be seeded.
IF EXISTS (
    SELECT 1 FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS e(DepartmentID)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Department d WHERE d.DepartmentID = e.DepartmentID
    )
)
    THROW 51074, 'STOP: One or more expected departments (1 to 8) are missing.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- No silent repeat seeding and no removal/replacement of previously approved rows.
    IF EXISTS (SELECT 1 FROM dbo.GraduationProject WITH (UPDLOCK, HOLDLOCK))
        THROW 51075, 'STOP: GraduationProject is not empty. No rows inserted.', 1;

    INSERT INTO dbo.GraduationProject (GraduationProjectID, ProjectTitle, DepartmentID)
    VALUES
        (1001, N'AI-Assisted Student Advising Platform', 1),
        (1002, N'Campus Shuttle Route Optimization System', 1),
        (1003, N'SME Strategic Performance Dashboard', 2),
        (1004, N'University Service Quality Assessment', 2),
        (1005, N'ERP Integration for Campus Services', 3),
        (1006, N'Secure Digital Academic Records Management', 3),
        (1007, N'Smart Campus Energy Monitoring', 4),
        (1008, N'IoT-Based Power Quality Analysis', 4),
        (1009, N'Predictive Maintenance for Campus HVAC', 5),
        (1010, N'Manufacturing Defect Detection Prototype', 5),
        (1011, N'University Timetable Optimization', 6),
        (1012, N'Statistical Modeling of Student Success', 6),
        (1013, N'Solar Panel Performance Measurement', 7),
        (1014, N'Physics Laboratory Sensor Calibration', 7),
        (1015, N'Student Spending and Financial Literacy Study', 8),
        (1016, N'Local Labor Market Skills Demand Analysis', 8);

    IF @@ROWCOUNT <> 16
        THROW 51076, 'STOP: GraduationProject insertion did not affect exactly 16 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.GraduationProject) <> 16
        THROW 51077, 'STOP: GraduationProject total row count is not 16.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.GraduationProject g
        LEFT JOIN dbo.Department d ON d.DepartmentID = g.DepartmentID
        WHERE d.DepartmentID IS NULL
    )
        THROW 51078, 'STOP: Orphan DepartmentID detected; rolling back.', 1;

    COMMIT TRANSACTION;
    PRINT 'GraduationProject: 16 synthetic rows committed. Run separate read-only verification.';
    PRINT 'Student participation and supervision minima are deferred to later dependent-table population.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
------------------------------
---READ-ONLY verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.GraduationProject', N'U') IS NULL
    THROW 51079, 'FAIL: dbo.GraduationProject does not exist.', 1;

DECLARE @Expected TABLE
(
    GraduationProjectID INT NOT NULL PRIMARY KEY,
    ProjectTitle NVARCHAR(255) NOT NULL,
    DepartmentID INT NOT NULL
);
INSERT INTO @Expected (GraduationProjectID, ProjectTitle, DepartmentID)
VALUES
    (1001, N'AI-Assisted Student Advising Platform', 1),
    (1002, N'Campus Shuttle Route Optimization System', 1),
    (1003, N'SME Strategic Performance Dashboard', 2),
    (1004, N'University Service Quality Assessment', 2),
    (1005, N'ERP Integration for Campus Services', 3),
    (1006, N'Secure Digital Academic Records Management', 3),
    (1007, N'Smart Campus Energy Monitoring', 4),
    (1008, N'IoT-Based Power Quality Analysis', 4),
    (1009, N'Predictive Maintenance for Campus HVAC', 5),
    (1010, N'Manufacturing Defect Detection Prototype', 5),
    (1011, N'University Timetable Optimization', 6),
    (1012, N'Statistical Modeling of Student Success', 6),
    (1013, N'Solar Panel Performance Measurement', 7),
    (1014, N'Physics Laboratory Sensor Calibration', 7),
    (1015, N'Student Spending and Financial Literacy Study', 8),
    (1016, N'Local Labor Market Skills Demand Analysis', 8);

-- TEST 1: Exact rows, schema, PK, approved enabled+trusted FK, no extra UNIQUE index.
-- EXPECTED: PASS, ActualRows 16, ExpectedRows 16.
SELECT
    N'GraduationProject: Exact Row Set + Schema + PK + FK' AS VerificationTest,
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.GraduationProject) = 16
       AND NOT EXISTS (
           SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM dbo.GraduationProject
           EXCEPT
           SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM @Expected
       )
       AND NOT EXISTS (
           SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM @Expected
           EXCEPT
           SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM dbo.GraduationProject
       )
       AND (SELECT COUNT_BIG(*) FROM sys.columns
            WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')) = 3
       AND EXISTS (
           SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND name = N'GraduationProjectID' AND column_id = 1
             AND system_type_id = 56 AND is_nullable = 0
       )
       AND EXISTS (
           SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND name = N'ProjectTitle' AND column_id = 2
             AND system_type_id = 231 AND max_length = 510 AND is_nullable = 0
       )
       AND EXISTS (
           SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND name = N'DepartmentID' AND column_id = 3
             AND system_type_id = 56 AND is_nullable = 0
       )
       AND (SELECT COUNT_BIG(*) FROM sys.key_constraints
            WHERE parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
              AND type = 'PK') = 1
       AND EXISTS (
           SELECT 1 FROM sys.key_constraints kc
           JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id
                                    AND ic.index_id = kc.unique_index_id
           JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
           WHERE kc.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND kc.name = N'PK_GraduationProject' AND kc.type = 'PK'
             AND ic.key_ordinal = 1 AND c.name = N'GraduationProjectID'
             AND NOT EXISTS (
                 SELECT 1 FROM sys.index_columns ic2
                 WHERE ic2.object_id = kc.parent_object_id
                   AND ic2.index_id = kc.unique_index_id AND ic2.key_ordinal > 1
             )
       )
       AND (SELECT COUNT_BIG(*) FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')) = 1
       AND EXISTS (
           SELECT 1 FROM sys.foreign_keys fk
           JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
           JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id
                              AND pc.column_id = fkc.parent_column_id
           JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id
                              AND rc.column_id = fkc.referenced_column_id
           WHERE fk.parent_object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND fk.name = N'FK_GraduationProject_Department'
             AND fk.referenced_object_id = OBJECT_ID(N'dbo.Department', N'U')
             AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
             AND fkc.constraint_column_id = 1
             AND pc.name = N'DepartmentID' AND rc.name = N'DepartmentID'
             AND NOT EXISTS (
                 SELECT 1 FROM sys.foreign_key_columns fkc2
                 WHERE fkc2.constraint_object_id = fk.object_id
                   AND fkc2.constraint_column_id > 1
             )
       )
       AND NOT EXISTS (
           SELECT 1 FROM sys.indexes i
           WHERE i.object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
             AND i.is_unique = 1 AND i.is_primary_key = 0
       )
       AND NOT EXISTS (
           SELECT 1 FROM dbo.GraduationProject g
           WHERE g.ProjectTitle IS NULL OR LEN(LTRIM(RTRIM(g.ProjectTitle))) = 0
       )
       AND NOT EXISTS (
           SELECT 1 FROM dbo.GraduationProject g
           LEFT JOIN dbo.Department d ON d.DepartmentID = g.DepartmentID
           WHERE d.DepartmentID IS NULL
       )
      THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.GraduationProject) AS ActualRows,
    CAST(16 AS BIGINT) AS ExpectedRows;

-- TEST 2: Visual listing, EXPECTED 16 rows.
SELECT GraduationProjectID, ProjectTitle, DepartmentID
FROM dbo.GraduationProject
ORDER BY GraduationProjectID;

-- TEST 3: Unexpected or modified project rows, EXPECTED ZERO rows.
SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM dbo.GraduationProject
EXCEPT
SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM @Expected;

-- TEST 4: Missing expected project rows, EXPECTED ZERO rows.
SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM @Expected
EXCEPT
SELECT GraduationProjectID, ProjectTitle, DepartmentID FROM dbo.GraduationProject;

-- TEST 5: Duplicate IDs (PK should prevent this), EXPECTED ZERO rows.
SELECT GraduationProjectID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.GraduationProject
GROUP BY GraduationProjectID
HAVING COUNT_BIG(*) > 1;

-- TEST 6: NULL or blank title, EXPECTED ZERO rows.
SELECT GraduationProjectID, ProjectTitle FROM dbo.GraduationProject
WHERE ProjectTitle IS NULL OR LEN(LTRIM(RTRIM(ProjectTitle))) = 0;

-- TEST 7: Orphan DepartmentID, EXPECTED ZERO rows.
SELECT g.GraduationProjectID, g.DepartmentID
FROM dbo.GraduationProject g
LEFT JOIN dbo.Department d ON d.DepartmentID = g.DepartmentID
WHERE d.DepartmentID IS NULL;

-- TEST 8: Unapproved UNIQUE indexes, EXPECTED ZERO rows.
SELECT i.name AS UnexpectedUniqueIndex, i.is_unique AS IsUnique, i.is_primary_key AS IsPK
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'dbo.GraduationProject', N'U')
  AND i.is_unique = 1 AND i.is_primary_key = 0;

-- TEST 9: Distribution across departments, EXPECTED 8 rows, each ProjectCount = 2.
SELECT d.DepartmentID, d.DepartmentName, COUNT_BIG(g.GraduationProjectID) AS ProjectCount
FROM dbo.Department d
LEFT JOIN dbo.GraduationProject g ON g.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY d.DepartmentID;
GO
------------------------------------
GO
