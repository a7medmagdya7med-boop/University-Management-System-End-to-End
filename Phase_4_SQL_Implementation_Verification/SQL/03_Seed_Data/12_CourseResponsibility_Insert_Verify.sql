-- Extracted from UniversityManagementDB(2).sql; source lines 5420-5877.
USE [UniversityManagementDB];
GO
-----Table 12 — CourseResponsibility
--Phase4_12_Insert_CourseResponsibility
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.CourseResponsibility',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Course',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Professor',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Department',N'U') IS NULL
    THROW 51201, 'STOP: Target or parent table is missing. Nothing inserted.', 1;

-- Metadata flags: exact two ordered INT NOT NULL columns, composite PK, exact two trusted FKs.
DECLARE @TableObject INT = OBJECT_ID(N'dbo.CourseResponsibility', N'U');
DECLARE @ColumnsOK BIT=0, @PKOK BIT=0, @FKOK BIT=0, @UniqueOK BIT=0;

IF (SELECT COUNT_BIG(*) FROM sys.columns WHERE object_id=@TableObject)=2
 AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableObject AND name=N'CourseID'
             AND column_id=1 AND system_type_id=56 AND is_nullable=0)
 AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableObject AND name=N'ProfessorID'
             AND column_id=2 AND system_type_id=56 AND is_nullable=0)
    SET @ColumnsOK=1;

IF EXISTS
(
 SELECT 1 FROM sys.key_constraints kc
 WHERE kc.parent_object_id=@TableObject AND kc.name=N'PK_CourseResponsibility' AND kc.type='PK'
  AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic WHERE ic.object_id=@TableObject
       AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0)=2
  AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
              ON c.object_id=ic.object_id AND c.column_id=ic.column_id
              WHERE ic.object_id=@TableObject AND ic.index_id=kc.unique_index_id
              AND ic.key_ordinal=1 AND c.name=N'CourseID')
  AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
              ON c.object_id=ic.object_id AND c.column_id=ic.column_id
              WHERE ic.object_id=@TableObject AND ic.index_id=kc.unique_index_id
              AND ic.key_ordinal=2 AND c.name=N'ProfessorID')
) SET @PKOK=1;

IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys WHERE parent_object_id=@TableObject)=2
 AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@TableObject
                 AND (is_disabled=1 OR is_not_trusted=1))
 AND EXISTS
 (
  SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@TableObject AND fk.name=N'FK_CourseResponsibility_Course'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Course',N'U')
    AND pc.name=N'CourseID' AND rc.name=N'CourseID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0
    AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns f2 WHERE f2.constraint_object_id=fk.object_id)=1
 )
 AND EXISTS
 (
  SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@TableObject AND fk.name=N'FK_CourseResponsibility_Professor'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Professor',N'U')
    AND pc.name=N'ProfessorID' AND rc.name=N'ProfessorID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0
    AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns f2 WHERE f2.constraint_object_id=fk.object_id)=1
 ) SET @FKOK=1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@TableObject
               AND is_unique=1 AND is_primary_key=0)
 SET @UniqueOK=1;

IF @ColumnsOK=0 OR @PKOK=0 OR @FKOK=0 OR @UniqueOK=0
    THROW 51202, 'STOP: CourseResponsibility schema / keys do not match Phase 3 approval.', 1;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.CourseResponsibility)
        THROW 51203, 'STOP: CourseResponsibility is not empty. No rows inserted.', 1;

DECLARE @Expected TABLE
(
    CourseID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (CourseID, ProfessorID)
);

-- Synthetic assignment plan per academic department:
-- Course 1: two professors; Course 2: two professors; Course 3: one professor.
-- Fourth professor in each department intentionally has no assignment (0..N allowed).
-- These ID groupings are SEED ASSUMPTIONS, not new database business rules.
INSERT INTO @Expected (CourseID, ProfessorID)
SELECT m.CourseID, m.ProfessorID
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS d(DepartmentID)
CROSS APPLY
(
    VALUES
       (3*d.DepartmentID-2, 100*d.DepartmentID+1),
       (3*d.DepartmentID-2, 100*d.DepartmentID+2),
       (3*d.DepartmentID-1, 100*d.DepartmentID+2),
       (3*d.DepartmentID-1, 100*d.DepartmentID+3),
       (3*d.DepartmentID,   100*d.DepartmentID+3)
) AS m(CourseID, ProfessorID);

