-- Extracted from UniversityManagementDB(2).sql; source lines 10806-10817.
USE [UniversityManagementDB];
GO
-- Q11 | CTE / SUBQUERY | Courses lacking assigned professors
-- Business question: Are any courses missing a responsible professor?
-- ================================================================
SELECT c.CourseID,c.CourseTitle
FROM dbo.Course AS c
WHERE NOT EXISTS
 (SELECT 1 FROM dbo.CourseResponsibility AS cr WHERE cr.CourseID=c.CourseID)
ORDER BY c.CourseID;
GO


-- ================================================================
GO
