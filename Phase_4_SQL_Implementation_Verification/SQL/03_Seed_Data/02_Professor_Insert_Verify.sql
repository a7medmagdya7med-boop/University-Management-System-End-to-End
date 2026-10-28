-- Extracted from UniversityManagementDB(2).sql; source lines 2659-2929.
USE [UniversityManagementDB];
GO
----Table 02 — Professor | INSERT & Verification

 USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Department', N'U') IS NULL
    THROW 51201, 'STOP: dbo.Department is missing.', 1;
IF OBJECT_ID(N'dbo.Professor', N'U') IS NULL
    THROW 51202, 'STOP: dbo.Professor is missing.', 1;

-- Gate 1: the eight approved Department IDs and names must be unchanged.
DECLARE @ExpectedDepartments TABLE
(
    DepartmentID INT NOT NULL PRIMARY KEY,
    DepartmentName NVARCHAR(150) NOT NULL
);
INSERT INTO @ExpectedDepartments (DepartmentID, DepartmentName)
VALUES
    (1, N'Computer Science'),
    (2, N'Business Administration'),
    (3, N'Information Systems'),
    (4, N'Electrical Engineering'),
    (5, N'Mechanical Engineering'),
    (6, N'Mathematics'),
    (7, N'Physics'),
    (8, N'Economics');

IF (SELECT COUNT_BIG(*) FROM dbo.Department) <> 8
   OR EXISTS
   (
       SELECT DepartmentID, DepartmentName FROM @ExpectedDepartments
       EXCEPT
       SELECT DepartmentID, DepartmentName FROM dbo.Department
   )
   OR EXISTS
   (
       SELECT DepartmentID, DepartmentName FROM dbo.Department
       EXCEPT
       SELECT DepartmentID, DepartmentName FROM @ExpectedDepartments
   )
    THROW 51203, 'STOP: Department seed differs from the approved eight-row set.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Exclusive lock ensures a safe, empty-table-only first population.
    IF EXISTS (SELECT 1 FROM dbo.Professor WITH (TABLOCKX, HOLDLOCK))
        THROW 51204, 'STOP: Professor already contains rows; no INSERT attempted.', 1;

    -- Batch 1: independent professors, no self-referencing FK dependency.
    INSERT INTO dbo.Professor
        (ProfessorID, [Name], DepartmentID, AdvisorProfessorID)
    VALUES
    (101, N'Layla Nasser', 1, NULL),
    (102, N'Kareem Haddad', 1, NULL),
    (201, N'Hala Mansour', 2, NULL),
    (202, N'Tarek Salim', 2, NULL),
    (301, N'Dalia Saeed', 3, NULL),
    (302, N'Basma Ali', 3, NULL),
    (401, N'Farid Younis', 4, NULL),
    (402, N'Nada Hamdi', 4, NULL),
    (501, N'Ihab Zaki', 5, NULL),
    (502, N'Salma Farouk', 5, NULL),
    (601, N'Nabil Ismail', 6, NULL),
    (602, N'Lamis Ahmed', 6, NULL),
    (701, N'Safa Mahmoud', 7, NULL),
    (702, N'Walid Ashour', 7, NULL),
    (801, N'Eman Adel', 8, NULL),
    (802, N'Khaled Salem', 8, NULL);
    IF @@ROWCOUNT <> 16
        THROW 51205, 'STOP: Expected exactly 16 independent professors.', 1;

    -- Batch 2: advisors now exist, including in the same Department.
    INSERT INTO dbo.Professor
        (ProfessorID, [Name], DepartmentID, AdvisorProfessorID)
    VALUES
    (103, N'Noor Elmasry', 1, 101),
    (104, N'Samir Khalil', 1, 102),
    (203, N'Rania Fadel', 2, 201),
    (204, N'Youssef Adnan', 2, 202),
    (303, N'Mahmoud Kamal', 3, 301),
    (304, N'Yasmin Darwish', 3, 302),
    (403, N'Hatem Saqr', 4, 401),
    (404, N'Muna Sabri', 4, 402),
    (503, N'Sameh Raouf', 5, 501),
    (504, N'Jana Hashim', 5, 502),
    (603, N'Omar Rashid', 6, 601),
    (604, N'Mariam Diab', 6, 602),
    (703, N'Sara Anwar', 7, 701),
    (704, N'Fadi Hussein', 7, 702),
    (803, N'Noura Fawzi', 8, 801),
    (804, N'Rami Atef', 8, 802);
    IF @@ROWCOUNT <> 16
        THROW 51206, 'STOP: Expected exactly 16 advised professors.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Professor) <> 32
        THROW 51207, 'STOP: Expected 32 total professor rows.', 1;

    IF EXISTS
    (
        SELECT d.DepartmentID
        FROM dbo.Department AS d
        LEFT JOIN dbo.Professor AS p ON p.DepartmentID = d.DepartmentID
        GROUP BY d.DepartmentID
        HAVING COUNT(p.ProfessorID) <> 4
    )
        THROW 51208, 'STOP: Expected four professors per department.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.Professor AS p
        LEFT JOIN dbo.Professor AS a ON a.ProfessorID = p.AdvisorProfessorID
        WHERE p.AdvisorProfessorID IS NOT NULL
          AND (a.ProfessorID IS NULL OR a.DepartmentID <> p.DepartmentID
               OR p.ProfessorID = p.AdvisorProfessorID)
    )
        THROW 51209, 'STOP: Invalid advisor or cross-department reference.', 1;

    COMMIT TRANSACTION;
    PRINT 'PASS: 32 synthetic professors inserted and committed. Run separate read-only verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-----------------------
