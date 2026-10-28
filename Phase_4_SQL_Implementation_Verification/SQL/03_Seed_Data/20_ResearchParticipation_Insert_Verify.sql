-- Extracted from UniversityManagementDB(2).sql; source lines 8857-9367.
USE [UniversityManagementDB];
GO
--Table 20 — ResearchParticipation
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'tempdb..#ExpectedResearchParticipation') IS NOT NULL
    DROP TABLE #ExpectedResearchParticipation;
CREATE TABLE #ExpectedResearchParticipation
(
    StudentID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    PRIMARY KEY (StudentID, ResearchProjectID)
);

-- Deterministic 8x8 series; 0..63. Target: 80 associations.
;WITH Digits AS
(
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS v(n)
), N AS
(
    SELECT 8*a.n + b.n AS n
    FROM Digits AS a CROSS JOIN Digits AS b
)
INSERT INTO #ExpectedResearchParticipation (StudentID, ResearchProjectID)
SELECT 10001 + n, 2001 + (n % 16)
FROM N WHERE n < 56
UNION ALL
SELECT 10001 + n, 2001 + ((n + 8) % 16)
FROM N WHERE n < 24;

BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    IF DB_NAME() <> N'UniversityManagementDB'
        THROW 52001, 'STOP: Unexpected database.', 1;

    DECLARE @TableID INT = OBJECT_ID(N'dbo.ResearchParticipation', N'U');
    IF @TableID IS NULL OR OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
        THROW 52002, 'STOP: Missing approved target or parent table.', 1;

    -- Approved column structure, types, order and NOT NULL rules.
    IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = @TableID) <> 2
       OR EXISTS
       (
           SELECT 1 FROM sys.columns
           WHERE object_id = @TableID
             AND (is_nullable <> 0 OR is_identity <> 0 OR is_computed <> 0
                  OR default_object_id <> 0)
       )
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.columns c
           WHERE c.object_id=@TableID AND c.column_id=1
             AND c.name=N'StudentID' AND TYPE_NAME(c.user_type_id)=N'int'
             AND c.max_length=4
       )
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.columns c
           WHERE c.object_id=@TableID AND c.column_id=2
             AND c.name=N'ResearchProjectID' AND TYPE_NAME(c.user_type_id)=N'int'
             AND c.max_length=4
       )
        THROW 52003, 'STOP: Columns differ from approved DDL.', 1;

    -- Composite PK: exact name and exact ordered columns.
    IF (SELECT COUNT(*) FROM sys.key_constraints
        WHERE parent_object_id=@TableID AND type='PK') <> 1
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.key_constraints kc
           JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                    AND ic.index_id=kc.unique_index_id
           JOIN sys.columns c ON c.object_id=ic.object_id
                    AND c.column_id=ic.column_id
           WHERE kc.parent_object_id=@TableID AND kc.type='PK'
             AND kc.name=N'PK_ResearchParticipation'
           GROUP BY kc.object_id
           HAVING COUNT(*)=2
              AND SUM(CASE WHEN ic.key_ordinal=1 AND c.name=N'StudentID' THEN 1 ELSE 0 END)=1
              AND SUM(CASE WHEN ic.key_ordinal=2 AND c.name=N'ResearchProjectID' THEN 1 ELSE 0 END)=1
       )
        THROW 52004, 'STOP: Composite primary key does not match approved DDL.', 1;

    -- Both FKs must exist, have the approved mapping, and be enabled/trusted.
    IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@TableID)<>2
       OR (SELECT COUNT(*) FROM sys.foreign_keys f
           JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id
           WHERE f.parent_object_id=@TableID
             AND f.is_disabled=0 AND f.is_not_trusted=0
             AND (SELECT COUNT(*) FROM sys.foreign_key_columns
                  WHERE constraint_object_id=f.object_id)=1
             AND ((f.name=N'FK_ResearchParticipation_Student'
                AND f.referenced_object_id=OBJECT_ID(N'dbo.Student', N'U')
                AND COL_NAME(fc.parent_object_id,fc.parent_column_id)=N'StudentID'
                AND COL_NAME(fc.referenced_object_id,fc.referenced_column_id)=N'StudentID')
              OR (f.name=N'FK_ResearchParticipation_ResearchProject'
                AND f.referenced_object_id=OBJECT_ID(N'dbo.ResearchProject', N'U')
                AND COL_NAME(fc.parent_object_id,fc.parent_column_id)=N'ResearchProjectID'
                AND COL_NAME(fc.referenced_object_id,fc.referenced_column_id)=N'ResearchProjectID'))
          )<>2
        THROW 52005, 'STOP: Approved foreign keys not found or not trusted.', 1;

    IF EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id=@TableID AND is_unique=1 AND is_primary_key=0)
       OR EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@TableID)
       OR EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@TableID)
        THROW 52006, 'STOP: Unexpected UNIQUE/CHECK/DEFAULT constraints.', 1;

    -- Protect the approved 64-student parent baseline, not just total count.
    IF (SELECT COUNT_BIG(*) FROM dbo.Student WITH (HOLDLOCK))<>64
       OR EXISTS
       (
           SELECT StudentID FROM dbo.Student
           EXCEPT
           SELECT 10001 + n
           FROM (SELECT (8*a.n+b.n) AS n
                 FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a(n)
                 CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)) z
       )
       OR EXISTS
       (
           SELECT 10001 + n
           FROM (SELECT (8*a.n+b.n) AS n
                 FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a(n)
                 CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)) z
           EXCEPT SELECT StudentID FROM dbo.Student
       )
        THROW 52007, 'STOP: Student parent baseline differs from IDs 10001..10064.', 1;

    -- Protect the approved 16 ResearchProject IDs.
    IF (SELECT COUNT_BIG(*) FROM dbo.ResearchProject WITH (HOLDLOCK))<>16
       OR EXISTS
       (
           SELECT ResearchProjectID FROM dbo.ResearchProject
           EXCEPT
           SELECT 2001 + 8*a.n + b.n
           FROM (VALUES (0),(1)) a(n)
           CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)
       )
       OR EXISTS
       (
           SELECT 2001 + 8*a.n + b.n
           FROM (VALUES (0),(1)) a(n)
           CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)
           EXCEPT SELECT ResearchProjectID FROM dbo.ResearchProject
       )
        THROW 52008, 'STOP: ResearchProject parent baseline differs from IDs 2001..2016.', 1;

    IF (SELECT COUNT_BIG(*) FROM #ExpectedResearchParticipation)<>80
        THROW 52009, 'STOP: Prepared seed does not contain exactly 80 pairs.', 1;

    IF EXISTS (SELECT 1 FROM dbo.ResearchParticipation WITH (UPDLOCK,HOLDLOCK))
        THROW 52010, 'STOP: ResearchParticipation already contains rows; no INSERT attempted.', 1;

    IF EXISTS (SELECT 1 FROM #ExpectedResearchParticipation e
               LEFT JOIN dbo.Student s ON s.StudentID=e.StudentID
               LEFT JOIN dbo.ResearchProject r ON r.ResearchProjectID=e.ResearchProjectID
               WHERE s.StudentID IS NULL OR r.ResearchProjectID IS NULL)
        THROW 52011, 'STOP: Synthetic associations reference unavailable parent rows.', 1;

    INSERT INTO dbo.ResearchParticipation (StudentID,ResearchProjectID)
    SELECT StudentID,ResearchProjectID
    FROM #ExpectedResearchParticipation;

    IF @@ROWCOUNT<>80
       OR (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation)<>80
        THROW 52012, 'STOP: INSERT row count incorrect; rollback.', 1;

    IF EXISTS
       (SELECT StudentID, ResearchProjectID FROM dbo.ResearchParticipation
        EXCEPT SELECT StudentID, ResearchProjectID FROM #ExpectedResearchParticipation)
       OR EXISTS
       (SELECT StudentID, ResearchProjectID FROM #ExpectedResearchParticipation
        EXCEPT SELECT StudentID, ResearchProjectID FROM dbo.ResearchParticipation)
        THROW 52013, 'STOP: Exact row-set mismatch; rollback.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    PRINT 'SUCCESS: 80 ResearchParticipation rows inserted and committed.';
    SELECT COUNT_BIG(*) AS ActualRows,
           CONVERT(BIGINT,80) AS ExpectedRows,
           N'INSERT COMMITTED' AS InsertResult
    FROM dbo.ResearchParticipation;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
DROP TABLE #ExpectedResearchParticipation;
GO
------------------------------
--READ-ONLY verification against the exact deterministic seed
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF DB_NAME()<>N'UniversityManagementDB'
    THROW 52021, 'STOP: Unexpected database.', 1;
IF OBJECT_ID(N'dbo.ResearchParticipation',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
   OR OBJECT_ID(N'dbo.ResearchProject',N'U') IS NULL
    THROW 52022, 'STOP: Required approved tables are missing.', 1;

IF OBJECT_ID(N'tempdb..#ExpectedResearchParticipation') IS NOT NULL
    DROP TABLE #ExpectedResearchParticipation;
IF OBJECT_ID(N'tempdb..#ResearchParticipationChecks') IS NOT NULL
    DROP TABLE #ResearchParticipationChecks;

CREATE TABLE #ExpectedResearchParticipation
(
    StudentID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    PRIMARY KEY (StudentID,ResearchProjectID)
);

-- Deterministic 8x8 series; 0..63. Target: 80 associations.
;WITH Digits AS
(
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS v(n)
), N AS
(
    SELECT 8*a.n + b.n AS n
    FROM Digits AS a CROSS JOIN Digits AS b
)
INSERT INTO #ExpectedResearchParticipation (StudentID, ResearchProjectID)
SELECT 10001 + n, 2001 + (n % 16)
FROM N WHERE n < 56
UNION ALL
SELECT 10001 + n, 2001 + ((n + 8) % 16)
FROM N WHERE n < 24;

CREATE TABLE #ResearchParticipationChecks
(
    CheckID INT NOT NULL PRIMARY KEY,
    Item NVARCHAR(220) NOT NULL,
    Result VARCHAR(4) NOT NULL
);

DECLARE @oid INT = OBJECT_ID(N'dbo.ResearchParticipation',N'U');

-- 01: exactly two native INT NOT NULL columns, approved order and no extra properties.
INSERT INTO #ResearchParticipationChecks VALUES
(1,N'Exactly two approved INT NOT NULL columns in order; no IDENTITY/computed/default',
 CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id=@oid)=2
      AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid
                      AND (is_nullable<>0 OR is_identity<>0 OR is_computed<>0
                           OR default_object_id<>0))
      AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=1
                  AND name=N'StudentID' AND TYPE_NAME(user_type_id)=N'int' AND max_length=4)
      AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=2
                  AND name=N'ResearchProjectID' AND TYPE_NAME(user_type_id)=N'int' AND max_length=4)
      THEN 'PASS' ELSE 'FAIL' END);

