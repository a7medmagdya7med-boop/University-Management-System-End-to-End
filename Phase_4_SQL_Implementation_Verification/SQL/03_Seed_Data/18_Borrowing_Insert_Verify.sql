-- Extracted from UniversityManagementDB(2).sql; source lines 7969-8429.
USE [UniversityManagementDB];
GO
--Table 18 — Borrowing
--Phase4_18_Insert_Borrowing
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    BEGIN TRANSACTION;

    IF DB_NAME() <> N'UniversityManagementDB'
        THROW 51801, 'STOP: wrong database selected.', 1;
    IF OBJECT_ID(N'dbo.Borrowing',N'U') IS NULL
       OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
       OR OBJECT_ID(N'dbo.Book',N'U') IS NULL
        THROW 51802, 'STOP: Borrowing/Student/Book missing. Do not change schema.', 1;

    -- Parents must match previously approved exact ID populations.
    IF (SELECT COUNT_BIG(*) FROM dbo.Student)<>64
       OR EXISTS (SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)
       OR (SELECT COUNT_BIG(*) FROM dbo.Book)<>32
       OR EXISTS (SELECT 1 FROM dbo.Book WHERE BookID NOT BETWEEN 3001 AND 3032)
        THROW 51803, 'STOP: Student/Book baseline differs from approved seed.', 1;

    -- Defensive DDL checks: never repair an unauthorized schema automatically.
    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes AS i
        JOIN sys.index_columns AS ic
          ON ic.object_id=i.object_id AND ic.index_id=i.index_id AND ic.key_ordinal=1
        JOIN sys.columns AS c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE i.object_id=OBJECT_ID(N'dbo.Borrowing',N'U')
          AND i.name=N'UX_Borrowing_OneOpenLoanPerBook'
          AND i.is_unique=1 AND i.has_filter=1 AND i.is_disabled=0
          AND UPPER(REPLACE(REPLACE(REPLACE(i.filter_definition,N'[',N''),N']',N''),N' ',N'')) LIKE N'%RETURNDATEISNULL%'
          AND c.name=N'BookID'
          AND (SELECT COUNT(*) FROM sys.index_columns AS z
               WHERE z.object_id=i.object_id AND z.index_id=i.index_id AND z.key_ordinal>0)=1
    )
        THROW 51804, 'STOP: approved filtered UNIQUE index is absent/disabled/changed.', 1;

    IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys
        WHERE parent_object_id=OBJECT_ID(N'dbo.Borrowing',N'U')
          AND is_disabled=0 AND is_not_trusted=0)<>2
        THROW 51805, 'STOP: expected 2 enabled trusted Borrowing foreign keys.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Borrowing WITH (UPDLOCK,HOLDLOCK))
        THROW 51806, 'STOP: Borrowing already contains rows; no INSERT attempted.', 1;

    IF OBJECT_ID(N'tempdb..#ExpectedBorrowing',N'U') IS NOT NULL
        DROP TABLE #ExpectedBorrowing;
    CREATE TABLE #ExpectedBorrowing
    (
        BorrowingID BIGINT NOT NULL PRIMARY KEY,
        StudentID INT NOT NULL,
        BookID INT NOT NULL,
        BorrowDate DATE NOT NULL,
        DueDate DATE NOT NULL,
        ReturnDate DATE NULL
    );

-- Fixed reproducible seed: 32 physical book copies x 3 borrowing events.
-- Status at 2026-10-24: 80 returned, 16 open (8 overdue, 8 not overdue).
;WITH BookCopies AS
(
    SELECT n FROM (VALUES
       (1),(2),(3),(4),(5),(6),(7),(8),
       (9),(10),(11),(12),(13),(14),(15),(16),
       (17),(18),(19),(20),(21),(22),(23),(24),
       (25),(26),(27),(28),(29),(30),(31),(32)
    ) AS x(n)
),
LoanCycles AS (SELECT CycleNo FROM (VALUES (1),(2),(3)) AS x(CycleNo))
INSERT INTO #ExpectedBorrowing
    (BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate)
