/*
Slava Murygin

Demo for "SQL Server on Linux"

2017-02-01
*/
SELECT @@VERSION;
GO
USE [master]
GO
RESTORE DATABASE [AdventureWorks2014] 
FROM  DISK = N'C:\var\opt\mssql\data\AdventureWorks2014.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2014_Data' TO N'C:\var\opt\mssql\data\AdventureWorks2014_Data.mdf',  
MOVE N'AdventureWorks2014_Log' TO N'C:\var\opt\mssql\data\AdventureWorks2014_Log.ldf',  
NOUNLOAD,  STATS = 1
GO



