--http://jongurgul.com/blog/sql-server-login-password-hash
USE [tempdb]
GO
IF NOT EXISTS(SELECT * FROM [tempdb].sys.tables WHERE name = 'WordList')
BEGIN
 CREATE TABLE [dbo].[WordList]([Plain] NVARCHAR(MAX))
 
 --USERNAME//PASSWORD COMBOS
 INSERT INTO [WordList]([Plain])
 SELECT [name] FROM sys.sql_logins
 UNION
 SELECT REPLACE(REPLACE(REPLACE([name],'o','0'),'i','1'),'e','3') FROM sys.sql_logins
 UNION
 SELECT REPLACE(REPLACE(REPLACE([name],'o','0'),'i','1'),'e','3')+'.' FROM sys.sql_logins --example added character
 UNION
 SELECT REPLACE(REPLACE(REPLACE([name],'o','0'),'i','1'),'e','3')+'!' FROM sys.sql_logins --example added character
 
 --No Comment
 INSERT INTO [WordList]([Plain]) VALUES (N'')
 INSERT INTO [WordList]([Plain]) VALUES (N'password')
 INSERT INTO [WordList]([Plain]) VALUES (N'sa')
 INSERT INTO [WordList]([Plain]) VALUES (N'dev')
 INSERT INTO [WordList]([Plain]) VALUES (N'test')
END
--DECLARE @Algorithm VARCHAR(10)
--SET @Algorithm = CASE WHEN @@MICROSOFTVERSION/0x01000000 >= 11 THEN 'SHA2_512' ELSE 'SHA1' END
 
SELECT
 s.[name]
,s.[password_hash]
,SUBSTRING(s.[password_hash],1,2) [Algorithm]
,SUBSTRING(s.[password_hash],3,4) [Salt]
,SUBSTRING(s.[password_hash],7,(LEN(s.[password_hash])-6)) [Hash]
,HASHBYTES(a.[Algorithm],CAST(w.[Plain] AS VARBINARY(MAX))+SUBSTRING(s.[password_hash],3,4)) [ComputedHash]
--,HASHBYTES(@Algorithm,CAST(w.[Plain] AS VARBINARY(MAX))+SUBSTRING([password_hash],3,4)) [ComputedHash]
,w.[Plain]
FROM sys.sql_logins s
INNER JOIN (
SELECT 0x0100 [AlgorithmVersion],'SHA1' [Algorithm] UNION ALL
SELECT 0x0200,'SHA2_512'
) a ON a.[AlgorithmVersion] = SUBSTRING(s.[password_hash],1,2)
INNER JOIN [tempdb].[dbo].[WordList] w
ON SUBSTRING(s.[password_hash],7,(LEN(s.[password_hash])-6)) = HASHBYTES(a.[Algorithm],CAST(w.[Plain] AS VARBINARY(MAX))+SUBSTRING(s.[password_hash],3,4))
--ON SUBSTRING([password_hash],7,(LEN([password_hash])-6)) = HASHBYTES(@Algorithm,CAST(w.[Plain] AS VARBINARY(MAX))+SUBSTRING([password_hash],3,4))

IF EXISTS(SELECT * FROM [tempdb].sys.tables WHERE name = 'WordList')
BEGIN
 DROP TABLE [tempdb].[dbo].[WordList]
END
GO
SELECT
[name]
,[password_hash]
,SUBSTRING([password_hash],1,2) [Algorithm]
,SUBSTRING([password_hash],3,4) [Salt]
,SUBSTRING([password_hash],7,(LEN([password_hash])-6)) [Hash]
FROM sys.sql_logins
GO

