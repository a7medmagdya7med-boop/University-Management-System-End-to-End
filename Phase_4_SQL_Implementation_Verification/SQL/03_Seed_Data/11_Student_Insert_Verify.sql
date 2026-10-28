-- Extracted from UniversityManagementDB(2).sql; source lines 4949-5419.
USE [UniversityManagementDB];
GO
--Table 11 — Student
---Phase4_11_Insert_Student
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Student',N'U') IS NULL
    THROW 51101, 'STOP: dbo.Student does not exist.', 1;
IF OBJECT_ID(N'dbo.GraduationProject',N'U') IS NULL
    THROW 51102, 'STOP: dbo.GraduationProject does not exist.', 1;

-- Strict five-column physical shape from approved Phase 3 DDL.
IF (SELECT COUNT_BIG(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Student',N'U'))<>5
 OR EXISTS (
     SELECT 1
     FROM (VALUES
       (1,N'StudentID',56,4,0),
       (2,N'Name',231,300,0),
       (3,N'DateOfBirth',40,3,0),
       (4,N'Email',231,508,0),
       (5,N'GraduationProjectID',56,4,1)
     ) e(ColumnOrder,ColumnName,TypeID,MaxBytes,IsNullable)
     LEFT JOIN sys.columns c
       ON c.object_id=OBJECT_ID(N'dbo.Student',N'U') AND c.column_id=e.ColumnOrder
     WHERE c.column_id IS NULL OR c.name<>e.ColumnName
        OR c.system_type_id<>e.TypeID OR c.max_length<>e.MaxBytes
        OR c.is_nullable<>e.IsNullable
 )
    THROW 51103, 'STOP: dbo.Student columns differ from approved DDL.', 1;

IF (SELECT COUNT_BIG(*) FROM sys.key_constraints
    WHERE parent_object_id=OBJECT_ID(N'dbo.Student',N'U') AND type='PK')<>1
 OR NOT EXISTS (
    SELECT 1 FROM sys.key_constraints kc
    JOIN sys.index_columns ic
      ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
     AND ic.key_ordinal=1
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(N'dbo.Student',N'U')
      AND kc.name=N'PK_Student' AND kc.type='PK' AND c.name=N'StudentID'
      AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic2
           WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id
             AND ic2.key_ordinal>0)=1
)
    THROW 51104, 'STOP: Student PK is not approved PK_Student(StudentID).', 1;

IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys
    WHERE parent_object_id=OBJECT_ID(N'dbo.Student',N'U'))<>1
 OR NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
    JOIN sys.columns pc ON pc.object_id=fc.parent_object_id
                       AND pc.column_id=fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id
                       AND rc.column_id=fc.referenced_column_id
    WHERE fk.parent_object_id=OBJECT_ID(N'dbo.Student',N'U')
      AND fk.referenced_object_id=OBJECT_ID(N'dbo.GraduationProject',N'U')
      AND fk.name=N'FK_Student_GraduationProject'
      AND fk.is_disabled=0 AND fk.is_not_trusted=0
      AND pc.name=N'GraduationProjectID' AND rc.name=N'GraduationProjectID'
      AND fc.constraint_column_id=1
      AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns ff
           WHERE ff.constraint_object_id=fk.object_id)=1
)
    THROW 51105, 'STOP: Student FK is absent, disabled, untrusted or malformed.', 1;

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE object_id=OBJECT_ID(N'dbo.Student',N'U')
             AND is_unique=1 AND is_primary_key=0)
    THROW 51106, 'STOP: Student has an unauthorized additional UNIQUE index.', 1;

