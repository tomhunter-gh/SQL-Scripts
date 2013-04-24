USE [master]
GO

ALTER PROCEDURE [sp_DDLChanges]
AS
BEGIN
	DECLARE @curr_tracefilename VARCHAR(500);
	DECLARE @base_tracefilename VARCHAR(500);
	DECLARE @indx INT;

	SELECT @curr_tracefilename = [path] FROM sys.traces WHERE [is_default] = 1;
	SET @curr_tracefilename = REVERSE(@curr_tracefilename)
	SELECT @indx  = PATINDEX('%\%', @curr_tracefilename)
	SET @curr_tracefilename = REVERSE(@curr_tracefilename)
	SET @base_tracefilename = LEFT(@curr_tracefilename, LEN(@curr_tracefilename) - @indx) + '\log.trc';

	SELECT
		[ServerName] AS [Server],
		[StartTime] AS [Time],
		CASE [EventClass]
			WHEN 46 THEN 'CREATE'
			WHEN 47 THEN 'DROP'
			WHEN 164 THEN 'ALTER'
		END AS [Action],
		object_type.[subclass_name] AS [ObjectType],
		[DatabaseName] AS [Database],
		OBJECT_SCHEMA_NAME([ObjectID], [DatabaseID]) AS [Schema],
		OBJECT_NAME([ObjectID], [DatabaseID]) AS [Object],
		[NTUserName] AS [User],
		[ApplicationName] AS [Application]
	FROM ::fn_trace_gettable(@base_tracefilename, default) t
	LEFT JOIN sys.trace_subclass_values object_type
		ON object_type.trace_column_id = 28
		AND object_type.trace_event_id = t.[EventClass]
		AND object_type.[subclass_value] = t.[ObjectType]
	WHERE [EventClass] IN (46,47,164)
	AND [EventSubclass] = 0
	AND [ObjectType] <> 21587 -- don't bother with auto-statistics as it generates too much noise
	AND [StartTime] >= DATEADD(DD,-1,GETDATE())
	--AND [StartTime] BETWEEN '2013-04-24 12:00:00' AND '2013-04-24 12:30:00'
	AND [DatabaseID] <> DB_ID('tempdb')
	ORDER BY t.[starttime] DESC
END

EXEC sys.sp_MS_marksystemobject 'sp_DDLChanges'