DECLARE @ParentsOK BIT=0;
IF (SELECT COUNT_BIG(*) FROM dbo.Course)=24
 AND (SELECT COUNT_BIG(*) FROM dbo.Professor)=32
 AND (SELECT COUNT_BIG(*) FROM dbo.Department)=8
 AND (SELECT COUNT_BIG(*) FROM @Expected)=40
 AND NOT EXISTS
 (
  SELECT 1 FROM @Expected e
  LEFT JOIN dbo.Course c ON c.CourseID=e.CourseID
  LEFT JOIN dbo.Professor p ON p.ProfessorID=e.ProfessorID
  LEFT JOIN dbo.Department d ON d.DepartmentID=((e.CourseID-1)/3)+1
  WHERE c.CourseID IS NULL OR p.ProfessorID IS NULL OR d.DepartmentID IS NULL
     OR p.DepartmentID<>d.DepartmentID
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Course c
  WHERE c.CourseID NOT BETWEEN 1 AND 24
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Department d
  LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
  GROUP BY d.DepartmentID
  HAVING COUNT_BIG(p.ProfessorID)<>4
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Professor p
  WHERE p.ProfessorID<>(p.DepartmentID*100 + (p.ProfessorID%100))
     OR p.ProfessorID%100 NOT BETWEEN 1 AND 4
 )
 SET @ParentsOK=1;

IF @ParentsOK=0
    THROW 51204, 'STOP: Approved 24-course / 32-professor parent seed does not match expected IDs or departments.', 1;

-- Exactly 40 distinct rows; the target PK prevents duplicate pairs.
INSERT INTO dbo.CourseResponsibility (CourseID, ProfessorID)
SELECT e.CourseID, e.ProfessorID
FROM @Expected e;

IF @@ROWCOUNT<>40 OR (SELECT COUNT_BIG(*) FROM dbo.CourseResponsibility)<>40
    THROW 51205, 'STOP: Inserted row count is not exactly 40.', 1;

IF EXISTS
 (SELECT CourseID, ProfessorID FROM @Expected
  EXCEPT SELECT CourseID, ProfessorID FROM dbo.CourseResponsibility)
 OR EXISTS
 (SELECT CourseID, ProfessorID FROM dbo.CourseResponsibility
  EXCEPT SELECT CourseID, ProfessorID FROM @Expected)
    THROW 51206, 'STOP: Exact 40-row seed mismatch. Transaction will roll back.', 1;

IF EXISTS
 (
  SELECT 1 FROM dbo.Course c
  LEFT JOIN dbo.CourseResponsibility cr ON cr.CourseID=c.CourseID
  GROUP BY c.CourseID
  HAVING COUNT_BIG(cr.ProfessorID) NOT BETWEEN 1 AND 2
 )
    THROW 51207, 'STOP: A course has zero or more than two seed responsibilities.', 1;

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
PRINT 'CourseResponsibility: 40 synthetic rows committed. No parent data changed. Run Phase4_12_Verify_CourseResponsibility.sql.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
--------------------------------
---Phase4_12_Verify_CourseResponsibility
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.CourseResponsibility',N'U') IS NULL
 OR OBJECT_ID(N'dbo.Course',N'U') IS NULL
 OR OBJECT_ID(N'dbo.Professor',N'U') IS NULL
 OR OBJECT_ID(N'dbo.Department',N'U') IS NULL
BEGIN
 SELECT N'CourseResponsibility: Exact Row Set + Schema + PK + FK + Coverage' AS VerificationTest,
        'FAIL' AS VerificationResult, CAST(NULL AS BIGINT) AS ActualRows,
        CAST(40 AS BIGINT) AS ExpectedRows, N'Target or parent table missing' AS Finding;
 RETURN;
END;

DECLARE @Expected TABLE
(
    CourseID INT NOT NULL,
    ProfessorID INT NOT NULL,
    PRIMARY KEY (CourseID, ProfessorID)
);

