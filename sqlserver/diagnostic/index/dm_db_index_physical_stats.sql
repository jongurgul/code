--http://jongurgul.com/blog/sql-index-stats-queries
SELECT
 DB_NAME() [DatabaseName]
,ao.[object_id] [ObjectID]
,SCHEMA_NAME(ao.[schema_id]) [SchemaName]
,ao.[name] [ObjectName]
,ao.[is_ms_shipped] [IsSystemObject]
,i.[index_id] [IndexID]
,i.[name] [IndexName]
,i.[type_desc] [IndexType]
,au.[type_desc] [AllocationUnitType]
,p.[partition_number] [PartitionNumber]
,ds.[type] [IsPartition]
--,p.[data_compression_desc] [Compression]
,ds.[name] [PartitionName]
,fg.[name] [FileGroupName]
,p.[rows] [NumberOfRows]
,CASE WHEN pf.[boundary_value_on_right] = 1 AND ds.[type] = 'PS' THEN 'RIGHT'
 WHEN pf.[boundary_value_on_right] IS NULL AND ds.[type] = 'PS' THEN 'LEFT'
 ELSE NULL
 END [Range]
,prv.[value] [LowerBoundaryValue]
,prv2.[value] [UpperBoundaryValue]
,CONVERT(DECIMAL(15,3),(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND p.[rows] >0 THEN p.[rows]/au.[data_pages] ELSE 0 END)) [RowsPerPage]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.20 ELSE NULL END) [TippingPointLower_Rows]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.30 ELSE NULL END) [TippingPointUpper_Rows]
,au.[used_pages][UsedPages]
,CONVERT(DECIMAL (15,3),(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END)*0.0078125) [DataUsedSpace_MiB]
,CONVERT(DECIMAL (15,3),(au.[used_pages]-(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END))*0.0078125) [IndexUsedSpace_MiB]
,au.[data_pages] [DataPages]
,ddips.[avg_fragmentation_in_percent] [AverageFragementationPercent]
--,'ALTER INDEX ' + QUOTENAME(i.[name]) + ' ON ' + QUOTENAME(SCHEMA_NAME(ao.[schema_id])) + '.' + QUOTENAME(ao.[name]) + ' REBUILD ' + 
--CASE WHEN ds.[type] = 'PS' THEN 'Partition = ' +  CAST(p.[partition_number] AS VARCHAR(10))
--ELSE ''
--END +' WITH (SORT_IN_TEMPDB=ON,DATA_COMPRESSION=PAGE)' [RebuildCommands] --PAD_INDEX  = ON,FILLFACTOR = 80
FROM
sys.partition_functions pf
INNER JOIN sys.partition_schemes ps ON pf.[function_id] = ps.[function_id]
RIGHT OUTER JOIN sys.partitions p
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN sys.allocation_units au ON au.[container_id] = p.[partition_id] AND au.[type_desc] = 'IN_ROW_DATA' 
INNER JOIN sys.filegroups fg ON au.[data_space_id] = fg.[data_space_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.all_objects ao ON i.[object_id] = ao.[object_id] ON ps.[data_space_id] = ds.[data_space_id]
LEFT OUTER JOIN sys.partition_range_values prv ON ps.[function_id] = prv.[function_id] AND p.[partition_number] - 1 = prv.[boundary_id]
LEFT OUTER JOIN sys.partition_range_values prv2 ON ps.[function_id] = prv2.[function_id] AND prv2.[boundary_id] = p.[partition_number]
INNER JOIN sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'LIMITED') ddips ON i.[object_id] = ddips.[object_id] AND i.[index_id] = ddips.[index_id] AND ddips.[alloc_unit_type_desc] = 'IN_ROW_DATA'
WHERE ao.[is_ms_shipped] = 0