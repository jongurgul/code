--http://jongurgul.com/blog/detailed-table-index-breakdown/
SELECT
 DB_NAME(mf.[database_id]) [DatabaseName]
,CONVERT(DECIMAL(15,3),(SUM(mf.[size])*CONVERT(FLOAT,8)/1024)) [Size_MiB]
,mf.[type_desc] [FileType]
FROM sys.master_files mf
WHERE DB_NAME(mf.[database_id]) = 'Test'
GROUP BY DB_NAME(mf.[database_id]),mf.[type_desc]
ORDER BY DB_NAME(mf.[database_id])
GO

--http://jongurgul.com/blog/detailed-table-index-breakdown/
SELECT
 DB_NAME(mf.[database_id]) [DatabaseName]
,mf.[size] * CONVERT(FLOAT,8) [Size_KiB]
,CONVERT(DECIMAL(15,3),(mf.[size]*CONVERT(FLOAT,8)/1024)) [Size_MiB]
,CONVERT(DECIMAL (15,3),(mf.[size]*CONVERT(FLOAT,8))/1048576) [Size_GiB]
,mf.[size] * CONVERT(FLOAT,8192) [Size_bytes]
,LTRIM(CASE mf.[is_percent_growth] WHEN 1 THEN STR(mf.[growth]) +' %' ELSE STR(mf.[growth]*CONVERT(FLOAT,8)/1024)+' MiB' END) [AutoGrowth]
,CASE WHEN mf.[max_size]= -1 THEN -1 ELSE mf.[max_size] * CONVERT(FLOAT,8) END [MaxSize]
,mf.[type_desc] [FileType]
,CAST(CASE mf.[state] WHEN 6 THEN 1 ELSE 0 END AS BIT) [IsOffline]
,mf.[is_read_only] [IsReadOnly]
,mf.[name] [LogicalName]
,mf.[file_id] [FileID]
,RIGHT(mf.[physical_name],CHARINDEX('\',REVERSE (mf.[physical_name]))-1) [FileName]
,mf.[physical_name] [Path]
FROM sys.master_files mf
--WHERE DB_NAME(mf.[database_id]) = DB_NAME()
ORDER BY DB_NAME(mf.[database_id]),mf.[file_id]
GO

--http://jongurgul.com/blog/detailed-table-index-breakdown/
SELECT
 DB_NAME() [DatabaseName]
,CONVERT(DECIMAL (15,2),(SUM(sf.[size])*CONVERT(FLOAT,8)/1024)) [Size_MiB]
,CONVERT(DECIMAL (15,2),
 (SUM(CASE WHEN (sf.[status] & 64 = 0) THEN sf.[size] ELSE 0 END)
 - (
 SELECT SUM(au.[total_pages])
 FROM sys.partitions p INNER JOIN sys.allocation_units au
 ON p.[partition_id] = au.[container_id] LEFT JOIN sys.internal_tables it on p.[object_id] = it.[object_id])
   )*CONVERT(FLOAT,8)/1024
) [AvailableSpace_MiB]
FROM sys.sysfiles sf
GO

--http://jongurgul.com/blog/detailed-table-index-breakdown/
SELECT
 DB_NAME() [DatabaseName]
,fg.[groupname] [FileGroupName]
,CONVERT(DECIMAL(15,3),(FILEPROPERTY(sf.[name],'SpaceUsed')*CONVERT(FLOAT,8)/1024)) [SpaceUsed_MiB]
,CONVERT(DECIMAL(15,3),((sf.[size]-FILEPROPERTY(sf.[name],'SpaceUsed'))*CONVERT(FLOAT,8)/1024)) [AvailableSpace_MiB]
,mf.[size] * CONVERT(FLOAT,8) [Size_KiB]
,CONVERT(DECIMAL(15,3),(sf.[size] * CONVERT(FLOAT,8)/1024)) [Size_MiB]
,CONVERT(DECIMAL (15,3),(sf.[size] * CONVERT(FLOAT,8))/1048576) [Size_GiB]
,mf.[size] * CONVERT(FLOAT,8192) [Size_bytes]
,LTRIM(CASE mf.[is_percent_growth] WHEN 1 THEN STR(mf.[growth]) +' %' ELSE STR(mf.[growth]*CONVERT(FLOAT,8)/1024)+' MiB' END) [AutoGrowth]
,CASE WHEN mf.[max_size]=-1 THEN -1 ELSE mf.[max_size] * CONVERT(FLOAT,8) END [MaxSize]
,mf.[type_desc] [FileType]
,CAST(CASE mf.[state] WHEN 6 THEN 1 ELSE 0 END AS BIT) [IsOffline]
,mf.[is_read_only] [IsReadOnly]
,sf.[name] [LogicalName]
,mf.[file_id] [FileID]
,RIGHT(mf.[physical_name],CHARINDEX('\',REVERSE (mf.[physical_name]))-1) [FileName]
,sf.[filename] [Path]
FROM sys.master_files mf
INNER JOIN sys.sysfiles sf ON mf.[file_id] = sf.[fileid] AND mf.[database_id] = DB_ID()
LEFT JOIN sys.sysfilegroups fg ON sf.[groupid] = fg.[groupid]
ORDER BY mf.[file_id]