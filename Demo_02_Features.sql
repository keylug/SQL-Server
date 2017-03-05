/*
Slava Murygin

Demo for "SQL Server on Linux"

2017-02-01
*/

/*
Creadit for ideas to Adam Machanic
*/


-- String Split:
SELECT * FROM STRING_SPLIT('We can do it on Linux!', ' ')
GO


-- Session Context:
DECLARE @SessionContext VARBINARY(128) = CONVERT(VARBINARY, 'This is SQL Server on Linux!')
SET CONTEXT_INFO @SessionContext
GO

SELECT CONTEXT_INFO()
GO

SELECT CAST(CONTEXT_INFO() as VARCHAR)
GO


/*------------------------------------------------------------------------------
Temporal tables
------------------------------------------------------------------------------*/

USE tempdb
GO
IF EXISTS ( SELECT * FROM sys.tables WHERE name = 'tbl_Temporal')
BEGIN
	ALTER TABLE [dbo].tbl_Temporal SET ( SYSTEM_VERSIONING = OFF )

	DROP TABLE [dbo].tbl_Temporal
END
GO
CREATE TABLE [dbo].tbl_Temporal
(
	F1 INT NOT NULL PRIMARY KEY, F2 INT,
	start_datetime DATETIME2 GENERATED ALWAYS AS ROW START, 
	end_datetime DATETIME2 GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME (start_datetime, end_datetime),
)
WITH (SYSTEM_VERSIONING = ON)
GO

INSERT [dbo].tbl_Temporal (F1, F2) VALUES (1,2),(3,4)
GO
SELECT * FROM [dbo].tbl_Temporal;
GO

UPDATE [dbo].tbl_Temporal 
SET F2 = 123 WHERE F1 = 1;
GO
DELETE [dbo].tbl_Temporal WHERE F1 = 3;
GO
SELECT * FROM [dbo].tbl_Temporal
GO

SELECT * FROM [dbo].tbl_Temporal 
FOR SYSTEM_TIME BETWEEN '2016-12-01' AND '9999-12-31'
ORDER BY F1, start_datetime
GO

ALTER TABLE [dbo].tbl_Temporal SET ( SYSTEM_VERSIONING = OFF )
GO
DROP TABLE [dbo].tbl_Temporal
GO


-- Timezone Info
SELECT * FROM sys.time_zone_info
GO
/*------------------------------------------------------------------------------
Row Level Security
------------------------------------------------------------------------------*/
use tempdb
GO
DROP SECURITY POLICY IF EXISTS SalesFilter;
DROP FUNCTION IF EXISTS Security.fn_securitypredicate;
DROP SCHEMA IF EXISTS Security;
DROP TABLE IF EXISTS Sales;
GO
CREATE TABLE Sales  
    (  
    OrderID int,  
    SalesRep sysname,  
    Product varchar(10),  
    Qty int  
    );  
