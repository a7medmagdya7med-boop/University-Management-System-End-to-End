-- Extracted from UniversityManagementDB(2).sql; source lines 11007-11032.
USE [UniversityManagementDB];
GO
/* Phase 5 - BUSINESS QUERIES read-only smoke checks; approved seed baseline only.
   Verify on your SQL Server; never perform any writes. */
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SELECT DB_NAME() AS ConnectedDatabase,
       CASE WHEN DB_NAME()=N'UniversityManagementDB' THEN 'PASS' ELSE 'FAIL' END AS DatabaseNameCheck;
SELECT (SELECT COUNT_BIG(*) FROM dbo.Student) AS Students,
       (SELECT COUNT_BIG(*) FROM dbo.Course) AS Courses,
       (SELECT COUNT_BIG(*) FROM dbo.Enrollment) AS EnrollmentRows,
       (SELECT COUNT_BIG(*) FROM dbo.Borrowing) AS BorrowingRows,
       (SELECT COUNT_BIG(*) FROM dbo.ClubMembership) AS MembershipRows,
       (SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation) AS ParticipationRows,
       (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration) AS CollaborationRows;
-- OBD-01: informational gap, not a failed business rule.
SELECT COUNT_BIG(*) AS StudentsWithoutCards,
       N'OBD-01 OPEN' AS PolicyStatus
FROM dbo.Student AS s WHERE NOT EXISTS
 (SELECT 1 FROM dbo.UniversityIDCard AS u WHERE u.StudentID=s.StudentID);
-- D-18: informational gap, not a failed business rule.
SELECT COUNT_BIG(*) AS ParticipationPairsWithoutCollaboration,
       N'D-18 OPEN' AS PolicyStatus
FROM dbo.ResearchParticipation AS p WHERE NOT EXISTS
 (SELECT 1 FROM dbo.ResearchCollaboration AS c
  WHERE c.StudentID=p.StudentID AND c.ResearchProjectID=p.ResearchProjectID);
GO
GO
