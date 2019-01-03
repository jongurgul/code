--http://jongurgul.com/blog/most-recent-sql-query
SELECT
 DB_NAME(est.[dbid]) [DatabaseName]
,es.[session_id] [SessionID]
,est.[text] [StatementText]
,es.[host_name] [ConnectionHostName]
,es.[login_name] [ConnectionLoginName]
,es.[program_name] [ConnectionProgramName]
FROM sys.dm_exec_sessions es
LEFT OUTER JOIN sys.dm_exec_connections ec ON es.[session_id] = ec.[session_id]
OUTER APPLY sys.dm_exec_sql_text(ec.[most_recent_sql_handle]) est