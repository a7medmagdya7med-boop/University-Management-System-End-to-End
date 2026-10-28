-- Extracted from UniversityManagementDB(2).sql; source lines 2515-2658.
USE [UniversityManagementDB];
GO
     ----Phase4_01_Insert_Department
     /*
 Business Scenario for University Management System
 Phase 4 - Data Population | 01 of 21: Department
 Synthetic, deterministic seed data. Run only in UniversityManagementDB.
 This script deliberately refuses to run if Department contains rows.
 It does not modify table definitions or other tables.
*/
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
    THROW 51001, 'STOP: dbo.Department does not exist.', 1;

IF EXISTS (SELECT 1 FROM dbo.Department)
    THROW 51002, 'STOP: dbo.Department already contains rows. No INSERT attempted.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Department (DepartmentID, DepartmentName)
    VALUES
       (1, N'Computer Science'),
       (2, N'Business Administration'),
       (3, N'Information Systems'),
       (4, N'Electrical Engineering'),
       (5, N'Mechanical Engineering'),
       (6, N'Mathematics'),
       (7, N'Physics'),
       (8, N'Economics');

    IF @@ROWCOUNT <> 8
        THROW 51003, 'STOP: The INSERT did not affect exactly 8 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Department) <> 8
        THROW 51004, 'STOP: Department row count differs from 8.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Department
        WHERE DepartmentName IS NULL
           OR LEN(LTRIM(RTRIM(DepartmentName))) = 0
    )
        THROW 51005, 'STOP: Null or blank department name detected.', 1;

    COMMIT TRANSACTION;

    PRINT 'Department seed INSERT completed and committed. Run the separate read-only verification script.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-----------------------------------------
----Phase4_01_Verify_Department
/*
 Business Scenario for University Management System
 Phase 4 - Data Population | Verification for Department
 READ ONLY. Expected: eight exact synthetic department rows.
 Result must be PASS before proceeding to table 02.
*/
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
    THROW 51011, 'FAIL: dbo.Department does not exist.', 1;

DECLARE @Expected TABLE
(
    DepartmentID INT NOT NULL PRIMARY KEY,
    DepartmentName NVARCHAR(150) NOT NULL
);

INSERT INTO @Expected (DepartmentID, DepartmentName)
VALUES
   (1, N'Computer Science'),
   (2, N'Business Administration'),
   (3, N'Information Systems'),
   (4, N'Electrical Engineering'),
   (5, N'Mechanical Engineering'),
   (6, N'Mathematics'),
   (7, N'Physics'),
   (8, N'Economics');

-- 1. Confirm the exact expected data set in BOTH directions.
SELECT
    N'Department: Exact Row Set' AS VerificationTest,
    CASE
      WHEN (SELECT COUNT_BIG(*) FROM dbo.Department) = 8
       AND NOT EXISTS
       (
         SELECT DepartmentID, DepartmentName FROM @Expected
         EXCEPT
         SELECT DepartmentID, DepartmentName FROM dbo.Department
       )
       AND NOT EXISTS
       (
         SELECT DepartmentID, DepartmentName FROM dbo.Department
         EXCEPT
         SELECT DepartmentID, DepartmentName FROM @Expected
       )
       AND NOT EXISTS
       (
         SELECT 1
         FROM dbo.Department
         WHERE DepartmentName IS NULL
            OR LEN(LTRIM(RTRIM(DepartmentName))) = 0
       )
      THEN 'PASS' ELSE 'FAIL'
    END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Department) AS ActualRows,
    CAST(8 AS BIGINT) AS ExpectedRows;

-- 2. Show inserted rows for visual confirmation.
SELECT DepartmentID, DepartmentName
FROM dbo.Department
ORDER BY DepartmentID;

-- 3. Unexpected or changed rows: expected ZERO rows.
SELECT d.DepartmentID, d.DepartmentName
FROM dbo.Department AS d
WHERE NOT EXISTS
(
    SELECT 1 FROM @Expected AS e
    WHERE e.DepartmentID = d.DepartmentID
      AND e.DepartmentName = d.DepartmentName
);

-- 4. Missing rows: expected ZERO rows.
SELECT e.DepartmentID, e.DepartmentName
FROM @Expected AS e
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Department AS d
    WHERE d.DepartmentID = e.DepartmentID
      AND d.DepartmentName = e.DepartmentName
);
GO
----------------------------------
GO
