-- Extracted from UniversityManagementDB(2).sql; source lines 10883-10899.
USE [UniversityManagementDB];
GO
-- Q16 | ADVANCED | Semester grade rankings
-- Business question: Rank completed students by grade within each semester.
-- ================================================================
SELECT se.AcademicYear,se.TermName,
       e.SemesterID,e.CourseID,c.CourseTitle,e.StudentID,s.[Name] AS StudentName,
       e.Grade,
       DENSE_RANK() OVER (PARTITION BY e.SemesterID ORDER BY e.Grade DESC) AS SemesterGradeRank
FROM dbo.Enrollment AS e
JOIN dbo.Semester AS se ON se.SemesterID=e.SemesterID
JOIN dbo.Course AS c ON c.CourseID=e.CourseID
JOIN dbo.Student AS s ON s.StudentID=e.StudentID
WHERE e.EnrollmentStatus=N'Completed' AND e.Grade IS NOT NULL
ORDER BY e.SemesterID,SemesterGradeRank,e.StudentID,e.CourseID;
GO


-- ================================================================
GO
