-- Extracted from UniversityManagementDB(2).sql; source lines 4535-4948.
USE [UniversityManagementDB];
GO
---Table 10 DepartmentHead
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51100, 'STOP: Wrong database. No changes made.', 1;

IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Professor', N'U') IS NULL
   OR OBJECT_ID(N'dbo.DepartmentHead', N'U') IS NULL
    THROW 51101, 'STOP: Prerequisite or target table is missing. No changes made.', 1;

-- Approved physical schema: exactly two INT NOT NULL columns in this order.
IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.DepartmentHead', N'U')) <> 2
   OR NOT EXISTS (SELECT 1 FROM sys.columns
                  WHERE object_id = OBJECT_ID(N'dbo.DepartmentHead', N'U')
                    AND name=N'DepartmentID' AND column_id=1
                    AND system_type_id=56 AND is_nullable=0)
   OR NOT EXISTS (SELECT 1 FROM sys.columns
                  WHERE object_id = OBJECT_ID(N'dbo.DepartmentHead', N'U')
                    AND name=N'ProfessorID' AND column_id=2
                    AND system_type_id=56 AND is_nullable=0)
    THROW 51102, 'STOP: dbo.DepartmentHead columns differ from approved DDL.', 1;

-- Required PK on DepartmentID; UNIQUE on ProfessorID.
IF NOT EXISTS
(
    SELECT 1 FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                              AND ic.index_id=kc.unique_index_id
                              AND ic.key_ordinal=1
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead', N'U')
      AND kc.name=N'PK_DepartmentHead' AND kc.type='PK'
      AND c.name=N'DepartmentID'
      AND (SELECT COUNT_BIG(*) FROM sys.index_columns x
           WHERE x.object_id=ic.object_id AND x.index_id=ic.index_id
             AND x.key_ordinal>0)=1
)
OR NOT EXISTS
(
    SELECT 1 FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                              AND ic.index_id=kc.unique_index_id
                              AND ic.key_ordinal=1
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead', N'U')
      AND kc.name=N'UQ_DepartmentHead_Professor' AND kc.type='UQ'
      AND c.name=N'ProfessorID'
      AND (SELECT COUNT_BIG(*) FROM sys.index_columns x
           WHERE x.object_id=ic.object_id AND x.index_id=ic.index_id
             AND x.key_ordinal>0)=1
)
    THROW 51103, 'STOP: Required PK or UNIQUE definition is missing or changed.', 1;

-- Exact FK mapping and enabled/trusted status, especially same-department composite FK.
IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys
    WHERE parent_object_id=OBJECT_ID(N'dbo.DepartmentHead', N'U')) <> 2
   OR NOT EXISTS
   (
      SELECT 1 FROM sys.foreign_keys fk
      JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
      JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id
      JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id
      WHERE fk.name=N'FK_DepartmentHead_Department'
        AND fk.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead', N'U')
        AND fk.referenced_object_id=OBJECT_ID(N'dbo.Department', N'U')
        AND fk.is_disabled=0 AND fk.is_not_trusted=0
        AND fc.constraint_column_id=1 AND pc.name=N'DepartmentID' AND rc.name=N'DepartmentID'
        AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns x
             WHERE x.constraint_object_id=fk.object_id)=1
   )
   OR NOT EXISTS
   (
      SELECT 1 FROM sys.foreign_keys fk
      JOIN sys.foreign_key_columns f1 ON f1.constraint_object_id=fk.object_id AND f1.constraint_column_id=1
      JOIN sys.foreign_key_columns f2 ON f2.constraint_object_id=fk.object_id AND f2.constraint_column_id=2
      JOIN sys.columns p1 ON p1.object_id=f1.parent_object_id AND p1.column_id=f1.parent_column_id
      JOIN sys.columns r1 ON r1.object_id=f1.referenced_object_id AND r1.column_id=f1.referenced_column_id
      JOIN sys.columns p2 ON p2.object_id=f2.parent_object_id AND p2.column_id=f2.parent_column_id
      JOIN sys.columns r2 ON r2.object_id=f2.referenced_object_id AND r2.column_id=f2.referenced_column_id
      WHERE fk.name=N'FK_DepartmentHead_ProfessorSameDepartment'
        AND fk.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead', N'U')
        AND fk.referenced_object_id=OBJECT_ID(N'dbo.Professor', N'U')
        AND fk.is_disabled=0 AND fk.is_not_trusted=0
        AND p1.name=N'ProfessorID' AND r1.name=N'ProfessorID'
        AND p2.name=N'DepartmentID' AND r2.name=N'DepartmentID'
        AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns x
             WHERE x.constraint_object_id=fk.object_id)=2
   )
    THROW 51104, 'STOP: Required FK mapping or trusted/enabled status differs from approval.', 1;

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
             AND is_unique=1 AND name NOT IN
             (N'PK_DepartmentHead',N'UQ_DepartmentHead_Professor'))
    THROW 51105, 'STOP: Unexpected unique index on DepartmentHead.', 1;

BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.DepartmentHead)
        THROW 51106, 'STOP: DepartmentHead already contains data. Nothing inserted.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Department) <> 8
       OR (SELECT COUNT_BIG(*) FROM dbo.Professor) <> 32
       OR EXISTS
       (
           SELECT 1 FROM dbo.Department d
           LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
           GROUP BY d.DepartmentID
           HAVING COUNT_BIG(p.ProfessorID) <> 4
       )
        THROW 51107, 'STOP: Expected parent population is 8 departments / 32 professors / 4 per department.', 1;

    DECLARE @Expected TABLE
    (
        DepartmentID INT NOT NULL PRIMARY KEY,
        ProfessorID  INT NOT NULL UNIQUE
    );

    INSERT INTO @Expected (DepartmentID, ProfessorID)
    SELECT d.DepartmentID, MIN(p.ProfessorID)
    FROM dbo.Department d
    INNER JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
    GROUP BY d.DepartmentID;

    IF (SELECT COUNT_BIG(*) FROM @Expected) <> 8
       OR EXISTS
       (
           SELECT 1 FROM @Expected e
           LEFT JOIN dbo.Professor p
             ON p.ProfessorID=e.ProfessorID AND p.DepartmentID=e.DepartmentID
           WHERE p.ProfessorID IS NULL
       )
        THROW 51108, 'STOP: Eight unique, valid same-department heads could not be selected.', 1;

    INSERT INTO dbo.DepartmentHead (DepartmentID, ProfessorID)
    SELECT DepartmentID, ProfessorID FROM @Expected;

    IF @@ROWCOUNT <> 8
       OR (SELECT COUNT_BIG(*) FROM dbo.DepartmentHead) <> 8
       OR EXISTS
       (
           SELECT DepartmentID, ProfessorID FROM @Expected
           EXCEPT
           SELECT DepartmentID, ProfessorID FROM dbo.DepartmentHead
       )
       OR EXISTS
       (
           SELECT DepartmentID, ProfessorID FROM dbo.DepartmentHead
           EXCEPT
           SELECT DepartmentID, ProfessorID FROM @Expected
       )
       OR EXISTS
       (
           SELECT 1 FROM dbo.DepartmentHead h
           LEFT JOIN dbo.Professor p
             ON p.ProfessorID=h.ProfessorID AND p.DepartmentID=h.DepartmentID
           WHERE p.ProfessorID IS NULL
       )
       OR EXISTS
       (
           SELECT 1 FROM dbo.Department d
           LEFT JOIN dbo.DepartmentHead h ON h.DepartmentID=d.DepartmentID
           WHERE h.DepartmentID IS NULL
       )
        THROW 51109, 'STOP: Post-insert row-set or business-rule check failed. Rolling back.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    PRINT 'SUCCESS: 8 DepartmentHead rows committed. No previously approved tables were modified.';
    PRINT 'NEXT: Run Phase4_10_Verify_DepartmentHead.sql in full (F5).';

    SELECT h.DepartmentID, d.DepartmentName, h.ProfessorID, p.[Name] AS HeadProfessorName
    FROM dbo.DepartmentHead h
    JOIN dbo.Department d ON d.DepartmentID=h.DepartmentID
    JOIN dbo.Professor p ON p.ProfessorID=h.ProfessorID AND p.DepartmentID=h.DepartmentID
    ORDER BY h.DepartmentID;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
--------------------------------
----Phase4_10_Verify_DepartmentHead
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.DepartmentHead', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Department', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Professor', N'U') IS NULL
BEGIN
    SELECT N'DepartmentHead: Exact Row Set + Schema + PK + UQ + FK' AS VerificationTest,
           'FAIL' AS VerificationResult,
           CAST(NULL AS BIGINT) AS ActualRows,
           CAST(8 AS BIGINT) AS ExpectedRows,
           N'Missing target or parent table' AS Finding;
    RETURN;
END;

-- Baseline of synthetic parent data. Do not modify parents here.
SELECT d.DepartmentID, MIN(p.ProfessorID) AS ProfessorID,
       COUNT_BIG(p.ProfessorID) AS ProfessorCount
INTO #ExpectedHeads
FROM dbo.Department d
LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID
GROUP BY d.DepartmentID;

