-- Extracted from UniversityManagementDB(2).sql; source lines 2930-3085.
USE [UniversityManagementDB];
GO
----Table 03: Semester
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Semester', N'U') IS NULL
    THROW 51031, 'STOP: dbo.Semester does not exist. No changes made.', 1;

IF EXISTS (SELECT 1 FROM dbo.Semester)
    THROW 51032, 'STOP: dbo.Semester already contains rows. No INSERT attempted.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Semester (SemesterID, AcademicYear, TermName)
    VALUES
        (1, N'2023/2024', N'Fall'),
        (2, N'2023/2024', N'Spring'),
        (3, N'2024/2025', N'Fall'),
        (4, N'2024/2025', N'Spring'),
        (5, N'2025/2026', N'Fall'),
        (6, N'2025/2026', N'Spring'),
        (7, N'2026/2027', N'Fall'),
        (8, N'2026/2027', N'Spring');

    IF @@ROWCOUNT <> 8
        THROW 51033, 'STOP: Semester INSERT did not affect exactly eight rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Semester) <> 8
        THROW 51034, 'STOP: Semester row count is not exactly eight.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.Semester
        WHERE AcademicYear IS NULL OR TermName IS NULL
           OR LEN(LTRIM(RTRIM(AcademicYear))) = 0
           OR LEN(LTRIM(RTRIM(TermName))) = 0
    )
        THROW 51035, 'STOP: NULL or blank Semester attributes detected.', 1;

    COMMIT TRANSACTION;
    PRINT 'Semester: 8 synthetic rows committed successfully. Now run separate read-only verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
--------------------------------------
----02 — Verification Script
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Semester', N'U') IS NULL
    THROW 51036, 'FAIL: dbo.Semester does not exist.', 1;

DECLARE @Expected TABLE
(
    SemesterID INT NOT NULL PRIMARY KEY,
    AcademicYear NVARCHAR(9) NOT NULL,
    TermName NVARCHAR(50) NOT NULL
);

INSERT INTO @Expected (SemesterID, AcademicYear, TermName)
VALUES
    (1, N'2023/2024', N'Fall'),
    (2, N'2023/2024', N'Spring'),
    (3, N'2024/2025', N'Fall'),
    (4, N'2024/2025', N'Spring'),
    (5, N'2025/2026', N'Fall'),
    (6, N'2025/2026', N'Spring'),
    (7, N'2026/2027', N'Fall'),
    (8, N'2026/2027', N'Spring');

-- TEST 1. Exact row-set verification (expected PASS, 8, 8).
SELECT
    N'Semester: Exact Row Set + Keys' AS VerificationTest,
    CASE WHEN (SELECT COUNT_BIG(*) FROM dbo.Semester) = 8
         AND NOT EXISTS
         (
             SELECT SemesterID, AcademicYear, TermName FROM @Expected
             EXCEPT
             SELECT SemesterID, AcademicYear, TermName FROM dbo.Semester
         )
         AND NOT EXISTS
         (
             SELECT SemesterID, AcademicYear, TermName FROM dbo.Semester
             EXCEPT
             SELECT SemesterID, AcademicYear, TermName FROM @Expected
         )
         AND NOT EXISTS
         (
             SELECT 1 FROM dbo.Semester
             WHERE AcademicYear IS NULL OR TermName IS NULL
                OR LEN(LTRIM(RTRIM(AcademicYear))) = 0
                OR LEN(LTRIM(RTRIM(TermName))) = 0
         )
         AND EXISTS
         (
             SELECT 1 FROM sys.key_constraints
             WHERE parent_object_id = OBJECT_ID(N'dbo.Semester', N'U')
               AND name = N'PK_Semester' AND [type] = 'PK'
         )
         AND EXISTS
         (
             SELECT 1 FROM sys.key_constraints
             WHERE parent_object_id = OBJECT_ID(N'dbo.Semester', N'U')
               AND name = N'UQ_Semester_AcademicYear_TermName' AND [type] = 'UQ'
         )
    THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Semester) AS ActualRows,
    CAST(8 AS BIGINT) AS ExpectedRows;

-- TEST 2. Visual listing (expected 8 rows).
SELECT SemesterID, AcademicYear, TermName
FROM dbo.Semester
ORDER BY SemesterID;

-- TEST 3. Distribution (expected 4 years, 2 terms per year).
SELECT AcademicYear, COUNT(*) AS SemesterCount,
       SUM(CASE WHEN TermName = N'Fall' THEN 1 ELSE 0 END) AS FallCount,
       SUM(CASE WHEN TermName = N'Spring' THEN 1 ELSE 0 END) AS SpringCount
FROM dbo.Semester
GROUP BY AcademicYear
ORDER BY AcademicYear;

-- TEST 4. Unexpected or changed records (expected ZERO rows).
SELECT s.SemesterID, s.AcademicYear, s.TermName
FROM dbo.Semester AS s
WHERE NOT EXISTS
(
    SELECT 1 FROM @Expected AS e
    WHERE e.SemesterID = s.SemesterID
      AND e.AcademicYear = s.AcademicYear
      AND e.TermName = s.TermName
);

-- TEST 5. Missing expected records (expected ZERO rows).
SELECT e.SemesterID, e.AcademicYear, e.TermName
FROM @Expected AS e
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Semester AS s
    WHERE s.SemesterID = e.SemesterID
      AND s.AcademicYear = e.AcademicYear
      AND s.TermName = e.TermName
);

-- TEST 6. Duplicate academic year + term pairs (expected ZERO rows).
SELECT AcademicYear, TermName, COUNT_BIG(*) AS DuplicateCount
FROM dbo.Semester
GROUP BY AcademicYear, TermName
HAVING COUNT_BIG(*) > 1;
--------------------------------------
GO
