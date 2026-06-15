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
        if name == "__version__":
            return "0.0.0"
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
    # Granian — Rust ASGI server
    "granian",
    "granian.constants",
    "granian.server",
    "granian.server.embed",
    "granian.utils",
    "granian.utils.proxies",
    # HTTP / Network
    "httpx",
    "hishel",
    # AI / ML
    "llama_cpp",
    "llama_cpp.llama_chat_format",
    # NATS / Messaging
    "nats",
    "nats.aio",
    "nats.aio.client",
    "nats.js",
    "nats.js.api",
    "nats.errors",
    "taskiq", "taskiq_nats",
    # Litestar
    "litestar",
    "litestar.plugins",
    "litestar.plugins.core",
    "litestar.connection",
    "litestar.handlers",
    "litestar.handlers.base",
    "litestar.middleware",
    "litestar.config",
    "litestar.config.cors",
    "litestar.config.csrf",
    "litestar.config.response_cache",
    "litestar.openapi",
    "litestar.openapi.config",
    "litestar.openapi.plugins",
    "litestar.openapi.spec",
    "litestar.plugins.problem_details",
    "litestar.plugins.prometheus",
    "litestar.plugins.opentelemetry",
    "litestar.plugins.sqlalchemy",
    "litestar.response",
    "litestar.status_codes",
    "litestar.middleware.rate_limit",
    "litestar.testing",
    "litestar.types",
    # OTel
    "opentelemetry",
    "opentelemetry-api",
    "opentelemetry-sdk",
    "opentelemetry-exporter-prometheus",
    # Filesystem — SUPERMOC fsspec: MemoryFileSystem dla testów bez I/O
    # fsspec jest realną zależnością, mockujemy tylko implementacje
    "fsspec.implementations.memory",
    "fsspec.implementations.cached",
    "fsspec.implementations.zip",
    # Imaging
    "PIL", "PIL.Image",
    "PIL._imaging", "PIL.ImageFilter", "PIL.ImageEnhance",
    # PDF
    "fitz",  # PyMuPDF
    # System
    "psutil",
    "structlog",
    # Crypto
    "nexus_crypto",
    # Resilience
    "stamina",
    # DB
    "duckdb",
    # Pydantic / SQLModel
    "pydantic_core",
    "pydantic_core._pydantic_core",
    "pydantic",
    "pydantic.v1",
    "pydantic.fields",
    "pydantic.main",
    "pydantic._internal",
    "pydantic._internal._model_construction",
    "sqlmodel",
    "sqlmodel.sql",
    "sqlmodel.sql.expression",
    # Alembic
    "alembic",
    "alembic.command",
    "alembic.config",
    "alembic.runtime",
    "alembic.runtime.migration",
    # Arrow
    "pyarrow",
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
