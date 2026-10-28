-- Extracted from UniversityManagementDB(2).sql; source lines 10759-10773.
USE [UniversityManagementDB];
GO
-- Q08 | JOINS | Teaching responsibility map
-- Business question: Which professors are responsible for each course?
-- ================================================================
SELECT c.CourseID,c.CourseTitle,
       p.ProfessorID,p.[Name] AS ProfessorName,
       d.DepartmentName AS ProfessorDepartment
FROM dbo.Course AS c
JOIN dbo.CourseResponsibility AS cr ON cr.CourseID=c.CourseID
JOIN dbo.Professor AS p ON p.ProfessorID=cr.ProfessorID
JOIN dbo.Department AS d ON d.DepartmentID=p.DepartmentID
ORDER BY c.CourseID,p.ProfessorID;
GO


-- ================================================================
GO
