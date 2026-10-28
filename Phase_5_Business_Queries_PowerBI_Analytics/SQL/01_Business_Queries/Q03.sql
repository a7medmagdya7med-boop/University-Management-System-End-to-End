-- Extracted from UniversityManagementDB(2).sql; source lines 10695-10704.
USE [UniversityManagementDB];
GO
-- Q03 | BASIC | Semester register
-- Business question: What academic years and semester periods are configured?
-- ================================================================
SELECT s.SemesterID, s.AcademicYear, s.TermName
FROM dbo.Semester AS s
ORDER BY s.SemesterID;
GO


-- ================================================================
GO
