/*
Slava Murygin

Demo for "SQL Server on Linux"

2017-02-01
*/

/*
Demo

Name: Demonstrate performance

*/
-- 1. Start file TestStart.bat
-- 2. Show woting results
-- 3. Insert very first value into 
USE LinuxTest
GO
INSERT INTO [dbo].[tbl_Transactions](c1,c2) 
SELECT IsNull(MAX(c1),0)+1, (IsNull(MAX(c1),0) 
	+ datepart(MILLISECOND, getdate()))  % 2
FROM [dbo].[tbl_Transactions];  

-- 4. Show voting results
-- 5. Press any key in TestStart.bat
-- 6. Show voting results

-- 7. Increase number of transactions 10 times
-- UPDATE [dbo].[tbl_Multiplier] SET MP = 10;
UPDATE [dbo].[tbl_Multiplier] SET MP = 10*MP;

-- Cleanup
UPDATE [dbo].[tbl_Multiplier] SET MP = 1, RecordCount = 0;
DELETE FROM [dbo].[tbl_Transactions];