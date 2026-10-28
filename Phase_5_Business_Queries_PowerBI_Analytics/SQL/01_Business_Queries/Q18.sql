-- Extracted from UniversityManagementDB(2).sql; source lines 10922-10945.
USE [UniversityManagementDB];
GO
-- Q18 | ADVANCED | Research project supervision profile
-- Business question: How many supervisors and participants does each project have?
-- ================================================================
;WITH Supervision AS
(
 SELECT ResearchProjectID,COUNT_BIG(*) AS SupervisorsCount
 FROM dbo.ResearchProjectSupervision GROUP BY ResearchProjectID
), Participation AS
(
 SELECT ResearchProjectID,COUNT_BIG(*) AS StudentParticipants
 FROM dbo.ResearchParticipation GROUP BY ResearchProjectID
)
SELECT rp.ResearchProjectID,rp.ProjectTitle,d.DepartmentName AS LeadDepartment,
       COALESCE(s.SupervisorsCount,0) AS SupervisorsCount,
       COALESCE(p.StudentParticipants,0) AS StudentParticipants
FROM dbo.ResearchProject AS rp
JOIN dbo.Department AS d ON d.DepartmentID=rp.LeadDepartmentID
LEFT JOIN Supervision AS s ON s.ResearchProjectID=rp.ResearchProjectID
LEFT JOIN Participation AS p ON p.ResearchProjectID=rp.ResearchProjectID
ORDER BY rp.ResearchProjectID;
GO


-- ================================================================
GO
