-- Extracted from UniversityManagementDB(2).sql; source lines 3944-4255.
USE [UniversityManagementDB];
GO
----Table 08 ResearchProject
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
    THROW 51081, 'STOP: dbo.ResearchProject does not exist. No changes made.', 1;
IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
    THROW 51082, 'STOP: dbo.Department does not exist. No changes made.', 1;

-- Exact approved three-column definition and approved relationship.
IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')) <> 3
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'ResearchProjectID' AND column_id = 1
          AND system_type_id = 56 AND is_nullable = 0
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'ProjectTitle' AND column_id = 2
          AND system_type_id = 231 AND max_length = 510 AND is_nullable = 0
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'LeadDepartmentID' AND column_id = 3
          AND system_type_id = 56 AND is_nullable = 0
    )
    OR (SELECT COUNT_BIG(*) FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND type = 'PK') <> 1
    OR NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints AS kc
        JOIN sys.index_columns AS ic
          ON ic.object_id = kc.parent_object_id
         AND ic.index_id = kc.unique_index_id
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND kc.name = N'PK_ResearchProject' AND kc.type = 'PK'
          AND ic.key_ordinal = 1 AND c.name = N'ResearchProjectID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.index_columns AS ic2
              WHERE ic2.object_id = kc.parent_object_id
                AND ic2.index_id = kc.unique_index_id
                AND ic2.key_ordinal > 1
          )
    )
    OR (SELECT COUNT_BIG(*) FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')) <> 1
    OR NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys AS fk
        JOIN sys.foreign_key_columns AS fkc
          ON fkc.constraint_object_id = fk.object_id
        JOIN sys.columns AS pc
          ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
        JOIN sys.columns AS rc
          ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND fk.name = N'FK_ResearchProject_LeadDepartment'
          AND fk.referenced_object_id = OBJECT_ID(N'dbo.Department', N'U')
          AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
          AND fkc.constraint_column_id = 1
          AND pc.name = N'LeadDepartmentID' AND rc.name = N'DepartmentID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.foreign_key_columns AS fkc2
              WHERE fkc2.constraint_object_id = fk.object_id
                AND fkc2.constraint_column_id > 1
          )
    )
    OR EXISTS (
        SELECT 1 FROM sys.indexes AS i
        WHERE i.object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND i.is_unique = 1 AND i.is_primary_key = 0
    )
    THROW 51083, 'STOP: ResearchProject schema/PK/FK mismatch. No changes made.', 1;

-- Ensure the established eight parent departments are available.
IF EXISTS (
    SELECT 1 FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS e(DepartmentID)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Department AS d WHERE d.DepartmentID = e.DepartmentID)
)
    THROW 51084, 'STOP: A required DepartmentID from 1-8 is missing.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Prevent accidental reseeding; hold a serializable range lock until commit.
    IF EXISTS (SELECT 1 FROM dbo.ResearchProject WITH (UPDLOCK, HOLDLOCK))
        THROW 51085, 'STOP: ResearchProject already contains data; no INSERT attempted.', 1;

    INSERT INTO dbo.ResearchProject (ResearchProjectID, ProjectTitle, LeadDepartmentID)
    VALUES
        (2001, N'Explainable AI for Student Retention Analytics', 1),
        (2002, N'Cybersecurity Risk Detection in University Networks', 1),
        (2003, N'Digital Transformation and Institutional Performance', 2),
        (2004, N'Sustainable Supply Chain Management in Higher Education', 2),
        (2005, N'Data Governance Framework for University Systems', 3),
        (2006, N'Enterprise Architecture for Integrated Student Services', 3),
        (2007, N'Smart Grid Demand Forecasting on University Campuses', 4),
        (2008, N'Energy Efficiency Assessment of Building Automation', 4),
        (2009, N'Predictive Maintenance of Laboratory Equipment', 5),
        (2010, N'Life Cycle Assessment of Additive Manufacturing', 5),
        (2011, N'Optimization Algorithms for Academic Resource Allocation', 6),
        (2012, N'Statistical Forecasting of Student Course Demand', 6),
        (2013, N'Photovoltaic Material Performance Under High Heat', 7),
        (2014, N'Experimental Analysis of Low-Cost Optical Sensors', 7),
        (2015, N'Economic Impact of Digital Skills Development', 8),
        (2016, N'Cost-Benefit Analysis of Campus Energy Investments', 8);

    IF @@ROWCOUNT <> 16
        THROW 51086, 'STOP: ResearchProject INSERT did not affect 16 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.ResearchProject) <> 16
        THROW 51087, 'STOP: ResearchProject row count mismatch.', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.ResearchProject AS r
        LEFT JOIN dbo.Department AS d ON d.DepartmentID = r.LeadDepartmentID
        WHERE d.DepartmentID IS NULL
    )
        THROW 51088, 'STOP: ResearchProject orphan LeadDepartmentID detected.', 1;

    COMMIT TRANSACTION;
    PRINT 'ResearchProject: 16 synthetic rows committed. Run read-only verification.';
    PRINT 'Supervision and D-18 collaboration timing checks are deferred.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-------------------------------------------------
