# make.ps1 — atajo: build + install en un solo paso
# Uso:
#   powershell -ExecutionPolicy Bypass -File make.ps1
#   powershell -ExecutionPolicy Bypass -File make.ps1 -ContextMenu
[CmdletBinding()]
param(
  [switch]$ContextMenu,
  [switch]$NoContextMenu,
  [switch]$BuildOnly
)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

& (Join-Path $root "build_tools\build.ps1")
if ($BuildOnly) { exit 0 }

$installArgs = @()
if ($ContextMenu)   { $installArgs += "-ContextMenu" }
if ($NoContextMenu) { $installArgs += "-NoContextMenu" }
& (Join-Path $root "build_tools\install.ps1") @installArgs
