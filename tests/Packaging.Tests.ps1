[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path $projectRoot ('.test-output\packaging-' + [Guid]::NewGuid().ToString('N'))
$addons = Join-Path $testRoot "Dossier d'essai avec espaces\AddOns"
[IO.Directory]::CreateDirectory($addons) | Out-Null
$powershell = Join-Path $PSHOME 'powershell.exe'
$installer = Join-Path $projectRoot 'Install-Addon.ps1'
$builder = Join-Path $projectRoot 'Build-Release.ps1'
$checks = 0
function Assert-That([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
    $script:checks++
    Write-Output "PASS $message"
}

foreach ($file in @($installer, $builder, (Join-Path $projectRoot 'scripts\Payload.ps1'), $PSCommandPath)) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-That ($errors.Count -eq 0) "Syntaxe PowerShell : $([IO.Path]::GetFileName($file))"
}
. (Join-Path $projectRoot 'scripts\Payload.ps1')
$payload = Get-VendorMaxStackPayload -ProjectRoot $projectRoot
$target = Join-Path $addons 'VendorMaxStack'

& $powershell -NoProfile -ExecutionPolicy Bypass -File $installer -AddOnsPath $addons -WhatIf
Assert-That ($LASTEXITCODE -eq 0) 'WhatIf se termine sans erreur'
Assert-That (-not (Test-Path -LiteralPath $target)) 'WhatIf ne cree aucun dossier addon'

$otherAddon = Join-Path $addons 'AutreAddon'
[IO.Directory]::CreateDirectory($otherAddon) | Out-Null
[IO.File]::WriteAllText((Join-Path $otherAddon 'temoin.txt'), 'ne pas modifier')
& $powershell -NoProfile -ExecutionPolicy Bypass -File $installer -AddOnsPath $addons
Assert-That ($LASTEXITCODE -eq 0) 'Installation reussie avec espaces et apostrophe dans le chemin'
foreach ($file in $payload.Files) {
    Assert-That ((Get-FileHash -LiteralPath $file.Source).Hash -eq (Get-FileHash -LiteralPath (Join-Path $target $file.Name)).Hash) "Copie identique : $($file.Name)"
}
Assert-That ((Get-ChildItem -LiteralPath $target -File).Count -eq $payload.Files.Count) 'Seuls les fichiers distribuables sont installes'

[IO.File]::WriteAllText((Join-Path $target 'Core.lua'), '-- ancienne version')
& $powershell -NoProfile -ExecutionPolicy Bypass -File $installer -AddOnsPath $addons
Assert-That ($LASTEXITCODE -eq 0) 'Mise a jour reussie'
Assert-That ((Get-FileHash -LiteralPath (Join-Path $target 'Core.lua')).Hash -eq (Get-FileHash -LiteralPath (Join-Path $payload.SourceRoot 'Core.lua')).Hash) 'Mise a jour remplace les anciens fichiers'
Assert-That ([IO.File]::ReadAllText((Join-Path $otherAddon 'temoin.txt')) -eq 'ne pas modifier') 'Les autres addons restent inchanges'

& $powershell -NoProfile -ExecutionPolicy Bypass -File $installer -AddOnsPath (Join-Path $testRoot 'absent')
Assert-That ($LASTEXITCODE -ne 0) 'Dossier AddOns absent signale avec code erreur'
& $powershell -NoProfile -ExecutionPolicy Bypass -File $installer -AddOnsPath $projectRoot
Assert-That ($LASTEXITCODE -ne 0) 'Copie du dossier source sur lui-meme refusee'

# A staging source verifies validation happens before creating the destination.
$brokenRoot = Join-Path $testRoot 'source-incomplete'
[IO.Directory]::CreateDirectory((Join-Path $brokenRoot 'scripts')) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $brokenRoot 'VendorMaxStack')) | Out-Null
Copy-Item -LiteralPath $installer -Destination $brokenRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'scripts\Payload.ps1') -Destination (Join-Path $brokenRoot 'scripts')
Copy-Item -LiteralPath (Join-Path $payload.SourceRoot 'VendorMaxStack.toc') -Destination (Join-Path $brokenRoot 'VendorMaxStack')
& $powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $brokenRoot 'Install-Addon.ps1') -AddOnsPath $addons
Assert-That ($LASTEXITCODE -ne 0) 'Fichiers sources incomplets refuses'
Assert-That ((Get-FileHash -LiteralPath (Join-Path $target 'Core.lua')).Hash -eq (Get-FileHash -LiteralPath (Join-Path $payload.SourceRoot 'Core.lua')).Hash) 'Echec de validation conserve la version installee'

& $powershell -NoProfile -ExecutionPolicy Bypass -File $builder
Assert-That ($LASTEXITCODE -eq 0) 'Construction du ZIP reussie'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $projectRoot "dist\VendorMaxStack-$($payload.Version).zip"
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    Assert-That ($zip.Entries.Count -eq $payload.Files.Count) 'ZIP : nombre exact de fichiers'
    foreach ($file in $payload.Files) {
        $entry = $zip.GetEntry("VendorMaxStack/$($file.Name)")
        Assert-That ($null -ne $entry) "ZIP : chemin correct pour $($file.Name)"
        $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
        try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
        Assert-That ($content -ceq [IO.File]::ReadAllText($file.Source)) "ZIP : contenu exact pour $($file.Name)"
    }
    Assert-That (@($zip.Entries | Where-Object { $_.FullName -match '\.(ps1|cmd|bat|exe)$|node_modules|tests/' }).Count -eq 0) 'ZIP sans scripts Windows ni fichiers de developpement'
}
finally { $zip.Dispose() }
Write-Output "$checks verifications reussies. Fichiers de test : $testRoot"
