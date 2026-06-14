"""
Projections — CQRS read-side that rebuilds denormalized views from event streams.

Każda projekcja:
  1. Czyta eventy z EventStore (od ostatniego checkpointu)
  2. Aktualizuje denormalizowany widok (SQLite / DuckDB)
  3. Zapisuje checkpoint po przetworzeniu

Projekcje mogą być odtwarzane od początku (rebuilt) przez ustawienie
checkpointu na 0.
"""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

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
from nexus_ai.events.event_store import EventStore

logger = get_logger("nexus.events.projections")


# ── Projection base class ────────────────────────────────────────────────


class Projection:
    """Bazowa klasa dla projekcji CQRS.

    Args:
        event_store: EventStore do odczytu eventów.
        name: Nazwa projekcji (używana jako klucz checkpointu).
    """

    def __init__(self, event_store: EventStore, name: str) -> None:
        self._event_store = event_store
        self._name = name

    @property
    def name(self) -> str:
        return self._name

    async def rebuild(self) -> int:
        """Odtwórz projekcję od początku.

        Czyści tabelę, resetuje checkpoint i przetwarza wszystkie eventy od wersji 0.

        Returns:
            Liczba przetworzonych eventów.
        """
        self._truncate()
        self._event_store.update_checkpoint(self._name, "", 0)
        return await self.process()

    def _truncate(self) -> None:
        """Wyczyść tabelę projekcji (przed rebuildem)."""
        raise NotImplementedError

    async def process(self) -> int:
        """Przetwórz nowe eventy od ostatniego checkpointu.

        Checkpoint przechowuje wersję ostatniego przetworzonego eventu.
        Przy kolejnym wywołaniu pomijamy tę wersję (``from_version + 1``),
        aby nie przetwarzać tego samego eventu dwukrotnie.
        Dzięki idempotentnym INSERT OR REPLACE podwójne przetworzenie
        nie psuje danych, ale jest niepotrzebnym narzutem.

        Returns:
            Liczba przetworzonych eventów.
        """
        checkpoint = self._event_store.get_checkpoint(self._name)
        from_version = checkpoint + 1 if checkpoint > 0 else 0
        processed = 0

        events = self._fetch_events(from_version)
        for event in events:
            try:
                await self._handle_event(event)
                processed += 1
                self._event_store.update_checkpoint(
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
                self._event_store.get_checkpoint(self._name),
            )

        return processed

    def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        """Pobierz eventy od checkpointu."""
        # Domyślnie pobiera wszystkie eventy typu invoice.*
        # Nadpisz w konkretnej projekcji dla optymalizacji
        raise NotImplementedError

    async def _handle_event(self, event: DomainEvent) -> None:
        """Przetwórz pojedynczy event."""
        raise NotImplementedError


# ── Invoice Projection ────────────────────────────────────────────────────


