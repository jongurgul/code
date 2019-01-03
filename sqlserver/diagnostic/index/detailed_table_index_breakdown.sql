--http://jongurgul.com/blog/detailed-table-index-breakdown/
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
,CONVERT(DECIMAL (15,3),(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND p.[rows] >0 THEN p.[rows]/NULLIF(au.[data_pages],0) ELSE 0 END)) [RowsPerPage]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.20 ELSE NULL END) [TippingPointLower_Rows]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.30 ELSE NULL END) [TippingPointUpper_Rows]
,au.[used_pages][UsedPages]
,CONVERT(DECIMAL (15,3),(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END)*CONVERT(FLOAT,8)/1024) [DataUsedSpace_MiB]
,CONVERT(DECIMAL (15,3),(au.[used_pages]-(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END))*CONVERT(FLOAT,8)/1024) [IndexUsedSpace_MiB]
,au.[data_pages] [DataPages]
FROM        
sys.partition_functions pf
INNER JOIN sys.partition_schemes ps ON pf.[function_id] = ps.[function_id]
RIGHT OUTER JOIN sys.partitions p
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN sys.allocation_units au ON au.[container_id] = p.[partition_id]
INNER JOIN sys.filegroups fg ON au.[data_space_id] = fg.[data_space_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.all_objects ao ON i.[object_id] = ao.[object_id] ON ps.[data_space_id] = ds.[data_space_id]
LEFT OUTER JOIN sys.partition_range_values prv ON ps.[function_id] = prv.[function_id] AND p.[partition_number] - 1 = prv.[boundary_id]
LEFT OUTER JOIN sys.partition_range_values prv2 ON ps.[function_id] = prv2.[function_id] AND prv2.[boundary_id] = p.[partition_number]
WHERE
ao.[is_ms_shipped] = 0
AND au.[type_desc] = 'IN_ROW_DATA'
--AND SCHEMA_NAME(ao.[schema_id]) ='dbo'
--AND ao.[name] LIKE '%%'
ORDER BY SCHEMA_NAME(ao.[schema_id]),ao.[name]

--http://jongurgul.com/blog/detailed-table-index-breakdown-buffered/
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
,CASE 
 WHEN pf.[boundary_value_on_right] = 1 AND ds.[type] = 'PS' THEN 'RIGHT'
 WHEN pf.[boundary_value_on_right] IS NULL AND ds.[type] = 'PS' THEN 'LEFT'
 ELSE NULL
 END [Range]
,prv.[value] [LowerBoundaryValue]
,prv2.[value] [UpperBoundaryValue]
,CONVERT(DECIMAL (15,3),(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND p.[rows] >0 THEN p.[rows]/NULLIF(au.[data_pages],0) ELSE 0 END)) [RowsPerPage]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.20 ELSE NULL END) [TippingPointLower_Rows]
,(CASE WHEN au.[type_desc] = 'IN_ROW_DATA' AND i.[type_desc] = 'CLUSTERED' THEN au.[used_pages]*0.30 ELSE NULL END) [TippingPointUpper_Rows]
,au.[used_pages][UsedPages]
,CONVERT(DECIMAL (15,3),(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END)*0.0078125) [DataUsedSpace_MiB]
,CONVERT(DECIMAL (15,3),(au.[used_pages]-(CASE WHEN au.[type] <> 1 THEN au.[used_pages] WHEN p.[index_id] < 2 THEN au.[data_pages] ELSE 0 END))*0.0078125) [IndexUsedSpace_MiB]
,au.[data_pages] [DataPages] --maybe better called leaf pages? page level 0 could be data pages or in nc index pages. it counts In-row data,LOB data and Row-overflow data.
,b.[DataPagesBuffered]
,CONVERT(DECIMAL (15,3),b.[DataPagesBuffered]*0.0078125) [DataBuffered_MiB]
,b.[IndexPagesBuffered]
,CONVERT(DECIMAL (15,3),b.[IndexPagesBuffered]*0.0078125) [IndexBuffered_MiB]
,b.[PagesBuffered]
--,b.[numa_node] [NumaNode]
FROM        
sys.partition_functions pf
INNER JOIN sys.partition_schemes ps ON pf.[function_id] = ps.[function_id]
RIGHT OUTER JOIN sys.partitions p
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN sys.allocation_units au ON au.[container_id] = p.[partition_id]
INNER JOIN sys.filegroups fg ON au.[data_space_id] = fg.[data_space_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.all_objects ao ON i.[object_id] = ao.[object_id] ON ps.[data_space_id] = ds.[data_space_id]
LEFT OUTER JOIN sys.partition_range_values prv ON ps.[function_id] = prv.[function_id] AND p.[partition_number] - 1 = prv.[boundary_id]
LEFT OUTER JOIN sys.partition_range_values prv2 ON ps.[function_id] = prv2.[function_id] AND prv2.[boundary_id] = p.[partition_number]
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
WHERE
ao.[is_ms_shipped] = 0
AND au.[type_desc] = 'IN_ROW_DATA'
--AND SCHEMA_NAME(ao.[schema_id]) ='dbo'
--AND ao.[name] LIKE '%%'
ORDER BY SCHEMA_NAME(ao.[schema_id]),ao.[name]