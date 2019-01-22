
Function Get-StringHash([String] $FileName, $HashName = "MD5") {
    <#
.SYNOPSIS
    Get-StringHash
.DESCRIPTION
	Get-StringHash
.NOTES

	Author: Jon Gurgul
	License: AGPL-3.0-only
.LINK
    http://jongurgul.com/blog/get-stringhash-get-filehash/
.PARAMETER FileName
	String to hash.
.PARAMETER HashName
	HashAlgorithm name.
.EXAMPLE
	Get-StringHash "My String to hash" "MD5"

    Hash a string.
#>

    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String)) | ForEach-Object {
        [Void]$StringBuilder.Append($_.ToString("x2"))
    }
    $StringBuilder.ToString()
}