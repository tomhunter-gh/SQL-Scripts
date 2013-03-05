USE [master]
GO

CREATE PROCEDURE [sp_AutoFixAllUsers]
AS
BEGIN

	DECLARE @AutoFixCommand NVARCHAR(MAX)
	SET @AutoFixCommand = ''

	SELECT @AutoFixCommand = @AutoFixCommand + ' '
			+ 'EXEC sp_change_users_login ''Auto_Fix'', ''' + dp.[name] + ''';'
	FROM sys.database_principals dp
	INNER JOIN sys.server_principals sp
		ON dp.[name] = sp.[name] COLLATE DATABASE_DEFAULT
	WHERE dp.[type_desc] IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP')
	AND sp.[type_desc] IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
	AND dp.[sid] <> sp.[sid]

	IF (@AutoFixCommand <> '')
	BEGIN
		PRINT 'Fixing users in database: ' + DB_NAME()
		PRINT @AutoFixCommand
		EXEC(@AutoFixCommand)
		PRINT ''
	END
END
GO

EXEC sys.sp_MS_marksystemobject 'sp_AutoFixAllUsers'

--EXEC sp_msforeachdb '[?].[dbo].[sp_AutoFixAllUsers]'