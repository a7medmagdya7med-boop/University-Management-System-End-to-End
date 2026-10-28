-- Extracted from UniversityManagementDB(2).sql; source lines 3226-3403.
USE [UniversityManagementDB];
GO
---Table 05 StudentClub
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.StudentClub', N'U') IS NULL
    THROW 51051, 'STOP: dbo.StudentClub does not exist. Nothing inserted.', 1;

-- Never overwrite existing data or silently insert a second seed batch.
IF EXISTS (SELECT 1 FROM dbo.StudentClub)
    THROW 51052, 'STOP: dbo.StudentClub already has rows. No INSERT attempted.', 1;

-- Fail safely if the agreed table definition is not present.
IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')) <> 2
   OR NOT EXISTS (
       SELECT 1 FROM sys.columns
       WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
         AND name = N'ClubID' AND system_type_id = 56
         AND is_nullable = 0 AND column_id = 1
   )
   OR NOT EXISTS (
       SELECT 1 FROM sys.columns
       WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
         AND name = N'ClubName' AND system_type_id = 231
         AND max_length = 300 AND is_nullable = 0 AND column_id = 2
   )
   OR NOT EXISTS (
       SELECT 1 FROM sys.key_constraints
       WHERE parent_object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
         AND name = N'PK_StudentClub' AND type = 'PK'
   )
    THROW 51053, 'STOP: StudentClub schema differs from approved definition.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.StudentClub (ClubID, ClubName)
    VALUES
        (1, N'Robotics Club'),
        (2, N'Entrepreneurship Club'),
        (3, N'Data Science Club'),
        (4, N'Debate Society'),
        (5, N'Sustainability Club'),
        (6, N'Arts and Culture Club'),
        (7, N'Sports Club'),
        (8, N'Volunteering Club');

    IF @@ROWCOUNT <> 8
        THROW 51054, 'STOP: StudentClub insertion did not affect 8 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.StudentClub) <> 8
        THROW 51055, 'STOP: StudentClub total row count is not 8.', 1;

    COMMIT TRANSACTION;
    PRINT 'StudentClub: 8 synthetic rows committed successfully. Run separate read-only verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-------------------------------------
---READ-ONLY verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.StudentClub', N'U') IS NULL
    THROW 51056, 'FAIL: dbo.StudentClub does not exist.', 1;

DECLARE @Expected TABLE
(
    ClubID INT NOT NULL PRIMARY KEY,
    ClubName NVARCHAR(150) NOT NULL
);

INSERT INTO @Expected (ClubID, ClubName)
VALUES
    (1, N'Robotics Club'),
    (2, N'Entrepreneurship Club'),
    (3, N'Data Science Club'),
    (4, N'Debate Society'),
    (5, N'Sustainability Club'),
    (6, N'Arts and Culture Club'),
    (7, N'Sports Club'),
    (8, N'Volunteering Club');

-- TEST 1: Exact rows + columns/types + PK, expected PASS / 8 / 8.
SELECT
    N'StudentClub: Exact Row Set + Schema + PK' AS VerificationTest,
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.StudentClub) = 8
          AND NOT EXISTS (
              SELECT ClubID, ClubName FROM @Expected
              EXCEPT SELECT ClubID, ClubName FROM dbo.StudentClub
          )
          AND NOT EXISTS (
              SELECT ClubID, ClubName FROM dbo.StudentClub
              EXCEPT SELECT ClubID, ClubName FROM @Expected
          )
          AND (SELECT COUNT_BIG(*) FROM sys.columns
               WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')) = 2
          AND EXISTS (
              SELECT 1 FROM sys.columns
              WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
                AND name = N'ClubID' AND system_type_id = 56
                AND is_nullable = 0 AND column_id = 1
          )
          AND EXISTS (
              SELECT 1 FROM sys.columns
              WHERE object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
                AND name = N'ClubName' AND system_type_id = 231
                AND max_length = 300 AND is_nullable = 0 AND column_id = 2
          )
          AND EXISTS (
              SELECT 1 FROM sys.key_constraints kc
              JOIN sys.index_columns ic
                ON ic.object_id = kc.parent_object_id
               AND ic.index_id = kc.unique_index_id
              JOIN sys.columns c
                ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE kc.parent_object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
                AND kc.name = N'PK_StudentClub' AND kc.type = 'PK'
                AND ic.key_ordinal = 1 AND c.name = N'ClubID'
          )
          AND NOT EXISTS (
              SELECT 1 FROM dbo.StudentClub
              WHERE ClubName IS NULL OR LEN(LTRIM(RTRIM(ClubName))) = 0
          )
          AND NOT EXISTS (
              SELECT 1 FROM sys.indexes i
              JOIN sys.index_columns ic
                ON ic.object_id = i.object_id AND ic.index_id = i.index_id
              JOIN sys.columns c
                ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE i.object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
                AND i.is_unique = 1 AND i.is_primary_key = 0
                AND ic.key_ordinal > 0 AND c.name = N'ClubName'
          )
    THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.StudentClub) AS ActualRows,
    CAST(8 AS BIGINT) AS ExpectedRows;

-- TEST 2: All clubs, expected 8 rows.
SELECT ClubID, ClubName
FROM dbo.StudentClub
ORDER BY ClubID;

-- TEST 3: Unexpected or changed club rows, expected ZERO rows.
SELECT ClubID, ClubName FROM dbo.StudentClub
EXCEPT
SELECT ClubID, ClubName FROM @Expected;

-- TEST 4: Missing expected club rows, expected ZERO rows.
SELECT ClubID, ClubName FROM @Expected
EXCEPT
SELECT ClubID, ClubName FROM dbo.StudentClub;

-- TEST 5: Duplicated IDs, expected ZERO rows.
SELECT ClubID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.StudentClub
GROUP BY ClubID
HAVING COUNT_BIG(*) > 1;

-- TEST 6: Blank/NULL club names, expected ZERO rows.
SELECT ClubID, ClubName FROM dbo.StudentClub
WHERE ClubName IS NULL OR LEN(LTRIM(RTRIM(ClubName))) = 0;

-- TEST 7: Unapproved extra UNIQUE index on ClubName, expected ZERO rows.
SELECT i.name AS UnexpectedUniqueIndex, c.name AS UniqueColumn
FROM sys.indexes AS i
JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.StudentClub', N'U')
  AND i.is_unique = 1 AND i.is_primary_key = 0
  AND ic.key_ordinal > 0 AND c.name = N'ClubName';
  -----------------------------------------------
GO
