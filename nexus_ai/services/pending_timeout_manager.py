"""Pending Timeout Manager — automatyczne voidowanie przeterminowanych pending.

v7.0 AUDIT (Raport TigerBeetle Shadow Ledger, sekcja 1.3, 11.3):
  "timeout=0 → brak automatycznego void po czasie"
  "PENDING timeout >0 jako priorytet PILNY #1"

Ten moduł implementuje:
- Cykliczne skanowanie pending transferów (co 60s)
- Automatyczne voidowanie tych z przekroczonym timeoutem
- Rejestr voidniętych transferów dla audytu
- Integracja z ContinuousAudit dla logowania
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.pending.timeout")


# ── Konfiguracja ──────────────────────────────────────────────────────────

SCAN_INTERVAL_SECONDS: int = 60
DEFAULT_PENDING_TIMEOUT_SECONDS: int = 3600


@dataclass
class VoidedPendingRecord:
    """Rekord automatycznie voidniętego pending transferu."""

    pending_id: str
    voided_at: str
    reason: str = "timeout_expired"
    age_seconds: int = 0
    amount_minor: int = 0


@dataclass
class TimeoutManagerState:
    """Stan PendingTimeoutManager."""

    scans_total: int = 0
    voided_total: int = 0
    active_pending: int = 0
    last_scan: str = ""
    recent_voids: list[VoidedPendingRecord] = field(default_factory=list)


@final
class PendingTimeoutManager:
    """Automatyczne voidowanie przeterminowanych pending transferów (v7.0 AUDIT).

    Skanuje pending transfery i automatycznie voiduje te,
    których timeout minął. Zapobiega "wiszącym" pendingom.

    Usage:
        manager = PendingTimeoutManager(tb_client, duckdb_conn)
        await manager.start()
    """

    def __init__(
        self,
        tb_client=None,
        duckdb_conn=None,
        *,
        scan_interval: int = SCAN_INTERVAL_SECONDS,
        default_timeout: int = DEFAULT_PENDING_TIMEOUT_SECONDS,
    ) -> None:
        self._tb = tb_client
        self._duckdb = duckdb_conn
        self._interval = scan_interval
        self._default_timeout = default_timeout
        self._running = False
        self._tasks: list[asyncio.Task] = []
        self._state = TimeoutManagerState()
        self._pending_cache: dict[str, dict[str, Any]] = {}

    @property
    def state(self) -> TimeoutManagerState:
        return self._state

    async def start(self) -> None:
        """Uruchom cykliczne skanowanie."""
        if self._running:
            return
        self._running = True
        self._ensure_schema()
        self._tasks.append(asyncio.create_task(self._scan_loop()))
        logger.info("[PENDING-TIMEOUT] Started — interval=%ds, timeout=%ds",
                     self._interval, self._default_timeout)

    async def stop(self) -> None:
        """Zatrzymaj skanowanie."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        logger.info("[PENDING-TIMEOUT] Stopped — voided=%d", self._state.voided_total)

    async def register_pending(self, pending_id: str, metadata: dict[str, Any]) -> None:
        """Zarejestruj nowy pending transfer do monitorowania.

        Args:
            pending_id: ID pending transferu.
            metadata: Metadane (created_at, timeout, amount_minor).
        """
        self._pending_cache[pending_id] = {
            "created_at": metadata.get("created_at", time.time()),
            "timeout": metadata.get("timeout", self._default_timeout),
            "amount_minor": metadata.get("amount_minor", 0),
            "debit_account": metadata.get("debit_account", 0),
            "credit_account": metadata.get("credit_account", 0),
        }
        self._state.active_pending = len(self._pending_cache)

    async def unregister_pending(self, pending_id: str) -> None:
        """Usuń pending z monitorowania (został już posted/voided)."""
        self._pending_cache.pop(pending_id, None)
        self._state.active_pending = len(self._pending_cache)

    # ── Internal ────────────────────────────────────────────────────────

    def _ensure_schema(self) -> None:
        """Utwórz tabelę do śledzenia voidniętych pendingów."""
        if not self._duckdb:
            return
        self._duckdb.execute("""
            CREATE TABLE IF NOT EXISTS pending_void_log (
                pending_id VARCHAR PRIMARY KEY,
                voided_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                reason VARCHAR NOT NULL DEFAULT 'timeout_expired',
                age_seconds INTEGER NOT NULL DEFAULT 0,
                amount_minor BIGINT NOT NULL DEFAULT 0,
                debit_account BIGINT NOT NULL DEFAULT 0,
                credit_account BIGINT NOT NULL DEFAULT 0
            )
        """)

    async def _scan_loop(self) -> None:
        """Główna pętla skanowania."""
        while self._running:
            try:
                voided = await self._scan_and_void()
                now = pendulum.now("UTC")
                self._state.scans_total += 1
                self._state.last_scan = now.isoformat()

                if voided > 0:
                    logger.warning("[PENDING-TIMEOUT] Voided %d expired pending transfers", voided)

            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[PENDING-TIMEOUT] Scan error: %s", exc)

            await asyncio.sleep(self._interval)

    async def _scan_and_void(self) -> int:
        """Skanuj i voiduj przeterminowane pending transfery."""
        now = time.time()
        voided_count = 0

        expired_ids = []
        for pid, meta in self._pending_cache.items():
            age = now - meta["created_at"]
            if age > meta["timeout"]:
                expired_ids.append(pid)

        for pid in expired_ids:
            meta = self._pending_cache.get(pid, {})
            age = int(now - meta.get("created_at", now))
            amount = meta.get("amount_minor", 0)

            try:
                # Void przez TB — konwertuj pid na int
                if self._tb:
                    ok = self._tb.void_pending_transfer(
                        int(pid),
                        ledger=meta.get("ledger", 700),
                        code=meta.get("code", 7001),
                    )
                    if not ok:
                        logger.warning("[PENDING-TIMEOUT] Void failed for %s", pid)
                        continue

                # Loguj
                record = VoidedPendingRecord(
                    pending_id=pid,
                    voided_at=pendulum.now("UTC").isoformat(),
                    reason="timeout_expired",
                    age_seconds=age,
                    amount_minor=amount,
                )

                self._state.voided_total += 1
                self._state.recent_voids.append(record)
                if len(self._state.recent_voids) > 100:
                    self._state.recent_voids = self._state.recent_voids[-100:]

                # Zapisz w DuckDB
                if self._duckdb:
                    self._duckdb.execute(
                        """INSERT OR REPLACE INTO pending_void_log
                           (pending_id, reason, age_seconds, amount_minor, debit_account, credit_account)
                           VALUES (?, ?, ?, ?, ?, ?)""",
                        (pid, "timeout_expired", age, amount,
                         meta.get("debit_account", 0), meta.get("credit_account", 0)),
                    )

                # Usuń z cache
                del self._pending_cache[pid]
                voided_count += 1

                logger.info("[PENDING-TIMEOUT] Voided %s after %ds (amount=%d minor)",
                             pid, age, amount)

            except Exception as exc:
                logger.warning("[PENDING-TIMEOUT] Error voiding %s: %s", pid, exc)

        self._state.active_pending = len(self._pending_cache)
        return voided_count

    def get_pending_summary(self) -> dict[str, Any]:
        """Podsumowanie pending transferów."""
        now = time.time()
        expired = sum(
            1 for meta in self._pending_cache.values()
            if now - meta["created_at"] > meta["timeout"]
        )
        return {
            "active_pending": self._state.active_pending,
            "expired_pending": expired,
            "healthy_pending": self._state.active_pending - expired,
            "voided_total": self._state.voided_total,
            "scans_total": self._state.scans_total,
            "last_scan": self._state.last_scan,
        }