-- 02: Exact composite PK name, two ordered key components, no extras.
INSERT INTO #ResearchParticipationChecks VALUES
(2,N'Approved composite PK PK_ResearchParticipation(StudentID,ResearchProjectID)',
 CASE WHEN (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@oid AND type='PK')=1
      AND EXISTS (SELECT 1 FROM sys.key_constraints kc
                  JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                      AND ic.index_id=kc.unique_index_id
                  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
                  WHERE kc.parent_object_id=@oid AND kc.type='PK' AND kc.name=N'PK_ResearchParticipation'
                  GROUP BY kc.object_id
                  HAVING COUNT(*)=2
                     AND SUM(CASE WHEN ic.key_ordinal=1 AND c.name=N'StudentID' THEN 1 ELSE 0 END)=1
                     AND SUM(CASE WHEN ic.key_ordinal=2 AND c.name=N'ResearchProjectID' THEN 1 ELSE 0 END)=1)
      THEN 'PASS' ELSE 'FAIL' END);

-- 03: Exactly two FKs, the approved names and mappings, each enabled/trusted.
INSERT INTO #ResearchParticipationChecks VALUES
(3,N'Exactly two approved enabled/trusted FKs to Student and ResearchProject',
 CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid)=2
       AND (SELECT COUNT(*) FROM sys.foreign_keys f
             JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id
             WHERE f.parent_object_id=@oid AND f.is_disabled=0 AND f.is_not_trusted=0
             AND (SELECT COUNT(*) FROM sys.foreign_key_columns
                  WHERE constraint_object_id=f.object_id)=1
             AND ((f.name=N'FK_ResearchParticipation_Student'
                AND f.referenced_object_id=OBJECT_ID(N'dbo.Student',N'U')
                AND COL_NAME(fc.parent_object_id,fc.parent_column_id)=N'StudentID'
                AND COL_NAME(fc.referenced_object_id,fc.referenced_column_id)=N'StudentID')
              OR (f.name=N'FK_ResearchParticipation_ResearchProject'
                AND f.referenced_object_id=OBJECT_ID(N'dbo.ResearchProject',N'U')
                AND COL_NAME(fc.parent_object_id,fc.parent_column_id)=N'ResearchProjectID'
                AND COL_NAME(fc.referenced_object_id,fc.referenced_column_id)=N'ResearchProjectID')))=2
      THEN 'PASS' ELSE 'FAIL' END);

