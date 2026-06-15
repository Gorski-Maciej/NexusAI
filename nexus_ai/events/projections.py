"""
AsyncProjections — CQRS read-side with sqlite3.

Python 3.13t (free-threaded): używamy natywnego sqlite3 + asyncio.to_thread
zamiast aiosqlite.

Każda projekcja:
  1. Czyta eventy z AsyncEventStore (od ostatniego checkpointu)
  2. Aktualizuje denormalizowany widok (SQLite przez sqlite3)
  3. Zapisuje checkpoint po przetworzeniu

SUPERMOC:
- async/await dla wszystkich operacji DB
- FTS5 na invoice_read_model z triggerami synchronizacji
- Partial indexes dla najczęstszych zapytań
"""

from __future__ import annotations

import asyncio
import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.db.async_base_service import AsyncBaseService
from nexus_ai.events.domain_events import (
    DomainEvent,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
    DecisionMade,
    DecisionOverridden,
)
from nexus_ai.events.event_store import AsyncEventStore

logger = get_logger("nexus.events.projections")


# ── Projection base class ────────────────────────────────────────────────


class AsyncProjection:
    """Bazowa klasa dla async projekcji CQRS.

    Args:
        event_store: AsyncEventStore do odczytu eventów.
        name: Nazwa projekcji (używana jako klucz checkpointu).
    """

    def __init__(self, event_store: AsyncEventStore, name: str) -> None:
        self._event_store = event_store
        self._name = name

    @property
    def name(self) -> str:
        return self._name

    async def rebuild(self) -> int:
        """Odtwórz projekcję od początku (async)."""
        await self._truncate()
        await self._event_store.update_checkpoint(self._name, "", 0)
        return await self.process()

    async def _truncate(self) -> None:
        """Wyczyść tabelę projekcji (async)."""
        raise NotImplementedError

    async def process(self) -> int:
        """Przetwórz nowe eventy od ostatniego checkpointu (async)."""
        checkpoint = await self._event_store.get_checkpoint(self._name)
        from_version = checkpoint + 1 if checkpoint > 0 else 0
        processed = 0

        events = await self._fetch_events(from_version)
        for event in events:
            try:
                await self._handle_event(event)
                processed += 1
                await self._event_store.update_checkpoint(
                    self._name,
                    event.event_id,
                    event.version,
                )
            except Exception as exc:
                logger.error(
                    "[PROJECTION:%s] Failed to process event %s: %s",
                    self._name,
                    event.event_id,
                    exc,
                )

        if processed:
            logger.info(
                "[PROJECTION:%s] Processed %d events (checkpoint=%d)",
                self._name,
                processed,
                await self._event_store.get_checkpoint(self._name),
            )

        return processed

    async def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        raise NotImplementedError

    async def _handle_event(self, event: DomainEvent) -> None:
        raise NotImplementedError


# ── Invoice Projection (async) ───────────────────────────────────────────


