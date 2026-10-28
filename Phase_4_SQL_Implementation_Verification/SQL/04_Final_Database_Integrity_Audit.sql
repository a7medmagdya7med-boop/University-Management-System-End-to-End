-- Extracted from UniversityManagementDB(2).sql; source lines 10023-10661.
USE [UniversityManagementDB];
GO
---Final Database Integrity Audit
--Phase4_Final_Database_Integrity_Audit_21Tables
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
IF DB_NAME() <> N'UniversityManagementDB'
    THROW 52000, 'STOP: unexpected target database.', 1;

DECLARE @AsOfDate DATE = CONVERT(DATE, GETDATE());
DECLARE @ExpectedTables TABLE
(
  Ordinal INT NOT NULL PRIMARY KEY,
  TableName SYSNAME NOT NULL UNIQUE,
  ExpectedRows BIGINT NOT NULL,
  PKColumns NVARCHAR(300) NOT NULL
);
INSERT INTO @ExpectedTables(Ordinal, TableName, ExpectedRows, PKColumns) VALUES
  (1,N'Department',8,N'DepartmentID'),
  (2,N'Professor',32,N'ProfessorID'),
  (3,N'Semester',8,N'SemesterID'),
  (4,N'Library',1,N'LibraryID'),
  (5,N'StudentClub',8,N'ClubID'),
  (6,N'Course',24,N'CourseID'),
  (7,N'GraduationProject',16,N'GraduationProjectID'),
  (8,N'ResearchProject',16,N'ResearchProjectID'),
  (9,N'Book',32,N'BookID'),
  (10,N'DepartmentHead',8,N'DepartmentID'),
  (11,N'Student',64,N'StudentID'),
  (12,N'CourseResponsibility',40,N'CourseID,ProfessorID'),
  (13,N'GraduationProjectSupervision',24,N'GraduationProjectID,ProfessorID'),
  (14,N'ResearchProjectSupervision',24,N'ResearchProjectID,ProfessorID'),
  (15,N'StudentPhone',80,N'StudentID,PhoneNumber'),
  (16,N'UniversityIDCard',48,N'CardNumber'),
  (17,N'Enrollment',192,N'StudentID,CourseID,SemesterID'),
  (18,N'Borrowing',96,N'BorrowingID'),
  (19,N'ClubMembership',88,N'ClubMembershipID'),
  (20,N'ResearchParticipation',80,N'StudentID,ResearchProjectID'),
  (21,N'ResearchCollaboration',80,N'StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID');

DECLARE @ExpectedColumns TABLE
(
 TableName SYSNAME NOT NULL,
 ColumnOrdinal INT NOT NULL,
 ColumnName SYSNAME NOT NULL,
 TypeName SYSNAME NOT NULL,
 LengthBytes SMALLINT NOT NULL,
 NumericPrecision TINYINT NOT NULL,
 NumericScale TINYINT NOT NULL,
 IsNullable BIT NOT NULL,
 PRIMARY KEY(TableName,ColumnOrdinal)
);
INSERT INTO @ExpectedColumns VALUES
  (N'Department',1,N'DepartmentID',N'int',4,0,0,0),
  (N'Department',2,N'DepartmentName',N'nvarchar',300,0,0,0),
  (N'Professor',1,N'ProfessorID',N'int',4,0,0,0),
  (N'Professor',2,N'Name',N'nvarchar',300,0,0,0),
  (N'Professor',3,N'DepartmentID',N'int',4,0,0,0),
  (N'Professor',4,N'AdvisorProfessorID',N'int',4,0,0,1),
  (N'Semester',1,N'SemesterID',N'int',4,0,0,0),
  (N'Semester',2,N'AcademicYear',N'nvarchar',18,0,0,0),
  (N'Semester',3,N'TermName',N'nvarchar',100,0,0,0),
  (N'Library',1,N'LibraryID',N'int',4,0,0,0),
  (N'Library',2,N'LibraryName',N'nvarchar',300,0,0,0),
  (N'StudentClub',1,N'ClubID',N'int',4,0,0,0),
  (N'StudentClub',2,N'ClubName',N'nvarchar',300,0,0,0),
  (N'Course',1,N'CourseID',N'int',4,0,0,0),
  (N'Course',2,N'CourseTitle',N'nvarchar',400,0,0,0),
  (N'GraduationProject',1,N'GraduationProjectID',N'int',4,0,0,0),
  (N'GraduationProject',2,N'ProjectTitle',N'nvarchar',510,0,0,0),
  (N'GraduationProject',3,N'DepartmentID',N'int',4,0,0,0),
  (N'ResearchProject',1,N'ResearchProjectID',N'int',4,0,0,0),
  (N'ResearchProject',2,N'ProjectTitle',N'nvarchar',510,0,0,0),
  (N'ResearchProject',3,N'LeadDepartmentID',N'int',4,0,0,0),
  (N'Book',1,N'BookID',N'int',4,0,0,0),
  (N'Book',2,N'BookTitle',N'nvarchar',510,0,0,0),
  (N'Book',3,N'LibraryID',N'int',4,0,0,0),
  (N'DepartmentHead',1,N'DepartmentID',N'int',4,0,0,0),
  (N'DepartmentHead',2,N'ProfessorID',N'int',4,0,0,0),
  (N'Student',1,N'StudentID',N'int',4,0,0,0),
  (N'Student',2,N'Name',N'nvarchar',300,0,0,0),
  (N'Student',3,N'DateOfBirth',N'date',3,0,0,0),
  (N'Student',4,N'Email',N'nvarchar',508,0,0,0),
  (N'Student',5,N'GraduationProjectID',N'int',4,0,0,1),
  (N'CourseResponsibility',1,N'CourseID',N'int',4,0,0,0),
  (N'CourseResponsibility',2,N'ProfessorID',N'int',4,0,0,0),
  (N'GraduationProjectSupervision',1,N'GraduationProjectID',N'int',4,0,0,0),
  (N'GraduationProjectSupervision',2,N'ProfessorID',N'int',4,0,0,0),
  (N'ResearchProjectSupervision',1,N'ResearchProjectID',N'int',4,0,0,0),
  (N'ResearchProjectSupervision',2,N'ProfessorID',N'int',4,0,0,0),
  (N'StudentPhone',1,N'StudentID',N'int',4,0,0,0),
  (N'StudentPhone',2,N'PhoneNumber',N'nvarchar',60,0,0,0),
  (N'UniversityIDCard',1,N'CardNumber',N'nvarchar',64,0,0,0),
  (N'UniversityIDCard',2,N'StudentID',N'int',4,0,0,0),
  (N'UniversityIDCard',3,N'IssueDate',N'date',3,0,0,0),
  (N'Enrollment',1,N'StudentID',N'int',4,0,0,0),
  (N'Enrollment',2,N'CourseID',N'int',4,0,0,0),
  (N'Enrollment',3,N'SemesterID',N'int',4,0,0,0),
  (N'Enrollment',4,N'Grade',N'decimal',5,5,2,1),
  (N'Enrollment',5,N'EnrollmentStatus',N'nvarchar',40,0,0,0),
  (N'Borrowing',1,N'BorrowingID',N'bigint',8,0,0,0),
  (N'Borrowing',2,N'StudentID',N'int',4,0,0,0),
  (N'Borrowing',3,N'BookID',N'int',4,0,0,0),
  (N'Borrowing',4,N'BorrowDate',N'date',3,0,0,0),
  (N'Borrowing',5,N'DueDate',N'date',3,0,0,0),
  (N'Borrowing',6,N'ReturnDate',N'date',3,0,0,1),
  (N'ClubMembership',1,N'ClubMembershipID',N'bigint',8,0,0,0),
  (N'ClubMembership',2,N'StudentID',N'int',4,0,0,0),
  (N'ClubMembership',3,N'ClubID',N'int',4,0,0,0),
  (N'ClubMembership',4,N'JoinDate',N'date',3,0,0,0),
  (N'ClubMembership',5,N'EndDate',N'date',3,0,0,1),
  (N'ResearchParticipation',1,N'StudentID',N'int',4,0,0,0),
  (N'ResearchParticipation',2,N'ResearchProjectID',N'int',4,0,0,0),
  (N'ResearchCollaboration',1,N'StudentID',N'int',4,0,0,0),
  (N'ResearchCollaboration',2,N'ProfessorID',N'int',4,0,0,0),
  (N'ResearchCollaboration',3,N'ResearchProjectID',N'int',4,0,0,0),
  (N'ResearchCollaboration',4,N'CollaborationDepartmentID',N'int',4,0,0,0);