-- 04: Unique index only for the PK.
INSERT INTO #ResearchParticipationChecks VALUES
(4,N'No extra or unapproved UNIQUE indexes or UNIQUE constraints',
 CASE WHEN NOT EXISTS (SELECT 1 FROM sys.indexes
                       WHERE object_id=@oid AND is_unique=1 AND is_primary_key=0)
      THEN 'PASS' ELSE 'FAIL' END);

-- 05: No extra check/default constraints.
INSERT INTO #ResearchParticipationChecks VALUES
(5,N'No extra CHECK or DEFAULT constraints',
 CASE WHEN NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid)
       AND NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@oid)
      THEN 'PASS' ELSE 'FAIL' END);

-- 06: Student baseline verified by exact ID set.
INSERT INTO #ResearchParticipationChecks VALUES
(6,N'Parent Student exact baseline: 64 IDs 10001..10064',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64
       AND NOT EXISTS
       (SELECT StudentID FROM dbo.Student
        EXCEPT SELECT 10001+(8*a.n+b.n)
               FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a(n)
               CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n))
       AND NOT EXISTS
       (SELECT 10001+(8*a.n+b.n)
        FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) a(n)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)
        EXCEPT SELECT StudentID FROM dbo.Student)
      THEN 'PASS' ELSE 'FAIL' END);

