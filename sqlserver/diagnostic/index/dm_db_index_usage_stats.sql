--http://jongurgul.com/blog/sql-index-stats-queries
SELECT
 SCHEMA_NAME(ao.[schema_id]) [SchemaName]
,ao.[object_id] [ObjectID]
,ao.[name] [ObjectName]
,ao.[is_ms_shipped] [IsSystemObject]
,i.[index_id] [IndexID]
,i.[name] [IndexName]
,i.[type_desc] [IndexType]
,ddius.[user_scans] [UserScans]
,ddius.[user_seeks] [UserSeeks]
,ddius.[user_lookups] [UserLookups]
,ddius.[user_updates] [UserUpdates]
FROM sys.all_objects ao
INNER JOIN sys.indexes i ON ao.[object_id] = i.[object_id]
LEFT OUTER JOIN sys.dm_db_index_usage_stats ddius ON i.[object_id] = ddius.[object_id] AND i.[index_id] = ddius.[index_id]--stats reset upon server restart
WHERE ao.[is_ms_shipped] = 0