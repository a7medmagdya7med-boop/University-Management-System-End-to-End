-- Extracted from UniversityManagementDB(2).sql; source lines 6290-6711.
USE [UniversityManagementDB];
GO
--Table 14 — ResearchProjectSupervision
--Phase4_14_Insert_ResearchProjectSupervision
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U') IS NULL
        THROW 51014, 'STOP: ResearchProjectSupervision table is missing.', 1;
    IF OBJECT_ID(N'dbo.ResearchProject', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Professor', N'U') IS NULL
        THROW 51015, 'STOP: Required parent table is missing.', 1;

    -- Safety: refuse if target is already populated, never overwrite or append blindly.
    IF EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision WITH (UPDLOCK, HOLDLOCK))
        THROW 51016, 'STOP: Target table is not empty. No rows inserted.', 1;

    -- Schema must match approved DDL exactly: two INT NOT NULL columns.
    IF (SELECT COUNT(*) FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')) <> 2
        OR (SELECT COUNT(*) FROM sys.columns
            WHERE object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
              AND ((column_id = 1 AND name = N'ResearchProjectID' AND system_type_id = 56 AND is_nullable = 0)
                OR (column_id = 2 AND name = N'ProfessorID' AND system_type_id = 56 AND is_nullable = 0))) <> 2
        THROW 51017, 'STOP: Target columns differ from approved DDL.', 1;

    -- Parent baseline: do not change previously approved data.
    IF (SELECT COUNT_BIG(*) FROM dbo.ResearchProject) <> 16
       OR (SELECT COUNT_BIG(*) FROM dbo.Professor) <> 32
       OR (SELECT COUNT_BIG(*) FROM dbo.Department) <> 8
        THROW 51018, 'STOP: Approved parent table row-count baseline differs.', 1;

DECLARE @Expected TABLE
(
    ResearchProjectID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (ResearchProjectID, ProfessorID)
);

INSERT INTO @Expected (ResearchProjectID, ProfessorID)
VALUES
    (2001, 101),
    (2001, 102),
    (2002, 103),
    (2003, 201),
    (2003, 202),
    (2004, 203),
    (2005, 301),
    (2005, 302),
    (2006, 303),
    (2007, 401),
    (2007, 402),
    (2008, 403),
    (2009, 501),
    (2009, 502),
    (2010, 503),
    (2011, 601),
    (2011, 602),
    (2012, 603),
    (2013, 701),
    (2013, 702),
    (2014, 703),
    (2015, 801),
    (2015, 802),
    (2016, 803);

    IF (SELECT COUNT(*) FROM @Expected) <> 24
       OR (SELECT COUNT(DISTINCT ResearchProjectID) FROM @Expected) <> 16
       OR (SELECT COUNT(DISTINCT ProfessorID) FROM @Expected) <> 24
        THROW 51019, 'STOP: Seed data internal count mismatch.', 1;

    IF EXISTS (SELECT e.ResearchProjectID FROM @Expected AS e
               LEFT JOIN dbo.ResearchProject AS r ON r.ResearchProjectID = e.ResearchProjectID
               WHERE r.ResearchProjectID IS NULL)
       OR EXISTS (SELECT e.ProfessorID FROM @Expected AS e
                  LEFT JOIN dbo.Professor AS p ON p.ProfessorID = e.ProfessorID
                  WHERE p.ProfessorID IS NULL)
        THROW 51020, 'STOP: An approved parent ResearchProjectID or ProfessorID is missing.', 1;

    -- Seed design only: sampled professors belong to each project's lead department.
    -- The approved relational model DOES NOT generally forbid cross-department supervisors.
    IF EXISTS
    (
        SELECT 1 FROM @Expected AS e
        JOIN dbo.ResearchProject AS r ON r.ResearchProjectID = e.ResearchProjectID
        JOIN dbo.Professor AS p ON p.ProfessorID = e.ProfessorID
        WHERE p.DepartmentID <> r.LeadDepartmentID
    )
        THROW 51021, 'STOP: Seed assignment is inconsistent with proposed same-department sample.', 1;

    -- Ensure the target's original FK constraints remain enabled and trusted.
    IF (SELECT COUNT(*) FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')) <> 2
       OR EXISTS (SELECT 1 FROM sys.foreign_keys
                  WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
                    AND (is_disabled = 1 OR is_not_trusted = 1))
        THROW 51022, 'STOP: FK count, enabled state, or trust differs from approved schema.', 1;

    -- PK must be exactly (ResearchProjectID, ProfessorID), in this order.
    IF (SELECT COUNT(*) FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
          AND type = 'PK') <> 1
       OR (SELECT COUNT(*) FROM sys.key_constraints AS kc
           JOIN sys.index_columns AS ic
             ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
           WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
             AND kc.type = 'PK' AND ic.key_ordinal > 0) <> 2
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.key_constraints AS kc
           JOIN sys.index_columns AS ic
             ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
           JOIN sys.columns AS c
             ON c.object_id = ic.object_id AND c.column_id = ic.column_id
           WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
             AND kc.type = 'PK' AND ic.key_ordinal = 1 AND c.name = N'ResearchProjectID'
       )
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.key_constraints AS kc
           JOIN sys.index_columns AS ic
             ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
           JOIN sys.columns AS c
             ON c.object_id = ic.object_id AND c.column_id = ic.column_id
           WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U')
             AND kc.type = 'PK' AND ic.key_ordinal = 2 AND c.name = N'ProfessorID'
       )
        THROW 51023, 'STOP: Approved composite primary key differs.', 1;

    INSERT INTO dbo.ResearchProjectSupervision (ResearchProjectID, ProfessorID)
    SELECT ResearchProjectID, ProfessorID
    FROM @Expected;

    IF @@ROWCOUNT <> 24
        THROW 51024, 'STOP: Inserted row count differs from 24.', 1;

    -- Exact-row safety check BEFORE commit (catches unexpected data changes/triggers).
    IF (SELECT COUNT_BIG(*) FROM dbo.ResearchProjectSupervision) <> 24
       OR EXISTS
       (
           SELECT ResearchProjectID, ProfessorID FROM @Expected
           EXCEPT
           SELECT ResearchProjectID, ProfessorID FROM dbo.ResearchProjectSupervision
       )
       OR EXISTS
       (
           SELECT ResearchProjectID, ProfessorID FROM dbo.ResearchProjectSupervision
           EXCEPT
           SELECT ResearchProjectID, ProfessorID FROM @Expected
       )
        THROW 51025, 'STOP: Post-insert exact-row verification failed. Rolling back.', 1;

    -- Minimum one research supervisor per approved research project.
    IF EXISTS
    (
        SELECT 1 FROM dbo.ResearchProject AS r
        WHERE NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision AS s
                          WHERE s.ResearchProjectID = r.ResearchProjectID)
    )
        THROW 51026, 'STOP: At least one research project has no supervisor.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 24 ResearchProjectSupervision rows inserted and committed.';
    SELECT COUNT_BIG(*) AS ActualRows, 24 AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.ResearchProjectSupervision;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