-- Approved reference data must be intact before any insert.
IF NOT ((SELECT COUNT_BIG(*) FROM dbo.GraduationProject)=16
  AND NOT EXISTS (
    SELECT 1 FROM (VALUES (1001), (1002), (1003), (1004), (1005), (1006), (1007), (1008), (1009), (1010), (1011), (1012), (1013), (1014), (1015), (1016)) e(GraduationProjectID)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.GraduationProject gp
                      WHERE gp.GraduationProjectID=e.GraduationProjectID)
  ))
    THROW 51107, 'STOP: Expected 16 graduation projects 1001..1016 are not present.', 1;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.Student WITH (UPDLOCK,HOLDLOCK))
        THROW 51108, 'STOP: dbo.Student already contains rows. No insert attempted.', 1;

    INSERT INTO dbo.Student
        (StudentID,[Name],DateOfBirth,Email,GraduationProjectID)
    VALUES
        (10001, N'Mariam Khalil', CONVERT(date, '19990101', 112), N's10001@students.university.example', 1001),
        (10002, N'Omar Khalil', CONVERT(date, '20040812', 112), N's10002@students.university.example', 1001),
        (10003, N'Nour Khalil', CONVERT(date, '20010323', 112), N's10003@students.university.example', NULL),
        (10004, N'Yousef Khalil', CONVERT(date, '20061007', 112), N's10004@students.university.example', NULL),
        (10005, N'Salma Khalil', CONVERT(date, '20030518', 112), N's10005@students.university.example', 1002),
        (10006, N'Ahmed Khalil', CONVERT(date, '20001202', 112), N's10006@students.university.example', 1002),
        (10007, N'Lina Khalil', CONVERT(date, '20050713', 112), N's10007@students.university.example', NULL),
        (10008, N'Karim Khalil', CONVERT(date, '20020224', 112), N's10008@students.university.example', NULL),
        (10009, N'Hana Khalil', CONVERT(date, '19990908', 112), N's10009@students.university.example', 1003),
        (10010, N'Tarek Khalil', CONVERT(date, '20040419', 112), N's10010@students.university.example', 1003),
        (10011, N'Dina Khalil', CONVERT(date, '20011103', 112), N's10011@students.university.example', NULL),
        (10012, N'Hassan Khalil', CONVERT(date, '20060614', 112), N's10012@students.university.example', NULL),
        (10013, N'Reem Khalil', CONVERT(date, '20030125', 112), N's10013@students.university.example', 1004),
        (10014, N'Adel Khalil', CONVERT(date, '20000809', 112), N's10014@students.university.example', 1004),
        (10015, N'Farah Khalil', CONVERT(date, '20050320', 112), N's10015@students.university.example', NULL),
        (10016, N'Samir Khalil', CONVERT(date, '20021004', 112), N's10016@students.university.example', NULL),
        (10017, N'Mariam Mansour', CONVERT(date, '19990515', 112), N's10017@students.university.example', 1005),
        (10018, N'Omar Mansour', CONVERT(date, '20041226', 112), N's10018@students.university.example', 1005),
        (10019, N'Nour Mansour', CONVERT(date, '20010710', 112), N's10019@students.university.example', NULL),
        (10020, N'Yousef Mansour', CONVERT(date, '20060221', 112), N's10020@students.university.example', NULL),
        (10021, N'Salma Mansour', CONVERT(date, '20030905', 112), N's10021@students.university.example', 1006),
        (10022, N'Ahmed Mansour', CONVERT(date, '20000416', 112), N's10022@students.university.example', 1006),
        (10023, N'Lina Mansour', CONVERT(date, '20051127', 112), N's10023@students.university.example', NULL),
        (10024, N'Karim Mansour', CONVERT(date, '20020611', 112), N's10024@students.university.example', NULL),
        (10025, N'Hana Mansour', CONVERT(date, '19990122', 112), N's10025@students.university.example', 1007),
        (10026, N'Tarek Mansour', CONVERT(date, '20040806', 112), N's10026@students.university.example', 1007),
        (10027, N'Dina Mansour', CONVERT(date, '20010317', 112), N's10027@students.university.example', NULL),
        (10028, N'Hassan Mansour', CONVERT(date, '20061001', 112), N's10028@students.university.example', NULL),
        (10029, N'Reem Mansour', CONVERT(date, '20030512', 112), N's10029@students.university.example', 1008),
        (10030, N'Adel Mansour', CONVERT(date, '20001223', 112), N's10030@students.university.example', 1008),
        (10031, N'Farah Mansour', CONVERT(date, '20050707', 112), N's10031@students.university.example', NULL),
        (10032, N'Samir Mansour', CONVERT(date, '20020218', 112), N's10032@students.university.example', NULL),
        (10033, N'Mariam Haddad', CONVERT(date, '19990902', 112), N's10033@students.university.example', 1009),
        (10034, N'Omar Haddad', CONVERT(date, '20040413', 112), N's10034@students.university.example', 1009),
        (10035, N'Nour Haddad', CONVERT(date, '20011124', 112), N's10035@students.university.example', NULL),
        (10036, N'Yousef Haddad', CONVERT(date, '20060608', 112), N's10036@students.university.example', NULL),
        (10037, N'Salma Haddad', CONVERT(date, '20030119', 112), N's10037@students.university.example', 1010),
        (10038, N'Ahmed Haddad', CONVERT(date, '20000803', 112), N's10038@students.university.example', 1010),
        (10039, N'Lina Haddad', CONVERT(date, '20050314', 112), N's10039@students.university.example', NULL),
        (10040, N'Karim Haddad', CONVERT(date, '20021025', 112), N's10040@students.university.example', NULL),
        (10041, N'Hana Haddad', CONVERT(date, '19990509', 112), N's10041@students.university.example', 1011),
        (10042, N'Tarek Haddad', CONVERT(date, '20041220', 112), N's10042@students.university.example', 1011),
        (10043, N'Dina Haddad', CONVERT(date, '20010704', 112), N's10043@students.university.example', NULL),
        (10044, N'Hassan Haddad', CONVERT(date, '20060215', 112), N's10044@students.university.example', NULL),
        (10045, N'Reem Haddad', CONVERT(date, '20030926', 112), N's10045@students.university.example', 1012),
        (10046, N'Adel Haddad', CONVERT(date, '20000410', 112), N's10046@students.university.example', 1012),
        (10047, N'Farah Haddad', CONVERT(date, '20051121', 112), N's10047@students.university.example', NULL),
        (10048, N'Samir Haddad', CONVERT(date, '20020605', 112), N's10048@students.university.example', NULL),
        (10049, N'Mariam Younis', CONVERT(date, '19990116', 112), N's10049@students.university.example', 1013),
        (10050, N'Omar Younis', CONVERT(date, '20040827', 112), N's10050@students.university.example', 1013),
        (10051, N'Nour Younis', CONVERT(date, '20010311', 112), N's10051@students.university.example', NULL),
        (10052, N'Yousef Younis', CONVERT(date, '20061022', 112), N's10052@students.university.example', NULL),
        (10053, N'Salma Younis', CONVERT(date, '20030506', 112), N's10053@students.university.example', 1014),
        (10054, N'Ahmed Younis', CONVERT(date, '20001217', 112), N's10054@students.university.example', 1014),
        (10055, N'Lina Younis', CONVERT(date, '20050701', 112), N's10055@students.university.example', NULL),
        (10056, N'Karim Younis', CONVERT(date, '20020212', 112), N's10056@students.university.example', NULL),
        (10057, N'Hana Younis', CONVERT(date, '19990923', 112), N's10057@students.university.example', 1015),
        (10058, N'Tarek Younis', CONVERT(date, '20040407', 112), N's10058@students.university.example', 1015),
        (10059, N'Dina Younis', CONVERT(date, '20011118', 112), N's10059@students.university.example', NULL),
        (10060, N'Hassan Younis', CONVERT(date, '20060602', 112), N's10060@students.university.example', NULL),
        (10061, N'Reem Younis', CONVERT(date, '20030113', 112), N's10061@students.university.example', 1016),
        (10062, N'Adel Younis', CONVERT(date, '20000824', 112), N's10062@students.university.example', 1016),
        (10063, N'Farah Younis', CONVERT(date, '20050308', 112), N's10063@students.university.example', NULL),
        (10064, N'Samir Younis', CONVERT(date, '20021019', 112), N's10064@students.university.example', NULL);

    IF @@ROWCOUNT<>64
        THROW 51109, 'STOP: Inserted Student row count is not 64.', 1;

    IF (SELECT COUNT_BIG(*) FROM dbo.Student)<>64
       OR (SELECT COUNT_BIG(*) FROM dbo.Student WHERE GraduationProjectID IS NULL)<>32
       OR (SELECT COUNT_BIG(*) FROM dbo.Student WHERE GraduationProjectID IS NOT NULL)<>32
        THROW 51110, 'STOP: Student count or project assignment distribution is wrong.', 1;

    IF EXISTS (
      SELECT 1 FROM dbo.GraduationProject gp
      OUTER APPLY (SELECT COUNT_BIG(*) AS NumStudents FROM dbo.Student s
                   WHERE s.GraduationProjectID=gp.GraduationProjectID) x
      WHERE x.NumStudents<>2
    )
        THROW 51111, 'STOP: Every graduation project must have exactly 2 seed students.', 1;

    IF EXISTS (
      SELECT 1 FROM dbo.Student
      WHERE [Name] IS NULL OR LEN(LTRIM(RTRIM([Name])))=0
         OR Email IS NULL OR LEN(LTRIM(RTRIM(Email)))=0
         OR DateOfBirth IS NULL OR DateOfBirth>CAST(GETDATE() AS date)
    )
        THROW 51112, 'STOP: Seed contains an invalid name, email or date of birth.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Student GROUP BY Email HAVING COUNT_BIG(*)>1)
        THROW 51113, 'STOP: Duplicate synthetic email found in Student seed.', 1;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    PRINT 'Student: 64 synthetic records COMMITTED. Run Phase4_11_Verify_Student.sql.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
