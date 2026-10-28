-- Extracted from UniversityManagementDB(2).sql; source lines 2169-2514.
USE [UniversityManagementDB];
GO
---05_Final_Database_Schema_Audit
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('tempdb..#ExpectedTable') IS NOT NULL DROP TABLE #ExpectedTable;
IF OBJECT_ID('tempdb..#ExpectedColumn') IS NOT NULL DROP TABLE #ExpectedColumn;
IF OBJECT_ID('tempdb..#ExpectedPK') IS NOT NULL DROP TABLE #ExpectedPK;
IF OBJECT_ID('tempdb..#ExpectedFK') IS NOT NULL DROP TABLE #ExpectedFK;
IF OBJECT_ID('tempdb..#Checks') IS NOT NULL DROP TABLE #Checks;

CREATE TABLE #ExpectedTable(TableName sysname NOT NULL PRIMARY KEY);
CREATE TABLE #ExpectedColumn(
    TableName sysname NOT NULL,
    ColumnName sysname NOT NULL,
    ColumnOrder int NOT NULL,
    TypeName sysname NOT NULL,
    NvarcharLength int NULL,
    NumericPrecision int NULL,
    NumericScale int NULL,
    IsNullable bit NOT NULL,
    PRIMARY KEY (TableName, ColumnName)
);
CREATE TABLE #ExpectedPK(TableName sysname NOT NULL PRIMARY KEY, KeyColumns nvarchar(max) NOT NULL);
CREATE TABLE #ExpectedFK(
    ParentTable sysname NOT NULL,
    ParentColumns nvarchar(max) NOT NULL,
    ReferencedTable sysname NOT NULL,
    ReferencedColumns nvarchar(max) NOT NULL
);
CREATE TABLE #Checks(
    Area varchar(40) NOT NULL,
    ObjectName nvarchar(300) NOT NULL,
    Expected nvarchar(max) NULL,
    Actual nvarchar(max) NULL,
    Result varchar(6) NOT NULL
);

INSERT INTO #ExpectedTable(TableName) VALUES
(N'Department'),
(N'Course'),
(N'Semester'),
(N'Library'),
(N'StudentClub'),
(N'Professor'),
(N'GraduationProject'),
(N'ResearchProject'),
(N'Book'),
(N'DepartmentHead'),
(N'Student'),
(N'CourseResponsibility'),
(N'GraduationProjectSupervision'),
(N'ResearchProjectSupervision'),
(N'StudentPhone'),
(N'UniversityIDCard'),
(N'Enrollment'),
(N'Borrowing'),
(N'ClubMembership'),
(N'ResearchParticipation'),
(N'ResearchCollaboration');