-----------------------
---Phase4_14_Verify_ResearchProjectSupervision
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U') IS NULL
BEGIN
    SELECT 'ResearchProjectSupervision: Exact Row Set + Schema + PK + FK' AS VerificationTest,
           'FAIL' AS VerificationResult,
           CAST(0 AS BIGINT) AS ActualRows, 24 AS ExpectedRows,
           1 AS ChecksEvaluated, 1 AS FailedChecks;
    RETURN;
END;

DECLARE @Expected TABLE
(
    ResearchProjectID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (ResearchProjectID, ProfessorID)
);

INSERT INTO @Expected (ResearchProjectID, ProfessorID)
VALUES
    (2001, 101),
    (2001, 102),
    (2002, 103),
    (2003, 201),
    (2003, 202),
    (2004, 203),
    (2005, 301),
    (2005, 302),
    (2006, 303),
    (2007, 401),
    (2007, 402),
    (2008, 403),
    (2009, 501),
    (2009, 502),
    (2010, 503),
    (2011, 601),
    (2011, 602),
    (2012, 603),
    (2013, 701),
    (2013, 702),
    (2014, 703),
    (2015, 801),
    (2015, 802),
    (2016, 803);

DECLARE @Checks TABLE
(
    CheckID INT NOT NULL PRIMARY KEY,
    Item NVARCHAR(230) NOT NULL,
    Result VARCHAR(4) NOT NULL
);

