-- Extracted from UniversityManagementDB(2).sql; source lines 9368-10022.
USE [UniversityManagementDB];
GO
--Table 21 — ResearchCollaboration
--Phase4_21_Insert_ResearchCollaboration
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Clean up only session-scoped temporary objects if this script is rerun.
IF OBJECT_ID(N'tempdb..#R21ExpectedParticipation') IS NOT NULL DROP TABLE #R21ExpectedParticipation;
IF OBJECT_ID(N'tempdb..#R21ExpectedCollaboration') IS NOT NULL DROP TABLE #R21ExpectedCollaboration;

CREATE TABLE #R21ExpectedParticipation
(
    StudentID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    CONSTRAINT PK_R21ExpectedParticipation PRIMARY KEY (StudentID,ResearchProjectID)
);

-- Repeat exact approved Table 20 seed, INDEPENDENTLY of live target data.
;WITH Digits AS
(
    SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7)) AS d(n)
), N AS
(
    SELECT 8*a.n + b.n AS n FROM Digits a CROSS JOIN Digits b
)
INSERT INTO #R21ExpectedParticipation (StudentID,ResearchProjectID)
SELECT 10001+n, 2001+(n%16) FROM N WHERE n<56
UNION ALL
SELECT 10001+n, 2001+((n+8)%16) FROM N WHERE n<24;

CREATE TABLE #R21ExpectedCollaboration
(
    StudentID INT NOT NULL,
    ProfessorID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    CollaborationDepartmentID INT NOT NULL,
    CONSTRAINT PK_R21ExpectedCollaboration PRIMARY KEY
      (StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID)
);

-- Four distinct Student/Project pairs per project (the first four by StudentID).
-- Professors alternate between two per lead-department project, except row 4
-- deliberately invites one professor from the next department (wrap 8 to 1).
-- Add a second department for the row-1 triple, proving the approved four-way PK
-- allows one Student+Professor+Project across two collaboration departments.
;WITH Ranked AS
(
    SELECT rp.StudentID,rp.ResearchProjectID,
           1+((rp.ResearchProjectID-2001)/2) AS LeadDept,
           (rp.ResearchProjectID-2001)%2 AS ProjectSlot,
           ROW_NUMBER() OVER
             (PARTITION BY rp.ResearchProjectID ORDER BY rp.StudentID) AS rn
    FROM #R21ExpectedParticipation rp
), Base AS
(
    SELECT StudentID,ResearchProjectID,LeadDept,
           CASE WHEN LeadDept=8 THEN 1 ELSE LeadDept+1 END AS NextDept,
           ProjectSlot,rn
    FROM Ranked WHERE rn<=4
), CollaborationRows AS
(
    SELECT StudentID,
           CASE WHEN rn=4 THEN NextDept*100+2+ProjectSlot*2
                WHEN rn IN (1,3) THEN LeadDept*100+1+ProjectSlot*2
                ELSE LeadDept*100+2+ProjectSlot*2 END AS ProfessorID,
           ResearchProjectID,
           CASE WHEN rn=4 THEN NextDept ELSE LeadDept END AS CollaborationDepartmentID
    FROM Base
    UNION ALL
    SELECT StudentID,LeadDept*100+1+ProjectSlot*2,
           ResearchProjectID,NextDept
    FROM Base WHERE rn=1
)
INSERT INTO #R21ExpectedCollaboration
    (StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID)
SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
FROM CollaborationRows;

BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    IF DB_NAME()<>N'UniversityManagementDB'
        THROW 52101, 'STOP: Wrong database. No tables changed.', 1;

    DECLARE @oid INT=OBJECT_ID(N'dbo.ResearchCollaboration',N'U');
    IF @oid IS NULL OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
       OR OBJECT_ID(N'dbo.Professor',N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchProject',N'U') IS NULL
       OR OBJECT_ID(N'dbo.Department',N'U') IS NULL
       OR OBJECT_ID(N'dbo.ResearchParticipation',N'U') IS NULL
        THROW 52102, 'STOP: Target or parent table missing.', 1;

-- Exactly five enabled+trusted FKs and exactly six ordered component mappings.
DECLARE @ExpectedFK TABLE
(
    FKName SYSNAME NOT NULL,
    Position INT NOT NULL,
    ParentColumn SYSNAME NOT NULL,
    ReferencedObject SYSNAME NOT NULL,
    ReferencedColumn SYSNAME NOT NULL,
    PRIMARY KEY(FKName,Position)
);
INSERT INTO @ExpectedFK VALUES
 (N'FK_ResearchCollaboration_Student',1,N'StudentID',N'Student',N'StudentID'),
 (N'FK_ResearchCollaboration_Professor',1,N'ProfessorID',N'Professor',N'ProfessorID'),
 (N'FK_ResearchCollaboration_ResearchProject',1,N'ResearchProjectID',N'ResearchProject',N'ResearchProjectID'),
 (N'FK_ResearchCollaboration_CollaborationDepartment',1,N'CollaborationDepartmentID',N'Department',N'DepartmentID'),
 (N'FK_ResearchCollaboration_ResearchParticipation',1,N'StudentID',N'ResearchParticipation',N'StudentID'),
 (N'FK_ResearchCollaboration_ResearchParticipation',2,N'ResearchProjectID',N'ResearchParticipation',N'ResearchProjectID');

-- DDL gate: exact four columns in exact order, native INT, NOT NULL,
-- no identity / computed / default attributes.
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=@oid)<>4
   OR EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid
              AND (TYPE_NAME(user_type_id)<>N'int' OR max_length<>4
                   OR is_nullable<>0 OR is_identity<>0 OR is_computed<>0
                   OR default_object_id<>0))
   OR EXISTS
   (
       SELECT e.Ordinal,e.ColName
       FROM (VALUES(1,N'StudentID'),(2,N'ProfessorID'),
                   (3,N'ResearchProjectID'),(4,N'CollaborationDepartmentID')) e(Ordinal,ColName)
       EXCEPT
       SELECT column_id,name FROM sys.columns WHERE object_id=@oid
   )
    THROW 52103, 'STOP: Exact four approved INT NOT NULL columns not found.', 1;

-- PK name + precise ordered 4-column key, clustered per approved DDL.
IF (SELECT COUNT(*) FROM sys.key_constraints
    WHERE parent_object_id=@oid AND type='PK')<>1
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.key_constraints kc
       JOIN sys.indexes ix ON ix.object_id=kc.parent_object_id
                            AND ix.index_id=kc.unique_index_id
       JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                                  AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
       JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
       WHERE kc.parent_object_id=@oid AND kc.type='PK'
         AND kc.name=N'PK_ResearchCollaboration' AND ix.type=1
       GROUP BY kc.object_id
       HAVING COUNT(*)=4
          AND SUM(CASE WHEN ic.key_ordinal=1 AND c.name=N'StudentID' THEN 1 ELSE 0 END)=1
          AND SUM(CASE WHEN ic.key_ordinal=2 AND c.name=N'ProfessorID' THEN 1 ELSE 0 END)=1
          AND SUM(CASE WHEN ic.key_ordinal=3 AND c.name=N'ResearchProjectID' THEN 1 ELSE 0 END)=1
          AND SUM(CASE WHEN ic.key_ordinal=4 AND c.name=N'CollaborationDepartmentID' THEN 1 ELSE 0 END)=1
   )
    THROW 52104, 'STOP: Approved ordered four-column composite PK missing.', 1;

IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid)<>5
   OR (SELECT COUNT(*)
       FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
       WHERE fk.parent_object_id=@oid)<>6
   OR EXISTS
   (
       SELECT FKName,Position,ParentColumn,ReferencedObject,ReferencedColumn
       FROM @ExpectedFK
       EXCEPT
       SELECT fk.name,fc.constraint_column_id,
              COL_NAME(fc.parent_object_id,fc.parent_column_id),
              OBJECT_NAME(fk.referenced_object_id),
              COL_NAME(fc.referenced_object_id,fc.referenced_column_id)
       FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
       WHERE fk.parent_object_id=@oid
         AND OBJECT_SCHEMA_NAME(fk.referenced_object_id)=N'dbo'
         AND fk.is_disabled=0 AND fk.is_not_trusted=0
   )
   OR EXISTS
   (
       SELECT fk.name,fc.constraint_column_id,
              COL_NAME(fc.parent_object_id,fc.parent_column_id),
              OBJECT_NAME(fk.referenced_object_id),
              COL_NAME(fc.referenced_object_id,fc.referenced_column_id)
       FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
       WHERE fk.parent_object_id=@oid
       EXCEPT
       SELECT FKName,Position,ParentColumn,ReferencedObject,ReferencedColumn
       FROM @ExpectedFK
   )
   OR EXISTS (SELECT 1 FROM sys.foreign_keys
              WHERE parent_object_id=@oid AND (is_disabled=1 OR is_not_trusted=1))
    THROW 52105, 'STOP: Exactly five approved enabled/trusted FKs with six mappings required.', 1;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@oid
           AND is_unique=1 AND is_primary_key=0)
   OR EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid)
   OR EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@oid)
   OR EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@oid AND type='UQ')
    THROW 52106, 'STOP: Unapproved UNIQUE/CHECK/DEFAULT constraints or indexes.', 1;

