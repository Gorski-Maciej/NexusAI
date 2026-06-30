"""AdminServiceRegistry -- samo-rejestrujące się serwisy administracyjne.

Eliminuje ~1 030 linii powtarzalnego boilerplate'u DuckDB + NATS.
Każdy serwis dziedziczy po AdminServiceRegistry i automatycznie
rejestruje się w słowniku _registry pod swoją nazwą.

Usage:
    class RiskThresholdService(AdminServiceRegistry):
        _nats_subject = "risk.thresholds.updated"

        @classmethod
        def list(cls) -> list[dict]:
            with cls.db() as conn:
                return RiskGuard(conn).list_thresholds()

    # Automatycznie dostępne przez:
    AdminServiceRegistry.get("risk_threshold").list()
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any, ClassVar

import duckdb

from nexus_ai.core.config import AppConfig


def rule_service(nats_subject: str):
    """Dekorator rejestrujący serwis reguł z przedrostkiem NATS.

    Eliminuje ~30 linii boilerplate'u na każdy serwis reguł.

    Usage:
        @rule_service("risk.thresholds.updated")
        class RiskThresholdService(AdminServiceRegistry):
            @classmethod
            def list(cls) -> list[dict]:
                ...
    """
    def wrapper(cls: type) -> type:
        cls._nats_subject = nats_subject
        return cls
    return wrapper


class AdminServiceRegistry:
    """Base class for admin services -- auto-registration via __init_subclass__.

    Provides:
    - DuckDB connection (context manager)
    - NATS event publishing
    - DuckDB row -> dict conversion
    - Auto-registration in _registry

    Usage:
        class MyService(AdminServiceRegistry):
            _nats_subject = "my.service.updated"

            @classmethod
            def list(cls) -> list[dict]:
                with cls.db() as conn:
                    return cls._read_rows(...)
    """

    _registry: ClassVar[dict[str, type[AdminServiceRegistry]]] = {}
    _nats_subject: ClassVar[str] = ""

    def __init_subclass__(cls, **kwargs: Any) -> None:
        """Auto-register subclass w _registry pod snake_case name."""
        super().__init_subclass__(**kwargs)
        # Generuj nazwę: "RiskThresholdService" -> "risk_threshold"
        name = cls.__name__
        for suffix in ("Service", "AdminService", "Registry"):
            if name.endswith(suffix):
                name = name[: -len(suffix)]
                break
        # CamelCase to snake_case
        import re
        snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
        cls._registry[snake] = cls

    @classmethod
    def get(cls, name: str) -> type[AdminServiceRegistry]:
        """Pobierz serwis po nazwie snake_case."""
        if name not in cls._registry:
            raise KeyError(f"Admin service not registered: {name}. Available: {list(cls._registry.keys())}")
        return cls._registry[name]

    @classmethod
    @contextmanager
    def db(cls) -> Iterator[duckdb.DuckDBPyConnection]:
        """Context manager dla DuckDB -- auto-create i close."""
        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            cls._on_connect(conn)
            yield conn
        finally:
            conn.close()

    @classmethod
    def _on_connect(cls, conn: duckdb.DuckDBPyConnection) -> None:
        """Override to create tables on connect."""

    @classmethod
    def publish(cls, rule_id: str, action: str) -> None:
        """Opublikuj event NATS (fire-and-forget)."""
        if not cls._nats_subject:
            return
        import anyio

        from nexus_ai.core.nats_utils import publish_event as _publish
        try:
            anyio.ensure_backend().create_task(
                _publish(cls._nats_subject, {"rule_id": rule_id, "action": action})
            )
        except RuntimeError:
            pass

    @staticmethod
    def _read_rows(
        rows: list[Any],
        columns: tuple[str, ...],
        key_overrides: dict[str, str] | None = None,
    ) -> list[dict[str, Any]]:
        """Convert DuckDB rows to list of dicts."""
        return [
            {key_overrides.get(col, col): val for col, val in zip(columns, row)}
            for row in rows
        ]