DECLARE @ActualRows BIGINT=(SELECT COUNT_BIG(*) FROM dbo.DepartmentHead);
DECLARE @ExpectedRows BIGINT=8;
DECLARE @ColumnsOK BIT=0, @PKOK BIT=0, @UQOK BIT=0,
        @FKDepartmentOK BIT=0, @FKProfessorOK BIT=0,
        @ParentsOK BIT=0, @ExactRowsOK BIT=0, @IntegrityOK BIT=0,
        @UnexpectedUniqueOK BIT=0;

IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U'))=2
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
               AND name=N'DepartmentID' AND column_id=1 AND system_type_id=56 AND is_nullable=0)
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
               AND name=N'ProfessorID' AND column_id=2 AND system_type_id=56 AND is_nullable=0)
    SET @ColumnsOK=1;

IF EXISTS
(
   SELECT 1 FROM sys.key_constraints kc
   JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                             AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
   JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
   WHERE kc.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
     AND kc.name=N'PK_DepartmentHead' AND kc.type='PK' AND c.name=N'DepartmentID'
     AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic2
          WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id
            AND ic2.key_ordinal>0)=1
) SET @PKOK=1;

IF EXISTS
(
   SELECT 1 FROM sys.key_constraints kc
   JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                             AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
   JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
   WHERE kc.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
     AND kc.name=N'UQ_DepartmentHead_Professor' AND kc.type='UQ' AND c.name=N'ProfessorID'
     AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic2
          WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id
            AND ic2.key_ordinal>0)=1
) SET @UQOK=1;

IF EXISTS
(
   SELECT 1 FROM sys.foreign_keys fk
   JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
   JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id
   JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id
   WHERE fk.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
     AND fk.referenced_object_id=OBJECT_ID(N'dbo.Department',N'U')
     AND fk.name=N'FK_DepartmentHead_Department' AND fk.is_disabled=0 AND fk.is_not_trusted=0
     AND fc.constraint_column_id=1 AND pc.name=N'DepartmentID' AND rc.name=N'DepartmentID'
     AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns f2 WHERE f2.constraint_object_id=fk.object_id)=1
) SET @FKDepartmentOK=1;

IF EXISTS
(
   SELECT 1 FROM sys.foreign_keys fk
   JOIN sys.foreign_key_columns f1 ON f1.constraint_object_id=fk.object_id AND f1.constraint_column_id=1
   JOIN sys.foreign_key_columns f2 ON f2.constraint_object_id=fk.object_id AND f2.constraint_column_id=2
   JOIN sys.columns p1 ON p1.object_id=f1.parent_object_id AND p1.column_id=f1.parent_column_id
   JOIN sys.columns r1 ON r1.object_id=f1.referenced_object_id AND r1.column_id=f1.referenced_column_id
   JOIN sys.columns p2 ON p2.object_id=f2.parent_object_id AND p2.column_id=f2.parent_column_id
   JOIN sys.columns r2 ON r2.object_id=f2.referenced_object_id AND r2.column_id=f2.referenced_column_id
   WHERE fk.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
     AND fk.referenced_object_id=OBJECT_ID(N'dbo.Professor',N'U')
     AND fk.name=N'FK_DepartmentHead_ProfessorSameDepartment'
     AND fk.is_disabled=0 AND fk.is_not_trusted=0
     AND p1.name=N'ProfessorID' AND r1.name=N'ProfessorID'
     AND p2.name=N'DepartmentID' AND r2.name=N'DepartmentID'
     AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns fx WHERE fx.constraint_object_id=fk.object_id)=2
) SET @FKProfessorOK=1;

IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U'))<>2
    SET @FKDepartmentOK=0;

IF NOT EXISTS
(
  SELECT 1 FROM sys.indexes
  WHERE object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U') AND is_unique=1
    AND name NOT IN(N'PK_DepartmentHead',N'UQ_DepartmentHead_Professor')
) SET @UnexpectedUniqueOK=1;

