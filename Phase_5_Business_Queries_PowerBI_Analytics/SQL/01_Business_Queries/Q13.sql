-- Extracted from UniversityManagementDB(2).sql; source lines 10837-10848.
USE [UniversityManagementDB];
GO
-- Q13 | CTE / SUBQUERY | Research projects without participants
-- Business question: Which research projects have no registered student participation?
-- ================================================================
SELECT rp.ResearchProjectID,rp.ProjectTitle
FROM dbo.ResearchProject AS rp
WHERE NOT EXISTS
 (SELECT 1 FROM dbo.ResearchParticipation AS pa WHERE pa.ResearchProjectID=rp.ResearchProjectID)
ORDER BY rp.ResearchProjectID;
GO


-- ================================================================
GO