DECLARE @TableCounts TABLE(Ordinal INT PRIMARY KEY, TableName SYSNAME, ActualRows BIGINT NULL);
DECLARE @Checks TABLE
(
 CheckID INT IDENTITY(1,1) PRIMARY KEY,
 Category NVARCHAR(40),
 CheckName NVARCHAR(220),
 Result VARCHAR(6),
 ActualValue NVARCHAR(100),
 ExpectedValue NVARCHAR(100),
 Notes NVARCHAR(500)
);
DECLARE @Issues TABLE
(
 IssueType NVARCHAR(80), EntityKey NVARCHAR(150), Details NVARCHAR(400)
);
DECLARE @i INT,@t SYSNAME,@want BIGINT,@cnt BIGINT,@sql NVARCHAR(MAX),@pk NVARCHAR(300);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
 SELECT Ordinal,TableName,ExpectedRows,PKColumns FROM @ExpectedTables ORDER BY Ordinal;
OPEN c;
FETCH NEXT FROM c INTO @i,@t,@want,@pk;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @cnt=NULL;
 IF OBJECT_ID(N'dbo.'+@t,N'U') IS NOT NULL
 BEGIN
  SET @sql=N'SELECT @countOut=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@t)+N';';
  EXEC sys.sp_executesql @sql,N'@countOut BIGINT OUTPUT',@countOut=@cnt OUTPUT;
 END;
 INSERT INTO @TableCounts VALUES(@i,@t,@cnt);
 INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 VALUES (N'ROW COUNT',N'['+RIGHT(N'00'+CONVERT(NVARCHAR(2),@i),2)+N'] '+@t,
   CASE WHEN @cnt=@want THEN 'PASS' ELSE 'FAIL' END,
   COALESCE(CONVERT(NVARCHAR(100),@cnt),N'MISSING TABLE'),CONVERT(NVARCHAR(100),@want),
   N'Exact Phase-4 synthetic seed baseline');
 FETCH NEXT FROM c INTO @i,@t,@want,@pk;
END;
CLOSE c;
DEALLOCATE c;

-- Prevent subsequent SELECT statements from referencing missing user tables.
IF EXISTS(SELECT 1 FROM @TableCounts WHERE ActualRows IS NULL)
BEGIN
 SELECT N'STOP: Missing approved tables' AS AuditStatus;
 SELECT * FROM @TableCounts ORDER BY Ordinal;
 SELECT * FROM @Checks ORDER BY CheckID;
 THROW 52001, 'Missing table(s); complete the approved DDL before full integrity audit.',1;
END;