-------------------------------------
----Phase4_11_Verify_Student
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Student',N'U') IS NULL
   OR OBJECT_ID(N'dbo.GraduationProject',N'U') IS NULL
BEGIN
    SELECT N'Student: Exact Row Set + Schema + PK + FK' AS VerificationTest,
           'FAIL' AS VerificationResult,
           CAST(NULL AS bigint) AS ActualRows,
           CAST(64 AS bigint) AS ExpectedRows,
           'Student or parent table missing' AS Finding;
    RETURN;
END;

DECLARE @Expected TABLE (
    StudentID int NOT NULL PRIMARY KEY,
    [Name] nvarchar(150) NOT NULL,
    DateOfBirth date NOT NULL,
    Email nvarchar(254) NOT NULL,
    GraduationProjectID int NULL
);
INSERT INTO @Expected (StudentID,[Name],DateOfBirth,Email,GraduationProjectID)
VALUES
        (10001, N'Mariam Khalil', CONVERT(date, '19990101', 112), N's10001@students.university.example', 1001),
        (10002, N'Omar Khalil', CONVERT(date, '20040812', 112), N's10002@students.university.example', 1001),
        (10003, N'Nour Khalil', CONVERT(date, '20010323', 112), N's10003@students.university.example', NULL),
        (10004, N'Yousef Khalil', CONVERT(date, '20061007', 112), N's10004@students.university.example', NULL),
        (10005, N'Salma Khalil', CONVERT(date, '20030518', 112), N's10005@students.university.example', 1002),
        (10006, N'Ahmed Khalil', CONVERT(date, '20001202', 112), N's10006@students.university.example', 1002),
        (10007, N'Lina Khalil', CONVERT(date, '20050713', 112), N's10007@students.university.example', NULL),
        (10008, N'Karim Khalil', CONVERT(date, '20020224', 112), N's10008@students.university.example', NULL),
        (10009, N'Hana Khalil', CONVERT(date, '19990908', 112), N's10009@students.university.example', 1003),
        (10010, N'Tarek Khalil', CONVERT(date, '20040419', 112), N's10010@students.university.example', 1003),
        (10011, N'Dina Khalil', CONVERT(date, '20011103', 112), N's10011@students.university.example', NULL),
        (10012, N'Hassan Khalil', CONVERT(date, '20060614', 112), N's10012@students.university.example', NULL),
        (10013, N'Reem Khalil', CONVERT(date, '20030125', 112), N's10013@students.university.example', 1004),
        (10014, N'Adel Khalil', CONVERT(date, '20000809', 112), N's10014@students.university.example', 1004),
        (10015, N'Farah Khalil', CONVERT(date, '20050320', 112), N's10015@students.university.example', NULL),
        (10016, N'Samir Khalil', CONVERT(date, '20021004', 112), N's10016@students.university.example', NULL),
        (10017, N'Mariam Mansour', CONVERT(date, '19990515', 112), N's10017@students.university.example', 1005),
        (10018, N'Omar Mansour', CONVERT(date, '20041226', 112), N's10018@students.university.example', 1005),
        (10019, N'Nour Mansour', CONVERT(date, '20010710', 112), N's10019@students.university.example', NULL),
        (10020, N'Yousef Mansour', CONVERT(date, '20060221', 112), N's10020@students.university.example', NULL),
        (10021, N'Salma Mansour', CONVERT(date, '20030905', 112), N's10021@students.university.example', 1006),
        (10022, N'Ahmed Mansour', CONVERT(date, '20000416', 112), N's10022@students.university.example', 1006),
        (10023, N'Lina Mansour', CONVERT(date, '20051127', 112), N's10023@students.university.example', NULL),
        (10024, N'Karim Mansour', CONVERT(date, '20020611', 112), N's10024@students.university.example', NULL),
        (10025, N'Hana Mansour', CONVERT(date, '19990122', 112), N's10025@students.university.example', 1007),
        (10026, N'Tarek Mansour', CONVERT(date, '20040806', 112), N's10026@students.university.example', 1007),
        (10027, N'Dina Mansour', CONVERT(date, '20010317', 112), N's10027@students.university.example', NULL),
        (10028, N'Hassan Mansour', CONVERT(date, '20061001', 112), N's10028@students.university.example', NULL),
        (10029, N'Reem Mansour', CONVERT(date, '20030512', 112), N's10029@students.university.example', 1008),
        (10030, N'Adel Mansour', CONVERT(date, '20001223', 112), N's10030@students.university.example', 1008),
        (10031, N'Farah Mansour', CONVERT(date, '20050707', 112), N's10031@students.university.example', NULL),
        (10032, N'Samir Mansour', CONVERT(date, '20020218', 112), N's10032@students.university.example', NULL),
        (10033, N'Mariam Haddad', CONVERT(date, '19990902', 112), N's10033@students.university.example', 1009),
        (10034, N'Omar Haddad', CONVERT(date, '20040413', 112), N's10034@students.university.example', 1009),
        (10035, N'Nour Haddad', CONVERT(date, '20011124', 112), N's10035@students.university.example', NULL),
        (10036, N'Yousef Haddad', CONVERT(date, '20060608', 112), N's10036@students.university.example', NULL),
        (10037, N'Salma Haddad', CONVERT(date, '20030119', 112), N's10037@students.university.example', 1010),
        (10038, N'Ahmed Haddad', CONVERT(date, '20000803', 112), N's10038@students.university.example', 1010),
        (10039, N'Lina Haddad', CONVERT(date, '20050314', 112), N's10039@students.university.example', NULL),
        (10040, N'Karim Haddad', CONVERT(date, '20021025', 112), N's10040@students.university.example', NULL),
        (10041, N'Hana Haddad', CONVERT(date, '19990509', 112), N's10041@students.university.example', 1011),
        (10042, N'Tarek Haddad', CONVERT(date, '20041220', 112), N's10042@students.university.example', 1011),
        (10043, N'Dina Haddad', CONVERT(date, '20010704', 112), N's10043@students.university.example', NULL),
        (10044, N'Hassan Haddad', CONVERT(date, '20060215', 112), N's10044@students.university.example', NULL),
        (10045, N'Reem Haddad', CONVERT(date, '20030926', 112), N's10045@students.university.example', 1012),
        (10046, N'Adel Haddad', CONVERT(date, '20000410', 112), N's10046@students.university.example', 1012),
        (10047, N'Farah Haddad', CONVERT(date, '20051121', 112), N's10047@students.university.example', NULL),
        (10048, N'Samir Haddad', CONVERT(date, '20020605', 112), N's10048@students.university.example', NULL),
        (10049, N'Mariam Younis', CONVERT(date, '19990116', 112), N's10049@students.university.example', 1013),
        (10050, N'Omar Younis', CONVERT(date, '20040827', 112), N's10050@students.university.example', 1013),
        (10051, N'Nour Younis', CONVERT(date, '20010311', 112), N's10051@students.university.example', NULL),
        (10052, N'Yousef Younis', CONVERT(date, '20061022', 112), N's10052@students.university.example', NULL),
        (10053, N'Salma Younis', CONVERT(date, '20030506', 112), N's10053@students.university.example', 1014),
        (10054, N'Ahmed Younis', CONVERT(date, '20001217', 112), N's10054@students.university.example', 1014),
        (10055, N'Lina Younis', CONVERT(date, '20050701', 112), N's10055@students.university.example', NULL),
        (10056, N'Karim Younis', CONVERT(date, '20020212', 112), N's10056@students.university.example', NULL),
        (10057, N'Hana Younis', CONVERT(date, '19990923', 112), N's10057@students.university.example', 1015),
        (10058, N'Tarek Younis', CONVERT(date, '20040407', 112), N's10058@students.university.example', 1015),
        (10059, N'Dina Younis', CONVERT(date, '20011118', 112), N's10059@students.university.example', NULL),
        (10060, N'Hassan Younis', CONVERT(date, '20060602', 112), N's10060@students.university.example', NULL),
        (10061, N'Reem Younis', CONVERT(date, '20030113', 112), N's10061@students.university.example', 1016),
        (10062, N'Adel Younis', CONVERT(date, '20000824', 112), N's10062@students.university.example', 1016),
        (10063, N'Farah Younis', CONVERT(date, '20050308', 112), N's10063@students.university.example', NULL),
        (10064, N'Samir Younis', CONVERT(date, '20021019', 112), N's10064@students.university.example', NULL);

