-- Extracted from UniversityManagementDB(2).sql; source lines 6712-7094.
USE [UniversityManagementDB];
GO
---Table 15 — StudentPhone
--Phase4_15_Insert_StudentPhone
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('tempdb..#ExpectedStudentPhone') IS NOT NULL
    DROP TABLE #ExpectedStudentPhone;

CREATE TABLE #ExpectedStudentPhone
(
    StudentID INT NOT NULL,
    PhoneNumber NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_ExpectedStudentPhone PRIMARY KEY (StudentID, PhoneNumber)
);

-- Explicitly deterministic 0..63 generator (8 x 8).
;WITH D AS
(
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) v(n)
),
N AS
(
    SELECT (a.n * 8 + b.n) AS n
    FROM D AS a CROSS JOIN D AS b
)
INSERT INTO #ExpectedStudentPhone (StudentID, PhoneNumber)
SELECT 10001 + n,
       CONVERT(NVARCHAR(30), N'+1-202-555-' + RIGHT(N'0000' + CONVERT(NVARCHAR(4),
           CASE WHEN n = 1 THEN 100 ELSE 100 + n END), 4))
FROM N
UNION ALL
SELECT 10001 + n,
       CONVERT(NVARCHAR(30), N'+1-202-555-' + RIGHT(N'0000' + CONVERT(NVARCHAR(4), 164 + n), 4))
FROM N
WHERE n BETWEEN 0 AND 15;

BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    IF DB_NAME() <> N'UniversityManagementDB'
        THROW 51501, 'STOP: Wrong database.', 1;

    DECLARE @StudentPhoneId INT = OBJECT_ID(N'dbo.StudentPhone', N'U');
    IF @StudentPhoneId IS NULL OR OBJECT_ID(N'dbo.Student', N'U') IS NULL
        THROW 51502, 'STOP: Required tables are unavailable.', 1;

    IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = @StudentPhoneId) <> 2
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.columns c
           WHERE c.object_id = @StudentPhoneId AND c.column_id = 1
             AND c.name = N'StudentID' AND TYPE_NAME(c.user_type_id) = N'int'
             AND c.is_nullable = 0
       )
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.columns c
           WHERE c.object_id = @StudentPhoneId AND c.column_id = 2
             AND c.name = N'PhoneNumber' AND TYPE_NAME(c.user_type_id) = N'nvarchar'
             AND c.max_length = 60 AND c.is_nullable = 0
       )
        THROW 51503, 'STOP: StudentPhone columns differ from approved DDL.', 1;

    IF NOT EXISTS
    (
       SELECT 1 FROM sys.key_constraints kc
       JOIN sys.index_columns ic
         ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
       WHERE kc.parent_object_id = @StudentPhoneId
         AND kc.name = N'PK_StudentPhone' AND kc.type = 'PK'
       GROUP BY kc.object_id
       HAVING COUNT(*) = 2
          AND SUM(CASE WHEN ic.key_ordinal = 1 AND COL_NAME(ic.object_id, ic.column_id) = N'StudentID' THEN 1 ELSE 0 END) = 1
          AND SUM(CASE WHEN ic.key_ordinal = 2 AND COL_NAME(ic.object_id, ic.column_id) = N'PhoneNumber' THEN 1 ELSE 0 END) = 1
    )
        THROW 51504, 'STOP: Composite primary key differs from approved DDL.', 1;

    IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id = @StudentPhoneId) <> 1
       OR NOT EXISTS
       (
           SELECT 1 FROM sys.foreign_keys fk
           JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
           WHERE fk.parent_object_id = @StudentPhoneId
             AND fk.name = N'FK_StudentPhone_Student'
             AND fk.referenced_object_id = OBJECT_ID(N'dbo.Student', N'U')
             AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'StudentID'
             AND COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) = N'StudentID'
             AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
             AND (SELECT COUNT(*) FROM sys.foreign_key_columns WHERE constraint_object_id = fk.object_id) = 1
       )
        THROW 51505, 'STOP: Student FK differs from approved DDL.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sys.indexes i
        WHERE i.object_id = @StudentPhoneId
          AND i.is_unique = 1 AND i.is_primary_key = 0
    )
        THROW 51506, 'STOP: Unexpected UNIQUE index found on StudentPhone.', 1;

    IF (SELECT COUNT_BIG(*) FROM #ExpectedStudentPhone) <> 80
        THROW 51507, 'STOP: Expected seed is not exactly 80 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Student WITH (HOLDLOCK)) <> 64
       OR EXISTS
       (
           SELECT x.StudentID FROM
           (
               SELECT DISTINCT StudentID FROM #ExpectedStudentPhone
           ) x
           EXCEPT
           SELECT StudentID FROM dbo.Student
       )
       OR EXISTS
       (
           SELECT StudentID FROM dbo.Student
           EXCEPT
           SELECT DISTINCT StudentID FROM #ExpectedStudentPhone
       )
        THROW 51508, 'STOP: Student parent baseline must be exactly IDs 10001..10064.', 1;

    -- Strict no-touch policy: an already-populated target halts everything.
    IF EXISTS (SELECT 1 FROM dbo.StudentPhone WITH (UPDLOCK, HOLDLOCK))
        THROW 51509, 'STOP: StudentPhone already contains data. No changes made.', 1;

    INSERT INTO dbo.StudentPhone (StudentID, PhoneNumber)
    SELECT StudentID, PhoneNumber FROM #ExpectedStudentPhone;

    IF @@ROWCOUNT <> 80 OR (SELECT COUNT_BIG(*) FROM dbo.StudentPhone) <> 80
        THROW 51510, 'STOP: Inserted row count mismatch. Rolling back.', 1;

    IF EXISTS
       (SELECT StudentID, PhoneNumber FROM dbo.StudentPhone
        EXCEPT SELECT StudentID, PhoneNumber FROM #ExpectedStudentPhone)
       OR EXISTS
       (SELECT StudentID, PhoneNumber FROM #ExpectedStudentPhone
        EXCEPT SELECT StudentID, PhoneNumber FROM dbo.StudentPhone)
        THROW 51511, 'STOP: Exact row set mismatch. Rolling back.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'SUCCESS: 80 StudentPhone rows inserted and committed.';
    SELECT COUNT_BIG(*) AS ActualRows,
           CONVERT(BIGINT,80) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.StudentPhone;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
------------------------------
-- Table 15/21: dbo.StudentPhone | READ-ONLY VERIFICATION
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51601, 'STOP: Wrong database.', 1;
IF OBJECT_ID(N'dbo.StudentPhone', N'U') IS NULL OR OBJECT_ID(N'dbo.Student', N'U') IS NULL
    THROW 51602, 'STOP: Required tables missing. No verification run.', 1;

IF OBJECT_ID('tempdb..#ExpectedStudentPhone') IS NOT NULL DROP TABLE #ExpectedStudentPhone;
IF OBJECT_ID('tempdb..#Checks') IS NOT NULL DROP TABLE #Checks;

CREATE TABLE #ExpectedStudentPhone
(
    StudentID INT NOT NULL,
    PhoneNumber NVARCHAR(30) NOT NULL,
    PRIMARY KEY (StudentID, PhoneNumber)
);

;WITH D AS
(
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) v(n)
),
N AS
(
    SELECT (a.n * 8 + b.n) AS n FROM D a CROSS JOIN D b
)
INSERT INTO #ExpectedStudentPhone (StudentID,PhoneNumber)
SELECT 10001+n,
       CONVERT(NVARCHAR(30), N'+1-202-555-' + RIGHT(N'0000' + CONVERT(NVARCHAR(4),
            CASE WHEN n = 1 THEN 100 ELSE 100+n END), 4))
FROM N
UNION ALL
SELECT 10001+n,
       CONVERT(NVARCHAR(30), N'+1-202-555-' + RIGHT(N'0000' + CONVERT(NVARCHAR(4),164+n),4))
FROM N WHERE n BETWEEN 0 AND 15;

CREATE TABLE #Checks
(
    CheckID INT IDENTITY(1,1) PRIMARY KEY,
    Item NVARCHAR(200) NOT NULL,
    Result VARCHAR(4) NOT NULL
);

DECLARE @TableID INT = OBJECT_ID(N'dbo.StudentPhone', N'U');

INSERT INTO #Checks(Item,Result)
SELECT N'Exactly 2 columns in approved order / INT and NVARCHAR(30) NOT NULL',
       CASE WHEN (SELECT COUNT(*) FROM sys.columns WHERE object_id=@TableID) = 2
          AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=1
              AND name=N'StudentID' AND TYPE_NAME(user_type_id)=N'int' AND is_nullable=0)
          AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=2
              AND name=N'PhoneNumber' AND TYPE_NAME(user_type_id)=N'nvarchar'
              AND max_length=60 AND is_nullable=0)
          THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Approved composite PK (StudentID, PhoneNumber), ordered',
       CASE WHEN EXISTS
       (
           SELECT 1 FROM sys.key_constraints kc
           JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
           WHERE kc.parent_object_id=@TableID AND kc.name=N'PK_StudentPhone' AND kc.type='PK'
           GROUP BY kc.object_id
           HAVING COUNT(*)=2
             AND SUM(CASE WHEN ic.key_ordinal=1 AND COL_NAME(ic.object_id,ic.column_id)=N'StudentID' THEN 1 ELSE 0 END)=1
             AND SUM(CASE WHEN ic.key_ordinal=2 AND COL_NAME(ic.object_id,ic.column_id)=N'PhoneNumber' THEN 1 ELSE 0 END)=1
       ) THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'One enabled/trusted StudentID FK with approved name and mapping',
       CASE WHEN (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@TableID)=1
         AND EXISTS
         (
           SELECT 1 FROM sys.foreign_keys fk
           JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
           WHERE fk.parent_object_id=@TableID AND fk.name=N'FK_StudentPhone_Student'
             AND fk.referenced_object_id=OBJECT_ID(N'dbo.Student',N'U')
             AND COL_NAME(fkc.parent_object_id,fkc.parent_column_id)=N'StudentID'
             AND COL_NAME(fkc.referenced_object_id,fkc.referenced_column_id)=N'StudentID'
             AND fk.is_disabled=0 AND fk.is_not_trusted=0
             AND (SELECT COUNT(*) FROM sys.foreign_key_columns WHERE constraint_object_id=fk.object_id)=1
         ) THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'No unapproved UNIQUE indexes (PhoneNumber need not be unique)',
       CASE WHEN NOT EXISTS
            (SELECT 1 FROM sys.indexes WHERE object_id=@TableID
                AND is_unique=1 AND is_primary_key=0)
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Parent Student table: exactly 64 approved IDs (10001-10064)',
       CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Student)=64
         AND NOT EXISTS
          (SELECT DISTINCT StudentID FROM #ExpectedStudentPhone
           EXCEPT SELECT StudentID FROM dbo.Student)
         AND NOT EXISTS
          (SELECT StudentID FROM dbo.Student
           EXCEPT SELECT DISTINCT StudentID FROM #ExpectedStudentPhone)
         THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Exactly 80 StudentPhone rows',
       CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.StudentPhone)=80 THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Exact approved seed: no missing or extra/altered rows',
       CASE WHEN NOT EXISTS
         (SELECT StudentID,PhoneNumber FROM dbo.StudentPhone
          EXCEPT SELECT StudentID,PhoneNumber FROM #ExpectedStudentPhone)
          AND NOT EXISTS
         (SELECT StudentID,PhoneNumber FROM #ExpectedStudentPhone
          EXCEPT SELECT StudentID,PhoneNumber FROM dbo.StudentPhone)
         THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Every phone refers to an existing Student',
       CASE WHEN NOT EXISTS
       (SELECT 1 FROM dbo.StudentPhone sp
        LEFT JOIN dbo.Student s ON s.StudentID=sp.StudentID
        WHERE s.StudentID IS NULL) THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Exactly 64 distinct students have phone rows',
       CASE WHEN (SELECT COUNT(DISTINCT StudentID) FROM dbo.StudentPhone)=64
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'48 students with 1 phone and 16 with 2 phones',
       CASE WHEN (SELECT COUNT(*) FROM
                 (SELECT StudentID FROM dbo.StudentPhone GROUP BY StudentID HAVING COUNT(*)=1) x)=48
            AND (SELECT COUNT(*) FROM
                 (SELECT StudentID FROM dbo.StudentPhone GROUP BY StudentID HAVING COUNT(*)=2) x)=16
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'Exactly students 10001-10016 have 2 numbers',
       CASE WHEN (SELECT COUNT(*) FROM
                 (SELECT StudentID FROM dbo.StudentPhone GROUP BY StudentID HAVING COUNT(*)=2) x
                 WHERE x.StudentID BETWEEN 10001 AND 10016)=16
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'One shared phone across students 10001 & 10002 is accepted',
       CASE WHEN (SELECT COUNT(*) FROM dbo.StudentPhone
                      WHERE PhoneNumber=N'+1-202-555-0100'
                        AND StudentID IN (10001,10002))=2
            AND (SELECT COUNT(*) FROM
                    (SELECT PhoneNumber FROM dbo.StudentPhone
                     GROUP BY PhoneNumber HAVING COUNT(DISTINCT StudentID)>1) x)=1
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'79 different phone values among 80 StudentPhone rows',
       CASE WHEN (SELECT COUNT(DISTINCT PhoneNumber) FROM dbo.StudentPhone)=79
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'No blank phone numbers and all follow approved fictional number pattern',
       CASE WHEN NOT EXISTS
           (SELECT 1 FROM dbo.StudentPhone
            WHERE PhoneNumber IS NULL OR LEN(LTRIM(RTRIM(PhoneNumber)))=0
              OR PhoneNumber NOT LIKE N'+1-202-555-01[0-7][0-9]'
              OR LEN(PhoneNumber)<>15)
            THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #Checks(Item,Result)
SELECT N'No duplicate (StudentID, PhoneNumber) pairs',
       CASE WHEN NOT EXISTS
           (SELECT 1 FROM dbo.StudentPhone GROUP BY StudentID,PhoneNumber HAVING COUNT_BIG(*)>1)
            THEN 'PASS' ELSE 'FAIL' END;

-- Result set 1 - Overall verification and checks count
SELECT N'StudentPhone: Exact Row Set + Schema + PK + FK' AS VerificationTest,
       CASE WHEN NOT EXISTS(SELECT 1 FROM #Checks WHERE Result='FAIL')
                 AND (SELECT COUNT(*) FROM #Checks)=15 THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.StudentPhone) AS ActualRows,
       CONVERT(BIGINT,80) AS ExpectedRows,
       (SELECT COUNT(*) FROM #Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM #Checks WHERE Result='FAIL') AS FailedChecks;

-- Result set 2 - Detailed verification
SELECT CheckID,Item,Result FROM #Checks ORDER BY CheckID;

-- Result set 3 - All 80 records
SELECT StudentID,PhoneNumber FROM dbo.StudentPhone ORDER BY StudentID,PhoneNumber;

-- Result set 4 - Distribution per student
SELECT s.StudentID,s.[Name] AS StudentName,COUNT(sp.PhoneNumber) AS PhoneCount
FROM dbo.Student s LEFT JOIN dbo.StudentPhone sp ON sp.StudentID=s.StudentID
GROUP BY s.StudentID,s.[Name]
ORDER BY s.StudentID;

-- Result set 5 - Shared numbers (expect exactly one row)
SELECT PhoneNumber,COUNT(DISTINCT StudentID) AS StudentCount
FROM dbo.StudentPhone
GROUP BY PhoneNumber
HAVING COUNT(DISTINCT StudentID)>1;

-- Result set 6 - Unexpected/missing rows (expect ZERO rows)
SELECT N'UNEXPECTED' AS Mismatch,StudentID,PhoneNumber FROM
  (SELECT StudentID,PhoneNumber FROM dbo.StudentPhone
   EXCEPT SELECT StudentID,PhoneNumber FROM #ExpectedStudentPhone) a
UNION ALL
SELECT N'MISSING' AS Mismatch,StudentID,PhoneNumber FROM
  (SELECT StudentID,PhoneNumber FROM #ExpectedStudentPhone
   EXCEPT SELECT StudentID,PhoneNumber FROM dbo.StudentPhone) b;

-- Result set 7 - Read-only schema inspection
SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,
       TYPE_NAME(c.user_type_id) AS DataType,c.max_length AS LengthBytes,c.is_nullable AS IsNullable
FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'dbo.StudentPhone',N'U')
ORDER BY c.column_id;

SELECT fk.name AS ForeignKeyName,fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.StudentPhone',N'U');

DROP TABLE #Checks;
DROP TABLE #ExpectedStudentPhone;
GO
-----------------
GO
