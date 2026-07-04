"""NexusAI services package -- business logic layer z lazy importami.

Po spłaszczeniu 15 podkatalogów domenowych do płaskich plików .py,
lazy loader jest prostszy: skanuje tylko pliki .py (w tym dawne __init__.py
pakietów domenowych, które teraz są accounting.py, tax.py, itd.).

Ładowanie lazy przez __getattr__ -- szuka w plikach .py.
"""

from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any

_SERVICE_CACHE: dict[str, Any] = {}


def __getattr__(name: str) -> Any:
    """Auto-import przy pierwszym użyciu -- szuka w plikach .py modułu."""
    if name in _SERVICE_CACHE:
        return _SERVICE_CACHE[name]

    # Skanuj wszystkie pliki .py
    for py_file in Path(__file__).parent.glob("*.py"):
        if py_file.stem == "__init__":
            continue
        try:
            module = importlib.import_module(f"nexus_ai.services.{py_file.stem}")
            obj = getattr(module, name, None)
            if obj is not None:
                _SERVICE_CACHE[name] = obj
                return obj
        except ImportError:
            continue

    raise AttributeError(f"module 'nexus_ai.services' has no attribute '{name}'")


__all__ = [  # type: ignore[has-type]
    p.stem for p in Path(__file__).parent.glob("*.py")
    if p.stem != "__init__"
]
