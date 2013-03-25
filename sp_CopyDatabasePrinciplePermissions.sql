USE [master]
GO

IF (OBJECT_ID('[dbo].[sp_CopyDatabasePrinciplePermissions]') IS NULL)
	EXEC ('CREATE PROCEDURE [dbo].[sp_CopyDatabasePrinciplePermissions] AS RETURN')
GO

ALTER PROCEDURE [dbo].[sp_CopyDatabasePrinciplePermissions]
	@CopyFromPrinciple NVARCHAR(128),
	@CopyToPrinciple NVARCHAR(128)
AS
BEGIN
	PRINT 'Copying permissions in [' + DB_NAME() + ']'
	DECLARE @PermissionCommand NVARCHAR(500)
	
	DECLARE csrPermission CURSOR FAST_FORWARD FOR
	SELECT
		[state_desc] + ' ' + [permission_name] + ' '
		+
			CASE
				WHEN [class_desc] = 'OBJECT_OR_COLUMN' THEN
					'ON [' + OBJECT_SCHEMA_NAME([major_id]) + '].[' + OBJECT_NAME([major_id]) + '] '
				ELSE ''
			END
		+ 'TO [' + @CopyToPrinciple + '];' COLLATE DATABASE_DEFAULT AS [PermissionCommand]
	FROM sys.database_permissions permission
	INNER JOIN sys.database_principals principle
		ON principle.principal_id = permission.grantee_principal_id
	WHERE [class_desc] IN ('OBJECT_OR_COLUMN', 'DATABASE')
	AND principle.[name] = @CopyFromPrinciple

	OPEN csrPermission
	FETCH NEXT FROM csrPermission INTO @PermissionCommand
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT ' ' + @PermissionCommand
		EXEC (@PermissionCommand)
		FETCH NEXT FROM csrPermission INTO @PermissionCommand
	END
	
	CLOSE csrPermission
	DEALLOCATE csrPermission


	-- Role memberships
	DECLARE csrRoleMembership CURSOR FAST_FORWARD FOR
	SELECT
		'EXEC sp_addrolemember N''' + rolePrinciple.[name] + ''', N''' + @CopyToPrinciple + ''''
	FROM sys.database_role_members drm
	INNER JOIN sys.database_principals rolePrinciple
		ON rolePrinciple.[principal_id] = drm.[role_principal_id]
	INNER JOIN sys.database_principals memberPrinciple
		ON memberPrinciple.[principal_id] = drm.[member_principal_id]
	WHERE memberPrinciple.[name] = @CopyFromPrinciple
	
	OPEN csrRoleMembership
	FETCH NEXT FROM csrRoleMembership INTO @PermissionCommand
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT ' ' + @PermissionCommand
		EXEC (@PermissionCommand)
		FETCH NEXT FROM csrRoleMembership INTO @PermissionCommand
	END
	
	CLOSE csrRoleMembership
	DEALLOCATE csrRoleMembership

END
GO

--EXEC sys.sp_MS_marksystemobject 'sp_CopyDatabasePrinciplePermissions'

--EXEC [FundReporting].[dbo].[sp_CopyDatabasePrinciplePermissions] 'DOMAIN\ProductionServiceAccount', 'DOMAIN\UATServiceAccount'