-- Baselines for all five approved parent tables.
IF (SELECT COUNT_BIG(*) FROM dbo.Department)<>8
   OR EXISTS (SELECT 1 FROM dbo.Department WHERE DepartmentID NOT BETWEEN 1 AND 8)
    THROW 52107, 'STOP: Department baseline differs from eight departments 1..8.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.Student)<>64
   OR EXISTS (SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)
    THROW 52108, 'STOP: Student baseline differs from exactly IDs 10001..10064.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.Professor)<>32
   OR EXISTS (SELECT 1 FROM dbo.Professor
              WHERE DepartmentID NOT BETWEEN 1 AND 8
                OR ProfessorID NOT BETWEEN (DepartmentID*100+1) AND (DepartmentID*100+4))
   OR EXISTS (SELECT DepartmentID FROM dbo.Professor
              GROUP BY DepartmentID HAVING COUNT(*)<>4)
    THROW 52109, 'STOP: Professor baseline must be 32; four IDs per Department.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.ResearchProject)<>16
   OR EXISTS (SELECT 1 FROM dbo.ResearchProject
              WHERE ResearchProjectID NOT BETWEEN 2001 AND 2016
                 OR LeadDepartmentID<>(1+((ResearchProjectID-2001)/2)))
    THROW 52110, 'STOP: ResearchProject IDs or lead departments changed.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation)<>80
   OR (SELECT COUNT_BIG(*) FROM #R21ExpectedParticipation)<>80
   OR EXISTS
      (SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation
       EXCEPT SELECT StudentID,ResearchProjectID FROM #R21ExpectedParticipation)
   OR EXISTS
      (SELECT StudentID,ResearchProjectID FROM #R21ExpectedParticipation
       EXCEPT SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation)
    THROW 52111, 'STOP: ResearchParticipation is not its exact approved 80-row baseline.', 1;

IF (SELECT COUNT_BIG(*) FROM #R21ExpectedCollaboration)<>80
   OR (SELECT COUNT(DISTINCT ResearchProjectID) FROM #R21ExpectedCollaboration)<>16
   OR (SELECT COUNT(DISTINCT CollaborationDepartmentID) FROM #R21ExpectedCollaboration)<>8
   OR EXISTS (SELECT ResearchProjectID FROM #R21ExpectedCollaboration
              GROUP BY ResearchProjectID HAVING COUNT(*)<>5)
   OR EXISTS (SELECT CollaborationDepartmentID FROM #R21ExpectedCollaboration
              GROUP BY CollaborationDepartmentID HAVING COUNT(*)<>10)
    THROW 52112, 'STOP: 80-row synthetic seed distribution was not constructed.', 1;

IF EXISTS
   (SELECT e.StudentID FROM #R21ExpectedCollaboration e
    LEFT JOIN dbo.Student s ON s.StudentID=e.StudentID
    LEFT JOIN dbo.Professor p ON p.ProfessorID=e.ProfessorID
    LEFT JOIN dbo.ResearchProject r ON r.ResearchProjectID=e.ResearchProjectID
    LEFT JOIN dbo.Department d ON d.DepartmentID=e.CollaborationDepartmentID
    LEFT JOIN dbo.ResearchParticipation rp
      ON rp.StudentID=e.StudentID AND rp.ResearchProjectID=e.ResearchProjectID
    WHERE s.StudentID IS NULL OR p.ProfessorID IS NULL OR r.ResearchProjectID IS NULL
       OR d.DepartmentID IS NULL OR rp.StudentID IS NULL)
    THROW 52113, 'STOP: A collaboration references a missing parent or ResearchParticipation.', 1;

    -- Strict no-touch policy. Never insert again into a populated target.
    IF EXISTS (SELECT 1 FROM dbo.ResearchCollaboration WITH (UPDLOCK,HOLDLOCK))
        THROW 52114, 'STOP: ResearchCollaboration already contains rows. No INSERT attempted.', 1;

    INSERT INTO dbo.ResearchCollaboration
      (StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID)
    SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
    FROM #R21ExpectedCollaboration;

    IF @@ROWCOUNT<>80 OR (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration)<>80
        THROW 52115, 'STOP: Inserted count differs from 80. Rolling back.', 1;

    IF EXISTS
       (SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
        FROM dbo.ResearchCollaboration
        EXCEPT
        SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
        FROM #R21ExpectedCollaboration)
       OR EXISTS
       (SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
        FROM #R21ExpectedCollaboration
        EXCEPT
        SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
        FROM dbo.ResearchCollaboration)
        THROW 52116, 'STOP: Exact four-column row set differs. Rolling back.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 80 ResearchCollaboration rows inserted and COMMITTED; parents untouched.';
    PRINT 'NEXT: run Phase4_21_Verify_ResearchCollaboration.sql in a separate full execution.';
    SELECT COUNT_BIG(*) AS ActualRows,CONVERT(BIGINT,80) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.ResearchCollaboration;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;

DROP TABLE #R21ExpectedCollaboration;
DROP TABLE #R21ExpectedParticipation;
GO
-----------------------------------
--Phase4_21_Verify_ResearchCollaboration
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Clean up only session-scoped temporary objects if this script is rerun.
IF OBJECT_ID(N'tempdb..#R21ExpectedParticipation') IS NOT NULL DROP TABLE #R21ExpectedParticipation;
IF OBJECT_ID(N'tempdb..#R21ExpectedCollaboration') IS NOT NULL DROP TABLE #R21ExpectedCollaboration;

CREATE TABLE #R21ExpectedParticipation
(
    StudentID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    CONSTRAINT PK_R21ExpectedParticipation PRIMARY KEY (StudentID,ResearchProjectID)
);

-- Repeat exact approved Table 20 seed, INDEPENDENTLY of live target data.
;WITH Digits AS
(
    SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7)) AS d(n)
), N AS
(
    SELECT 8*a.n + b.n AS n FROM Digits a CROSS JOIN Digits b
)
INSERT INTO #R21ExpectedParticipation (StudentID,ResearchProjectID)
SELECT 10001+n, 2001+(n%16) FROM N WHERE n<56
UNION ALL
SELECT 10001+n, 2001+((n+8)%16) FROM N WHERE n<24;

CREATE TABLE #R21ExpectedCollaboration
(
    StudentID INT NOT NULL,
    ProfessorID INT NOT NULL,
    ResearchProjectID INT NOT NULL,
    CollaborationDepartmentID INT NOT NULL,
    CONSTRAINT PK_R21ExpectedCollaboration PRIMARY KEY
      (StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID)
);

-- Four distinct Student/Project pairs per project (the first four by StudentID).
-- Professors alternate between two per lead-department project, except row 4
-- deliberately invites one professor from the next department (wrap 8 to 1).
-- Add a second department for the row-1 triple, proving the approved four-way PK
-- allows one Student+Professor+Project across two collaboration departments.
;WITH Ranked AS
(
    SELECT rp.StudentID,rp.ResearchProjectID,
           1+((rp.ResearchProjectID-2001)/2) AS LeadDept,
           (rp.ResearchProjectID-2001)%2 AS ProjectSlot,
           ROW_NUMBER() OVER
             (PARTITION BY rp.ResearchProjectID ORDER BY rp.StudentID) AS rn
    FROM #R21ExpectedParticipation rp
), Base AS
(
    SELECT StudentID,ResearchProjectID,LeadDept,
           CASE WHEN LeadDept=8 THEN 1 ELSE LeadDept+1 END AS NextDept,
           ProjectSlot,rn
    FROM Ranked WHERE rn<=4
), CollaborationRows AS
(
    SELECT StudentID,
           CASE WHEN rn=4 THEN NextDept*100+2+ProjectSlot*2
                WHEN rn IN (1,3) THEN LeadDept*100+1+ProjectSlot*2
                ELSE LeadDept*100+2+ProjectSlot*2 END AS ProfessorID,
           ResearchProjectID,
           CASE WHEN rn=4 THEN NextDept ELSE LeadDept END AS CollaborationDepartmentID
    FROM Base
    UNION ALL
    SELECT StudentID,LeadDept*100+1+ProjectSlot*2,
           ResearchProjectID,NextDept
    FROM Base WHERE rn=1
)
INSERT INTO #R21ExpectedCollaboration
    (StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID)
SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
FROM CollaborationRows;

IF DB_NAME()<>N'UniversityManagementDB'
    THROW 52201, 'STOP: Wrong database.', 1;
DECLARE @oid INT=OBJECT_ID(N'dbo.ResearchCollaboration',N'U');
IF @oid IS NULL OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Professor',N'U') IS NULL
   OR OBJECT_ID(N'dbo.ResearchProject',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Department',N'U') IS NULL
   OR OBJECT_ID(N'dbo.ResearchParticipation',N'U') IS NULL
    THROW 52202, 'STOP: Target or parent table missing.', 1;

IF OBJECT_ID(N'tempdb..#R21Checks') IS NOT NULL DROP TABLE #R21Checks;
CREATE TABLE #R21Checks
(
    CheckID INT NOT NULL PRIMARY KEY,
    Item NVARCHAR(250) NOT NULL,
    Result VARCHAR(4) NOT NULL
);

-- Exactly five enabled+trusted FKs and exactly six ordered component mappings.
DECLARE @ExpectedFK TABLE
(
    FKName SYSNAME NOT NULL,
    Position INT NOT NULL,
    ParentColumn SYSNAME NOT NULL,
    ReferencedObject SYSNAME NOT NULL,
    ReferencedColumn SYSNAME NOT NULL,
    PRIMARY KEY(FKName,Position)
);
INSERT INTO @ExpectedFK VALUES
 (N'FK_ResearchCollaboration_Student',1,N'StudentID',N'Student',N'StudentID'),
 (N'FK_ResearchCollaboration_Professor',1,N'ProfessorID',N'Professor',N'ProfessorID'),
 (N'FK_ResearchCollaboration_ResearchProject',1,N'ResearchProjectID',N'ResearchProject',N'ResearchProjectID'),
 (N'FK_ResearchCollaboration_CollaborationDepartment',1,N'CollaborationDepartmentID',N'Department',N'DepartmentID'),
 (N'FK_ResearchCollaboration_ResearchParticipation',1,N'StudentID',N'ResearchParticipation',N'StudentID'),
 (N'FK_ResearchCollaboration_ResearchParticipation',2,N'ResearchProjectID',N'ResearchParticipation',N'ResearchProjectID');

-- Structural assertions (01-06)
INSERT INTO #R21Checks VALUES
(1,N'Four approved INT NOT NULL columns in exact order; no identity/computed/default',
 CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id=@oid)=4
  AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid
       AND (TYPE_NAME(user_type_id)<>N'int' OR max_length<>4 OR is_nullable<>0
            OR is_identity<>0 OR is_computed<>0 OR default_object_id<>0))
  AND NOT EXISTS
  (SELECT Ordinal,ColName FROM
    (VALUES(1,N'StudentID'),(2,N'ProfessorID'),(3,N'ResearchProjectID'),
            (4,N'CollaborationDepartmentID')) t(Ordinal,ColName)
   EXCEPT SELECT column_id,name FROM sys.columns WHERE object_id=@oid)
 THEN 'PASS' ELSE 'FAIL' END),
(2,N'Approved clustered PK with all four components in exact order',
 CASE WHEN (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@oid AND type='PK')=1
  AND EXISTS
  (SELECT 1 FROM sys.key_constraints kc
   JOIN sys.indexes ix ON ix.object_id=kc.parent_object_id AND ix.index_id=kc.unique_index_id
   JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
   JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
   WHERE kc.parent_object_id=@oid AND kc.name=N'PK_ResearchCollaboration' AND kc.type='PK' AND ix.type=1
   GROUP BY kc.object_id HAVING COUNT(*)=4
     AND SUM(CASE WHEN ic.key_ordinal=1 AND c.name=N'StudentID' THEN 1 ELSE 0 END)=1
     AND SUM(CASE WHEN ic.key_ordinal=2 AND c.name=N'ProfessorID' THEN 1 ELSE 0 END)=1
     AND SUM(CASE WHEN ic.key_ordinal=3 AND c.name=N'ResearchProjectID' THEN 1 ELSE 0 END)=1
     AND SUM(CASE WHEN ic.key_ordinal=4 AND c.name=N'CollaborationDepartmentID' THEN 1 ELSE 0 END)=1)
 THEN 'PASS' ELSE 'FAIL' END),
(3,N'Exactly five enabled and trusted approved foreign keys',
 CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid)=5
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@oid
       AND (is_disabled=1 OR is_not_trusted=1))
 THEN 'PASS' ELSE 'FAIL' END),
(4,N'Exactly six approved ordered FK component mappings including composite participation FK',
 CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fc
                 ON fc.constraint_object_id=fk.object_id WHERE fk.parent_object_id=@oid)=6
   AND NOT EXISTS
      (SELECT FKName,Position,ParentColumn,ReferencedObject,ReferencedColumn FROM @ExpectedFK
       EXCEPT
       SELECT fk.name,fc.constraint_column_id,
              COL_NAME(fc.parent_object_id,fc.parent_column_id),
              OBJECT_NAME(fk.referenced_object_id),
              COL_NAME(fc.referenced_object_id,fc.referenced_column_id)
       FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
       WHERE fk.parent_object_id=@oid AND fk.is_disabled=0 AND fk.is_not_trusted=0
         AND OBJECT_SCHEMA_NAME(fk.referenced_object_id)=N'dbo')
   AND NOT EXISTS
      (SELECT fk.name,fc.constraint_column_id,
              COL_NAME(fc.parent_object_id,fc.parent_column_id),
              OBJECT_NAME(fk.referenced_object_id),
              COL_NAME(fc.referenced_object_id,fc.referenced_column_id)
       FROM sys.foreign_keys fk
       JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
       WHERE fk.parent_object_id=@oid
       EXCEPT SELECT FKName,Position,ParentColumn,ReferencedObject,ReferencedColumn FROM @ExpectedFK)
 THEN 'PASS' ELSE 'FAIL' END),
