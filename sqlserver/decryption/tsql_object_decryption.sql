--https://social.msdn.microsoft.com/Forums/sqlserver/en-US/e7056ca8-94cd-4d36-a676-04c64bf96330/decrypt-the-encrypted-store-procedure-through-the-tsql-programming-in-sql-server-2005?forum=transactsql
--http://jongurgul.com/blog/sql-object-decryption/
DECLARE @EncObj VARBINARY(MAX),@DummyEncObj VARBINARY(MAX),@ObjectNameType NVARCHAR(50),@ObjectNameStmTemplate NVARCHAR(4000),@Schema nVARCHAR(MAX),@ObjectName NVARCHAR(50),@TemplateObj NVARCHAR(max)
DECLARE @p INT,@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX),@QueryForDummyObj NVARCHAR(MAX),@C INT
SET NOCOUNT ON
SET @ObjectName = 'jjj'
SET @Schema = 'dbo'
--please set @Schema = null for database/server triggers if needed
IF EXISTS
(
SELECT 1 FROM syscomments WHERE [encrypted] = 1 AND [id]= OBJECT_ID(@Schema+'.'+@ObjectName) OR @Schema IS NULL
)
BEGIN
IF EXISTS
(
SELECT * FROM sys.dm_exec_connections ec JOIN sys.endpoints e
on (ec.[endpoint_id]=e.[endpoint_id])
WHERE e.[name]='Dedicated Admin Connection'
AND ec.[session_id] = @@SPID
)
BEGIN
SELECT TOP 1 @ObjectName=ObjectName,@ObjectNameType=ObjectType,@ObjectNameStmTemplate=ObjectStmTemplate,@EncObj = [imageval]
FROM
(
SELECT name ObjectName,
CASE WHEN [type] = 'P' THEN N'PROCEDURE'
WHEN [type] = 'V' THEN 'VIEW'
WHEN [type] IN ('FN','TF','IF') THEN N'FUNCTION'
WHEN [type] IN ('TR') THEN N'TRIGGER'
ELSE [type]
END ObjectType,
CASE WHEN [type] = 'P' THEN N'WITH ENCRYPTION AS'
WHEN [type] = 'V' THEN N'WITH ENCRYPTION AS SELECT 123 ABC'
WHEN [type] IN ('FN') THEN N'() RETURNS INT WITH ENCRYPTION AS BEGIN RETURN 1 END'
WHEN [type] IN ('TF') THEN N'() RETURNS @t TABLE(i INT) WITH ENCRYPTION AS BEGIN RETURN END'
WHEN [type] IN ('IF') THEN N'() RETURNS TABLE WITH ENCRYPTION AS RETURN SELECT 1 N'
WHEN [type] IN ('TR') THEN N' ON ' + OBJECT_NAME(ao.[parent_object_id]) + ' WITH ENCRYPTION FOR DELETE AS SELECT 1 N'
ELSE [type]
END ObjectStmTemplate,
sov.[imageval]
FROM sys.all_objects ao
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND ao.[Object_id] = sov.[objid]
WHERE [type] NOT IN ('S','U','PK','F','D','SQ','IT','X','PC','FS','AF')
AND ao.[name] = @ObjectName
AND ao.[schema_id] = SCHEMA_ID(@Schema)
--Server Triggers
UNION ALL SELECT name [ObjectName],'TRIGGER' [type],N'ON ALL SERVER WITH ENCRYPTION FOR DDL_LOGIN_EVENTS AS SELECT 1' [ObjectStmTemplate],sov.[imageval] FROM sys.server_triggers st
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND st.[Object_id] = sov.[objid]
WHERE name = @ObjectName
--Database Triggers
UNION ALL SELECT name [ObjectName],'TRIGGER' [type],N'ON DATABASE WITH ENCRYPTION FOR CREATE_TABLE AS SELECT 1' [ObjectStmTemplate],sov.[imageval] FROM sys.triggers dt
INNER JOIN sys.sysobjvalues sov ON sov.[valclass] = 1 AND dt.[Object_id] = sov.[objid] AND dt.[parent_class_desc] = 'DATABASE'
WHERE name = @ObjectName
) x

