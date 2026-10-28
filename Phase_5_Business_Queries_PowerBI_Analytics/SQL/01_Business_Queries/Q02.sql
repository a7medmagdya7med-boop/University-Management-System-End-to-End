-- Extracted from UniversityManagementDB(2).sql; source lines 10682-10694.
USE [UniversityManagementDB];
GO
-- Q02 | BASIC | Enrollment pipeline by status
-- Business question: What is the proportion of completed, enrolled, and planned records?
-- ================================================================
SELECT e.EnrollmentStatus,
       COUNT_BIG(*) AS EnrollmentCount,
       CAST(100.0 * COUNT_BIG(*) / NULLIF((SELECT COUNT_BIG(*) FROM dbo.Enrollment), 0) AS DECIMAL(6,2)) AS SharePct
FROM dbo.Enrollment AS e
GROUP BY e.EnrollmentStatus
ORDER BY EnrollmentCount DESC, e.EnrollmentStatus;
GO


-- ================================================================
GO
