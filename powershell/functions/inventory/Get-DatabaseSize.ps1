If (!(Get-Module SqlServer)) {Import-Module SqlServer};

Function Get-DatabaseSize([String] $SQLInstanceName = $Env:COMPUTERNAME) {
    <#
.SYNOPSIS
    Get-DatabaseSize
.DESCRIPTION
	Get-DatabaseSize
.NOTES

	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    http://jongurgul.com/blog/Get-DatabaseSizes/
.PARAMETER SQLInstanceName
	SQLInstanceName
.EXAMPLE
	Get-DatabaseSize . | Where-Object {$_.DatabaseName -like "m*"}

    Wild card search.
#>
    $SQLInstance = New-Object "Microsoft.SqlServer.Management.Smo.Server" $SQLInstanceName;
    $Results = New-Object System.Collections.Generic.List[System.Object];
    ForEach ($db in $SQLInstance.Databases) {
        ForEach ($fg in $db.FileGroups) {
            $Results += $fg.Files | Select-Object @{Name = "DatabaseName"; Expression = {$db.Name}},
            @{Name = "FileGroupName"; Expression = {$fg.Name}},
            @{Name = "SpaceUsed_MiB"; Expression = {([Math]::Round($_.UsedSpace / 1KB, 3))}},
            @{Name = "AvailableSpace_MiB"; Expression = {([Math]::Round(($_.Size - $_.UsedSpace) / 1KB, 3))}},
            @{Name = "Size_KiB"; Expression = {$_.Size}},
            @{Name = "Size_MiB"; Expression = {([Math]::Round($_.Size / 1KB, 3))}},
            @{Name = "Size_GiB"; Expression = {([Math]::Round($_.Size / 1MB, 3))}},
            @{Name = "Size_bytes"; Expression = {($_.Size * 1024)}},
            @{Name = "AutoGrowth"; Expression = {if ($_.GrowthType -eq "Percent") {$_.Growth.ToString() + " %"}else {([Math]::Round($_.Growth / 1KB, 3)).ToString() + " MiB"}}},
            @{Name = "MaxSize"; Expression = {($_.MaxSize)}},
            @{Name = "FileType"; Expression = {"ROWS"}},
            @{Name = "IsOffline"; Expression = {($_.IsOffline)}},
            @{Name = "IsReadOnly"; Expression = {($_.IsReadOnly)}},
            @{Name = "LogicalName"; Expression = {($_.Name)}},
            @{Name = "FileID"; Expression = {($_.ID)}},
            @{Name = "FileName"; Expression = {($_.FileName.Substring($_.FileName.LastIndexOf("\") + 1))}},
            @{Name = "Path"; Expression = {($_.FileName)}}
        }
        $Results += $db.LogFiles| Select-Object @{Name = "DatabaseName"; Expression = {$db.Name}},
        @{Name = "FileGroupName"; Expression = {$null}},
        @{Name = "SpaceUsed_MiB"; Expression = {([Math]::Round($_.UsedSpace / 1KB, 3))}},
        @{Name = "AvailableSpace_MiB"; Expression = {([Math]::Round(($_.Size - $_.UsedSpace) / 1KB, 3))}},
        @{Name = "Size_KiB"; Expression = {$_.Size}},
        @{Name = "Size_MiB"; Expression = {([Math]::Round($_.Size / 1KB, 3))}},
        @{Name = "Size_GiB"; Expression = {([Math]::Round($_.Size / 1MB, 3))}},
        @{Name = "Size_bytes"; Expression = {($_.Size * 1024)}},
        @{Name = "AutoGrowth"; Expression = {if ($_.GrowthType -eq "Percent") {$_.Growth.ToString() + " %"}else {([Math]::Round($_.Growth / 1KB, 3)).ToString() + " MiB"}}},
        @{Name = "MaxSize"; Expression = {($_.MaxSize)}},
        @{Name = "FileType"; Expression = {"LOG"}},
        @{Name = "IsOffline"; Expression = {($_.IsOffline)}},
        @{Name = "IsReadOnly"; Expression = {($_.IsReadOnly)}},
        @{Name = "LogicalName"; Expression = {($_.Name)}},
        @{Name = "FileID"; Expression = {($_.ID)}},
        @{Name = "FileName"; Expression = {($_.FileName.Substring($_.FileName.LastIndexOf("\") + 1))}},
        @{Name = "Path"; Expression = {($_.FileName)}}
    }
    RETURN $Results
}