DECLARE @TargetID INT = OBJECT_ID(N'dbo.ResearchProjectSupervision', N'U');

-- Capture actual foreign-key mappings and trust state.
DECLARE @ActualFK TABLE
(
    ForeignKeyName SYSNAME NOT NULL,
    ParentColumn SYSNAME NOT NULL,
    ReferencedTable SYSNAME NOT NULL,
    ReferencedColumn SYSNAME NOT NULL,
    IsDisabled BIT NOT NULL,
    IsNotTrusted BIT NOT NULL,
    ColumnOrdinal INT NOT NULL
);
INSERT INTO @ActualFK
SELECT fk.name, pc.name, OBJECT_NAME(fk.referenced_object_id), rc.name,
       fk.is_disabled, fk.is_not_trusted, fkc.constraint_column_id
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns AS pc ON pc.object_id = fkc.parent_object_id
                          AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc ON rc.object_id = fkc.referenced_object_id
                          AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = @TargetID;

INSERT INTO @Checks VALUES
(1, N'Table dbo.ResearchProjectSupervision exists',
    CASE WHEN @TargetID IS NOT NULL THEN 'PASS' ELSE 'FAIL' END),
(2, N'Exactly two approved INT NOT NULL columns in correct order',
    CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id = @TargetID) = 2
         AND (SELECT COUNT(*) FROM sys.columns WHERE object_id = @TargetID
             AND ((column_id=1 AND name=N'ResearchProjectID' AND system_type_id=56 AND is_nullable=0)
               OR (column_id=2 AND name=N'ProfessorID' AND system_type_id=56 AND is_nullable=0)))=2
         THEN 'PASS' ELSE 'FAIL' END),
(3, N'Composite PK exactly (ResearchProjectID, ProfessorID) in approved order',
    CASE WHEN (SELECT COUNT(*) FROM sys.key_constraints
               WHERE parent_object_id=@TargetID AND type='PK')=1
         AND (SELECT COUNT(*) FROM sys.key_constraints kc
              JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
              WHERE kc.parent_object_id=@TargetID AND kc.type='PK' AND ic.key_ordinal>0)=2
         AND EXISTS (SELECT 1 FROM sys.key_constraints kc
                     JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
                     JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
                     WHERE kc.parent_object_id=@TargetID AND kc.type='PK'
                           AND ic.key_ordinal=1 AND c.name=N'ResearchProjectID')
         AND EXISTS (SELECT 1 FROM sys.key_constraints kc
                     JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
                     JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
                     WHERE kc.parent_object_id=@TargetID AND kc.type='PK'
                           AND ic.key_ordinal=2 AND c.name=N'ProfessorID')
         THEN 'PASS' ELSE 'FAIL' END),
(4, N'Exactly two approved FKs, correct column mapping and enabled/trusted',
    CASE WHEN (SELECT COUNT(*) FROM @ActualFK)=2
         AND EXISTS (SELECT 1 FROM @ActualFK
                     WHERE ForeignKeyName=N'FK_ResearchProjectSupervision_ResearchProject'
                       AND ParentColumn=N'ResearchProjectID' AND ReferencedTable=N'ResearchProject'
                       AND ReferencedColumn=N'ResearchProjectID' AND ColumnOrdinal=1
                       AND IsDisabled=0 AND IsNotTrusted=0)
         AND EXISTS (SELECT 1 FROM @ActualFK
                     WHERE ForeignKeyName=N'FK_ResearchProjectSupervision_Professor'
                       AND ParentColumn=N'ProfessorID' AND ReferencedTable=N'Professor'
                       AND ReferencedColumn=N'ProfessorID' AND ColumnOrdinal=1
                       AND IsDisabled=0 AND IsNotTrusted=0)
         THEN 'PASS' ELSE 'FAIL' END),
(5, N'No extra UNIQUE indexes or UNIQUE constraints beyond the PK',
    CASE WHEN NOT EXISTS (SELECT 1 FROM sys.indexes
                          WHERE object_id=@TargetID AND is_unique=1 AND is_primary_key=0)
         THEN 'PASS' ELSE 'FAIL' END),
