-- Extracted from UniversityManagementDB(2).sql; source lines 4256-4534.
USE [UniversityManagementDB];
GO
--Table 09 Book
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Book', N'U') IS NULL
    THROW 51091, 'STOP: dbo.Book is not available.', 1;

IF EXISTS (SELECT 1 FROM dbo.Book)
    THROW 51092, 'STOP: dbo.Book contains data. No INSERT attempted.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Library
    WHERE LibraryID = 1 AND LibraryName = N'Central Library'
)
    THROW 51093, 'STOP: Central Library (LibraryID = 1) was not found.', 1;

-- Preflight: approved column names, positions, types and NOT NULL.
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')) <> 3
   OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                  AND name = N'BookID' AND column_id = 1
                  AND system_type_id = 56 AND is_nullable = 0 AND is_identity = 0)
   OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                  AND name = N'BookTitle' AND column_id = 2
                  AND system_type_id = 231 AND max_length = 510 AND is_nullable = 0)
   OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                  AND name = N'LibraryID' AND column_id = 3
                  AND system_type_id = 56 AND is_nullable = 0)
    THROW 51094, 'STOP: dbo.Book columns do not match the approved schema.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic
      ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c
      ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID(N'dbo.Book', N'U')
      AND kc.type = 'PK' AND kc.name = N'PK_Book'
      AND c.name = N'BookID' AND ic.key_ordinal = 1
)
    THROW 51095, 'STOP: approved PK_Book not found.', 1;

IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.Book',N'U')) <> 1
    THROW 51099, 'STOP: expected exactly one foreign key for dbo.Book.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
    JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Book', N'U')
      AND fk.referenced_object_id = OBJECT_ID(N'dbo.Library', N'U')
      AND fk.name = N'FK_Book_Library'
      AND fk.is_disabled = 0 AND fk.is_not_trusted = 0
      AND pc.name = N'LibraryID' AND rc.name = N'LibraryID'
)
    THROW 51096, 'STOP: approved enabled/trusted FK_Book_Library not found.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.Book (BookID, BookTitle, LibraryID)
    VALUES
        (3001, N'Introduction to Programming', 1),
        (3002, N'Introduction to Programming', 1),
        (3003, N'Database Systems', 1),
        (3004, N'Database Systems', 1),
        (3005, N'Principles of Management', 1),
        (3006, N'Principles of Management', 1),
        (3007, N'Strategic Management', 1),
        (3008, N'Strategic Management', 1),
        (3009, N'Systems Analysis and Design', 1),
        (3010, N'Systems Analysis and Design', 1),
        (3011, N'Enterprise Information Systems', 1),
        (3012, N'Enterprise Information Systems', 1),
        (3013, N'Electrical Circuits Fundamentals', 1),
        (3014, N'Electrical Circuits Fundamentals', 1),
        (3015, N'Renewable Energy Systems', 1),
        (3016, N'Renewable Energy Systems', 1),
        (3017, N'Engineering Mechanics', 1),
        (3018, N'Engineering Mechanics', 1),
        (3019, N'Manufacturing Processes', 1),
        (3020, N'Manufacturing Processes', 1),
        (3021, N'Calculus and Linear Algebra', 1),
        (3022, N'Calculus and Linear Algebra', 1),
        (3023, N'Applied Statistics', 1),
        (3024, N'Applied Statistics', 1),
        (3025, N'Classical Mechanics', 1),
        (3026, N'Classical Mechanics', 1),
        (3027, N'Modern Physics', 1),
        (3028, N'Modern Physics', 1),
        (3029, N'Microeconomics', 1),
        (3030, N'Microeconomics', 1),
        (3031, N'Macroeconomics', 1),
        (3032, N'Macroeconomics', 1);

    IF @@ROWCOUNT <> 32
        THROW 51097, 'STOP: Book INSERT did not affect 32 rows.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Book) <> 32
       OR (SELECT COUNT(DISTINCT BookTitle) FROM dbo.Book) <> 16
       OR EXISTS (SELECT 1 FROM dbo.Book GROUP BY BookTitle HAVING COUNT_BIG(*) <> 2)
       OR EXISTS (SELECT 1 FROM dbo.Book
                  WHERE LibraryID <> 1 OR BookTitle IS NULL
                     OR LEN(LTRIM(RTRIM(BookTitle))) = 0)
        THROW 51098, 'STOP: Book seed validation failed; transaction will roll back.', 1;

    COMMIT TRANSACTION;
    PRINT 'Book: 32 physical copies (16 titles x 2) committed. Run separate verification.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-------------------------------------
