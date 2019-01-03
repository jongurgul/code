--http://jongurgul.com/blog/capturing-deadlocks/
DECLARE @on BIT
SET @on=1
DECLARE @maxsize BIGINT,@tracefile NVARCHAR(256);
SET @maxsize = 20
SET @tracefile = (SELECT LEFT([path],LEN([path])-CHARINDEX('\',REVERSE([path])))+ '\DeadLock' FROM sys.traces WHERE [is_default] = 1) -- We shall use the path of the default trace
SELECT @tracefile
DECLARE @trace_id INT
EXEC sp_trace_create @trace_id output,2,@tracefile ,@maxsize --The 2 means the file will roll over

EXEC sp_trace_setevent @trace_id,148,1,@on --Deadlock graph: TextData
EXEC sp_trace_setevent @trace_id,148,4,@on --Deadlock graph: TransactionID
EXEC sp_trace_setevent @trace_id,148,11,@on --Deadlock graph: LoginName
EXEC sp_trace_setevent @trace_id,148,12,@on --Deadlock graph: SPID
EXEC sp_trace_setevent @trace_id,148,14,@on --Deadlock graph: StartTime
EXEC sp_trace_setevent @trace_id,148,26,@on --Deadlock graph: ServerName
EXEC sp_trace_setevent @trace_id,148,41,@on --Deadlock graph: LoginSid
EXEC sp_trace_setevent @trace_id,148,51,@on --Deadlock graph: EventSequence
EXEC sp_trace_setevent @trace_id,148,60,@on --Deadlock graph: IsSystem
EXEC sp_trace_setevent @trace_id,148,64,@on --Deadlock graph: SessionLoginName

EXEC sp_trace_setstatus  @trace_id,1 --Start the Trace