----READ ONLY verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
    THROW 51089, 'FAIL: dbo.ResearchProject does not exist.', 1;

DECLARE @Expected TABLE (
    ResearchProjectID INT NOT NULL PRIMARY KEY,
    ProjectTitle NVARCHAR(255) NOT NULL,
    LeadDepartmentID INT NOT NULL
);
INSERT INTO @Expected (ResearchProjectID, ProjectTitle, LeadDepartmentID)
VALUES
        (2001, N'Explainable AI for Student Retention Analytics', 1),
        (2002, N'Cybersecurity Risk Detection in University Networks', 1),
        (2003, N'Digital Transformation and Institutional Performance', 2),
        (2004, N'Sustainable Supply Chain Management in Higher Education', 2),
        (2005, N'Data Governance Framework for University Systems', 3),
        (2006, N'Enterprise Architecture for Integrated Student Services', 3),
        (2007, N'Smart Grid Demand Forecasting on University Campuses', 4),
        (2008, N'Energy Efficiency Assessment of Building Automation', 4),
        (2009, N'Predictive Maintenance of Laboratory Equipment', 5),
        (2010, N'Life Cycle Assessment of Additive Manufacturing', 5),
        (2011, N'Optimization Algorithms for Academic Resource Allocation', 6),
        (2012, N'Statistical Forecasting of Student Course Demand', 6),
        (2013, N'Photovoltaic Material Performance Under High Heat', 7),
        (2014, N'Experimental Analysis of Low-Cost Optical Sensors', 7),
        (2015, N'Economic Impact of Digital Skills Development', 8),
        (2016, N'Cost-Benefit Analysis of Campus Energy Investments', 8);

