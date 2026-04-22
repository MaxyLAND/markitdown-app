"""Markitdown Converter - GUI desktop para la herramienta markitdown."""
from __future__ import annotations

import argparse
import os
import queue
import shutil
import subprocess
import sys
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

APP_TITLE = "Markitdown Converter"
APP_VERSION = "1.0.0"


def find_markitdown() -> str | None:
    """Localiza el ejecutable markitdown en el sistema."""
    exe = shutil.which("markitdown")
    if exe:
        return exe
    candidates = [
        Path(sys.executable).parent / "Scripts" / "markitdown.exe",
        Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Python" / "Python312" / "Scripts" / "markitdown.exe",
        Path(os.environ.get("APPDATA", "")) / "Python" / "Python312" / "Scripts" / "markitdown.exe",
    ]
    for c in candidates:
        if c.is_file():
            return str(c)
    return None


def convert_one(markitdown_exe: str, input_file: Path, output_file: Path) -> tuple[bool, str]:
    """Ejecuta markitdown sobre un archivo. Devuelve (ok, mensaje)."""
    try:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            [markitdown_exe, str(input_file), "-o", str(output_file)],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
        if result.returncode == 0:
            return True, f"OK  {input_file.name}  ->  {output_file}"
        msg = (result.stderr or result.stdout or "error desconocido").strip().splitlines()[-1]
        return False, f"ERR {input_file.name}: {msg}"
    except Exception as e:
        return False, f"ERR {input_file.name}: {e}"


# ---------- modo CLI para el menú contextual ----------
def run_cli_convert(path: str) -> int:
    mk = find_markitdown()
    if not mk:
        print("No se encontró markitdown.exe. Instala con: pip install markitdown", file=sys.stderr)
        return 2
    src = Path(path)
    if not src.is_file():
        print(f"No es un archivo: {src}", file=sys.stderr)
        return 2
    dst = src.with_suffix(".md")
    ok, msg = convert_one(mk, src, dst)
    print(msg)
    return 0 if ok else 1


