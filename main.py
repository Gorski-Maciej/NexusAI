"""
NexusAI — Central Application Entry Point (shim)
=================================================

Thin shim that delegates to ``Code.main``.
This file exists so that ``python main.py ...`` still works from the project root.

The canonical entry point is registered in ``pyproject.toml`` as ``nexus = "main:main"``
and resolves via the ``Code/`` package directory.
"""

import sys
from pathlib import Path

# Ensure Code/ is on sys.path so that `import main` resolves to Code/main.py
_CODE_DIR = str(Path(__file__).resolve().parent / "Code")
if _CODE_DIR not in sys.path:
    sys.path.insert(0, _CODE_DIR)

import importlib.util  # noqa: E402

# Use importlib to avoid circular import (this file is also named "main")
_CODE_MAIN_PY = Path(__file__).resolve().parent / "Code" / "main.py"
spec = importlib.util.spec_from_file_location("code_main", _CODE_MAIN_PY)
code_main = importlib.util.module_from_spec(spec)
spec.loader.exec_module(code_main)
main = code_main.main

if __name__ == "__main__":
    raise SystemExit(main())
