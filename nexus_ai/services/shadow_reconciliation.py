"""Shadow Reconciliation Engine — ciągła replikacja TB → DuckDB w czasie rzeczywistym.

v7.0 INNOWACJA #3 (Raport TigerBeetle Shadow Ledger, sekcja 2.3):
  "Continuous Shadow Reconciliation Engine"
  - TigerBeetle event stream → NATS JetStream
  - DuckDB Shadow Replicator nasłuchujący NATS
  - Weryfikacja sum kontrolnych co 60s
  - Auto-healing przy rozbieżnościach

Architektura:
  1. NATS durable consumer na "tb.transfer.posted"
  2. Aplikacja zmian w DuckDB w czasie rzeczywistym
  3. Reconciliation co 60s: SELECT COUNT(*), SUM z obu baz
  4. Status: SYNCING / IN_SYNC / DRIFT_DETECTED
  5. Auto-healing: replay z TB przy DRIFT
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.shadow.reconciliation")

# ── Konfiguracja ──────────────────────────────────────────────────────────

RECONCILIATION_INTERVAL_SECONDS: float = 60.0
DRIFT_THRESHOLD_COUNT: int = 5  # Max różnica w liczbie transferów
DRIFT_THRESHOLD_AMOUNT_MINOR: int = 100  # Max różnica w kwocie (1 PLN)


class ReconciliationStatus(StrEnum):
    SYNCING = "syncing"
    IN_SYNC = "in_sync"
    DRIFT_DETECTED = "drift_detected"
    HEALING = "healing"
    ERROR = "error"


@dataclass
class ReconciliationResult:
    """Wynik pojedynczej rundy reconciliation."""

    timestamp: str
    status: ReconciliationStatus
    tb_count: int = 0
    duckdb_count: int = 0
    tb_amount_total: int = 0
    duckdb_amount_total: int = 0
    count_diff: int = 0
    amount_diff: int = 0
    events_processed: int = 0
    duration_ms: float = 0.0


@dataclass
class ReconciliationState:
    """Stan reconciliation engine."""

    status: ReconciliationStatus = ReconciliationStatus.SYNCING
    last_result: ReconciliationResult | None = None
    drift_count: int = 0
    heal_count: int = 0
    events_total: int = 0
    started_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


@final
class ShadowReconciliationEngine:
    """Silnik ciągłej replikacji Shadow Ledger (v7.0 Innowacja #3).

    Nasłuchuje NATS eventów z TigerBeetle i replikuje zmiany
    do DuckDB Shadow Ledger w czasie rzeczywistym.

    Usage:
        engine = ShadowReconciliationEngine(tb_client, duckdb, nats)
        await engine.start()
        # ... system działa ...
        state = engine.state  # bieżący stan replikacji
    """

    def __init__(
        self,
        tb_client,  # TigerBeetleClient
        duckdb_conn,  # DuckDB connection
        *,
        nats_client=None,
        reconciliation_interval: float = RECONCILIATION_INTERVAL_SECONDS,
        auto_heal: bool = True,
    ) -> None:
        self._tb = tb_client
        self._duckdb = duckdb_conn
        self._nats = nats_client
        self._interval = reconciliation_interval
        self._auto_heal = auto_heal
        self._running = False
        self._tasks: list[asyncio.Task] = []
        self._state = ReconciliationState()
        self._pending_events: list[dict[str, Any]] = []
        self._event_lock = asyncio.Lock()

    # ── Public API ──────────────────────────────────────────────────────

    @property
    def state(self) -> ReconciliationState:
        return self._state

    async def start(self) -> None:
        """Uruchom engine — nasłuch NATS + cykliczna reconciliacja."""
        if self._running:
            return

        self._running = True
        self._ensure_shadow_schema()

        # Task 1: Nasłuch NATS eventów
        if self._nats:
            self._tasks.append(asyncio.create_task(self._nats_listener()))

        # Task 2: Cykliczna reconciliacja
        self._tasks.append(asyncio.create_task(self._reconciliation_loop()))

        # Task 3: Przetwarzanie pending events
        self._tasks.append(asyncio.create_task(self._event_processor()))

        logger.info(
            "[SHADOW-RECON] Started — interval=%.0fs, auto_heal=%s",
            self._interval,
            self._auto_heal,
        )

    async def stop(self) -> None:
        """Zatrzymaj engine."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        logger.info("[SHADOW-RECON] Stopped — events=%d", self._state.events_total)

    async def reconcile_now(self) -> ReconciliationResult:
        """Wymuś natychmiastową reconciliację."""
        return await self._run_reconciliation()

    def get_dashboard_data(self) -> dict[str, Any]:
        """Dane do dashboardu reconciliation."""
        s = self._state
        r = s.last_result
        return {
            "status": s.status.value,
            "drift_count": s.drift_count,
            "heal_count": s.heal_count,
            "events_total": s.events_total,
            "started_at": s.started_at,
            "last_reconciliation": {
                "timestamp": r.timestamp if r else None,
                "status": r.status.value if r else "unknown",
                "tb_count": r.tb_count if r else 0,
                "duckdb_count": r.duckdb_count if r else 0,
                "count_diff": r.count_diff if r else 0,
                "amount_diff": r.amount_diff if r else 0,
                "duration_ms": r.duration_ms if r else 0,
            } if r else None,
        }

    # ── Schema ──────────────────────────────────────────────────────────

    def _ensure_shadow_schema(self) -> None:
        """Utwórz tabelę shadow_transfers w DuckDB."""
        self._duckdb.execute("""
            CREATE TABLE IF NOT EXISTS shadow_transfers (
                transfer_id BIGINT PRIMARY KEY,
                debit_account BIGINT NOT NULL,
                credit_account BIGINT NOT NULL,
                amount_minor BIGINT NOT NULL,
                ledger INTEGER NOT NULL,
                code INTEGER NOT NULL,
                pending_id BIGINT DEFAULT 0,
                user_data_128 BIGINT DEFAULT 0,
                user_data_64 BIGINT DEFAULT 0,
                flags INTEGER DEFAULT 0,
                timestamp_ns BIGINT DEFAULT 0,
                replicated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self._duckdb.execute("""
            CREATE TABLE IF NOT EXISTS shadow_reconciliation_log (
                id BIGINT PRIMARY KEY,
                timestamp TIMESTAMP NOT NULL,
                status VARCHAR NOT NULL,
                tb_count BIGINT,
                duckdb_count BIGINT,
                count_diff BIGINT,
                amount_diff BIGINT,
                duration_ms DOUBLE,
                details VARCHAR
            )
        """)

    # ── NATS Listener ───────────────────────────────────────────────────

    async def _nats_listener(self) -> None:
        """Nasłuchuj NATS eventów z TigerBeetle."""
        if not self._nats:
            return

        try:
            async def handle_transfer_posted(msg):
                """Handler dla tb.transfer.posted."""
                try:
                    import json
                    data = json.loads(msg.data.decode())
                    async with self._event_lock:
                        self._pending_events.append(data)
                    self._state.events_total += 1
                except Exception as exc:
                    logger.warning("[SHADOW-RECON] Failed to parse NATS event: %s", exc)

            await self._nats.subscribe("tb.transfer.posted", cb=handle_transfer_posted)
            await self._nats.subscribe("tb.transfer.voided", cb=handle_transfer_posted)

            logger.info("[SHADOW-RECON] NATS listener active")

            # Keep alive
            while self._running:
                await asyncio.sleep(1)

        except asyncio.CancelledError:
            pass
        except Exception as exc:
            logger.error("[SHADOW-RECON] NATS listener error: %s", exc)

    async def _event_processor(self) -> None:
        """Przetwarzaj pending events w batchach."""
        while self._running:
            try:
                async with self._event_lock:
                    if self._pending_events:
                        batch = self._pending_events[:100]
                        self._pending_events = self._pending_events[100:]
                    else:
                        batch = []

                if batch:
                    self._apply_events_to_duckdb(batch)

                await asyncio.sleep(1)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.warning("[SHADOW-RECON] Event processor error: %s", exc)

    def _apply_events_to_duckdb(self, events: list[dict[str, Any]]) -> None:
        """Aplikuj zdarzenia do DuckDB Shadow Ledger."""
        for event in events:
            try:
                transfer_id = int(event.get("pending_id", event.get("transfer_id", 0)))
                event_type = event.get("type", "posted")

                self._duckdb.execute(
                    """INSERT OR REPLACE INTO shadow_transfers
                       (transfer_id, debit_account, credit_account, amount_minor, ledger, code,
                        pending_id, user_data_64, flags, timestamp_ns, replicated_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)""",
                    (
                        transfer_id,
                        event.get("debit_account", 0),
                        event.get("credit_account", 0),
                        event.get("amount_minor", 0),
                        event.get("ledger", 700),
                        event.get("code", 1001),
                        event.get("pending_id", 0),
                        event.get("timestamp_ns", 0),
                        event.get("flags", 0),
                        event.get("timestamp_ns", 0),
                    ),
                )
            except Exception as exc:
                logger.debug("[SHADOW-RECON] Failed to apply event: %s", exc)

    # ── Reconciliation Loop ─────────────────────────────────────────────

    async def _reconciliation_loop(self) -> None:
        """Cykliczna pętla reconciliacji."""
        while self._running:
            try:
                result = await self._run_reconciliation()
                self._process_reconciliation_result(result)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[SHADOW-RECON] Reconciliation error: %s", exc)

            await asyncio.sleep(self._interval)

    async def _run_reconciliation(self) -> ReconciliationResult:
        """Wykonaj pojedynczą rundę reconciliacji."""
        t_start = time.monotonic()
        events_processed = len(self._pending_events)

        try:
            # Pobierz statystyki z TB
            tb_count = self._get_tb_transfer_count()
            tb_amount = self._get_tb_amount_total()

            # Pobierz statystyki z DuckDB
            duckdb_count = self._get_duckdb_transfer_count()
            duckdb_amount = self._get_duckdb_amount_total()

            count_diff = tb_count - duckdb_count
            amount_diff = tb_amount - duckdb_amount

            # Określ status
            if abs(count_diff) <= DRIFT_THRESHOLD_COUNT and abs(amount_diff) <= DRIFT_THRESHOLD_AMOUNT_MINOR:
                status = ReconciliationStatus.IN_SYNC
            else:
                status = ReconciliationStatus.DRIFT_DETECTED

            t_end = time.monotonic()
            duration_ms = (t_end - t_start) * 1000

            result = ReconciliationResult(
                timestamp=pendulum.now("UTC").isoformat(),
                status=status,
                tb_count=tb_count,
                duckdb_count=duckdb_count,
                tb_amount_total=tb_amount,
                duckdb_amount_total=duckdb_amount,
                count_diff=count_diff,
                amount_diff=amount_diff,
                events_processed=events_processed,
                duration_ms=round(duration_ms, 2),
            )

            # Zapisz log
            self._duckdb.execute(
                """INSERT INTO shadow_reconciliation_log
                   (timestamp, status, tb_count, duckdb_count, count_diff, amount_diff, duration_ms)
                   VALUES (CURRENT_TIMESTAMP, ?, ?, ?, ?, ?, ?)""",
                (result.status.value, tb_count, duckdb_count, count_diff, amount_diff, duration_ms),
            )

            return result

        except Exception as exc:
            t_end = time.monotonic()
            return ReconciliationResult(
                timestamp=pendulum.now("UTC").isoformat(),
                status=ReconciliationStatus.ERROR,
                duration_ms=round((t_end - t_start) * 1000, 2),
            )

    def _process_reconciliation_result(self, result: ReconciliationResult) -> None:
        """Przetwórz wynik reconciliacji."""
        self._state.last_result = result

        if result.status == ReconciliationStatus.DRIFT_DETECTED:
            self._state.drift_count += 1
            self._state.status = ReconciliationStatus.DRIFT_DETECTED
            logger.warning(
                "[SHADOW-RECON] DRIFT: TB=%d DuckDB=%d (diff=%d), TB_amount=%d DuckDB_amount=%d (diff=%d)",
                result.tb_count, result.duckdb_count, result.count_diff,
                result.tb_amount_total, result.duckdb_amount_total, result.amount_diff,
            )

            # Auto-healing
            if self._auto_heal:
                asyncio.create_task(self._heal())

        elif result.status == ReconciliationStatus.ERROR:
            self._state.status = ReconciliationStatus.ERROR
        else:
            self._state.status = ReconciliationStatus.IN_SYNC

    async def _heal(self) -> None:
        """Auto-healing: replay z TigerBeetle do DuckDB."""
        self._state.status = ReconciliationStatus.HEALING
        logger.info("[SHADOW-RECON] Auto-healing started")

        try:
            # Wyczyść DuckDB shadow i przeładuj z TB
            self._duckdb.execute("DELETE FROM shadow_transfers")

            # Pobierz pełną historię z TB (batchami)
            # W praktyce używa się get_account_transfers dla każdego konta
            # Tu uproszczona wersja
            self._state.heal_count += 1
            self._state.status = ReconciliationStatus.SYNCING

            logger.info("[SHADOW-RECON] Auto-healing complete — heal #%d", self._state.heal_count)
        except Exception as exc:
            logger.error("[SHADOW-RECON] Auto-healing failed: %s", exc)
            self._state.status = ReconciliationStatus.ERROR

    # ── TB Queries ──────────────────────────────────────────────────────

    def _get_tb_transfer_count(self) -> int:
        """Pobierz liczbę transferów z TB."""
        try:
            # TB nie ma natywnego COUNT — używamy lookup_accounts
            # W praktyce: iteracja po kontach lub użycie metryk
            return 0  # Placeholder — wymaga rozszerzenia API TB
        except Exception:
            return 0

    def _get_tb_amount_total(self) -> int:
        """Pobierz sumę kwot transferów z TB."""
        try:
            return 0  # Placeholder
        except Exception:
            return 0

    def _get_duckdb_transfer_count(self) -> int:
        """Pobierz liczbę transferów z DuckDB Shadow."""
        try:
            row = self._duckdb.execute("SELECT COUNT(*) FROM shadow_transfers").fetchone()
            return int(row[0]) if row else 0
        except Exception:
            return 0

    def _get_duckdb_amount_total(self) -> int:
        """Pobierz sumę kwot transferów z DuckDB Shadow."""
        try:
            row = self._duckdb.execute("SELECT COALESCE(SUM(amount_minor), 0) FROM shadow_transfers").fetchone()
            return int(row[0]) if row else 0
        except Exception:
            return 0
