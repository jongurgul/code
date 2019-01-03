#http://jongurgul.com/blog/wmi-classes-powershell/
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null;
Function Get-WMIClassInstanceAsXML($Path="root\cimv2",  $Class = "Win32_Processor", $Computer= $Env:COMPUTERNAME){
$StringBuilder = New-Object "System.Text.StringBuilder"
$ManagementPath = New-Object System.Management.ManagementPath("\\$Computer\$Path`:$Class");
$ManagementScope = New-Object System.Management.ManagementScope($ManagementPath);
$ObjectGetOptions = New-Object System.Management.ObjectGetOptions;
$ObjectGetOptions.UseAmendedQualifiers = $True;
$ManagementScope.Connect();
$ManagementClass = New-Object System.Management.ManagementClass($ManagementScope,$ManagementPath,$ObjectGetOptions);
 
[Void]$StringBuilder.Append("<$Class>");
$ManagementClass.PSBase.GetInstances()|%{
$_.PSBase.Properties|%{
If($_.Value){[Void]$StringBuilder.Append("<$($_.Name)>$([System.Web.HttpUtility]::HtmlEncode($_.Value).Replace([Char]0x1F, ' '))</$($_.Name)>")}
}
}
[Void]$StringBuilder.Append("</$Class>");
$StringBuilder.ToString();
}