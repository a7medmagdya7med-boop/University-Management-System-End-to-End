-- Extracted from UniversityManagementDB(2).sql; source lines 10746-10758.
USE [UniversityManagementDB];
GO
-- Q07 | JOINS | Departments and heads
-- Business question: Which professor heads each department?
-- ================================================================
SELECT d.DepartmentID,d.DepartmentName,
       p.ProfessorID,p.[Name] AS HeadProfessorName
FROM dbo.Department AS d
LEFT JOIN dbo.DepartmentHead AS dh ON dh.DepartmentID=d.DepartmentID
LEFT JOIN dbo.Professor AS p ON p.ProfessorID=dh.ProfessorID
ORDER BY d.DepartmentID;
GO


-- ================================================================
GO
