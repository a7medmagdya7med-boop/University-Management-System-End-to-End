-- Extracted from UniversityManagementDB(2).sql; source lines 10774-10788.
USE [UniversityManagementDB];
GO
-- Q09 | JOINS | Semester academic results
-- Business question: How do enrollment volume and recorded grades vary by semester?
-- ================================================================
SELECT se.SemesterID,se.AcademicYear,se.TermName,
       COUNT_BIG(e.StudentID) AS EnrollmentCount,
       SUM(CASE WHEN e.EnrollmentStatus=N'Completed' THEN 1 ELSE 0 END) AS CompletedCount,
       CAST(AVG(CASE WHEN e.EnrollmentStatus=N'Completed' THEN e.Grade END) AS DECIMAL(6,2)) AS AvgCompletedGrade
FROM dbo.Semester AS se
LEFT JOIN dbo.Enrollment AS e ON e.SemesterID=se.SemesterID
GROUP BY se.SemesterID,se.AcademicYear,se.TermName
ORDER BY se.SemesterID;
GO


-- ================================================================
GO