INSERT INTO #ExpectedColumn(TableName,ColumnName,ColumnOrder,TypeName,NvarcharLength,NumericPrecision,NumericScale,IsNullable) VALUES
(N'Department',N'DepartmentID',1,N'int',NULL,NULL,NULL,0),
(N'Department',N'DepartmentName',2,N'nvarchar',150,NULL,NULL,0),
(N'Course',N'CourseID',1,N'int',NULL,NULL,NULL,0),
(N'Course',N'CourseTitle',2,N'nvarchar',200,NULL,NULL,0),
(N'Semester',N'SemesterID',1,N'int',NULL,NULL,NULL,0),
(N'Semester',N'AcademicYear',2,N'nvarchar',9,NULL,NULL,0),
(N'Semester',N'TermName',3,N'nvarchar',50,NULL,NULL,0),
(N'Library',N'LibraryID',1,N'int',NULL,NULL,NULL,0),
(N'Library',N'LibraryName',2,N'nvarchar',150,NULL,NULL,0),
(N'StudentClub',N'ClubID',1,N'int',NULL,NULL,NULL,0),
(N'StudentClub',N'ClubName',2,N'nvarchar',150,NULL,NULL,0),
(N'Professor',N'ProfessorID',1,N'int',NULL,NULL,NULL,0),
(N'Professor',N'Name',2,N'nvarchar',150,NULL,NULL,0),
(N'Professor',N'DepartmentID',3,N'int',NULL,NULL,NULL,0),
(N'Professor',N'AdvisorProfessorID',4,N'int',NULL,NULL,NULL,1),
(N'GraduationProject',N'GraduationProjectID',1,N'int',NULL,NULL,NULL,0),
(N'GraduationProject',N'ProjectTitle',2,N'nvarchar',255,NULL,NULL,0),
(N'GraduationProject',N'DepartmentID',3,N'int',NULL,NULL,NULL,0),
(N'ResearchProject',N'ResearchProjectID',1,N'int',NULL,NULL,NULL,0),
(N'ResearchProject',N'ProjectTitle',2,N'nvarchar',255,NULL,NULL,0),
(N'ResearchProject',N'LeadDepartmentID',3,N'int',NULL,NULL,NULL,0),
(N'Book',N'BookID',1,N'int',NULL,NULL,NULL,0),
(N'Book',N'BookTitle',2,N'nvarchar',255,NULL,NULL,0),
(N'Book',N'LibraryID',3,N'int',NULL,NULL,NULL,0),
(N'DepartmentHead',N'DepartmentID',1,N'int',NULL,NULL,NULL,0),
(N'DepartmentHead',N'ProfessorID',2,N'int',NULL,NULL,NULL,0),
(N'Student',N'StudentID',1,N'int',NULL,NULL,NULL,0),
(N'Student',N'Name',2,N'nvarchar',150,NULL,NULL,0),
(N'ResearchCollaboration',N'StudentID',1,N'int',NULL,NULL,NULL,0),
(N'ResearchCollaboration',N'ProfessorID',2,N'int',NULL,NULL,NULL,0),
(N'ResearchCollaboration',N'ResearchProjectID',3,N'int',NULL,NULL,NULL,0),
(N'ResearchCollaboration',N'CollaborationDepartmentID',4,N'int',NULL,NULL,NULL,0);
INSERT INTO #ExpectedPK(TableName,KeyColumns) VALUES
(N'Department',N'DepartmentID'),
(N'Course',N'CourseID'),
(N'Semester',N'SemesterID'),
(N'Library',N'LibraryID'),
(N'StudentClub',N'ClubID'),
(N'Professor',N'ProfessorID'),
(N'GraduationProject',N'GraduationProjectID'),
(N'ResearchProject',N'ResearchProjectID'),
(N'Book',N'BookID'),
(N'DepartmentHead',N'DepartmentID'),
(N'Student',N'StudentID'),
(N'CourseResponsibility',N'CourseID,ProfessorID'),
(N'GraduationProjectSupervision',N'GraduationProjectID,ProfessorID'),
(N'ResearchProjectSupervision',N'ResearchProjectID,ProfessorID'),
(N'StudentPhone',N'StudentID,PhoneNumber'),
(N'UniversityIDCard',N'CardNumber'),
(N'Enrollment',N'StudentID,CourseID,SemesterID'),
(N'Borrowing',N'BorrowingID'),
(N'ClubMembership',N'ClubMembershipID'),
(N'ResearchParticipation',N'StudentID,ResearchProjectID'),
(N'ResearchCollaboration',N'StudentID,ProfessorID,ResearchProjectID,CollaborationDepartmentID');