-- Synthetic assignment plan per academic department:
-- Course 1: two professors; Course 2: two professors; Course 3: one professor.
-- Fourth professor in each department intentionally has no assignment (0..N allowed).
-- These ID groupings are SEED ASSUMPTIONS, not new database business rules.
INSERT INTO @Expected (CourseID, ProfessorID)
SELECT m.CourseID, m.ProfessorID
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS d(DepartmentID)
CROSS APPLY
(
    VALUES
       (3*d.DepartmentID-2, 100*d.DepartmentID+1),
       (3*d.DepartmentID-2, 100*d.DepartmentID+2),
       (3*d.DepartmentID-1, 100*d.DepartmentID+2),
       (3*d.DepartmentID-1, 100*d.DepartmentID+3),
       (3*d.DepartmentID,   100*d.DepartmentID+3)
) AS m(CourseID, ProfessorID);

-- Metadata flags: exact two ordered INT NOT NULL columns, composite PK, exact two trusted FKs.
DECLARE @TableObject INT = OBJECT_ID(N'dbo.CourseResponsibility', N'U');
DECLARE @ColumnsOK BIT=0, @PKOK BIT=0, @FKOK BIT=0, @UniqueOK BIT=0;

IF (SELECT COUNT_BIG(*) FROM sys.columns WHERE object_id=@TableObject)=2
 AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableObject AND name=N'CourseID'
             AND column_id=1 AND system_type_id=56 AND is_nullable=0)
 AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableObject AND name=N'ProfessorID'
             AND column_id=2 AND system_type_id=56 AND is_nullable=0)
    SET @ColumnsOK=1;

IF EXISTS
(
 SELECT 1 FROM sys.key_constraints kc
 WHERE kc.parent_object_id=@TableObject AND kc.name=N'PK_CourseResponsibility' AND kc.type='PK'
  AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic WHERE ic.object_id=@TableObject
       AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0)=2
  AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
              ON c.object_id=ic.object_id AND c.column_id=ic.column_id
              WHERE ic.object_id=@TableObject AND ic.index_id=kc.unique_index_id
              AND ic.key_ordinal=1 AND c.name=N'CourseID')
  AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
              ON c.object_id=ic.object_id AND c.column_id=ic.column_id
              WHERE ic.object_id=@TableObject AND ic.index_id=kc.unique_index_id
              AND ic.key_ordinal=2 AND c.name=N'ProfessorID')
) SET @PKOK=1;

IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys WHERE parent_object_id=@TableObject)=2
 AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@TableObject
                 AND (is_disabled=1 OR is_not_trusted=1))
 AND EXISTS
 (
  SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@TableObject AND fk.name=N'FK_CourseResponsibility_Course'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Course',N'U')
    AND pc.name=N'CourseID' AND rc.name=N'CourseID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0
    AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns f2 WHERE f2.constraint_object_id=fk.object_id)=1
 )
 AND EXISTS
 (
  SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@TableObject AND fk.name=N'FK_CourseResponsibility_Professor'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Professor',N'U')
    AND pc.name=N'ProfessorID' AND rc.name=N'ProfessorID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0
    AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns f2 WHERE f2.constraint_object_id=fk.object_id)=1
 ) SET @FKOK=1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@TableObject
               AND is_unique=1 AND is_primary_key=0)
 SET @UniqueOK=1;

DECLARE @ParentsOK BIT=0;
IF (SELECT COUNT_BIG(*) FROM dbo.Course)=24
 AND (SELECT COUNT_BIG(*) FROM dbo.Professor)=32
 AND (SELECT COUNT_BIG(*) FROM dbo.Department)=8
 AND (SELECT COUNT_BIG(*) FROM @Expected)=40
 AND NOT EXISTS
 (
  SELECT 1 FROM @Expected e
  LEFT JOIN dbo.Course c ON c.CourseID=e.CourseID
  LEFT JOIN dbo.Professor p ON p.ProfessorID=e.ProfessorID
  LEFT JOIN dbo.Department d ON d.DepartmentID=((e.CourseID-1)/3)+1
  WHERE c.CourseID IS NULL OR p.ProfessorID IS NULL OR d.DepartmentID IS NULL
     OR p.DepartmentID<>d.DepartmentID
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Course c
  WHERE c.CourseID NOT BETWEEN 1 AND 24
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Department d
  LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
  GROUP BY d.DepartmentID
  HAVING COUNT_BIG(p.ProfessorID)<>4
 )
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Professor p
  WHERE p.ProfessorID<>(p.DepartmentID*100 + (p.ProfessorID%100))
     OR p.ProfessorID%100 NOT BETWEEN 1 AND 4
 )
 SET @ParentsOK=1;

