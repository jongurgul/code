--http://jongurgul.com/blog/delta-cumulative-io-stats/
SELECT 
 QUOTENAME(DB_NAME(iovfs.[database_id])) [DatabaseName]
,iovfs.[file_id] [FileID]
,mf.[name] [LogicalName]
,mf.[type_desc] [FileType]
,SUM(iovfs.[num_of_bytes_read]) [Read_bytes]
,SUM(iovfs.[num_of_bytes_written]) [Written_bytes]
,SUM(iovfs.[num_of_bytes_read])/1048576 [Read_MiB]
,SUM(iovfs.[num_of_bytes_written])/1048576 [Written_MiB]
,SUM(iovfs.[num_of_reads]) [Read_Count]
,SUM(iovfs.[num_of_writes]) [Write_Count]
,SUM(iovfs.[num_of_reads]+iovfs.[num_of_writes]) [IO_Count]
,CONVERT(DECIMAL (15,2),SUM([num_of_bytes_read])/(SUM([num_of_bytes_read]+[num_of_bytes_written])*0.01)) [Read_Percent]
,CONVERT(DECIMAL (15,2),SUM([num_of_bytes_written])/(SUM([num_of_bytes_read]+[num_of_bytes_written])*0.01)) [Write_Percent]
,CONVERT(DECIMAL (15,2),COALESCE(SUM(iovfs.[io_stall_read_ms])/NULLIF(SUM(iovfs.[num_of_reads]*1.0),0),0)) [AverageReadStall_ms]
,CONVERT(DECIMAL (15,2),COALESCE(SUM(iovfs.[io_stall_write_ms])/NULLIF(SUM(iovfs.[num_of_writes]*1.0),0),0)) [AverageWriteStall_ms]
FROM sys.master_files mf INNER JOIN sys.dm_io_virtual_file_stats(NULL,NULL) iovfs
ON mf.[database_id] = iovfs.[database_id]
AND mf.[file_id] = iovfs.[file_id] 
GROUP BY iovfs.[database_id],iovfs.[file_id],mf.[name],mf.[type_desc]
--GROUP BY GROUPING SETS ((iovfs.[database_id],iovfs.[file_id],mf.[name],mf.[type_desc]),(iovfs.[database_id]),()) --SQL2008
ORDER BY QUOTENAME(DB_NAME(iovfs.[database_id])),iovfs.[file_id]