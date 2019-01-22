#http://jongurgul.com/blog/regain-access-sql-server-inject-service
If(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    $You = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
    $ImagePath = $(Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SQLWriter" -Name ImagePath).ImagePath;
    #"C:\Program Files\Microsoft SQL Server\90\Shared\sqlwriter.exe";
    $SQLCMDPaths = $(Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server\" -include SQLCMD.exe -Recurse | Select-Object FullName,Directory,@{Name="Version";Expression={$_.Directory.ToString().Split("\")[-3]}} | Sort-Object Version -Descending);
    $SQLCMDPath = $SQLCMDPaths[0].FullName;
    $SQLCMDPath;
    
        If(Test-Path $SQLCMDPath){
            $InjectedImagePath = "$SQLCMDPath -S . -E -Q `"CREATE LOGIN [$You] FROM WINDOWS;EXECUTE sp_addsrvrolemember @loginame = '$You', @rolename = 'sysadmin'`"";

            #Stop SQLWriter
            Get-Service -Name SQLWriter | Stop-Service -ea SilentlyContinue;

            #Inject
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SQLWriter" -Name ImagePath -Value $InjectedImagePath;
            Write-Host $(Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SQLWriter" -Name ImagePath).ImagePath;
            Get-Service -Name SQLWriter | Start-Service -ea SilentlyContinue;

            #Restore
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SQLWriter" -Name ImagePath -Value $ImagePath;
            Write-Host $(Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SQLWriter" -Name ImagePath).ImagePath;

            #Restart SQLWriter
            Get-Service -Name SQLWriter | Start-Service -ea SilentlyContinue;
        }Else{"Check SQLCMDPath";}
}Else{"Not Administrator"};