-- Extracted from UniversityManagementDB(2).sql; source lines 10862-10882.
USE [UniversityManagementDB];
GO
-- Q15 | CTE / SUBQUERY | Teaching loads above average
-- Business question: Which professors have more responsibility links than the professor mean?
-- ================================================================
;WITH TeachingLoad AS
(
 SELECT p.ProfessorID,p.[Name] AS ProfessorName,
        COUNT_BIG(cr.CourseID) AS AssignedCourses
 FROM dbo.Professor AS p
 LEFT JOIN dbo.CourseResponsibility AS cr ON cr.ProfessorID=p.ProfessorID
 GROUP BY p.ProfessorID,p.[Name]
)
SELECT t.ProfessorID,t.ProfessorName,t.AssignedCourses,
       a.AvgAssignedCourses
FROM TeachingLoad AS t
CROSS JOIN (SELECT CAST(AVG(CAST(AssignedCourses AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS AvgAssignedCourses FROM TeachingLoad) AS a
WHERE t.AssignedCourses>a.AvgAssignedCourses
ORDER BY t.AssignedCourses DESC,t.ProfessorID;
GO


-- ================================================================
GO
