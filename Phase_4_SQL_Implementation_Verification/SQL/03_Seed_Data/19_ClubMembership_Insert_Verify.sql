-- Extracted from UniversityManagementDB(2).sql; source lines 8430-8856.
USE [UniversityManagementDB];
GO
---Table 19/21 — ClubMembership
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'UniversityManagementDB'
    THROW 51901, 'STOP: Wrong database selected.', 1;
IF OBJECT_ID(N'dbo.ClubMembership', N'U') IS NULL
    THROW 51902, 'STOP: dbo.ClubMembership is missing. Run the approved DDL separately.', 1;
IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
    OR OBJECT_ID(N'dbo.StudentClub', N'U') IS NULL
    THROW 51903, 'STOP: Required parent table missing.', 1;

DECLARE @TableID INT = OBJECT_ID(N'dbo.ClubMembership', N'U');

-- Structural guardrails (no changes made).
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = @TableID) <> 5
    OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=1 AND name=N'ClubMembershipID' AND system_type_id=127 AND is_nullable=0 AND is_identity=0)
    OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=2 AND name=N'StudentID' AND system_type_id=56 AND is_nullable=0)
    OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=3 AND name=N'ClubID' AND system_type_id=56 AND is_nullable=0)
    OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=4 AND name=N'JoinDate' AND system_type_id=40 AND is_nullable=0)
    OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=5 AND name=N'EndDate' AND system_type_id=40 AND is_nullable=1)
    THROW 51904, 'STOP: ClubMembership column schema differs from approved DDL.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@TableID AND name=N'PK_ClubMembership' AND type='PK')
    OR NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@TableID AND name=N'UQ_ClubMembership_StudentClubJoinDate' AND type='UQ')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@TableID AND name=N'FK_ClubMembership_Student' AND is_disabled=0 AND is_not_trusted=0)
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@TableID AND name=N'FK_ClubMembership_StudentClub' AND is_disabled=0 AND is_not_trusted=0)
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@TableID AND name=N'CK_ClubMembership_EndDate' AND is_disabled=0 AND is_not_trusted=0)
    OR NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@TableID AND name=N'UX_ClubMembership_OneActivePerStudentClub' AND is_unique=1 AND has_filter=1 AND is_disabled=0)
    THROW 51905, 'STOP: Approved PK/UQ/FK/CHECK/filtered UNIQUE metadata missing or disabled.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.Student) <> 64
    OR EXISTS (SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)
    OR (SELECT COUNT_BIG(*) FROM dbo.StudentClub) <> 8
    OR EXISTS (SELECT 1 FROM dbo.StudentClub WHERE ClubID NOT BETWEEN 1 AND 8)
    THROW 51906, 'STOP: Parent seed baseline differs from 64 students / 8 clubs.', 1;

IF OBJECT_ID(N'tempdb..#ExpectedClubMembership') IS NOT NULL
    DROP TABLE #ExpectedClubMembership;

CREATE TABLE #ExpectedClubMembership
(
    ClubMembershipID BIGINT NOT NULL PRIMARY KEY,
    StudentID INT NOT NULL,
    ClubID INT NOT NULL,
    JoinDate DATE NOT NULL,
    EndDate DATE NULL
);

INSERT INTO #ExpectedClubMembership
    (ClubMembershipID, StudentID, ClubID, JoinDate, EndDate)
