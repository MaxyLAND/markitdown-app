# uninstall.ps1 — elimina MarkitdownApp del equipo
$ErrorActionPreference = "SilentlyContinue"

$installDir = Join-Path $env:LOCALAPPDATA "MarkitdownApp"
$startMenu  = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk        = Join-Path $startMenu "Markitdown Converter.lnk"
$regKey     = "HKCU:\Software\Classes\*\shell\MarkitdownApp"

Write-Host "==> Quitando menú contextual" -ForegroundColor Cyan
if (Test-Path $regKey) { Remove-Item $regKey -Recurse -Force }

Write-Host "==> Quitando acceso directo" -ForegroundColor Cyan
if (Test-Path $lnk) { Remove-Item $lnk -Force }

Write-Host "==> Eliminando archivos" -ForegroundColor Cyan
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }

Write-Host "Desinstalación completada." -ForegroundColor Green
