--http://jongurgul.com/blog/using-the-default-system_health-extended-event/
DECLARE @target_data XML
SELECT @target_data = CAST([target_data] AS XML)
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s ON s.[address] = st.[event_session_address]
WHERE s.[name] = 'system_health'
AND st.[target_name] = 'ring_buffer'

SELECT
 x.y.query('.') [event]
,x.y.value('(@timestamp)[1]','DATETIME') [DateTime]
,x.y.value('(@name)[1]','VARCHAR(MAX)') [name]
,x.y.value('(@package)[1]','VARCHAR(MAX)') [package]
,x.y.value('(action[@name="database_id"]/value)[1]','INT') [database_id]
,x.y.value('(action[@name="session_id"]/value)[1]','INT') [session_id]
,x.y.value('(data[@name="error_number"]/value)[1]','INT') [error_number]
,x.y.value('(data[@name="severity"]/value)[1]','INT') [severity]
,x.y.value('(data[@name="state"]/value)[1]','INT') [state]
,x.y.value('(data[@name="message"]/value)[1]','VARCHAR(MAX)') [message]
,x.y.value('(action[@name="sql_text"]/value)[1]','VARCHAR(MAX)') [sql_text]
FROM (SELECT @target_data) [target_data]([target_data])
CROSS APPLY [target_data].nodes('/RingBufferTarget/event') AS x(y)
WHERE x.y.query('.').exist('/event[@name="error_reported"]') = 1
--AND x.y.exist('.//data[@name="severity"]/value/text()[. = "20"]') = 1
--AND x.y.value('(@timestamp)[1]','DATETIME') = '2015-10-21 16:29:00.000'

--http://jongurgul.com/blog/using-the-default-system_health-extended-event/
SELECT 
 x.y.query('.') [event]
,x.y.value('(@timestamp)[1]','DATETIME') [DateTime]
,x.y.value('(@name)[1]','VARCHAR(MAX)') [name]
,x.y.value('(@package)[1]','VARCHAR(MAX)') [package]
,x.y.value('(action[@name="database_id"]/value)[1]','INT') [database_id]
,x.y.value('(action[@name="session_id"]/value)[1]','INT') [session_id]
,x.y.value('(data[@name="error_number"]/value)[1]','INT') [error_number]
,x.y.value('(data[@name="severity"]/value)[1]','INT') [severity]
,x.y.value('(data[@name="state"]/value)[1]','INT') [state]
,x.y.value('(data[@name="message"]/value)[1]','VARCHAR(MAX)') [message]
,x.y.value('(action[@name="sql_text"]/value)[1]','VARCHAR(MAX)') [sql_text]
FROM
(
	SELECT 
	CAST([event_data] AS XML) as [target_data],*
	FROM sys.fn_xe_file_target_read_file('*system_health*.xel',NULL,NULL,NULL)
) e CROSS APPLY [target_data].nodes('/event') AS x(y)
WHERE x.y.query('.').exist('/event[@name="error_reported"]') = 1