class InvoiceProjection(Projection):
    """Projekcja faktur — denormalizowany widok dla szybkich zapytań.

    Tworzy i utrzymuje tabelę ``invoice_read_model`` w SQLite z bieżącym
    stanem każdej faktury, odtworzonym ze strumienia eventów.
    """

    def __init__(
        self,
        event_store: EventStore,
        db_path: str | Path | None = None,
    ) -> None:
        super().__init__(event_store, name="invoice_projection")
        self._db_path = Path(db_path) if db_path else Path("app_data/projections/invoices.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn: sqlite3.Connection | None = None
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        conn = self._get_conn()
        conn.executescript("""
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
        """)
        conn.commit()

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute("PRAGMA synchronous=NORMAL")
            self._conn.execute("PRAGMA cache_size = -25600")    # 100MB cache
            self._conn.execute("PRAGMA temp_store = MEMORY")    # Temp tables w RAM
            self._conn.execute("PRAGMA mmap_size = 2147483648") # 2GB mmap
        return self._conn

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.execute("PRAGMA optimize")  # SUPERMOC: optimize przed close
            except Exception:
                pass
            self._conn.close()
            self._conn = None

    def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        # Pobierz wszystkie eventy typu invoice od checkpointu
        return (
            self._event_store.read_events_since_version(
                aggregate_type="invoice",
                from_version=checkpoint,
                limit=500,
            )
            if checkpoint >= 0
            else []
        )

    def _truncate(self) -> None:
        conn = self._get_conn()
        conn.execute("DELETE FROM invoice_read_model")
        conn.commit()
        logger.info("[PROJECTION:%s] Truncated read model", self._name)

    async def _handle_event(self, event: DomainEvent) -> None:
        conn = self._get_conn()

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

    def query(
        self,
        status: str | None = None,
        contractor_nip: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Zapytaj widok faktur.

        Args:
            status: Filtr po statusie (np. "approved", "blocked").
            contractor_nip: Filtr po NIP kontrahenta.
            limit: Maksymalna liczba wyników.

        Returns:
            Lista faktur.
        """
        conn = self._get_conn()
        query = "SELECT * FROM invoice_read_model WHERE 1=1"
        params: list[Any] = []

        if status:
            query += " AND status = ?"
            params.append(status)
        if contractor_nip:
            query += " AND contractor_nip = ?"
            params.append(contractor_nip)

        query += " ORDER BY updated_at DESC LIMIT ?"
        params.append(limit)

        rows = conn.execute(query, params).fetchall()
        return [dict(r) for r in rows]

    def get_by_id(self, invoice_id: str) -> dict[str, Any] | None:
        """Pobierz fakturę po ID.

        Args:
            invoice_id: ID faktury.

        Returns:
            Słownik z danymi faktury lub None.
        """
        conn = self._get_conn()
        row = conn.execute(
            "SELECT * FROM invoice_read_model WHERE invoice_id = ?",
            (invoice_id,),
        ).fetchone()
        return dict(row) if row else None

    def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki widoku faktur.

        Returns:
            Słownik z liczbą faktur per status.
        """
        conn = self._get_conn()
        rows = conn.execute(
            "SELECT status, COUNT(*) as cnt FROM invoice_read_model GROUP BY status"
        ).fetchall()
        total = conn.execute("SELECT COUNT(*) FROM invoice_read_model").fetchone()[0]
        return {
            "total": int(total),
            "by_status": {r["status"]: int(r["cnt"]) for r in rows},
        }


# ── Decision Projection ───────────────────────────────────────────────────


class DecisionProjection(Projection):
    """Projekcja decyzji — analityczny widok decyzji dla DuckDB.

    Utrzymuje tabelę ``decision_analytics`` z denormalizowanymi danymi
    o każdej podjętej decyzji, gotową do zapytań OLAP.
    """

    def __init__(
        self,
        event_store: EventStore,
        db_path: str | Path | None = None,
    ) -> None:
        super().__init__(event_store, name="decision_projection")
        self._db_path = Path(db_path) if db_path else Path("app_data/projections/decisions.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn: sqlite3.Connection | None = None
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        conn = self._get_conn()
        conn.executescript("""
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
        """)
        conn.commit()

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute("PRAGMA synchronous=NORMAL")
            self._conn.execute("PRAGMA cache_size = -25600")
            self._conn.execute("PRAGMA temp_store = MEMORY")
            self._conn.execute("PRAGMA mmap_size = 2147483648")
        return self._conn

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.execute("PRAGMA optimize")
            except Exception:
                pass
            self._conn.close()
            self._conn = None

    def _fetch_events(self, checkpoint: int) -> list[DomainEvent]:
        return (
            self._event_store.read_events_since_version(
                aggregate_type="decision",
                from_version=checkpoint,
                limit=500,
            )
            if checkpoint >= 0
            else []
        )

    def _truncate(self) -> None:
        conn = self._get_conn()
        conn.execute("DELETE FROM decision_analytics")
        conn.commit()
        logger.info("[PROJECTION:%s] Truncated analytics", self._name)

    async def _handle_event(self, event: DomainEvent) -> None:
        conn = self._get_conn()

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

    def query(
        self,
        decision_type: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Zapytaj widok decyzji.

        Args:
            decision_type: "decision.made" lub "decision.overridden".
            limit: Maksymalna liczba wyników.

        Returns:
            Lista decyzji.
        """
        conn = self._get_conn()
        query = "SELECT * FROM decision_analytics WHERE 1=1"
        params: list[Any] = []

        if decision_type:
            query += " AND event_type = ?"
            params.append(decision_type)

        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)

        rows = conn.execute(query, params).fetchall()
        return [dict(r) for r in rows]

    def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki decyzji.

        Returns:
            Słownik z rozkładem decyzji.
        """
        conn = self._get_conn()
        by_decision = conn.execute(
            "SELECT decision, COUNT(*) as cnt FROM decision_analytics "
            "WHERE decision IS NOT NULL GROUP BY decision"
        ).fetchall()
        total = conn.execute("SELECT COUNT(*) FROM decision_analytics").fetchone()[0]
        return {
            "total": int(total),
            "by_decision": {r["decision"]: int(r["cnt"]) for r in by_decision},
        }
