-- Extracted from UniversityManagementDB(2).sql; source lines 7497-7968.
USE [UniversityManagementDB];
GO
--Phase4_17_Insert_Enrollment.
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51700, 'STOP: Wrong database selected.', 1;
IF OBJECT_ID(N'tempdb..#ExpectedEnrollment', N'U') IS NOT NULL
    DROP TABLE #ExpectedEnrollment;
CREATE TABLE #ExpectedEnrollment
(
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    SemesterID INT NOT NULL,
    Grade DECIMAL(5,2) NULL,
    EnrollmentStatus NVARCHAR(20) NOT NULL,
    PRIMARY KEY (StudentID, CourseID, SemesterID)
);

-- Deterministic, synthetic seed: 8 subject groups x 8 students x 3 courses = 192.
-- Within each group, CourseIDs are group*3+1..group*3+3.
-- Semester progression per student uses 1..4, 3..6 and 5..8.
INSERT INTO #ExpectedEnrollment
    (StudentID, CourseID, SemesterID, Grade, EnrollmentStatus)
SELECT
    10001 + g.GroupNo * 8 + s.StudentNo AS StudentID,
    g.GroupNo * 3 + k.CourseSlot AS CourseID,
    sem.SemesterID,
    CASE WHEN sem.SemesterID <= 6
         THEN CONVERT(DECIMAL(5,2), 55.00 +
             (( (10001 + g.GroupNo*8+s.StudentNo)*7
                + (g.GroupNo*3+k.CourseSlot)*11
                + sem.SemesterID*13 ) % 45)
             + ((10001 + g.GroupNo*8+s.StudentNo + g.GroupNo*3+k.CourseSlot) % 4)*0.25)
         ELSE CONVERT(DECIMAL(5,2), NULL)
    END AS Grade,
    CASE WHEN sem.SemesterID <= 6 THEN N'Completed'
         WHEN sem.SemesterID = 7 THEN N'Enrolled'
         ELSE N'Planned'
    END AS EnrollmentStatus
FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS g(GroupNo)
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS s(StudentNo)
CROSS JOIN (VALUES (1),(2),(3)) AS k(CourseSlot)
CROSS APPLY (VALUES (1 + s.StudentNo/2 + 2*(k.CourseSlot-1))) AS sem(SemesterID);

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @oid INT = OBJECT_ID(N'dbo.Enrollment', N'U');

    IF @oid IS NULL OR OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Course', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Semester', N'U') IS NULL
        THROW 51701, 'STOP: Enrollment or a required parent table is missing.', 1;

    -- Schema check: exactly five columns, with types/ordinals/nullability fixed by DDL.
    IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = @oid) <> 5
       OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=1 AND name=N'StudentID' AND system_type_id=56 AND is_nullable=0)
       OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=2 AND name=N'CourseID' AND system_type_id=56 AND is_nullable=0)
       OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=3 AND name=N'SemesterID' AND system_type_id=56 AND is_nullable=0)
       OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=4 AND name=N'Grade' AND system_type_id=106 AND precision=5 AND scale=2 AND is_nullable=1)
       OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=5 AND name=N'EnrollmentStatus' AND system_type_id=231 AND max_length=40 AND is_nullable=0)
        THROW 51702, 'STOP: Enrollment columns do not match the approved DDL.', 1;

    -- Exactly one approved composite primary key, in the approved order.
    IF (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@oid AND type='PK') <> 1
       OR NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@oid AND name=N'PK_Enrollment' AND type='PK')
       OR (SELECT COUNT(*) FROM sys.key_constraints kc JOIN sys.index_columns ic
            ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
            WHERE kc.parent_object_id=@oid AND kc.name=N'PK_Enrollment') <> 3
       OR EXISTS (
           SELECT c.name, ic.key_ordinal
           FROM sys.key_constraints kc JOIN sys.index_columns ic
             ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
           JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
           WHERE kc.parent_object_id=@oid AND kc.name=N'PK_Enrollment'
           EXCEPT
           SELECT x.ColumnName, x.ColOrder FROM (VALUES
             (N'StudentID',1),(N'CourseID',2),(N'SemesterID',3)) x(ColumnName,ColOrder)
       )
        THROW 51703, 'STOP: Enrollment primary key differs from approved design.', 1;

    -- Exactly three enabled/trusted, single-column FKs with approved names and targets.
    IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid) <> 3
       OR EXISTS (
          SELECT fk.name, pc.name, OBJECT_NAME(fk.referenced_object_id), rc.name,
                 fk.is_disabled, fk.is_not_trusted
          FROM sys.foreign_keys fk
          JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
          JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
          JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
          WHERE fk.parent_object_id=@oid
          EXCEPT
          SELECT x.FKName, x.ParentCol, x.RefTable, x.RefCol, CONVERT(BIT,0), CONVERT(BIT,0)
          FROM (VALUES
            (N'FK_Enrollment_Student',N'StudentID',N'Student',N'StudentID'),
            (N'FK_Enrollment_Course',N'CourseID',N'Course',N'CourseID'),
            (N'FK_Enrollment_Semester',N'SemesterID',N'Semester',N'SemesterID')
          ) AS x(FKName,ParentCol,RefTable,RefCol)
       )
       OR (SELECT COUNT(*) FROM sys.foreign_key_columns fkc
           JOIN sys.foreign_keys fk ON fk.object_id=fkc.constraint_object_id
           WHERE fk.parent_object_id=@oid) <> 3
        THROW 51704, 'STOP: Enrollment foreign keys differ or are disabled/untrusted.', 1;

    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@oid AND is_unique=1 AND is_primary_key=0)
       OR EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid)
        THROW 51705, 'STOP: Unapproved UNIQUE index or CHECK constraint on Enrollment.', 1;

    -- Read-only baseline checks on APPROVED parent data. Require exact parent ID sets.
    IF (SELECT COUNT_BIG(*) FROM dbo.Student WITH (HOLDLOCK)) <> 64
       OR EXISTS (SELECT DISTINCT StudentID FROM #ExpectedEnrollment EXCEPT SELECT StudentID FROM dbo.Student)
       OR EXISTS (SELECT StudentID FROM dbo.Student EXCEPT SELECT DISTINCT StudentID FROM #ExpectedEnrollment)
        THROW 51706, 'STOP: Student baseline is not exactly 64 IDs (10001-10064).', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Course WITH (HOLDLOCK)) <> 24
       OR EXISTS (SELECT DISTINCT CourseID FROM #ExpectedEnrollment EXCEPT SELECT CourseID FROM dbo.Course)
       OR EXISTS (SELECT CourseID FROM dbo.Course EXCEPT SELECT DISTINCT CourseID FROM #ExpectedEnrollment)
        THROW 51707, 'STOP: Course baseline is not exactly IDs 1-24.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Semester WITH (HOLDLOCK)) <> 8
       OR EXISTS (SELECT DISTINCT SemesterID FROM #ExpectedEnrollment EXCEPT SELECT SemesterID FROM dbo.Semester)
       OR EXISTS (SELECT SemesterID FROM dbo.Semester EXCEPT SELECT DISTINCT SemesterID FROM #ExpectedEnrollment)
        THROW 51708, 'STOP: Semester baseline is not exactly IDs 1-8.', 1;

    IF EXISTS (
        SELECT SemesterID, AcademicYear, TermName FROM dbo.Semester
        EXCEPT
        SELECT x.SemesterID, x.AcademicYear, x.TermName
        FROM (VALUES
           (1,N'2023/2024',N'Fall'),(2,N'2023/2024',N'Spring'),
           (3,N'2024/2025',N'Fall'),(4,N'2024/2025',N'Spring'),
           (5,N'2025/2026',N'Fall'),(6,N'2025/2026',N'Spring'),
           (7,N'2026/2027',N'Fall'),(8,N'2026/2027',N'Spring')
        ) x(SemesterID,AcademicYear,TermName)
    )
        THROW 51709, 'STOP: Approved Semester year/term baseline differs.', 1;

    IF (SELECT COUNT_BIG(*) FROM #ExpectedEnrollment) <> 192
        THROW 51710, 'STOP: Seed generation did not produce 192 rows.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Enrollment WITH (UPDLOCK, HOLDLOCK))
        THROW 51711, 'STOP: Enrollment already contains rows; no INSERT attempted.', 1;

    INSERT INTO dbo.Enrollment
        (StudentID, CourseID, SemesterID, Grade, EnrollmentStatus)
    SELECT StudentID, CourseID, SemesterID, Grade, EnrollmentStatus
    FROM #ExpectedEnrollment;

    DECLARE @Inserted INT = @@ROWCOUNT;
    IF @Inserted <> 192 OR (SELECT COUNT_BIG(*) FROM dbo.Enrollment) <> 192
        THROW 51712, 'STOP: Enrollment row count differs from 192; rolling back.', 1;

    IF EXISTS (
        SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM dbo.Enrollment
        EXCEPT SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM #ExpectedEnrollment
    ) OR EXISTS (
        SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM #ExpectedEnrollment
        EXCEPT SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM dbo.Enrollment
    )
        THROW 51713, 'STOP: Enrollment differs from exact approved demo seed; rolling back.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 192 Enrollment sample rows inserted and committed; parent tables unchanged.';
    SELECT COUNT_BIG(*) AS ActualRows, CONVERT(BIGINT,192) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.Enrollment;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
DROP TABLE #ExpectedEnrollment;
GO
-------------------------
---Phase 4 | Table 17: Enrollment | READ-ONLY VERIFICATION.
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51720, 'STOP: Wrong database selected.', 1;
IF OBJECT_ID(N'dbo.Enrollment',N'U') IS NULL
    THROW 51721, 'STOP: Enrollment table is missing.', 1;
IF OBJECT_ID(N'dbo.Student',N'U') IS NULL OR OBJECT_ID(N'dbo.Course',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Semester',N'U') IS NULL
    THROW 51722, 'STOP: At least one parent table is missing.', 1;

IF OBJECT_ID(N'tempdb..#ExpectedEnrollment',N'U') IS NOT NULL DROP TABLE #ExpectedEnrollment;
IF OBJECT_ID(N'tempdb..#EnrollmentChecks',N'U') IS NOT NULL DROP TABLE #EnrollmentChecks;

CREATE TABLE #ExpectedEnrollment
(
    StudentID INT NOT NULL, CourseID INT NOT NULL, SemesterID INT NOT NULL,
    Grade DECIMAL(5,2) NULL, EnrollmentStatus NVARCHAR(20) NOT NULL,
    PRIMARY KEY(StudentID,CourseID,SemesterID)
);

-- Deterministic, synthetic seed: 8 subject groups x 8 students x 3 courses = 192.
-- Within each group, CourseIDs are group*3+1..group*3+3.
-- Semester progression per student uses 1..4, 3..6 and 5..8.
INSERT INTO #ExpectedEnrollment
    (StudentID, CourseID, SemesterID, Grade, EnrollmentStatus)
SELECT
    10001 + g.GroupNo * 8 + s.StudentNo AS StudentID,
    g.GroupNo * 3 + k.CourseSlot AS CourseID,
    sem.SemesterID,
    CASE WHEN sem.SemesterID <= 6
         THEN CONVERT(DECIMAL(5,2), 55.00 +
             (( (10001 + g.GroupNo*8+s.StudentNo)*7
                + (g.GroupNo*3+k.CourseSlot)*11
                + sem.SemesterID*13 ) % 45)
             + ((10001 + g.GroupNo*8+s.StudentNo + g.GroupNo*3+k.CourseSlot) % 4)*0.25)
         ELSE CONVERT(DECIMAL(5,2), NULL)
    END AS Grade,
    CASE WHEN sem.SemesterID <= 6 THEN N'Completed'
         WHEN sem.SemesterID = 7 THEN N'Enrolled'
         ELSE N'Planned'
    END AS EnrollmentStatus
FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS g(GroupNo)
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS s(StudentNo)
CROSS JOIN (VALUES (1),(2),(3)) AS k(CourseSlot)
CROSS APPLY (VALUES (1 + s.StudentNo/2 + 2*(k.CourseSlot-1))) AS sem(SemesterID);

CREATE TABLE #EnrollmentChecks
(
    CheckID INT IDENTITY(1,1) PRIMARY KEY,
    Item NVARCHAR(240) NOT NULL,
    Result VARCHAR(4) NOT NULL,
    Notes NVARCHAR(240) NULL
);
DECLARE @oid INT = OBJECT_ID(N'dbo.Enrollment',N'U');

-- 01: Exact schema, order, type, precision/scale, nullability.
INSERT INTO #EnrollmentChecks (Item,Result,Notes)
SELECT N'Exact five approved columns / order / types / NULL rules',
CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id=@oid)=5
  AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=1 AND name=N'StudentID' AND system_type_id=56 AND is_nullable=0)
  AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=2 AND name=N'CourseID' AND system_type_id=56 AND is_nullable=0)
  AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=3 AND name=N'SemesterID' AND system_type_id=56 AND is_nullable=0)
  AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=4 AND name=N'Grade' AND system_type_id=106 AND precision=5 AND scale=2 AND is_nullable=1)
  AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@oid AND column_id=5 AND name=N'EnrollmentStatus' AND system_type_id=231 AND max_length=40 AND is_nullable=0)
THEN 'PASS' ELSE 'FAIL' END, N'PK components INT; Grade DECIMAL(5,2); status NVARCHAR(20)';

-- 02: Exact PK order.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Approved composite PK (StudentID, CourseID, SemesterID)',
CASE WHEN (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@oid AND type='PK')=1
  AND EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@oid AND name=N'PK_Enrollment' AND type='PK')
  AND (SELECT COUNT(*) FROM sys.key_constraints kc JOIN sys.index_columns ic
       ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
       WHERE kc.parent_object_id=@oid AND kc.name=N'PK_Enrollment')=3
  AND NOT EXISTS (
      SELECT c.name,ic.key_ordinal FROM sys.key_constraints kc JOIN sys.index_columns ic
         ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
      JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
      WHERE kc.parent_object_id=@oid AND kc.name=N'PK_Enrollment'
      EXCEPT SELECT x.Col, x.Ord FROM (VALUES (N'StudentID',1),(N'CourseID',2),(N'SemesterID',3)) x(Col,Ord)
  ) THEN 'PASS' ELSE 'FAIL' END;

