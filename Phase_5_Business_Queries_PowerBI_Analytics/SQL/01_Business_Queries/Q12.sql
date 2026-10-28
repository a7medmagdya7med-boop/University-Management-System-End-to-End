-- Extracted from UniversityManagementDB(2).sql; source lines 10818-10836.
USE [UniversityManagementDB];
GO
-- Q12 | CTE / SUBQUERY | Students with multiple current clubs
-- Business question: Which students have two or more current memberships?
-- ================================================================
;WITH ActiveClubs AS
(
 SELECT cm.StudentID,COUNT_BIG(*) AS ActiveClubCount
 FROM dbo.ClubMembership AS cm
 WHERE cm.EndDate IS NULL AND cm.JoinDate <= CONVERT(DATE,GETDATE())
 GROUP BY cm.StudentID
)
SELECT s.StudentID,s.[Name] AS StudentName,a.ActiveClubCount
FROM ActiveClubs AS a
JOIN dbo.Student AS s ON s.StudentID=a.StudentID
WHERE a.ActiveClubCount>=2
ORDER BY a.ActiveClubCount DESC,s.StudentID;
GO


-- ================================================================
GO
