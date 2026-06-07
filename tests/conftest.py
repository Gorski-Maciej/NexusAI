"""
conftest.py — prepares test environment for nexus_ai package.

Updated after Code/ → nexus_ai/ restructuring.
"""
from __future__ import annotations

import sys
import types
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

ROOT = Path(__file__).resolve().parents[1]
ROOT_STR = str(ROOT)
if ROOT_STR not in sys.path:
    sys.path.insert(0, ROOT_STR)


# ===== KROK 1: _MockModule for external packages =====


class _MockModule(types.ModuleType):
    """Mock module that allows any attribute access."""

    def __getattr__(self, name: str) -> Any:
        if name == "__path__":
            return []
        if name.startswith("__") and name.endswith("__"):
            raise AttributeError(name)
        m = MagicMock()
        setattr(self, name, m)
        return m


class FakeDuckDBManager:
    """Symuluje DuckDBManager."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        self.executed: list[tuple[str, tuple | None]] = []

    def execute(self, query: str, params: tuple | list | None = None) -> list:
        self.executed.append((query, tuple(params) if params else ()))
        if "COUNT(*)" in query:
            return [(0,)]
        return []

    def close(self) -> None:
        pass

    def __enter__(self) -> FakeDuckDBManager:
        return self

    def __exit__(self, *args: Any) -> None:
        pass


EXTERNAL_MOCK_MODULES: list[str] = [
    "httpx",
    "llama_cpp",
    "nats",
    "litestar", "litestar.plugins",
    "fsspec", "fsspec.implementations", "fsspec.implementations.local",
    "PIL", "PIL.Image",
    "fitz",  # PyMuPDF
    "taskiq", "taskiq_nats",
    "psutil",
]

for mod_name in EXTERNAL_MOCK_MODULES:
    sys.modules[mod_name] = _MockModule(mod_name)

for m in [
    "aiohttp", "yarl", "multidict", "aiosignal", "frozenlist",
    "pyarrow", "pillow", "boto3", "botocore",
    "kubernetes", "opentelemetry",
    "PIL._imaging", "PIL.ImageFilter", "PIL.ImageEnhance",
    "opentelemetry-api", "opentelemetry-sdk",
    "opentelemetry-prometheus-exporter",
    "numpy",
    "huggingface_hub", "huggingface_hub._snapshot_download",
]:
    if m not in sys.modules:
        sys.modules[m] = _MockModule(m)
