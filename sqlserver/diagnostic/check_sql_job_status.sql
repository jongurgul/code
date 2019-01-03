--http://jongurgul.com/blog/check-status-of-sql-jobs
DECLARE @t TABLE
(
[Job ID] UNIQUEIDENTIFIER,[Last Run Date] CHAR(8),[Last Run Time] CHAR(6),[Next Run Date] CHAR(8),[Next Run Time] CHAR(6),[Next Run Schedule ID] INT,
[Requested To Run] INT,[Request Source] INT,[Request Source ID] SQL_VARIANT,[Running] INT,[Current Step] INT,[Current Retry Attempt] INT,[State] INT
)

INSERT INTO @t
EXECUTE master.dbo.xp_sqlagent_enum_jobs @can_see_all_running_jobs=1,@job_owner='0x4A6F6E47757267756C'

SELECT
 es.[session_id] [SessionID]
,t.[Request Source ID] [Requester]
,t.[Job ID] [JobID]
,sj.[name] [JobName]
,sjs.[step_id] [StepID]
,sjs.[step_name] [StepName]
,CASE t.[State]
 WHEN 0 THEN 'Not idle or suspended'
 WHEN 1 THEN 'Executing'
 WHEN 2 THEN 'Waiting For Thread'
 WHEN 3 THEN 'Between Retries'
 WHEN 4 THEN 'Idle'
 WHEN 5 THEN 'Suspended'
 WHEN 6 THEN 'WaitingForStepToFinish'
 WHEN 7 THEN 'PerformingCompletionActions'
 ELSE ''
 END [State]
,sja.[start_execution_date] [FirstStepStartDate]
,sja.[last_executed_step_id] [LastStepID]
,sja.[last_executed_step_date] [LastStepStartDate]
,sja.[stop_execution_date] [LastStepEndDate]
FROM @t t
INNER JOIN msdb..sysjobs sj ON t.[Job ID] = sj.[job_id]
INNER JOIN msdb..sysjobsteps sjs ON sjs.[job_id] = sj.[job_id]
AND t.[Job ID] = sjs.[job_id]
AND t.[Current Step] = sjs.[step_id]
INNER JOIN
(
	SELECT * FROM msdb..sysjobactivity d
	WHERE EXISTS
	(
	SELECT 1
	FROM msdb..sysjobactivity l
	GROUP BY l.[job_id]
	HAVING l.[job_id] = d.[job_id]
	AND MAX(l.[start_execution_date]) = d.[start_execution_date]
	)
) sja
ON sja.[job_id] = sj.[job_id]
LEFT JOIN (SELECT SUBSTRING([program_name],30,34) p,[session_id] FROM sys.dm_exec_sessions
WHERE [program_name] LIKE 'SQLAgent - TSQL JobStep%') es
ON CAST('' AS XML).value('xs:hexBinary(substring(sql:column("es.p"),3))','VARBINARY(MAX)') = sj.[job_id]