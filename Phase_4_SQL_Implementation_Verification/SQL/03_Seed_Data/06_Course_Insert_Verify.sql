-- Extracted from UniversityManagementDB(2).sql; source lines 3404-3636.
USE [UniversityManagementDB];
GO
  ---Table 06 Course
  USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Course', N'U') IS NULL
    THROW 51061, 'STOP: dbo.Course does not exist. Nothing inserted.', 1;

-- Never overwrite existing data or silently insert a second seed batch.
IF EXISTS (SELECT 1 FROM dbo.Course)
    THROW 51062, 'STOP: dbo.Course already has rows. No INSERT attempted.', 1;

-- Verify the exact approved two-column definition and PRIMARY KEY before inserting.
IF (SELECT COUNT_BIG(*) FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')) <> 2
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')
          AND name = N'CourseID' AND system_type_id = 56
          AND is_nullable = 0 AND column_id = 1
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')
          AND name = N'CourseTitle' AND system_type_id = 231
          AND max_length = 400 AND is_nullable = 0 AND column_id = 2
    )
    OR NOT EXISTS (
        SELECT 1 FROM sys.key_constraints AS kc
        JOIN sys.index_columns AS ic
          ON kc.parent_object_id = ic.object_id
         AND kc.unique_index_id = ic.index_id
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE kc.parent_object_id = OBJECT_ID(N'dbo.Course', N'U')
          AND kc.name = N'PK_Course' AND kc.type = 'PK'
          AND ic.key_ordinal = 1 AND c.name = N'CourseID'
    )
    OR EXISTS (
        SELECT 1 FROM sys.indexes AS i
        JOIN sys.index_columns AS ic
          ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns AS c
          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE i.object_id = OBJECT_ID(N'dbo.Course', N'U')
          AND i.is_unique = 1 AND i.is_primary_key = 0
          AND ic.key_ordinal > 0 AND c.name = N'CourseTitle'
    )
    THROW 51063, 'STOP: Course schema/constraints differ from the approved design.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Course (CourseID, CourseTitle)
    VALUES
        ( 1, N'Introduction to Programming'),
        ( 2, N'Database Systems'),
        ( 3, N'Data Structures and Algorithms'),
        ( 4, N'Principles of Management'),
        ( 5, N'Strategic Management'),
        ( 6, N'Business Analytics'),
        ( 7, N'Systems Analysis and Design'),
        ( 8, N'Enterprise Information Systems'),
        ( 9, N'Information Security'),
        (10, N'Circuit Analysis'),
        (11, N'Control Systems'),
        (12, N'Digital Electronics'),
        (13, N'Thermodynamics'),
        (14, N'Fluid Mechanics'),
        (15, N'Manufacturing Processes'),
        (16, N'Calculus I'),
        (17, N'Linear Algebra'),
        (18, N'Applied Statistics'),
        (19, N'Classical Mechanics'),
        (20, N'Electromagnetism'),
        (21, N'Quantum Physics'),
        (22, N'Microeconomics'),
        (23, N'Macroeconomics'),
        (24, N'Econometrics');

    IF @@ROWCOUNT <> 24
        THROW 51064, 'STOP: Course insertion did not affect 24 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Course) <> 24
        THROW 51065, 'STOP: Course total row count is not 24.', 1;

    COMMIT TRANSACTION;
    PRINT 'Course: 24 synthetic rows committed successfully. Run the separate read-only verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-------------------------------
---READ-ONLY verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Course', N'U') IS NULL
    THROW 51066, 'FAIL: dbo.Course does not exist.', 1;

DECLARE @Expected TABLE
(
    CourseID INT NOT NULL PRIMARY KEY,
    CourseTitle NVARCHAR(200) NOT NULL
);

INSERT INTO @Expected (CourseID, CourseTitle)
VALUES
    ( 1, N'Introduction to Programming'),
    ( 2, N'Database Systems'),
    ( 3, N'Data Structures and Algorithms'),
    ( 4, N'Principles of Management'),
    ( 5, N'Strategic Management'),
    ( 6, N'Business Analytics'),
    ( 7, N'Systems Analysis and Design'),
    ( 8, N'Enterprise Information Systems'),
    ( 9, N'Information Security'),
    (10, N'Circuit Analysis'),
    (11, N'Control Systems'),
    (12, N'Digital Electronics'),
    (13, N'Thermodynamics'),
    (14, N'Fluid Mechanics'),
    (15, N'Manufacturing Processes'),
    (16, N'Calculus I'),
    (17, N'Linear Algebra'),
    (18, N'Applied Statistics'),
    (19, N'Classical Mechanics'),
    (20, N'Electromagnetism'),
    (21, N'Quantum Physics'),
    (22, N'Microeconomics'),
    (23, N'Macroeconomics'),
    (24, N'Econometrics');