(5,N'No unapproved UNIQUE indexes or UQ constraints beyond PK',
 CASE WHEN NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@oid
     AND is_unique=1 AND is_primary_key=0)
  AND NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@oid AND type='UQ')
 THEN 'PASS' ELSE 'FAIL' END),
(6,N'No unapproved CHECK or DEFAULT constraints',
 CASE WHEN NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid)
       AND NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@oid)
 THEN 'PASS' ELSE 'FAIL' END);

-- Immutable parents, exact 20th-table participation data (07-11)
INSERT INTO #R21Checks VALUES
(7,N'Parent Department baseline: exactly IDs 1..8',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Department)=8 AND NOT EXISTS
  (SELECT 1 FROM dbo.Department WHERE DepartmentID NOT BETWEEN 1 AND 8)
 THEN 'PASS' ELSE 'FAIL' END),
(8,N'Parent Student baseline: exactly IDs 10001..10064',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64 AND NOT EXISTS
  (SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)
 THEN 'PASS' ELSE 'FAIL' END),
(9,N'Parent Professor baseline: 32 IDs, four per department, exact association',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Professor)=32 AND NOT EXISTS
  (SELECT 1 FROM dbo.Professor WHERE DepartmentID NOT BETWEEN 1 AND 8
    OR ProfessorID NOT BETWEEN (DepartmentID*100+1) AND (DepartmentID*100+4))
  AND NOT EXISTS (SELECT DepartmentID FROM dbo.Professor GROUP BY DepartmentID HAVING COUNT(*)<>4)
 THEN 'PASS' ELSE 'FAIL' END),
