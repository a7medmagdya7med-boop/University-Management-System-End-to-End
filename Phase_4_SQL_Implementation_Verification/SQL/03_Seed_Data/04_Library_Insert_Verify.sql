-- Extracted from UniversityManagementDB(2).sql; source lines 3086-3225.
USE [UniversityManagementDB];
GO
---Table 04: Library
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Library', N'U') IS NULL
    THROW 51041, 'STOP: dbo.Library does not exist. No change made.', 1;

IF EXISTS (SELECT 1 FROM dbo.Library)
    THROW 51042, 'STOP: dbo.Library already contains data. No INSERT attempted.', 1;

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.Library', N'U')
      AND [name] = N'PK_Library'
      AND [type] = 'PK'
)
    THROW 51043, 'STOP: Expected PK_Library constraint is missing.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Library (LibraryID, LibraryName)
    VALUES (1, N'Central Library');

    IF @@ROWCOUNT <> 1
        THROW 51044, 'STOP: Expected exactly one inserted Library row.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Library) <> 1
        THROW 51045, 'STOP: Library has an unexpected row count.', 1;

    COMMIT TRANSACTION;
    PRINT 'Library: 1 synthetic record committed. Run separate read-only verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
------------------------------
---READ-ONLY VERIFICATION.
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Library', N'U') IS NULL
    THROW 51046, 'FAIL: dbo.Library does not exist.', 1;

DECLARE @Expected TABLE
(
    LibraryID INT NOT NULL PRIMARY KEY,
    LibraryName NVARCHAR(150) NOT NULL
);
INSERT INTO @Expected (LibraryID, LibraryName)
VALUES (1, N'Central Library');

-- TEST 1: Exact row set AND structural integrity: expected PASS, 1, 1.
SELECT
    N'Library: Exact Row Set + Schema + PK' AS VerificationTest,
    CASE
        WHEN (SELECT COUNT_BIG(*) FROM dbo.Library) = 1
         AND NOT EXISTS (
             SELECT LibraryID, LibraryName FROM @Expected
             EXCEPT
             SELECT LibraryID, LibraryName FROM dbo.Library
         )
         AND NOT EXISTS (
             SELECT LibraryID, LibraryName FROM dbo.Library
             EXCEPT
             SELECT LibraryID, LibraryName FROM @Expected
         )
         AND (
             SELECT COUNT_BIG(*)
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_CATALOG = DB_NAME()
               AND TABLE_SCHEMA = N'dbo'
               AND TABLE_NAME = N'Library'
         ) = 2
         AND EXISTS (
             SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_CATALOG = DB_NAME()
               AND TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Library'
               AND COLUMN_NAME = N'LibraryID' AND DATA_TYPE = N'int'
               AND IS_NULLABLE = N'NO' AND ORDINAL_POSITION = 1
         )
         AND EXISTS (
             SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_CATALOG = DB_NAME()
               AND TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Library'
               AND COLUMN_NAME = N'LibraryName' AND DATA_TYPE = N'nvarchar'
               AND CHARACTER_MAXIMUM_LENGTH = 150
               AND IS_NULLABLE = N'NO' AND ORDINAL_POSITION = 2
         )
         AND EXISTS (
             SELECT 1 FROM sys.key_constraints kc
             JOIN sys.index_columns ic
               ON ic.object_id = kc.parent_object_id
              AND ic.index_id = kc.unique_index_id
             JOIN sys.columns c
               ON c.object_id = ic.object_id
              AND c.column_id = ic.column_id
             WHERE kc.parent_object_id = OBJECT_ID(N'dbo.Library', N'U')
               AND kc.name = N'PK_Library' AND kc.type = 'PK'
               AND ic.key_ordinal = 1 AND c.name = N'LibraryID'
         )
         AND NOT EXISTS (
             SELECT 1 FROM dbo.Library
             WHERE LibraryName IS NULL
                OR LEN(LTRIM(RTRIM(LibraryName))) = 0
         )
        THEN 'PASS' ELSE 'FAIL'
    END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Library) AS ActualRows,
    CAST(1 AS BIGINT) AS ExpectedRows;

-- TEST 2: Actual values, expected one row.
SELECT LibraryID, LibraryName
FROM dbo.Library
ORDER BY LibraryID;

-- TEST 3: Unexpected values, expected zero rows.
SELECT LibraryID, LibraryName FROM dbo.Library
EXCEPT
SELECT LibraryID, LibraryName FROM @Expected;

-- TEST 4: Missing expected values, expected zero rows.
SELECT LibraryID, LibraryName FROM @Expected
EXCEPT
SELECT LibraryID, LibraryName FROM dbo.Library;

-- TEST 5: Duplicated ID or blank name, expected zero rows.
SELECT LibraryID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.Library
GROUP BY LibraryID
HAVING COUNT_BIG(*) > 1;

SELECT LibraryID, LibraryName FROM dbo.Library
WHERE LibraryName IS NULL OR LEN(LTRIM(RTRIM(LibraryName))) = 0;
--------------------------------
GO
