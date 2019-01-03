--http://jongurgul.com/blog/sql-server-instance-security-scripting-permissions-part-2/
;WITH DatabaseAccounts(DatabaseName,IsOrphaned,ServerLogin,DatabaseLogin,DatabaseLoginSid,DatabaseUser,DefaultLanguage,DefaultDatabase,DefaultSchema,OwningPrincipal,PrincipalID, LoginType) AS
(
SELECT
QUOTENAME(DB_NAME()) [DatabaseName],
CAST((CASE WHEN spr.[name] IS NULL THEN 1 ELSE 0 END) AS BIT) [IsOrphaned],
QUOTENAME(SUSER_SNAME(dpr.[sid])) [ServerLogin],
QUOTENAME(ISNULL(SUSER_SNAME(dpr.[sid]),dpr.[name])) [DatabaseLogin],
dpr.[sid] [DatabaseLoginSid],
QUOTENAME(dpr.[name])[DatabaseUser],
QUOTENAME(spr.[default_language_name]) [DefaultLanguage],
QUOTENAME(spr.[default_database_name]) [DefaultDatabase],
QUOTENAME(dpr.[default_schema_name]) [DefaultSchema],
QUOTENAME(USER_NAME(dpr.[owning_principal_id])) [OwningPrincipal],
dpr.[principal_id] [PrincipalID],
dpr.[type_desc]
FROM sys.database_principals dpr
LEFT OUTER JOIN sys.server_principals spr ON dpr.[sid] = spr.[sid]
WHERE dpr.[type] IN ('S','G','U','R')
AND dpr.[is_fixed_role] = 0
AND dpr.[name] NOT IN ('public','dbo','guest','INFORMATION_SCHEMA','sys')
AND dpr.[name] NOT LIKE '##%'
)
SELECT * FROM
(
SELECT
'DatabaseCreateUser' [Description],
'USE'+ SPACE(1) +da.DatabaseName+';CREATE USER' + SPACE(1) + da.[DatabaseUser] + SPACE(1)
+ (CASE WHEN da.[ServerLogin] IS NULL THEN 'WITHOUT LOGIN' ELSE 'FOR'+ SPACE(1) +'LOGIN' + SPACE(1) + da.[DatabaseLogin] + SPACE(1) + ISNULL(('WITH DEFAULT_SCHEMA=' + da.[DefaultSchema]),'')+(CASE WHEN da.[IsOrphaned] = 1 THEN '--Orphan' ELSE '' END) END) COLLATE DATABASE_DEFAULT Commands
FROM DatabaseAccounts da
WHERE da.LoginType <> 'DATABASE_ROLE'
UNION ALL
SELECT
'DatabaseCreateRole' [Description],
'USE '+da.[DatabaseName]+';CREATE ROLE' + SPACE(1) + da.[DatabaseUser] + ISNULL((SPACE(1)+'AUTHORIZATION'+SPACE(1)+da.[OwningPrincipal]),'') COLLATE DATABASE_DEFAULT Commands
FROM DatabaseAccounts da
WHERE da.[LoginType] = 'DATABASE_ROLE'
UNION ALL
SELECT
'DatabaseAddUserToRole' [Description],
'EXEC '+QUOTENAME(DB_NAME())+'..sp_addrolemember N'''+user_name(rm.[role_principal_id])+''',N'''+user_name(rm.[member_principal_id])+'''' COLLATE DATABASE_DEFAULT Commands
FROM DatabaseAccounts da
INNER JOIN sys.database_role_members rm ON rm.[member_principal_id] = da.[PrincipalID]
UNION ALL
SELECT
'DatbaseAddUserPermission' [Description],
CASE
WHEN p.[class] = 1 AND p.[state_desc] = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT' + SPACE(1) + p.[permission_name] + SPACE(1) + 'ON' + SPACE(1) + (QUOTENAME(DB_NAME())+'.'+QUOTENAME(SCHEMA_NAME(sob.[schema_id]))+'.'+QUOTENAME(sob.[name])) + SPACE(1) + 'TO' + SPACE(1) + da.[DatabaseUser] + SPACE(1) + 'WITH GRANT OPTION'
WHEN p.[class] = 1 AND p.[state_desc] <> 'GRANT_WITH_GRANT_OPTION' THEN p.[state_desc] + SPACE(1) + p.[permission_name] + SPACE(1) + 'ON' + SPACE(1) + (QUOTENAME(DB_NAME())+'.'+QUOTENAME(SCHEMA_NAME(sob.[schema_id]))+'.'+QUOTENAME(sob.[name])) + SPACE(1) + 'TO' + SPACE(1) + da.[DatabaseUser]
WHEN p.[class] = 3 THEN 'GRANT' + SPACE(1) + p.[permission_name] + SPACE(1) + 'ON SCHEMA::' + QUOTENAME(SCHEMA_NAME(p.[major_id]))+ 'TO' + SPACE(1) + da.[DatabaseUser]
WHEN p.[class] <> 1 or p.[class] <> 3 THEN p.[state_desc] + SPACE(1) + p.[permission_name] + SPACE(1) + 'TO' + SPACE(1) + da.[DatabaseUser]
ELSE NULL
END COLLATE DATABASE_DEFAULT Commands
FROM sys.database_permissions AS p
LEFT OUTER JOIN sys.all_objects sob ON p.[major_id] = sob.[object_id]
INNER JOIN DatabaseAccounts da ON da.[PrincipalID] = p.[grantee_principal_id]
) x
UNION ALL
SELECT 'ServerCreateLogin' [Description],
CASE WHEN sp.[type] IN ('G','U') THEN 'CREATE LOGIN '+QUOTENAME(sp.[name])+' FROM WINDOWS WITH DEFAULT_DATABASE='+QUOTENAME(sp.[default_database_name])+', DEFAULT_LANGUAGE='+QUOTENAME(sp.[default_language_name])
WHEN sp.[type] = 'S' THEN 'CREATE LOGIN '+QUOTENAME(sp.[name])+' WITH PASSWORD = '+ master.dbo.[fn_varbintohexstr](CAST(LOGINPROPERTY(sp.[name],'passwordhash') AS VARBINARY(256)))+' HASHED'+',SID = '+master.dbo.[fn_varbintohexstr](sp.[sid])+',DEFAULT_DATABASE = '+QUOTENAME(sp.[default_database_name])+',DEFAULT_LANGUAGE = '+QUOTENAME(sp.[default_language_name])
END
FROM master.sys.server_principals sp
WHERE sp.[name] NOT LIKE '##%'
AND sp.[name] <> 'sa'
AND sp.[type] IN ('G','U','S')
UNION ALL
--Add ServerRoles
SELECT 'ServerAddToRole' [Description],'EXEC master..sp_addsrvrolemember @loginame = N''' + sp.[name] + ''', @rolename = N''' + sp2.[name] + ''''
FROM master.sys.server_role_members srm
INNER JOIN master.sys.server_principals sp2 ON srm.[role_principal_id] = sp2.[principal_id]
INNER JOIN master.sys.server_principals sp ON srm.[member_principal_id] = sp.[principal_id]
WHERE sp.[name] <> 'sa'
UNION ALL
SELECT
'ServerAddPermission' [Description],
CASE
WHEN p.[class_desc] = 'SERVER' AND p.[state_desc] = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT'+SPACE(1)+p.[permission_name]+SPACE(1)+'TO'+SPACE(1)+QUOTENAME(sp.name)+SPACE(1)+'WITH GRANT OPTION' COLLATE DATABASE_DEFAULT
WHEN p.[class_desc] = 'SERVER' THEN p.[state_desc]+SPACE(1)+p.[permission_name]+SPACE(1)+'TO'+SPACE(1)+QUOTENAME(sp.[name]) COLLATE DATABASE_DEFAULT
WHEN p.[class_desc] = 'ENDPOINT' AND p.[state_desc] = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT'+SPACE(1)+p.[permission_name]+SPACE(1)+'ON ENDPOINT::'+QUOTENAME(e.[name])+SPACE(1)+'TO'+SPACE(1)+QUOTENAME(sp.[name])+SPACE(1)+'WITH GRANT OPTION' COLLATE DATABASE_DEFAULT
WHEN p.[class_desc] = 'ENDPOINT' THEN p.[state_desc]+SPACE(1)+p.[permission_name]+SPACE(1)+'ON ENDPOINT::'+QUOTENAME(e.[name])+SPACE(1)+'TO'+SPACE(1)+QUOTENAME(sp.[name]) COLLATE DATABASE_DEFAULT
END
FROM sys.server_principals AS sp
INNER JOIN sys.server_permissions AS p ON sp.[principal_id] = p.[grantee_principal_id]
LEFT JOIN sys.endpoints e ON e.[endpoint_id]= p.[major_id]
WHERE sp.[name] NOT LIKE '##%'