--http://jongurgul.com/blog/checking-permissions-sql-server
CREATE USER Meow WITHOUT LOGIN
 
SELECT SUSER_NAME() [LoginName],USER_NAME() [DatabaseLoginName];
 
EXECUTE AS USER = 'Meow'
--EXECUTE AS LOGIN = 'Meow'
 
SELECT * FROM
(
SELECT SUSER_NAME() [LoginName],USER_NAME() [DatabaseLoginName],2 [Level],ao.[name],p.[permission_name],p.[entity_name],p.[subentity_name]
FROM sys.all_objects ao
CROSS APPLY sys.fn_my_permissions(QUOTENAME(ao.[name]),'OBJECT') p
UNION ALL
SELECT SUSER_NAME() [LoginName],USER_NAME() [DatabaseLoginName],1,db_name () [name],p.[permission_name],p.[entity_name],p.[subentity_name]
FROM sys.fn_my_permissions(NULL, 'DATABASE') p
UNION ALL
SELECT SUSER_NAME() [LoginName],USER_NAME() [DatabaseLoginName],0,@@SERVERNAME,p.[permission_name],p.[entity_name],p.[subentity_name]
FROM sys.fn_my_permissions(NULL, 'SERVER') p
) x
ORDER BY 1,2,3
REVERT
 
SELECT SUSER_NAME() [LoginName],USER_NAME() [DatabaseLoginName];
 
DROP USER Meow