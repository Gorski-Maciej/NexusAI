"""
AsyncProjections -- CQRS read-side z BaseProjection[T] generic + match/case.

Python 3.13t (free-threaded): sqlite3 + anyio.to_thread.run_sync.

Używa BaseProjection[T] jako generycznej klasy bazowej -- każda projekcja
definiuje tylko: schema_sql, aggregate_type, event_handler.
Reszta (checkpointy, paginacja, PRAGMY, FTS5) jest współdzielona.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any, ClassVar, TypeVar

import anyio
from structlog import get_logger

from nexus_ai.db.async_base_service import AsyncBaseService
from nexus_ai.events.domain_events import (
    DecisionMade,
    DecisionOverridden,
    DomainEvent,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
)
from nexus_ai.events.event_store import AsyncEventStore

logger = get_logger("nexus.events.projections")

T = TypeVar("T", bound=DomainEvent)


class BaseProjection[T: DomainEvent](AsyncBaseService):
    """Generyczna projekcja CQRS -- współdzielona logika dla wszystkich widoków.

    Każda konkretna projekcja definiuje tylko:
      - schema_sql: DDL dla tabeli widoku
      - aggregate_type: typ agregatu w EventStore
      - _apply_event(): logika mapowania event -> SQL

    Współdzielone: checkpointy, PRAGMY, FTS5, paginacja, truncate, stats.
    """

    schema_sql: ClassVar[str] = ""
    aggregate_type: ClassVar[str] = ""
    pragma_config: ClassVar[tuple[str, ...]] = (
        "cache_size = -25600",
        "temp_store = MEMORY",
        "mmap_size = 2147483648",
    )

    def __init__(
        self,
        event_store: AsyncEventStore,
        db_path: str | Path | None = None,
        *,
        projection_name: str | None = None,
    ) -> None:
        name = projection_name or f"{self.aggregate_type}_projection"
        default_path = Path(f"app_data/projections/{name}.db")
        AsyncBaseService.__init__(self, db_path or default_path)
        self._event_store = event_store
        self._name = name
        Path(str(self._db_path)).parent.mkdir(parents=True, exist_ok=True)

    @property
    def name(self) -> str:
        return self._name

    # ── Lifecycle ──────────────────────────────────────────────────────

    async def rebuild(self) -> int:
        await self._truncate()
        await self._event_store.update_checkpoint(self._name, "", 0)
        return await self.process()

    async def process(self) -> int:
        checkpoint = await self._event_store.get_checkpoint(self._name)
        from_version = max(checkpoint, 0)
        processed = 0
        for event in await self._fetch_events(from_version):
            try:
                await self._apply_event(event)
                await self.commit()
                processed += 1
                await self._event_store.update_checkpoint(self._name, event.event_id, event.version)
            except Exception as exc:
                logger.error("[PROJECTION:%s] Failed event %s: %s", self._name, event.event_id, exc)
        if processed:
            logger.info("[PROJECTION:%s] Processed %d events", self._name, processed)
        return processed

    # ── Hooks ──────────────────────────────────────────────────────────

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        def _set_pragmas():
            for pragma in self.pragma_config:
                conn.execute(f"PRAGMA {pragma}")

        await anyio.to_thread.run_sync(_set_pragmas)
        await self._ensure_schema()

    async def _ensure_schema(self) -> None:
        if self.schema_sql:
            await self.executescript(self.schema_sql)
            await self.commit()

    async def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        return (
            await self._event_store.read_events_since_version(
                aggregate_type=self.aggregate_type,
                from_version=checkpoint,
                limit=500,
            )
            if checkpoint >= 0
            else []
        )

    async def _truncate(self) -> None:
        raise NotImplementedError

    async def _apply_event(self, event: DomainEvent) -> None:
        """Aplikuje pojedynczy event na widok. Nadpisz w podklasie z match/case."""
        raise NotImplementedError

    # ── Queries ────────────────────────────────────────────────────────

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki widoku. Nadpisz w podklasie dla specyficznych agregacji."""
        return {"total": 0}