IF (SELECT COUNT_BIG(*) FROM dbo.Department)=8
   AND (SELECT COUNT_BIG(*) FROM dbo.Professor)=32
   AND (SELECT COUNT_BIG(*) FROM #ExpectedHeads)=8
   AND NOT EXISTS (SELECT 1 FROM #ExpectedHeads WHERE ProfessorCount<>4 OR ProfessorID IS NULL)
    SET @ParentsOK=1;

IF @ActualRows=8
   AND NOT EXISTS
   (
     SELECT DepartmentID, ProfessorID FROM #ExpectedHeads
     EXCEPT SELECT DepartmentID, ProfessorID FROM dbo.DepartmentHead
   )
   AND NOT EXISTS
   (
     SELECT DepartmentID, ProfessorID FROM dbo.DepartmentHead
     EXCEPT SELECT DepartmentID, ProfessorID FROM #ExpectedHeads
   )
    SET @ExactRowsOK=1;

IF NOT EXISTS
(
   SELECT 1 FROM dbo.DepartmentHead h
   LEFT JOIN dbo.Department d ON d.DepartmentID=h.DepartmentID
   LEFT JOIN dbo.Professor p ON p.ProfessorID=h.ProfessorID AND p.DepartmentID=h.DepartmentID
   WHERE d.DepartmentID IS NULL OR p.ProfessorID IS NULL
)
AND NOT EXISTS
(
   SELECT 1 FROM dbo.Department d
   LEFT JOIN dbo.DepartmentHead h ON h.DepartmentID=d.DepartmentID
   WHERE h.DepartmentID IS NULL
)
AND NOT EXISTS
(
   SELECT ProfessorID FROM dbo.DepartmentHead GROUP BY ProfessorID HAVING COUNT_BIG(*)>1
)
    SET @IntegrityOK=1;

-- Result set 1: PRIMARY GATE (this is the screenshot required for sign-off).
SELECT N'DepartmentHead: Exact Row Set + Schema + PK + UQ + FK' AS VerificationTest,
       CASE WHEN @ColumnsOK=1 AND @PKOK=1 AND @UQOK=1
                      AND @FKDepartmentOK=1 AND @FKProfessorOK=1
                      AND @UnexpectedUniqueOK=1 AND @ParentsOK=1
                      AND @ExactRowsOK=1 AND @IntegrityOK=1
            THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       @ActualRows AS ActualRows,
       @ExpectedRows AS ExpectedRows;

-- Result set 2: Individual check statuses; ALL must PASS.
SELECT Item, CASE WHEN Passed=1 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM
(
 VALUES
 (N'Exact two INT NOT NULL columns',@ColumnsOK),
 (N'PK DepartmentID',@PKOK),
 (N'UNIQUE ProfessorID',@UQOK),
 (N'FK Department enabled/trusted',@FKDepartmentOK),
 (N'Composite FK ProfessorSameDepartment enabled/trusted',@FKProfessorOK),
 (N'No unexpected UNIQUE indexes',@UnexpectedUniqueOK),
 (N'8 departments / 32 professors / 4 professors per department',@ParentsOK),
 (N'Exact eight-row expected set',@ExactRowsOK),
 (N'Every department headed; all heads valid; no reused professor',@IntegrityOK)
) AS Tests(Item,Passed);

-- Result set 3: Human-readable exact head assignments.
SELECT h.DepartmentID,d.DepartmentName,h.ProfessorID,p.[Name] AS HeadProfessorName
FROM dbo.DepartmentHead h
JOIN dbo.Department d ON d.DepartmentID=h.DepartmentID
JOIN dbo.Professor p ON p.ProfessorID=h.ProfessorID AND p.DepartmentID=h.DepartmentID
ORDER BY h.DepartmentID;

-- Result sets 4/5: both expected ZERO rows.
SELECT DepartmentID,ProfessorID FROM #ExpectedHeads
EXCEPT SELECT DepartmentID,ProfessorID FROM dbo.DepartmentHead;

SELECT DepartmentID,ProfessorID FROM dbo.DepartmentHead
EXCEPT SELECT DepartmentID,ProfessorID FROM #ExpectedHeads;

-- Result set 6: Department-level coverage; exactly eight rows, each HeadCount = 1.
SELECT d.DepartmentID,d.DepartmentName,COUNT_BIG(h.ProfessorID) AS HeadCount
FROM dbo.Department d
LEFT JOIN dbo.DepartmentHead h ON h.DepartmentID=d.DepartmentID
GROUP BY d.DepartmentID,d.DepartmentName
ORDER BY d.DepartmentID;

-- Result set 7: Column metadata.
SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,
       TYPE_NAME(c.system_type_id) AS DataType,c.is_nullable AS IsNullable
FROM sys.columns c
WHERE c.object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
ORDER BY c.column_id;

-- Result set 8: PK and UNIQUE definitions.
SELECT kc.name AS ConstraintName,kc.type_desc AS ConstraintType,
       c.name AS KeyColumn,ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                         AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE kc.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
ORDER BY kc.name,ic.key_ordinal;

-- Result set 9: Both FK constraints and mapped columns; all IsDisabled/IsNotTrusted = 0.
SELECT fk.name AS ForeignKeyName, fkc.constraint_column_id AS ColumnOrder,
       pc.name AS ParentColumn,OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.DepartmentHead',N'U')
ORDER BY fk.name,fkc.constraint_column_id;

DROP TABLE #ExpectedHeads;
-------------------------------------
GO