INSERT INTO #ExpectedFK(ParentTable,ParentColumns,ReferencedTable,ReferencedColumns) VALUES
(N'Professor',N'AdvisorProfessorID,DepartmentID',N'Professor',N'ProfessorID,DepartmentID'),
(N'Professor',N'DepartmentID',N'Department',N'DepartmentID'),
(N'GraduationProject',N'DepartmentID',N'Department',N'DepartmentID'),
(N'ResearchProject',N'LeadDepartmentID',N'Department',N'DepartmentID'),
(N'Book',N'LibraryID',N'Library',N'LibraryID'),
(N'DepartmentHead',N'DepartmentID',N'Department',N'DepartmentID'),
(N'DepartmentHead',N'ProfessorID,DepartmentID',N'Professor',N'ProfessorID,DepartmentID'),
(N'Student',N'GraduationProjectID',N'GraduationProject',N'GraduationProjectID'),
(N'CourseResponsibility',N'CourseID',N'Course',N'CourseID'),
(N'CourseResponsibility',N'ProfessorID',N'Professor',N'ProfessorID'),
(N'GraduationProjectSupervision',N'GraduationProjectID',N'GraduationProject',N'GraduationProjectID'),
(N'GraduationProjectSupervision',N'ProfessorID',N'Professor',N'ProfessorID'),
(N'ResearchProjectSupervision',N'ResearchProjectID',N'ResearchProject',N'ResearchProjectID'),
(N'ResearchProjectSupervision',N'ProfessorID',N'Professor',N'ProfessorID'),
(N'StudentPhone',N'StudentID',N'Student',N'StudentID'),
(N'UniversityIDCard',N'StudentID',N'Student',N'StudentID'),
(N'Enrollment',N'StudentID',N'Student',N'StudentID'),
(N'Enrollment',N'CourseID',N'Course',N'CourseID'),
(N'Enrollment',N'SemesterID',N'Semester',N'SemesterID'),
(N'Borrowing',N'StudentID',N'Student',N'StudentID'),
(N'Borrowing',N'BookID',N'Book',N'BookID'),
(N'ClubMembership',N'StudentID',N'Student',N'StudentID'),
(N'ClubMembership',N'ClubID',N'StudentClub',N'ClubID'),
(N'ResearchParticipation',N'StudentID',N'Student',N'StudentID'),
(N'ResearchParticipation',N'ResearchProjectID',N'ResearchProject',N'ResearchProjectID'),
(N'ResearchCollaboration',N'CollaborationDepartmentID',N'Department',N'DepartmentID'),
(N'ResearchCollaboration',N'ProfessorID',N'Professor',N'ProfessorID'),
(N'ResearchCollaboration',N'StudentID,ResearchProjectID',N'ResearchParticipation',N'StudentID,ResearchProjectID'),
(N'ResearchCollaboration',N'ResearchProjectID',N'ResearchProject',N'ResearchProjectID'),
(N'ResearchCollaboration',N'StudentID',N'Student',N'StudentID');

-- A. Expected tables (missing table is FAIL)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'TABLE',e.TableName,'dbo table exists',
       CASE WHEN t.object_id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
       CASE WHEN t.object_id IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM #ExpectedTable e
LEFT JOIN sys.tables t ON t.name=e.TableName AND SCHEMA_NAME(t.schema_id)=N'dbo';

-- Unexpected dbo user tables are flagged (target schema has exactly 21 tables)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'EXTRA TABLE',t.name,'No extra dbo tables','EXISTS','FAIL'
FROM sys.tables t LEFT JOIN #ExpectedTable e ON e.TableName=t.name
WHERE SCHEMA_NAME(t.schema_id)=N'dbo' AND e.TableName IS NULL;
------------------------
-- B. Column metadata: compares name, order, type, NVARCHAR length, decimal (p,s), NULL
;WITH ActualColumns AS (
    SELECT t.name TableName, c.name ColumnName, c.column_id ColumnOrder,
           ty.name TypeName, CASE WHEN ty.name='nvarchar' THEN c.max_length/2 ELSE NULL END NvarcharLength,
           CASE WHEN ty.name IN('decimal','numeric') THEN CONVERT(int,c.precision) END NumericPrecision,
           CASE WHEN ty.name IN('decimal','numeric') THEN CONVERT(int,c.scale) END NumericScale,
           c.is_nullable IsNullable
    FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id
    JOIN sys.types ty ON c.user_type_id=ty.user_type_id
    WHERE SCHEMA_NAME(t.schema_id)=N'dbo'
)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'COLUMN',COALESCE(e.TableName,a.TableName)+N'.'+COALESCE(e.ColumnName,a.ColumnName),
       CASE WHEN e.ColumnName IS NULL THEN 'NOT EXPECTED' ELSE CONCAT('ord=',e.ColumnOrder,', ',e.TypeName,
            COALESCE('('+CONVERT(varchar(15),e.NvarcharLength)+')',CASE WHEN e.NumericPrecision IS NOT NULL
            THEN '('+CONVERT(varchar(15),e.NumericPrecision)+','+CONVERT(varchar(15),e.NumericScale)+')' END,''),
            ', nullable=',CONVERT(int,e.IsNullable)) END,
       CASE WHEN a.ColumnName IS NULL THEN 'MISSING' ELSE CONCAT('ord=',a.ColumnOrder,', ',a.TypeName,
            COALESCE('('+CONVERT(varchar(15),a.NvarcharLength)+')',CASE WHEN a.NumericPrecision IS NOT NULL
            THEN '('+CONVERT(varchar(15),a.NumericPrecision)+','+CONVERT(varchar(15),a.NumericScale)+')' END,''),
            ', nullable=',CONVERT(int,a.IsNullable)) END,
       CASE WHEN e.ColumnName IS NOT NULL AND a.ColumnName IS NOT NULL
                 AND e.ColumnOrder=a.ColumnOrder AND e.TypeName=a.TypeName
                 AND ISNULL(e.NvarcharLength,-1)=ISNULL(a.NvarcharLength,-1)
                 AND ISNULL(e.NumericPrecision,-1)=ISNULL(a.NumericPrecision,-1)
                 AND ISNULL(e.NumericScale,-1)=ISNULL(a.NumericScale,-1)
                 AND e.IsNullable=a.IsNullable THEN 'PASS' ELSE 'FAIL' END