-- Compare each approved column signature in both directions (including exact order).
;WITH ActualColumns AS
(
 SELECT t.name TableName,c.column_id ColumnOrdinal,c.name ColumnName,
        ty.name TypeName,c.max_length LengthBytes,c.is_nullable IsNullable,
        CASE WHEN ty.name=N'decimal' THEN c.precision ELSE 0 END NumericPrecision,
        CASE WHEN ty.name=N'decimal' THEN c.scale ELSE 0 END NumericScale
 FROM sys.tables t
 JOIN sys.schemas s ON s.schema_id=t.schema_id AND s.name=N'dbo'
 JOIN sys.columns c ON c.object_id=t.object_id
 JOIN sys.types ty ON ty.user_type_id=c.user_type_id
 JOIN @ExpectedTables x ON x.TableName=t.name
)
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'SCHEMA',N'Column signature: '+e.TableName,
 CASE WHEN EXISTS
 (
 SELECT ColumnOrdinal,ColumnName,TypeName,LengthBytes,NumericPrecision,NumericScale,IsNullable
 FROM @ExpectedColumns ec WHERE ec.TableName=e.TableName
 EXCEPT
 SELECT ColumnOrdinal,ColumnName,TypeName,LengthBytes,NumericPrecision,NumericScale,IsNullable
 FROM ActualColumns ac WHERE ac.TableName=e.TableName
 ) OR EXISTS
 (
 SELECT ColumnOrdinal,ColumnName,TypeName,LengthBytes,NumericPrecision,NumericScale,IsNullable
 FROM ActualColumns ac WHERE ac.TableName=e.TableName
 EXCEPT
 SELECT ColumnOrdinal,ColumnName,TypeName,LengthBytes,NumericPrecision,NumericScale,IsNullable
 FROM @ExpectedColumns ec WHERE ec.TableName=e.TableName
 ) THEN 'FAIL' ELSE 'PASS' END,
 CONVERT(NVARCHAR(100),(SELECT COUNT(*) FROM ActualColumns a WHERE a.TableName=e.TableName)),
 CONVERT(NVARCHAR(100),(SELECT COUNT(*) FROM @ExpectedColumns c WHERE c.TableName=e.TableName)),
 N'Type, max bytes, NULL allowance, decimal precision/scale and position'
FROM @ExpectedTables e;

-- Ordered PRIMARY KEY column strings for all 21 tables.
;WITH ActualPK AS
(
 SELECT t.name TableName,STRING_AGG(CONVERT(NVARCHAR(MAX),c.name),N',')
           WITHIN GROUP (ORDER BY ic.key_ordinal) PKColumns
 FROM sys.tables t
 JOIN sys.schemas s ON s.schema_id=t.schema_id AND s.name=N'dbo'
 JOIN sys.key_constraints k ON k.parent_object_id=t.object_id AND k.type='PK'
 JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=k.unique_index_id AND ic.key_ordinal>0
 JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
 JOIN @ExpectedTables e ON e.TableName=t.name
 GROUP BY t.name
)
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'PRIMARY KEY',N'Ordered PK: '+e.TableName,
 CASE WHEN ap.PKColumns=e.PKColumns THEN 'PASS' ELSE 'FAIL' END,
 COALESCE(CONVERT(NVARCHAR(100),ap.PKColumns),N'MISSING'),e.PKColumns,
 N'Approved key order; composite keys checked explicitly'
FROM @ExpectedTables e LEFT JOIN ActualPK ap ON ap.TableName=e.TableName;

