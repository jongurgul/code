#http://jongurgul.com/blog/sql-server-instance-security-scripting-permissions/
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
$SQLInstanceName = $Env:COMPUTERNAME; #"ServerName\InstanceName"
$SQLInstance = New-Object "Microsoft.SqlServer.Management.Smo.Server" $SQLInstanceName;
$DatabaseNames = $null #@("master","etc") comma seperated List of databases or $null for all
$BatchSeperator = $null #$null for none, or "`r`nGO" for carriage return, line feed and batch seperator.
 
#Options
[Microsoft.SqlServer.Management.Smo.ScriptingOptions] $ScriptingOptions = New-Object "Microsoft.SqlServer.Management.Smo.ScriptingOptions";
$ScriptingOptions.TargetServerVersion = [Microsoft.SqlServer.Management.Smo.SqlServerVersion]::Version90; #Version90, Version100, Version105
$ScriptingOptions.AllowSystemObjects = $false
$ScriptingOptions.IncludeDatabaseRoleMemberships = $true
$ScriptingOptions.ContinueScriptingOnError = $false; #ignore scripts errors, advisable to set to $false
 
#Server Permissions#
"USE [master]$BatchSeperator";
 
#Server Logins - Integrated Windows Authentication
$SQLInstance.Logins | Where-Object {@("WindowsUser","WindowsGroup") -contains $_.LoginType} |% {$_.Script($ScriptingOptions)} |% {$_.ToString()+$BatchSeperator};
 
#Server Logins - SQL Authentication
$SQLAuthLoginsCommand =
"
SELECT
'CREATE LOGIN ' + QUOTENAME(sp.[name]) + ' WITH PASSWORD = ' + master.dbo.[fn_varbintohexstr](CAST(LOGINPROPERTY(sp.[name], 'passwordhash') AS VARBINARY(256))) + ' HASHED'
+',SID = ' + master.dbo.[fn_varbintohexstr](sl.[sid])
+',DEFAULT_DATABASE = ' + QUOTENAME(sl.[default_database_name])
+',DEFAULT_LANGUAGE = ' + QUOTENAME(sl.[default_language_name])
 +',CHECK_EXPIRATION = ' + CASE WHEN sl.[is_expiration_checked] = 1 THEN 'ON' ELSE 'OFF' END
 +',CHECK_POLICY = ' + CASE WHEN sl.[is_policy_checked] = 1 THEN 'ON' ELSE 'OFF' END
 +';'
FROM sys.sql_logins AS sl
INNER JOIN sys.server_principals AS sp ON sl.[principal_id] = sp.[principal_id]
WHERE sp.[name] <> 'sa' AND sp.[name] NOT LIKE '##%'
"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("server=$SQLInstanceName;Integrated Security=sspi;");
$SqlCommand = New-Object System.Data.SqlClient.SqlCommand;
$SqlCommand.Connection = $SqlConnection;
$SqlCommand.CommandText = $SQLAuthLoginsCommand;
 
$SqlConnection.Open();
$Reader = $SqlCommand.ExecuteReader();
While ($Reader.Read()){$Reader[0]+$BatchSeperator;}
$SqlConnection.Close();
 
#Server Roles
foreach ($Role in $SQLInstance.Roles){$Role.EnumServerRoleMembers() | Where-Object {$_ -ne "sa"} |% {"EXEC master..sp_addsrvrolemember @loginame = N'{0}', @rolename = N'{1}'{2}" -f ($_,$Role.Name,$BatchSeperator);}};
 
#Server Permissions
$SQLInstance.EnumServerPermissions() | Where-Object {@("sa","dbo","information_schema","sys") -notcontains $_.Grantee -and $_.Grantee -notlike "##*"} |% {
if ($_.PermissionState -eq "GrantWithGrant"){$wg = "WITH GRANT OPTION"} else {$wg = ""};
"{0} {1} TO [{2}] {3}{4}" -f ($_.PermissionState.ToString().Replace("WithGrant","").ToUpper(),$_.PermissionType,$_.Grantee,$wg,$BatchSeperator);
};
 
#Server Object Permissions
$SQLInstance.EnumObjectPermissions() | Where-Object {@("sa","dbo","information_schema","sys") -notcontains $_.Grantee} |% {
if ($_.PermissionState -eq "GrantWithGrant"){$wg = "WITH GRANT OPTION"} else {$wg = ""};
"{0} {1} ON {2}::[{3}] TO [{4}] {5}{6}" -f ($_.PermissionState.ToString().Replace("WithGrant","").ToUpper(),$_.PermissionType,$_.ObjectClass.ToString().ToUpper(),$_.ObjectName,$_.Grantee,$wg,$BatchSeperator);
};
 
#Database Permissions#
$SQLInstance.Databases | Where-Object {$DatabaseNames -contains $_.Name -or $DatabaseNames -eq $null} |% {
 
    $ScriptingOptions.IncludeDatabaseContext = $false;"USE ["+$_.Name+"]$BatchSeperator";#setting database context once.
 
    #Fixed Roles
    $_.Roles | Where {$_.IsFixedRole -eq $false} |% {$_.Script($ScriptingOptions)} | Sort-Object $_.ToString() |% {"{0}{1}" -f ($_.ToString(),$BatchSeperator)};#Dependency Issue. Create Role, before add to role. Solved by sort for now.
 
    #Database Create User(s) and add to Role(s)
    $_.Users | Where-Object {$_.IsSystemObject -eq $false -and $_.Name -notlike "##*"} |% {
    $_.Script($ScriptingOptions)} |% {
    if ($_.Contains("sp_addrolemember")){$me = "EXEC "} else {$me = ""};
    "{0}{1}{2}" -f ($me,$_,$BatchSeperator);
    };
 
    #Database Permissions
    $_.EnumDatabasePermissions() | Where-Object {@("sa","dbo","information_schema","sys") -notcontains $_.Grantee -and $_.Grantee -notlike "##*"} |% {
    if ($_.PermissionState -eq "GrantWithGrant"){$wg = "WITH GRANT OPTION"} else {$wg = ""};
    "{0} {1} TO [{2}] {3}{4}" -f ($_.PermissionState.ToString().Replace("WithGrant","").ToUpper(),$_.PermissionType,$_.Grantee,$wg,$BatchSeperator);
    };
 
    #Database Object Permissions
    $_.EnumObjectPermissions() | Where-Object {@("sa","dbo","information_schema","sys") -notcontains $_.Grantee -and $_.Grantee -notlike "##*"} |% {
    if ($_.ObjectClass -eq "Schema"){$obj = "SCHEMA::["+$_.ObjectName+"]"}
    elseif ($_.ObjectClass -eq "User"){$obj = "USER::["+$_.ObjectName+"]"}
    else {$obj = "["+$_.ObjectSchema+"].["+$_.ObjectName+"]"};
    if ($_.PermissionState -eq "GrantWithGrant"){$wg = "WITH GRANT OPTION"} else {$wg = ""};
    "{0} {1} ON {2} TO [{3}] {4}{5}" -f ($_.PermissionState.ToString().Replace("WithGrant","").ToUpper(),$_.PermissionType,$obj,$_.Grantee,$wg,$BatchSeperator);
    };
};