# core/__init__.py
"""NexusAI Core — safe lazy imports for constrained environments.

Nowy stack (zgodny z aa3fvcx.txt):
- nexus-crypto zamiast cryptography (AEAD ChaCha20-Poly1305 + Argon2id)
- stamina zamiast tenacity + pybreaker (async-native retry + CB)
- msgspec zamiast pydantic-settings + python-dotenv + json
"""
from __future__ import annotations

import logging as _logging

_log = _logging.getLogger("nexus.core")

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

def _safe_import(qualname: str, names: list[str]):
    """Try to import *names* from *qualname*; return (module, imported_names) on success."""
    try:
        mod = __import__(qualname, fromlist=names)
        return mod, [getattr(mod, n) for n in names]
    except (ImportError, ModuleNotFoundError, AttributeError) as exc:
        _log.debug("Optional import %s.%s unavailable: %s", qualname, names, exc)
        return None, [None] * len(names)

# core.crypto — Vault (uses nexus-crypto now, always available)
from nexus_ai.core.crypto import Vault  # noqa: E402

# core.resilience — async_retry (uses stamina now)
from nexus_ai.core.resilience import async_retry  # noqa: E402

# core.secrets (optional)
_, [SecretsManager] = _safe_import("core.secrets", ["SecretsManager"])  # noqa: E402

# core.llm_guard (optional)
_, [LLMGuard, InvoiceLLMExtraction] = _safe_import(
    "core.llm_guard", ["LLMGuard", "InvoiceLLMExtraction"]
)

# core.monitor (optional)
_, [SystemMonitor] = _safe_import("core.monitor", ["SystemMonitor"])

# core.prompts (optional)
_, [PromptTemplate] = _safe_import("core.prompts", ["PromptTemplate"])

# core.bus (optional)
_, [bus] = _safe_import("core.bus", ["bus"])

# core.parsers (optional)
_, [DataParser] = _safe_import("core.parsers", ["DataParser"])

# core.ai_context (optional)
_, [AIContextManager] = _safe_import("core.ai_context", ["AIContextManager"])

# core.plugins (optional)
_, [PluginManager] = _safe_import("core.plugins", ["PluginManager"])

# core.hardware (optional)
_, [HardwareProbe] = _safe_import("core.hardware", ["HardwareProbe"])  # noqa: E402

# core.storage (optional)
_, [StorageProvider, LocalStorageProvider] = _safe_import(
    "core.storage", ["StorageProvider", "LocalStorageProvider"]  # noqa: E402
)

# core.events (optional)
_, [NexusEvent] = _safe_import("core.events", ["NexusEvent"])  # noqa: E402


# ── Late-bound globals ──────────────────────────────────────────────────────
hw_config = None
plugin_manager = None

def _init_globals():
    global hw_config, plugin_manager
    if HardwareProbe is not None:
        try:
            hw_config = HardwareProbe.get_gpu_config()
        except Exception as exc:
            _log.debug("HardwareProbe.get_gpu_config() failed: %s", exc)
            hw_config = {}
    if PluginManager is not None:
        try:
            pm = PluginManager()
            pm.discover_exporters()
            plugin_manager = pm
        except Exception as exc:
            _log.debug("PluginManager init failed: %s", exc)
            plugin_manager = None

_init_globals()


__all__ = [
    "AppConfig",
    "logger",
    "NexusBaseException",
    "AIProcessingError",
    "LLMGuardrailError",
    "BrokerConnectionError",
    "VectorDBError",
    "Vault",
    "async_retry",
    "LLMGuard",
    "InvoiceLLMExtraction",
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
    "HardwareProbe",
    "hw_config",
]
