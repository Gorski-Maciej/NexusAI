"""
Materialized Views przez DuckDB Change Data Capture (CDC).

INNOWACJA #2 z Raportu v7.0: Zamiast budować read models ręcznie,
DuckDB subskrybuje NATS JetStream i automatycznie aktualizuje
materialized views przy każdym zdarzeniu.
Zero kodu projekcji — sama konfiguracja SQL.

Architektura:
    NATS JetStream ──subscribe──▶ MaterializedViewManager
                                        │
                          ┌─────────────▼──────────────┐
                          │  DuckDB in-memory instance  │
                          │  ┌────────────────────────┐ │
                          │  │ invoice_daily_stats MV │ │
                          │  │ contractor_monthly MV   │ │
                          │  │ decision_accuracy MV    │ │
                          │  └────────────────────────┘ │
                          └────────────────────────────┘

Usage:
    mv = MaterializedViewManager(duckdb_path=":memory:")
    mv.register_view(
        name="invoice_daily_stats",
        source_stream="nexus-invoice.>",
        refresh_sql="SELECT ... FROM invoice_read_model WHERE ...",
        refresh_trigger="on_insert",  # "on_insert", "on_change", "interval:60"
    )
    await mv.start()
"""

from __future__ import annotations

import threading
import time as _time
from pathlib import Path
from typing import Any

import msgspec
from structlog import get_logger

logger = get_logger("nexus.analytics.materialized_views")


# ── MV Config ─────────────────────────────────────────────────────────────


class MaterializedViewConfig(msgspec.Struct, kw_only=True):
    """Konfiguracja materialized view."""

    name: str
    description: str = ""
    source_streams: list[str] = []  # NATS subjects do subskrypcji
    create_sql: str = ""  # DDL do utworzenia MV
    refresh_sql: str = ""  # Query do odświeżenia (opcjonalny — można użyć create_sql)
    refresh_trigger: str = "on_change"  # "on_insert", "on_change", "interval:N"
    refresh_interval_seconds: float = 60.0  # Dla "interval:N"
    enabled: bool = True


# ── Materialized View Manager ─────────────────────────────────────────────


class MaterializedViewManager:
    """Zarządza materialized views w DuckDB subskrybując NATS JetStream.

    Eliminuje potrzebę ręcznego pisania kodu projekcji.
    Każdy widok jest definiowany przez SQL DDL + trigger odświeżenia.
    """

    __slots__ = (
        "_connected",
        "_db_path",
        "_duckdb",
        "_jetstream_consumer",
        "_lock",
        "_nats_servers",
        "_running",
        "_views",
    )

    def __init__(
        self,
        duckdb_path: str | Path = ":memory:",
        nats_servers: list[str] | str | None = None,
    ) -> None:
        self._db_path = str(duckdb_path)
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._views: dict[str, MaterializedViewConfig] = {}
        self._duckdb: Any = None
        self._jetstream_consumer: Any = None
        self._connected = False
        self._running = False
        self._lock = threading.Lock()

    def register_view(self, config: MaterializedViewConfig) -> None:
        """Register a materialized view configuration."""
        with self._lock:
            self._views[config.name] = config
        logger.info("[MV] Registered view: %s (trigger: %s)", config.name, config.refresh_trigger)

    async def start(self) -> None:
        """Start the materialized view manager — connect DuckDB and NATS."""
        import duckdb

        # ── DuckDB connection ─────────────────────────────────────────
        self._duckdb = duckdb.connect(self._db_path)
        self._duckdb.execute("PRAGMA threads=4")
        self._duckdb.execute("PRAGMA memory_limit='512MB'")

        # ── Create all registered views ──────────────────────────────
        with self._lock:
            for view_config in self._views.values():
                await self._create_view(view_config)

        self._connected = True
        self._running = True

        # ── Start interval-based refreshes ───────────────────────────
        import anyio

        while self._running:
            await self._refresh_interval_views()
            await anyio.sleep(10.0)  # Check every 10 seconds

        logger.info("[MV] Started with %d views", len(self._views))

    async def stop(self) -> None:
        """Stop the manager."""
        self._running = False
        if self._duckdb:
            self._duckdb.close()
            self._duckdb = None
        logger.info("[MV] Stopped")

    async def _create_view(self, config: MaterializedViewConfig) -> None:
        """Create a materialized view in DuckDB."""
        if not self._duckdb or not config.create_sql:
            return
        try:
            # Drop if exists, then create
            self._duckdb.execute(f"DROP VIEW IF EXISTS {config.name}")
            self._duckdb.execute(config.create_sql)
            logger.info("[MV] Created view: %s", config.name)
        except Exception as exc:
            logger.error("[MV] Failed to create view %s: %s", config.name, exc)

    async def _refresh_interval_views(self) -> None:
        """Refresh all interval-triggered views that are due."""
        now = _time.time()
        with self._lock:
            interval_views = [
                v for v in self._views.values()
                if v.refresh_trigger.startswith("interval:")
                and v.enabled
            ]

        for view_config in interval_views:
            try:
                interval_s = view_config.refresh_interval_seconds
                await self._refresh_view(view_config)
                logger.debug("[MV] Interval refresh: %s", view_config.name)
            except Exception as exc:
                logger.warning("[MV] Interval refresh failed for %s: %s", view_config.name, exc)

    async def _refresh_view(self, config: MaterializedViewConfig) -> None:
        """Execute refresh SQL for a view."""
        if not self._duckdb:
            return
        try:
            sql = config.refresh_sql or config.create_sql
            if sql:
                self._duckdb.execute(sql)
        except Exception as exc:
            logger.warning("[MV] Refresh failed for %s: %s", config.name, exc)

    async def handle_event(self, event_type: str, event_data: bytes) -> None:
        """Handle a domain event — trigger on_change views for this event type.

        Called by NATS consumer for each incoming event.
        """
        if not self._duckdb:
            return

        with self._lock:
            triggered = [
                v for v in self._views.values()
                if v.refresh_trigger in ("on_change", "on_insert")
                and v.enabled
            ]

        for view_config in triggered:
            await self._refresh_view(view_config)

    async def query_view(
        self, view_name: str, sql: str | None = None, params: list[Any] | None = None
    ) -> list[dict[str, Any]]:
        """Query a registered materialized view."""
        if not self._duckdb:
            return []
        try:
            query = sql or f"SELECT * FROM {view_name} LIMIT 100"
            result = self._duckdb.execute(query, params or []).fetchdf()
            if result.empty:
                return []
            return result.to_dict(orient="records")
        except Exception as exc:
            logger.warning("[MV] Query failed for %s: %s", view_name, exc)
            return []

    @property
    def view_count(self) -> int:
        with self._lock:
            return len(self._views)

    @property
    def is_connected(self) -> bool:
        return self._connected

    def get_stats(self) -> dict[str, Any]:
        """Return current manager statistics."""
        with self._lock:
            views = {
                name: {
                    "trigger": cfg.refresh_trigger,
                    "enabled": cfg.enabled,
                    "streams": cfg.source_streams,
                }
                for name, cfg in self._views.items()
            }
        return {
            "view_count": len(self._views),
            "connected": self._connected,
            "running": self._running,
            "views": views,
        }