-- 07: Project baseline verified by exact ID set.
INSERT INTO #ResearchParticipationChecks VALUES
(7,N'Parent ResearchProject exact baseline: 16 IDs 2001..2016',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchProject)=16
       AND NOT EXISTS
       (SELECT ResearchProjectID FROM dbo.ResearchProject
        EXCEPT SELECT 2001+8*a.n+b.n
               FROM (VALUES (0),(1)) a(n)
               CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n))
       AND NOT EXISTS
       (SELECT 2001+8*a.n+b.n
        FROM (VALUES (0),(1)) a(n)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) b(n)
        EXCEPT SELECT ResearchProjectID FROM dbo.ResearchProject)
      THEN 'PASS' ELSE 'FAIL' END);

-- 08: Exact seed count.
INSERT INTO #ResearchParticipationChecks VALUES
(8,N'Expected deterministic seed contains exactly 80 distinct pairs',
 CASE WHEN (SELECT COUNT_BIG(*) FROM #ExpectedResearchParticipation)=80
      THEN 'PASS' ELSE 'FAIL' END);

-- 09: Exact row count in target.
INSERT INTO #ResearchParticipationChecks VALUES
(9,N'Actual ResearchParticipation has exactly 80 rows',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation)=80
      THEN 'PASS' ELSE 'FAIL' END);

