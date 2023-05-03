
# Copyright (c) Isaac Paul
# Licensed under the MIT License.

<#
.Synopsis
    Download and install sdl2 binaries, headers, and libraries.
.DESCRIPTION
    Download and install sdl2 binaries, headers, and libraries.
.EXAMPLE
    .\downloadBinaries.ps1
#>
param([string]$downloadAndExtractPath = ".download"

)

If (-Not (Test-Path $downloadAndExtractPath)) {
    New-Item -ItemType Directory -Path $downloadAndExtractPath -Force
}

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$moveToRoot = @("SDL2.dll", "SDL2_ttf.dll")

$libraries =
@(
    [pscustomobject]@{url="https://libsdl.org/release/SDL2-devel-2.26.5-VC.zip";name="SDL2";include="SDL2-2.26.5/include";x64Path="SDL2-2.26.5/lib/x64";x86Path="SDL2-2.26.5/lib/x64"},
    [pscustomobject]@{url="https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.20.2/SDL2_ttf-devel-2.20.2-VC.zip";name="SDL2";include="SDL2_ttf-2.20.2/include";x64Path="SDL2_ttf-2.20.2/lib/x64";x86Path="SDL2_ttf-2.20.2/lib/x64"},
    [pscustomobject]@{url="https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-devel-2.6.3-VC.zip";name="SDL2";include="SDL2_mixer-2.6.3/include";x64Path="SDL2_mixer-2.6.3/lib/x64";x86Path="SDL2_mixer-2.6.3/lib/x64"},
    [pscustomobject]@{url="https://github.com/libsdl-org/SDL_image/releases/download/release-2.6.3/SDL2_image-devel-2.6.3-VC.zip";name="SDL2";include="SDL2_image-2.6.3/include";x64Path="SDL2_image-2.6.3/lib/x64";x86Path="SDL2_image-2.6.3/lib/x64"}
)

$IsLinuxEnv = (Get-Variable -Name "IsLinux" -ErrorAction Ignore) -and $IsLinux
$IsMacOSEnv = (Get-Variable -Name "IsMacOS" -ErrorAction Ignore) -and $IsMacOS
$IsWinEnv = !$IsLinuxEnv -and !$IsMacOSEnv

if (-not $IsWinEnv) {
    throw "Currently for windows only. Install SDL2 via homebrew or apt."
}

switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { $architecture = "x64" }
    "x86" { $architecture = "x86" }
    default { throw "This script only supports x64 or x86 windows: '$_' is not supported." }
}

# The next two functions have the below copyright
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Expand an archive using Expand-archive when available
# and the DotNet API when it is not
function Expand-ArchiveInternal {

    [CmdletBinding()]

    param(
        $Path,
        $DestinationPath
    )

    if((Get-Command -Name Expand-Archive -ErrorAction Ignore))
    {
        Expand-Archive -Path $Path -DestinationPath $DestinationPath
    }
    else
    {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $resolvedDestinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($resolvedPath,$resolvedDestinationPath)

    }

}

if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
    # On Windows PowerShell, progress can make the download significantly slower
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
}

Write-Verbose "Creating folders." -Verbose

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
$null = New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction Stop

$contentPath = Join-Path -Path $tempDir -ChildPath "windows_bin"
$null = New-Item -ItemType Directory -Path $contentPath -ErrorAction SilentlyContinue

$includePath = Join-Path -Path $contentPath -ChildPath "include"
$null = New-Item -ItemType Directory -Path $includePath -ErrorAction SilentlyContinue

$libPath = Join-Path -Path $contentPath -ChildPath "lib"
$null = New-Item -ItemType Directory -Path $libPath -ErrorAction SilentlyContinue

$libx64Path = Join-Path -Path $libPath -ChildPath "x64"
$null = New-Item -ItemType Directory -Path $libx64Path -ErrorAction SilentlyContinue

$libx86Path = Join-Path -Path $libPath -ChildPath "x86"
$null = New-Item -ItemType Directory -Path $libx86Path -ErrorAction SilentlyContinue