-- 03: Three expected FKs, enabled/trusted.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Exactly three enabled/trusted FKs with approved names and targets',
CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid)=3
  AND (SELECT COUNT(*) FROM sys.foreign_key_columns fkc JOIN sys.foreign_keys fk
        ON fk.object_id=fkc.constraint_object_id WHERE fk.parent_object_id=@oid)=3
  AND NOT EXISTS (
     SELECT fk.name,pc.name,OBJECT_NAME(fk.referenced_object_id),rc.name,fk.is_disabled,fk.is_not_trusted
     FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
     JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
     JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
     WHERE fk.parent_object_id=@oid
     EXCEPT SELECT v.FKName,v.Col,v.TableName,v.RefCol,CONVERT(BIT,0),CONVERT(BIT,0)
        FROM (VALUES
          (N'FK_Enrollment_Student',N'StudentID',N'Student',N'StudentID'),
          (N'FK_Enrollment_Course',N'CourseID',N'Course',N'CourseID'),
          (N'FK_Enrollment_Semester',N'SemesterID',N'Semester',N'SemesterID')
        ) v(FKName,Col,TableName,RefCol)
  ) THEN 'PASS' ELSE 'FAIL' END;

-- 04-05: Approved DDL has no extra UNIQUE or CHECK.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'No unexpected UNIQUE indexes (PK excluded)',
CASE WHEN NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=@oid AND is_unique=1 AND is_primary_key=0)
THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'No invented CHECK constraints on Grade or EnrollmentStatus',
CASE WHEN NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid)
THEN 'PASS' ELSE 'FAIL' END;

