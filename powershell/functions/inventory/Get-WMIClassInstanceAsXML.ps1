#http://jongurgul.com/blog/wmi-classes-powershell/
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null;
Function Get-WMIClassInstanceAsXML($Path = "root\cimv2", $Class = "Win32_Processor", $Computer = $Env:COMPUTERNAME) {
    <#
.SYNOPSIS
    Get-WMIClassInstanceAsXML
.DESCRIPTION
	Get-WMIClassInstanceAsXML
.NOTES

	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    http://jongurgul.com/blog/wmi-classes-powershell/
.PARAMETER Path
    Path
.PARAMETER Class
    Class
.PARAMETER Computer
	Computer
.EXAMPLE
	Get-WMIClassInstanceAsXML "root\cimv2" "Win32_Printer" "ComputerA"
    .
    Returns printers.
#>
    $StringBuilder = New-Object "System.Text.StringBuilder"
    $ManagementPath = New-Object System.Management.ManagementPath("\\$Computer\$Path`:$Class");
    $ManagementScope = New-Object System.Management.ManagementScope($ManagementPath);
    $ObjectGetOptions = New-Object System.Management.ObjectGetOptions;
    $ObjectGetOptions.UseAmendedQualifiers = $True;
    $ManagementScope.Connect();
    $ManagementClass = New-Object System.Management.ManagementClass($ManagementScope, $ManagementPath, $ObjectGetOptions);

    [Void]$StringBuilder.Append("<$Class>");
    $ManagementClass.PSBase.GetInstances()| ForEach-Object {
        $_.PSBase.Properties| ForEach-Object {
            If ($_.Value) {[Void]$StringBuilder.Append("<$($_.Name)>$([System.Web.HttpUtility]::HtmlEncode($_.Value).Replace([Char]0x1F, ' '))</$($_.Name)>")}
        }
    }
    [Void]$StringBuilder.Append("</$Class>");
    $StringBuilder.ToString();
}