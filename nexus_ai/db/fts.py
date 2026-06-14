"""
FTS5 Full-Text Search — natywne wyszukiwanie pełnotekstowe SQLite.

SUPERMOC: SQLite FTS5 (Full-Text Search v5) — wbudowany silnik wyszukiwania
z tokenizerem, stemmingiem, rankingiem BM25 i wsparciem dla języków.

Zgodnie z aa3fvcx.txt: zastępuje zewnętrzne silniki wyszukiwania natywnym
FTS5 SQLite — zero dodatkowych zależności.

Tokenizery:
- ``unicode61`` — domyślny, wspiera Unicode, usuwa diakrytyki
- ``trigram`` — wspiera polskie znaki, odporne na literówki
  (używany przez nexus_ai/api/routes/search.py)

Usage:
    from nexus_ai.db.fts import FTSManager

    fts = FTSManager(db_path=\"app_data/databases/nexus_oltp.db\")
    fts.ensure_fts_tables()

    # Szukaj faktur
    results = fts.search_invoices(\"faktura VAT marzec\", limit=10)

    # Szukaj kontrahentów
    results = fts.search_contractors(\"Kowalski\", limit=5)

    # Indeksuj pojedynczą fakturę
    fts.index_invoice(invoice_id=\"...\", number=\"FV/2026/001\",
                      contractor_name=\"Jan Kowalski\", status=\"PAID\")

    # Synchronizacja z tabelą invoices (trigger-based)
    fts.create_triggers()
"""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.fts")