-- 06-08: Approved parent baselines, read only.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Student baseline: exactly IDs 10001-10064',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64
AND NOT EXISTS (SELECT DISTINCT StudentID FROM #ExpectedEnrollment EXCEPT SELECT StudentID FROM dbo.Student)
AND NOT EXISTS (SELECT StudentID FROM dbo.Student EXCEPT SELECT DISTINCT StudentID FROM #ExpectedEnrollment)
THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Course baseline: exactly IDs 1-24',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Course)=24
AND NOT EXISTS (SELECT DISTINCT CourseID FROM #ExpectedEnrollment EXCEPT SELECT CourseID FROM dbo.Course)
AND NOT EXISTS (SELECT CourseID FROM dbo.Course EXCEPT SELECT DISTINCT CourseID FROM #ExpectedEnrollment)
THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Semester baseline: IDs 1-8 with approved year/term',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Semester)=8
AND NOT EXISTS (
   SELECT SemesterID, AcademicYear, TermName FROM dbo.Semester
   EXCEPT
   SELECT v.SemesterID,v.AcademicYear,v.TermName FROM (VALUES
      (1,N'2023/2024',N'Fall'),(2,N'2023/2024',N'Spring'),
      (3,N'2024/2025',N'Fall'),(4,N'2024/2025',N'Spring'),
      (5,N'2025/2026',N'Fall'),(6,N'2025/2026',N'Spring'),
      (7,N'2026/2027',N'Fall'),(8,N'2026/2027',N'Spring')
   ) v(SemesterID,AcademicYear,TermName))
THEN 'PASS' ELSE 'FAIL' END;

-- 09-11: Expected seed and actual exact row-set.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Seed generator: exactly 192 expected synthetic rows',
CASE WHEN (SELECT COUNT_BIG(*) FROM #ExpectedEnrollment)=192 THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Enrollment actual row count exactly 192',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Enrollment)=192 THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Exact row set: no missing, extra, or altered values',
CASE WHEN NOT EXISTS (
 SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM dbo.Enrollment
 EXCEPT SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM #ExpectedEnrollment
) AND NOT EXISTS (
 SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM #ExpectedEnrollment
 EXCEPT SELECT StudentID,CourseID,SemesterID,Grade,EnrollmentStatus FROM dbo.Enrollment
) THEN 'PASS' ELSE 'FAIL' END;

-- 12-13: Composite duplicates and orphans.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'No duplicate Student-Course-Semester triplets',
CASE WHEN NOT EXISTS (
 SELECT StudentID,CourseID,SemesterID FROM dbo.Enrollment
 GROUP BY StudentID,CourseID,SemesterID HAVING COUNT_BIG(*)>1
) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'No orphan Student/Course/Semester references',
CASE WHEN NOT EXISTS (
 SELECT 1 FROM dbo.Enrollment e
 LEFT JOIN dbo.Student s ON s.StudentID=e.StudentID
 LEFT JOIN dbo.Course c ON c.CourseID=e.CourseID
 LEFT JOIN dbo.Semester t ON t.SemesterID=e.SemesterID
 WHERE s.StudentID IS NULL OR c.CourseID IS NULL OR t.SemesterID IS NULL
) THEN 'PASS' ELSE 'FAIL' END;

-- 14-15: Intended analytics coverage.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'64 students; each registered in exactly 3 distinct courses',
CASE WHEN (SELECT COUNT_BIG(*) FROM (SELECT StudentID FROM dbo.Enrollment GROUP BY StudentID) d)=64
AND NOT EXISTS(SELECT StudentID FROM dbo.Enrollment GROUP BY StudentID
 HAVING COUNT_BIG(*)<>3 OR COUNT(DISTINCT CourseID)<>3)
THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'24 courses; exactly 8 different students per course',
CASE WHEN (SELECT COUNT_BIG(*) FROM (SELECT CourseID FROM dbo.Enrollment GROUP BY CourseID) d)=24
AND NOT EXISTS(SELECT CourseID FROM dbo.Enrollment GROUP BY CourseID
 HAVING COUNT_BIG(*)<>8 OR COUNT(DISTINCT StudentID)<>8)
THEN 'PASS' ELSE 'FAIL' END;

-- 16: Temporal coverage by SemesterID.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Semester distributions exactly 16/16/32/32/32/32/16/16',
CASE WHEN NOT EXISTS(
  SELECT SemesterID,COUNT_BIG(*) AS Enrollments FROM dbo.Enrollment GROUP BY SemesterID
  EXCEPT SELECT v.SemesterID,CONVERT(BIGINT,v.ExpectedCount)
  FROM (VALUES(1,16),(2,16),(3,32),(4,32),(5,32),(6,32),(7,16),(8,16)) v(SemesterID,ExpectedCount)
) AND NOT EXISTS(
  SELECT v.SemesterID,CONVERT(BIGINT,v.ExpectedCount)
  FROM (VALUES(1,16),(2,16),(3,32),(4,32),(5,32),(6,32),(7,16),(8,16)) v(SemesterID,ExpectedCount)
  EXCEPT SELECT SemesterID,COUNT_BIG(*) FROM dbo.Enrollment GROUP BY SemesterID
) THEN 'PASS' ELSE 'FAIL' END;

-- 17: Expected status/grade combination is a test dataset convention, NOT an approved constraint.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Synthetic statuses: 160 Completed, 16 Enrolled, 16 Planned',
CASE WHEN (SELECT COUNT(*) FROM dbo.Enrollment WHERE EnrollmentStatus=N'Completed')=160
 AND (SELECT COUNT(*) FROM dbo.Enrollment WHERE EnrollmentStatus=N'Enrolled')=16
 AND (SELECT COUNT(*) FROM dbo.Enrollment WHERE EnrollmentStatus=N'Planned')=16
 AND NOT EXISTS (SELECT 1 FROM dbo.Enrollment WHERE
   (SemesterID BETWEEN 1 AND 6 AND (EnrollmentStatus<>N'Completed' OR Grade IS NULL))
   OR (SemesterID=7 AND (EnrollmentStatus<>N'Enrolled' OR Grade IS NOT NULL))
   OR (SemesterID=8 AND (EnrollmentStatus<>N'Planned' OR Grade IS NOT NULL))
 ) THEN 'PASS' ELSE 'FAIL' END;

-- 18: Values appropriate for THIS synthetic seed only, not a schema-level grade policy.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Synthetic grade/blank-status quality checks',
CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.Enrollment WHERE
    EnrollmentStatus IS NULL OR LEN(LTRIM(RTRIM(EnrollmentStatus)))=0
    OR (EnrollmentStatus=N'Completed' AND (Grade<55 OR Grade>99.75))
) THEN 'PASS' ELSE 'FAIL' END;

-- 19: Subject-group allocation in the synthetic seed.
INSERT INTO #EnrollmentChecks(Item,Result)
SELECT N'Department-aligned course-group seed allocation',
CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.Enrollment WHERE
 CourseID NOT BETWEEN ((StudentID-10001)/8)*3+1 AND ((StudentID-10001)/8)*3+3
) THEN 'PASS' ELSE 'FAIL' END;

-- Summary first: PASS only when zero checks fail.
SELECT
 N'Enrollment: Exact Row Set + Schema + PK + FK' AS VerificationTest,
 CASE WHEN NOT EXISTS(SELECT 1 FROM #EnrollmentChecks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
 (SELECT COUNT_BIG(*) FROM dbo.Enrollment) AS ActualRows,
 CONVERT(BIGINT,192) AS ExpectedRows,
 (SELECT COUNT(*) FROM #EnrollmentChecks) AS ChecksEvaluated,
 (SELECT COUNT(*) FROM #EnrollmentChecks WHERE Result='FAIL') AS FailedChecks;

SELECT CheckID,Item,Result,Notes FROM #EnrollmentChecks ORDER BY CheckID;
SELECT CheckID,Item,Notes FROM #EnrollmentChecks WHERE Result='FAIL' ORDER BY CheckID;

-- Display / audit evidence; 12 representative rows.
SELECT TOP(12) e.StudentID, s.[Name] AS StudentName,
       e.CourseID,c.CourseTitle,e.SemesterID,t.AcademicYear,t.TermName,
       e.Grade,e.EnrollmentStatus
FROM dbo.Enrollment e
JOIN dbo.Student s ON s.StudentID=e.StudentID
JOIN dbo.Course c ON c.CourseID=e.CourseID
JOIN dbo.Semester t ON t.SemesterID=e.SemesterID
ORDER BY e.StudentID,e.SemesterID,e.CourseID;

SELECT t.SemesterID,t.AcademicYear,t.TermName,
       COUNT(e.StudentID) AS EnrollmentCount,
       SUM(CASE WHEN e.EnrollmentStatus=N'Completed' THEN 1 ELSE 0 END) AS CompletedCount,
       SUM(CASE WHEN e.EnrollmentStatus=N'Enrolled' THEN 1 ELSE 0 END) AS EnrolledCount,
       SUM(CASE WHEN e.EnrollmentStatus=N'Planned' THEN 1 ELSE 0 END) AS PlannedCount,
       AVG(e.Grade) AS AverageRecordedGrade
FROM dbo.Semester t
LEFT JOIN dbo.Enrollment e ON e.SemesterID=t.SemesterID
GROUP BY t.SemesterID,t.AcademicYear,t.TermName
ORDER BY t.SemesterID;

SELECT c.CourseID,c.CourseTitle,COUNT(e.StudentID) AS EnrollmentCount
FROM dbo.Course c LEFT JOIN dbo.Enrollment e ON e.CourseID=c.CourseID
GROUP BY c.CourseID,c.CourseTitle ORDER BY c.CourseID;

SELECT TOP (12) s.StudentID,s.[Name] AS StudentName,
       COUNT(e.CourseID) AS EnrollmentCount,
       COUNT(DISTINCT e.CourseID) AS DistinctCourses
FROM dbo.Student s LEFT JOIN dbo.Enrollment e ON e.StudentID=s.StudentID
GROUP BY s.StudentID,s.[Name] ORDER BY s.StudentID;

SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,TYPE_NAME(c.system_type_id) AS DataType,
       c.max_length AS LengthBytes,c.precision AS NumericPrecision,c.scale AS NumericScale,c.is_nullable AS IsNullable
FROM sys.columns c WHERE c.object_id=@oid ORDER BY c.column_id;

SELECT kc.name AS PrimaryKeyName,c.name AS PrimaryKeyColumn,ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE kc.parent_object_id=@oid AND kc.type='PK'
ORDER BY ic.key_ordinal;

SELECT fk.name AS ForeignKeyName,pc.name AS ParentColumn,OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,fk.is_disabled AS IsDisabled,fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id=@oid ORDER BY fk.name,fkc.constraint_column_id;

DROP TABLE #EnrollmentChecks;
DROP TABLE #ExpectedEnrollment;
GO
-------------------------------------------
GO
