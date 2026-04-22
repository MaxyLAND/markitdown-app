# make_installer.ps1 — genera installer\out\MarkitdownApp-Setup.exe
# Requiere: dist\MarkitdownApp.exe ya generado (build.ps1).
$ErrorActionPreference = "Stop"
$root    = Split-Path -Parent $PSScriptRoot
$dist    = Join-Path $root "dist\MarkitdownApp.exe"
$staging = Join-Path $root "installer\staging"
$outDir  = Join-Path $root "installer\out"
$sed     = Join-Path $root "installer\MarkitdownApp-Setup.sed"

if (-not (Test-Path $dist)) {
  Write-Host "Falta $dist. Ejecuta primero build_tools\build.ps1." -ForegroundColor Red
  exit 1
}

Write-Host "==> Actualizando staging" -ForegroundColor Cyan
Copy-Item -Force $dist (Join-Path $staging "MarkitdownApp.exe")

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$target = Join-Path $outDir "MarkitdownApp-Setup.exe"
if (Test-Path $target) { Remove-Item $target -Force }

Write-Host "==> Empaquetando con IExpress" -ForegroundColor Cyan
& "$env:WINDIR\System32\iexpress.exe" /N /Q $sed | Out-Null

if (Test-Path $target) {
  $size = [math]::Round((Get-Item $target).Length / 1MB, 2)
  Write-Host "OK  $target  ($size MB)" -ForegroundColor Green
} else {
  Write-Host "ERROR  No se generó el instalador." -ForegroundColor Red
  exit 1
}
