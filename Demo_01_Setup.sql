/*
Slava Murygin

Demo for "SQL Server on Linux"

2017-02-01
*/

use Master;
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.sql_logins WHERE name = 'LinuxTest')
BEGIN
	DROP LOGIN LinuxTest;
END
GO
CREATE LOGIN LinuxTest with PASSWORD= N'LinuxTe@t1';
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE name = 'LinuxTest')
BEGIN
  ALTER DATABASE LinuxTest SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE 
  DROP DATABASE LinuxTest
END
GO
/*
CREATE DATABASE LinuxTest 
ON  PRIMARY 
( NAME = N'LinuxTest', FILENAME = N'C:\var\opt\mssql\UserData\LinuxTest.mdf' , SIZE = 1GB , FILEGROWTH = 100MB )
 LOG ON 
( NAME = N'LinuxTest_log', FILENAME = N'C:\var\opt\mssql\UserData\LinuxTest_log.ldf' , SIZE = 1GB , FILEGROWTH = 100MB);
GO
*/

/*
USE [master]
GO
CREATE DATABASE [LinuxTest] ON 
( FILENAME = N'C:\var\opt\mssql\UserData\LinuxTest.mdf' ),
( FILENAME = N'C:\var\opt\mssql\UserData\LinuxTest_log.ldf' )
 FOR ATTACH
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [LinuxTest]
GO
-- sp_detach_db [LinuxTest]
*/

CREATE DATABASE LinuxTest 
ON  PRIMARY 
( NAME = N'LinuxTest', FILENAME = N'C:\var\opt\mssql\data\LinuxTest.mdf' , SIZE = 1GB , FILEGROWTH = 100MB )
 LOG ON 
( NAME = N'LinuxTest_log', FILENAME = N'C:\var\opt\mssql\data\LinuxTest_log.ldf' , SIZE = 1GB , FILEGROWTH = 100MB);
GO

ALTER DATABASE LinuxTest SET RECOVERY SIMPLE;
GO
ALTER DATABASE LinuxTest ADD FILEGROUP [imoltp_mod]  
    CONTAINS MEMORY_OPTIMIZED_DATA;  
GO
/*
ALTER DATABASE LinuxTest ADD FILE  
    (name = [imoltp_dir], filename= 'C:\var\opt\mssql\UserData\imoltp_dir')  
    TO FILEGROUP imoltp_mod; 
GO
*/
ALTER DATABASE LinuxTest ADD FILE  
    (name = [imoltp_dir], filename= 'C:\var\opt\mssql\data\imoltp_dir')  
    TO FILEGROUP imoltp_mod; 
GO
USE LinuxTest;
GO
DROP USER IF EXISTS [LinuxTest];
GO
CREATE USER [LinuxTest] FOR LOGIN [LinuxTest] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [LinuxTest]
GO
DROP PROCEDURE IF EXISTS usp_TranTest;
GO
DROP PROCEDURE IF EXISTS [dbo].usp_TranReport;
GO
DROP TABLE IF EXISTS tbl_Transactions;
GO
DROP TABLE IF EXISTS tbl_Multiplier;
GO
CREATE TABLE [dbo].[tbl_Multiplier] (
	ID INT NOT NULL PRIMARY KEY NONCLUSTERED,
	MP INT NOT NULL,
	RecordCount INT NOT NULL,
	TS DATETIME NOT NULL) 
	WITH (MEMORY_OPTIMIZED=ON, DURABILITY = SCHEMA_AND_DATA);  
GO
INSERT INTO [dbo].[tbl_Multiplier](ID,MP,RecordCount,TS) VALUES (1,10,0,GetDate());
GO
CREATE TABLE [dbo].[tbl_Transactions] (  
  c1 INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT=1000000),  
  c2 TINYINT NOT NULL  
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY = SCHEMA_AND_DATA);  
GO
CREATE PROCEDURE [dbo].usp_TranTest  
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
  AS   
  BEGIN ATOMIC   
  WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')  
  DECLARE @i INT, 
	@rowcount INT; 
  SELECT @rowcount = MAX(MP) FROM [dbo].tbl_Multiplier;
  SELECT @i = IsNull(MAX(c1),0)+1, @rowcount += @i FROM [dbo].[tbl_Transactions];  
  WHILE @i < @rowcount  
  BEGIN;  
    INSERT INTO [dbo].[tbl_Transactions](c1,c2) 
	SELECT @i, (datepart(MILLISECOND, getdate()))  % 2
    SET @i += 1;  
  END;  
END;  
GO
CREATE PROCEDURE [dbo].usp_TranReport  
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
  AS   
  BEGIN ATOMIC   
  WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')  

	DECLARE @CT DATETIME = GetDate()
	DECLARE @CNT INT, @WND INT;
	SELECT @CNT = COUNT(*), @WND = ISNULL(SUM(c2),0), @CT = GetDAte()
	FROM [dbo].[tbl_Transactions];

	SELECT 'Linux' = CAST(CAST( CASE @CNT WHEN 0 THEN 50 ELSE (@CNT - @WND) * 100. / @CNT END as DECIMAL(6,3)) as CHAR(7)) + '%'
		, 'Windows' = CAST(CAST( CASE @CNT WHEN 0 THEN 50 ELSE @WND * 100. / @CNT END as DECIMAL(6,3)) as CHAR(7)) + '%'
		, 'Total' = RTRIM(CAST(@CNT as CHAR(8))) + ' Records'
		, 'Per Second' = CAST(CAST( (@CNT - RecordCount)*1000/DATEDIFF(MILLISECOND, TS, @CT) as DECIMAL(9,3)) as VARCHAR)
	FROM [dbo].[tbl_Multiplier]
  
	UPDATE [dbo].[tbl_Multiplier]
	SET RecordCount = @CNT, TS = @CT;
END;

/*
CREATE TABLE LinuxTest.dbo.tbl_Transactions (
	ID INT IDENTITY(1,1) PRIMARY KEY, 
	A CHAR(1)
);
GO
*/