VALUES
    (190001, 10001, 1, '2026-09-01', NULL),
    (190002, 10002, 2, '2026-09-01', NULL),
    (190003, 10003, 3, '2026-09-01', NULL),
    (190004, 10004, 4, '2026-09-01', NULL),
    (190005, 10005, 5, '2026-09-01', NULL),
    (190006, 10006, 6, '2026-09-01', NULL),
    (190007, 10007, 7, '2026-09-01', NULL),
    (190008, 10008, 8, '2026-09-01', NULL),
    (190009, 10009, 1, '2026-09-01', NULL),
    (190010, 10010, 2, '2026-09-01', NULL),
    (190011, 10011, 3, '2026-09-01', NULL),
    (190012, 10012, 4, '2026-09-01', NULL),
    (190013, 10013, 5, '2026-09-01', NULL),
    (190014, 10014, 6, '2026-09-01', NULL),
    (190015, 10015, 7, '2026-09-01', NULL),
    (190016, 10016, 8, '2026-09-01', NULL),
    (190017, 10017, 1, '2026-09-01', NULL),
    (190018, 10018, 2, '2026-09-01', NULL),
    (190019, 10019, 3, '2026-09-01', NULL),
    (190020, 10020, 4, '2026-09-01', NULL),
    (190021, 10021, 5, '2026-09-01', NULL),
    (190022, 10022, 6, '2026-09-01', NULL),
    (190023, 10023, 7, '2026-09-01', NULL),
    (190024, 10024, 8, '2026-09-01', NULL),
    (190025, 10025, 1, '2026-09-01', NULL),
    (190026, 10026, 2, '2026-09-01', NULL),
    (190027, 10027, 3, '2026-09-01', NULL),
    (190028, 10028, 4, '2026-09-01', NULL),
    (190029, 10029, 5, '2026-09-01', NULL),
    (190030, 10030, 6, '2026-09-01', NULL),
    (190031, 10031, 7, '2026-09-01', NULL),
    (190032, 10032, 8, '2026-09-01', NULL),
    (190033, 10033, 1, '2026-09-01', NULL),
    (190034, 10034, 2, '2026-09-01', NULL),
    (190035, 10035, 3, '2026-09-01', NULL),
    (190036, 10036, 4, '2026-09-01', NULL),
    (190037, 10037, 5, '2026-09-01', NULL),
    (190038, 10038, 6, '2026-09-01', NULL),
    (190039, 10039, 7, '2026-09-01', NULL),
    (190040, 10040, 8, '2026-09-01', NULL),
    (190041, 10041, 1, '2026-09-01', NULL),
    (190042, 10042, 2, '2026-09-01', NULL),
    (190043, 10043, 3, '2026-09-01', NULL),
    (190044, 10044, 4, '2026-09-01', NULL),
    (190045, 10045, 5, '2026-09-01', NULL),
    (190046, 10046, 6, '2026-09-01', NULL),
    (190047, 10047, 7, '2026-09-01', NULL),
    (190048, 10048, 8, '2026-09-01', NULL),
    (190049, 10001, 2, '2026-09-15', NULL),
    (190050, 10002, 3, '2026-09-15', NULL),
    (190051, 10003, 4, '2026-09-15', NULL),
    (190052, 10004, 5, '2026-09-15', NULL),
    (190053, 10005, 6, '2026-09-15', NULL),
    (190054, 10006, 7, '2026-09-15', NULL),
    (190055, 10007, 8, '2026-09-15', NULL),
    (190056, 10008, 1, '2026-09-15', NULL),
    (190057, 10009, 2, '2026-09-15', NULL),
    (190058, 10010, 3, '2026-09-15', NULL),
    (190059, 10011, 4, '2026-09-15', NULL),
    (190060, 10012, 5, '2026-09-15', NULL),
    (190061, 10013, 6, '2026-09-15', NULL),
    (190062, 10014, 7, '2026-09-15', NULL),
    (190063, 10015, 8, '2026-09-15', NULL),
    (190064, 10016, 1, '2026-09-15', NULL),
    (190065, 10017, 2, '2026-09-15', NULL),
    (190066, 10018, 3, '2026-09-15', NULL),
    (190067, 10019, 4, '2026-09-15', NULL),
    (190068, 10020, 5, '2026-09-15', NULL),
    (190069, 10021, 6, '2026-09-15', NULL),
    (190070, 10022, 7, '2026-09-15', NULL),
    (190071, 10023, 8, '2026-09-15', NULL),
    (190072, 10024, 1, '2026-09-15', NULL),
    (190073, 10041, 1, '2024-09-01', '2025-06-30'),
    (190074, 10042, 2, '2024-09-01', '2025-06-30'),
    (190075, 10043, 3, '2024-09-01', '2025-06-30'),
    (190076, 10044, 4, '2024-09-01', '2025-06-30'),
    (190077, 10045, 5, '2024-09-01', '2025-06-30'),
    (190078, 10046, 6, '2024-09-01', '2025-06-30'),
    (190079, 10047, 7, '2024-09-01', '2025-06-30'),
    (190080, 10048, 8, '2024-09-01', '2025-06-30'),
    (190081, 10049, 1, '2024-09-01', '2025-06-30'),
    (190082, 10050, 2, '2024-09-01', '2025-06-30'),
    (190083, 10051, 3, '2024-09-01', '2025-06-30'),
    (190084, 10052, 4, '2024-09-01', '2025-06-30'),
    (190085, 10053, 5, '2024-09-01', '2025-06-30'),
    (190086, 10054, 6, '2024-09-01', '2025-06-30'),
    (190087, 10055, 7, '2024-09-01', '2025-06-30'),
    (190088, 10056, 8, '2024-09-01', '2025-06-30');