----READ-ONLY Verification
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Book', N'U') IS NULL
    THROW 51101, 'STOP: dbo.Book does not exist.', 1;

DECLARE @Expected TABLE
(
    BookID INT NOT NULL PRIMARY KEY,
    BookTitle NVARCHAR(255) NOT NULL,
    LibraryID INT NOT NULL
);

INSERT INTO @Expected (BookID, BookTitle, LibraryID)
VALUES
        (3001, N'Introduction to Programming', 1),
        (3002, N'Introduction to Programming', 1),
        (3003, N'Database Systems', 1),
        (3004, N'Database Systems', 1),
        (3005, N'Principles of Management', 1),
        (3006, N'Principles of Management', 1),
        (3007, N'Strategic Management', 1),
        (3008, N'Strategic Management', 1),
        (3009, N'Systems Analysis and Design', 1),
        (3010, N'Systems Analysis and Design', 1),
        (3011, N'Enterprise Information Systems', 1),
        (3012, N'Enterprise Information Systems', 1),
        (3013, N'Electrical Circuits Fundamentals', 1),
        (3014, N'Electrical Circuits Fundamentals', 1),
        (3015, N'Renewable Energy Systems', 1),
        (3016, N'Renewable Energy Systems', 1),
        (3017, N'Engineering Mechanics', 1),
        (3018, N'Engineering Mechanics', 1),
        (3019, N'Manufacturing Processes', 1),
        (3020, N'Manufacturing Processes', 1),
        (3021, N'Calculus and Linear Algebra', 1),
        (3022, N'Calculus and Linear Algebra', 1),
        (3023, N'Applied Statistics', 1),
        (3024, N'Applied Statistics', 1),
        (3025, N'Classical Mechanics', 1),
        (3026, N'Classical Mechanics', 1),
        (3027, N'Modern Physics', 1),
        (3028, N'Modern Physics', 1),
        (3029, N'Microeconomics', 1),
        (3030, N'Microeconomics', 1),
        (3031, N'Macroeconomics', 1),
        (3032, N'Macroeconomics', 1);