(6, N'Parent table baseline: 16 research projects, 32 professors and 8 departments',
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchProject)=16
           AND (SELECT COUNT_BIG(*) FROM dbo.Professor)=32
           AND (SELECT COUNT_BIG(*) FROM dbo.Department)=8
         THEN 'PASS' ELSE 'FAIL' END),
(7, N'Expected seed: 24 relationships; 16 distinct projects; 24 distinct professors',
    CASE WHEN (SELECT COUNT(*) FROM @Expected)=24
           AND (SELECT COUNT(DISTINCT ResearchProjectID) FROM @Expected)=16
           AND (SELECT COUNT(DISTINCT ProfessorID) FROM @Expected)=24
         THEN 'PASS' ELSE 'FAIL' END),
(8, N'Exact approved seed: no missing, extra or altered supervision rows',
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchProjectSupervision)=24
         AND NOT EXISTS (SELECT ResearchProjectID,ProfessorID FROM @Expected
                         EXCEPT SELECT ResearchProjectID,ProfessorID FROM dbo.ResearchProjectSupervision)
         AND NOT EXISTS (SELECT ResearchProjectID,ProfessorID FROM dbo.ResearchProjectSupervision
                         EXCEPT SELECT ResearchProjectID,ProfessorID FROM @Expected)
         THEN 'PASS' ELSE 'FAIL' END),
(9, N'No invalid parent references in approved seed',
    CASE WHEN NOT EXISTS (SELECT 1 FROM @Expected e LEFT JOIN dbo.ResearchProject r
                          ON e.ResearchProjectID=r.ResearchProjectID WHERE r.ResearchProjectID IS NULL)
           AND NOT EXISTS (SELECT 1 FROM @Expected e LEFT JOIN dbo.Professor p
                          ON e.ProfessorID=p.ProfessorID WHERE p.ProfessorID IS NULL)
         THEN 'PASS' ELSE 'FAIL' END),
(10, N'No orphan ResearchProject / Professor references in actual rows',
    CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision s
                          LEFT JOIN dbo.ResearchProject r ON s.ResearchProjectID=r.ResearchProjectID
                          LEFT JOIN dbo.Professor p ON s.ProfessorID=p.ProfessorID
                          WHERE r.ResearchProjectID IS NULL OR p.ProfessorID IS NULL)
         THEN 'PASS' ELSE 'FAIL' END),
(11, N'Every research project has at least one supervisor',
    CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchProject r
                          WHERE NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision s
                                            WHERE s.ResearchProjectID=r.ResearchProjectID))
         THEN 'PASS' ELSE 'FAIL' END),
(12, N'Seed distribution: eight projects with 1 supervisor and eight with 2',
    CASE WHEN (SELECT COUNT(*) FROM (SELECT ResearchProjectID, COUNT(*) AS N
                                    FROM dbo.ResearchProjectSupervision GROUP BY ResearchProjectID) x WHERE N=1)=8
         AND (SELECT COUNT(*) FROM (SELECT ResearchProjectID, COUNT(*) AS N
                                    FROM dbo.ResearchProjectSupervision GROUP BY ResearchProjectID) x WHERE N=2)=8
         THEN 'PASS' ELSE 'FAIL' END),
(13, N'Seed distribution: 8 departments, each 2 research projects and 3 supervision links',
    CASE WHEN (SELECT COUNT(*) FROM dbo.Department d)=8
         AND NOT EXISTS (SELECT 1 FROM dbo.Department d
                         CROSS APPLY
                         (SELECT COUNT(*) AS ProjectCount FROM dbo.ResearchProject r
                          WHERE r.LeadDepartmentID=d.DepartmentID) a
                         CROSS APPLY
                         (SELECT COUNT(*) AS LinkCount FROM dbo.ResearchProjectSupervision s
                          JOIN dbo.ResearchProject r ON r.ResearchProjectID=s.ResearchProjectID
                          WHERE r.LeadDepartmentID=d.DepartmentID) b
                         WHERE a.ProjectCount<>2 OR b.LinkCount<>3)
         THEN 'PASS' ELSE 'FAIL' END),