-- TEST 1: Exact data, schema and PK/FK checks. Expect PASS, 16/16.
SELECT
    N'ResearchProject: Exact Row Set + Schema + PK + FK' AS VerificationTest,
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchProject) = 16
      AND NOT EXISTS (
          SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM dbo.ResearchProject
          EXCEPT
          SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM @Expected
      )
      AND NOT EXISTS (
          SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM @Expected
          EXCEPT
          SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM dbo.ResearchProject
      )
      AND NOT ((SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')) <> 3
      OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'ResearchProjectID' AND column_id = 1
          AND system_type_id = 56 AND is_nullable = 0
    )
      OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'ProjectTitle' AND column_id = 2
          AND system_type_id = 231 AND max_length = 510 AND is_nullable = 0
    )
      OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND name = N'LeadDepartmentID' AND column_id = 3
          AND system_type_id = 56 AND is_nullable = 0
    )
      OR (SELECT COUNT_BIG(*) FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND type = 'PK') <> 1
      OR NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints AS kc
        JOIN sys.index_columns AS ic
          ON ic.object_id = kc.parent_object_id
         AND ic.index_id = kc.unique_index_id
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND kc.name = N'PK_ResearchProject' AND kc.type = 'PK'
          AND ic.key_ordinal = 1 AND c.name = N'ResearchProjectID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.index_columns AS ic2
              WHERE ic2.object_id = kc.parent_object_id
                AND ic2.index_id = kc.unique_index_id
                AND ic2.key_ordinal > 1
          )
    )
      OR (SELECT COUNT_BIG(*) FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')) <> 1
      OR NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys AS fk
        JOIN sys.foreign_key_columns AS fkc
          ON fkc.constraint_object_id = fk.object_id
        JOIN sys.columns AS pc
          ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
        JOIN sys.columns AS rc
          ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND fk.name = N'FK_ResearchProject_LeadDepartment'
          AND fk.referenced_object_id = OBJECT_ID(N'dbo.Department', N'U')
          AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
          AND fkc.constraint_column_id = 1
          AND pc.name = N'LeadDepartmentID' AND rc.name = N'DepartmentID'
          AND NOT EXISTS (
              SELECT 1 FROM sys.foreign_key_columns AS fkc2
              WHERE fkc2.constraint_object_id = fk.object_id
                AND fkc2.constraint_column_id > 1
          )
    )
      OR EXISTS (
        SELECT 1 FROM sys.indexes AS i
        WHERE i.object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
          AND i.is_unique = 1 AND i.is_primary_key = 0
    ))
      AND NOT EXISTS (
          SELECT 1 FROM dbo.ResearchProject AS r
          WHERE r.ProjectTitle IS NULL OR LEN(LTRIM(RTRIM(r.ProjectTitle))) = 0
      )
      AND NOT EXISTS (
          SELECT 1 FROM dbo.ResearchProject AS r
          LEFT JOIN dbo.Department AS d ON d.DepartmentID = r.LeadDepartmentID
          WHERE d.DepartmentID IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.ResearchProject) AS ActualRows,
    CAST(16 AS BIGINT) AS ExpectedRows;

-- TEST 2: Approved project list; expect 16 rows.
SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID
FROM dbo.ResearchProject
ORDER BY ResearchProjectID;

-- TEST 3: Unexpected or modified records; expect zero rows.
SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM dbo.ResearchProject
EXCEPT
SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM @Expected;

-- TEST 4: Missing seed records; expect zero rows.
SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM @Expected
EXCEPT
SELECT ResearchProjectID, ProjectTitle, LeadDepartmentID FROM dbo.ResearchProject;

-- TEST 5: Duplicate ResearchProjectID; expect zero rows.
SELECT ResearchProjectID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.ResearchProject
GROUP BY ResearchProjectID
HAVING COUNT_BIG(*) > 1;

-- TEST 6: Blank or NULL project title; expect zero rows.
SELECT ResearchProjectID, ProjectTitle FROM dbo.ResearchProject
WHERE ProjectTitle IS NULL OR LEN(LTRIM(RTRIM(ProjectTitle))) = 0;

-- TEST 7: Orphan LeadDepartmentID; expect zero rows.
SELECT r.ResearchProjectID, r.LeadDepartmentID
FROM dbo.ResearchProject AS r
LEFT JOIN dbo.Department AS d ON d.DepartmentID = r.LeadDepartmentID
WHERE d.DepartmentID IS NULL;

-- TEST 8: Unauthorized unique index; expect zero rows.
SELECT i.name AS UnexpectedUniqueIndex, i.is_unique AS IsUnique, i.is_primary_key AS IsPK
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'dbo.ResearchProject', N'U')
  AND i.is_unique = 1 AND i.is_primary_key = 0;

-- TEST 9: Distribution; expect 8 rows each ProjectCount=2.
SELECT d.DepartmentID, d.DepartmentName,
       COUNT_BIG(r.ResearchProjectID) AS ProjectCount
FROM dbo.Department AS d
LEFT JOIN dbo.ResearchProject AS r ON r.LeadDepartmentID = d.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY d.DepartmentID;
GO
-------------------------------
GO
