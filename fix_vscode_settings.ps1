<#
.Synopsis
    Updates .vscode/settings.json to point to windows_bin with an absolute path
.DESCRIPTION
    Updates .vscode/settings.json to point to windows_bin with an absolute path
.EXAMPLE
    .\fix_vscode_settings.ps1
#>

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$cwd = Get-Location
$cwdStr = "${cwd}"
Write-Host "Current Working Directory: $cwd"
Write-Host "Current Working Directory: $cwdStr"
$filePath = Join-Path -Path $cwd -ChildPath '.vscode/settings.json'
$content = Get-Content -Path $filePath
$tempFilePath = "$env:TEMP\$($filePath | Split-Path -Leaf)"
$exCwd = $cwdStr.Replace('\','\\') #Because googling how to escape a string doesn't help me >:|

$content -replace ('((?<="-I).+(?=\\\\windows_bin))', $exCwd) | Add-Content -Path $tempFilePath
$content2 = Get-Content -Path $tempFilePath
$content2 -replace ('((?<="-L).+(?=\\\\windows_bin))', $exCwd) | Set-Content -Path $tempFilePath

Remove-Item -Path $filePath
Move-Item -Path $tempFilePath -Destination $filePath