-- Global metadata baselines from Phase-4 approved structural audit.
DECLARE @Global TABLE(Metric NVARCHAR(60),Expected BIGINT,Actual BIGINT);
INSERT INTO @Global VALUES
 (N'Tables',21,(SELECT COUNT_BIG(*) FROM sys.tables t JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo'))),
 (N'Columns',64,(SELECT COUNT_BIG(*) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo'))),
 (N'Primary keys',21,(SELECT COUNT_BIG(*) FROM sys.key_constraints k JOIN sys.tables t ON t.object_id=k.parent_object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo') AND k.type='PK')),
 (N'Foreign key objects',30,(SELECT COUNT_BIG(*) FROM sys.foreign_keys f JOIN sys.tables t ON t.object_id=f.parent_object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo'))),
 (N'UNIQUE constraints',5,(SELECT COUNT_BIG(*) FROM sys.key_constraints k JOIN sys.tables t ON t.object_id=k.parent_object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo') AND k.type='UQ')),
 (N'CHECK constraints',4,(SELECT COUNT_BIG(*) FROM sys.check_constraints k JOIN sys.tables t ON t.object_id=k.parent_object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo'))),
 (N'Filtered UNIQUE indexes',2,(SELECT COUNT_BIG(*) FROM sys.indexes ix JOIN sys.tables t ON t.object_id=ix.object_id JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo') AND ix.is_unique=1 AND ix.has_filter=1 AND ix.is_hypothetical=0));
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'METADATA',Metric,CASE WHEN Actual=Expected THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),Actual),CONVERT(NVARCHAR(100),Expected),N'Approved Phase-4 structural baseline'
FROM @Global;

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'CONSTRAINT HEALTH',N'Enabled + trusted FK (zero disabled/untrusted)',
 CASE WHEN SUM(CASE WHEN f.is_disabled=1 OR f.is_not_trusted=1 THEN 1 ELSE 0 END)=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),SUM(CASE WHEN f.is_disabled=1 OR f.is_not_trusted=1 THEN 1 ELSE 0 END)),N'0',N'FKs must all be enabled and trusted'
FROM sys.foreign_keys f JOIN sys.tables t ON t.object_id=f.parent_object_id
JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo');
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'CONSTRAINT HEALTH',N'Enabled + trusted CHECK (zero disabled/untrusted)',
 CASE WHEN SUM(CASE WHEN f.is_disabled=1 OR f.is_not_trusted=1 THEN 1 ELSE 0 END)=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),SUM(CASE WHEN f.is_disabled=1 OR f.is_not_trusted=1 THEN 1 ELSE 0 END)),N'0',N'CHECK constraints must all be enabled and trusted'
FROM sys.check_constraints f JOIN sys.tables t ON t.object_id=f.parent_object_id
JOIN @ExpectedTables e ON e.TableName=t.name WHERE t.schema_id=SCHEMA_ID(N'dbo');

DECLARE @ExpectedFK TABLE(ParentTable SYSNAME,ReferencedTable SYSNAME,ColumnMapping NVARCHAR(300));
INSERT INTO @ExpectedFK VALUES
 (N'Professor',N'Department',N'DepartmentID=DepartmentID'),
 (N'Professor',N'Professor',N'AdvisorProfessorID=ProfessorID,DepartmentID=DepartmentID'),
 (N'GraduationProject',N'Department',N'DepartmentID=DepartmentID'),
 (N'ResearchProject',N'Department',N'LeadDepartmentID=DepartmentID'),
 (N'Book',N'Library',N'LibraryID=LibraryID'),
 (N'DepartmentHead',N'Department',N'DepartmentID=DepartmentID'),
 (N'DepartmentHead',N'Professor',N'ProfessorID=ProfessorID,DepartmentID=DepartmentID'),
 (N'Student',N'GraduationProject',N'GraduationProjectID=GraduationProjectID'),
 (N'CourseResponsibility',N'Course',N'CourseID=CourseID'),
 (N'CourseResponsibility',N'Professor',N'ProfessorID=ProfessorID'),
 (N'GraduationProjectSupervision',N'GraduationProject',N'GraduationProjectID=GraduationProjectID'),
 (N'GraduationProjectSupervision',N'Professor',N'ProfessorID=ProfessorID'),
 (N'ResearchProjectSupervision',N'ResearchProject',N'ResearchProjectID=ResearchProjectID'),
 (N'ResearchProjectSupervision',N'Professor',N'ProfessorID=ProfessorID'),
 (N'StudentPhone',N'Student',N'StudentID=StudentID'),
 (N'UniversityIDCard',N'Student',N'StudentID=StudentID'),
 (N'Enrollment',N'Student',N'StudentID=StudentID'),
 (N'Enrollment',N'Course',N'CourseID=CourseID'),
 (N'Enrollment',N'Semester',N'SemesterID=SemesterID'),
 (N'Borrowing',N'Student',N'StudentID=StudentID'),
 (N'Borrowing',N'Book',N'BookID=BookID'),
 (N'ClubMembership',N'Student',N'StudentID=StudentID'),
 (N'ClubMembership',N'StudentClub',N'ClubID=ClubID'),
 (N'ResearchParticipation',N'Student',N'StudentID=StudentID'),
 (N'ResearchParticipation',N'ResearchProject',N'ResearchProjectID=ResearchProjectID'),
 (N'ResearchCollaboration',N'Student',N'StudentID=StudentID'),
 (N'ResearchCollaboration',N'Professor',N'ProfessorID=ProfessorID'),
 (N'ResearchCollaboration',N'ResearchProject',N'ResearchProjectID=ResearchProjectID'),
 (N'ResearchCollaboration',N'Department',N'CollaborationDepartmentID=DepartmentID'),
 (N'ResearchCollaboration',N'ResearchParticipation',N'StudentID=StudentID,ResearchProjectID=ResearchProjectID');

-- Actual FK structure, INCLUDING ordered components of composite FKs.
DECLARE @ActualFK TABLE(ParentTable SYSNAME,ReferencedTable SYSNAME,ColumnMapping NVARCHAR(300));
INSERT INTO @ActualFK(ParentTable,ReferencedTable,ColumnMapping)
SELECT pt.name,rt.name,
 STRING_AGG(CONVERT(NVARCHAR(MAX),pc.name+N'='+rc.name),N',')
   WITHIN GROUP(ORDER BY fkc.constraint_column_id)
FROM sys.foreign_keys fk
JOIN sys.tables pt ON pt.object_id=fk.parent_object_id
JOIN sys.tables rt ON rt.object_id=fk.referenced_object_id
JOIN @ExpectedTables et ON et.TableName=pt.name
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE pt.schema_id=SCHEMA_ID(N'dbo')
GROUP BY fk.object_id,pt.name,rt.name;
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'FK STRUCTURE',N'Approved 30 FK mappings (both directions)',
 CASE WHEN EXISTS(SELECT * FROM @ExpectedFK EXCEPT SELECT * FROM @ActualFK)
        OR EXISTS(SELECT * FROM @ActualFK EXCEPT SELECT * FROM @ExpectedFK) THEN 'FAIL' ELSE 'PASS' END,
 CONVERT(NVARCHAR(100),(SELECT COUNT(*) FROM @ActualFK)),N'30',
 N'FK parent, referenced table, and ordered mapping for each component';
-- Report the names/mappings of any missing or additional FK definitions.
INSERT INTO @Issues
SELECT N'Missing FK mapping',ParentTable+N' -> '+ReferencedTable,ColumnMapping
FROM (SELECT * FROM @ExpectedFK EXCEPT SELECT * FROM @ActualFK) x;
INSERT INTO @Issues
SELECT N'Unexpected FK mapping',ParentTable+N' -> '+ReferencedTable,ColumnMapping
FROM (SELECT * FROM @ActualFK EXCEPT SELECT * FROM @ExpectedFK) x;

DECLARE @ExpectedUQ TABLE(TableName SYSNAME,OrderedColumns NVARCHAR(200));
INSERT INTO @ExpectedUQ VALUES
 (N'Professor',N'ProfessorID,DepartmentID'),
 (N'DepartmentHead',N'ProfessorID'),
 (N'Semester',N'AcademicYear,TermName'),
 (N'UniversityIDCard',N'StudentID'),
 (N'ClubMembership',N'StudentID,ClubID,JoinDate');

DECLARE @ActualUQ TABLE(TableName SYSNAME,OrderedColumns NVARCHAR(200));
INSERT INTO @ActualUQ(TableName,OrderedColumns)
SELECT t.name,STRING_AGG(CONVERT(NVARCHAR(MAX),c.name),N',') WITHIN GROUP(ORDER BY ic.key_ordinal)
FROM sys.key_constraints k
JOIN sys.tables t ON t.object_id=k.parent_object_id
JOIN @ExpectedTables e ON e.TableName=t.name
JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=k.unique_index_id AND ic.key_ordinal>0
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE k.type='UQ' AND t.schema_id=SCHEMA_ID(N'dbo') GROUP BY k.object_id,t.name;
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'UNIQUE STRUCTURE',N'Approved five UNIQUE constraint column sets',
 CASE WHEN EXISTS(SELECT * FROM @ExpectedUQ EXCEPT SELECT * FROM @ActualUQ)
        OR EXISTS(SELECT * FROM @ActualUQ EXCEPT SELECT * FROM @ExpectedUQ) THEN 'FAIL' ELSE 'PASS' END,
 CONVERT(NVARCHAR(100),(SELECT COUNT(*) FROM @ActualUQ)),N'5',N'Ordered UQ key columns (not title/email/phone assumptions)';
INSERT INTO @Issues
SELECT N'Missing UNIQUE key',TableName,OrderedColumns FROM
 (SELECT * FROM @ExpectedUQ EXCEPT SELECT * FROM @ActualUQ) x;
INSERT INTO @Issues
SELECT N'Unexpected UNIQUE key',TableName,OrderedColumns FROM
 (SELECT * FROM @ActualUQ EXCEPT SELECT * FROM @ExpectedUQ) x;

DECLARE @ExpectedCheck TABLE(TableName SYSNAME,ConstraintName SYSNAME);
INSERT INTO @ExpectedCheck VALUES
 (N'Professor',N'CK_Professor_NoSelfAdvice'),
 (N'Borrowing',N'CK_Borrowing_DueDate'),
 (N'Borrowing',N'CK_Borrowing_ReturnDate'),
 (N'ClubMembership',N'CK_ClubMembership_EndDate');
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'CHECK STRUCTURE',N'Four approved CHECK constraint names/tables',
CASE WHEN EXISTS (
 SELECT TableName,ConstraintName FROM @ExpectedCheck
 EXCEPT
 SELECT t.name,c.name FROM sys.check_constraints c
 JOIN sys.tables t ON t.object_id=c.parent_object_id
 JOIN @ExpectedTables et ON et.TableName=t.name
) OR EXISTS (
 SELECT t.name,c.name FROM sys.check_constraints c
 JOIN sys.tables t ON t.object_id=c.parent_object_id
 JOIN @ExpectedTables et ON et.TableName=t.name
 EXCEPT SELECT TableName,ConstraintName FROM @ExpectedCheck
) THEN 'FAIL' ELSE 'PASS' END,
CONVERT(NVARCHAR(100),(SELECT COUNT(*) FROM sys.check_constraints c JOIN sys.tables t ON t.object_id=c.parent_object_id JOIN @ExpectedTables e ON e.TableName=t.name)),
N'4',N'Actual CHECK values also tested in the business section';

-- No additional unique indexes may silently prohibit valid scenario data.
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'INDEX POLICY',N'No unapproved standalone unique indexes',
CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
CONVERT(NVARCHAR(100),x.n),N'0',N'Only PK, UQ, and the two approved filtered UNIQUE indexes'
FROM (
 SELECT COUNT_BIG(*) AS n FROM sys.indexes i
 JOIN sys.tables t ON t.object_id=i.object_id
 JOIN @ExpectedTables et ON et.TableName=t.name
 WHERE i.is_unique=1 AND i.is_primary_key=0 AND i.is_unique_constraint=0
 AND NOT (t.name=N'Borrowing' AND i.name=N'UX_Borrowing_OneOpenLoanPerBook')
 AND NOT (t.name=N'ClubMembership' AND i.has_filter=1 AND i.filter_definition LIKE N'%EndDate%IS NULL%')
) x;

-- Validate the ACTUAL SQL Server FK mappings, including composites, against actual data.
-- SQL Server MATCH SIMPLE semantics: rows with NULL FK component(s) are exempt.
DECLARE @fkid INT,@fkname SYSNAME,@parent SYSNAME,@referenced SYSNAME,
        @predicate NVARCHAR(MAX),@nonNull NVARCHAR(MAX),@bad BIGINT;
DECLARE fkcur CURSOR LOCAL FAST_FORWARD FOR
 SELECT fk.object_id,fk.name,pt.name,rt.name
 FROM sys.foreign_keys fk
 JOIN sys.tables pt ON pt.object_id=fk.parent_object_id
 JOIN sys.tables rt ON rt.object_id=fk.referenced_object_id
 JOIN @ExpectedTables et ON et.TableName=pt.name
 WHERE pt.schema_id=SCHEMA_ID(N'dbo')
 ORDER BY pt.name,fk.name;
OPEN fkcur;
FETCH NEXT FROM fkcur INTO @fkid,@fkname,@parent,@referenced;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @predicate=STRING_AGG(CONVERT(NVARCHAR(MAX),N'r.'+QUOTENAME(rc.name)+N'=p.'+QUOTENAME(pc.name)),N' AND ')
         WITHIN GROUP (ORDER BY fkc.constraint_column_id),
        @nonNull=STRING_AGG(CONVERT(NVARCHAR(MAX),N'p.'+QUOTENAME(pc.name)+N' IS NOT NULL'),N' AND ')
         WITHIN GROUP (ORDER BY fkc.constraint_column_id)
 FROM sys.foreign_key_columns fkc
 JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
 JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
 WHERE fkc.constraint_object_id=@fkid;
 SET @bad=NULL;
 SET @sql=N'SELECT @out=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@parent)+N' p WHERE '+@nonNull+
  N' AND NOT EXISTS(SELECT 1 FROM dbo.'+QUOTENAME(@referenced)+N' r WHERE '+@predicate+N');';
 EXEC sys.sp_executesql @sql,N'@out BIGINT OUTPUT',@out=@bad OUTPUT;
 INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 VALUES(N'FK DATA',N'FK '+@fkname,
 CASE WHEN @bad=0 THEN 'PASS' ELSE 'FAIL' END,CONVERT(NVARCHAR(100),@bad),N'0',
 N'Child '+@parent+N' -> parent '+@referenced+N'; all mapped columns checked');
 FETCH NEXT FROM fkcur INTO @fkid,@fkname,@parent,@referenced;
END;
CLOSE fkcur;
DEALLOCATE fkcur;

-- Confirm the two approved filtered uniqueness policies.
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'INDEX POLICY',N'Borrowing: one open loan per Book',
 CASE WHEN EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=OBJECT_ID(N'dbo.Borrowing')
 AND i.name=N'UX_Borrowing_OneOpenLoanPerBook' AND i.is_unique=1 AND i.has_filter=1
 AND i.is_disabled=0 AND REPLACE(REPLACE(i.filter_definition,N'[',N''),N']',N'') LIKE N'%ReturnDate%IS NULL%')
 THEN 'PASS' ELSE 'FAIL' END,
 N'Metadata inspection',N'Enabled filtered UNIQUE',N'Unique filter must target ReturnDate IS NULL';
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'INDEX POLICY',N'ClubMembership: max one active membership per student/club',
 CASE WHEN EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=OBJECT_ID(N'dbo.ClubMembership')
 AND i.is_unique=1 AND i.has_filter=1 AND i.is_disabled=0
 AND REPLACE(REPLACE(i.filter_definition,N'[',N''),N']',N'') LIKE N'%EndDate%IS NULL%')
 THEN 'PASS' ELSE 'FAIL' END,
 N'Metadata inspection',N'Enabled filtered UNIQUE',N'Unique filter must target EndDate IS NULL';

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Department heads coverage',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Every department has a head'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Department d WHERE NOT EXISTS (SELECT 1 FROM dbo.DepartmentHead h WHERE h.DepartmentID=d.DepartmentID)) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Department head same-department',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Head must work in headed department'
 FROM (SELECT COUNT_BIG(*) FROM dbo.DepartmentHead h LEFT JOIN dbo.Professor p ON p.ProfessorID=h.ProfessorID AND p.DepartmentID=h.DepartmentID WHERE p.ProfessorID IS NULL) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Professor advisor same-department',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Advisors stay within their professor department'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Professor p LEFT JOIN dbo.Professor a ON a.ProfessorID=p.AdvisorProfessorID AND a.DepartmentID=p.DepartmentID WHERE p.AdvisorProfessorID IS NOT NULL AND a.ProfessorID IS NULL) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Professor cannot advise self',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Self-advising disallowed'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Professor WHERE AdvisorProfessorID=ProfessorID) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Course minimum responsibility',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'At least one responsible professor per course'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Course c WHERE NOT EXISTS(SELECT 1 FROM dbo.CourseResponsibility r WHERE r.CourseID=c.CourseID)) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'GraduationProject minimum student',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'At least one student per graduation project'
 FROM (SELECT COUNT_BIG(*) FROM dbo.GraduationProject p WHERE NOT EXISTS(SELECT 1 FROM dbo.Student s WHERE s.GraduationProjectID=p.GraduationProjectID)) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'GraduationProject minimum supervisor',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'At least one supervisor per graduation project'
 FROM (SELECT COUNT_BIG(*) FROM dbo.GraduationProject p WHERE NOT EXISTS(SELECT 1 FROM dbo.GraduationProjectSupervision s WHERE s.GraduationProjectID=p.GraduationProjectID)) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'ResearchProject minimum supervisor',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'At least one formal supervisor per research project'
 FROM (SELECT COUNT_BIG(*) FROM dbo.ResearchProject p WHERE NOT EXISTS(SELECT 1 FROM dbo.ResearchProjectSupervision s WHERE s.ResearchProjectID=p.ResearchProjectID)) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Borrowing valid due-date',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Check dates as approved'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Borrowing WHERE DueDate < BorrowDate) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Borrowing valid return-date',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Check dates as approved'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Borrowing WHERE ReturnDate IS NOT NULL AND ReturnDate < BorrowDate) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Borrowing one currently unreturned loan per physical book',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Physical BookID identifies individual copies'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT BookID FROM dbo.Borrowing WHERE ReturnDate IS NULL GROUP BY BookID HAVING COUNT_BIG(*)>1) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'ClubMembership valid EndDate',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Check dates as approved'
 FROM (SELECT COUNT_BIG(*) FROM dbo.ClubMembership WHERE EndDate IS NOT NULL AND EndDate < JoinDate) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'ClubMembership one active term per student/club',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Current membership EndDate IS NULL'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT StudentID,ClubID FROM dbo.ClubMembership WHERE EndDate IS NULL GROUP BY StudentID,ClubID HAVING COUNT_BIG(*)>1) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'ClubMembership no overlapping date ranges',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Closed inclusive date ranges; no historical overlap'
 FROM (SELECT COUNT_BIG(*) FROM dbo.ClubMembership a JOIN dbo.ClubMembership b ON a.StudentID=b.StudentID AND a.ClubID=b.ClubID AND a.ClubMembershipID < b.ClubMembershipID AND a.JoinDate <= ISNULL(b.EndDate,CONVERT(DATE,'99991231',112)) AND b.JoinDate <= ISNULL(a.EndDate,CONVERT(DATE,'99991231',112))) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'ResearchCollaboration requires student research participation',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Composite FK StudentID + ResearchProjectID'
 FROM (SELECT COUNT_BIG(*) FROM dbo.ResearchCollaboration c LEFT JOIN dbo.ResearchParticipation p ON p.StudentID=c.StudentID AND p.ResearchProjectID=c.ResearchProjectID WHERE p.StudentID IS NULL) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Collaboration quadruple duplicate',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Four-field association uniqueness'
 FROM (SELECT COUNT_BIG(*) FROM(SELECT StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID FROM dbo.ResearchCollaboration GROUP BY StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID HAVING COUNT_BIG(*)>1) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'BUSINESS',N'Book references designated central library',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Approved seed uses Central Library ID 1'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Book WHERE LibraryID<>1) x(n);

-- 1:1 UniversityIDCard business coverage is a lifecycle-sensitive minimum.
-- The schema enforces AT MOST ONE card, not mandatory issuance.
DECLARE @WithoutCard BIGINT=(SELECT COUNT_BIG(*) FROM dbo.Student s WHERE NOT EXISTS
 (SELECT 1 FROM dbo.UniversityIDCard c WHERE c.StudentID=s.StudentID));
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
VALUES (N'LIFECYCLE / DECISION',N'Every registered Student has UniversityIDCard',
 CASE WHEN @WithoutCard=0 THEN 'PASS' ELSE 'REVIEW' END,
 CONVERT(NVARCHAR(100),@WithoutCard),N'0 if issuance mandatory',
 N'16 missing on known seed. Rule says 1:1 after completed registration; no approved lifecycle attribute to decide eligibility. Needs owner decision.');
INSERT INTO @Issues
SELECT N'Student without UniversityIDCard',CONVERT(NVARCHAR(150),s.StudentID),s.[Name]
FROM dbo.Student s WHERE NOT EXISTS(SELECT 1 FROM dbo.UniversityIDCard c WHERE c.StudentID=s.StudentID);
-- D-18: Do not assert every research participation has a collaboration now.
INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
SELECT N'LIFECYCLE / DECISION',N'D-18 collaboration minimum timing', 'REVIEW',
 CONVERT(NVARCHAR(100),(SELECT COUNT_BIG(*) FROM dbo.ResearchParticipation rp WHERE NOT EXISTS
 (SELECT 1 FROM dbo.ResearchCollaboration rc WHERE rc.StudentID=rp.StudentID AND rc.ResearchProjectID=rp.ResearchProjectID))),
 N'UNSPECIFIED',N'D-18 remains OPEN: these pairs are not automatically invalid';

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'Professor per department exactly 4',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT d.DepartmentID FROM dbo.Department d LEFT JOIN dbo.Professor p ON p.DepartmentID=d.DepartmentID GROUP BY d.DepartmentID HAVING COUNT_BIG(p.ProfessorID)<>4) x) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'Student GraduationProject assignments 32',CASE WHEN x.n=32 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'32',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM dbo.Student WHERE GraduationProjectID IS NOT NULL) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'GraduationProject exactly 2 students each',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT gp.GraduationProjectID FROM dbo.GraduationProject gp LEFT JOIN dbo.Student s ON s.GraduationProjectID=gp.GraduationProjectID GROUP BY gp.GraduationProjectID HAVING COUNT_BIG(s.StudentID)<>2) x) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'16 projects each have 5 research participants',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT rp.ResearchProjectID FROM dbo.ResearchProject rp LEFT JOIN dbo.ResearchParticipation x ON x.ResearchProjectID=rp.ResearchProjectID GROUP BY rp.ResearchProjectID HAVING COUNT_BIG(x.StudentID)<>5) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'16 projects each have 5 research collaborations',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT rp.ResearchProjectID FROM dbo.ResearchProject rp LEFT JOIN dbo.ResearchCollaboration x ON x.ResearchProjectID=rp.ResearchProjectID GROUP BY rp.ResearchProjectID HAVING COUNT_BIG(x.StudentID)<>5) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'8 departments each have 10 collaboration rows',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT d.DepartmentID FROM dbo.Department d LEFT JOIN dbo.ResearchCollaboration rc ON rc.CollaborationDepartmentID=d.DepartmentID GROUP BY d.DepartmentID HAVING COUNT_BIG(rc.StudentID)<>10) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'Each student has 3 demo enrollments',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT s.StudentID FROM dbo.Student s LEFT JOIN dbo.Enrollment e ON e.StudentID=s.StudentID GROUP BY s.StudentID HAVING COUNT_BIG(e.CourseID)<>3) q) x(n);

