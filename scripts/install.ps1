# Installs the REG26 Tune for F1 Manager 2024.
# - REG26 not installed yet: installs REG26 v0.4.1 from its release zip (sha256 checked), then the tune on top.
# - REG26 v0.4.1 already installed: backs up its main.lua / superclipping.ini, then puts the tune on top.
# Never overwrites any other file. Backs up the save folder first. Everything it does is listed in
# installed_files.txt so uninstall.ps1 can undo it.
param(
    [string]$Game = 'C:\Program Files (x86)\Steam\steamapps\common\F1 Manager 2024',
    [string]$Reg26Zip = '',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Manifest = Join-Path $Repo 'installed_files.txt'
$BackupRoot = Join-Path $Repo 'backup'
$Saves = Join-Path $env:LOCALAPPDATA 'F1Manager24\Saved\SaveGames'
$ModRel = 'F1Manager24\Binaries\Win64\ue4ss\Mods\Reg2026'
$ModDir = Join-Path $Game $ModRel

$Reg26ZipSha = 'c7214be22ea8e74001c5a7c1a72a8db3dd7a009da51104244537ca691aae5560'
$Reg26MainSha = '5d6307b7d0e82ea177d84f43ec1dc71581ad24029685fe8b6c7369a19db2dc3b'
$TuneMainSha = 'ff70af7ad1a8a3fc9ae395c18f326d3be29974ed97c0f913f01be3b8eafaab69'
$TuneFiles = @('Scripts\main.lua', 'superclipping.ini')

function Sha([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower() }

if (Get-Process -Name 'F1Manager24*' -ErrorAction SilentlyContinue) { throw 'F1 Manager 2024 is running. Close the game first.' }
if (-not (Test-Path -LiteralPath (Join-Path $Game 'F1Manager24\Binaries\Win64\ue4ss\UE4SS.dll'))) {
    throw "UE4SS not found in $Game\F1Manager24\Binaries\Win64\ue4ss (UE4SS v3.0.1 is required)."
}
if (Test-Path -LiteralPath $Manifest) { throw 'installed_files.txt exists: the tune is already installed. Run uninstall.ps1 first.' }

# save backup
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
if (Test-Path -LiteralPath $Saves) {
    $saveBackup = Join-Path $BackupRoot "SaveGames_$stamp"
    Copy-Item -LiteralPath $Saves -Destination $saveBackup -Recurse
    Write-Host "Save backup: $saveBackup"
}

$lines = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $ModDir)) {
    # REG26 itself
    if (-not $Reg26Zip) {
        $candidates = @((Join-Path $Repo 'Reg2026_v0.4.1.zip'), (Join-Path $env:USERPROFILE 'Downloads\Reg2026_v0.4.1.zip'))
        $Reg26Zip = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }
    if (-not $Reg26Zip -or -not (Test-Path -LiteralPath $Reg26Zip)) {
        throw 'REG26 is not installed and Reg2026_v0.4.1.zip was not found. Download it from https://github.com/AndyD9/F1Manager24-REG26/releases/tag/v0.4.1 and pass -Reg26Zip <path>.'
    }
    if ((Sha $Reg26Zip) -ne $Reg26ZipSha) { throw "$Reg26Zip is not the official REG26 v0.4.1 zip (sha256 mismatch)." }

    # not $env:TEMP: its 8.3 short path breaks the relative paths below
    $tmp = Join-Path $BackupRoot "reg26_extract_$stamp"
    Expand-Archive -LiteralPath $Reg26Zip -DestinationPath $tmp
    $srcRoot = (Resolve-Path -LiteralPath $tmp).Path.TrimEnd('\') + '\'
    $plan = foreach ($f in Get-ChildItem -LiteralPath $tmp -Recurse -File) {
        $rel = $f.FullName.Substring($srcRoot.Length)
        [pscustomobject]@{ Source = $f.FullName; Rel = $rel; Target = Join-Path $Game $rel }
    }
    $conflicts = $plan | Where-Object { Test-Path -LiteralPath $_.Target }
    if ($conflicts) {
        $conflicts | ForEach-Object { Write-Warning "Already exists: $($_.Target)" }
        throw 'Aborted: a REG26 file is already in the game folder.'
    }
    foreach ($p in $plan) {
        $dir = Split-Path -Parent $p.Target
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Copy-Item -LiteralPath $p.Source -Destination $p.Target
        $lines.Add("added|$($p.Rel)")
        Write-Host "  + $($p.Rel)"
    }
    Remove-Item -LiteralPath $tmp -Recurse -Force -Confirm:$false
} else {
    $installed = Sha (Join-Path $ModDir 'Scripts\main.lua')
    if ($installed -eq $TuneMainSha) { throw 'The tune main.lua is already in place.' }
    if ($installed -ne $Reg26MainSha -and -not $Force) {
        throw 'The installed REG26 main.lua is not v0.4.1 (or was edited). The tune is built on v0.4.1; use -Force to overwrite anyway.'
    }
}

# tune on top (main.lua + superclipping.ini), originals kept in backup\replaced_<stamp>
$replacedDir = Join-Path $BackupRoot "replaced_$stamp"
foreach ($t in $TuneFiles) {
    $rel = Join-Path $ModRel $t
    $target = Join-Path $Game $rel
    if ((Test-Path -LiteralPath $target) -and -not $lines.Contains("added|$rel")) {
        $bak = Join-Path $replacedDir $t
        New-Item -ItemType Directory -Path (Split-Path -Parent $bak) -Force | Out-Null
        Copy-Item -LiteralPath $target -Destination $bak
        $lines.Add("replaced|$rel|$bak")
    }
    Copy-Item -LiteralPath (Join-Path $Repo "mod\Reg2026\$t") -Destination $target -Force
    Write-Host "  * $rel (tune)"
}
# address left by REG26's stock script, read by the DLL at start-up
$carstats = Join-Path $ModDir 'carstats.txt'
if (Test-Path -LiteralPath $carstats) { Remove-Item -LiteralPath $carstats -Force -Confirm:$false }

Set-Content -LiteralPath $Manifest -Value $lines -Encoding UTF8
Write-Host "Done. Start the game and check $ModDir\patch.log for 'Straight Mode actif'."
