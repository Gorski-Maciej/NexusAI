# core/__init__.py
from core.config import AppConfig
from core.logger import logger
from core.exceptions import (
    NexusBaseException,
    AIProcessingError,
    LLMGuardrailError,
    BrokerConnectionError,
    VectorDBError
)
from core.crypto import Vault
from core.llm_guard import LLMGuard, InvoiceLLMExtraction
from core.resilience import async_retry
from core.storage import StorageProvider, LocalStorageProvider
from core.events import NexusEvent
from core.secrets import SecretsManager
from core.monitor import SystemMonitor
from core.prompts import PromptTemplate
from core.bus import bus
from core.parsers import DataParser
from core.ai_context import AIContextManager
from core.plugins import PluginManager
from core.hardware import HardwareProbe

# Inicjalizacja globalnych usług CORE
hw_config = HardwareProbe.get_gpu_config()
plugin_manager = PluginManager()
plugin_manager.discover_exporters()

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
    "hw_config"
]