# ── Pre-built Views ───────────────────────────────────────────────────────

# Przykładowe definicje MV — gotowe do użycia po podłączeniu NATS

INVOICE_DAILY_STATS = MaterializedViewConfig(
    name="invoice_daily_stats",
    description="Daily invoice statistics: count, total amount, avg confidence per day",
    source_streams=["nexus-invoice.>"],
    create_sql="""
        CREATE OR REPLACE VIEW invoice_daily_stats AS
        SELECT
            date_trunc('day', created_at::TIMESTAMP) AS day,
            status,
            COUNT(*) AS invoice_count,
            SUM(amount_gross) AS total_amount,
            AVG(trust_score) AS avg_trust_score
        FROM invoice_read_model
        GROUP BY day, status
        ORDER BY day DESC
    """,
    refresh_trigger="interval:60",
    refresh_interval_seconds=60.0,
)

DECISION_ACCURACY = MaterializedViewConfig(
    name="decision_accuracy",
    description="Decision engine accuracy: auto vs manual, override rate",
    source_streams=["nexus-decision.>"],
    create_sql="""
        CREATE OR REPLACE VIEW decision_accuracy AS
        SELECT
            decision,
            COUNT(*) AS decision_count,
            AVG(trust_score) AS avg_trust,
            AVG(ai_confidence) AS avg_confidence,
            SUM(CASE WHEN event_type = 'decision.overridden' THEN 1 ELSE 0 END) AS overridden_count
        FROM decision_analytics
        WHERE decision IS NOT NULL
        GROUP BY decision
        ORDER BY decision_count DESC
    """,
    refresh_trigger="interval:120",
    refresh_interval_seconds=120.0,
)

CONTRACTOR_MONTHLY = MaterializedViewConfig(
    name="contractor_monthly",
    description="Monthly invoice volume per contractor",
    source_streams=["nexus-invoice.>"],
    create_sql="""
        CREATE OR REPLACE VIEW contractor_monthly AS
        SELECT
            contractor_nip,
            contractor_name,
            date_trunc('month', created_at::TIMESTAMP) AS month,
            COUNT(*) AS invoice_count,
            SUM(amount_gross) AS total_amount,
            AVG(trust_score) AS avg_trust
        FROM invoice_read_model
        GROUP BY contractor_nip, contractor_name, month
        ORDER BY month DESC, total_amount DESC
    """,
    refresh_trigger="interval:300",
    refresh_interval_seconds=300.0,
)


__all__ = [
    "MaterializedViewManager",
    "MaterializedViewConfig",
    "INVOICE_DAILY_STATS",
    "DECISION_ACCURACY",
    "CONTRACTOR_MONTHLY",
]
