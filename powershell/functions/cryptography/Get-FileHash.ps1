Function Get-FileHash([String] $FileName,$HashName = "MD5"){
    <#
.SYNOPSIS
    Get-FileHash
.DESCRIPTION
	Get-FileHash
.NOTES
    
	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    http://jongurgul.com/blog/get-stringhash-get-filehash/
.PARAMETER FileName
	File to hash.
.PARAMETER HashName
	HashAlgorithm name.
.EXAMPLE
	Get-FileHash "C:\MyFile.txt" "MD5"
	
#>
{
$FileStream = New-Object System.IO.FileStream($FileName,[System.IO.FileMode]::Open)
$StringBuilder = New-Object System.Text.StringBuilder
[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash($FileStream)|%{[Void]$StringBuilder.Append($_.ToString("x2"))}
$FileStream.Close()
$StringBuilder.ToString()
}