-- Extracted from UniversityManagementDB(2).sql; source lines 10670-10681.
USE [UniversityManagementDB];
GO
-- Q01 | BASIC | Student population by birth year
-- Business question: How is the student population distributed across birth years?
-- ================================================================
SELECT YEAR(s.DateOfBirth) AS BirthYear,
       COUNT_BIG(*) AS StudentCount
FROM dbo.Student AS s
GROUP BY YEAR(s.DateOfBirth)
ORDER BY BirthYear;
GO


-- ================================================================
GO
