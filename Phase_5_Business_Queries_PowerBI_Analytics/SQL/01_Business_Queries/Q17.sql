-- Extracted from UniversityManagementDB(2).sql; source lines 10900-10921.
USE [UniversityManagementDB];
GO
-- Q17 | ADVANCED | Course grades vs cohort mean
-- Business question: Compare each completed grade to the average recorded for that course.
-- ================================================================
;WITH CompletedGrades AS
(
 SELECT e.StudentID,e.CourseID,e.SemesterID,e.Grade,
        AVG(e.Grade) OVER(PARTITION BY e.CourseID) AS CourseMean
 FROM dbo.Enrollment AS e
 WHERE e.EnrollmentStatus=N'Completed' AND e.Grade IS NOT NULL
)
SELECT x.StudentID,s.[Name] AS StudentName,x.CourseID,c.CourseTitle,
       x.SemesterID,x.Grade,
       CAST(x.CourseMean AS DECIMAL(6,2)) AS CourseMean,
       CAST(x.Grade-x.CourseMean AS DECIMAL(7,2)) AS DeviationFromCourseMean
FROM CompletedGrades AS x
JOIN dbo.Student AS s ON s.StudentID=x.StudentID
JOIN dbo.Course AS c ON c.CourseID=x.CourseID
ORDER BY x.CourseID,x.StudentID,x.SemesterID;
GO


-- ================================================================
GO
