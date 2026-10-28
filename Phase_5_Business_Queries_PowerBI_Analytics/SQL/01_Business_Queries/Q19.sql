-- Extracted from UniversityManagementDB(2).sql; source lines 10946-10969.
USE [UniversityManagementDB];
GO
-- Q19 | ADVANCED | Loan performance and aging
-- Business question: What is the open, overdue, returned mix and overdue-day exposure?
-- ================================================================
DECLARE @AsOfDate DATE=CONVERT(DATE,GETDATE());
;WITH LoanFacts AS
(
 SELECT b.BorrowingID,b.BookID,b.StudentID,
        CASE WHEN b.ReturnDate IS NOT NULL THEN N'Returned'
             WHEN b.DueDate<@AsOfDate THEN N'Open overdue'
             ELSE N'Open not overdue' END AS LoanStatus,
        CASE WHEN b.ReturnDate IS NULL AND b.DueDate<@AsOfDate
             THEN DATEDIFF(DAY,b.DueDate,@AsOfDate) ELSE 0 END AS DaysOverdue
 FROM dbo.Borrowing AS b
)
SELECT LoanStatus,COUNT_BIG(*) AS LoanCount,
       SUM(DaysOverdue) AS TotalOpenOverdueDays,
       MAX(DaysOverdue) AS MaxOpenOverdueDays
FROM LoanFacts
GROUP BY LoanStatus
ORDER BY LoanStatus;
GO


-- ================================================================
GO
