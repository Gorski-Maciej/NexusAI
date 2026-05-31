# CORE/__init__.py
"""NexusAI Core — safe lazy imports for constrained environments."""
from __future__ import annotations

import logging as _logging

_log = _logging.getLogger("nexus.core")

# ── Helper: safe lazy import ─────────────────────────────────────────────────

def _safe_import(qualname: str, names: list[str]):
    """Try to import *names* from *qualname*; return (module, imported_names) on success."""
    try:
        mod = __import__(qualname, fromlist=names)
        return mod, [getattr(mod, n) for n in names]
    except (ImportError, ModuleNotFoundError, AttributeError) as exc:
        _log.debug("Optional import %s.%s unavailable: %s", qualname, names, exc)
        return None, [None] * len(names)

# ── Always-available modules ──────────────────────────────────────────────────

from CORE.config import AppConfig
from CORE.logger import logger
from CORE.exceptions import (
    NexusBaseException,
    AIProcessingError,
    LLMGuardrailError,
    BrokerConnectionError,
    VectorDBError,
)

# ── Optional / gracefully-falling modules ─────────────────────────────────────

# core.crypto — Vault (optional, needs cryptography)
_, [Vault] = _safe_import("CORE.crypto", ["Vault"])

# core.llm_guard (optional)
_, [LLMGuard, InvoiceLLMExtraction] = _safe_import(
    "CORE.llm_guard", ["LLMGuard", "InvoiceLLMExtraction"]
)

# core.resilience (optional)
_, [async_retry] = _safe_import("CORE.resilience", ["async_retry"])

# core.secrets (optional)
_, [SecretsManager] = _safe_import("CORE.secrets", ["SecretsManager"])

# core.monitor (optional)
_, [SystemMonitor] = _safe_import("CORE.monitor", ["SystemMonitor"])

# core.prompts (optional)
_, [PromptTemplate] = _safe_import("CORE.prompts", ["PromptTemplate"])

# core.bus (optional)
_, [bus] = _safe_import("CORE.bus", ["bus"])

# core.parsers (optional)
_, [DataParser] = _safe_import("CORE.parsers", ["DataParser"])

# core.ai_context (optional)
_, [AIContextManager] = _safe_import("CORE.ai_context", ["AIContextManager"])

# core.plugins (optional)
_, [PluginManager] = _safe_import("CORE.plugins", ["PluginManager"])

# core.hardware (optional)
_, [HardwareProbe] = _safe_import("CORE.hardware", ["HardwareProbe"])

# core.events (optional)
_, [NexusEvent] = _safe_import("CORE.events", ["NexusEvent"])

# core.storage (optional — may not exist in all deployments)
_, [StorageProvider, LocalStorageProvider] = _safe_import(
    "CORE.storage", ["StorageProvider", "LocalStorageProvider"]
)

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
    "LLMGuard",
    "InvoiceLLMExtraction",
    "async_retry",
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