DECLARE @ActualRows BIGINT=(SELECT COUNT_BIG(*) FROM dbo.CourseResponsibility);
DECLARE @ExactRowsOK BIT=0, @CoverageOK BIT=0, @DistributionOK BIT=0,
        @ProfessorLoadsOK BIT=0, @IntegrityOK BIT=0;

IF @ActualRows=40
 AND NOT EXISTS
 (SELECT CourseID, ProfessorID FROM @Expected
  EXCEPT SELECT CourseID, ProfessorID FROM dbo.CourseResponsibility)
 AND NOT EXISTS
 (SELECT CourseID, ProfessorID FROM dbo.CourseResponsibility
  EXCEPT SELECT CourseID, ProfessorID FROM @Expected)
 SET @ExactRowsOK=1;

IF (SELECT COUNT_BIG(DISTINCT CourseID) FROM dbo.CourseResponsibility)=24
 AND NOT EXISTS
 (
  SELECT 1 FROM dbo.Course c
  WHERE NOT EXISTS
   (SELECT 1 FROM dbo.CourseResponsibility cr WHERE cr.CourseID=c.CourseID)
 )
 SET @CoverageOK=1;

;WITH ByCourse AS
(
 SELECT c.CourseID, COUNT_BIG(cr.ProfessorID) AS ResponsibleCount
 FROM dbo.Course c
 LEFT JOIN dbo.CourseResponsibility cr ON cr.CourseID=c.CourseID
 GROUP BY c.CourseID
)
SELECT @DistributionOK=CASE WHEN
 (SELECT COUNT_BIG(*) FROM ByCourse WHERE ResponsibleCount=1)=8
 AND (SELECT COUNT_BIG(*) FROM ByCourse WHERE ResponsibleCount=2)=16
 AND (SELECT COUNT_BIG(*) FROM ByCourse WHERE ResponsibleCount NOT BETWEEN 1 AND 2)=0
 THEN 1 ELSE 0 END;

;WITH ByProfessor AS
(
 SELECT p.ProfessorID, COUNT_BIG(cr.CourseID) AS CourseCount
 FROM dbo.Professor p
 LEFT JOIN dbo.CourseResponsibility cr ON cr.ProfessorID=p.ProfessorID
 GROUP BY p.ProfessorID
)
SELECT @ProfessorLoadsOK=CASE WHEN
 (SELECT COUNT_BIG(*) FROM ByProfessor WHERE CourseCount=0)=8
 AND (SELECT COUNT_BIG(*) FROM ByProfessor WHERE CourseCount>0)=24
 AND (SELECT COUNT_BIG(*) FROM ByProfessor WHERE CourseCount=2)=16
 AND (SELECT COUNT_BIG(*) FROM ByProfessor WHERE CourseCount=1)=8
 THEN 1 ELSE 0 END;

IF NOT EXISTS
 (
  SELECT 1 FROM dbo.CourseResponsibility cr
  LEFT JOIN dbo.Course c ON c.CourseID=cr.CourseID
  LEFT JOIN dbo.Professor p ON p.ProfessorID=cr.ProfessorID
  WHERE c.CourseID IS NULL OR p.ProfessorID IS NULL
     OR p.DepartmentID<>((cr.CourseID-1)/3)+1
 )
 SET @IntegrityOK=1;

DECLARE @Checks TABLE (Item NVARCHAR(160) NOT NULL, Result VARCHAR(4) NOT NULL);
INSERT INTO @Checks (Item,Result) VALUES
 (N'Approved two INT NOT NULL columns and their order', IIF(@ColumnsOK=1,'PASS','FAIL')),
 (N'Ordered composite PK (CourseID,ProfessorID)', IIF(@PKOK=1,'PASS','FAIL')),
 (N'Exactly two enabled/trusted FKs to Course and Professor', IIF(@FKOK=1,'PASS','FAIL')),
 (N'No additional UNIQUE indexes', IIF(@UniqueOK=1,'PASS','FAIL')),
 (N'Approved parents: 24 courses / 32 professors / 8 departments', IIF(@ParentsOK=1,'PASS','FAIL')),
 (N'Exact deterministic 40-row seed / no missing / extra records', IIF(@ExactRowsOK=1,'PASS','FAIL')),
 (N'Every one of 24 courses has a professor (min participation)', IIF(@CoverageOK=1,'PASS','FAIL')),
 (N'16 courses with 2 professors / 8 courses with 1', IIF(@DistributionOK=1,'PASS','FAIL')),
 (N'24 active professors / 8 without a course / valid loads', IIF(@ProfessorLoadsOK=1,'PASS','FAIL')),
 (N'No invalid parent references / seed department alignment', IIF(@IntegrityOK=1,'PASS','FAIL'));

