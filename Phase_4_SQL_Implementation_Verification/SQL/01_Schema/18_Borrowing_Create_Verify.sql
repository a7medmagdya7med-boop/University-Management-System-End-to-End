-- Extracted from UniversityManagementDB(2).sql; source lines 1424-1576.
USE [UniversityManagementDB];
GO
---CREATE TABLE — Borrowing
USE [UniversityManagementDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Borrowing', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Borrowing
    (
        BorrowingID BIGINT NOT NULL,
        StudentID INT NOT NULL,
        BookID INT NOT NULL,
        BorrowDate DATE NOT NULL,
        DueDate DATE NOT NULL,
        ReturnDate DATE NULL,

        CONSTRAINT PK_Borrowing
            PRIMARY KEY CLUSTERED (BorrowingID),

        CONSTRAINT FK_Borrowing_Student
            FOREIGN KEY (StudentID)
            REFERENCES dbo.Student(StudentID),

        CONSTRAINT FK_Borrowing_Book
            FOREIGN KEY (BookID)
            REFERENCES dbo.Book(BookID),

        CONSTRAINT CK_Borrowing_DueDate
            CHECK (DueDate >= BorrowDate),

        CONSTRAINT CK_Borrowing_ReturnDate
            CHECK (
                ReturnDate IS NULL
                OR ReturnDate >= BorrowDate
            )
    );

    PRINT 'Borrowing table created successfully.';
END
ELSE
BEGIN
    PRINT 'Borrowing already exists. No changes made.';
END;
GO

IF OBJECT_ID(N'dbo.Borrowing', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.indexes
       WHERE object_id = OBJECT_ID(N'dbo.Borrowing', N'U')
         AND name = N'UX_Borrowing_OneOpenLoanPerBook'
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX
        UX_Borrowing_OneOpenLoanPerBook
    ON dbo.Borrowing (BookID)
    WHERE ReturnDate IS NULL;

    PRINT 'Filtered unique index created successfully.';
END;
GO
----------------------------------------
-----Verification — Borrowing
-- Test 0: table existence. Expected: EXISTS.
SELECT CASE WHEN OBJECT_ID(N'dbo.Borrowing', N'U') IS NOT NULL
            THEN 'EXISTS' ELSE 'NOT FOUND' END AS TableStatus;
GO
----------------------------------------
-- Test 1: six columns, data types and nullability.
SELECT COLUMN_NAME AS ColumnName,
       DATA_TYPE AS DataType,
       CHARACTER_MAXIMUM_LENGTH AS MaxLength,
       NUMERIC_PRECISION AS NumericPrecision,
       NUMERIC_SCALE AS NumericScale,
       IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Borrowing'
ORDER BY ORDINAL_POSITION;
GO
--------------------------------------
-- Test 2: PK_Borrowing, single column BorrowingID.
SELECT kc.name AS PrimaryKeyName,
       c.name AS PrimaryKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
  ON ic.object_id = kc.parent_object_id
 AND ic.index_id = kc.unique_index_id
JOIN sys.columns AS c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.Borrowing', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0
ORDER BY ic.key_ordinal;
GO
------------------------------------------
-- Test 3: FK references must point to Student and Book; enabled and trusted.
SELECT fk.name AS ForeignKeyName,
       pc.name AS ParentColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn,
       fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
  ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns AS pc
  ON pc.object_id = fkc.parent_object_id
 AND pc.column_id = fkc.parent_column_id
JOIN sys.columns AS rc
  ON rc.object_id = fkc.referenced_object_id
 AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Borrowing', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
---------------------------------------------
-- Test 4: two date CHECK constraints, enabled and trusted.
SELECT cc.name AS CheckConstraintName,
       cc.definition AS CheckDefinition,
       cc.is_disabled AS IsDisabled,
       cc.is_not_trusted AS IsNotTrusted
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id = OBJECT_ID(N'dbo.Borrowing', N'U')
ORDER BY cc.name;
GO
----------------------------------
-- Test 5: UNIQUE filtered index on BookID WHERE ReturnDate IS NULL.
SELECT i.name AS IndexName,
       i.is_unique AS IsUnique,
       i.has_filter AS HasFilter,
       i.filter_definition AS FilterDefinition,
       i.is_disabled AS IsDisabled,
       c.name AS IndexKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.indexes AS i
JOIN sys.index_columns AS ic
  ON ic.object_id = i.object_id
 AND ic.index_id = i.index_id
 AND ic.key_ordinal > 0
JOIN sys.columns AS c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.Borrowing', N'U')
  AND i.name = N'UX_Borrowing_OneOpenLoanPerBook'
ORDER BY ic.key_ordinal;
GO
---------------------------------------
GO