INSERT INTO @Checks(Category,CheckName,Result,ActualValue,ExpectedValue,Notes)
 SELECT N'SEED PROFILE',N'8 clubs each have 11 membership records',CASE WHEN x.n=0 THEN 'PASS' ELSE 'FAIL' END,
 CONVERT(NVARCHAR(100),x.n),N'0',N'Exact Phase-4 demonstration baseline (not future business limit)'
 FROM (SELECT COUNT_BIG(*) FROM (SELECT c.ClubID FROM dbo.StudentClub c LEFT JOIN dbo.ClubMembership m ON m.ClubID=c.ClubID GROUP BY c.ClubID HAVING COUNT_BIG(m.ClubMembershipID)<>11) q) x(n);

-- Optional diagnostics: eligible borrowing and enrollment descriptive insights.
-- No grade/status rules are added; the approved DDL has no permitted-values CHECK.
INSERT INTO @Issues
SELECT N'Completed enrollment without grade',
 CONVERT(NVARCHAR(150),e.StudentID)+N'/'+CONVERT(NVARCHAR(20),e.CourseID)+N'/'+CONVERT(NVARCHAR(20),e.SemesterID),
 N'EnrollmentStatus=Completed; Grade NULL (review business expectation only)'
FROM dbo.Enrollment e WHERE e.EnrollmentStatus=N'Completed' AND e.Grade IS NULL;