DECLARE @ActualRows bigint=(SELECT COUNT_BIG(*) FROM dbo.Student);
DECLARE @ExpectedRows bigint=64;
DECLARE @ColumnsOK bit=0, @PKOK bit=0, @FKOK bit=0,
        @UniqueOK bit=0, @ParentsOK bit=0, @ExactRowsOK bit=0,
        @QualityOK bit=0, @DistributionOK bit=0;

IF NOT ((SELECT COUNT_BIG(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Student',N'U'))<>5
 OR EXISTS (
     SELECT 1
     FROM (VALUES
       (1,N'StudentID',56,4,0),
       (2,N'Name',231,300,0),
       (3,N'DateOfBirth',40,3,0),
       (4,N'Email',231,508,0),
       (5,N'GraduationProjectID',56,4,1)
     ) e(ColumnOrder,ColumnName,TypeID,MaxBytes,IsNullable)
     LEFT JOIN sys.columns c
       ON c.object_id=OBJECT_ID(N'dbo.Student',N'U') AND c.column_id=e.ColumnOrder
     WHERE c.column_id IS NULL OR c.name<>e.ColumnName
        OR c.system_type_id<>e.TypeID OR c.max_length<>e.MaxBytes
        OR c.is_nullable<>e.IsNullable
 ))
    SET @ColumnsOK=1;

IF (SELECT COUNT_BIG(*) FROM sys.key_constraints
    WHERE parent_object_id=OBJECT_ID(N'dbo.Student',N'U') AND type='PK')=1
 AND EXISTS (
    SELECT 1 FROM sys.key_constraints kc
    JOIN sys.index_columns ic
      ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
     AND ic.key_ordinal=1
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(N'dbo.Student',N'U')
      AND kc.name=N'PK_Student' AND kc.type='PK' AND c.name=N'StudentID'
      AND (SELECT COUNT_BIG(*) FROM sys.index_columns ic2
           WHERE ic2.object_id=ic.object_id AND ic2.index_id=ic.index_id
             AND ic2.key_ordinal>0)=1
)
    SET @PKOK=1;

IF (SELECT COUNT_BIG(*) FROM sys.foreign_keys
    WHERE parent_object_id=OBJECT_ID(N'dbo.Student',N'U'))=1
 AND EXISTS (
    SELECT 1 FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
    JOIN sys.columns pc ON pc.object_id=fc.parent_object_id
                       AND pc.column_id=fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id
                       AND rc.column_id=fc.referenced_column_id
    WHERE fk.parent_object_id=OBJECT_ID(N'dbo.Student',N'U')
      AND fk.referenced_object_id=OBJECT_ID(N'dbo.GraduationProject',N'U')
      AND fk.name=N'FK_Student_GraduationProject'
      AND fk.is_disabled=0 AND fk.is_not_trusted=0
      AND pc.name=N'GraduationProjectID' AND rc.name=N'GraduationProjectID'
      AND fc.constraint_column_id=1
      AND (SELECT COUNT_BIG(*) FROM sys.foreign_key_columns ff
           WHERE ff.constraint_object_id=fk.object_id)=1
)
    SET @FKOK=1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id=OBJECT_ID(N'dbo.Student',N'U')
                 AND is_unique=1 AND is_primary_key=0)
    SET @UniqueOK=1;

IF (SELECT COUNT_BIG(*) FROM dbo.GraduationProject)=16
  AND NOT EXISTS (
    SELECT 1 FROM (VALUES (1001), (1002), (1003), (1004), (1005), (1006), (1007), (1008), (1009), (1010), (1011), (1012), (1013), (1014), (1015), (1016)) e(GraduationProjectID)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.GraduationProject gp
                      WHERE gp.GraduationProjectID=e.GraduationProjectID)
  )
    SET @ParentsOK=1;