class FTSManager:
    """Zarządza FTS5 tabelami dla wyszukiwania pełnotekstowego.

    Używa tokenizera ``trigram`` dla odpornego na literówki wyszukiwania
    („Kowalski" znajdzie nawet przy wpisaniu „Kowalskii" lub „Kowalksi").

    Tabele FTS5:
    - ``invoices_fts``: numer faktury, nazwa kontrahenta, status, kategoria
    - ``contractors_fts``: NIP, nazwa, adres
    - ``audit_logs_fts``: akcja, user_id, szczegóły
    - ``events_fts``: typ eventu, aggregate_id, metadane
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._conn: sqlite3.Connection | None = None

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute("PRAGMA synchronous=NORMAL")
        return self._conn

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.execute("PRAGMA optimize")
            except Exception:
                pass
            self._conn.close()
            self._conn = None

    # ── Schema ─────────────────────────────────────────────────────────

    FTS_INVOICES_SCHEMA = """
        CREATE VIRTUAL TABLE IF NOT EXISTS invoices_fts
        USING fts5(
            invoice_id UNINDEXED,
            number,
            contractor_nip UNINDEXED,
            contractor_name,
            amount_net UNINDEXED,
            amount_gross UNINDEXED,
            currency UNINDEXED,
            status,
            category,
            content='',
            tokenize='trigram'
        );
    """

    FTS_CONTRACTORS_SCHEMA = """
        CREATE VIRTUAL TABLE IF NOT EXISTS contractors_fts
        USING fts5(
            contractor_id UNINDEXED,
            nip UNINDEXED,
            name,
            address,
            vat_status UNINDEXED,
            content='',
            tokenize='trigram'
        );
    """

    FTS_AUDIT_LOGS_SCHEMA = """
        CREATE VIRTUAL TABLE IF NOT EXISTS audit_logs_fts
        USING fts5(
            log_id UNINDEXED,
            action,
            user_id UNINDEXED,
            field_changed,
            old_value,
            new_value,
            invoice_id UNINDEXED,
            content='',
            tokenize='unicode61'
        );
    """

    FTS_EVENTS_SCHEMA = """
        CREATE VIRTUAL TABLE IF NOT EXISTS events_fts
        USING fts5(
            event_id UNINDEXED,
            aggregate_type UNINDEXED,
            aggregate_id UNINDEXED,
            event_type,
            metadata_json,
            content='',
            tokenize='unicode61'
        );
    """

    def ensure_fts_tables(self) -> None:
        """Utwórz wszystkie tabele FTS5 jeśli nie istnieją."""
        conn = self._get_conn()
        for schema in [
            self.FTS_INVOICES_SCHEMA,
            self.FTS_CONTRACTORS_SCHEMA,
            self.FTS_AUDIT_LOGS_SCHEMA,
            self.FTS_EVENTS_SCHEMA,
        ]:
            conn.execute(schema)
        conn.commit()
        logger.info("[FTS] All FTS5 tables ensured")

    # ── Indexing methods ───────────────────────────────────────────────

    def index_invoice(
        self,
        invoice_id: str,
        number: str = "",
        contractor_nip: str = "",
        contractor_name: str = "",
        amount_net: float = 0.0,
        amount_gross: float = 0.0,
        currency: str = "PLN",
        status: str = "",
        category: str = "",
    ) -> None:
        """Indeksuj pojedynczą fakturę (DELETE + INSERT dla idempotentności).

        Używamy DELETE + INSERT zamiast INSERT OR REPLACE z subquery na rowid,
        ponieważ FTS5 nie akceptuje NULL rowid — a SELECT rowid z subquery
        zwróci NULL gdy wiersz nie istnieje (pierwsze indeksowanie).
        """
        conn = self._get_conn()
        conn.execute("DELETE FROM invoices_fts WHERE invoice_id = ?", (invoice_id,))
        conn.execute(
            """INSERT INTO invoices_fts(
                   invoice_id, number, contractor_nip, contractor_name,
                   amount_net, amount_gross, currency, status, category
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                invoice_id,
                number or "",
                contractor_nip or "",
                contractor_name or "",
                str(amount_net),
                str(amount_gross),
                currency,
                status or "",
                category or "",
            ),
        )
        conn.commit()

    def index_contractor(
        self,
        contractor_id: str,
        nip: str = "",
        name: str = "",
        address: str = "",
        vat_status: str = "",
    ) -> None:
        """Indeksuj pojedynczego kontrahenta (DELETE + INSERT)."""
        conn = self._get_conn()
        conn.execute("DELETE FROM contractors_fts WHERE contractor_id = ?", (contractor_id,))
        conn.execute(
            """INSERT INTO contractors_fts(
                   contractor_id, nip, name, address, vat_status
               ) VALUES (?, ?, ?, ?, ?)""",
            (contractor_id, nip, name, address, vat_status),
        )
        conn.commit()

    # ── Search methods ─────────────────────────────────────────────────

    def search_invoices(
        self,
        query: str,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """SZUKAJ faktur przez FTS5 z rankingiem BM25.

        Args:
            query: Zapytanie (obsługuje składnię FTS5, np. ``VAT AND marzec``).
            limit: Maksymalna liczba wyników.
            offset: Pominięcie dla paginacji.

        Returns:
            Lista pasujących faktur z rankingiem BM25.
        """
        if not query.strip():
            return []

        conn = self._get_conn()
        try:
            rows = conn.execute(
                """SELECT i.*, fts.rank
                   FROM invoices_fts fts
                   JOIN invoices i ON i.id = fts.invoice_id
                   WHERE invoices_fts MATCH ?
                   ORDER BY fts.rank
                   LIMIT ? OFFSET ?""",
                (query, limit, offset),
            ).fetchall()
            return [dict(r) for r in rows]
        except sqlite3.OperationalError as exc:
            logger.warning("[FTS] Search query failed: %s — query=%r", exc, query)
            return []

    def search_contractors(
        self,
        query: str,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """SZUKAJ kontrahentów przez FTS5."""
        if not query.strip():
            return []

        conn = self._get_conn()
        try:
            rows = conn.execute(
                """SELECT c.*, fts.rank
                   FROM contractors_fts fts
                   JOIN contractors c ON c.id = fts.contractor_id
                   WHERE contractors_fts MATCH ?
                   ORDER BY fts.rank
                   LIMIT ?""",
                (query, limit),
            ).fetchall()
            return [dict(r) for r in rows]
        except sqlite3.OperationalError as exc:
            logger.warning("[FTS] Contractor search failed: %s — query=%r", exc, query)
            return []

    def search_events(
        self,
        query: str,
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        """SZUKAJ eventów przez FTS5."""
        if not query.strip():
            return []

        conn = self._get_conn()
        try:
            rows = conn.execute(
                """SELECT fts.*, fts.rank
                   FROM events_fts fts
                   WHERE events_fts MATCH ?
                   ORDER BY fts.rank
                   LIMIT ?""",
                (query, limit),
            ).fetchall()
            return [dict(r) for r in rows]
        except sqlite3.OperationalError as exc:
            logger.warning("[FTS] Event search failed: %s — query=%r", exc, query)
            return []

    def search_all(
        self,
        query: str,
        limit_per_type: int = 5,
    ) -> dict[str, list[dict[str, Any]]]:
        """SZUKAJ we wszystkich tabelach FTS5 jednocześnie.

        Args:
            query: Zapytanie.
            limit_per_type: Maksymalna liczba wyników na typ.

        Returns:
            Słownik z wynikami per typ: invoices, contractors, events.
        """
        return {
            "invoices": self.search_invoices(query, limit=limit_per_type),
            "contractors": self.search_contractors(query, limit=limit_per_type),
            "events": self.search_events(query, limit=limit_per_type),
        }

    def delete_invoice(self, invoice_id: str) -> None:
        """Usuń fakturę z indeksu FTS5."""
        conn = self._get_conn()
        conn.execute(
            "DELETE FROM invoices_fts WHERE invoice_id = ?",
            (invoice_id,),
        )
        conn.commit()

    def rebuild_index(self) -> None:
        """Przebuduj wszystkie indeksy FTS5 (po pełnym reseed)."""
        conn = self._get_conn()
        conn.execute("INSERT INTO invoices_fts(invoices_fts) VALUES('rebuild')")
        conn.execute("INSERT INTO contractors_fts(contractors_fts) VALUES('rebuild')")
        conn.execute("INSERT INTO audit_logs_fts(audit_logs_fts) VALUES('rebuild')")
        conn.execute("INSERT INTO events_fts(events_fts) VALUES('rebuild')")
        conn.commit()
        logger.info("[FTS] All indexes rebuilt")


# ── Global singleton ──────────────────────────────────────────────────────

_default_fts: FTSManager | None = None


def get_fts_manager(db_path: str | Path | None = None) -> FTSManager:
    """Zwraca globalną instancję FTSManager."""
    global _default_fts
    if _default_fts is None:
        if db_path is None:
            from nexus_ai.core.config import AppConfig

            config = AppConfig.from_toml()
            db_path = config.sqlite_path
        _default_fts = FTSManager(db_path)
        _default_fts.ensure_fts_tables()
    return _default_fts
