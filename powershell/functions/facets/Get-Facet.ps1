If(!(Get-Module SqlServer)){Import-Module SqlServer};
Function Get-Facet {
    <#
.SYNOPSIS
    Get-Facet
.DESCRIPTION
	Get-Facet
.NOTES

	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    https://www.jongurgul.com
.PARAMETER SqlConnection
	SqlConnection
.PARAMETER Directory
	Directory
.PARAMETER DatabaseList
	DatabaseList
.EXAMPLE
	[System.Data.SqlClient.SqlConnection]$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$Env:COMPUTERNAME\SQL2017;Integrated Security=SSPI;Application Name=master");
	$DatabaseList = @("master","model","tempdb");
	$Directory = 'F:\'

    Get-Facet -SqlConnection $SqlConnection -DatabaseList $DatabaseList -Directory $Directory;

.EXAMPLE
	[System.Data.SqlClient.SqlConnection]$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$Env:COMPUTERNAME\SQL2017;Integrated Security=SSPI;Application Name=master");
	$DatabaseList = @("master","model","tempdb");
	$Directory = 'F:\'

    Get-Facet -SqlConnection $SqlConnection -DatabaseList $DatabaseList | ForEach-Object {
    Export-XmlToFile -Xml $_.Xml.InnerXml -Directory 'F:\' -Name $_.FileName
   }

#>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)][System.Data.SqlClient.SqlConnection]$SqlConnection,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)][string[]]$DatabaseList,
        [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)][string]$Directory

    )
    begin {

    }
    process {
        $ReturnObject = New-Object "System.Collections.Generic.List[System.Object]";

        $Base = New-Object PSObject;
        $Base | Add-Member Noteproperty FileName -Value $Null;
        $Base | Add-Member Noteproperty Xml -Value $Null;

        $SqlStoreConnection = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SqlStoreConnection($SqlConnection);
        $PolicyStore = New-Object Microsoft.SQLServer.Management.DMF.PolicyStore($SqlStoreConnection);

        $XmlWriterSettings = New-Object System.Xml.XmlWriterSettings;
        $XmlWriterSettings.Indent = [System.Xml.Formatting]::Indented;
        $XmlWriterSettings.OmitXmlDeclaration = $true; #strip of declaration

        #Server Facet
        $ServerFacets = [Microsoft.SqlServer.Management.Dmf.PolicyStore]::Facets | Where-Object {$_.TargetTypes -contains [Microsoft.SqlServer.Management.Smo.Server]};
        #$DataSource = $SqlConnection.DataSource;
        $SfcQueryExpression = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SfcQueryExpression("Server");

        If (($ServerFacets.Count -gt 0) -and ($SfcQueryExpression)) {
            $ServerFacets | ForEach-Object {
                $Guid = [Guid]::NewGuid();
                $Policy = $_.Name;

                $Name = "$($SqlConnection.DataSource.Replace('\','$'))_$($Policy)_$($Guid).xml"
                If ($Directory.Length -gt 0) {
                    $FullName = $(Join-Path -Path $Directory -ChildPath $Name);
                    $fw = [System.Xml.XmlWriter]::Create($FullName, $XmlWriterSettings);
                    $PolicyStore.CreatePolicyFromFacet($SfcQueryExpression, $($_.Name), $($_.Name), $($_.Name), $fw);

                    $fw.Flush();
                    $fw.Close();
                    $fw.Dispose();
                }
                Else {
                    $MemoryStream = New-Object System.IO.MemoryStream;
                    $mw = [System.Xml.XmlWriter]::Create($MemoryStream, $XmlWriterSettings);
                    $PolicyStore.CreatePolicyFromFacet($SfcQueryExpression, $($_.Name), $($_.Name), $($_.Name), $mw);

                    $mw.Flush();
                    $mw.Close();
                    $mw.Dispose();

                    [Void]$MemoryStream.Seek(0, "Begin");
                    $StreamReader = New-Object System.IO.StreamReader($MemoryStream);
                    [xml]$Xml = $StreamReader.ReadToEnd();

                    $StreamReader.Close();
                    $StreamReader.Dispose();

                    $MemoryStream.Close();
                    $MemoryStream.Dispose();


                    $Entry = $Base | Select-Object *
                    $Entry.FileName = $Name;
                    $Entry.Xml = $Xml;

                    [Void]$ReturnObject.Add($Entry);
                }

                [Void]$SqlStoreConnection.Disconnect();
                $SqlConnection.Close();

            }
        }

        #Database Facet
        if ($DatabaseList.Count -ge 1) {
            $DatabaseFacets = [Microsoft.SqlServer.Management.Dmf.PolicyStore]::Facets | Where-Object {$_.TargetTypes -contains [Microsoft.SqlServer.Management.Smo.Database]};
            Foreach ($Database in ($DatabaseList | Select-Object -uniq)) {
                If ($Database.Length -gt 0) {
                    $SfcQueryExpression = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SfcQueryExpression("Server/Database[@Name='$Database']");
                    If (($DatabaseFacets.Count -gt 0) -and ($SfcQueryExpression)) {
                        $DatabaseFacets | ForEach-Object {
                            $Guid = [Guid]::NewGuid();
                            $Policy = $_.Name;

                            $Name = "$($SqlConnection.DataSource.Replace('\','$'))_$($Policy)_$($Database)_$($Guid).xml"
                            If ($Directory.Length -gt 0) {
                                $FullName = $(Join-Path -Path $Directory -ChildPath $Name);
                                $fw = [System.Xml.XmlWriter]::Create($FullName, $XmlWriterSettings);
                                $PolicyStore.CreatePolicyFromFacet($SfcQueryExpression, $($_.Name), $($_.Name), $($_.Name), $fw);

                                $fw.Flush();
                                $fw.Close();
                                $fw.Dispose();
                            }
                            Else {
                                $MemoryStream = New-Object System.IO.MemoryStream;
                                $mw = [System.Xml.XmlWriter]::Create($MemoryStream, $XmlWriterSettings);
                                $PolicyStore.CreatePolicyFromFacet($SfcQueryExpression, $($_.Name), $($_.Name), $($_.Name), $mw);

                                $mw.Flush();
                                $mw.Close();
                                $mw.Dispose();

                                [Void]$MemoryStream.Seek(0, "Begin");
                                $StreamReader = New-Object System.IO.StreamReader($MemoryStream);
                                [xml]$Xml = $StreamReader.ReadToEnd();

                                $StreamReader.Close();
                                $StreamReader.Dispose();

                                $MemoryStream.Close();
                                $MemoryStream.Dispose();

			                    $Entry = $Base | Select-Object *
                                $Entry.FileName = $Name;
                                $Entry.Xml = $Xml;

                                [Void]$ReturnObject.Add($Entry);
                            }

                            [Void]$SqlStoreConnection.Disconnect();
                            $SqlConnection.Close();

                        }
                    }
                }
            }
        }
    }
    end {
        return $ReturnObject;
    }
}