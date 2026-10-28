-- Extracted from UniversityManagementDB(2).sql; source lines 7095-7496.
USE [UniversityManagementDB];
GO
--Table 16/21 — UniversityIDCard
--Phase4_16_Insert_UniversityIDCard
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    BEGIN TRANSACTION;

    IF DB_NAME() <> N'UniversityManagementDB'
        THROW 51601, 'STOP: Wrong database.', 1;

    IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.UniversityIDCard', N'U') IS NULL
        THROW 51602, 'STOP: Student or UniversityIDCard table is missing.', 1;

    -- Exact three-column approved DDL, including ordinal, type, length and nullability.
    IF (SELECT COUNT(*) FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')) <> 3
       OR (SELECT COUNT(*) FROM sys.columns AS c
           WHERE c.object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
             AND (
                 (c.column_id = 1 AND c.name = N'CardNumber'
                  AND c.system_type_id = 231 AND c.max_length = 64 AND c.is_nullable = 0)
              OR (c.column_id = 2 AND c.name = N'StudentID'
                  AND c.system_type_id = 56 AND c.is_nullable = 0)
              OR (c.column_id = 3 AND c.name = N'IssueDate'
                  AND c.system_type_id = 40 AND c.is_nullable = 0)
             )) <> 3
        THROW 51603, 'STOP: UniversityIDCard column schema differs from the approved DDL.', 1;

    -- The card number is the single-column primary key.
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints AS kc
        JOIN sys.index_columns AS ic
          ON ic.object_id = kc.parent_object_id
         AND ic.index_id = kc.unique_index_id
         AND ic.key_ordinal = 1
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
          AND kc.name = N'PK_UniversityIDCard' AND kc.type = 'PK'
          AND c.name = N'CardNumber'
          AND (SELECT COUNT(*) FROM sys.index_columns AS ic2
               WHERE ic2.object_id = ic.object_id
                 AND ic2.index_id = ic.index_id AND ic2.key_ordinal > 0) = 1
    )
        THROW 51604, 'STOP: Approved CardNumber PK was not found.', 1;

    -- One card per student: approved StudentID UNIQUE constraint, one key column.
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints AS kc
        JOIN sys.index_columns AS ic
          ON ic.object_id = kc.parent_object_id
         AND ic.index_id = kc.unique_index_id
         AND ic.key_ordinal = 1
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
          AND kc.name = N'UQ_UniversityIDCard_StudentID' AND kc.type = 'UQ'
          AND c.name = N'StudentID'
          AND (SELECT COUNT(*) FROM sys.index_columns AS ic2
               WHERE ic2.object_id = ic.object_id
                 AND ic2.index_id = ic.index_id AND ic2.key_ordinal > 0) = 1
    )
        THROW 51605, 'STOP: Approved StudentID UNIQUE constraint was not found.', 1;

    -- Exact FK from UniversityIDCard.StudentID to Student.StudentID; enabled and trusted.
    IF (SELECT COUNT(*) FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')) <> 1
       OR NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys AS fk
           JOIN sys.foreign_key_columns AS fkc
             ON fkc.constraint_object_id = fk.object_id
           JOIN sys.columns AS parentcol
             ON parentcol.object_id = fkc.parent_object_id
            AND parentcol.column_id = fkc.parent_column_id
           JOIN sys.columns AS refcol
             ON refcol.object_id = fkc.referenced_object_id
            AND refcol.column_id = fkc.referenced_column_id
           WHERE fk.parent_object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
             AND fk.name = N'FK_UniversityIDCard_Student'
             AND fk.referenced_object_id = OBJECT_ID(N'dbo.Student', N'U')
             AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
             AND parentcol.name = N'StudentID' AND refcol.name = N'StudentID'
             AND (SELECT COUNT(*) FROM sys.foreign_key_columns AS f2
                  WHERE f2.constraint_object_id = fk.object_id) = 1
       )
        THROW 51606, 'STOP: Approved enabled/trusted Student FK was not found.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sys.indexes AS i
        WHERE i.object_id = OBJECT_ID(N'dbo.UniversityIDCard', N'U')
          AND i.is_unique = 1
          AND i.name NOT IN (N'PK_UniversityIDCard', N'UQ_UniversityIDCard_StudentID')
    )
        THROW 51607, 'STOP: Unapproved UNIQUE index on UniversityIDCard.', 1;

    -- Protect the entire approved Student baseline (IDs contiguous by PK).
    IF (SELECT COUNT_BIG(*) FROM dbo.Student WITH (HOLDLOCK)) <> 64
       OR (SELECT MIN(StudentID) FROM dbo.Student) <> 10001
       OR (SELECT MAX(StudentID) FROM dbo.Student) <> 10064
        THROW 51608, 'STOP: Approved Student baseline (64 IDs 10001..10064) does not match.', 1;

    -- Never overwrite, delete or append to any preexisting target data.
    IF EXISTS (SELECT 1 FROM dbo.UniversityIDCard WITH (UPDLOCK, HOLDLOCK))
        THROW 51609, 'STOP: UniversityIDCard contains data. No changes made.', 1;

    CREATE TABLE #ExpectedUniversityIDCard
    (
        CardNumber NVARCHAR(32) NOT NULL PRIMARY KEY,
        StudentID INT NOT NULL UNIQUE,
        IssueDate DATE NOT NULL
    );

    -- Deterministic seed, generated independently from target table state.
    -- 48 students (10001..10048), issue dates 2026-09-01 through 2026-10-18.
    INSERT INTO #ExpectedUniversityIDCard (CardNumber, StudentID, IssueDate)
    SELECT CONCAT(N'UID-2026-', CONVERT(NVARCHAR(10), 10001 + (t.n * 10 + u.n))),
           10001 + (t.n * 10 + u.n),
           DATEADD(DAY, t.n * 10 + u.n, CONVERT(DATE, '20260901', 112))
    FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(n)
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS u(n)
    WHERE (t.n * 10 + u.n) < 48;

    IF (SELECT COUNT(*) FROM #ExpectedUniversityIDCard) <> 48
        THROW 51610, 'STOP: Expected card seed must contain exactly 48 records.', 1;

    IF EXISTS
    (
        SELECT 1 FROM #ExpectedUniversityIDCard AS e
        LEFT JOIN dbo.Student AS s WITH (HOLDLOCK) ON s.StudentID = e.StudentID
        WHERE s.StudentID IS NULL
    )
        THROW 51611, 'STOP: At least one target StudentID does not exist.', 1;

    INSERT INTO dbo.UniversityIDCard (CardNumber, StudentID, IssueDate)
    SELECT CardNumber, StudentID, IssueDate
    FROM #ExpectedUniversityIDCard;

    IF (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard) <> 48
        THROW 51612, 'STOP: Inserted row count is not 48.', 1;

    IF EXISTS
       (SELECT CardNumber, StudentID, IssueDate FROM dbo.UniversityIDCard
        EXCEPT
        SELECT CardNumber, StudentID, IssueDate FROM #ExpectedUniversityIDCard)
       OR EXISTS
       (SELECT CardNumber, StudentID, IssueDate FROM #ExpectedUniversityIDCard
        EXCEPT
        SELECT CardNumber, StudentID, IssueDate FROM dbo.UniversityIDCard)
        THROW 51613, 'STOP: Inserted data does not exactly match the expected seed.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 48 UniversityIDCard rows inserted and committed; no previous tables changed.';

    SELECT COUNT_BIG(*) AS ActualRows,
           CONVERT(BIGINT, 48) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.UniversityIDCard;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
-------------------------
---Phase4_16_Verify_UniversityIDCard
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51701, 'STOP: Wrong database.', 1;
IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
   OR OBJECT_ID(N'dbo.UniversityIDCard', N'U') IS NULL
    THROW 51702, 'STOP: Student or UniversityIDCard table is missing.', 1;

-- Safe repeat execution in the SAME SSMS session. Only session-local #temp tables are removed.
-- No dbo tables, existing data, or approved constraints are changed.
DROP TABLE IF EXISTS #Checks;
DROP TABLE IF EXISTS #ExpectedUniversityIDCard;

CREATE TABLE #ExpectedUniversityIDCard
(
    CardNumber NVARCHAR(32) NOT NULL PRIMARY KEY,
    StudentID INT NOT NULL UNIQUE,
    IssueDate DATE NOT NULL
);
INSERT INTO #ExpectedUniversityIDCard (CardNumber, StudentID, IssueDate)
SELECT CONCAT(N'UID-2026-', CONVERT(NVARCHAR(10), 10001 + t.n * 10 + u.n)),
       10001 + t.n * 10 + u.n,
       DATEADD(DAY, t.n * 10 + u.n, CONVERT(DATE, '20260901', 112))
FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(n)
CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS u(n)
WHERE t.n * 10 + u.n < 48;

CREATE TABLE #Checks
(
    CheckID INT NOT NULL PRIMARY KEY,
    Item NVARCHAR(220) NOT NULL,
    Result VARCHAR(4) NOT NULL
);

DECLARE @ObjectID INT = OBJECT_ID(N'dbo.UniversityIDCard', N'U');

INSERT INTO #Checks VALUES
(1, N'Approved UniversityIDCard table exists',
    CASE WHEN @ObjectID IS NOT NULL THEN 'PASS' ELSE 'FAIL' END);

INSERT INTO #Checks
SELECT 2, N'Exactly three approved columns: order, type, width and NOT NULL',
       CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id=@ObjectID)=3
             AND (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id=@ObjectID AND
             ((c.column_id=1 AND c.name=N'CardNumber' AND c.system_type_id=231 AND c.max_length=64 AND c.is_nullable=0)
              OR (c.column_id=2 AND c.name=N'StudentID' AND c.system_type_id=56 AND c.is_nullable=0)
              OR (c.column_id=3 AND c.name=N'IssueDate' AND c.system_type_id=40 AND c.is_nullable=0)))=3
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 3, N'Approved one-column PK: PK_UniversityIDCard(CardNumber)',
       CASE WHEN EXISTS
       (SELECT 1 FROM sys.key_constraints kc
        JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
        JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE kc.parent_object_id=@ObjectID AND kc.name=N'PK_UniversityIDCard'
          AND kc.type='PK' AND c.name=N'CardNumber'
          AND (SELECT COUNT(*) FROM sys.index_columns ic2
               WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id AND ic2.key_ordinal>0)=1)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 4, N'Approved one-column UNIQUE: UQ_UniversityIDCard_StudentID(StudentID)',
       CASE WHEN EXISTS
       (SELECT 1 FROM sys.key_constraints kc
        JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
        JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE kc.parent_object_id=@ObjectID AND kc.name=N'UQ_UniversityIDCard_StudentID'
          AND kc.type='UQ' AND c.name=N'StudentID'
          AND (SELECT COUNT(*) FROM sys.index_columns ic2
               WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id AND ic2.key_ordinal>0)=1)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 5, N'Exactly one FK: StudentID -> Student.StudentID; enabled and trusted',
       CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@ObjectID)=1
         AND EXISTS
         (SELECT 1 FROM sys.foreign_keys fk
          JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
          JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
          JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
          WHERE fk.parent_object_id=@ObjectID
            AND fk.name=N'FK_UniversityIDCard_Student'
            AND fk.referenced_object_id=OBJECT_ID(N'dbo.Student', N'U')
            AND fk.is_disabled=0 AND fk.is_not_trusted=0
            AND pc.name=N'StudentID' AND rc.name=N'StudentID'
            AND (SELECT COUNT(*) FROM sys.foreign_key_columns f2
                 WHERE f2.constraint_object_id=fk.object_id)=1)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 6, N'Exactly PK and StudentID UQ; no extra unique constraints/indexes',
       CASE WHEN (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@ObjectID)=2
         AND NOT EXISTS
         (SELECT 1 FROM sys.indexes i WHERE i.object_id=@ObjectID AND i.is_unique=1
          AND i.name NOT IN (N'PK_UniversityIDCard', N'UQ_UniversityIDCard_StudentID'))
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 7, N'Parent Student baseline: 64 IDs from 10001 through 10064',
       CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64
                  AND (SELECT MIN(StudentID) FROM dbo.Student)=10001
                  AND (SELECT MAX(StudentID) FROM dbo.Student)=10064
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 8, N'Expected seed has exactly 48 unique card/student pairs',
       CASE WHEN (SELECT COUNT_BIG(*) FROM #ExpectedUniversityIDCard)=48
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 9, N'Actual UniversityIDCard contains exactly 48 rows',
       CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard)=48
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 10, N'Exact seed: no missing, extra, or altered rows',
       CASE WHEN NOT EXISTS
         (SELECT CardNumber,StudentID,IssueDate FROM dbo.UniversityIDCard
          EXCEPT SELECT CardNumber,StudentID,IssueDate FROM #ExpectedUniversityIDCard)
         AND NOT EXISTS
         (SELECT CardNumber,StudentID,IssueDate FROM #ExpectedUniversityIDCard
          EXCEPT SELECT CardNumber,StudentID,IssueDate FROM dbo.UniversityIDCard)
         AND (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard)=48
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 11, N'No duplicate StudentID/card holder',
       CASE WHEN NOT EXISTS
         (SELECT StudentID FROM dbo.UniversityIDCard GROUP BY StudentID HAVING COUNT_BIG(*)>1)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 12, N'No duplicate or empty CardNumber',
       CASE WHEN NOT EXISTS
         (SELECT CardNumber FROM dbo.UniversityIDCard GROUP BY CardNumber HAVING COUNT_BIG(*)>1)
         AND NOT EXISTS
         (SELECT 1 FROM dbo.UniversityIDCard
          WHERE CardNumber IS NULL OR LEN(LTRIM(RTRIM(CardNumber)))=0)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 13, N'No StudentID orphan references',
       CASE WHEN NOT EXISTS
         (SELECT 1 FROM dbo.UniversityIDCard uc
          LEFT JOIN dbo.Student s ON s.StudentID=uc.StudentID
          WHERE s.StudentID IS NULL)
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 14, N'48 issued students and 16 students without a card',
       CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student s
                  WHERE EXISTS (SELECT 1 FROM dbo.UniversityIDCard uc WHERE uc.StudentID=s.StudentID))=48
         AND (SELECT COUNT_BIG(*) FROM dbo.Student s
              WHERE NOT EXISTS (SELECT 1 FROM dbo.UniversityIDCard uc WHERE uc.StudentID=s.StudentID))=16
       THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks
SELECT 15, N'Issue dates from 2026-09-01 through 2026-10-18; none in the future',
       CASE WHEN NOT EXISTS
         (SELECT 1 FROM dbo.UniversityIDCard
          WHERE IssueDate IS NULL
             OR IssueDate NOT BETWEEN CONVERT(DATE,'20260901',112) AND CONVERT(DATE,'20261018',112)
             OR IssueDate > CONVERT(DATE,GETDATE()))
         AND (SELECT MIN(IssueDate) FROM dbo.UniversityIDCard)=CONVERT(DATE,'20260901',112)
         AND (SELECT MAX(IssueDate) FROM dbo.UniversityIDCard)=CONVERT(DATE,'20261018',112)
       THEN 'PASS' ELSE 'FAIL' END;

-- Result set 1: summary; MUST read PASS + FailedChecks = 0.
SELECT N'UniversityIDCard: Exact Row Set + Schema + PK + UQ + FK' AS VerificationTest,
       CASE WHEN NOT EXISTS (SELECT 1 FROM #Checks WHERE Result='FAIL')
            THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard) AS ActualRows,
       CONVERT(BIGINT,48) AS ExpectedRows,
       (SELECT COUNT(*) FROM #Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM #Checks WHERE Result='FAIL') AS FailedChecks;

-- Result set 2: detailed check list.
SELECT CheckID, Item, Result FROM #Checks ORDER BY CheckID;

-- Result set 3: actual card records (48 rows expected).
SELECT CardNumber, StudentID, IssueDate
FROM dbo.UniversityIDCard
ORDER BY StudentID;

-- Result set 4: every student and card assignment (64 rows expected).
SELECT s.StudentID, s.[Name] AS StudentName,
       uc.CardNumber, uc.IssueDate,
       CASE WHEN uc.StudentID IS NULL THEN 'NOT ISSUED' ELSE 'ISSUED' END AS CardStatus
FROM dbo.Student AS s
LEFT JOIN dbo.UniversityIDCard AS uc ON uc.StudentID=s.StudentID
ORDER BY s.StudentID;

-- Result set 5: unexpected and missing rows; ZERO rows expected.
SELECT N'EXTRA OR ALTERED' AS Mismatch, e.CardNumber, e.StudentID, e.IssueDate
FROM (SELECT CardNumber, StudentID, IssueDate FROM dbo.UniversityIDCard
      EXCEPT
      SELECT CardNumber, StudentID, IssueDate FROM #ExpectedUniversityIDCard) AS e
UNION ALL
SELECT N'MISSING' AS Mismatch, e.CardNumber, e.StudentID, e.IssueDate
FROM (SELECT CardNumber, StudentID, IssueDate FROM #ExpectedUniversityIDCard
      EXCEPT
      SELECT CardNumber, StudentID, IssueDate FROM dbo.UniversityIDCard) AS e;

-- Result set 6: approved physical column inventory.
SELECT c.column_id AS ColumnOrder, c.name AS ColumnName,
       TYPE_NAME(c.system_type_id) AS DataType,
       c.max_length AS LengthBytes, c.is_nullable AS IsNullable
FROM sys.columns c WHERE c.object_id=@ObjectID
ORDER BY c.column_id;

-- Result set 7: FK status.
SELECT fk.name AS ForeignKeyName, fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk WHERE fk.parent_object_id=@ObjectID;

DROP TABLE #Checks;
DROP TABLE #ExpectedUniversityIDCard;
GO
------------------------------------------
GO
