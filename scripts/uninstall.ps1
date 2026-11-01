# Undoes install.ps1 using installed_files.txt:
# - files the tune replaced in an existing REG26 install are restored from the backup;
# - if install.ps1 also installed REG26, REG26 is removed as well (its files, the Mods\Reg2026 folder with the
#   logs it wrote, and Content\UIGameface\Reg2026 created by its DLL).
# Saves, the game's own files and other mods are not touched.
param(
    [string]$Game = 'C:\Program Files (x86)\Steam\steamapps\common\F1 Manager 2024'
)
$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Manifest = Join-Path $Repo 'installed_files.txt'
$ModDir = Join-Path $Game 'F1Manager24\Binaries\Win64\ue4ss\Mods\Reg2026'
$UiRoot = Join-Path $Game 'F1Manager24\Content\UIGameface'
$UiState = Join-Path $UiRoot 'Reg2026'

if (Get-Process -Name 'F1Manager24*' -ErrorAction SilentlyContinue) { throw 'F1 Manager 2024 is running. Close the game first.' }
if (-not (Test-Path -LiteralPath $Manifest)) { throw 'installed_files.txt not found: nothing to undo.' }

$fullInstall = $false
foreach ($line in Get-Content -LiteralPath $Manifest -Encoding UTF8) {
    if (-not $line) { continue }
    $parts = $line.Split('|')
    $target = Join-Path $Game $parts[1]
    if ($parts[0] -eq 'added') {
        $fullInstall = $true
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -Confirm:$false; Write-Host "  - $($parts[1])" }
    } elseif ($parts[0] -eq 'replaced') {
        Copy-Item -LiteralPath $parts[2] -Destination $target -Force
        Write-Host "  < $($parts[1]) (restored)"
    }
}

if ($fullInstall) {
    if (Test-Path -LiteralPath $ModDir) { Remove-Item -LiteralPath $ModDir -Recurse -Force -Confirm:$false; Write-Host "  - $ModDir" }
    if (Test-Path -LiteralPath $UiState) { Remove-Item -LiteralPath $UiState -Recurse -Force -Confirm:$false; Write-Host "  - $UiState" }
    if ((Test-Path -LiteralPath $UiRoot) -and -not (Get-ChildItem -LiteralPath $UiRoot -Force)) {
        Remove-Item -LiteralPath $UiRoot -Force -Confirm:$false
    }
}
Remove-Item -LiteralPath $Manifest -Force -Confirm:$false
Write-Host 'Uninstalled. Save backups stay in the backup folder.'
