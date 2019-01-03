--http://jongurgul.com/blog/simple-table-index-breakdown/
SELECT
 SCHEMA_NAME(ao.[schema_id]) [SchemaName]
,ao.[name] [ObjectName]
,i.[name] [IndexName]
,i.[type_desc] [IndexType]
,p.[partition_number] [PartitionNumber]
--,p.[data_compression_desc] [Compression]
,ds.[name] [PartitionName]
,p.[rows] [NumberOfRows]
,prv.[value] [LowerBoundaryValue]
,prv2.[value] [UpperBoundaryValue]
FROM sys.partition_functions pf
INNER JOIN sys.partition_schemes ps ON pf.[function_id] = ps.[function_id]
RIGHT OUTER JOIN sys.partitions p
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.all_objects ao ON i.[object_id] = ao.[object_id] ON ps.[data_space_id] = ds.[data_space_id]
LEFT OUTER JOIN sys.partition_range_values prv ON ps.[function_id] = prv.[function_id] AND p.[partition_number] - 1 = prv.[boundary_id]
LEFT OUTER JOIN sys.partition_range_values prv2 ON ps.[function_id] = prv2.[function_id] AND prv2.[boundary_id] = p.[partition_number]
WHERE ao.[is_ms_shipped] = 0 
--AND SCHEMA_NAME(ao.[schema_id]) ='dbo' 
--AND ao.[name] LIKE '%%' 
ORDER BY SCHEMA_NAME(ao.[schema_id]),ao.[name]

--http://jongurgul.com/blog/simple-table-index-breakdown-buffered/
SELECT
 SCHEMA_NAME(ao.[schema_id]) [SchemaName]
,ao.[name] [ObjectName]
,i.[name] [IndexName]
,i.[type_desc] [IndexType]
,p.[partition_number] [PartitionNumber]
--,p.[data_compression_desc] [Compression]
,ds.[name] [PartitionName]
,p.[rows] [NumberOfRows]
,prv.[value] [LowerBoundaryValue]
,prv2.[value] [UpperBoundaryValue]
,b.[DataPagesBuffered]
,CONVERT(DECIMAL (15,3),b.[DataPagesBuffered]*0.0078125) [DataBuffered_MiB]
,b.[IndexPagesBuffered]
,CONVERT(DECIMAL (15,3),b.[IndexPagesBuffered]*0.0078125) [IndexBuffered_MiB]
,b.[PagesBuffered]
--,b.[numa_node] [NumaNode]
FROM sys.partition_functions pf
INNER JOIN sys.partition_schemes ps ON pf.[function_id] = ps.[function_id]
RIGHT OUTER JOIN sys.partitions p
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.all_objects ao ON i.[object_id] = ao.[object_id] ON ps.[data_space_id] = ds.[data_space_id]
LEFT OUTER JOIN sys.partition_range_values prv ON ps.[function_id] = prv.[function_id] AND p.[partition_number] - 1 = prv.[boundary_id]
LEFT OUTER JOIN sys.partition_range_values prv2 ON ps.[function_id] = prv2.[function_id] AND prv2.[boundary_id] = p.[partition_number]
	INNER JOIN sys.allocation_units au ON au.[container_id] = p.[partition_id]
	INNER JOIN
	(
	SELECT
	[allocation_unit_id], SUM(CASE WHEN [page_type] = 'INDEX_PAGE' THEN 1 ELSE 0 END) [IndexPagesBuffered]
	,SUM(CASE WHEN [page_type] = 'DATA_PAGE' THEN 1 ELSE 0 END) [DataPagesBuffered]
	,COUNT_BIG(*) [PagesBuffered]
	--,[numa_node]
	FROM sys.dm_os_buffer_descriptors
	WHERE [database_id] = DB_ID()
	GROUP BY [allocation_unit_id]--,[numa_node]
	) b
	ON au.[allocation_unit_id] = b.[allocation_unit_id]
WHERE ao.[is_ms_shipped] = 0 
--AND SCHEMA_NAME(ao.[schema_id]) ='dbo' 
--AND ao.[name] LIKE '%%' 
ORDER BY SCHEMA_NAME(ao.[schema_id]),ao.[name]