---Table 02: Professor Verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Professor', N'U') IS NULL
    THROW 51301, 'FAIL: dbo.Professor does not exist.', 1;

DECLARE @Expected TABLE
(
    ProfessorID INT NOT NULL PRIMARY KEY,
    [Name] NVARCHAR(150) NOT NULL,
    DepartmentID INT NOT NULL,
    AdvisorProfessorID INT NULL
);
INSERT INTO @Expected (ProfessorID, [Name], DepartmentID, AdvisorProfessorID)
VALUES
    (101, N'Layla Nasser', 1, NULL),
    (102, N'Kareem Haddad', 1, NULL),
    (103, N'Noor Elmasry', 1, 101),
    (104, N'Samir Khalil', 1, 102),
    (201, N'Hala Mansour', 2, NULL),
    (202, N'Tarek Salim', 2, NULL),
    (203, N'Rania Fadel', 2, 201),
    (204, N'Youssef Adnan', 2, 202),
    (301, N'Dalia Saeed', 3, NULL),
    (302, N'Basma Ali', 3, NULL),
    (303, N'Mahmoud Kamal', 3, 301),
    (304, N'Yasmin Darwish', 3, 302),
    (401, N'Farid Younis', 4, NULL),
    (402, N'Nada Hamdi', 4, NULL),
    (403, N'Hatem Saqr', 4, 401),
    (404, N'Muna Sabri', 4, 402),
    (501, N'Ihab Zaki', 5, NULL),
    (502, N'Salma Farouk', 5, NULL),
    (503, N'Sameh Raouf', 5, 501),
    (504, N'Jana Hashim', 5, 502),
    (601, N'Nabil Ismail', 6, NULL),
    (602, N'Lamis Ahmed', 6, NULL),
    (603, N'Omar Rashid', 6, 601),
    (604, N'Mariam Diab', 6, 602),
    (701, N'Safa Mahmoud', 7, NULL),
    (702, N'Walid Ashour', 7, NULL),
    (703, N'Sara Anwar', 7, 701),
    (704, N'Fadi Hussein', 7, 702),
    (801, N'Eman Adel', 8, NULL),
    (802, N'Khaled Salem', 8, NULL),
    (803, N'Noura Fawzi', 8, 801),
    (804, N'Rami Atef', 8, 802);