GO
INSERT Sales VALUES   
(1, 'Sales1', 'Valve', 5),   
(2, 'Sales1', 'Wheel', 2),   
(3, 'Sales1', 'Valve', 4),  
(4, 'Sales2', 'Bracket', 2),   
(5, 'Sales2', 'Wheel', 5),   
(6, 'Sales2', 'Seat', 5);  
-- View the 6 rows in the table  
SELECT * FROM Sales;  
GO
DROP USER IF EXISTS Manager;
DROP USER IF EXISTS Sales1;
DROP USER IF EXISTS Sales2;  
CREATE USER Manager WITHOUT LOGIN;  
CREATE USER Sales1 WITHOUT LOGIN;  
CREATE USER Sales2 WITHOUT LOGIN;  
GRANT SELECT ON Sales TO Manager;  
GRANT SELECT ON Sales TO Sales1;  
GRANT SELECT ON Sales TO Sales2;  
GO
CREATE SCHEMA Security;  
GO  
CREATE FUNCTION Security.fn_securitypredicate(@SalesRep AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result   
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager';  
GO
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate(SalesRep)   
ON dbo.Sales  
WITH (STATE = ON); 
GO
-------------------------------------------
EXECUTE AS USER = 'Sales1';  
SELECT * FROM Sales;   
REVERT;  
  
EXECUTE AS USER = 'Sales2';  
SELECT * FROM Sales;   
REVERT;  
  
EXECUTE AS USER = 'Manager';  
SELECT * FROM Sales;   
REVERT;  

/*------------------------------------------------------------------------------
Dynamic data masking
------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS Membership;
GO
CREATE TABLE Membership  
  (MemberID int IDENTITY PRIMARY KEY,  
   FirstName varchar(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,  
   LastName varchar(100) NOT NULL,  
   Phone# varchar(12) MASKED WITH (FUNCTION = 'default()') NULL,  
   Email varchar(100) MASKED WITH (FUNCTION = 'email()') NULL);  
GO
INSERT Membership (FirstName, LastName, Phone#, Email) VALUES   
('Roberto', 'Tamburello', '555.123.4567', 'RTamburello@contoso.com'),  
('Janice', 'Galvin', '555.123.4568', 'JGalvin@contoso.com.co'),  
('Zheng', 'Mu', '555.123.4569', 'ZMu@contoso.net');  
SELECT * FROM Membership;  
GO
DROP USER IF EXISTS TestUser;
GO
CREATE USER TestUser WITHOUT LOGIN;  
GRANT SELECT ON Membership TO TestUser;  
GO
EXECUTE AS USER = 'TestUser';  
SELECT * FROM Membership;  
REVERT;  
GO

/*------------------------------------------------------------------------------
Database scoped configuration
------------------------------------------------------------------------------*/
SELECT 
	configuration_id, 
	name, 
	value, 
	value_for_secondary
FROM sys.database_scoped_configurations
GO

/*------------------------------------------------------------------------------
Data compression
------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS dbo.tbl_Compression
GO
CREATE TABLE dbo.tbl_Compression
(
	F1 INT IDENTITY(1,1) NOT NULL,
	F2 VARCHAR(MAX)
)
GO
INSERT dbo.tbl_Compression (F2)
SELECT TOP(100000)
	REPLICATE('a', 4000)
FROM sys.messages as a, sys.messages as b;
GO

EXEC sp_spaceused 'dbo.tbl_Compression'
GO

CREATE CLUSTERED INDEX F1 ON dbo.tbl_Compression (F1) 
WITH (DATA_COMPRESSION = PAGE)
GO
EXEC sp_spaceused 'dbo.tbl_Compression'
GO

SELECT 2248 * 100./ 400136 

DROP TABLE IF EXISTS dbo.tbl_Compression
GO
---------------------------------------------------------------------------
SELECT DATALENGTH (
	COMPRESS(
		REPLICATE(CONVERT(VARCHAR(MAX), 'xyz'), 100000)
		)
	)
GO


/*------------------------------------------------------------------------------
JSON support
------------------------------------------------------------------------------*/
DECLARE @json NVARCHAR(4000)
SET @json = 
N'{
    "info":{  
      "type":1,

      "address":{  
        "town":"Linthicum",
        "county":"Anne Arundel County",
        "state":"Maryland"
      },
      "tags":["SQL Server", "Linux"]
   },
   "type":"User Group"
}'

SELECT
  JSON_VALUE(@json, '$.type') as type,
  JSON_VALUE(@json, '$.info.address.town') as town,
  JSON_QUERY(@json, '$.info.tags') as tags

/*------------------------------------------------------------------------------
Trimming
------------------------------------------------------------------------------*/
-- Try 1
DECLARE @C CHAR(10) = '   ABC    ';
PRINT 'My First Sample is: "' + @C + '"';
GO
-- Try 2
DECLARE @C CHAR(10) = '   ABC    ';
PRINT 'My Second Sample is: "' + RTRIM(LTRIM(@C)) + '"';
GO
-- Try 3
DECLARE @C CHAR(10) = '   ABC    ';
PRINT 'My new nicew Trimming: "' + TRIM(@C) + '"';
GO
/*------------------------------------------------------------------------------
String Concatenation
------------------------------------------------------------------------------*/
DECLARE @A VARCHAR(10) = 'ABC';
DECLARE @B VARCHAR(10) = 'DEF';
DECLARE @C VARCHAR(10) = 'GHJ';
PRINT CONCAT_WS(';', @A, @B, @C);
GO
/*------------------------------------------------------------------------------
String Aggregation
------------------------------------------------------------------------------*/
-- Try 1
SELECT SUBSTRING(
	(SELECT ', ' + name FROM master.sys.tables
	FOR XML PATH(''))
	,3,8000);
GO
-- Try 2
SELECT STRING_AGG(name, ', ') FROM master.sys.tables;
GO
/*------------------------------------------------------------------------------
Translation 
------------------------------------------------------------------------------*/
PRINT TRANSLATE ( 'This is my unencrypted message',   
'abcdefghijklmnopqrstuvwxyz',
'mnopqrstuvwxyzabcdefghijkl' );
GO
PRINT TRANSLATE ('ftue ue yk gzqzodkbfqp yqeemsq',   
'mnopqrstuvwxyzabcdefghijkl',
'abcdefghijklmnopqrstuvwxyz');
GO