IF @ActualRows=@ExpectedRows
   AND NOT EXISTS (
       SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM @Expected
       EXCEPT
       SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM dbo.Student
   )
   AND NOT EXISTS (
       SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM dbo.Student
       EXCEPT
       SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM @Expected
   )
    SET @ExactRowsOK=1;

IF NOT EXISTS (
       SELECT 1 FROM dbo.Student s
       LEFT JOIN dbo.GraduationProject gp
         ON gp.GraduationProjectID=s.GraduationProjectID
       WHERE s.[Name] IS NULL OR LEN(LTRIM(RTRIM(s.[Name])))=0
          OR s.Email IS NULL OR LEN(LTRIM(RTRIM(s.Email)))=0
          OR s.DateOfBirth IS NULL OR s.DateOfBirth>CAST(GETDATE() AS date)
          OR (s.GraduationProjectID IS NOT NULL AND gp.GraduationProjectID IS NULL)
   )
   AND NOT EXISTS (SELECT 1 FROM dbo.Student GROUP BY Email HAVING COUNT_BIG(*)>1)
    SET @QualityOK=1;

IF (SELECT COUNT_BIG(*) FROM dbo.Student WHERE GraduationProjectID IS NULL)=32
   AND (SELECT COUNT_BIG(*) FROM dbo.Student WHERE GraduationProjectID IS NOT NULL)=32
   AND (SELECT COUNT_BIG(*) FROM dbo.GraduationProject)=16
   AND NOT EXISTS (
        SELECT 1 FROM dbo.GraduationProject gp
        OUTER APPLY (SELECT COUNT_BIG(*) AS NumStudents FROM dbo.Student s
                     WHERE s.GraduationProjectID=gp.GraduationProjectID) x
        WHERE x.NumStudents<>2
   )
    SET @DistributionOK=1;

