[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateNotNullOrEmpty()]
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns',
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'
try {
    . (Join-Path $PSScriptRoot 'scripts\Payload.ps1')
    $payload = Get-VendorMaxStackPayload -ProjectRoot $PSScriptRoot
    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) { throw "Dossier AddOns introuvable : $AddOnsPath" }
    $resolvedAddOns = (Resolve-Path -LiteralPath $AddOnsPath).ProviderPath
    $destination = [IO.Path]::GetFullPath((Join-Path $resolvedAddOns 'VendorMaxStack'))
    if ([string]::Equals([IO.Path]::GetFullPath($payload.SourceRoot), $destination, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Le dossier source est déjà le dossier de destination.'
    }
    $targets = @($destination) + @($payload.Files | ForEach-Object { Join-Path $destination $_.Name })
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target) {
            if ((Get-Item -LiteralPath $target -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Installation interrompue : la destination est un lien ou une jonction : $target"
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($destination, "Installer ou mettre à jour VendorMaxStack $($payload.Version)")) {
        [IO.Directory]::CreateDirectory($destination) | Out-Null
        foreach ($file in $payload.Files) {
            Copy-Item -LiteralPath $file.Source -Destination (Join-Path $destination $file.Name) -Force
        }
        foreach ($file in $payload.Files) {
            if ((Get-FileHash -LiteralPath $file.Source).Hash -ne (Get-FileHash -LiteralPath (Join-Path $destination $file.Name)).Hash) {
                throw "Échec de vérification du fichier : $($file.Name)"
            }
        }
        Write-Host "VendorMaxStack $($payload.Version) installé dans : $destination" -ForegroundColor Green
        Write-Host 'Première installation : redémarrez WoW et activez VendorMaxStack dans la liste des addons.'
        Write-Host 'Mise à jour : tapez /reload si cet addon est déjà chargé.'
    }
}
catch {
    $exception = $_.Exception
    $accessDenied = $_.CategoryInfo.Category -eq 'PermissionDenied'
    while ($exception) {
        if ($exception -is [UnauthorizedAccessException]) { $accessDenied = $true }
        $exception = $exception.InnerException
    }
    if ($accessDenied -and -not $Elevated -and -not $WhatIfPreference) {
        Write-Host 'Windows demande les droits administrateur pour copier les fichiers. Une demande UAC va apparaître.'
        # EncodedCommand preserves paths with spaces, accents and apostrophes without shell interpolation.
        $escapedScript = $PSCommandPath.Replace("'", "''")
        $escapedTarget = $AddOnsPath.Replace("'", "''")
        $command = "& '$escapedScript' -AddOnsPath '$escapedTarget' -Elevated"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        try {
            $child = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded)
            if ($child.ExitCode -ne 0) { throw "L'installation avec les droits administrateur a échoué (code $($child.ExitCode))." }
            Write-Host 'VendorMaxStack installé. Redémarrez WoW, ou utilisez /reload pour une mise à jour.' -ForegroundColor Green
        }
        catch {
            Write-Host "Installation impossible ou demande administrateur annulée : $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Installation impossible : $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
