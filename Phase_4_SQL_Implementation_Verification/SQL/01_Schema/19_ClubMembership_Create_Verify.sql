-- Extracted from UniversityManagementDB(2).sql; source lines 1577-1774.
USE [UniversityManagementDB];
GO
---CREATE TABLE + PK + UQ + FK + CHECK + Filtered Index


USE [UniversityManagementDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.ClubMembership', N'U') IS NULL
BEGIN
    IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
       OR OBJECT_ID(N'dbo.StudentClub', N'U') IS NULL
    BEGIN
        THROW 51019, 'Prerequisite table Student or StudentClub does not exist.', 1;
    END;

    CREATE TABLE dbo.ClubMembership
    (
        ClubMembershipID BIGINT NOT NULL,
        StudentID INT NOT NULL,
        ClubID INT NOT NULL,
        JoinDate DATE NOT NULL,
        EndDate DATE NULL,

        CONSTRAINT PK_ClubMembership
            PRIMARY KEY CLUSTERED (ClubMembershipID),

        CONSTRAINT UQ_ClubMembership_StudentClubJoinDate
            UNIQUE (StudentID, ClubID, JoinDate),

        CONSTRAINT FK_ClubMembership_Student
            FOREIGN KEY (StudentID)
            REFERENCES dbo.Student (StudentID),

        CONSTRAINT FK_ClubMembership_StudentClub
            FOREIGN KEY (ClubID)
            REFERENCES dbo.StudentClub (ClubID),

        CONSTRAINT CK_ClubMembership_EndDate
            CHECK (EndDate IS NULL OR EndDate >= JoinDate)
    );

    PRINT 'ClubMembership table created successfully.';
END
ELSE
BEGIN
    PRINT 'ClubMembership already exists. No table changes made.';
END;
GO
------------------------------
-- SQL Server filtered uniqueness: ONE unended membership per student/club.
IF OBJECT_ID(N'dbo.ClubMembership', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.indexes
       WHERE object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
         AND name = N'UX_ClubMembership_OneActivePerStudentClub'
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_ClubMembership_OneActivePerStudentClub
        ON dbo.ClubMembership (StudentID, ClubID)
        WHERE EndDate IS NULL;

    PRINT 'Filtered unique index created successfully.';
END
ELSE
BEGIN
    PRINT 'Filtered unique index already exists (or table is unavailable).';
END;
GO
------------------------------
---Verification
-- Test 0: table existence.
SELECT CASE WHEN OBJECT_ID(N'dbo.ClubMembership', N'U') IS NOT NULL
            THEN 'EXISTS' ELSE 'NOT FOUND' END AS TableStatus;
GO
-----------------------------------
-- Test 1: columns, types and nullability (expect 5 rows).
SELECT COLUMN_NAME AS ColumnName,
       DATA_TYPE AS DataType,
       CHARACTER_MAXIMUM_LENGTH AS MaxLength,
       NUMERIC_PRECISION AS NumericPrecision,
       NUMERIC_SCALE AS NumericScale,
       IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ClubMembership'
ORDER BY ORDINAL_POSITION;
GO
------------------------------------
-- Test 2: primary key (expect one row: ClubMembershipID).
SELECT kc.name AS PrimaryKeyName,
       c.name AS PrimaryKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
  ON kc.parent_object_id = ic.object_id
 AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
  ON ic.object_id = c.object_id
 AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
  AND kc.type = 'PK'
  AND ic.key_ordinal > 0
ORDER BY ic.key_ordinal;
GO
---------------------------------------
-- Test 3: unique constraint (expect 3 rows in stated order).
SELECT kc.name AS UniqueConstraintName,
       c.name AS UniqueColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
  ON kc.parent_object_id = ic.object_id
 AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
  ON ic.object_id = c.object_id
 AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
  AND kc.type = 'UQ'
  AND ic.key_ordinal > 0
ORDER BY kc.name, ic.key_ordinal;
GO
------------------------------------------------
-- Test 4: foreign keys (expect 2 rows, enabled and trusted).
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
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
ORDER BY fk.name, fkc.constraint_column_id;
GO
--------------------------
-- Test 5: CHECK constraint (expect 1 row, enabled and trusted).
SELECT cc.name AS CheckConstraintName,
       cc.definition AS CheckDefinition,
       cc.is_disabled AS IsDisabled,
       cc.is_not_trusted AS IsNotTrusted
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
ORDER BY cc.name;
GO
-----------------------------------------
-- Test 6: filtered unique index (expect 2 rows for its 2 key columns).
SELECT i.name AS IndexName,
       i.is_unique AS IsUnique,
       i.has_filter AS HasFilter,
       i.filter_definition AS FilterDefinition,
       i.is_disabled AS IsDisabled,
       c.name AS IndexKeyColumn,
       ic.key_ordinal AS ColumnOrder
FROM sys.indexes AS i
JOIN sys.index_columns AS ic
  ON i.object_id = ic.object_id
 AND i.index_id = ic.index_id
 AND ic.key_ordinal > 0
JOIN sys.columns AS c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.ClubMembership', N'U')
  AND i.name = N'UX_ClubMembership_OneActivePerStudentClub'
ORDER BY ic.key_ordinal;
GO
------------------------------------------
-- Test 7: find potential historical membership overlaps, if any.
-- Zero rows means no conflicts in CURRENT stored data. It DOES NOT prove
-- the database prevents future overlapping non-NULL EndDate ranges.
SELECT a.StudentID,
       a.ClubID,
       a.ClubMembershipID AS MembershipA,
       a.JoinDate AS AJoinDate,
       a.EndDate AS AEndDate,
       b.ClubMembershipID AS MembershipB,
       b.JoinDate AS BJoinDate,
       b.EndDate AS BEndDate
FROM dbo.ClubMembership AS a
JOIN dbo.ClubMembership AS b
  ON a.StudentID = b.StudentID
 AND a.ClubID = b.ClubID
 AND a.ClubMembershipID < b.ClubMembershipID
 AND a.JoinDate <= ISNULL(b.EndDate, CONVERT(date, '99991231', 112))
 AND b.JoinDate <= ISNULL(a.EndDate, CONVERT(date, '99991231', 112))
ORDER BY a.StudentID, a.ClubID, a.ClubMembershipID;
GO
-----------------------
GO
