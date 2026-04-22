# install.ps1 (empaquetado por IExpress) — instala MarkitdownApp en el equipo.
# Se ejecuta en la carpeta temporal donde IExpress extrajo los archivos.
[CmdletBinding()]
param(
  [switch]$ContextMenu,
  [switch]$NoContextMenu
)
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $here "MarkitdownApp.exe"

if (-not (Test-Path $src)) {
  Write-Host "No se encontró MarkitdownApp.exe junto al instalador." -ForegroundColor Red
  exit 1
}

$installDir = Join-Path $env:LOCALAPPDATA "MarkitdownApp"
$installExe = Join-Path $installDir "MarkitdownApp.exe"

Write-Host ""
Write-Host "  Markitdown Converter - Instalador" -ForegroundColor Cyan
Write-Host "  =================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Destino: $installDir"
Write-Host ""

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item -Force -Path $src -Destination $installExe
Write-Host "  [OK] Ejecutable copiado." -ForegroundColor Green

# Acceso directo en el menú Inicio
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk       = Join-Path $startMenu "Markitdown Converter.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath       = $installExe
$sc.WorkingDirectory = $installDir
$sc.IconLocation     = "$installExe,0"
$sc.Description      = "Markitdown Converter"
$sc.Save()
Write-Host "  [OK] Acceso directo en el menú Inicio." -ForegroundColor Green

# Desinstalador local
$uninstall = Join-Path $installDir "uninstall.ps1"
@'
$ErrorActionPreference = "SilentlyContinue"
$installDir = Join-Path $env:LOCALAPPDATA "MarkitdownApp"
$startMenu  = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk        = Join-Path $startMenu "Markitdown Converter.lnk"
$regKey     = "HKCU:\Software\Classes\*\shell\MarkitdownApp"
$uninstReg  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MarkitdownApp"
if (Test-Path $regKey)    { Remove-Item $regKey -Recurse -Force }
if (Test-Path $uninstReg) { Remove-Item $uninstReg -Recurse -Force }
if (Test-Path $lnk)       { Remove-Item $lnk -Force }
if (Test-Path $installDir){ Start-Sleep -Milliseconds 300; Remove-Item $installDir -Recurse -Force }
Write-Host "Markitdown Converter desinstalado." -ForegroundColor Green
'@ | Set-Content -Path $uninstall -Encoding UTF8

# Entrada en "Agregar o quitar programas"
$uninstReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MarkitdownApp"
New-Item -Path $uninstReg -Force | Out-Null
Set-ItemProperty -Path $uninstReg -Name "DisplayName"     -Value "Markitdown Converter"
Set-ItemProperty -Path $uninstReg -Name "DisplayVersion"  -Value "1.0.0"
Set-ItemProperty -Path $uninstReg -Name "Publisher"       -Value "Markitdown App"
Set-ItemProperty -Path $uninstReg -Name "DisplayIcon"     -Value $installExe
Set-ItemProperty -Path $uninstReg -Name "InstallLocation" -Value $installDir
Set-ItemProperty -Path $uninstReg -Name "UninstallString" -Value "powershell -ExecutionPolicy Bypass -File `"$uninstall`""
Set-ItemProperty -Path $uninstReg -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstReg -Name "NoRepair" -Value 1 -Type DWord

# Menú contextual (opcional)
$addContext = $false
if ($ContextMenu) { $addContext = $true }
elseif ($NoContextMenu) { $addContext = $false }
else {
  Write-Host ""
  $resp = Read-Host "  ¿Añadir 'Generar markitdown' al click derecho de Windows? (s/N)"
  if ($resp -match '^[sSyY]') { $addContext = $true }
}

if ($addContext) {
  $key    = "HKCU:\Software\Classes\*\shell\MarkitdownApp"
  $cmdKey = "$key\command"
  New-Item -Path $key    -Force | Out-Null
  New-Item -Path $cmdKey -Force | Out-Null
  Set-ItemProperty -Path $key    -Name "(Default)" -Value "Generar markitdown"
  Set-ItemProperty -Path $key    -Name "Icon"      -Value "`"$installExe`",0"
  Set-ItemProperty -Path $cmdKey -Name "(Default)" -Value "`"$installExe`" --convert `"%1`""
  Write-Host "  [OK] Menú contextual registrado." -ForegroundColor Green
} else {
  Write-Host "  [--] Menú contextual omitido." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Instalación completada." -ForegroundColor Green
Write-Host "  Puedes abrir la app desde el menú Inicio."
Write-Host ""
Write-Host "  Pulsa Enter para cerrar..."
[void](Read-Host)