-- OUTPUT #1: overall audit gate. REVIEW is intentionally not counted as PASS.
SELECT N'Phase4 Final Database Integrity Audit' AS AuditName,
 DB_NAME() AS DatabaseName, @AsOfDate AS AsOfDate,
 (SELECT COUNT(*) FROM @ExpectedTables) AS TablesExpected,
 (SELECT SUM(ActualRows) FROM @TableCounts) AS ActualTotalRows,
 (SELECT SUM(ExpectedRows) FROM @ExpectedTables) AS ExpectedTotalRows,
 (SELECT COUNT(*) FROM @Checks) AS ChecksEvaluated,
 (SELECT COUNT(*) FROM @Checks WHERE Result='PASS') AS PassedChecks,
 (SELECT COUNT(*) FROM @Checks WHERE Result='FAIL') AS FailedChecks,
 (SELECT COUNT(*) FROM @Checks WHERE Result='REVIEW') AS ReviewItems,
 CASE WHEN EXISTS(SELECT 1 FROM @Checks WHERE Result='FAIL') THEN 'FAIL'
      WHEN EXISTS(SELECT 1 FROM @Checks WHERE Result='REVIEW') THEN 'REVIEW'
      ELSE 'PASS' END AS OverallAuditStatus;

-- OUTPUT #2: all table counts in approved population order.
SELECT t.Ordinal,t.TableName,t.ExpectedRows,a.ActualRows,
 a.ActualRows-t.ExpectedRows AS Variance,
 CASE WHEN a.ActualRows=t.ExpectedRows THEN 'PASS' ELSE 'FAIL' END AS Result
