-- Extracted from UniversityManagementDB(2).sql; source lines 10720-10731.
USE [UniversityManagementDB];
GO
-- Q05 | BASIC | Books by library
-- Business question: How many book records are catalogued in each library?
-- ================================================================
SELECT l.LibraryID, l.LibraryName, COUNT_BIG(b.BookID) AS BooksCount
FROM dbo.Library AS l
LEFT JOIN dbo.Book AS b ON b.LibraryID=l.LibraryID
GROUP BY l.LibraryID,l.LibraryName
ORDER BY l.LibraryID;
GO


-- ================================================================
GO