-- Result 1: the gate; PASS is expected only after successful INSERT.
SELECT N'Student: Exact Row Set + Schema + PK + FK' AS VerificationTest,
       CASE WHEN @ColumnsOK=1 AND @PKOK=1 AND @FKOK=1 AND @UniqueOK=1
                  AND @ParentsOK=1 AND @ExactRowsOK=1
                  AND @QualityOK=1 AND @DistributionOK=1
            THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       @ActualRows AS ActualRows, @ExpectedRows AS ExpectedRows;

-- Result 2: see all conditions separately; every Result must be PASS.
SELECT Item, CASE WHEN OK=1 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM (VALUES
   (1,N'Five approved columns / data types / nullability',@ColumnsOK),
   (2,N'Approved primary key PK_Student(StudentID)',@PKOK),
   (3,N'Enabled + trusted FK to GraduationProject',@FKOK),
   (4,N'No additional UNIQUE indexes (Email is not UNIQUE)',@UniqueOK),
   (5,N'Parent project baseline: 16 IDs (1001..1016)',@ParentsOK),
   (6,N'Exact row set: 64 / no extra / no missing / no altered',@ExactRowsOK),
   (7,N'Valid seed names, emails, dates and FK references',@QualityOK),
   (8,N'32 NULL + 32 linked / exactly two students per project',@DistributionOK)
) v(SortOrder,Item,OK)
ORDER BY SortOrder;