FROM #ExpectedColumn e FULL JOIN ActualColumns a
 ON e.TableName=a.TableName AND e.ColumnName=a.ColumnName
WHERE e.TableName IS NOT NULL OR a.TableName IN(SELECT TableName FROM #ExpectedTable);

-------------------------------------
-- C. Actual PK column sequences (STRING_AGG order follows key_ordinal)
;WITH pkActual AS (
  SELECT t.name TableName,
         STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP (ORDER BY ic.key_ordinal) KeyColumns
  FROM sys.tables t JOIN sys.key_constraints kc ON t.object_id=kc.parent_object_id AND kc.type='PK'
  JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
  WHERE SCHEMA_NAME(t.schema_id)=N'dbo'
  GROUP BY t.name,kc.object_id
)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'PRIMARY KEY',e.TableName,e.KeyColumns,ISNULL(a.KeyColumns,'MISSING'),
       CASE WHEN e.KeyColumns=a.KeyColumns THEN 'PASS' ELSE 'FAIL' END
FROM #ExpectedPK e LEFT JOIN pkActual a ON a.TableName=e.TableName;
---------------------------------
-- D. Actual FK parent+referenced mapping, ordered for composite FK
;WITH fkActual AS (
   SELECT pt.name ParentTable, rt.name ReferencedTable, fk.name FKName,
          fk.is_disabled IsDisabled,fk.is_not_trusted IsNotTrusted,
          STRING_AGG(CONVERT(nvarchar(max),pc.name),N',') WITHIN GROUP (ORDER BY fkc.constraint_column_id) ParentColumns,
          STRING_AGG(CONVERT(nvarchar(max),rc.name),N',') WITHIN GROUP (ORDER BY fkc.constraint_column_id) ReferencedColumns
   FROM sys.foreign_keys fk
   JOIN sys.tables pt ON pt.object_id=fk.parent_object_id
   JOIN sys.tables rt ON rt.object_id=fk.referenced_object_id
   JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
   JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
   JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
   WHERE SCHEMA_NAME(pt.schema_id)=N'dbo'
   GROUP BY pt.name,rt.name,fk.name,fk.is_disabled,fk.is_not_trusted
)
SELECT * INTO #ActualFK FROM fkActual;

INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'FOREIGN KEY',e.ParentTable+N' ('+e.ParentColumns+N')',
 e.ReferencedTable+N' ('+e.ReferencedColumns+N')',
 COALESCE(a.ReferencedTable+N' ('+a.ReferencedColumns+N') '+a.FKName,N'MISSING'),
 CASE WHEN a.FKName IS NOT NULL AND a.IsDisabled=0 AND a.IsNotTrusted=0 THEN 'PASS' ELSE 'FAIL' END
FROM #ExpectedFK e
OUTER APPLY (
 SELECT TOP (1) af.* FROM #ActualFK af
 WHERE af.ParentTable=e.ParentTable AND af.ParentColumns=e.ParentColumns
   AND af.ReferencedTable=e.ReferencedTable AND af.ReferencedColumns=e.ReferencedColumns
 ORDER BY af.FKName
) a;

INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'EXTRA FK',a.ParentTable+N'.'+a.FKName,'Not defined in approved mapping',
       a.ParentColumns+N' => '+a.ReferencedTable+N'.'+a.ReferencedColumns,'FAIL'
FROM #ActualFK a
WHERE a.ParentTable IN(SELECT TableName FROM #ExpectedTable)
 AND NOT EXISTS (SELECT 1 FROM #ExpectedFK e
                 WHERE e.ParentTable=a.ParentTable AND e.ParentColumns=a.ParentColumns
                   AND e.ReferencedTable=a.ReferencedTable AND e.ReferencedColumns=a.ReferencedColumns);
--------------------------------------------
-- E. Known critical CHECK constraints should exist, be enabled and trusted
DECLARE @ExpectedCheck TABLE(TableName sysname,CheckName sysname);
INSERT @ExpectedCheck VALUES
(N'Professor',N'CK_Professor_NoSelfAdvice'),
(N'Borrowing',N'CK_Borrowing_DueDate'),
(N'Borrowing',N'CK_Borrowing_ReturnDate'),
(N'ClubMembership',N'CK_ClubMembership_EndDate');
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'CRITICAL CHECK',e.TableName+N'.'+e.CheckName,'Exists; enabled/trusted',
 CASE WHEN c.object_id IS NULL THEN 'MISSING' ELSE CONCAT('disabled=',c.is_disabled,', not_trusted=',c.is_not_trusted) END,
 CASE WHEN c.object_id IS NOT NULL AND c.is_disabled=0 AND c.is_not_trusted=0 THEN 'PASS' ELSE 'FAIL' END
FROM @ExpectedCheck e
LEFT JOIN sys.tables t ON t.name=e.TableName AND SCHEMA_NAME(t.schema_id)=N'dbo'
LEFT JOIN sys.check_constraints c ON c.parent_object_id=t.object_id AND c.name=e.CheckName;

INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'UNTRUSTED CHECK',t.name+N'.'+cc.name,'enabled/trusted',
       CONCAT('disabled=',cc.is_disabled,', not_trusted=',cc.is_not_trusted),'FAIL'
FROM sys.check_constraints cc JOIN sys.tables t ON t.object_id=cc.parent_object_id
WHERE SCHEMA_NAME(t.schema_id)=N'dbo' AND (cc.is_disabled=1 OR cc.is_not_trusted=1);
-----------------------------------------------
-- F. Expected UNIQUE constraints (order sensitive)
DECLARE @ExpectedUQ TABLE(TableName sysname,KeyColumns nvarchar(500));
INSERT @ExpectedUQ VALUES
(N'Professor',N'ProfessorID,DepartmentID'),
(N'DepartmentHead',N'ProfessorID'),
(N'Semester',N'AcademicYear,TermName'),
(N'UniversityIDCard',N'StudentID'),
(N'ClubMembership',N'StudentID,ClubID,JoinDate');
;WITH actualUQ AS (
 SELECT t.name TableName,kc.name UQName,
        STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP (ORDER BY ic.key_ordinal) KeyColumns
 FROM sys.tables t JOIN sys.key_constraints kc ON kc.parent_object_id=t.object_id AND kc.type='UQ'
 JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal>0
 JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ic.column_id
 WHERE SCHEMA_NAME(t.schema_id)=N'dbo'
 GROUP BY t.name,kc.name
)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'UNIQUE KEY',e.TableName+N' ('+e.KeyColumns+N')','Unique constraint',
       COALESCE(a.UQName,'MISSING'),CASE WHEN a.UQName IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM @ExpectedUQ e
LEFT JOIN actualUQ a ON a.TableName=e.TableName AND a.KeyColumns=e.KeyColumns;
-------------------------------
-- G. Filtered unique indexes enforce at most one active/open row per key
DECLARE @ExpectedIX TABLE(TableName sysname,IndexName sysname,KeyColumns nvarchar(500),FilteredColumn sysname);
INSERT @ExpectedIX VALUES
(N'Borrowing',N'UX_Borrowing_OneOpenLoanPerBook',N'BookID',N'ReturnDate'),
(N'ClubMembership',N'UX_ClubMembership_OneActivePerStudentClub',N'StudentID,ClubID',N'EndDate');
;WITH actualIX AS (
 SELECT t.name TableName,i.name IndexName,i.is_unique,i.is_disabled,i.has_filter,i.filter_definition,
        STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP(ORDER BY ic.key_ordinal) KeyColumns
 FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id
 JOIN sys.index_columns ic ON ic.object_id=t.object_id AND ic.index_id=i.index_id AND ic.key_ordinal>0
 JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ic.column_id
 WHERE SCHEMA_NAME(t.schema_id)=N'dbo'
 GROUP BY t.name,i.name,i.is_unique,i.is_disabled,i.has_filter,i.filter_definition
)
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'FILTERED INDEX',e.TableName+N'.'+e.IndexName,
       e.KeyColumns+N' WHERE '+e.FilteredColumn+N' IS NULL',
       COALESCE(a.KeyColumns+N' WHERE '+a.filter_definition,'MISSING'),
       CASE WHEN a.IndexName IS NOT NULL AND a.is_unique=1 AND a.is_disabled=0 AND a.has_filter=1
                AND a.KeyColumns=e.KeyColumns
                AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(a.filter_definition),N'[',N''),N']',N''),N'(',N''),N')',N''),N' ',N'')
                    = UPPER(e.FilteredColumn)+N'ISNULL'
           THEN 'PASS' ELSE 'FAIL' END