class InvoiceProjection(BaseProjection[InvoiceCreated]):
    """Projekcja faktur -- denormalizowany widok dla szybkich zapytań."""

    aggregate_type = "invoice"
    schema_sql = """
        CREATE TABLE IF NOT EXISTS invoice_read_model (
            invoice_id          TEXT PRIMARY KEY,
            number              TEXT, contractor_nip      TEXT, contractor_name     TEXT,
            amount_net          REAL DEFAULT 0, amount_gross        REAL DEFAULT 0,
            currency            TEXT DEFAULT 'PLN', category            TEXT, issue_date TEXT,
            file_path           TEXT, status TEXT DEFAULT 'created', current_version INTEGER DEFAULT 0,
            approved_by         TEXT, rejected_by TEXT, blocked_reason TEXT, paid_at TEXT,
            decision TEXT, trust_score REAL DEFAULT 0, created_at TEXT, updated_at TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_irm_status ON invoice_read_model(status);
        CREATE INDEX IF NOT EXISTS idx_irm_contractor ON invoice_read_model(contractor_nip);
        CREATE INDEX IF NOT EXISTS idx_irm_blocked ON invoice_read_model(updated_at) WHERE status = 'blocked';
        CREATE INDEX IF NOT EXISTS idx_irm_approved ON invoice_read_model(updated_at) WHERE status = 'approved';
        CREATE INDEX IF NOT EXISTS idx_irm_pending ON invoice_read_model(updated_at) WHERE status IN ('created', 'submitted');
        CREATE INDEX IF NOT EXISTS idx_irm_contractor_upper ON invoice_read_model(UPPER(contractor_nip));
        CREATE VIRTUAL TABLE IF NOT EXISTS invoice_rm_fts USING fts5(
            invoice_id UNINDEXED, number, contractor_nip UNINDEXED, contractor_name, category, status UNINDEXED,
            content='invoice_read_model', content_rowid='rowid', tokenize='unicode61', prefix='2,3'
        );
        CREATE TRIGGER IF NOT EXISTS trg_irm_fts_insert AFTER INSERT ON invoice_read_model BEGIN
            INSERT INTO invoice_rm_fts VALUES (new.rowid, new.invoice_id, new.number, new.contractor_nip, new.contractor_name, new.category, new.status);
        END;
        CREATE TRIGGER IF NOT EXISTS trg_irm_fts_delete AFTER DELETE ON invoice_read_model BEGIN
            INSERT INTO invoice_rm_fts(invoice_rm_fts, rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
            VALUES ('delete', old.rowid, old.invoice_id, old.number, old.contractor_nip, old.contractor_name, old.category, old.status);
        END;
        CREATE TRIGGER IF NOT EXISTS trg_irm_fts_update AFTER UPDATE ON invoice_read_model BEGIN
            INSERT INTO invoice_rm_fts(invoice_rm_fts, rowid, invoice_id, number, contractor_nip, contractor_name, category, status)
            VALUES ('delete', old.rowid, old.invoice_id, old.number, old.contractor_nip, old.contractor_name, old.category, old.status);
            INSERT INTO invoice_rm_fts VALUES (new.rowid, new.invoice_id, new.number, new.contractor_nip, new.contractor_name, new.category, new.status);
        END;
    """

    async def _truncate(self) -> None:
        await self.execute("DELETE FROM invoice_read_model")
        await self.commit()

    async def _apply_event(self, event: DomainEvent) -> None:
        match event:
            case InvoiceCreated():
                await self.execute(
                    """INSERT OR REPLACE INTO invoice_read_model
                       (invoice_id, number, contractor_nip, contractor_name,
                        amount_net, amount_gross, currency, category,
                        issue_date, file_path, status, current_version,
                        created_at, updated_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'created', ?, ?, ?)""",
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
                        event.file_path,
                        event.version,
                        event.timestamp,
                        event.timestamp,
                    ),
                )
            case InvoiceSubmitted():
                await self.execute(
                    "UPDATE invoice_read_model SET status='submitted', current_version=?, updated_at=? WHERE invoice_id=?",
                    (event.version, event.timestamp, event.aggregate_id),
                )
            case InvoiceApproved():
                await self.execute(
                    "UPDATE invoice_read_model SET status='approved', approved_by=?, trust_score=?, current_version=?, updated_at=? WHERE invoice_id=?",
                    (
                        event.approved_by,
                        event.trust_score,
                        event.version,
                        event.timestamp,
                        event.aggregate_id,
                    ),
                )
            case InvoiceRejected():
                await self.execute(
                    "UPDATE invoice_read_model SET status='rejected', rejected_by=?, current_version=?, updated_at=? WHERE invoice_id=?",
                    (event.rejected_by, event.version, event.timestamp, event.aggregate_id),
                )
            case InvoiceBlocked():
                await self.execute(
                    "UPDATE invoice_read_model SET status='blocked', blocked_reason=?, current_version=?, updated_at=? WHERE invoice_id=?",
                    (event.reason, event.version, event.timestamp, event.aggregate_id),
                )
            case InvoicePaid():
                await self.execute(
                    "UPDATE invoice_read_model SET status='paid', paid_at=?, current_version=?, updated_at=? WHERE invoice_id=?",
                    (event.paid_at, event.version, event.timestamp, event.aggregate_id),
                )

    async def query(
        self, status: str | None = None, contractor_nip: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        sql = "SELECT * FROM invoice_read_model WHERE 1=1"
        params: list[Any] = []
        if status:
            sql += " AND status = ?"
            params.append(status)
        if contractor_nip:
            sql += " AND contractor_nip = ?"
            params.append(contractor_nip)
        return await self.fetchall(sql + " ORDER BY updated_at DESC LIMIT ?", [*params, limit])

    async def get_by_id(self, invoice_id: str) -> dict[str, Any] | None:
        return await self.fetchone(
            "SELECT * FROM invoice_read_model WHERE invoice_id = ?", (invoice_id,)
        )


class DecisionProjection(BaseProjection[DecisionMade]):
    """Projekcja decyzji -- analityczny widok."""

    aggregate_type = "decision"
    schema_sql = """
        CREATE TABLE IF NOT EXISTS decision_analytics (
            decision_id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, event_type TEXT NOT NULL,
            decision TEXT, trust_score REAL DEFAULT 0, ai_confidence REAL DEFAULT 0,
            alpha_vote TEXT, beta_vote TEXT, gamma_vote TEXT, decision_pattern TEXT,
            reasoning TEXT, original_decision TEXT, user_decision TEXT, user_id TEXT,
            version INTEGER DEFAULT 0, timestamp TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_da_invoice ON decision_analytics(invoice_id);
        CREATE INDEX IF NOT EXISTS idx_da_type ON decision_analytics(event_type);
        CREATE INDEX IF NOT EXISTS idx_da_decision ON decision_analytics(timestamp) WHERE decision IS NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_da_overridden ON decision_analytics(timestamp) WHERE event_type = 'decision.overridden';
    """

    async def _truncate(self) -> None:
        await self.execute("DELETE FROM decision_analytics")
        await self.commit()

    async def _apply_event(self, event: DomainEvent) -> None:
        match event:
            case DecisionMade():
                await self.execute(
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
            case DecisionOverridden():
                await self.execute(
                    "INSERT OR REPLACE INTO decision_analytics (decision_id, invoice_id, event_type, original_decision, user_decision, user_id, version, timestamp) VALUES (?,?,?,?,?,?,?,?)",
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

    async def query(
        self, decision_type: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        sql = "SELECT * FROM decision_analytics WHERE 1=1"
        params: list[Any] = []
        if decision_type:
            sql += " AND event_type = ?"
            params.append(decision_type)
        return await self.fetchall(sql + " ORDER BY timestamp DESC LIMIT ?", [*params, limit])



# ── Query builder helper ────────────────────────────────────────────────

def _query_builder(params: dict[str, Any], base_sql: str = "WHERE 1=1", order: str = "updated_at DESC") -> tuple[str, list[Any]]:
    """Generyczny builder WHERE dla zapytań projekcji."""
    clauses: list[str] = []
    values: list[Any] = []
    for key, value in params.items():
        if value is not None:
            clauses.append(f"{key} = ?")
            values.append(value)
    where = " AND ".join(clauses) if clauses else "1=1"
    return f"SELECT * FROM {base_sql} WHERE {where} ORDER BY {order}", values