-- 10: exact set match in BOTH directions. PK also prevents duplicates.
INSERT INTO #ResearchParticipationChecks VALUES
(10,N'Exact 80-row set: no missing, extra or altered Student/Project pairs',
 CASE WHEN NOT EXISTS
        (SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation
         EXCEPT SELECT StudentID,ResearchProjectID FROM #ExpectedResearchParticipation)
       AND NOT EXISTS
        (SELECT StudentID,ResearchProjectID FROM #ExpectedResearchParticipation
         EXCEPT SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation)
      THEN 'PASS' ELSE 'FAIL' END);

-- 11: Referenced Students/ResearchProjects exist.
INSERT INTO #ResearchParticipationChecks VALUES
(11,N'No orphan associations against either parent',
 CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchParticipation rp
                       LEFT JOIN dbo.Student s ON s.StudentID=rp.StudentID
                       LEFT JOIN dbo.ResearchProject r ON r.ResearchProjectID=rp.ResearchProjectID
                       WHERE s.StudentID IS NULL OR r.ResearchProjectID IS NULL)
      THEN 'PASS' ELSE 'FAIL' END);

-- 12: No duplicate pairs.
INSERT INTO #ResearchParticipationChecks VALUES
(12,N'No duplicate StudentID/ResearchProjectID pairs',
 CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchParticipation
                       GROUP BY StudentID,ResearchProjectID HAVING COUNT_BIG(*)>1)
      THEN 'PASS' ELSE 'FAIL' END);

-- 13: each of 16 projects has five members.
INSERT INTO #ResearchParticipationChecks VALUES
(13,N'Exactly five participants in each of all 16 research projects',
 CASE WHEN (SELECT COUNT(*) FROM dbo.ResearchProject)=16
       AND NOT EXISTS (SELECT 1 FROM dbo.ResearchProject r
            LEFT JOIN dbo.ResearchParticipation rp ON rp.ResearchProjectID=r.ResearchProjectID
            GROUP BY r.ResearchProjectID HAVING COUNT_BIG(rp.StudentID)<>5)
      THEN 'PASS' ELSE 'FAIL' END);

-- 14: 56 distinct participating students.
INSERT INTO #ResearchParticipationChecks VALUES
(14,N'Exactly 56 students have at least one research participation',
 CASE WHEN (SELECT COUNT_BIG(DISTINCT StudentID) FROM dbo.ResearchParticipation)=56
      THEN 'PASS' ELSE 'FAIL' END);

-- 15: 24 students in exactly two projects.
INSERT INTO #ResearchParticipationChecks VALUES
(15,N'Exactly 24 students participate in two research projects',
 CASE WHEN (SELECT COUNT_BIG(*) FROM
            (SELECT StudentID FROM dbo.ResearchParticipation
             GROUP BY StudentID HAVING COUNT_BIG(*)=2) q)=24
      THEN 'PASS' ELSE 'FAIL' END);

-- 16: 32 students in exactly one project.
INSERT INTO #ResearchParticipationChecks VALUES
(16,N'Exactly 32 students participate in one research project',
 CASE WHEN (SELECT COUNT_BIG(*) FROM
            (SELECT StudentID FROM dbo.ResearchParticipation
             GROUP BY StudentID HAVING COUNT_BIG(*)=1) q)=32
      THEN 'PASS' ELSE 'FAIL' END);

-- 17: eight students have no participation; permitted by approved model.
INSERT INTO #ResearchParticipationChecks VALUES
(17,N'Exactly eight students do not participate in research',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student s
             WHERE NOT EXISTS(SELECT 1 FROM dbo.ResearchParticipation rp
                              WHERE rp.StudentID=s.StudentID))=8
      THEN 'PASS' ELSE 'FAIL' END);

-- 18: Demonstrates multi-project participation crossing lead-department areas.
INSERT INTO #ResearchParticipationChecks VALUES
(18,N'All 24 two-project students participate across two lead departments',
 CASE WHEN (SELECT COUNT_BIG(*) FROM
            (SELECT rp.StudentID FROM dbo.ResearchParticipation rp
             JOIN dbo.ResearchProject r ON r.ResearchProjectID=rp.ResearchProjectID
             GROUP BY rp.StudentID
             HAVING COUNT_BIG(*)=2 AND COUNT(DISTINCT r.LeadDepartmentID)=2) q)=24
      THEN 'PASS' ELSE 'FAIL' END);

