"""AppServices — centralny DI container dla NexusAI.

Zastępuje 62+ wystąpień `global` przez Litestar-compatible DI.
Dostarcza:
- AppServices — wszystkie serwisy wstrzykiwane jako dataclass
- LazyImport — bezpieczny lazy loading z kontrolą typów
- create_app_services() — fabryka tworząca wszystkie serwisy

Usage:
    @app.get("/invoices")
    async def list_invoices(self, services: AppServices) -> list[dict]:
        return await services.invoice_service.list()
"""

from __future__ import annotations

import importlib
from dataclasses import dataclass, field
from typing import Any

import warnings

from nexus_ai.core.config import AppConfig
from nexus_ai.db.database import create_oltp_engine, create_session_factory

# ── Module-level imports for DI container (NOT inline — Enterprise TOP-2 fix) ──
from nexus_ai.core.decision_engine import DecisionEngine
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.events import EventStore, JetStreamEventBus
from nexus_ai.core.inference import ModelManager
from nexus_ai.core.broker import broker


class LazyImport:
    """Lazy import z opóźnionym ładowaniem — widoczny dla mypy.

    Zastępuje inline importy (import wewnątrz funkcji).
    Ładuje moduł dopiero przy pierwszym dostępie do atrybutu.

    Usage:
        doctr_io = LazyImport("doctr.io", "DocumentFile")
        # Import następuje dopiero tutaj:
        doc = doctr_io.DocumentFile.from_images(path)
    """

    __slots__ = ("_module", "_name", "_mod")

    def __init__(self, module: str, name: str | None = None) -> None:
        self._module = module
        self._name = name
        self._mod: Any = None

    def __getattr__(self, attr: str) -> Any:
        if self._mod is None:
            self._mod = importlib.import_module(self._module)
        if self._name:
            return getattr(self._mod, self._name)
        return getattr(self._mod, attr)

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        if self._mod is None:
            self._mod = importlib.import_module(self._module)
        if self._name:
            return getattr(self._mod, self._name)(*args, **kwargs)
        return self._mod(*args, **kwargs)


# ── Lazy-loaded modules ─────────────────────────────────────────────
# Zastępują inline importy w pipeline/ i services/

doctr_io = LazyImport("doctr.io", "DocumentFile")
paddleocr = LazyImport("paddleocr", "PaddleOCR")
gc_module = LazyImport("gc")
risk_guard = LazyImport("nexus_ai.services.risk_guard", "RiskGuard")
billing_estimator = LazyImport("nexus_ai.services.billing_estimator", "BillingEstimator")
rule_store = LazyImport("nexus_ai.services.rule_store", "RuleStore")
fallback_handler = LazyImport("nexus_ai.services.fallback_handler", "FallbackHandler")
replay_engine = LazyImport("nexus_ai.services.replay_engine", "ReplayEngine")
integrity_verifier = LazyImport("nexus_ai.services.integrity_verifier", "IntegrityVerifier")


@dataclass
class AppServices:
    """Centralny rejestr serwisów — zastępuje 62+ wystąpień `global`.

    Wszystkie serwisy są tworzone przez fabrykę i wstrzykiwane
    przez Litestar DI. Żadnych globali, żadnych singletonów.
    """

    config: AppConfig = field(default_factory=AppConfig)
    engine: Any = None
    session_factory: Any = None

    # Lazy-loaded serwisy (inicjalizowane na żądanie)
    _services: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.engine is None:
            self.engine = create_oltp_engine(self.config)
        if self.session_factory is None:
            self.session_factory = create_session_factory(self.engine)

    def get(self, name: str) -> Any:
        """Pobierz serwis po nazwie — lazy init z cache."""
        if name not in self._services:
            self._services[name] = self._create(name)
        return self._services[name]

    def _create(self, name: str) -> Any:
        """Utwórz serwis — zastępuje `global _default_X`."""
        match name:
            case "decision_engine":
                return DecisionEngine(self.config)
            case "duckdb_manager":
                return DuckDBManager(db_path=self.config.duckdb_path, sqlite_path=self.config.sqlite_path)
            case "event_store":
                return EventStore(sqlite_path=self.config.sqlite_path)
            case "jetstream_bus":
                return JetStreamEventBus(nats_servers=self.config.nats_url)
            case "model_manager":
                return ModelManager(config=self.config)
            case "broker":
                return broker
            case _:
                raise KeyError(f"Unknown service: {name}")

    @property
    def decision_engine(self) -> Any:
        return self.get("decision_engine")

    @property
    def duckdb_manager(self) -> Any:
        return self.get("duckdb_manager")

    @property
    def event_store(self) -> Any:
        return self.get("event_store")

    @property
    def jetstream_bus(self) -> Any:
        return self.get("jetstream_bus")

    @property
    def model_manager(self) -> Any:
        return self.get("model_manager")

    @property
    def broker(self) -> Any:
        return self.get("broker")


# ── Fabryka dla Litestar DI ────────────────────────────────────────


def create_app_services(config: AppConfig | None = None) -> AppServices:
    """Fabryka tworząca AppServices — do użycia z Litestar Provide()."""
    cfg = config or AppConfig()
    return AppServices(config=cfg)


# ── Singleton dla backward compatibility ───────────────────────────
# UWAGA: Ten singleton jest TYLKO dla kodu który nie został jeszcze
# zmigrowany do DI. Docelowo: usuń.
_default_services: AppServices | None = None


def get_services() -> AppServices:
    """Pobierz domyślne serwisy (backward compat).

    DEPRECATED: Użyj create_app_services() z Litestar DI zamiast get_services().
    Ten singleton zostanie usunięty w następnej wersji.
    """
    warnings.warn(
        "get_services() is deprecated. Use create_app_services() with DI injection instead.",
        DeprecationWarning,
        stacklevel=2,
    )
    global _default_services
    if _default_services is None:
        _default_services = create_app_services()
    return _default_services