FROM @ExpectedTables t JOIN @TableCounts a ON a.Ordinal=t.Ordinal ORDER BY t.Ordinal;

-- OUTPUT #3: grouped audit results.
SELECT Category,
 COUNT(*) AS ChecksEvaluated,
 SUM(CASE WHEN Result='PASS' THEN 1 ELSE 0 END) AS PassedChecks,
 SUM(CASE WHEN Result='FAIL' THEN 1 ELSE 0 END) AS FailedChecks,
 SUM(CASE WHEN Result='REVIEW' THEN 1 ELSE 0 END) AS ReviewItems
FROM @Checks GROUP BY Category ORDER BY Category;

-- OUTPUT #4: failed and review findings, followed by full audit trail.
SELECT CheckID,Category,CheckName,Result,ActualValue,ExpectedValue,Notes
FROM @Checks WHERE Result<>'PASS' ORDER BY CASE Result WHEN 'FAIL' THEN 0 ELSE 1 END,CheckID;
SELECT CheckID,Category,CheckName,Result,ActualValue,ExpectedValue,Notes
FROM @Checks ORDER BY CheckID;

-- OUTPUT #5: actionable exceptions (students without cards, optional grade review).
SELECT IssueType,EntityKey,Details FROM @Issues ORDER BY IssueType,EntityKey;

