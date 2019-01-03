--http://jongurgul.com/blog/capturing-deadlocks/
DECLARE @target_data XML
SELECT @target_data = CAST([target_data] as XML)
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s ON s.[address] = st.[event_session_address]
WHERE s.[name] = 'system_health'
AND st.[target_name] = 'ring_buffer'
 
SELECT
 x.y.query('./data/value/deadlock') [Deadlock_SaveAs_File.xdl]
,x.y.value('(@timestamp)[1]', 'datetime') [DateTime]
FROM (SELECT @target_data) [deadlock]([target_data])
CROSS APPLY [target_data].nodes('/RingBufferTarget/event') AS x(y)
WHERE x.y.query('.').exist('/event[@name="xml_deadlock_report"]') = 1
ORDER BY x.y.value('(@timestamp)[1]', 'datetime')