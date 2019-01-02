--https://social.msdn.microsoft.com/Forums/sqlserver/en-US/e7056ca8-94cd-4d36-a676-04c64bf96330/decrypt-the-encrypted-store-procedure-through-the-tsql-programming-in-sql-server-2005?forum=transactsql
--http://jongurgul.com/blog/sql-object-decryption/
DECLARE @EncObj VARBINARY(MAX),@DummyEncObj VARBINARY(MAX),@ObjectNameStmTemplate NVARCHAR(MAX)
SET NOCOUNT ON
/*
--You must be using a DAC.
SELECT * FROM sys.dm_exec_connections ec JOIN sys.endpoints e
on (ec.[endpoint_id]=e.[endpoint_id])
WHERE e.[name]='Dedicated Admin Connection'
AND ec.[session_id] = @@SPID
*/
USE [master] --change to where your encrypted object resides
DECLARE @object_id INT,@name sysname
SELECT @object_id = [object_id],@name = [name] 
FROM sys.all_objects 
WHERE name = N'jjj' --<=Either put your object name here or make sure @object_id is set, and that the object it relates to is encrypted.

SELECT TOP 1 
 @ObjectNameStmTemplate = [ObjectStmTemplate]
,@EncObj = [imageval]
FROM
(
SELECT
SPACE(1)+
(
CASE WHEN [type] = 'P' THEN N'PROCEDURE'
WHEN [type] = 'V' THEN 'VIEW'
WHEN [type] IN ('FN','TF','IF') THEN N'FUNCTION'
WHEN [type] IN ('TR') THEN N'TRIGGER'
ELSE [type]
END
)
+SPACE(1)+QUOTENAME(SCHEMA_NAME([schema_id]))+'.'+QUOTENAME(ao.[name])+SPACE(1)+
(
CASE WHEN [type] = 'P' THEN N'WITH ENCRYPTION AS'
WHEN [type] = 'V' THEN N'WITH ENCRYPTION AS SELECT 123 ABC'
WHEN [type] IN ('FN') THEN N'() RETURNS INT WITH ENCRYPTION AS BEGIN RETURN 1 END'
WHEN [type] IN ('TF') THEN N'() RETURNS @t TABLE(i INT) WITH ENCRYPTION AS BEGIN RETURN END'
WHEN [type] IN ('IF') THEN N'() RETURNS TABLE WITH ENCRYPTION AS RETURN SELECT 1 N'
WHEN [type] IN ('TR') THEN N' ON ' + OBJECT_NAME(ao.[parent_object_id]) + ' WITH ENCRYPTION FOR DELETE AS SELECT 1 N'
ELSE [type]
END
) +REPLICATE(CAST(N'-' AS NVARCHAR(MAX)),DATALENGTH(sov.[imageval])) COLLATE DATABASE_DEFAULT
,sov.[imageval]
FROM sys.all_objects ao
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND ao.[Object_id] = sov.[objid]
WHERE [type] NOT IN ('S','U','PK','F','D','SQ','IT','X','PC','FS','AF','TR') AND ao.[object_id] = @object_id
UNION ALL
--Server Triggers
SELECT SPACE(1)+'TRIGGER'+SPACE(1)+QUOTENAME(st.[name])+SPACE(1)+N'ON ALL SERVER WITH ENCRYPTION FOR DDL_LOGIN_EVENTS AS SELECT 1'
 +REPLICATE(CAST(N'-' AS NVARCHAR(MAX)),DATALENGTH(sov.[imageval])) COLLATE DATABASE_DEFAULT
,sov.[imageval] 
FROM sys.server_triggers st
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND st.[object_id] = sov.[objid] WHERE st.[object_id] = @object_id
--Database Triggers
UNION ALL
SELECT SPACE(1)+'TRIGGER'+SPACE(1)+QUOTENAME(dt.[name])+SPACE(1)+N'ON DATABASE WITH ENCRYPTION FOR CREATE_TABLE AS SELECT 1'
 +REPLICATE(CAST(N'-' AS NVARCHAR(MAX)),DATALENGTH(sov.[imageval])) COLLATE DATABASE_DEFAULT
,sov.[imageval] 
FROM sys.triggers dt
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND dt.[object_id] = sov.[objid] AND dt.[parent_class_desc] = 'DATABASE' WHERE dt.[object_id] = @object_id
) x([ObjectStmTemplate],[imageval])

--Alter the existing object, then revert so that we have the dummy object encrypted value
BEGIN TRANSACTION
	DECLARE @sql NVARCHAR(MAX)
	SET @sql = N'ALTER'+@ObjectNameStmTemplate
	EXEC sp_executesql @sql
	SELECT @DummyEncObj = sov.[imageval]
	FROM sys.all_objects ao
	INNER JOIN sys.sysobjvalues sov ON sov.[valclass]=1 AND ao.[Object_id]=sov.[objid]
	WHERE ao.[object_id] = @object_id
ROLLBACK TRANSACTION

DECLARE @Final NVARCHAR(MAX)
SET @Final = N''
DECLARE @Pos INT
SET @Pos = 1
WHILE @Pos <= DATALENGTH(@EncObj)/2
BEGIN
	SET @Final = @Final + NCHAR(UNICODE(SUBSTRING(CAST(@EncObj AS NVARCHAR(MAX)),@Pos,1))^(UNICODE(SUBSTRING(N'CREATE'+@ObjectNameStmTemplate,@Pos,1))^UNICODE(SUBSTRING(CAST(@DummyEncObj AS NVARCHAR(MAX)),@Pos,1))))
	SET @Pos = @Pos + 1
END

--If the object is small then just print, else print in chunks
IF DATALENGTH(@Final) <= 8000
BEGIN
	PRINT '--SMALL--'
	PRINT @Final
END
ELSE
BEGIN
	PRINT '--BIG--'
	DECLARE @c INT
	SET @c = 0
	WHILE @c <= (DATALENGTH(@Final)/8000)
	BEGIN
		PRINT SUBSTRING(@Final,@c+(@c*4000),4000)
		SET @c = @c + 1
	END
END