-- OUTPUT #6: live status diagnostics (no status tables are modified).
SELECT CASE WHEN ReturnDate IS NOT NULL THEN N'Returned'
            WHEN DueDate<@AsOfDate THEN N'Open overdue'
            ELSE N'Open not overdue' END AS LoanStatus,
 COUNT_BIG(*) AS LoanCount
FROM dbo.Borrowing
GROUP BY CASE WHEN ReturnDate IS NOT NULL THEN N'Returned'
            WHEN DueDate<@AsOfDate THEN N'Open overdue'
            ELSE N'Open not overdue' END;
SELECT EnrollmentStatus,COUNT_BIG(*) AS EnrollmentCount,
 SUM(CASE WHEN Grade IS NULL THEN 1 ELSE 0 END) AS NullGrades
FROM dbo.Enrollment GROUP BY EnrollmentStatus ORDER BY EnrollmentStatus;
SELECT COUNT_BIG(*) AS ParticipationWithoutCollaboration
FROM dbo.ResearchParticipation rp WHERE NOT EXISTS
 (SELECT 1 FROM dbo.ResearchCollaboration rc
  WHERE rc.StudentID=rp.StudentID AND rc.ResearchProjectID=rp.ResearchProjectID);

PRINT 'AUDIT FINISHED: no approved user tables modified. Review OverallAuditStatus, then all findings.';
GO
-----------------------------------
GO
