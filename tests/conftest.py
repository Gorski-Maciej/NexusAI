"""
conftest.py — prepares test environment for nexus_ai package.

Updated after Code/ → nexus_ai/ restructuring.

SUPERMOCE pytest:
  - pytest_configure() — rejestracja markerów, zero warningów
  - pytest_addoption() — --run-slow, --run-integration, --run-schemathesis flagi

SUPERMOCE pytest-anyio:
  - anyio_backend fixture — jawny backend (asyncio) dla wszystkich testów
    Odkomentuj params= aby testować na obu backendach (asyncio + trio)

SUPERMOCE schemathesis:
  - pytest_configure() rejestruje marker schemathesis
  - pytest_addoption() dodaje --run-schemathesis
  - pytest_collection_modifyitems() pomija testy schemathesis bez flagi
"""
from __future__ import annotations

import sys
import types
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

import pytest

ROOT = Path(__file__).resolve().parents[1]
ROOT_STR = str(ROOT)
if ROOT_STR not in sys.path:
    sys.path.insert(0, ROOT_STR)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: pytest_configure() — rejestracja markerów
# ═══════════════════════════════════════════════════════════════════════════════


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers to suppress PytestUnknownMarkWarning.

    SUPERMOC: Każdy marker ma dokumentację — pytest --markers wyświetla opisy.
    """
    config.addinivalue_line("markers", "integration: Integration test (requires DB/NATS/TigerBeetle)")
    config.addinivalue_line("markers", "anyio: Async test using anyio backend (built-in)")
    config.addinivalue_line("markers", "slow: Slow test (>5s), skipped by default, use --run-slow to run")
    config.addinivalue_line("markers", "benchmark: Performance benchmark (pytest-benchmark)")
    config.addinivalue_line("markers", "smoke: Quick smoke test — basic import and structure checks")
    config.addinivalue_line("markers", "schemathesis: Property-based API testing via schemathesis (uses OpenAPI spec)")


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: pytest_addoption() — kontrola zakresu testów przez CLI
# ═══════════════════════════════════════════════════════════════════════════════
# Uruchomienie:
#   pytest --run-slow             # Uwzględnij wolne testy
#   pytest --run-integration      # Uwzględnij integracyjne
#   pytest --run-schemathesis     # Uwzględnij testy schemathesis (property-based API fuzzing)
#   pytest --run-slow --run-integration --run-schemathesis  # Wszystkie
# ═══════════════════════════════════════════════════════════════════════════════


def pytest_addoption(parser: pytest.Parser) -> None:
    """Add custom CLI options for selective test execution.

    Inspiracja: pandas-dev/pandas — pytest_addoption do kontroli zakresu testów.
    """
    parser.addoption(
        "--run-slow",
        action="store_true",
        default=False,
        help="Run slow tests (marked with @pytest.mark.slow)",
    )
    parser.addoption(
        "--run-integration",
        action="store_true",
        default=False,
        help="Run integration tests (marked with @pytest.mark.integration)",
    )
    parser.addoption(
        "--run-schemathesis",
        action="store_true",
        default=False,
        help="Run schemathesis property-based API tests (marked with @pytest.mark.schemathesis)",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    """Skip slow/integration/schemathesis tests unless explicitly requested via CLI flags.

    Inspiracja: pytest dokumentacja — collection_modifyitems hook.
    """
    run_slow = config.getoption("--run-slow", default=False)
    run_integration = config.getoption("--run-integration", default=False)
    run_schemathesis = config.getoption("--run-schemathesis", default=False)

    skip_slow = pytest.mark.skip(reason="Use --run-slow to run slow tests")
    skip_integration = pytest.mark.skip(reason="Use --run-integration to run integration tests")
    skip_schemathesis = pytest.mark.skip(reason="Use --run-schemathesis to run schemathesis tests")

    for item in items:
        if "slow" in item.keywords and not run_slow:
            item.add_marker(skip_slow)
        if "integration" in item.keywords and not run_integration:
            item.add_marker(skip_integration)
        if "schemathesis" in item.keywords and not run_schemathesis:
            item.add_marker(skip_schemathesis)


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 1: _MockModule for external packages
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: anyio_backend — jawny backend dla wszystkich testów
# ═══════════════════════════════════════════════════════════════════════════════
# Domyślnie: asyncio (najszybszy, najszerzej wspierany).
# Aby testować na obu backendach, odkomentuj parametryzację:
#   @pytest.fixture(params=["asyncio", "trio"])
# UWAGA: trio wymaga pip install trio (nie jest domyślną zależnością anyio).
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def anyio_backend():
    """Explicit anyio backend for all tests.

    SUPERMOC: Jawnie zdefiniowany backend zapewnia deterministyczne
    środowisko testowe. Bez tej fixture, anyio używa domyślnego backendu
    (asyncio), ale zmiana domyślnego backendu w przyszłości mogłaby
    niepostrzeżenie zmienić zachowanie testów.

    Aby testować na obu backendach (asyncio + trio), zamień na:

        @pytest.fixture(params=["asyncio", "trio"])
        def anyio_backend(request):
            return request.param

    Każdy test z @pytest.mark.anyio uruchomi się wtedy dwukrotnie.
    """
    return "asyncio"


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
    "taskiq.abc", "taskiq.abc.middleware",
    "taskiq.message", "taskiq.result", "taskiq.broker",
    "taskiq.scheduler", "taskiq.receiver",
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
    "pypdfium2",  # PDFium engine (zastępuje PyMuPDF)
    # System
    "psutil",
    "structlog",
    # OpenCV
    "cv2",
    # PaddleOCR
    "paddleocr",
    "paddleocr.PaddleOCR",
    "paddleocr.PPStructure",
    # Crypto
    "nexus_crypto",
    # Resilience
    "stamina",
    # DB
    "duckdb",
    "polars",
    # SQLModel (zależność przechodnia: pydantic + pydantic-core)
    # Mocked because SQLModel pulls in pydantic internally.
    # These are NOT direct project dependencies.
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
    # Alembic removed — replaced by native migrations/ (NOT mocked, it's our code)
    # Arrow
    "pyarrow",
]

INTERNAL_MOCK_MODULES: list[str] = [
    # Przecięcie pre-existing import chain:
    # test → pipeline/ocr_consensus → pipeline/__init__ → parser → services → broker → ERROR
    "nexus_ai.pipeline.parser",
    "nexus_ai.services.currency_converter",
    "nexus_ai.services.audit_service",
    "nexus_ai.core.broker",
    "nexus_ai.core.taskiq_middleware",
    "nexus_ai.core.taskiq_result_backend",
]

for mod_name in INTERNAL_MOCK_MODULES:
    sys.modules[mod_name] = _MockModule(mod_name)

for mod_name in EXTERNAL_MOCK_MODULES:
    sys.modules[mod_name] = _MockModule(mod_name)

for m in [
    "yarl", "multidict", "aiosignal", "frozenlist",
    "pyarrow", "pillow", "boto3", "botocore",
    "kubernetes", "opentelemetry",
    "PIL._imaging", "PIL.ImageFilter", "PIL.ImageEnhance",
    "opentelemetry-api", "opentelemetry-sdk",
    "opentelemetry-prometheus-exporter",
    # OpenCV is optional (HAS_CV2 pattern)
    # numpy is real dependency, but mocked for tests without it
    "numpy",
]:
    if m not in sys.modules:
        sys.modules[m] = _MockModule(m)