(14, N'No repeated (ResearchProjectID,ProfessorID) association',
    CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision
                          GROUP BY ResearchProjectID,ProfessorID HAVING COUNT_BIG(*)>1)
         THEN 'PASS' ELSE 'FAIL' END),
(15, N'Seed-specific project and supervisor departmental matching',
    CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision s
                          JOIN dbo.ResearchProject r ON r.ResearchProjectID=s.ResearchProjectID
                          JOIN dbo.Professor p ON p.ProfessorID=s.ProfessorID
                          WHERE r.LeadDepartmentID<>p.DepartmentID)
         THEN 'PASS' ELSE 'FAIL' END);

-- Summary, individual checks, physical data, and diagnostic views.
SELECT 'ResearchProjectSupervision: Exact Row Set + Schema + PK + FK' AS VerificationTest,
       CASE WHEN NOT EXISTS (SELECT 1 FROM @Checks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END
            AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.ResearchProjectSupervision) AS ActualRows,
       24 AS ExpectedRows,
       (SELECT COUNT(*) FROM @Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM @Checks WHERE Result='FAIL') AS FailedChecks;

SELECT CheckID, Item, Result FROM @Checks ORDER BY CheckID;

SELECT s.ResearchProjectID, r.ProjectTitle, r.LeadDepartmentID,
       s.ProfessorID, p.[Name] AS SupervisorName, p.DepartmentID AS ProfessorDepartmentID
FROM dbo.ResearchProjectSupervision s
JOIN dbo.ResearchProject r ON r.ResearchProjectID=s.ResearchProjectID
JOIN dbo.Professor p ON p.ProfessorID=s.ProfessorID
ORDER BY s.ResearchProjectID, s.ProfessorID;

SELECT r.ResearchProjectID, r.ProjectTitle, r.LeadDepartmentID,
       COUNT(s.ProfessorID) AS SupervisorCount
FROM dbo.ResearchProject r
LEFT JOIN dbo.ResearchProjectSupervision s ON s.ResearchProjectID=r.ResearchProjectID
GROUP BY r.ResearchProjectID, r.ProjectTitle, r.LeadDepartmentID
ORDER BY r.ResearchProjectID;

SELECT d.DepartmentID, d.DepartmentName,
       (SELECT COUNT(*) FROM dbo.ResearchProject r WHERE r.LeadDepartmentID=d.DepartmentID) AS ProjectCount,
       (SELECT COUNT(*) FROM dbo.ResearchProjectSupervision s
        JOIN dbo.ResearchProject r ON r.ResearchProjectID=s.ResearchProjectID
        WHERE r.LeadDepartmentID=d.DepartmentID) AS SupervisionLinks
FROM dbo.Department d
ORDER BY d.DepartmentID;

SELECT p.ProfessorID, p.[Name] AS ProfessorName, p.DepartmentID,
       COUNT(s.ResearchProjectID) AS SupervisedResearchProjects
FROM dbo.Professor p
LEFT JOIN dbo.ResearchProjectSupervision s ON s.ProfessorID=p.ProfessorID
GROUP BY p.ProfessorID, p.[Name], p.DepartmentID
ORDER BY p.DepartmentID, p.ProfessorID;

SELECT c.column_id AS ColumnOrder, c.name AS ColumnName,
       TYPE_NAME(c.user_type_id) AS DataType, c.is_nullable AS IsNullable
FROM sys.columns c WHERE c.object_id=@TargetID ORDER BY c.column_id;

SELECT ForeignKeyName, ParentColumn, ReferencedTable, ReferencedColumn,
       IsDisabled, IsNotTrusted, ColumnOrdinal
FROM @ActualFK ORDER BY ForeignKeyName, ColumnOrdinal;

SELECT s.ResearchProjectID,s.ProfessorID,COUNT_BIG(*) AS DuplicateCount
FROM dbo.ResearchProjectSupervision s
GROUP BY s.ResearchProjectID,s.ProfessorID HAVING COUNT_BIG(*)>1;

SELECT r.ResearchProjectID,r.ProjectTitle
FROM dbo.ResearchProject r
WHERE NOT EXISTS (SELECT 1 FROM dbo.ResearchProjectSupervision s
                  WHERE s.ResearchProjectID=r.ResearchProjectID);
GO
---------------------------------
GO
