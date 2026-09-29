[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\Payload.ps1')
$payload = Get-VendorMaxStackPayload -ProjectRoot $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$releaseDirectory = Join-Path $PSScriptRoot 'dist'
[IO.Directory]::CreateDirectory($releaseDirectory) | Out-Null
$releasePath = Join-Path $releaseDirectory "VendorMaxStack-$($payload.Version).zip"
$stream = [IO.File]::Open($releasePath, [IO.FileMode]::Create)
try {
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($file in $payload.Files) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.Source, "VendorMaxStack/$($file.Name)", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
    finally { $archive.Dispose() }
}
finally { $stream.Dispose() }
Write-Output "Archive de distribution : $releasePath"