IF (SELECT COUNT_BIG(*) FROM #ExpectedClubMembership) <> 88
    THROW 51907, 'STOP: Seed staging table should contain exactly 88 records.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Exclusive target-table lock: prevents concurrent duplicate population.
    IF EXISTS (SELECT 1 FROM dbo.ClubMembership WITH (TABLOCKX, HOLDLOCK))
        THROW 51908, 'STOP: ClubMembership already has data. No INSERT attempted.', 1;

    INSERT INTO dbo.ClubMembership
        (ClubMembershipID, StudentID, ClubID, JoinDate, EndDate)
    SELECT ClubMembershipID, StudentID, ClubID, JoinDate, EndDate
    FROM #ExpectedClubMembership;

    DECLARE @Inserted INT = @@ROWCOUNT;
    IF @Inserted <> 88 OR (SELECT COUNT_BIG(*) FROM dbo.ClubMembership) <> 88
        THROW 51909, 'STOP: Unexpected number of inserted rows.', 1;

    IF EXISTS (
        SELECT ClubMembershipID, StudentID, ClubID, JoinDate, EndDate FROM #ExpectedClubMembership
        EXCEPT
        SELECT ClubMembershipID, StudentID, ClubID, JoinDate, EndDate FROM dbo.ClubMembership
    ) OR EXISTS (
        SELECT ClubMembershipID, StudentID, ClubID, JoinDate, EndDate FROM dbo.ClubMembership
        EXCEPT
        SELECT ClubMembershipID, StudentID, ClubID, JoinDate, EndDate FROM #ExpectedClubMembership
    )
        THROW 51910, 'STOP: Database rows differ from approved seed; rolled back.', 1;

    COMMIT TRANSACTION;
    PRINT 'SUCCESS: 88 ClubMembership rows inserted and committed; prior tables unchanged.';
    SELECT COUNT_BIG(*) AS ActualRows,
           CONVERT(BIGINT,88) AS ExpectedRows,
           'INSERT COMMITTED' AS InsertResult
    FROM dbo.ClubMembership;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

DROP TABLE #ExpectedClubMembership;
GO
------------------------------
-- Phase 4 | Table 19/21 dbo.ClubMembership — verification ONLY
USE [UniversityManagementDB];
GO
SET NOCOUNT ON;
IF DB_NAME()<>N'UniversityManagementDB'
    THROW 51921, 'STOP: Wrong database selected.', 1;
IF OBJECT_ID(N'dbo.ClubMembership',N'U') IS NULL
    OR OBJECT_ID(N'dbo.Student',N'U') IS NULL
    OR OBJECT_ID(N'dbo.StudentClub',N'U') IS NULL
    THROW 51922, 'STOP: Required table is missing.', 1;

DECLARE @TableID INT=OBJECT_ID(N'dbo.ClubMembership',N'U');
IF OBJECT_ID(N'tempdb..#ExpectedClubMembership') IS NOT NULL DROP TABLE #ExpectedClubMembership;
IF OBJECT_ID(N'tempdb..#Checks') IS NOT NULL DROP TABLE #Checks;

CREATE TABLE #ExpectedClubMembership
(
    ClubMembershipID BIGINT NOT NULL PRIMARY KEY,
    StudentID INT NOT NULL,
    ClubID INT NOT NULL,
    JoinDate DATE NOT NULL,
    EndDate DATE NULL
);

INSERT INTO #ExpectedClubMembership
    (ClubMembershipID, StudentID, ClubID, JoinDate, EndDate)
VALUES
    (190001, 10001, 1, '2026-09-01', NULL),
    (190002, 10002, 2, '2026-09-01', NULL),
    (190003, 10003, 3, '2026-09-01', NULL),
    (190004, 10004, 4, '2026-09-01', NULL),
    (190005, 10005, 5, '2026-09-01', NULL),
    (190006, 10006, 6, '2026-09-01', NULL),
    (190007, 10007, 7, '2026-09-01', NULL),
    (190008, 10008, 8, '2026-09-01', NULL),
    (190009, 10009, 1, '2026-09-01', NULL),
    (190010, 10010, 2, '2026-09-01', NULL),
    (190011, 10011, 3, '2026-09-01', NULL),
    (190012, 10012, 4, '2026-09-01', NULL),
    (190013, 10013, 5, '2026-09-01', NULL),
    (190014, 10014, 6, '2026-09-01', NULL),
    (190015, 10015, 7, '2026-09-01', NULL),
    (190016, 10016, 8, '2026-09-01', NULL),
    (190017, 10017, 1, '2026-09-01', NULL),
    (190018, 10018, 2, '2026-09-01', NULL),
    (190019, 10019, 3, '2026-09-01', NULL),
    (190020, 10020, 4, '2026-09-01', NULL),
    (190021, 10021, 5, '2026-09-01', NULL),
    (190022, 10022, 6, '2026-09-01', NULL),
    (190023, 10023, 7, '2026-09-01', NULL),
    (190024, 10024, 8, '2026-09-01', NULL),
    (190025, 10025, 1, '2026-09-01', NULL),
    (190026, 10026, 2, '2026-09-01', NULL),
    (190027, 10027, 3, '2026-09-01', NULL),
    (190028, 10028, 4, '2026-09-01', NULL),
    (190029, 10029, 5, '2026-09-01', NULL),
    (190030, 10030, 6, '2026-09-01', NULL),
    (190031, 10031, 7, '2026-09-01', NULL),
    (190032, 10032, 8, '2026-09-01', NULL),
    (190033, 10033, 1, '2026-09-01', NULL),
    (190034, 10034, 2, '2026-09-01', NULL),
    (190035, 10035, 3, '2026-09-01', NULL),
    (190036, 10036, 4, '2026-09-01', NULL),
    (190037, 10037, 5, '2026-09-01', NULL),
    (190038, 10038, 6, '2026-09-01', NULL),
    (190039, 10039, 7, '2026-09-01', NULL),
    (190040, 10040, 8, '2026-09-01', NULL),
    (190041, 10041, 1, '2026-09-01', NULL),
    (190042, 10042, 2, '2026-09-01', NULL),
    (190043, 10043, 3, '2026-09-01', NULL),
    (190044, 10044, 4, '2026-09-01', NULL),
    (190045, 10045, 5, '2026-09-01', NULL),
    (190046, 10046, 6, '2026-09-01', NULL),
    (190047, 10047, 7, '2026-09-01', NULL),
    (190048, 10048, 8, '2026-09-01', NULL),
    (190049, 10001, 2, '2026-09-15', NULL),
    (190050, 10002, 3, '2026-09-15', NULL),
    (190051, 10003, 4, '2026-09-15', NULL),
    (190052, 10004, 5, '2026-09-15', NULL),
    (190053, 10005, 6, '2026-09-15', NULL),
    (190054, 10006, 7, '2026-09-15', NULL),
    (190055, 10007, 8, '2026-09-15', NULL),
    (190056, 10008, 1, '2026-09-15', NULL),
    (190057, 10009, 2, '2026-09-15', NULL),
    (190058, 10010, 3, '2026-09-15', NULL),
    (190059, 10011, 4, '2026-09-15', NULL),
    (190060, 10012, 5, '2026-09-15', NULL),
    (190061, 10013, 6, '2026-09-15', NULL),
    (190062, 10014, 7, '2026-09-15', NULL),
    (190063, 10015, 8, '2026-09-15', NULL),
    (190064, 10016, 1, '2026-09-15', NULL),
    (190065, 10017, 2, '2026-09-15', NULL),
    (190066, 10018, 3, '2026-09-15', NULL),
    (190067, 10019, 4, '2026-09-15', NULL),
    (190068, 10020, 5, '2026-09-15', NULL),
    (190069, 10021, 6, '2026-09-15', NULL),
    (190070, 10022, 7, '2026-09-15', NULL),
    (190071, 10023, 8, '2026-09-15', NULL),
    (190072, 10024, 1, '2026-09-15', NULL),
    (190073, 10041, 1, '2024-09-01', '2025-06-30'),
    (190074, 10042, 2, '2024-09-01', '2025-06-30'),
    (190075, 10043, 3, '2024-09-01', '2025-06-30'),
    (190076, 10044, 4, '2024-09-01', '2025-06-30'),
    (190077, 10045, 5, '2024-09-01', '2025-06-30'),
    (190078, 10046, 6, '2024-09-01', '2025-06-30'),
    (190079, 10047, 7, '2024-09-01', '2025-06-30'),
    (190080, 10048, 8, '2024-09-01', '2025-06-30'),
    (190081, 10049, 1, '2024-09-01', '2025-06-30'),
    (190082, 10050, 2, '2024-09-01', '2025-06-30'),
    (190083, 10051, 3, '2024-09-01', '2025-06-30'),
    (190084, 10052, 4, '2024-09-01', '2025-06-30'),
    (190085, 10053, 5, '2024-09-01', '2025-06-30'),
    (190086, 10054, 6, '2024-09-01', '2025-06-30'),
    (190087, 10055, 7, '2024-09-01', '2025-06-30'),
    (190088, 10056, 8, '2024-09-01', '2025-06-30');

CREATE TABLE #Checks(CheckID INT NOT NULL PRIMARY KEY, Item NVARCHAR(200) NOT NULL, Result VARCHAR(4) NOT NULL);

INSERT INTO #Checks(CheckID, Item, Result)
SELECT 1, N'Approved five columns, order, type and nullability', CASE WHEN ((SELECT COUNT(*) FROM sys.columns WHERE object_id=@TableID)=5
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=1 AND name=N'ClubMembershipID' AND system_type_id=127 AND is_nullable=0 AND is_identity=0)
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=2 AND name=N'StudentID' AND system_type_id=56 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=3 AND name=N'ClubID' AND system_type_id=56 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=4 AND name=N'JoinDate' AND system_type_id=40 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@TableID AND column_id=5 AND name=N'EndDate' AND system_type_id=40 AND is_nullable=1)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 2, N'Approved primary key on ClubMembershipID only', CASE WHEN ((SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@TableID AND type='PK')=1
 AND EXISTS(SELECT 1 FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE k.parent_object_id=@TableID AND k.name=N'PK_ClubMembership' AND k.type='PK' AND ic.key_ordinal=1 AND c.name=N'ClubMembershipID')
 AND (SELECT COUNT(*) FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id WHERE k.parent_object_id=@TableID AND k.type='PK' AND ic.key_ordinal>0)=1) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 3, N'Approved UNIQUE StudentID ClubID JoinDate in order', CASE WHEN ((SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@TableID AND type='UQ')=1
 AND EXISTS(SELECT 1 FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE k.parent_object_id=@TableID AND k.name=N'UQ_ClubMembership_StudentClubJoinDate' AND k.type='UQ' AND ic.key_ordinal=1 AND c.name=N'StudentID')
 AND EXISTS(SELECT 1 FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE k.parent_object_id=@TableID AND k.name=N'UQ_ClubMembership_StudentClubJoinDate' AND k.type='UQ' AND ic.key_ordinal=2 AND c.name=N'ClubID')
 AND EXISTS(SELECT 1 FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE k.parent_object_id=@TableID AND k.name=N'UQ_ClubMembership_StudentClubJoinDate' AND k.type='UQ' AND ic.key_ordinal=3 AND c.name=N'JoinDate')
 AND (SELECT COUNT(*) FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id WHERE k.parent_object_id=@TableID AND k.type='UQ' AND ic.key_ordinal>0)=3) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 4, N'Exactly two enabled trusted FKs with proper mappings', CASE WHEN ((SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@TableID)=2
 AND EXISTS(SELECT 1 FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id WHERE fk.parent_object_id=@TableID AND fk.name=N'FK_ClubMembership_Student' AND fk.referenced_object_id=OBJECT_ID(N'dbo.Student') AND fk.is_disabled=0 AND fk.is_not_trusted=0 AND pc.name=N'StudentID' AND rc.name=N'StudentID')
 AND EXISTS(SELECT 1 FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id WHERE fk.parent_object_id=@TableID AND fk.name=N'FK_ClubMembership_StudentClub' AND fk.referenced_object_id=OBJECT_ID(N'dbo.StudentClub') AND fk.is_disabled=0 AND fk.is_not_trusted=0 AND pc.name=N'ClubID' AND rc.name=N'ClubID')
 AND (SELECT COUNT(*) FROM sys.foreign_key_columns fkc JOIN sys.foreign_keys fk ON fk.object_id=fkc.constraint_object_id WHERE fk.parent_object_id=@TableID)=2) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 5, N'Approved CHECK EndDate >= JoinDate enabled/trusted', CASE WHEN ((SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=@TableID)=1
 AND EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@TableID AND name=N'CK_ClubMembership_EndDate' AND is_disabled=0 AND is_not_trusted=0 AND definition LIKE N'%EndDate%JoinDate%')) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 6, N'Approved filtered UNIQUE index enabled, key and filter', CASE WHEN (EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=@TableID AND i.name=N'UX_ClubMembership_OneActivePerStudentClub' AND i.is_unique=1 AND i.has_filter=1 AND i.is_disabled=0 AND i.filter_definition LIKE N'%EndDate%IS NULL%')
 AND EXISTS(SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=@TableID AND i.name=N'UX_ClubMembership_OneActivePerStudentClub' AND ic.key_ordinal=1 AND c.name=N'StudentID')
 AND EXISTS(SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=@TableID AND i.name=N'UX_ClubMembership_OneActivePerStudentClub' AND ic.key_ordinal=2 AND c.name=N'ClubID')
 AND (SELECT COUNT(*) FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id WHERE i.object_id=@TableID AND i.name=N'UX_ClubMembership_OneActivePerStudentClub' AND ic.key_ordinal>0)=2) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 7, N'No unexpected UNIQUE indexes', CASE WHEN ((SELECT COUNT(*) FROM sys.indexes WHERE object_id=@TableID AND is_unique=1 AND is_hypothetical=0)=3) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 8, N'Parent Student baseline 64 students 10001-10064', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.Student)=64 AND NOT EXISTS(SELECT 1 FROM dbo.Student WHERE StudentID NOT BETWEEN 10001 AND 10064)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 9, N'Parent StudentClub baseline 8 clubs IDs 1-8', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.StudentClub)=8 AND NOT EXISTS(SELECT 1 FROM dbo.StudentClub WHERE ClubID NOT BETWEEN 1 AND 8)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 10, N'Exact row count 88', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.ClubMembership)=88) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 11, N'Exact 88-row seed no missing extra altered records', CASE WHEN (NOT EXISTS(SELECT ClubMembershipID,StudentID,ClubID,JoinDate,EndDate FROM #ExpectedClubMembership EXCEPT SELECT ClubMembershipID,StudentID,ClubID,JoinDate,EndDate FROM dbo.ClubMembership)
 AND NOT EXISTS(SELECT ClubMembershipID,StudentID,ClubID,JoinDate,EndDate FROM dbo.ClubMembership EXCEPT SELECT ClubMembershipID,StudentID,ClubID,JoinDate,EndDate FROM #ExpectedClubMembership)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 12, N'All membership Student and Club references valid', CASE WHEN (NOT EXISTS(SELECT 1 FROM dbo.ClubMembership m LEFT JOIN dbo.Student s ON s.StudentID=m.StudentID LEFT JOIN dbo.StudentClub c ON c.ClubID=m.ClubID WHERE s.StudentID IS NULL OR c.ClubID IS NULL)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 13, N'All date ranges valid', CASE WHEN (NOT EXISTS(SELECT 1 FROM dbo.ClubMembership WHERE EndDate < JoinDate)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 14, N'72 current and 16 historical-ended memberships', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.ClubMembership WHERE EndDate IS NULL)=72
 AND (SELECT COUNT_BIG(*) FROM dbo.ClubMembership WHERE EndDate IS NOT NULL)=16) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 15, N'Each of 8 clubs has nine current and two ended members', CASE WHEN (NOT EXISTS(SELECT c.ClubID FROM dbo.StudentClub c LEFT JOIN dbo.ClubMembership m ON m.ClubID=c.ClubID GROUP BY c.ClubID HAVING SUM(CASE WHEN m.ClubMembershipID IS NOT NULL AND m.EndDate IS NULL THEN 1 ELSE 0 END)<>9 OR SUM(CASE WHEN m.EndDate IS NOT NULL THEN 1 ELSE 0 END)<>2)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 16, N'Student current distribution: 24 two, 24 one, 16 zero', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.Student s OUTER APPLY (SELECT COUNT_BIG(*) AS N FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NULL) q WHERE q.N=2)=24
 AND (SELECT COUNT_BIG(*) FROM dbo.Student s OUTER APPLY (SELECT COUNT_BIG(*) AS N FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NULL) q WHERE q.N=1)=24
 AND (SELECT COUNT_BIG(*) FROM dbo.Student s OUTER APPLY (SELECT COUNT_BIG(*) AS N FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NULL) q WHERE q.N=0)=16) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 17, N'Eight former-only and eight never-joined students', CASE WHEN ((SELECT COUNT_BIG(*) FROM dbo.Student s WHERE EXISTS(SELECT 1 FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NULL))=8
 AND (SELECT COUNT_BIG(*) FROM dbo.Student s WHERE NOT EXISTS(SELECT 1 FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID))=8) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 18, N'Eight historical members rejoined same club', CASE WHEN ((SELECT COUNT_BIG(*) FROM (SELECT StudentID,ClubID FROM dbo.ClubMembership GROUP BY StudentID,ClubID HAVING SUM(CASE WHEN EndDate IS NULL THEN 1 ELSE 0 END)=1 AND SUM(CASE WHEN EndDate IS NOT NULL THEN 1 ELSE 0 END)=1) r)=8) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 19, N'No duplicate current StudentID/ClubID pair', CASE WHEN (NOT EXISTS(SELECT 1 FROM dbo.ClubMembership WHERE EndDate IS NULL GROUP BY StudentID,ClubID HAVING COUNT_BIG(*)>1)) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 20, N'No overlapping date intervals for same student-club', CASE WHEN (NOT EXISTS(SELECT 1 FROM dbo.ClubMembership a JOIN dbo.ClubMembership b ON a.StudentID=b.StudentID AND a.ClubID=b.ClubID AND a.ClubMembershipID<b.ClubMembershipID WHERE a.JoinDate <= ISNULL(b.EndDate,CONVERT(date,'9999-12-31',23)) AND b.JoinDate <= ISNULL(a.EndDate,CONVERT(date,'9999-12-31',23)))) THEN 'PASS' ELSE 'FAIL' END;
INSERT INTO #Checks(CheckID, Item, Result)
SELECT 21, N'No duplicate student club join-date tuple', CASE WHEN (NOT EXISTS(SELECT 1 FROM dbo.ClubMembership GROUP BY StudentID,ClubID,JoinDate HAVING COUNT_BIG(*)>1)) THEN 'PASS' ELSE 'FAIL' END;

-- Main outcome and validation detail.
SELECT N'ClubMembership: Exact Row Set + Schema + PK + FK + UQ + CHECK + Filtered Index' AS VerificationTest,
       CASE WHEN NOT EXISTS(SELECT 1 FROM #Checks WHERE Result='FAIL') THEN 'PASS' ELSE 'FAIL' END AS VerificationResult,
       (SELECT COUNT_BIG(*) FROM dbo.ClubMembership) AS ActualRows,
       CONVERT(BIGINT,88) AS ExpectedRows,
       (SELECT COUNT(*) FROM #Checks) AS ChecksEvaluated,
       (SELECT COUNT(*) FROM #Checks WHERE Result='FAIL') AS FailedChecks;

SELECT CheckID,Item,Result FROM #Checks ORDER BY CheckID;

-- Samples and BI-friendly summaries.
SELECT TOP(20) m.ClubMembershipID,m.StudentID,s.[Name] AS StudentName,
       m.ClubID,c.ClubName,m.JoinDate,m.EndDate,
       CASE WHEN m.EndDate IS NULL THEN 'Current' ELSE 'Ended' END AS MembershipStatus
FROM dbo.ClubMembership m
JOIN dbo.Student s ON s.StudentID=m.StudentID
JOIN dbo.StudentClub c ON c.ClubID=m.ClubID
ORDER BY m.ClubMembershipID;

SELECT c.ClubID,c.ClubName,
       SUM(CASE WHEN m.ClubMembershipID IS NOT NULL AND m.EndDate IS NULL THEN 1 ELSE 0 END) AS CurrentMemberships,
       SUM(CASE WHEN m.EndDate IS NOT NULL THEN 1 ELSE 0 END) AS EndedMemberships,
       COUNT(m.ClubMembershipID) AS AllMembershipRecords
FROM dbo.StudentClub c
LEFT JOIN dbo.ClubMembership m ON m.ClubID=c.ClubID
GROUP BY c.ClubID,c.ClubName ORDER BY c.ClubID;

SELECT q.CurrentClubCount, COUNT_BIG(*) AS Students
FROM dbo.Student s
CROSS APPLY (SELECT COUNT_BIG(*) AS CurrentClubCount FROM dbo.ClubMembership m WHERE m.StudentID=s.StudentID AND m.EndDate IS NULL) q
GROUP BY q.CurrentClubCount ORDER BY q.CurrentClubCount;

SELECT m.StudentID,m.ClubID,COUNT_BIG(*) AS MembershipPeriods,
       MIN(m.JoinDate) AS FirstJoinDate,
       MAX(m.JoinDate) AS MostRecentJoinDate
FROM dbo.ClubMembership m
GROUP BY m.StudentID,m.ClubID HAVING COUNT_BIG(*)>1
ORDER BY m.StudentID,m.ClubID;

SELECT c.column_id AS ColumnOrder,c.name AS ColumnName,TYPE_NAME(c.user_type_id) AS DataType,
       c.max_length AS LengthBytes,c.is_nullable AS IsNullable
FROM sys.columns c WHERE c.object_id=@TableID ORDER BY c.column_id;

SELECT fk.name AS ForeignKeyName,OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
       fk.is_disabled AS IsDisabled,fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk WHERE fk.parent_object_id=@TableID ORDER BY fk.name;

SELECT i.name AS IndexName,i.is_unique AS IsUnique,i.has_filter AS HasFilter,
       i.filter_definition AS FilterDefinition,i.is_disabled AS IsDisabled
FROM sys.indexes i WHERE i.object_id=@TableID AND i.is_unique=1 ORDER BY i.name;

DROP TABLE #Checks;
DROP TABLE #ExpectedClubMembership;
GO
-------------------------------------------
GO
