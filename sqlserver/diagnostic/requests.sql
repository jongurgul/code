--http://jongurgul.com/blog/simple-running-script-aka-modern-sp_who2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
DB_NAME(er.[database_id]) [DatabaseName]
,er.[session_id] AS [SessionID]
,er.[blocking_session_id] [BlockingSessionID]
,er.[command] AS [CommandType]
,CASE WHEN er.[command] LIKE ('ALTER%') OR er.[command] LIKE ('CREATE%') THEN est.text
ELSE
(SUBSTRING(est.text,(er.[statement_start_offset]/2)+1,((CASE er.[statement_end_offset] WHEN -1 THEN DATALENGTH(est.text) ELSE er.[statement_end_offset] END - er.[statement_start_offset])/2)+1)) 
END [StatementCoreText]--http://msdn.microsoft.com/en-gb/library/ms181929.aspx
,est.text [StatementText]
,er.[open_transaction_count] [OpenTransactions]
,er.[status] AS [Status]
,CONVERT(DECIMAL(5,2),er.[percent_complete]) AS [Complete_Percent]
,CONVERT(DECIMAL(38,2),er.[total_elapsed_time] / 60000.00) AS [ElapsedTime_m]
,CONVERT(DECIMAL(38,2),er.[estimated_completion_time] / 60000.00) AS [EstimatedCompletionTime_m]
--,eqp.[query_plan] [QueryPlan]
,er.[plan_handle] [PlanHandle]
,er.[last_wait_type] [LastWait]
,er.[wait_resource] [CurrentWait]
,er.[cpu_time] [CPU]
,CONVERT(DECIMAL(15,3),(er.[granted_query_memory]/128)) [GrantedMemory_MiB]
,eqmg.[grant_time] [GrantTime]
,CONVERT(DECIMAL(15,3),eqmg.[requested_memory_kb]/1024) [RequestedMemory_MiB]
,CONVERT(DECIMAL (15,3),eqmg.[ideal_memory_kb]/1024) [IdealMemory_MiB]
,CONVERT(DECIMAL(15,3),eqmg.[max_used_memory_kb]/1024) [MaxUsedMemory_MiB]
,CONVERT(DECIMAL(15,3),eqmg.[used_memory_kb]/1024) [UsedMemory_MiB]
,er.[logical_reads] [LogicalReads]
,er.[reads] [Reads]
,er.[writes] [Writes]
,(SELECT COUNT(*) FROM sys.dm_os_tasks ot WHERE er.[session_id] = ot.[session_id]) [NumberOfTasks]
,es.[host_name] [ConnectionHostName]
,es.[login_name] [ConnectionLoginName]
,es.[program_name] [ConnectionProgramName]
--,rgwg.[name] [WorkloadGroupName]
--,rgrp.[name] [ResourcePoolName]
--,tsu.[internal_objects_alloc_page_count]/128 [Task_UserObjectsAlloc_MiB]
--,tsu.[internal_objects_dealloc_page_count]/128 [Task_UserObjectsDeAlloc_MiB]
FROM sys.dm_exec_requests er
INNER JOIN sys.dm_exec_sessions es ON er.[session_id] = es.[session_id] AND es.[session_id] > 50
--LEFT JOIN
--(
--SELECT [session_id],
--SUM([internal_objects_alloc_page_count]) [internal_objects_alloc_page_count],        
--SUM([internal_objects_dealloc_page_count]) [internal_objects_dealloc_page_count]
--FROM sys.dm_db_task_space_usage
--GROUP BY [session_id]
--) tsu
--ON tsu.session_id = es.[session_id]
--INNER JOIN sys.resource_governor_workload_groups rgwg ON es.[group_id] = rgwg.[group_id]
--INNER JOIN sys.resource_governor_resource_pools rgrp ON rgwg.[pool_id] = rgrp.[pool_id]
LEFT JOIN sys.dm_exec_query_memory_grants eqmg ON es.[session_id] = eqmg.[session_id]
CROSS APPLY sys.dm_exec_sql_text(er.[sql_handle]) est
--OUTER APPLY sys.dm_exec_query_plan(er.[plan_handle]) eqp
--WHERE es.[session_id] <> @@SPID