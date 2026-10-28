-- Extracted from UniversityManagementDB(2).sql; source lines 10849-10861.
USE [UniversityManagementDB];
GO
-- Q14 | CTE / SUBQUERY | Students without an ID card (OBD-01)
-- Business question: Which students have no ID-card record? Informational only.
-- ================================================================
SELECT s.StudentID,s.[Name] AS StudentName,s.Email,
       N'OBD-01: timing policy pending' AS BusinessDecisionStatus
FROM dbo.Student AS s
WHERE NOT EXISTS
 (SELECT 1 FROM dbo.UniversityIDCard AS u WHERE u.StudentID=s.StudentID)
ORDER BY s.StudentID;
GO


-- ================================================================
GO
