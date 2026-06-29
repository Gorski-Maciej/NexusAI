# core/__init__.py
"""NexusAI Core — safe lazy imports for constrained environments.

Nowy stack (zgodny z aa3fvcx.txt):
- nexus-crypto (AEAD + Argon2id + SHA-256)
- stamina (async-native retry + circuit breaker)
- msgspec do serializacji TOML/JSON (zamiast json/orjson)
"""

from __future__ import annotations

import logging as _logging

_log = _logging.getLogger("nexus.core")

# ── Nuitka compilation guard ── ─────────────────────────────────────────────
# __compiled__ is set by Nuitka for compiled modules. Use it to skip
# optional-module probing at import time when the set of available modules
# is already known (faster startup, smaller binary).
# Standard Nuitka idiom: try/except NameError instead of __builtins__ inspection.
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

# ── Always-available modules ────────────────────────────────────────────────
from nexus_ai.core.config import AppConfig  # noqa: E402
from nexus_ai.core.exceptions import (  # noqa: E402
    AIProcessingError,
    BrokerConnectionError,
    LLMGuardrailError,
    NexusBaseException,
    VectorDBError,
)
from nexus_ai.core.logger import logger  # noqa: E402

# ── Optional / gracefully-falling modules ───────────────────────────────────


import importlib as _importlib


def _safe_import(qualname: str, names: list[str]):
    """Try to import *names* from *qualname*; return (module, imported_names) on success.

    Używa importlib.import_module zamiast __import__ (Enterprise TOP-6 fix).
    """
    try:
        mod = _importlib.import_module(qualname)
        return mod, [getattr(mod, n) for n in names]
    except (ImportError, ModuleNotFoundError, AttributeError) as exc:
        _log.debug("Optional import %s.%s unavailable: %s", qualname, names, exc)
        return None, [None] * len(names)


# ── Nuitka-compiled: skip optional-import probing entirely.
# When compiled by Nuitka, all modules are already resolved and bundled.
# The _safe_import mechanism is only needed in interpreted mode.
if not _NUITKA_COMPILED:
    # core.mimalloc — Python ctypes bridge do mimalloc API (optional)
    # Gdy mimalloc nie jest LD_PRELOAD'owany, wszystkie funkcje zwracają None/False.
    from nexus_ai.core.mimalloc_bridge import (  # noqa: E402
        InvoiceOCRHeap,
        MemoryLeakDetector,
        SecureHeap,
        heap_destroy,
        heap_new,
        is_active,
        option_get,
        option_set,
        record_metrics,
        save_stats_to_file,
        stats_as_dict,
    )

    # core.crypto — Vault (uses nexus-crypto now, always available)
    from nexus_ai.core.crypto import Vault  # noqa: E402

    # core.secrets (optional)
    _, [SecretsManager] = _safe_import("core.secrets", ["SecretsManager"])  # noqa: E402

    # core.monitor (optional)
    _, [SystemMonitor] = _safe_import("core.monitor", ["SystemMonitor"])

    # core.prompts (optional)
    _, [PromptTemplate] = _safe_import("core.prompts", ["PromptTemplate"])

    # core.bus (optional)
    _, [bus] = _safe_import("core.bus", ["bus"])

    # core.parsers (optional)
    _, [DataParser] = _safe_import("core.parsers", ["DataParser"])

    # core.plugins (optional)
    _, [PluginManager] = _safe_import("core.plugins", ["PluginManager"])

    # core.storage (optional)
    _, [StorageProvider, LocalStorageProvider] = _safe_import(
        "core.storage",
        ["StorageProvider", "LocalStorageProvider"],  # noqa: E402
    )

    # core.events (optional)
    _, [NexusEvent] = _safe_import("core.events", ["NexusEvent"])  # noqa: E402

    # ── Late-bound globals ──────────────────────────────────────────────
    plugin_manager = None

    def _init_globals():
        global plugin_manager
        if PluginManager is not None:
            try:
                pm = PluginManager()
                pm.discover_exporters()
                plugin_manager = pm
            except Exception as exc:
                _log.debug("PluginManager init failed: %s", exc)
                plugin_manager = None

    _init_globals()
else:
    # ── Nuitka-compiled path: skip optional probing, import only known-safe modules.
    from nexus_ai.core.mimalloc_bridge import (  # noqa: E402
        InvoiceOCRHeap,
        MemoryLeakDetector,
        SecureHeap,
        heap_destroy,
        heap_new,
        is_active,
        option_get,
        option_set,
        record_metrics,
        save_stats_to_file,
        stats_as_dict,
    )
    from nexus_ai.core.crypto import Vault  # noqa: E402

    SecretsManager = None
    SystemMonitor = None
    PromptTemplate = None
    bus = None
    DataParser = None
    PluginManager = None
    StorageProvider = None
    LocalStorageProvider = None
    NexusEvent = None
    plugin_manager = None

__all__ = [
    "AppConfig",
    "logger",
    "NexusBaseException",
    "AIProcessingError",
    "LLMGuardrailError",
    "BrokerConnectionError",
    "VectorDBError",
    "Vault",
    "StorageProvider",
    "LocalStorageProvider",
    "NexusEvent",
    "SecretsManager",
    "SystemMonitor",
    "PromptTemplate",
    "bus",
    "DataParser",
    "AIContextManager",
    "plugin_manager",
    # Mimalloc bridge
    "is_active",
    "heap_new",
    "heap_destroy",
    "option_set",
    "option_get",
    "stats_as_dict",
    "record_metrics",
    "save_stats_to_file",
    "MemoryLeakDetector",
    "InvoiceOCRHeap",
    "SecureHeap",
]
