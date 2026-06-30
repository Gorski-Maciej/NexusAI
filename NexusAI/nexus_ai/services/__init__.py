"""NexusAI services package — business logic layer z lazy importami.

Ładowanie lazy przez __getattr__ — zero narzutu przy imporcie pakietu.
Importowane serwisy są dostępne przez: from nexus_ai.services import InvoiceService
"""

from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any

_SERVICE_CACHE: dict[str, Any] = {}

def __getattr__(name: str) -> Any:
    """Auto-import przy pierwszym użyciu — eliminuje 50+ ręcznych importów."""
    if name in _SERVICE_CACHE:
        return _SERVICE_CACHE[name]
    # Szukaj w bezpośrednich plikach
    module_path = Path(__file__).parent / f"{name.lower()}.py"
    if module_path.exists():
        module = importlib.import_module(f"nexus_ai.services.{name.lower()}")
        obj = getattr(module, name, None)
        if obj is not None:
            _SERVICE_CACHE[name] = obj
            return obj
    # Szukaj we wszystkich plikach
    for py_file in Path(__file__).parent.glob("*.py"):
        if py_file.stem == "__init__":
            continue
        module = importlib.import_module(f"nexus_ai.services.{py_file.stem}")
        obj = getattr(module, name, None)
        if obj is not None:
            _SERVICE_CACHE[name] = obj
            return obj
    raise AttributeError(f"module 'nexus_ai.services' has no attribute '{name}'")

__all__ = [  # type: ignore[has-type]
    p.stem for p in Path(__file__).parent.glob("*.py")
    if p.stem != "__init__"
]