-- TEST 1: exact row set + approved columns and types + PK + no unauthorized title uniqueness.
-- Expected PASS / ActualRows 24 / ExpectedRows 24.
SELECT
    N'Course: Exact Row Set + Schema + PK' AS VerificationTest,
    CASE
      WHEN (SELECT COUNT_BIG(*) FROM dbo.Course) = 24
       AND NOT EXISTS (
          SELECT CourseID, CourseTitle FROM dbo.Course
          EXCEPT
          SELECT CourseID, CourseTitle FROM @Expected
       )
       AND NOT EXISTS (
          SELECT CourseID, CourseTitle FROM @Expected
          EXCEPT
          SELECT CourseID, CourseTitle FROM dbo.Course
       )
       AND (SELECT COUNT_BIG(*) FROM sys.columns
            WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')) = 2
       AND EXISTS (
          SELECT 1 FROM sys.columns
          WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')
            AND name = N'CourseID' AND system_type_id = 56
            AND is_nullable = 0 AND column_id = 1
       )
       AND EXISTS (
          SELECT 1 FROM sys.columns
          WHERE object_id = OBJECT_ID(N'dbo.Course', N'U')
            AND name = N'CourseTitle' AND system_type_id = 231
            AND max_length = 400 AND is_nullable = 0 AND column_id = 2
       )
       AND EXISTS (
          SELECT 1 FROM sys.key_constraints AS kc
          JOIN sys.index_columns AS ic
            ON ic.object_id = kc.parent_object_id
           AND ic.index_id = kc.unique_index_id
          JOIN sys.columns AS c
            ON c.object_id = ic.object_id AND c.column_id = ic.column_id
          WHERE kc.parent_object_id = OBJECT_ID(N'dbo.Course', N'U')
            AND kc.name = N'PK_Course' AND kc.type = 'PK'
            AND ic.key_ordinal = 1 AND c.name = N'CourseID'
       )
       AND NOT EXISTS (
          SELECT 1 FROM dbo.Course
          WHERE CourseTitle IS NULL OR LEN(LTRIM(RTRIM(CourseTitle))) = 0
       )
       AND NOT EXISTS (
          SELECT 1 FROM sys.indexes AS i
          JOIN sys.index_columns AS ic
            ON i.object_id = ic.object_id AND i.index_id = ic.index_id
          JOIN sys.columns AS c
            ON c.object_id = ic.object_id AND c.column_id = ic.column_id
          WHERE i.object_id = OBJECT_ID(N'dbo.Course', N'U')
            AND i.is_unique = 1 AND i.is_primary_key = 0
            AND ic.key_ordinal > 0 AND c.name = N'CourseTitle'
       )
      THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Course) AS ActualRows,
    CAST(24 AS BIGINT) AS ExpectedRows;

-- TEST 2: visual listing, expected 24 rows.
SELECT CourseID, CourseTitle
FROM dbo.Course
ORDER BY CourseID;

-- TEST 3: unexpected/changed rows, expected ZERO rows.
SELECT CourseID, CourseTitle FROM dbo.Course
EXCEPT
SELECT CourseID, CourseTitle FROM @Expected;

-- TEST 4: missing expected rows, expected ZERO rows.
SELECT CourseID, CourseTitle FROM @Expected
EXCEPT
SELECT CourseID, CourseTitle FROM dbo.Course;

-- TEST 5: duplicate CourseID, expected ZERO rows.
SELECT CourseID, COUNT_BIG(*) AS DuplicateCount
FROM dbo.Course
GROUP BY CourseID
HAVING COUNT_BIG(*) > 1;

-- TEST 6: NULL/blank CourseTitle, expected ZERO rows.
SELECT CourseID, CourseTitle FROM dbo.Course
WHERE CourseTitle IS NULL OR LEN(LTRIM(RTRIM(CourseTitle))) = 0;

-- TEST 7: extra unauthorized UNIQUE index involving CourseTitle, expected ZERO rows.
SELECT i.name AS UnexpectedUniqueIndex, c.name AS UniqueColumn
FROM sys.indexes AS i
JOIN sys.index_columns AS ic
  ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c
  ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.Course', N'U')
  AND i.is_unique = 1 AND i.is_primary_key = 0
  AND ic.key_ordinal > 0 AND c.name = N'CourseTitle';
GO
----------------------------------
GO