-- 1. Main result -- screenshot this and the detailed test grid.
SELECT N'CourseResponsibility: Exact Row Set + Schema + PK + FK + Coverage' AS VerificationTest,
       CASE WHEN NOT EXISTS (SELECT 1 FROM @Checks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       @ActualRows AS ActualRows,
       CAST(40 AS BIGINT) AS ExpectedRows,
       (SELECT COUNT_BIG(*) FROM @Checks) AS ChecksEvaluated,
       (SELECT COUNT_BIG(*) FROM @Checks WHERE Result='FAIL') AS FailedChecks;

-- 2. Detailed test results.
SELECT Item,Result FROM @Checks ORDER BY Item;

-- 3. All 40 inserted associations + course title + professor name.
SELECT cr.CourseID,c.CourseTitle,cr.ProfessorID,p.[Name] AS ProfessorName,
       p.DepartmentID
FROM dbo.CourseResponsibility cr
JOIN dbo.Course c ON c.CourseID=cr.CourseID
JOIN dbo.Professor p ON p.ProfessorID=cr.ProfessorID
ORDER BY cr.CourseID,cr.ProfessorID;

-- 4. Minimum/maximum Course participation; every course appears.
SELECT c.CourseID,c.CourseTitle,COUNT_BIG(cr.ProfessorID) AS ResponsibleProfessors
FROM dbo.Course c
LEFT JOIN dbo.CourseResponsibility cr ON cr.CourseID=c.CourseID
GROUP BY c.CourseID,c.CourseTitle
ORDER BY c.CourseID;

-- 5. Professor zero-to-many participation, including zero rows.
SELECT p.ProfessorID,p.[Name] AS ProfessorName,p.DepartmentID,
       COUNT_BIG(cr.CourseID) AS ResponsibleCourses
FROM dbo.Professor p
LEFT JOIN dbo.CourseResponsibility cr ON cr.ProfessorID=p.ProfessorID
GROUP BY p.ProfessorID,p.[Name],p.DepartmentID
ORDER BY p.DepartmentID,p.ProfessorID;

-- 6. Seed distribution per department (5 responsibility rows each).
SELECT d.DepartmentID,d.DepartmentName,
       COUNT_BIG(cr.CourseID) AS ResponsibilityRows,
       COUNT(DISTINCT cr.CourseID) AS DistinctCourses,
       COUNT(DISTINCT cr.ProfessorID) AS ActiveProfessors
FROM dbo.Department d
LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
LEFT JOIN dbo.CourseResponsibility cr ON cr.ProfessorID=p.ProfessorID
GROUP BY d.DepartmentID,d.DepartmentName
ORDER BY d.DepartmentID;

-- 7-8. Both must have ZERO rows: extra and missing pairs.
SELECT cr.CourseID,cr.ProfessorID
FROM dbo.CourseResponsibility cr
EXCEPT
SELECT e.CourseID,e.ProfessorID FROM @Expected e;

SELECT e.CourseID,e.ProfessorID
FROM @Expected e
EXCEPT
SELECT cr.CourseID,cr.ProfessorID FROM dbo.CourseResponsibility cr;

-- 9. Table column metadata and 10. FK metadata.
SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,t.name AS DataType,c.is_nullable AS IsNullable
FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.CourseResponsibility',N'U')
ORDER BY c.column_id;

SELECT fk.name AS ForeignKeyName, pc.name AS ParentColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,
       fk.is_disabled AS IsDisabled, fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.CourseResponsibility',N'U')
ORDER BY fk.name,fkc.constraint_column_id;
GO
---------------------------------------------------
GO
