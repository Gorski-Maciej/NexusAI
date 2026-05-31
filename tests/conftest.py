"""
conftest.py — przygotowuje środowisko testowe.

Strategia:
1. Dodaj ścieżki do sys.path
2. Zarejestruj _MockModule dla zewnętrznych pakietów
3. Pre-load wszystkich core.* submodułów (przez importlib.util, z fallback do _MockModule)
4. Load core/__init__.py jako pakiet core
5. Load serwisów przez importlib.util
"""

from __future__ import annotations

import importlib.util
import logging
import sys
import types
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

ROOT = Path(__file__).resolve().parents[1]
CODE_DIR = ROOT / "Code"

ROOT_STR = str(ROOT)
if ROOT_STR not in sys.path:
    sys.path.insert(0, ROOT_STR)
CODE_STR = str(CODE_DIR)
if CODE_STR not in sys.path:
    sys.path.insert(0, CODE_STR)


# ===== KROK 1: _MockModule dla zewnętrznych pakietów =====


class _MockModule(types.ModuleType):
    """Mock module that allows any attribute access."""

    def __getattr__(self, name: str) -> Any:
        if name == "__path__":
            return []  # make mock look like a package for sub-imports
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

    def __enter__(self) -> "FakeDuckDBManager":
        return self

    def __exit__(self, *args: Any) -> None:
        pass


EXTERNAL_MOCK_MODULES: list[str] = [
    "db", "db.analytics", "db.models",
    "models", "models.invoice", "models.contract", "models.payment",
    "httpx",
    "llama_cpp",
    "nats",
    "sqlalchemy", "sqlalchemy.ext", "sqlalchemy.ext.asyncio", "sqlalchemy.orm",
    "sqlalchemy.dialects", "sqlalchemy.dialects.postgresql",
    "sqlalchemy.sql", "sqlalchemy.types",
    "sqlalchemy.engine", "sqlalchemy.engine.url",
    "starlette", "fastapi",
    "api", "api.routes", "api.server",
    "fsspec", "fsspec.implementations", "fsspec.implementations.local",
    "PIL", "PIL.Image",
]

for mod_name in EXTERNAL_MOCK_MODULES:
    sys.modules[mod_name] = _MockModule(mod_name)

sys.modules["db.analytics"].DuckDBManager = FakeDuckDBManager

for m in ["aiohttp", "yarl", "multidict", "aiosignal", "frozenlist",
           "orjson", "pyarrow", "pillow", "boto3", "botocore",
           "kubernetes", "prometheus_client", "opentelemetry",
           "PIL._imaging", "PIL.ImageFilter", "PIL.ImageEnhance"]:
    if m not in sys.modules:
        sys.modules[m] = _MockModule(m)


# ===== KROK 2: Pre-load wszystkich core.* submodułów =====

CORE_DIR = CODE_DIR / "CORE"

# Najpierw stwórz namespace core
_core_ns = types.ModuleType("core")
_core_ns.__path__ = [str(CORE_DIR)]
_core_ns.__package__ = "core"
sys.modules["core"] = _core_ns

# Lista wszystkich .py plików w CORE (oprócz __init__.py)
CORE_MODULES: list[str] = [
    "active_learning", "adaptive_batcher", "ai_context", "analytics",
    "backup", "base", "broker", "bus", "categorizer", "circuit_breaker",
    "config", "crypto", "events", "exceptions", "forecaster",
    "hardware", "ipc_vision", "llm_extractor", "llm_guard", "logger",
    "memory_manager", "model_manager", "model_retention", "monitor",
    "outbox_relay", "parsers", "plugins", "prompts", "resilience",
    "saga", "secrets", "shm_manager", "storage", "tasks", "tenant",
    "tracing", "updater",
]

_loaded_core_modules: list[str] = []
_failed_core_modules: list[str] = []

for mod_name in CORE_MODULES:
    full_mod_name = f"core.{mod_name}"
    file_path = CORE_DIR / f"{mod_name}.py"

    if not file_path.exists():
        sys.modules[full_mod_name] = _MockModule(full_mod_name)
        _failed_core_modules.append(mod_name)
        continue

    try:
        _spec = importlib.util.spec_from_file_location(full_mod_name, str(file_path))
        if _spec and _spec.loader:
            _mod = importlib.util.module_from_spec(_spec)
            sys.modules[full_mod_name] = _mod
            _spec.loader.exec_module(_mod)
            _loaded_core_modules.append(mod_name)
        else:
            sys.modules[full_mod_name] = _MockModule(full_mod_name)
            _failed_core_modules.append(mod_name)
    except Exception:
        sys.modules[full_mod_name] = _MockModule(full_mod_name)
        _failed_core_modules.append(mod_name)

# Specjalny: core.logger
_fake_logger = types.ModuleType("core.logger")
_fake_logger.__dict__["logger"] = logging.getLogger("nexus.test")
_fake_logger.__dict__["setup_logging"] = lambda *a, **kw: None
_fake_logger.__dict__["get_logger"] = lambda name: logging.getLogger(name)
sys.modules["core.logger"] = _fake_logger


# ===== KROK 3: Załaduj core/__init__.py jako pakiet core =====

_init_path = CORE_DIR / "__init__.py"
if _init_path.exists():
    _spec = importlib.util.spec_from_file_location("core", str(_init_path))
    if _spec and _spec.loader:
        _mod = importlib.util.module_from_spec(_spec)
        _mod.__path__ = [str(CORE_DIR)]
        sys.modules["core"] = _mod
        _spec.loader.exec_module(_mod)


# ===== KROK 4: Załaduj serwisy przez importlib.util =====

SERVICES_DIR = CODE_DIR / "SERVICES"

# Stwórz pakiet services
_services_ns = types.ModuleType("services")
_services_ns.__path__ = [str(SERVICES_DIR)]
_services_ns.__package__ = "services"
sys.modules["services"] = _services_ns

SERVICE_FILES: list[tuple[str, str]] = [
    ("council_agents", "council_agents.py"),
    ("council_session", "council_session.py"),
    ("decision_logger", "decision_logger.py"),
    ("ple_engine", "ple_engine.py"),
    ("autopilot", "autopilot.py"),
    ("notification_service", "notification_service.py"),
    ("orchestrator_agent", "orchestrator_agent.py"),
    ("decision_agent", "decision_agent.py"),
    ("rules_agent", "rules_agent.py"),
    ("analytics_agent", "analytics_agent.py"),
]

for svc_name, svc_filename in SERVICE_FILES:
    full_path = SERVICES_DIR / svc_filename
    if full_path.exists():
        _spec = importlib.util.spec_from_file_location(
            f"services.{svc_name}", str(full_path)
        )
        if _spec and _spec.loader:
            _mod = importlib.util.module_from_spec(_spec)
            sys.modules[f"services.{svc_name}"] = _mod
            _spec.loader.exec_module(_mod)
