# Markitdown Converter

App de escritorio para Windows 10/11 que envuelve la herramienta
[microsoft/markitdown](https://github.com/microsoft/markitdown) en una
GUI sencilla para convertir archivos (PDF, Word, Excel, PowerPoint, HTML, etc.)
a Markdown.

## Funciones

- Selección múltiple de archivos vía explorador de Windows.
- Checkbox **“Mantener ruta de origen para cada archivo”** (deja cada `.md`
  junto al original).
- Carpeta de salida única (deshabilitada cuando el checkbox está marcado).
- Botón **“Generar documentos”** con barra de progreso y log.
- Menú contextual opcional de Windows: **click derecho → Generar markitdown**
  sobre cualquier archivo genera su `.md` en la misma carpeta.

## Requisitos

- Windows 10 / 11.
- Python 3.10+ y `markitdown` instalado:
  ```powershell
  pip install markitdown[all]
  ```

## Ejecutar en desarrollo

```powershell
python src\app.py
```

## Construir el `.exe` e instalar

Desde PowerShell, en la raíz del proyecto:

```powershell
# Todo en un paso (pregunta por el menú contextual):
powershell -ExecutionPolicy Bypass -File make.ps1

# Forzando la opción de menú contextual:
powershell -ExecutionPolicy Bypass -File make.ps1 -ContextMenu

# Sólo construir:
powershell -ExecutionPolicy Bypass -File make.ps1 -BuildOnly
```

El ejecutable se genera en `dist\MarkitdownApp.exe`.
La instalación copia la app a `%LOCALAPPDATA%\MarkitdownApp` y crea
un acceso directo en el menú Inicio.

## Generar el instalador `.exe` distribuible

```powershell
powershell -ExecutionPolicy Bypass -File build_tools\make_installer.ps1
```

Produce `installer\out\MarkitdownApp-Setup.exe` (un autoextraíble hecho con
IExpress que empaqueta la app + el script de instalación).
El usuario final sólo ejecuta ese `.exe`, el instalador pregunta si quiere
añadir la opción **click derecho → "Generar markitdown"** y registra
la app en "Agregar o quitar programas".

## Desinstalar

Desde "Aplicaciones instaladas" de Windows (entrada **Markitdown Converter**),
o ejecutando:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\MarkitdownApp\uninstall.ps1"
```

## Modo CLI (usado por el menú contextual)

```powershell
MarkitdownApp.exe --convert "C:\ruta\archivo.pdf"
```

Genera `archivo.md` junto al archivo original.
