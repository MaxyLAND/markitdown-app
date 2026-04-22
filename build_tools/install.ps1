# install.ps1 — instala MarkitdownApp en el equipo
# Uso:
#   powershell -ExecutionPolicy Bypass -File install.ps1                 (interactivo)
#   powershell -ExecutionPolicy Bypass -File install.ps1 -ContextMenu    (sin preguntar)
#   powershell -ExecutionPolicy Bypass -File install.ps1 -NoContextMenu
[CmdletBinding()]
param(
  [switch]$ContextMenu,
  [switch]$NoContextMenu,
  [string]$ExePath
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if (-not $ExePath) { $ExePath = Join-Path $root "dist\MarkitdownApp.exe" }

if (-not (Test-Path $ExePath)) {
  Write-Host "No se encontró el ejecutable: $ExePath" -ForegroundColor Red
  Write-Host "Ejecuta primero build_tools\build.ps1 o pasa -ExePath <ruta>." -ForegroundColor Yellow
  exit 1
}

$installDir = Join-Path $env:LOCALAPPDATA "MarkitdownApp"
$installExe = Join-Path $installDir "MarkitdownApp.exe"

Write-Host "==> Copiando a $installDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item -Force -Path $ExePath -Destination $installExe

# Acceso directo en el menú Inicio
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk       = Join-Path $startMenu "Markitdown Converter.lnk"
Write-Host "==> Creando acceso directo en el menú Inicio" -ForegroundColor Cyan
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = $installExe
$sc.WorkingDirectory = $installDir
$sc.IconLocation = "$installExe,0"
$sc.Description = "Markitdown Converter"
$sc.Save()

# Menú contextual (opcional)
$addContext = $false
if ($ContextMenu) { $addContext = $true }
elseif ($NoContextMenu) { $addContext = $false }
else {
  $resp = Read-Host "¿Añadir la opción 'Generar markitdown' al click derecho de Windows? (s/N)"
  if ($resp -match '^[sSyY]') { $addContext = $true }
}

if ($addContext) {
  Write-Host "==> Registrando menú contextual (HKCU)" -ForegroundColor Cyan
  $key    = "HKCU:\Software\Classes\*\shell\MarkitdownApp"
  $cmdKey = "$key\command"
  New-Item -Path $key    -Force | Out-Null
  New-Item -Path $cmdKey -Force | Out-Null
  Set-ItemProperty -Path $key -Name "(Default)" -Value "Generar markitdown"
  Set-ItemProperty -Path $key -Name "Icon"      -Value "`"$installExe`",0"
  Set-ItemProperty -Path $cmdKey -Name "(Default)" -Value "`"$installExe`" --convert `"%1`""
  Write-Host "    Menú contextual añadido." -ForegroundColor Green
} else {
  Write-Host "    Menú contextual omitido." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Instalación completada." -ForegroundColor Green
Write-Host "  App       : $installExe"
Write-Host "  Acceso    : $lnk"
Write-Host "  Desinstalar: build_tools\uninstall.ps1"
