-- Extracted from UniversityManagementDB(2).sql; source lines 10732-10745.
USE [UniversityManagementDB];
GO
-- Q06 | JOINS | Students and graduation projects
-- Business question: Which students have graduation projects and what is their department?
-- ================================================================
SELECT s.StudentID, s.[Name] AS StudentName,
       g.GraduationProjectID, g.ProjectTitle,
       d.DepartmentName
FROM dbo.Student AS s
LEFT JOIN dbo.GraduationProject AS g ON s.GraduationProjectID=g.GraduationProjectID
LEFT JOIN dbo.Department AS d ON g.DepartmentID=d.DepartmentID
ORDER BY s.StudentID;
GO


-- ================================================================
GO
