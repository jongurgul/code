--http://jongurgul.com/blog/sql-server-locks
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SELECT 
 dtl.[request_session_id] [SessionID]
,DB_NAME(dtl.[resource_database_id])  [DatabaseName]
,dtl.[request_status] [Status]
,dtl.[resource_type] [Resource]
,CASE 
WHEN [resource_type] =   'OBJECT'      THEN OBJECT_NAME(dtl.[resource_associated_entity_id],dtl.[resource_database_id])
WHEN [resource_type] =   'DATABASE'    THEN DB_NAME(dtl.[resource_database_id])
WHEN [resource_type] IN ('KEY','PAGE','RID') THEN pin.[ObjectName]
ELSE CAST(dtl.[resource_associated_entity_id] AS VARCHAR(MAX))
END [ResourceName]
,dtl.[resource_description] [ResourceDescription]
,dtl.[request_mode] [Mode]
,pin.[type_desc] [Type]
,QUOTENAME(pin.[ObjectSchemaName]) [ObjectSchemaName]
,QUOTENAME(pin.[ObjectName]) [ObjectName]
,QUOTENAME(pin.[IndexName]) COLLATE DATABASE_DEFAULT [IndexName]
,dtl.[resource_description] [ResourceDetail]
,CASE 
WHEN [resource_type] IN ('KEY','RID')
THEN N'SELECT * FROM '+QUOTENAME(DB_NAME(dtl.[resource_database_id]))
+'.'+QUOTENAME(pin.[ObjectSchemaName])
+'.'+QUOTENAME(pin.[ObjectName])
+N' WITH(NOLOCK'+
+COALESCE (',INDEX('+QUOTENAME(pin.[IndexName]) COLLATE DATABASE_DEFAULT +')','')
+') WHERE %%LOCKRES%% = '''
+RTRIM(dtl.[resource_description])+''''
WHEN [resource_type] IN ('PAGE') THEN 'DBCC PAGE('''+DB_NAME(dtl.[resource_database_id])+''','+RTRIM(REPLACE(dtl.[resource_description],':',','))+',3) WITH TABLERESULTS'
ELSE NULL
END COLLATE DATABASE_DEFAULT [Row/Page]--Performance will be poor if the table is large.
--,es.[original_login_name],es.[login_name]
FROM   
(
	SELECT i.[object_id],d.[name] [DatabaseName],d.[database_id],p.[hobt_id],i.[name] [IndexName],i.[type_desc]
	,OBJECT_SCHEMA_NAME(i.[object_id],d.[database_id]) [ObjectSchemaName]
	,OBJECT_NAME(i.[object_id],d.[database_id]) [ObjectName]
	FROM sys.partitions p 
	INNER JOIN sys.indexes i
	ON p.[object_id] = i.[object_id]
	AND p.[index_id] = i.[index_id]
	CROSS APPLY (SELECT * FROM sys.databases WHERE database_id = DB_ID()) d
		UNION ALL
		SELECT i.[object_id],d.[name] [DatabaseName],d.[database_id],p.[hobt_id],i.[name] [IndexName],i.[type_desc]
		,OBJECT_SCHEMA_NAME(i.[object_id],d.[database_id]) [ObjectSchemaName]
		,OBJECT_NAME(i.[object_id],d.[database_id]) [ObjectName]
		FROM tempdb.sys.partitions p 
		INNER JOIN tempdb.sys.indexes i
		ON p.[object_id] = i.[object_id]
		AND p.[index_id] = i.[index_id]
		CROSS APPLY (SELECT * FROM sys.databases WHERE database_id = DB_ID('tempdb')) d
) pin
RIGHT OUTER JOIN sys.dm_tran_locks dtl ON pin.[database_id] = dtl.[resource_database_id]
AND
((pin.[hobt_id] = dtl.[resource_associated_entity_id] OR pin.[object_id] = dtl.[resource_associated_entity_id]))
--LEFT OUTER JOIN sys.dm_exec_sessions es ON dtl.[request_session_id] = es.[session_id]
WHERE 1=1
AND dtl.[request_mode] <> 'Sch-S'
AND dtl.[request_mode] <> 'S' 
ORDER BY pin.[type_desc],dtl.[request_mode]