FROM @ExpectedIX e LEFT JOIN actualIX a ON a.TableName=e.TableName AND a.IndexName=e.IndexName;
--------------------------------
-- H. Extra non-PK UNIQUE indexes on ResearchCollaboration are prohibited
INSERT #Checks(Area,ObjectName,Expected,Actual,Result)
SELECT 'PROHIBITED UNIQUE',N'ResearchCollaboration.'+i.name,'None','Unexpected unique index','FAIL'
FROM sys.indexes i
WHERE i.object_id=OBJECT_ID(N'dbo.ResearchCollaboration',N'U')
  AND i.is_unique=1 AND i.is_primary_key=0;

-- I. Report
SELECT Area,
       COUNT(*) AS Checks,
       SUM(CASE WHEN Result='PASS' THEN 1 ELSE 0 END) AS Passed,
       SUM(CASE WHEN Result='FAIL' THEN 1 ELSE 0 END) AS Failed
FROM #Checks GROUP BY Area ORDER BY Area;

SELECT Area,ObjectName,Expected,Actual,Result
FROM #Checks WHERE Result='FAIL' ORDER BY Area,ObjectName;

SELECT DB_NAME() AS DatabaseName,
       (SELECT COUNT(*) FROM sys.tables WHERE SCHEMA_NAME(schema_id)=N'dbo') AS ActualDboTableCount,
       (SELECT COUNT(*) FROM #ExpectedTable) AS ExpectedDboTableCount,
       (SELECT COUNT(*) FROM #ExpectedFK) AS ExpectedFKCount,
       (SELECT COUNT(*) FROM #ActualFK WHERE ParentTable IN (SELECT TableName FROM #ExpectedTable)) AS ActualFKCount,
       (SELECT COUNT(*) FROM #Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM #Checks WHERE Result='FAIL') AS FailedChecks,
       CASE WHEN NOT EXISTS (SELECT 1 FROM #Checks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END AS FINAL_DATABASE_SCHEMA_AUDIT;

       ------------------------------------------
GO
