-- Extracted from UniversityManagementDB(2).sql; source lines 10789-10805.
USE [UniversityManagementDB];
GO
-- Q10 | JOINS | Library loans and status
-- Business question: Who borrowed which book, and is each open loan overdue?
-- ================================================================
DECLARE @AsOfDate DATE=CONVERT(DATE,GETDATE());
SELECT b.BorrowingID,s.StudentID,s.[Name] AS StudentName,
       bk.BookID,bk.BookTitle,b.BorrowDate,b.DueDate,b.ReturnDate,
       CASE WHEN b.ReturnDate IS NOT NULL THEN N'Returned'
            WHEN b.DueDate < @AsOfDate THEN N'Open overdue'
            ELSE N'Open not overdue' END AS LoanStatus
FROM dbo.Borrowing AS b
JOIN dbo.Student AS s ON s.StudentID=b.StudentID
JOIN dbo.Book AS bk ON bk.BookID=b.BookID
ORDER BY b.BorrowDate DESC,b.BorrowingID DESC;
GO


-- ================================================================
GO
