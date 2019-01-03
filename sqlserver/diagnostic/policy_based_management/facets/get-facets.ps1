Import-Module –Name SqlServer;

<#
	Get-Facets
#>
function Get-Facets {
	[CmdletBinding()]
Param(
	[Parameter(Position=0,
	Mandatory=$true,
	ValueFromPipeline,
	ValueFromPipelineByPropertyName)]
	[System.Data.SqlClient.SqlConnection]$SqlConnection,

	[Parameter(Position=1,
	Mandatory=$true,
	ValueFromPipeline,
	ValueFromPipelineByPropertyName)]
	[string]$Directory,
	
	[Parameter(Position=2,
	Mandatory=$false,
	ValueFromPipeline,
	ValueFromPipelineByPropertyName)]
	[string[]]$DatabaseList
	)
	begin {

	}
	process {
		$SqlStoreConnection = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SqlStoreConnection($SqlConnection);
		$PolicyStore = New-Object Microsoft.SQLServer.Management.DMF.PolicyStore($SqlStoreConnection);

		$XmlWriterSettings = New-Object System.Xml.XmlWriterSettings;
		$XmlWriterSettings.Indent = [System.Xml.Formatting]::Indented;
		$XmlWriterSettings.OmitXmlDeclaration = $true; #strip of declaration

		#Server Facet
		$ServerFacets = [Microsoft.SqlServer.Management.Dmf.PolicyStore]::Facets |?{$_.TargetTypes -contains [Microsoft.SqlServer.Management.Smo.Server]};
		$DataSource = $SqlConnection.DataSource;
		$SfcQueryExpression = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SfcQueryExpression("Server");

		If(($ServerFacets.Count -gt 0) -and ($SfcQueryExpression)){
		$ServerFacets|%{
                    $Guid = [Guid]::NewGuid();
                    $Policy = $_.Name;
                    $Name = "$($SqlConnection.DataSource.Replace('\','$'))_$($Policy)_$($Guid).xml"
                    $FullName = $(Join-Path -Path $Directory -ChildPath $Name);
                    $XmlWriter = [System.Xml.XmlWriter]::Create($FullName,$XmlWriterSettings);

                    $PolicyStore.CreatePolicyFromFacet($SfcQueryExpression,$($_.Name),$($_.Name),$($_.Name),$XmlWriter);

                    $XmlWriter.Flush();
                    $XmlWriter.Close();
                    $XmlWriter.Dispose();
                    [Void]$SqlStoreConnection.Disconnect();
                    $SqlConnection.Close();
 				}
		}

		#Database Facet
		if($DatabaseList.Count -ge 1){
			$DatabaseFacets = [Microsoft.SqlServer.Management.Dmf.PolicyStore]::Facets|?{$_.TargetTypes -contains [Microsoft.SqlServer.Management.Smo.Database]};
			Foreach($Database in ($DatabaseList | select -uniq))
			{
				If($Database.Length -gt 0)
				{
				$SfcQueryExpression = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SfcQueryExpression("Server/Database[@Name='$Database']");
						If(($DatabaseFacets.Count -gt 0) -and ($SfcQueryExpression)){
						$DatabaseFacets|%{
                                        $Guid = [Guid]::NewGuid();
                                        $Policy = $_.Name;
                                        $Name = "$($SqlConnection.DataSource.Replace('\','$'))_$($Policy)_$($Database)_$($Guid).xml"
                                        $FullName = $(Join-Path -Path $Directory -ChildPath $Name);
                                        $XmlWriter = [System.Xml.XmlWriter]::Create($FullName,$XmlWriterSettings);

										$PolicyStore.CreatePolicyFromFacet($SfcQueryExpression,$($_.Name),$($_.Name),$($_.Name),$XmlWriter);

										$XmlWriter.Flush();
										$XmlWriter.Close();
										$XmlWriter.Dispose();
 								}
						}
				}
			}
		}

	} 
}

$Server = "$env:COMPUTERNAME";
[System.Data.SqlClient.SqlConnection]$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$Server;Integrated Security=SSPI;Application Name=CoeoDiscovery");

$SmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server $SqlConnection;
$DatabaseList = $SmoServer.Databases.Name;
#$DatabaseList = @("master","model","tempdb");
$DatabaseList = @("master");
$Directory = 'C:\temp'

Get-Facets $SqlConnection $Directory $DatabaseList;