-- Result 3: inspect actual students; sorted by StudentID.
SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID
FROM dbo.Student ORDER BY StudentID;

-- Results 4 and 5: both expected EMPTY result sets.
SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID
FROM @Expected
EXCEPT
SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM dbo.Student;

SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID
FROM dbo.Student
EXCEPT
SELECT StudentID,[Name],DateOfBirth,Email,GraduationProjectID FROM @Expected;

-- Result 6: 16 projects, each with exactly 2 linked students.
SELECT gp.GraduationProjectID,gp.ProjectTitle,
       COUNT_BIG(s.StudentID) AS StudentCount
FROM dbo.GraduationProject gp
LEFT JOIN dbo.Student s ON s.GraduationProjectID=gp.GraduationProjectID
GROUP BY gp.GraduationProjectID,gp.ProjectTitle
ORDER BY gp.GraduationProjectID;

-- Result 7: 32 / 32 distribution.
SELECT CASE WHEN GraduationProjectID IS NULL THEN N'No graduation project'
            ELSE N'Assigned to graduation project' END AS ProjectAssignment,
       COUNT_BIG(*) AS StudentCount
FROM dbo.Student
GROUP BY CASE WHEN GraduationProjectID IS NULL THEN N'No graduation project'
              ELSE N'Assigned to graduation project' END;

-- Result 8: expected no rows (seed email duplicates).
SELECT Email,COUNT_BIG(*) AS DuplicateCount
FROM dbo.Student GROUP BY Email HAVING COUNT_BIG(*)>1;

-- Result 9: exact physical column metadata.
SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,t.name AS DataType,
       c.max_length AS LengthBytes,c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON t.user_type_id=c.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.Student',N'U')
ORDER BY c.column_id;

-- Result 10: FK must have IsDisabled=0, IsNotTrusted=0.
SELECT fk.name AS ForeignKeyName,fk.is_disabled AS IsDisabled,
       fk.is_not_trusted AS IsNotTrusted,pc.name AS ParentColumn,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       rc.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fc.parent_object_id
                   AND pc.column_id=fc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id
                   AND rc.column_id=fc.referenced_column_id
WHERE fk.parent_object_id=OBJECT_ID(N'dbo.Student',N'U');
------------------------------------------------------------
GO