-- TEST 1: Exact row set (including advisor NULLs), count, and active FK constraints.
SELECT
    N'Professor: Exact Row Set + FK' AS VerificationTest,
    CASE
        WHEN (SELECT COUNT_BIG(*) FROM dbo.Professor) = 32
         AND NOT EXISTS
         (
             SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID FROM @Expected
             EXCEPT
             SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID FROM dbo.Professor
         )
         AND NOT EXISTS
         (
             SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID FROM dbo.Professor
             EXCEPT
             SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID FROM @Expected
         )
         AND (SELECT COUNT_BIG(*) FROM dbo.Professor WHERE AdvisorProfessorID IS NULL) = 16
         AND (SELECT COUNT_BIG(*) FROM dbo.Professor WHERE AdvisorProfessorID IS NOT NULL) = 16
         AND NOT EXISTS
         (
             SELECT d.DepartmentID
             FROM dbo.Department AS d
             LEFT JOIN dbo.Professor AS p ON p.DepartmentID = d.DepartmentID
             GROUP BY d.DepartmentID
             HAVING COUNT(p.ProfessorID) <> 4
         )
         AND EXISTS
         (
             SELECT 1 FROM sys.foreign_keys AS fk
             WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Professor', N'U')
               AND fk.name = N'FK_Professor_AdvisorSameDepartment'
               AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
         )
         AND EXISTS
         (
             SELECT 1 FROM sys.foreign_keys AS fk
             WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Professor', N'U')
               AND fk.name = N'FK_Professor_Department'
               AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
         )
        THEN 'PASS' ELSE 'FAIL'
    END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Professor) AS ActualRows,
    CAST(32 AS BIGINT) AS ExpectedRows;

-- TEST 2: Distribution; expect eight rows, count = 4 and 2 advised per department.
SELECT
    d.DepartmentID,
    d.DepartmentName,
    COUNT(p.ProfessorID) AS ProfessorCount,
    SUM(CASE WHEN p.AdvisorProfessorID IS NULL AND p.ProfessorID IS NOT NULL THEN 1 ELSE 0 END) AS WithoutAdvisor,
    SUM(CASE WHEN p.AdvisorProfessorID IS NOT NULL THEN 1 ELSE 0 END) AS WithAdvisor
FROM dbo.Department AS d
LEFT JOIN dbo.Professor AS p ON p.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY d.DepartmentID;

-- TEST 3: Advisor anomalies; expect ZERO rows.
SELECT p.ProfessorID, p.[Name], p.DepartmentID, p.AdvisorProfessorID,
       a.DepartmentID AS AdvisorDepartmentID
FROM dbo.Professor AS p
LEFT JOIN dbo.Professor AS a ON a.ProfessorID = p.AdvisorProfessorID
WHERE p.AdvisorProfessorID IS NOT NULL
  AND (a.ProfessorID IS NULL OR a.DepartmentID <> p.DepartmentID
       OR p.ProfessorID = p.AdvisorProfessorID);

-- TEST 4: Unexpected database rows; expect ZERO rows.
SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID
FROM dbo.Professor
EXCEPT
SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID
FROM @Expected;

-- TEST 5: Missing expected rows; expect ZERO rows.
SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID
FROM @Expected
EXCEPT
SELECT ProfessorID, [Name], DepartmentID, AdvisorProfessorID
FROM dbo.Professor;

-- TEST 6: Visual inspection: professor, department and academic advisor.
SELECT p.ProfessorID, p.[Name] AS ProfessorName, p.DepartmentID,
       d.DepartmentName, p.AdvisorProfessorID,
       a.[Name] AS AdvisorName
FROM dbo.Professor AS p
JOIN dbo.Department AS d ON d.DepartmentID = p.DepartmentID
LEFT JOIN dbo.Professor AS a ON a.ProfessorID = p.AdvisorProfessorID
ORDER BY p.DepartmentID, p.ProfessorID;
GO
---------------------------------------
GO