--SELECT @ObjectName,@ObjectNameType,@ObjectNameStmTemplate,@EncObj

--Chunks
SET @C = CEILING(DATALENGTH(@EncObj) / 8000.0)

--Alter the existing object, then revert so that we have the dummy object encrypted value
BEGIN TRANSACTION
SET @p = 1
SET @p1= N'ALTER'+SPACE(1)+@ObjectNameType+SPACE(1)+ISNULL((@Schema+'.'),'')+@ObjectName +SPACE(1)+@ObjectNameStmTemplate;
SET @p1=@p1+REPLICATE('-',4000-LEN(@p1))
SET @p2 = REPLICATE('-',4000)
SET @QueryForDummyObj = N'EXEC(@p1'
WHILE @p<=@C
BEGIN
SET @QueryForDummyObj=@QueryForDummyObj+N'+@f'
SET @p =@p +1
END
SET @QueryForDummyObj=@QueryForDummyObj+')'
EXEC sp_executesql @QueryForDummyObj,N'@p1 NVARCHAR(4000),@f VARCHAR(8000)',@p1=@p1,@f=@p2

SELECT @DummyEncObj = sov.[imageval]
FROM sys.all_objects ao
INNER JOIN sys.sysobjvalues sov ON sov.[valclass]=1 AND ao.[Object_id]=sov.[objid]
WHERE ao.[name]=@ObjectName AND (ao.[schema_id]=SCHEMA_ID(@Schema) OR @Schema IS NULL)

ROLLBACK TRANSACTION

--Replacement Text
SET @TemplateObj = N'CREATE'+SPACE(1)+@ObjectNameType+SPACE(1)+ISNULL((@Schema+'.'),'')+@ObjectName +SPACE(1)+@ObjectNameStmTemplate+REPLICATE('-',4000)
DECLARE @i INT
SET @i = 1
WHILE @i<@C
BEGIN
SET @TemplateObj=@TemplateObj+REPLICATE(N'-',4000)
SET @i =@i+1
END

----Simple Char Decrypt
--DECLARE @Pos INT
--SET @Pos=1
--WHILE @Pos<=DATALENGTH(@EncObj)/2
--BEGIN
--PRINT NCHAR(UNICODE(SUBSTRING(CAST(@EncObj AS NVARCHAR(MAX)),@Pos,1))^(UNICODE(SUBSTRING(@TemplateObj,@Pos,1))^UNICODE(SUBSTRING(CAST(@DummyEncObj AS NVARCHAR(MAX)),@Pos,1))))
--SET @Pos=@Pos+1
--END

----8000 Char Decrypt Strings
DECLARE @CNumber INT,@CEncObj NVARCHAR(MAX),@CDummyEnc NVARCHAR(MAX),@CPiece NVARCHAR(MAX),@CPosition INT,@CTemplateObj NVARCHAR(MAX)
SET @CNumber=1
WHILE @CNumber<=@C
BEGIN
SELECT @CEncObj=SUBSTRING(@EncObj,(@CNumber-1)*8000+1,8000)
SELECT @CDummyEnc=SUBSTRING(@DummyEncObj,(@CNumber - 1) * 8000+1,8000)
SELECT @CTemplateObj=SUBSTRING(@TemplateObj,0+((@CNumber-1)*4000),4000)
SET @CPiece=REPLICATE(N'-',(DATALENGTH(@CEncObj)/2))
SET @CPosition=1
WHILE @CPosition<=DATALENGTH(@CEncObj)/2
BEGIN
SET @CPiece=STUFF(@CPiece,@CPosition,1,NCHAR(UNICODE(SUBSTRING(@CEncObj,@CPosition,1))^(UNICODE(SUBSTRING(@CTemplateObj,@CPosition,1))^UNICODE(SUBSTRING(@CDummyEnc,@CPosition,1)))))
SET @CPosition=@CPosition+1
END
PRINT @CPiece
SET @CNumber=@CNumber+1
END
END
ELSE
BEGIN
PRINT 'Use a DAC Connection'
END
END
ELSE
BEGIN
PRINT 'Object not encrypted or not found'
END