function Get-VendorMaxStackPayload {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $addonRoot = Join-Path $ProjectRoot 'VendorMaxStack'
    $tocPath = Join-Path $addonRoot 'VendorMaxStack.toc'
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) { throw "TOC introuvable : $tocPath" }
    $toc = Get-Content -LiteralPath $tocPath -Encoding UTF8
    $versionLine = $toc | Where-Object { $_ -match '^## Version:\s*' } | Select-Object -First 1
    if ($versionLine -notmatch '^## Version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$') { throw 'Version du TOC invalide.' }
    $version = $Matches[1]
    $names = @('VendorMaxStack.toc', 'README.md', 'LICENSE', 'CHANGELOG.md')
    $names += @($toc | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } | ForEach-Object { $_.Trim() })
    $files = foreach ($name in ($names | Select-Object -Unique)) {
        if ($name -notmatch '^[A-Za-z0-9_-]+(?:\.(?:lua|toc|md))?$') { throw "Nom de fichier invalide : $name" }
        $sourceRoot = if ($name -in @('LICENSE', 'CHANGELOG.md')) { $ProjectRoot } else { $addonRoot }
        $source = Join-Path $sourceRoot $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Fichier source introuvable : $source" }
        [PSCustomObject]@{ Name = $name; Source = $source }
    }
    [PSCustomObject]@{ Version = $version; Files = @($files); SourceRoot = $addonRoot }
}
