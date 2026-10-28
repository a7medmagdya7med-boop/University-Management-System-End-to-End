-- Extracted from UniversityManagementDB(2).sql; source lines 10705-10719.
USE [UniversityManagementDB];
GO
-- Q04 | BASIC | University ID card coverage (OBD-01)
-- Business question: How many students have cards and how many are not yet issued?
-- ================================================================
SELECT
    (SELECT COUNT_BIG(*) FROM dbo.Student) AS TotalStudents,
    (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard) AS IssuedCards,
    (SELECT COUNT_BIG(*) FROM dbo.Student AS s
     WHERE NOT EXISTS (SELECT 1 FROM dbo.UniversityIDCard AS c WHERE c.StudentID=s.StudentID)) AS StudentsWithoutCards,
    CAST(100.0 * (SELECT COUNT_BIG(*) FROM dbo.UniversityIDCard) /
         NULLIF((SELECT COUNT_BIG(*) FROM dbo.Student),0) AS DECIMAL(6,2)) AS CardCoveragePct,
    N'OBD-01 OPEN: missing card does not imply an approved policy breach' AS DecisionNote;
GO


-- ================================================================
GO
