#http://jongurgul.com/blog/quick-data-wipe-truncate/
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
[Microsoft.SqlServer.Management.Smo.ScriptingOptions] $ScriptingOptions = New-Object "Microsoft.SqlServer.Management.Smo.ScriptingOptions";
$ScriptingOptions.TargetServerVersion = [Microsoft.SqlServer.Management.Smo.SqlServerVersion]::Version90; #Version90, Version100, Version105
$ScriptingOptions.ContinueScriptingOnError = $false; #ignore scripts errors, advisable to keep set to $false
$SqlInstance = New-Object "Microsoft.SqlServer.Management.Smo.Server" "(local)"; 
$SqlInstance.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Table], "IsSystemObject");
$SqlInstance.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject");
$Database = $SqlInstance.Databases["AdventureWorks"];
$DropFKScript = $null;
$TruncateScript = $null;
$CreateFKScript = $null;
$SchemaBound = $($Database.Views|Where-Object {!$_.IsSystemObject -and $_.IsSchemaBound}|%{$_});
cls;
If ($SchemaBound -eq $null){
	$Database.Tables|%{$_.ForeignKeys}|%{
	$ScriptingOptions.DriForeignKeys = $true;
	$ScriptingOptions.SchemaQualifyForeignKeysReferences = $true;
	$ScriptingOptions.ScriptDrops = $false;
	$CreateFKScript += "{0}`r`nGO`r`n" -f $($_.Script($ScriptingOptions));
	$ScriptingOptions.ScriptDrops = $true;
	$DropFKScript += "{0}`r`nGO`r`n" -f $($_.Script($ScriptingOptions));
	}
	$TruncateScript += $Database.Tables|Where-Object {!$_.IsSystemObject}|%{"TRUNCATE TABLE [{0}].[{1}]" -f ($_.Schema,$_.Name)};
}
Else{
	Write-Host "Schema Bound Objects Present:";
	$SchemaBound|%{"[{0}].[{1}]" -f ($_.Schema,$_.Name)};
}
$DropFKScript;
$TruncateScript;
$CreateFKScript;