-- Test 1: concise overall verdict, including exact rowset and metadata.
SELECT
    N'Book: Exact Row Set + Schema + PK + FK' AS VerificationTest,
    CASE WHEN
        (SELECT COUNT_BIG(*) FROM dbo.Book) = 32
        AND NOT EXISTS (SELECT BookID, BookTitle, LibraryID FROM @Expected
                        EXCEPT SELECT BookID, BookTitle, LibraryID FROM dbo.Book)
        AND NOT EXISTS (SELECT BookID, BookTitle, LibraryID FROM dbo.Book
                        EXCEPT SELECT BookID, BookTitle, LibraryID FROM @Expected)
        AND (SELECT COUNT_BIG(*) FROM sys.columns
             WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')) = 3
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                    AND name=N'BookID' AND column_id=1 AND system_type_id=56
                    AND is_nullable=0 AND is_identity=0)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                    AND name=N'BookTitle' AND column_id=2 AND system_type_id=231
                    AND max_length=510 AND is_nullable=0)
        AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Book', N'U')
                    AND name=N'LibraryID' AND column_id=3 AND system_type_id=56
                    AND is_nullable=0)
        AND EXISTS
        (
            SELECT 1 FROM sys.key_constraints kc
            JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id
                                      AND ic.index_id=kc.unique_index_id
            JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
            WHERE kc.parent_object_id=OBJECT_ID(N'dbo.Book', N'U')
              AND kc.name=N'PK_Book' AND kc.type='PK'
              AND c.name=N'BookID' AND ic.key_ordinal=1
        )
        AND (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.Book',N'U'))=1
        AND EXISTS
        (
            SELECT 1 FROM sys.foreign_keys fk
            JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
            JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
            JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
            WHERE fk.name=N'FK_Book_Library'
              AND fk.parent_object_id=OBJECT_ID(N'dbo.Book', N'U')
              AND fk.referenced_object_id=OBJECT_ID(N'dbo.Library', N'U')
              AND fk.is_disabled=0 AND fk.is_not_trusted=0
              AND pc.name=N'LibraryID' AND rc.name=N'LibraryID'
        )
        AND NOT EXISTS (SELECT 1 FROM sys.indexes
                        WHERE object_id=OBJECT_ID(N'dbo.Book', N'U')
                          AND is_unique=1 AND is_primary_key=0)
        AND NOT EXISTS (SELECT 1 FROM dbo.Book
                        WHERE BookTitle IS NULL OR LEN(LTRIM(RTRIM(BookTitle)))=0)
        AND NOT EXISTS (SELECT 1 FROM dbo.Book b
                        LEFT JOIN dbo.Library l ON l.LibraryID=b.LibraryID
                        WHERE l.LibraryID IS NULL)
        AND (SELECT COUNT(DISTINCT BookTitle) FROM dbo.Book) = 16
        AND NOT EXISTS (SELECT 1 FROM dbo.Book GROUP BY BookTitle HAVING COUNT_BIG(*)<>2)
        THEN 'PASS' ELSE 'FAIL'
    END AS VerificationResult,
    (SELECT COUNT_BIG(*) FROM dbo.Book) AS ActualRows,
    (SELECT COUNT_BIG(*) FROM @Expected) AS ExpectedRows;

-- Test 2: inspect every physical copy (expect 32 rows).
SELECT BookID, BookTitle, LibraryID FROM dbo.Book ORDER BY BookID;

-- Test 3: extra/wrong records (expect 0 rows).
SELECT BookID, BookTitle, LibraryID FROM dbo.Book
EXCEPT
SELECT BookID, BookTitle, LibraryID FROM @Expected;

-- Test 4: missing expected records (expect 0 rows).
SELECT BookID, BookTitle, LibraryID FROM @Expected
EXCEPT
SELECT BookID, BookTitle, LibraryID FROM dbo.Book;

-- Test 5: orphaned library references (expect 0 rows).
SELECT b.BookID, b.BookTitle, b.LibraryID
FROM dbo.Book b LEFT JOIN dbo.Library l ON l.LibraryID=b.LibraryID
WHERE l.LibraryID IS NULL;

-- Test 6: NULL/blank book titles (expect 0 rows).
SELECT BookID, BookTitle FROM dbo.Book
WHERE BookTitle IS NULL OR LEN(LTRIM(RTRIM(BookTitle)))=0;

-- Test 7: actual physical copies by title (expect 16 rows, Copies=2).
SELECT BookTitle, COUNT_BIG(*) AS Copies
FROM dbo.Book GROUP BY BookTitle ORDER BY BookTitle;

-- Test 8: unauthorized non-PK unique indexes (expect 0 rows).
SELECT name AS UnexpectedUniqueIndex, is_unique AS IsUnique, is_primary_key AS IsPK
FROM sys.indexes
WHERE object_id=OBJECT_ID(N'dbo.Book', N'U')
  AND is_unique=1 AND is_primary_key=0;

-- Test 9: schema metadata (expect 3 rows).
SELECT c.column_id AS ColumnOrder, c.name AS ColumnName,
       TYPE_NAME(c.system_type_id) AS DataType, c.max_length AS LengthBytes,
       c.is_nullable AS IsNullable
FROM sys.columns c
WHERE c.object_id=OBJECT_ID(N'dbo.Book', N'U') ORDER BY c.column_id;

-- Test 10: FK metadata (expect 1 row, IsDisabled=0, IsNotTrusted=0).
SELECT fk.name AS ForeignKeyName, fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted,
       pc.name AS ParentColumn, rc.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.Book', N'U');
GO
---------------------------------
GO
