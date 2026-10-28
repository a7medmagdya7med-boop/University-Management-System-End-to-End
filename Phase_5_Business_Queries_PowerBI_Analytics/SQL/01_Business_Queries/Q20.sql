-- Extracted from UniversityManagementDB(2).sql; source lines 10970-11006.
USE [UniversityManagementDB];
GO
-- Q20 | ADVANCED | Research collaboration vs participation (D-18)
-- Business question: How complete are collaboration records relative to participation? No compliance inference.
-- ================================================================
;WITH LinkedPairs AS
(
 SELECT DISTINCT StudentID, ResearchProjectID
 FROM dbo.ResearchCollaboration
), P AS
(
 SELECT rp.ResearchProjectID, COUNT_BIG(*) AS ParticipationRows,
        SUM(CASE WHEN lp.StudentID IS NULL THEN 1 ELSE 0 END) AS ParticipationPairsWithoutCollaboration
 FROM dbo.ResearchParticipation AS rp
 LEFT JOIN LinkedPairs AS lp
   ON lp.StudentID=rp.StudentID AND lp.ResearchProjectID=rp.ResearchProjectID
 GROUP BY rp.ResearchProjectID
), C AS
(
 SELECT rc.ResearchProjectID,COUNT_BIG(*) AS CollaborationRows,
        COUNT(DISTINCT rc.StudentID) AS CollaboratingStudents,
        SUM(CASE WHEN rc.CollaborationDepartmentID<>r.LeadDepartmentID THEN 1 ELSE 0 END) AS CrossLeadDepartmentRows
 FROM dbo.ResearchCollaboration AS rc
 JOIN dbo.ResearchProject AS r ON r.ResearchProjectID=rc.ResearchProjectID
 GROUP BY rc.ResearchProjectID
)
SELECT r.ResearchProjectID,r.ProjectTitle,r.LeadDepartmentID,
       COALESCE(p.ParticipationRows,0) AS ParticipationRows,
       COALESCE(c.CollaborationRows,0) AS CollaborationRows,
       COALESCE(c.CollaboratingStudents,0) AS CollaboratingStudents,
       COALESCE(c.CrossLeadDepartmentRows,0) AS CrossLeadDepartmentRows,
       COALESCE(p.ParticipationPairsWithoutCollaboration,0) AS UnlinkedParticipationPairs,
       N'D-18 OPEN: collaboration timing unapproved' AS BusinessDecisionStatus
FROM dbo.ResearchProject AS r
LEFT JOIN P AS p ON p.ResearchProjectID=r.ResearchProjectID
LEFT JOIN C AS c ON c.ResearchProjectID=r.ResearchProjectID
ORDER BY r.ResearchProjectID;
GO
---------------------------------------------
GO