SELECT
    CONVERT(BIGINT,180000 + (p.CycleNo-1)*32+b.n) AS BorrowingID,
    10001 + (((p.CycleNo-1)*32+b.n-1)%48) AS StudentID,
    3000+b.n AS BookID,
    d.BorrowDate,
    DATEADD(DAY,14,d.BorrowDate) AS DueDate,
    CASE
        WHEN p.CycleNo=1 THEN DATEADD(DAY,6+b.n%7,d.BorrowDate)
        WHEN p.CycleNo=2 THEN DATEADD(DAY,10+b.n%9,d.BorrowDate)
        WHEN b.n%2=0 THEN NULL
        ELSE DATEADD(DAY,3,d.BorrowDate)
    END AS ReturnDate
FROM BookCopies AS b
CROSS JOIN LoanCycles AS p
CROSS APPLY
(
    SELECT CASE p.CycleNo
       WHEN 1 THEN DATEADD(DAY,(b.n-1)%20,CONVERT(DATE,'2025-10-01',23))
       WHEN 2 THEN DATEADD(DAY,(b.n-1)%18,CONVERT(DATE,'2026-02-10',23))
       ELSE DATEADD(DAY,(b.n-1)%18,CONVERT(DATE,'2026-10-02',23))
    END AS BorrowDate
) AS d;

    IF (SELECT COUNT_BIG(*) FROM #ExpectedBorrowing)<>96
       OR EXISTS (SELECT 1 FROM #ExpectedBorrowing WHERE DueDate<BorrowDate
                  OR (ReturnDate IS NOT NULL AND ReturnDate<BorrowDate))
       OR EXISTS (SELECT 1 FROM #ExpectedBorrowing AS e
                  LEFT JOIN dbo.Student AS s ON s.StudentID=e.StudentID
                  LEFT JOIN dbo.Book AS b ON b.BookID=e.BookID
                  WHERE s.StudentID IS NULL OR b.BookID IS NULL)
        THROW 51807, 'STOP: generated borrowing seed failed quality/parent checks.', 1;

    INSERT INTO dbo.Borrowing
        (BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate)
    SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate
    FROM #ExpectedBorrowing;

    IF @@ROWCOUNT<>96
       OR (SELECT COUNT_BIG(*) FROM dbo.Borrowing)<>96
       OR EXISTS
       (
           SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate
           FROM #ExpectedBorrowing
           EXCEPT
           SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate
           FROM dbo.Borrowing
       )
       OR EXISTS
       (
           SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate
           FROM dbo.Borrowing
           EXCEPT
           SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate
           FROM #ExpectedBorrowing
       )
        THROW 51808, 'STOP: inserted rows did not match expected seed exactly.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 96 Borrowing rows inserted and committed; parent tables unchanged.';
    SELECT COUNT_BIG(*) AS ActualRows,
           CONVERT(BIGINT,96) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.Borrowing;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
---------------------------
--------Phase4_18_Verify_Borrowing
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51821, 'STOP: wrong database selected.', 1;
IF OBJECT_ID(N'dbo.Borrowing',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
   OR OBJECT_ID(N'dbo.Book',N'U') IS NULL
    THROW 51822, 'STOP: Borrowing/Student/Book table is missing.', 1;

IF OBJECT_ID(N'tempdb..#Checks',N'U') IS NOT NULL DROP TABLE #Checks;
IF OBJECT_ID(N'tempdb..#ExpectedBorrowing',N'U') IS NOT NULL DROP TABLE #ExpectedBorrowing;
CREATE TABLE #Checks
(
    CheckID INT IDENTITY(1,1) PRIMARY KEY,
    Item NVARCHAR(220) NOT NULL,
    Result VARCHAR(4) NOT NULL
);
CREATE TABLE #ExpectedBorrowing
(
    BorrowingID BIGINT NOT NULL PRIMARY KEY,
    StudentID INT NOT NULL,
    BookID INT NOT NULL,
    BorrowDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL
);

-- Fixed reproducible seed: 32 physical book copies x 3 borrowing events.
-- Status at 2026-10-24: 80 returned, 16 open (8 overdue, 8 not overdue).
;WITH BookCopies AS
(
    SELECT n FROM (VALUES
       (1),(2),(3),(4),(5),(6),(7),(8),
       (9),(10),(11),(12),(13),(14),(15),(16),
       (17),(18),(19),(20),(21),(22),(23),(24),
       (25),(26),(27),(28),(29),(30),(31),(32)
    ) AS x(n)
),
LoanCycles AS (SELECT CycleNo FROM (VALUES (1),(2),(3)) AS x(CycleNo))
INSERT INTO #ExpectedBorrowing
    (BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate)
SELECT
    CONVERT(BIGINT,180000 + (p.CycleNo-1)*32+b.n) AS BorrowingID,
    10001 + (((p.CycleNo-1)*32+b.n-1)%48) AS StudentID,
    3000+b.n AS BookID,
    d.BorrowDate,
    DATEADD(DAY,14,d.BorrowDate) AS DueDate,
    CASE
        WHEN p.CycleNo=1 THEN DATEADD(DAY,6+b.n%7,d.BorrowDate)
        WHEN p.CycleNo=2 THEN DATEADD(DAY,10+b.n%9,d.BorrowDate)
        WHEN b.n%2=0 THEN NULL
        ELSE DATEADD(DAY,3,d.BorrowDate)
    END AS ReturnDate
FROM BookCopies AS b
CROSS JOIN LoanCycles AS p
CROSS APPLY
(
    SELECT CASE p.CycleNo
       WHEN 1 THEN DATEADD(DAY,(b.n-1)%20,CONVERT(DATE,'2025-10-01',23))
       WHEN 2 THEN DATEADD(DAY,(b.n-1)%18,CONVERT(DATE,'2026-02-10',23))
       ELSE DATEADD(DAY,(b.n-1)%18,CONVERT(DATE,'2026-10-02',23))
    END AS BorrowDate
) AS d;

DECLARE @oid INT=OBJECT_ID(N'dbo.Borrowing',N'U');
DECLARE @AsOfDate DATE=CONVERT(DATE,'2026-10-24',23);

DECLARE @ExpectedColumns TABLE
(ColumnOrder INT NOT NULL PRIMARY KEY,ColumnName SYSNAME NOT NULL,TypeID TINYINT NOT NULL,IsNullable BIT NOT NULL);
INSERT INTO @ExpectedColumns VALUES
(1,N'BorrowingID',127,0),
(2,N'StudentID',56,0),
(3,N'BookID',56,0),
(4,N'BorrowDate',40,0),
(5,N'DueDate',40,0),
(6,N'ReturnDate',40,1);

INSERT #Checks(Item,Result)
SELECT N'1. Six approved columns, order, native data types and nullability',
CASE WHEN NOT EXISTS
   (SELECT ColumnOrder,ColumnName,TypeID,IsNullable FROM @ExpectedColumns
    EXCEPT
    SELECT column_id,name,system_type_id,is_nullable FROM sys.columns WHERE object_id=@oid)
    AND NOT EXISTS
   (SELECT column_id,name,system_type_id,is_nullable FROM sys.columns WHERE object_id=@oid
    EXCEPT
    SELECT ColumnOrder,ColumnName,TypeID,IsNullable FROM @ExpectedColumns)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'2. Approved PK_Borrowing on BorrowingID alone',
CASE WHEN EXISTS
  (SELECT 1 FROM sys.key_constraints k
   JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id AND ic.key_ordinal=1
   JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
   WHERE k.parent_object_id=@oid AND k.name=N'PK_Borrowing' AND k.type='PK' AND c.name=N'BorrowingID'
     AND (SELECT COUNT(*) FROM sys.index_columns z WHERE z.object_id=ic.object_id AND z.index_id=ic.index_id AND z.key_ordinal>0)=1)
  AND (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@oid AND type='PK')=1
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'3. Enabled trusted FK_Borrowing_Student mapped StudentID -> StudentID',
CASE WHEN EXISTS
 (SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@oid AND fk.name=N'FK_Borrowing_Student'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Student',N'U')
    AND pc.name=N'StudentID' AND rc.name=N'StudentID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0 AND fkc.constraint_column_id=1
    AND (SELECT COUNT(*) FROM sys.foreign_key_columns z WHERE z.constraint_object_id=fk.object_id)=1)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'4. Enabled trusted FK_Borrowing_Book mapped BookID -> BookID',
CASE WHEN EXISTS
 (SELECT 1 FROM sys.foreign_keys fk
  JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
  JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
  JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
  WHERE fk.parent_object_id=@oid AND fk.name=N'FK_Borrowing_Book'
    AND fk.referenced_object_id=OBJECT_ID(N'dbo.Book',N'U')
    AND pc.name=N'BookID' AND rc.name=N'BookID'
    AND fk.is_disabled=0 AND fk.is_not_trusted=0 AND fkc.constraint_column_id=1
    AND (SELECT COUNT(*) FROM sys.foreign_key_columns z WHERE z.constraint_object_id=fk.object_id)=1)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'5. Exactly two approved foreign keys, both enabled and trusted',
CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid)=2
 AND (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@oid AND is_disabled=0 AND is_not_trusted=0)=2
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'6. Approved DueDate CHECK enabled/trusted',
CASE WHEN EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid
 AND name=N'CK_Borrowing_DueDate' AND is_disabled=0 AND is_not_trusted=0)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'7. Approved ReturnDate CHECK enabled/trusted',
