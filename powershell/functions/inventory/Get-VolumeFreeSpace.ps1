Function Get-VolumeFreeSpace {
    <#
.SYNOPSIS
    Get-VolumeFreeSpace
.DESCRIPTION
	Get-VolumeFreeSpace
.NOTES
    
	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    http://jongurgul.com/blog/get-volumefreespace/ 
.PARAMETER Computers
	Computers

.EXAMPLE
	Get-VolumeFreeSpace
    
    Simple example.
#>

    Param([String[]]$Computers) 
    If (!$Computers) {$Computers = $ENV:ComputerName} 
    $Base = New-Object PSObject; 
    $Base | Add-Member Noteproperty ComputerName -Value $Null; 
    $Base | Add-Member Noteproperty DeviceID -Value $Null; 
    $Base | Add-Member Noteproperty SystemVolume -Value $Null; 
    $Base | Add-Member Noteproperty DriveType -Value $Null; 
    $Base | Add-Member Noteproperty Name -Value $Null; 
    $Base | Add-Member Noteproperty MountPoint -Value $Null; 
    $Base | Add-Member Noteproperty FreeSpaceGiB -Value $Null; 
    $Results = New-Object System.Collections.Generic.List[System.Object]; 
 
    ForEach ($Computer in $Computers) { 
        $Volume = Get-WmiObject -Class "Win32_Volume" -ComputerName $Computer; 
        $MountPoint = Get-WmiObject -Class "Win32_MountPoint" -ComputerName $Computer | Select @{Name = "DeviceID"; Expression = {$_.Volume.ToString().Substring($_.Volume.ToString().IndexOf("`"")).Replace("`"", "").Replace("\\", "\")}}, @{Name = "MountPoint"; Expression = {$_.Directory.ToString().Substring($_.Volume.ToString().IndexOf("`"")).Replace("`"", "").Replace("\\", "\")}};   
        [String[]]$Mounts = $MountPoint| % {$_.DeviceID} 
        $Volume | % { 
            $Entry = $Base | Select-Object * 
            $Entry.ComputerName = $Computer; 
            $Entry.DeviceID = $_.DeviceID; 
            $Entry.SystemVolume = $_.SystemVolume; 
            $Entry.DriveType = $_.DriveType; 
            $Entry.Name = $_.Name; 
            $Entry.FreeSpaceGiB = [Math]::Round($_.FreeSpace / 1GB, 3); 
            $DeviceID = $_.DeviceID;         
            $MountPoint| Where-Object {$DeviceID -contains $_.DeviceID}| % {
                $Local = $Entry | Select-Object *
                $Local.MountPoint = $_.MountPoint;
                [Void]$Results.Add($Local);
            }; 
            $_|Where-Object {$Mounts -notcontains $_.DeviceID}| % {[Void]$Results.Add($Entry); }; 
        } 
    }     
    $Results 
}