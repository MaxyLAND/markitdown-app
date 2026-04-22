# build.ps1 — genera MarkitdownApp.exe con PyInstaller
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "src\app.py"
$dist = Join-Path $root "dist"
$work = Join-Path $root "build"
$spec = Join-Path $root "build_tools"
$icon = Join-Path $root "assets\app.ico"

Write-Host "==> Instalando/actualizando PyInstaller..." -ForegroundColor Cyan
python -m pip install --upgrade pyinstaller | Out-Null

if (-not (Test-Path $icon)) { $icon = $null }

Write-Host "==> Limpiando build previos..." -ForegroundColor Cyan
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
if (Test-Path $work) { Remove-Item $work -Recurse -Force }

$pyiArgs = @(
  "--noconfirm",
  "--onefile",
  "--windowed",
  "--name", "MarkitdownApp",
  "--distpath", $dist,
  "--workpath", $work,
  "--specpath", $spec
)
if ($icon) { $pyiArgs += @("--icon", $icon) }
$pyiArgs += $src

Write-Host "==> Construyendo .exe..." -ForegroundColor Cyan
python -m PyInstaller @pyiArgs

$exe = Join-Path $dist "MarkitdownApp.exe"
if (Test-Path $exe) {
  Write-Host ""
  Write-Host "OK  Ejecutable generado: $exe" -ForegroundColor Green
} else {
  Write-Host "ERROR  No se generó el ejecutable." -ForegroundColor Red
  exit 1
}