class AsyncInvoiceProjection(AsyncProjection, AsyncBaseService):
    """Async projekcja faktur — denormalizowany widok dla szybkich zapytań."""

    def __init__(
        self,
        event_store: AsyncEventStore,
        db_path: str | Path | None = None,
    ) -> None:
        AsyncProjection.__init__(self, event_store, name="invoice_projection")
        db_path = db_path or Path("app_data/projections/invoices.db")
        AsyncBaseService.__init__(self, db_path)
        Path(str(db_path)).parent.mkdir(parents=True, exist_ok=True)

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook: PRAGMY + schema creation dla projekcji faktur."""
        def _sync() -> None:
            conn.execute("PRAGMA cache_size = -25600;")     # 100MB cache
            conn.execute("PRAGMA temp_store = MEMORY;")     # Temp tables w RAM
            conn.execute("PRAGMA mmap_size = 2147483648;")  # 2GB mmap
        await asyncio.to_thread(_sync)
        await self._ensure_schema()

    async def _ensure_schema(self) -> None:
        await self.executescript("""
            CREATE TABLE IF NOT EXISTS invoice_read_model (
                invoice_id          TEXT PRIMARY KEY,
                number              TEXT,
                contractor_nip      TEXT,
                contractor_name     TEXT,
                amount_net          REAL DEFAULT 0,
                amount_gross        REAL DEFAULT 0,
                currency            TEXT DEFAULT 'PLN',
                category            TEXT,
                issue_date          TEXT,
                file_path           TEXT,
                status              TEXT DEFAULT 'created',
                current_version     INTEGER DEFAULT 0,
                approved_by         TEXT,
                rejected_by         TEXT,
                blocked_reason      TEXT,
                paid_at             TEXT,
                decision            TEXT,
                trust_score         REAL DEFAULT 0,
                created_at          TEXT,
                updated_at          TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_status
                ON invoice_read_model(status);

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_contractor
                ON invoice_read_model(contractor_nip);

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_blocked
                ON invoice_read_model(updated_at) WHERE status = 'blocked';

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_approved
                ON invoice_read_model(updated_at) WHERE status = 'approved';

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_pending
                ON invoice_read_model(updated_at) WHERE status IN ('created', 'submitted');

            CREATE INDEX IF NOT EXISTS idx_invoice_rm_contractor_upper
                ON invoice_read_model(UPPER(contractor_nip));

            CREATE VIRTUAL TABLE IF NOT EXISTS invoice_rm_fts
            USING fts5(
                invoice_id UNINDEXED,
                number,
                contractor_nip UNINDEXED,
                contractor_name,
                category,
                status UNINDEXED,
                content='invoice_read_model',
                content_rowid='rowid',
                tokenize='unicode61',
                prefix='2,3'
            );

            CREATE TRIGGER IF NOT EXISTS trg_invoice_rm_fts_insert
            AFTER INSERT ON invoice_read_model
            BEGIN
                INSERT INTO invoice_rm_fts(rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
                VALUES (new.rowid, new.invoice_id, new.number, new.contractor_nip, new.contractor_name, new.category, new.status);
            END;

            CREATE TRIGGER IF NOT EXISTS trg_invoice_rm_fts_delete
            AFTER DELETE ON invoice_read_model
            BEGIN
                INSERT INTO invoice_rm_fts(invoice_rm_fts, rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
                VALUES ('delete', old.rowid, old.invoice_id, old.number, old.contractor_nip, old.contractor_name, old.category, old.status);
            END;

            CREATE TRIGGER IF NOT EXISTS trg_invoice_rm_fts_update
            AFTER UPDATE ON invoice_read_model
            BEGIN
                INSERT INTO invoice_rm_fts(invoice_rm_fts, rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
                VALUES ('delete', old.rowid, old.invoice_id, old.number, old.contractor_nip, old.contractor_name, old.category, old.status);
                INSERT INTO invoice_rm_fts(rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
                VALUES (new.rowid, new.invoice_id, new.number, new.contractor_nip, new.contractor_name, new.category, new.status);
            END;
        """)
        await self.commit()

    async def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        return (
            await self._event_store.read_events_since_version(
                aggregate_type="invoice",
                from_version=checkpoint,
                limit=500,
            )
            if checkpoint >= 0
            else []
        )

    async def _truncate(self) -> None:
        await self.execute("DELETE FROM invoice_read_model")
        await self.commit()
        logger.info("[PROJECTION:%s] Truncated read model", self._name)

    async def _handle_event(self, event: DomainEvent) -> None:
        conn = await self.get_conn()

        def _sync_handle() -> None:
            if isinstance(event, InvoiceCreated):
                conn.execute(
                    """INSERT OR REPLACE INTO invoice_read_model
                       (invoice_id, number, contractor_nip, contractor_name,
                        amount_net, amount_gross, currency, category,
                        issue_date, status, current_version, file_path,
                        created_at, updated_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'created', ?, ?, ?, ?)""",
                    (
                        event.aggregate_id,
                        event.number,
                        event.contractor_nip,
                        event.contractor_name,
                        event.amount_net,
                        event.amount_gross,
                        event.currency,
                        event.category,
                        event.issue_date,
                        event.version,
                        event.file_path,
                        event.timestamp,
                        event.timestamp,
                    ),
                )

            elif isinstance(event, InvoiceSubmitted):
                conn.execute(
                    """UPDATE invoice_read_model
                       SET status = 'submitted', current_version = ?, updated_at = ?
                       WHERE invoice_id = ?""",
                    (event.version, event.timestamp, event.aggregate_id),
                )

            elif isinstance(event, InvoiceApproved):
                conn.execute(
                    """UPDATE invoice_read_model
                       SET status = 'approved', approved_by = ?,
                           trust_score = ?, current_version = ?, updated_at = ?
                       WHERE invoice_id = ?""",
                    (
                        event.approved_by,
                        event.trust_score,
                        event.version,
                        event.timestamp,
                        event.aggregate_id,
                    ),
                )

            elif isinstance(event, InvoiceRejected):
                conn.execute(
                    """UPDATE invoice_read_model
                       SET status = 'rejected', rejected_by = ?,
                           current_version = ?, updated_at = ?
                       WHERE invoice_id = ?""",
                    (event.rejected_by, event.version, event.timestamp, event.aggregate_id),
                )

            elif isinstance(event, InvoiceBlocked):
                conn.execute(
                    """UPDATE invoice_read_model
                       SET status = 'blocked', blocked_reason = ?,
                           current_version = ?, updated_at = ?
                       WHERE invoice_id = ?""",
                    (event.reason, event.version, event.timestamp, event.aggregate_id),
                )

            elif isinstance(event, InvoicePaid):
                conn.execute(
                    """UPDATE invoice_read_model
                       SET status = 'paid', paid_at = ?,
                           current_version = ?, updated_at = ?
                       WHERE invoice_id = ?""",
                (event.paid_at, event.version, event.timestamp, event.aggregate_id),
                )

            conn.commit()

        await asyncio.to_thread(_sync_handle)

    async def query(
        self,
        status: str | None = None,
        contractor_nip: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Zapytaj widok faktur (async)."""
        sql = "SELECT * FROM invoice_read_model WHERE 1=1"
        params: list[Any] = []

        if status:
            sql += " AND status = ?"
            params.append(status)
        if contractor_nip:
            sql += " AND contractor_nip = ?"
            params.append(contractor_nip)

        sql += " ORDER BY updated_at DESC LIMIT ?"
        params.append(limit)

        return await self.fetchall(sql, params)

    async def get_by_id(self, invoice_id: str) -> dict[str, Any] | None:
        """Pobierz fakturę po ID (async)."""
        return await self.fetchone(
            "SELECT * FROM invoice_read_model WHERE invoice_id = ?",
            (invoice_id,),
        )

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki widoku faktur (async)."""
        conn = await self.get_conn()
        def _sync() -> dict[str, Any]:
            cursor = conn.execute(
                "SELECT status, COUNT(*) as cnt FROM invoice_read_model GROUP BY status"
            )
            rows = cursor.fetchall()
            total_cursor = conn.execute("SELECT COUNT(*) FROM invoice_read_model")
            total_row = total_cursor.fetchone()
            return {
                "total": int(total_row[0]) if total_row else 0,
                "by_status": {str(r[0]): int(r[1]) for r in rows},
            }
        return await asyncio.to_thread(_sync)


# ── Decision Projection (async) ──────────────────────────────────────────


class AsyncDecisionProjection(AsyncProjection, AsyncBaseService):
    """Async projekcja decyzji — analityczny widok dla DuckDB."""

    def __init__(
        self,
        event_store: AsyncEventStore,
        db_path: str | Path | None = None,
    ) -> None:
        AsyncProjection.__init__(self, event_store, name="decision_projection")
        db_path = db_path or Path("app_data/projections/decisions.db")
        AsyncBaseService.__init__(self, db_path)
        Path(str(db_path)).parent.mkdir(parents=True, exist_ok=True)

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook: PRAGMY + schema creation dla projekcji decyzji."""
        def _sync() -> None:
            conn.execute("PRAGMA cache_size = -25600;")
            conn.execute("PRAGMA temp_store = MEMORY;")
            conn.execute("PRAGMA mmap_size = 2147483648;")
        await asyncio.to_thread(_sync)
        await self._ensure_schema()

    async def _ensure_schema(self) -> None:
        await self.executescript("""
            CREATE TABLE IF NOT EXISTS decision_analytics (
                decision_id         TEXT PRIMARY KEY,
                invoice_id          TEXT NOT NULL,
                event_type          TEXT NOT NULL,
                decision            TEXT,
                trust_score         REAL DEFAULT 0,
                ai_confidence       REAL DEFAULT 0,
                alpha_vote          TEXT,
                beta_vote           TEXT,
                gamma_vote          TEXT,
                decision_pattern    TEXT,
                reasoning           TEXT,
                original_decision   TEXT,
                user_decision       TEXT,
                user_id             TEXT,
                version             INTEGER DEFAULT 0,
                timestamp           TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_decision_analytics_invoice
                ON decision_analytics(invoice_id);

            CREATE INDEX IF NOT EXISTS idx_decision_analytics_type
                ON decision_analytics(event_type);

            CREATE INDEX IF NOT EXISTS idx_decision_analytics_decision_notnull
                ON decision_analytics(timestamp) WHERE decision IS NOT NULL;

            CREATE INDEX IF NOT EXISTS idx_decision_analytics_overridden
                ON decision_analytics(timestamp) WHERE event_type = 'decision.overridden';
        """)
        await self.commit()

    async def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        return (
            await self._event_store.read_events_since_version(
                aggregate_type="decision",
                from_version=checkpoint,
                limit=500,
            )
            if checkpoint >= 0
            else []
        )

    async def _truncate(self) -> None:
        await self.execute("DELETE FROM decision_analytics")
        await self.commit()
        logger.info("[PROJECTION:%s] Truncated analytics", self._name)

    async def _handle_event(self, event: DomainEvent) -> None:
        conn = await self.get_conn()

        def _sync_handle() -> None:
            if isinstance(event, DecisionMade):
                conn.execute(
                    """INSERT OR REPLACE INTO decision_analytics
                       (decision_id, invoice_id, event_type, decision,
                        trust_score, ai_confidence, alpha_vote, beta_vote,
                        gamma_vote, decision_pattern, reasoning,
                        version, timestamp)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        event.event_id,
                        event.invoice_id,
                        event.event_type,
                        event.decision,
                        event.trust_score,
                        event.ai_confidence,
                        event.alpha_vote,
                        event.beta_vote,
                        event.gamma_vote,
                        event.decision_pattern,
                        event.reasoning,
                        event.version,
                        event.timestamp,
                    ),
                )

            elif isinstance(event, DecisionOverridden):
                conn.execute(
                    """INSERT OR REPLACE INTO decision_analytics
                       (decision_id, invoice_id, event_type,
                        original_decision, user_decision, user_id,
                        version, timestamp)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        event.event_id,
                        event.invoice_id,
                        event.event_type,
                        event.original_decision,
                        event.user_decision,
                        event.user_id,
                        event.version,
                        event.timestamp,
                    ),
                )

            conn.commit()

        await asyncio.to_thread(_sync_handle)

    async def query(
        self,
        decision_type: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Zapytaj widok decyzji (async)."""
        sql = "SELECT * FROM decision_analytics WHERE 1=1"
        params: list[Any] = []

        if decision_type:
            sql += " AND event_type = ?"
            params.append(decision_type)

        sql += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)

        return await self.fetchall(sql, params)

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki decyzji (async)."""
        conn = await self.get_conn()
        def _sync() -> dict[str, Any]:
            cursor = conn.execute(
                "SELECT decision, COUNT(*) as cnt FROM decision_analytics "
                "WHERE decision IS NOT NULL GROUP BY decision"
            )
            rows = cursor.fetchall()
            total_cursor = conn.execute("SELECT COUNT(*) FROM decision_analytics")
            total_row = total_cursor.fetchone()
            return {
                "total": int(total_row[0]) if total_row else 0,
                "by_decision": {str(r[0]): int(r[1]) for r in rows},
            }
        return await asyncio.to_thread(_sync)


# ── Aliases dla kompatybilności wstecznej ────────────────────────────────
Projection = AsyncProjection
InvoiceProjection = AsyncInvoiceProjection
DecisionProjection = AsyncDecisionProjection
