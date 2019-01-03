#http://jongurgul.com/blog/capturing-deadlocks/
$Computer = $Env:COMPUTERNAME;
$Path = "\\$Computer\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER";
$FileDirectory = "";
Write-Host $Path
$WQlEventQuery = New-Object "System.Management.WQlEventQuery" "SELECT * FROM DeadLock_GRAPH";
$ConnectionOptions = New-Object "System.Management.ConnectionOptions";
#$Credential = Get-Credential;
#$ConnectionOptions.Username = $Credential.Username;
#$ConnectionOptions.SecurePassword = $Credential.Password;

$ManagementScope = New-Object System.Management.ManagementScope ($Path, $ConnectionOptions);
$ManagementEventWatcher = New-Object System.Management.ManagementEventWatcher ($ManagementScope, $WQlEventQuery);
$Data = $null;
$ManagementBaseObject = $null;

try{
Write-Host "Waiting for watcher";
$ManagementEventWatcher.Start();
Write-Host "Waiting for next event";
[System.Management.ManagementBaseObject] $ManagementBaseObject = $ManagementEventWatcher.WaitForNextEvent();
}
catch
{
Write-Host -foregroundcolor Red "$($_.Exception.Message)";
}
finally
{
$ManagementEventWatcher.Stop();
}
$PathWithFile = $FileDirectory+((Get-Date -Format "yyyy-MM-ddThh-mm-ssZ")+"-"+$Computer+".xdl");
$Data =([xml]$ManagementBaseObject.TextData).FirstChild.InnerXml.ToString();
if ($Data){Add-Content $PathWithFile $Data;};