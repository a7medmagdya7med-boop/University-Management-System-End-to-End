-- Extracted from UniversityManagementDB(2).sql; source lines 112-176.
USE [UniversityManagementDB];
GO
  -----------02_Create_Tables_03_Semester
  
USE [UniversityManagementDB];
GO

IF OBJECT_ID(N'dbo.Semester', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Semester
    (
        SemesterID INT NOT NULL,
        AcademicYear NVARCHAR(9) NOT NULL,
        TermName NVARCHAR(50) NOT NULL,

        CONSTRAINT PK_Semester
            PRIMARY KEY CLUSTERED (SemesterID),

        CONSTRAINT UQ_Semester_AcademicYear_TermName
            UNIQUE (AcademicYear, TermName)
    );

    PRINT 'Semester table created successfully.';
END
ELSE
BEGIN
    PRINT 'Semester already exists. No changes made.';
END;
GO
-------------------------
----------04_Verify_Semester


USE [UniversityManagementDB];
GO

SELECT
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Semester'
ORDER BY ORDINAL_POSITION;

-----------------------------------
-----Primary Key
SELECT
    kc.name AS ConstraintName,
    kc.type_desc AS ConstraintType,
    c.name AS ColumnName,
    ic.key_ordinal AS ColumnOrder
FROM sys.key_constraints AS kc
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.parent_object_id =
    OBJECT_ID(N'dbo.Semester', N'U')
  AND kc.type IN ('PK', 'UQ')
  AND ic.key_ordinal > 0
ORDER BY kc.name, ic.key_ordinal;

----------------------------------------------
GO