CASE WHEN EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid
 AND name=N'CK_Borrowing_ReturnDate' AND is_disabled=0 AND is_not_trusted=0)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'8. Exactly two approved CHECK constraints, no extras',
CASE WHEN (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=@oid)=2
 AND NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@oid
    AND name NOT IN(N'CK_Borrowing_DueDate',N'CK_Borrowing_ReturnDate'))
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'9. Filtered UNIQUE index: at most one open loan per BookID',
CASE WHEN EXISTS
 (SELECT 1 FROM sys.indexes i
  JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id AND ic.key_ordinal=1
  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
  WHERE i.object_id=@oid AND i.name=N'UX_Borrowing_OneOpenLoanPerBook'
    AND i.is_unique=1 AND i.has_filter=1 AND i.is_disabled=0 AND c.name=N'BookID'
    AND UPPER(REPLACE(REPLACE(REPLACE(i.filter_definition,N'[',N''),N']',N''),N' ',N'')) LIKE N'%RETURNDATEISNULL%'
    AND (SELECT COUNT(*) FROM sys.index_columns z WHERE z.object_id=i.object_id AND z.index_id=i.index_id AND z.key_ordinal>0)=1)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'10. No unauthorized extra UNIQUE indexes or UNIQUE constraints',
CASE WHEN NOT EXISTS
 (SELECT 1 FROM sys.indexes WHERE object_id=@oid AND is_unique=1
   AND name NOT IN(N'PK_Borrowing',N'UX_Borrowing_OneOpenLoanPerBook'))
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'11. Parents unchanged: exactly 64 approved Students and 32 Books',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64
 AND NOT EXISTS(SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)
 AND (SELECT COUNT_BIG(*) FROM dbo.Book)=32
 AND NOT EXISTS(SELECT 1 FROM dbo.Book WHERE BookID NOT BETWEEN 3001 AND 3032)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'12. Exactly 96 expected Borrowing records',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Borrowing)=96
 AND (SELECT COUNT_BIG(*) FROM #ExpectedBorrowing)=96
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'13. Exact expected row set: no missing, extra or altered borrowing rows',
CASE WHEN NOT EXISTS
 (SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM #ExpectedBorrowing
  EXCEPT
  SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM dbo.Borrowing)
 AND NOT EXISTS
 (SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM dbo.Borrowing
  EXCEPT
  SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM #ExpectedBorrowing)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'14. Every loan refers to an existing Student and physical Book',
CASE WHEN NOT EXISTS
 (SELECT 1 FROM dbo.Borrowing br
  LEFT JOIN dbo.Student s ON s.StudentID=br.StudentID
  LEFT JOIN dbo.Book b ON b.BookID=br.BookID
  WHERE s.StudentID IS NULL OR b.BookID IS NULL)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'15. All due dates on/after borrow date',
CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.Borrowing WHERE DueDate<BorrowDate)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'16. All recorded returns on/after borrow date',
CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.Borrowing WHERE ReturnDate<BorrowDate)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'17. Exactly 80 returned and 16 open loans',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Borrowing WHERE ReturnDate IS NOT NULL)=80
 AND (SELECT COUNT_BIG(*) FROM dbo.Borrowing WHERE ReturnDate IS NULL)=16
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'18. No physical book has more than one open loan',
CASE WHEN NOT EXISTS
 (SELECT BookID FROM dbo.Borrowing WHERE ReturnDate IS NULL GROUP BY BookID HAVING COUNT_BIG(*)>1)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'19. Open loans as of 2026-10-24: 8 overdue, 8 not overdue',
CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Borrowing
           WHERE ReturnDate IS NULL AND DueDate<@AsOfDate)=8
 AND (SELECT COUNT_BIG(*) FROM dbo.Borrowing
      WHERE ReturnDate IS NULL AND DueDate>=@AsOfDate)=8
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'20. Exactly 32 BookIDs have three borrowing history rows each',
CASE WHEN (SELECT COUNT(DISTINCT BookID) FROM dbo.Borrowing)=32
 AND NOT EXISTS (SELECT BookID FROM dbo.Borrowing GROUP BY BookID HAVING COUNT_BIG(*)<>3)
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'21. Exactly 48 Students have two loans each; 16 without loans',
CASE WHEN (SELECT COUNT(DISTINCT StudentID) FROM dbo.Borrowing)=48
 AND NOT EXISTS(SELECT StudentID FROM dbo.Borrowing GROUP BY StudentID HAVING COUNT_BIG(*)<>2)
 AND (SELECT COUNT_BIG(*) FROM dbo.Student s WHERE NOT EXISTS
     (SELECT 1 FROM dbo.Borrowing br WHERE br.StudentID=s.StudentID))=16
THEN 'PASS' ELSE 'FAIL' END;

INSERT #Checks(Item,Result)
SELECT N'22. All recorded return dates not later than fixed snapshot 2026-10-24',
CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.Borrowing WHERE ReturnDate>@AsOfDate)
THEN 'PASS' ELSE 'FAIL' END;