function downloadAndExtract([string]$downloadURL, [string]$libraryName, [string]$includeDir, [string]$x64Path, [string]$x86Path) {
    Write-Verbose "About to download '$downloadURL'" -Verbose
    $endPiece = (Split-Path -Path $downloadURL -Leaf)
    $comps = $endPiece.Split(".")
    $fileName = $comps[0]
    #$extension = $comps[1]
    $downloadPath = Join-Path -Path $downloadAndExtractPath -ChildPath $endPiece
    $exPath = Join-Path -Path $downloadAndExtractPath -ChildPath $fileName

    If (Test-Path $downloadPath -PathType Leaf) {
        Write-Verbose "Download Exists." -Verbose
        If (Test-Path $exPath) {
            Write-Verbose "Removing previously extracted files." -Verbose
            Remove-Item -Recurse -Force $exPath
        }
    } else {
        try {
            Invoke-WebRequest -Uri $downloadURL -OutFile $downloadPath
        } finally {
            if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
                $ProgressPreference = $oldProgressPreference
            }
        }
        Write-Verbose "Download Complete." -Verbose
    }
    
    Write-Verbose "Extracting Zip." -Verbose
    Expand-ArchiveInternal -Path $downloadPath -DestinationPath $exPath
    
    Write-Verbose "Extract Complete. Creating include folder." -Verbose
    
    $includePathAny = Join-Path -Path $includePath -ChildPath $libraryName
    $null = New-Item -ItemType Directory -Path $includePathAny -ErrorAction SilentlyContinue


    Write-Verbose "Moving include files" -Verbose
    $exPathInclude = Join-Path -Path $exPath -ChildPath $includeDir
    Get-ChildItem -Recurse -File -Path $exPathInclude -Name | ForEach-Object -Process {
        $myLeaf = $_
        $src = Join-Path -Path $exPathInclude -ChildPath $myLeaf
        $targetPath = Join-Path -Path $includePathAny -ChildPath $myLeaf
        Write-Verbose "Moving: ${src} to ${targetPath}" -Verbose
        $parent = Split-Path -parent $targetPath
        If (-Not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force
        }
        Move-Item $src $targetPath
    }

    
    Write-Verbose "Moving x64 binaries" -Verbose
    $x64PathLib = Join-Path -Path $exPath -ChildPath $x64Path

    Get-ChildItem -Recurse -File -Path $x64PathLib -Name | ForEach-Object -Process {
        $myLeaf = $_
        $src = Join-Path -Path $x64PathLib -ChildPath $myLeaf
        $targetPath = Join-Path -Path $libx64Path -ChildPath $myLeaf
        Write-Verbose "Moving: ${src} to ${targetPath}" -Verbose
        $parent = Split-Path -parent $targetPath
        If (-Not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force
        }
        Move-Item $src $targetPath
    }

    if ($x86Path) {
        Write-Verbose "Moving x86 binaries" -Verbose
        $x86PathLib = Join-Path -Path $exPath -ChildPath $x86Path
    
        Get-ChildItem -Recurse -File -Path $x86PathLib -Name | ForEach-Object -Process {
            $myLeaf = $_
            $src = Join-Path -Path $x64PathLib -ChildPath $myLeaf
            $targetPath = Join-Path -Path $libx86Path -ChildPath $myLeaf
            Write-Verbose "Moving: ${src} to ${targetPath}" -Verbose
            $parent = Split-Path -parent $targetPath
            If (-Not (Test-Path $parent)) {
                New-Item -ItemType Directory -Path $parent -Force
            }
            Move-Item $src $targetPath
        }
    } else {
        Write-Verbose "x86 binaries not provided" -Verbose
    }
}

Write-Verbose "Starting downloads" -Verbose
Foreach ($item in $libraries) {
    downloadAndExtract $item.url $item.name $item.include $item.x64Path $item.x86Path
}

Write-Verbose "Moving needed dlls to directory root" -Verbose
$cwd = Get-Location
$arcPath = Join-Path -Path $libPath -ChildPath $architecture
Get-ChildItem -Recurse -File -Path $arcPath -Include *.dll | ForEach-Object {
    $src = $_.FullName
    $fileName = $(Split-Path -Path $src -Leaf)
    if ($fileName -in $moveToRoot) {
        $targetPath = Join-Path -Path $cwd -ChildPath $fileName
        Write-Verbose "Copying: ${src} to ${targetPath}" -Verbose
        Copy-Item $_.FullName $targetPath
    }
}


$targetWindowsBin = Join-Path -Path $cwd -ChildPath "windows_bin"
Write-Verbose "Moving: ${contentPath} to ${targetWindowsBin}" -Verbose


Remove-Item -Recurse -Force $targetWindowsBin
Move-Item $contentPath $cwd
Remove-Item -Recurse -Force $tempDir
Remove-Item -Recurse -Force $downloadAndExtractPath