(10,N'Parent ResearchProject baseline: 16 IDs and approved lead-department association',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchProject)=16 AND NOT EXISTS
  (SELECT 1 FROM dbo.ResearchProject WHERE ResearchProjectID NOT BETWEEN 2001 AND 2016
    OR LeadDepartmentID<>(1+((ResearchProjectID-2001)/2)))
 THEN 'PASS' ELSE 'FAIL' END),
(11,N'Parent ResearchParticipation exact seed: 80 pairs, no missing/extra/changed',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation)=80
    AND (SELECT COUNT_BIG(*) FROM #R21ExpectedParticipation)=80
    AND NOT EXISTS
      (SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation
       EXCEPT SELECT StudentID,ResearchProjectID FROM #R21ExpectedParticipation)
    AND NOT EXISTS
      (SELECT StudentID,ResearchProjectID FROM #R21ExpectedParticipation
       EXCEPT SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation)
 THEN 'PASS' ELSE 'FAIL' END);

-- Exact expected rows, patterns, and referential integrity (12-22)
INSERT INTO #R21Checks VALUES
(12,N'Expected four-tuple seed has exactly 80 distinct rows',
 CASE WHEN (SELECT COUNT_BIG(*) FROM #R21ExpectedCollaboration)=80 THEN 'PASS' ELSE 'FAIL' END),
(13,N'Target has exactly 80 collaborations',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration)=80 THEN 'PASS' ELSE 'FAIL' END),
(14,N'Exact row set both ways: no missing, extra, altered collaborations',
 CASE WHEN NOT EXISTS
  (SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID FROM dbo.ResearchCollaboration
   EXCEPT SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID FROM #R21ExpectedCollaboration)
   AND NOT EXISTS
  (SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID FROM #R21ExpectedCollaboration
   EXCEPT SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID FROM dbo.ResearchCollaboration)
 THEN 'PASS' ELSE 'FAIL' END),
(15,N'No orphan Student, Professor, ResearchProject, Department or participation pair',
 CASE WHEN NOT EXISTS
  (SELECT 1 FROM dbo.ResearchCollaboration c
   LEFT JOIN dbo.Student s ON s.StudentID=c.StudentID
   LEFT JOIN dbo.Professor p ON p.ProfessorID=c.ProfessorID
   LEFT JOIN dbo.ResearchProject r ON r.ResearchProjectID=c.ResearchProjectID
   LEFT JOIN dbo.Department d ON d.DepartmentID=c.CollaborationDepartmentID
   LEFT JOIN dbo.ResearchParticipation rp
      ON rp.StudentID=c.StudentID AND rp.ResearchProjectID=c.ResearchProjectID
   WHERE s.StudentID IS NULL OR p.ProfessorID IS NULL OR r.ResearchProjectID IS NULL
      OR d.DepartmentID IS NULL OR rp.StudentID IS NULL)
 THEN 'PASS' ELSE 'FAIL' END),
(16,N'No duplicate four-column collaboration tuples',
 CASE WHEN NOT EXISTS
   (SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
    FROM dbo.ResearchCollaboration
    GROUP BY StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID
    HAVING COUNT_BIG(*)>1)
 THEN 'PASS' ELSE 'FAIL' END),
(17,N'Exactly 16 projects; five collaboration rows for EACH project',
 CASE WHEN (SELECT COUNT(DISTINCT ResearchProjectID) FROM dbo.ResearchCollaboration)=16
  AND NOT EXISTS (SELECT ResearchProjectID FROM dbo.ResearchCollaboration
                  GROUP BY ResearchProjectID HAVING COUNT_BIG(*)<>5)
 THEN 'PASS' ELSE 'FAIL' END),
(18,N'Exactly eight departments, ten collaboration rows per department',
 CASE WHEN (SELECT COUNT(DISTINCT CollaborationDepartmentID) FROM dbo.ResearchCollaboration)=8
  AND NOT EXISTS (SELECT CollaborationDepartmentID FROM dbo.ResearchCollaboration
                  GROUP BY CollaborationDepartmentID HAVING COUNT_BIG(*)<>10)
 THEN 'PASS' ELSE 'FAIL' END),
(19,N'Exactly 64 participating Student/Project pairs collaborate; 16 do not',
 CASE WHEN (SELECT COUNT_BIG(*) FROM
   (SELECT StudentID,ResearchProjectID FROM dbo.ResearchCollaboration
    GROUP BY StudentID,ResearchProjectID) d)=64
  AND (SELECT COUNT_BIG(*) FROM
      (SELECT StudentID,ResearchProjectID FROM dbo.ResearchParticipation
       EXCEPT SELECT StudentID,ResearchProjectID FROM dbo.ResearchCollaboration) notlinked)=16
 THEN 'PASS' ELSE 'FAIL' END),
(20,N'Exactly 16 distinct triples occur in TWO collaboration departments, remaining 48 once',
 CASE WHEN (SELECT COUNT_BIG(*) FROM
     (SELECT StudentID,ProfessorID,ResearchProjectID FROM dbo.ResearchCollaboration
      GROUP BY StudentID,ProfessorID,ResearchProjectID HAVING COUNT_BIG(*)=2) t)=16
   AND (SELECT COUNT_BIG(*) FROM
     (SELECT StudentID,ProfessorID,ResearchProjectID FROM dbo.ResearchCollaboration
      GROUP BY StudentID,ProfessorID,ResearchProjectID HAVING COUNT_BIG(*)=1) t)=48
   AND NOT EXISTS
     (SELECT 1 FROM dbo.ResearchCollaboration GROUP BY StudentID,ProfessorID,ResearchProjectID
      HAVING COUNT(DISTINCT CollaborationDepartmentID)<>COUNT(*))
 THEN 'PASS' ELSE 'FAIL' END),
(21,N'All 32 professors participate: sixteen with three rows and sixteen with two',
 CASE WHEN (SELECT COUNT(DISTINCT ProfessorID) FROM dbo.ResearchCollaboration)=32
   AND (SELECT COUNT_BIG(*) FROM
       (SELECT ProfessorID FROM dbo.ResearchCollaboration
        GROUP BY ProfessorID HAVING COUNT_BIG(*)=3) x)=16
   AND (SELECT COUNT_BIG(*) FROM
       (SELECT ProfessorID FROM dbo.ResearchCollaboration
        GROUP BY ProfessorID HAVING COUNT_BIG(*)=2) x)=16
 THEN 'PASS' ELSE 'FAIL' END),
(22,N'Seed includes 32 cross-lead-department collaborations',
 CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration c
     JOIN dbo.ResearchProject r ON r.ResearchProjectID=c.ResearchProjectID
     WHERE c.CollaborationDepartmentID<>r.LeadDepartmentID)=32
 THEN 'PASS' ELSE 'FAIL' END);

-- Primary summary first. No dbo updates, inserts or deletes.
SELECT N'ResearchCollaboration: Exact Row Set + Schema + PK + 5 FK' AS VerificationTest,
       CASE WHEN COUNT(*)=22 AND SUM(CASE WHEN Result='FAIL' THEN 1 ELSE 0 END)=0
                 THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration) AS ActualRows,
       CONVERT(BIGINT,80) AS ExpectedRows,
       COUNT(*) AS ChecksEvaluated,
       SUM(CASE WHEN Result='FAIL' THEN 1 ELSE 0 END) AS FailedChecks
FROM #R21Checks;

SELECT CheckID,Item,Result FROM #R21Checks ORDER BY CheckID;

-- Detailed evidence panels, all read-only:
SELECT c.StudentID,s.[Name] AS StudentName,c.ProfessorID,p.[Name] AS ProfessorName,
       c.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID,
       c.CollaborationDepartmentID,d.DepartmentName AS CollaborationDepartmentName,
       p.DepartmentID AS ProfessorDepartmentID
FROM dbo.ResearchCollaboration c
JOIN dbo.Student s ON s.StudentID=c.StudentID
JOIN dbo.Professor p ON p.ProfessorID=c.ProfessorID
JOIN dbo.ResearchProject r ON r.ResearchProjectID=c.ResearchProjectID
JOIN dbo.Department d ON d.DepartmentID=c.CollaborationDepartmentID
ORDER BY c.ResearchProjectID,c.StudentID,c.ProfessorID,c.CollaborationDepartmentID;

SELECT r.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID,
       COUNT(c.StudentID) AS CollaborationRows,
       COUNT(DISTINCT c.StudentID) AS CollaboratingStudents
FROM dbo.ResearchProject r
LEFT JOIN dbo.ResearchCollaboration c ON c.ResearchProjectID=r.ResearchProjectID
GROUP BY r.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID
ORDER BY r.ResearchProjectID;

SELECT d.DepartmentID,d.DepartmentName,
       COUNT(c.StudentID) AS CollaborationRows
FROM dbo.Department d
LEFT JOIN dbo.ResearchCollaboration c ON c.CollaborationDepartmentID=d.DepartmentID
GROUP BY d.DepartmentID,d.DepartmentName ORDER BY d.DepartmentID;

SELECT c.ProfessorID,p.[Name] AS ProfessorName,p.DepartmentID,
       COUNT(*) AS CollaborationRows
FROM dbo.ResearchCollaboration c
JOIN dbo.Professor p ON p.ProfessorID=c.ProfessorID
GROUP BY c.ProfessorID,p.[Name],p.DepartmentID
ORDER BY c.ProfessorID;

SELECT c.StudentID,c.ProfessorID,c.ResearchProjectID,
       COUNT(*) AS CollaborationDepartments
FROM dbo.ResearchCollaboration c
GROUP BY c.StudentID,c.ProfessorID,c.ResearchProjectID
HAVING COUNT(*)>1
ORDER BY c.ResearchProjectID,c.StudentID,c.ProfessorID;

SELECT rp.StudentID,rp.ResearchProjectID
FROM dbo.ResearchParticipation rp
WHERE NOT EXISTS (SELECT 1 FROM dbo.ResearchCollaboration c
                  WHERE c.StudentID=rp.StudentID AND c.ResearchProjectID=rp.ResearchProjectID)
ORDER BY rp.ResearchProjectID,rp.StudentID;

SELECT fk.name AS ForeignKeyName,fc.constraint_column_id AS ColumnOrder,
       COL_NAME(fc.parent_object_id,fc.parent_column_id) AS ParentColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       COL_NAME(fc.referenced_object_id,fc.referenced_column_id) AS ReferencedColumn,
       fk.is_disabled AS IsDisabled,fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
WHERE fk.parent_object_id=@oid
ORDER BY fk.name,fc.constraint_column_id;

DROP TABLE #R21Checks;
DROP TABLE #R21ExpectedCollaboration;
DROP TABLE #R21ExpectedParticipation;
GO
------------
GO