# ---------- GUI ----------
class MarkitdownApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title(APP_TITLE)
        self.geometry("720x560")
        self.minsize(640, 480)

        self.markitdown_exe = find_markitdown()
        self.log_queue: queue.Queue[str] = queue.Queue()
        self.worker: threading.Thread | None = None

        self._build_ui()
        self._pump_log()

        if not self.markitdown_exe:
            messagebox.showerror(
                APP_TITLE,
                "No se encontró el ejecutable 'markitdown'.\n\n"
                "Instala la herramienta con:\n    pip install markitdown\n\n"
                "y vuelve a abrir la aplicación.",
            )

    def _build_ui(self) -> None:
        pad = {"padx": 10, "pady": 6}

        # --- sección archivos ---
        files_frame = ttk.LabelFrame(self, text="Archivos de entrada")
        files_frame.pack(fill="both", expand=True, **pad)

        list_container = ttk.Frame(files_frame)
        list_container.pack(fill="both", expand=True, padx=8, pady=(8, 4))

        self.file_list = tk.Listbox(list_container, selectmode=tk.EXTENDED, activestyle="dotbox")
        scroll = ttk.Scrollbar(list_container, orient="vertical", command=self.file_list.yview)
        self.file_list.configure(yscrollcommand=scroll.set)
        self.file_list.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")

        btns = ttk.Frame(files_frame)
        btns.pack(fill="x", padx=8, pady=(0, 8))
        ttk.Button(btns, text="Añadir archivos...", command=self.on_add_files).pack(side="left")
        ttk.Button(btns, text="Quitar selección", command=self.on_remove_selected).pack(side="left", padx=6)
        ttk.Button(btns, text="Vaciar lista", command=self.on_clear).pack(side="left")

        # --- sección salida ---
        out_frame = ttk.LabelFrame(self, text="Destino de los .md")
        out_frame.pack(fill="x", **pad)

        self.keep_source = tk.BooleanVar(value=True)
        cb = ttk.Checkbutton(
            out_frame,
            text="Mantener ruta de origen para cada archivo",
            variable=self.keep_source,
            command=self._update_output_state,
        )
        cb.pack(anchor="w", padx=8, pady=(8, 4))

        row = ttk.Frame(out_frame)
        row.pack(fill="x", padx=8, pady=(0, 8))
        ttk.Label(row, text="Carpeta de salida:").pack(side="left")
        self.output_dir = tk.StringVar()
        self.output_entry = ttk.Entry(row, textvariable=self.output_dir)
        self.output_entry.pack(side="left", fill="x", expand=True, padx=6)
        self.browse_btn = ttk.Button(row, text="Examinar...", command=self.on_browse_output)
        self.browse_btn.pack(side="left")

        # --- acción ---
        action = ttk.Frame(self)
        action.pack(fill="x", **pad)
        self.generate_btn = ttk.Button(action, text="Generar documentos", command=self.on_generate)
        self.generate_btn.pack(side="left")
        self.progress = ttk.Progressbar(action, mode="determinate")
        self.progress.pack(side="left", fill="x", expand=True, padx=10)

        # --- log ---
        log_frame = ttk.LabelFrame(self, text="Progreso")
        log_frame.pack(fill="both", expand=True, **pad)
        self.log_text = tk.Text(log_frame, height=10, wrap="word", state="disabled")
        self.log_text.pack(fill="both", expand=True, padx=8, pady=8)

        self._update_output_state()

    # --- handlers ---
    def on_add_files(self) -> None:
        files = filedialog.askopenfilenames(
            title="Seleccionar archivos",
            filetypes=[
                ("Todos los soportados", "*.pdf *.docx *.doc *.xlsx *.xls *.pptx *.ppt *.html *.htm *.csv *.json *.xml *.txt *.md *.png *.jpg *.jpeg *.mp3 *.wav *.epub *.zip"),
                ("PDF", "*.pdf"),
                ("Word", "*.docx *.doc"),
                ("Excel", "*.xlsx *.xls"),
                ("PowerPoint", "*.pptx *.ppt"),
                ("Texto/HTML", "*.html *.htm *.txt *.md *.csv *.json *.xml"),
                ("Todos los archivos", "*.*"),
            ],
        )
        for f in files:
            if f not in self.file_list.get(0, tk.END):
                self.file_list.insert(tk.END, f)

    def on_remove_selected(self) -> None:
        for idx in reversed(self.file_list.curselection()):
            self.file_list.delete(idx)

    def on_clear(self) -> None:
        self.file_list.delete(0, tk.END)

    def on_browse_output(self) -> None:
        d = filedialog.askdirectory(title="Seleccionar carpeta de salida")
        if d:
            self.output_dir.set(d)

    def _update_output_state(self) -> None:
        state = "disabled" if self.keep_source.get() else "normal"
        self.output_entry.configure(state=state)
        self.browse_btn.configure(state=state)

    def on_generate(self) -> None:
        if self.worker and self.worker.is_alive():
            return
        if not self.markitdown_exe:
            messagebox.showerror(APP_TITLE, "markitdown no está disponible.")
            return
        files = list(self.file_list.get(0, tk.END))
        if not files:
            messagebox.showwarning(APP_TITLE, "Añade al menos un archivo.")
            return
        out_dir: Path | None = None
        if not self.keep_source.get():
            raw = self.output_dir.get().strip()
            if not raw:
                messagebox.showwarning(APP_TITLE, "Selecciona una carpeta de salida.")
                return
            out_dir = Path(raw)
            try:
                out_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                messagebox.showerror(APP_TITLE, f"No se pudo crear la carpeta:\n{e}")
                return

        self._log_clear()
        self.progress.configure(maximum=len(files), value=0)
        self.generate_btn.configure(state="disabled")
        self.worker = threading.Thread(
            target=self._run_conversion,
            args=(files, out_dir),
            daemon=True,
        )
        self.worker.start()

    def _run_conversion(self, files: list[str], out_dir: Path | None) -> None:
        ok_count = 0
        err_count = 0
        for f in files:
            src = Path(f)
            if out_dir is None:
                dst = src.with_suffix(".md")
            else:
                dst = out_dir / (src.stem + ".md")
                if dst.exists():
                    # evitar pisar si hay colisión de nombre
                    dst = out_dir / f"{src.stem}__{src.parent.name}.md"
            ok, msg = convert_one(self.markitdown_exe, src, dst)
            self.log_queue.put(msg)
            if ok:
                ok_count += 1
            else:
                err_count += 1
            self.log_queue.put(("__progress__", ok_count + err_count))
        self.log_queue.put(("__done__", (ok_count, err_count)))

    def _pump_log(self) -> None:
        try:
            while True:
                item = self.log_queue.get_nowait()
                if isinstance(item, tuple) and item[0] == "__progress__":
                    self.progress.configure(value=item[1])
                elif isinstance(item, tuple) and item[0] == "__done__":
                    ok, err = item[1]
                    self.generate_btn.configure(state="normal")
                    self._log(f"\nTerminado. {ok} OK, {err} con error.")
                    if err == 0:
                        messagebox.showinfo(APP_TITLE, f"Conversión completada. {ok} archivo(s).")
                    else:
                        messagebox.showwarning(APP_TITLE, f"Completado con errores.\nOK: {ok}  Err: {err}")
                else:
                    self._log(str(item))
        except queue.Empty:
            pass
        self.after(80, self._pump_log)

    def _log(self, text: str) -> None:
        self.log_text.configure(state="normal")
        self.log_text.insert(tk.END, text + "\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state="disabled")

    def _log_clear(self) -> None:
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", tk.END)
        self.log_text.configure(state="disabled")


def main() -> int:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--convert", metavar="FILE", help="modo CLI: convierte un archivo a .md junto al original")
    parser.add_argument("--version", action="store_true")
    args, _ = parser.parse_known_args()

    if args.version:
        print(f"{APP_TITLE} {APP_VERSION}")
        return 0
    if args.convert:
        return run_cli_convert(args.convert)

    MarkitdownApp().mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