-- Result 1: official consolidated verification gate.
SELECT N'ResearchParticipation: Exact Row Set + Schema + PK + FK' AS VerificationTest,
       CASE WHEN EXISTS (SELECT 1 FROM #ResearchParticipationChecks WHERE Result='FAIL')
            THEN 'FAIL' ELSE 'PASS' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation) AS ActualRows,
       CONVERT(BIGINT,80) AS ExpectedRows,
       (SELECT COUNT(*) FROM #ResearchParticipationChecks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM #ResearchParticipationChecks WHERE Result='FAIL') AS FailedChecks;

-- Result 2: all checks including failures, if any.
SELECT CheckID,Item,Result FROM #ResearchParticipationChecks ORDER BY CheckID;

-- Result 3: student/project associations with joined names.
SELECT TOP (24) rp.StudentID, s.[Name] AS StudentName,
       rp.ResearchProjectID, r.ProjectTitle, r.LeadDepartmentID
FROM dbo.ResearchParticipation rp
JOIN dbo.Student s ON s.StudentID=rp.StudentID
JOIN dbo.ResearchProject r ON r.ResearchProjectID=rp.ResearchProjectID
ORDER BY rp.StudentID,rp.ResearchProjectID;

-- Result 4: distribution across research projects, expected 5 for each.
SELECT r.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID,
       COUNT(rp.StudentID) AS ParticipationCount
FROM dbo.ResearchProject r
LEFT JOIN dbo.ResearchParticipation rp ON rp.ResearchProjectID=r.ResearchProjectID
GROUP BY r.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID
ORDER BY r.ResearchProjectID;

-- Result 5: distribution by student participation count, expected (0:8,1:32,2:24).
;WITH PerStudent AS
(
  SELECT s.StudentID,COUNT_BIG(rp.ResearchProjectID) AS ProjectCount
  FROM dbo.Student s LEFT JOIN dbo.ResearchParticipation rp ON rp.StudentID=s.StudentID
  GROUP BY s.StudentID
)
SELECT ProjectCount,COUNT_BIG(*) AS StudentCount
FROM PerStudent GROUP BY ProjectCount ORDER BY ProjectCount;

-- Result 6: orphan scan - expected zero rows.
SELECT rp.StudentID,rp.ResearchProjectID
FROM dbo.ResearchParticipation rp
LEFT JOIN dbo.Student s ON s.StudentID=rp.StudentID
LEFT JOIN dbo.ResearchProject r ON r.ResearchProjectID=rp.ResearchProjectID
WHERE s.StudentID IS NULL OR r.ResearchProjectID IS NULL;

-- Result 7: exact-set mismatch - expected zero rows.
SELECT N'Unexpected actual pair' AS Mismatch,x.StudentID,x.ResearchProjectID
FROM (SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation
      EXCEPT SELECT StudentID,ResearchProjectID FROM #ExpectedResearchParticipation) x
UNION ALL
SELECT N'Missing expected pair',x.StudentID,x.ResearchProjectID
FROM (SELECT StudentID,ResearchProjectID FROM #ExpectedResearchParticipation
      EXCEPT SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation) x;

-- Result 8: approved physical columns.
SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,
       TYPE_NAME(c.user_type_id) AS DataType,c.max_length AS LengthBytes,
       c.is_nullable AS IsNullable,c.is_identity AS IsIdentity
FROM sys.columns c WHERE c.object_id=@oid ORDER BY c.column_id;

-- Result 9: ordered PK columns.
SELECT kc.name AS PrimaryKeyName,c.name AS PrimaryKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
    AND ic.index_id=kc.unique_index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE kc.parent_object_id=@oid AND kc.type='PK'
ORDER BY ic.key_ordinal;

-- Result 10: approved foreign keys and trusted status.
SELECT f.name AS ForeignKeyName,
       COL_NAME(fc.parent_object_id,fc.parent_column_id) AS ParentColumn,
       OBJECT_NAME(f.referenced_object_id) AS ReferencedTable,
       COL_NAME(fc.referenced_object_id,fc.referenced_column_id) AS ReferencedColumn,
       f.is_disabled AS IsDisabled,f.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id
WHERE f.parent_object_id=@oid ORDER BY f.name;

DROP TABLE #ResearchParticipationChecks;
DROP TABLE #ExpectedResearchParticipation;
GO
-----------------------------------
GO
