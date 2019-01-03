--http://jongurgul.com/blog/sql-server-memory-usage-buffer/
SELECT
 CASE dobd.[database_id] WHEN 32767 THEN 'ResourceDB' ELSE DB_NAME(dobd.[database_id]) END AS [DatabaseName]
,COUNT_BIG(*) [PagesBuffered]
,CONVERT(DECIMAL (15,3),COUNT_BIG(*)*0.0078125) [Buffered_MiB]
FROM sys.dm_os_buffer_descriptors dobd
--WHERE dobd.[database_id] = DB_ID()
GROUP BY dobd.[database_id],DB_NAME(dobd.[database_id])

--http://jongurgul.com/blog/sql-server-memory-usage-buffer/
SELECT
 CASE dobd.[database_id] WHEN 32767 THEN 'ResourceDB' ELSE DB_NAME(dobd.[database_id]) END AS [DatabaseName]
,OBJECT_NAME(p.[object_id]) [ObjectName]
,p.[index_id] [IndexID]
,dobd.[page_type] [PageType]
,COUNT_BIG(*) [PagesBuffered]
,CONVERT(DECIMAL (15,3),COUNT_BIG(*)*0.0078125) [Buffered_MiB]
FROM sys.dm_os_buffer_descriptors AS dobd
LEFT OUTER JOIN sys.allocation_units AS au ON au.[allocation_unit_id] = dobd.[allocation_unit_id]
LEFT OUTER JOIN sys.partitions AS p ON au.[container_id] = p.[partition_id]
WHERE dobd.[database_id] = DB_ID()
GROUP BY dobd.[database_id],DB_NAME(dobd.[database_id]),p.[object_id],p.[index_id],dobd.[page_type]