-- Result set 1: approve only if PASS with 0 FailedChecks.
SELECT
  N'Borrowing: Exact Row Set + Schema + PK + FK + CHECK + Filtered UX' AS VerificationTest,
  CASE WHEN NOT EXISTS(SELECT 1 FROM #Checks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
  (SELECT COUNT_BIG(*) FROM dbo.Borrowing) AS ActualRows,
  CONVERT(BIGINT,96) AS ExpectedRows,
  (SELECT COUNT(*) FROM #Checks) AS ChecksEvaluated,
  (SELECT COUNT(*) FROM #Checks WHERE Result='FAIL') AS FailedChecks;

-- Result set 2: individual quality and schema checks.
SELECT CheckID,Item,Result FROM #Checks ORDER BY CheckID;

-- Result set 3: sample loan records with title and student name.
SELECT TOP (16) br.BorrowingID,br.StudentID,s.[Name] AS StudentName,
       br.BookID,b.BookTitle,br.BorrowDate,br.DueDate,br.ReturnDate,
       CASE WHEN br.ReturnDate IS NOT NULL THEN 'Returned'
            WHEN br.DueDate<@AsOfDate THEN 'Overdue (as of 2026-10-24)'
            ELSE 'Open / not overdue' END AS LoanStatus
FROM dbo.Borrowing br
JOIN dbo.Student s ON s.StudentID=br.StudentID
JOIN dbo.Book b ON b.BookID=br.BookID
ORDER BY br.BorrowingID DESC;

-- Result set 4: snapshot aggregation.
SELECT CASE WHEN ReturnDate IS NOT NULL THEN 'Returned'
            WHEN DueDate<@AsOfDate THEN 'Overdue (as of 2026-10-24)'
            ELSE 'Open / not overdue' END AS LoanStatus,
       COUNT_BIG(*) AS LoanCount
FROM dbo.Borrowing
GROUP BY CASE WHEN ReturnDate IS NOT NULL THEN 'Returned'
              WHEN DueDate<@AsOfDate THEN 'Overdue (as of 2026-10-24)'
              ELSE 'Open / not overdue' END;

-- Result set 5: missing or extra records; zero rows expected.
SELECT N'Missing' AS Mismatch, q.* FROM
(SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM #ExpectedBorrowing
 EXCEPT SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM dbo.Borrowing) AS q
UNION ALL
SELECT N'Extra' AS Mismatch, q.* FROM
(SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM dbo.Borrowing
 EXCEPT SELECT BorrowingID,StudentID,BookID,BorrowDate,DueDate,ReturnDate FROM #ExpectedBorrowing) AS q;

-- Result set 6: configured PK, FKs, date CHECK constraints and filtered index.
SELECT name AS ConstraintName,type_desc AS ConstraintType
FROM sys.objects WHERE parent_object_id=@oid AND type IN('PK','UQ','F','C')
ORDER BY type_desc,name;
SELECT i.name AS IndexName,i.is_unique AS IsUnique,i.has_filter AS HasFilter,
       i.filter_definition AS FilterDefinition,i.is_disabled AS IsDisabled
FROM sys.indexes i WHERE i.object_id=@oid AND i.name=N'UX_Borrowing_OneOpenLoanPerBook';

DROP TABLE #Checks;
DROP TABLE #ExpectedBorrowing;
GO
----------------------------------------
GO
