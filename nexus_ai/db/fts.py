"""
AsyncFTSManager — async FTS5 Full-Text Search via sqlite3.

Python 3.13t (free-threaded): używamy natywnego sqlite3 + asyncio.to_thread
zamiast aiosqlite.

SUPERMOCE FTS5:
- FTS5 (Full-Text Search v5) — wbudowany silnik wyszukiwania
- BM25 ranking z custom wagami kolumn
- highlight/snippet dla podświetlania wyników
- Hybrydowe wyszukiwanie FTS5 + vec0
- Prefix indexing dla szybszych prefix queries
- FTS5 content sync triggers (automatyczna synchronizacja)
"""

from __future__ import annotations

import asyncio
import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.db.async_base_service import AsyncBaseService

logger = get_logger("nexus.db.fts")


class AsyncFTSManager(AsyncBaseService):
    """Async zarządca FTS5 tabel dla wyszukiwania pełnotekstowego.

    Python 3.13t (free-threaded): synchroniczne sqlite3 + asyncio.to_thread.

    Tabele FTS5:
    - ``invoices_fts``: numer faktury, nazwa kontrahenta, status, kategoria
    - ``contractors_fts``: NIP, nazwa, adres
    - ``audit_logs_fts``: akcja, user_id, szczegóły
    - ``events_fts``: typ eventu, aggregate_id, metadane
    """

    def __init__(self, db_path: str | Path) -> None:
        super().__init__(db_path)

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook dodający PRAGMY specyficzne dla FTS5."""
        def _sync() -> None:
            conn.execute("PRAGMA cache_size = -25600;")  # 100MB
            conn.execute("PRAGMA temp_store = MEMORY;")
        await asyncio.to_thread(_sync)

    async def close(self) -> None:
        """Zamknij z PRAGMA optimize (tylko jeśli połączenie aktywne)."""
        if self._conn is not None:
            try:
                def _optimize() -> None:
                    try:
                        self._conn.execute("PRAGMA optimize;")
                    except Exception:
                        pass
                await asyncio.to_thread(_optimize)
            except Exception:
                pass
        await super().close()

    # ── Schema definitions ──────────────────────────────────────────

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
            tokenize='trigram 3 4',
            prefix='3,4'
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
            tokenize='trigram 3 4',
            prefix='3,4'
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
            tokenize='unicode61',
            prefix='3,4'
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
            tokenize='unicode61',
            prefix='3,4'
        );
    """

    FTS_INVOICES_TRIGGER_INSERT = """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_insert
        AFTER INSERT ON invoices
        BEGIN
            INSERT INTO invoices_fts(invoice_id, number, contractor_nip, status)
            VALUES (
                NEW.id,
                COALESCE(NEW.number, ''),
                COALESCE(NEW.contractor_nip, ''),
                COALESCE(NEW.status, '')
            );
        END;
    """

    FTS_INVOICES_TRIGGER_DELETE = """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_delete
        AFTER DELETE ON invoices
        BEGIN
            DELETE FROM invoices_fts WHERE invoice_id = OLD.id;
        END;
    """

    FTS_INVOICES_TRIGGER_UPDATE = """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_update
        AFTER UPDATE ON invoices
        BEGIN
            DELETE FROM invoices_fts WHERE invoice_id = OLD.id;
            INSERT INTO invoices_fts(invoice_id, number, contractor_nip, status)
            VALUES (
                NEW.id,
                COALESCE(NEW.number, ''),
                COALESCE(NEW.contractor_nip, ''),
                COALESCE(NEW.status, '')
            );
        END;
    """

    async def ensure_fts_tables(self) -> None:
        """Utwórz wszystkie tabele FTS5 jeśli nie istnieją (async)."""
        for schema in [
            self.FTS_INVOICES_SCHEMA,
            self.FTS_CONTRACTORS_SCHEMA,
            self.FTS_AUDIT_LOGS_SCHEMA,
            self.FTS_EVENTS_SCHEMA,
        ]:
            await self.execute(schema)

        for trigger in [
            self.FTS_INVOICES_TRIGGER_INSERT,
            self.FTS_INVOICES_TRIGGER_DELETE,
            self.FTS_INVOICES_TRIGGER_UPDATE,
        ]:
            await self.execute(trigger)

        await self.commit()
        logger.info("[FTS] All FTS5 tables + sync triggers ensured (async)")

    # ── BM25 ranking ──────────────────────────────────────────────────

    @staticmethod
    def _rank_bm25_custom() -> str:
        return "bm25(invoices_fts, 10.0, 5.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0)"

    @staticmethod
    def _highlight_snippet(column_idx: int = 1, max_tokens: int = 64) -> str:
        return (
            f"snippet(invoices_fts, {column_idx}, '<mark>', '</mark>', {max_tokens})"
        )

    # ── Search methods (ASYNC!) ────────────────────────────────────────

    async def search_invoices_with_highlights(
        self,
        query: str,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """SZUKAJ faktur przez FTS5 z podświetlonymi trafieniami (ASYNC)."""
        if not query.strip():
            return []

        try:
            rank_expr = self._rank_bm25_custom()
            number_snippet = self._highlight_snippet(1, 64)
            name_snippet = self._highlight_snippet(3, 64)
            rows = await self.fetchall(
                f"""SELECT i.*, {rank_expr} AS rank,
                           {number_snippet} AS snippet_number,
                           {name_snippet} AS snippet_contractor
                   FROM invoices_fts fts
                   JOIN invoices i ON i.id = fts.invoice_id
                   WHERE invoices_fts MATCH ?
                   ORDER BY rank
                   LIMIT ? OFFSET ?""",
                (query, limit, offset),
            )
            return rows
        except Exception as exc:
            logger.warning("[FTS] Search highlights failed: %s — query=%r", exc, query)
            return []

    async def search_invoices(
        self,
        query: str,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """SZUKAJ faktur przez FTS5 z rankingiem BM25 (ASYNC)."""
        if not query.strip():
            return []

        try:
            return await self.fetchall(
                """SELECT i.*, fts.rank
                   FROM invoices_fts fts
                   JOIN invoices i ON i.id = fts.invoice_id
                   WHERE invoices_fts MATCH ?
                   ORDER BY fts.rank
                   LIMIT ? OFFSET ?""",
                (query, limit, offset),
            )
        except Exception as exc:
            logger.warning("[FTS] Search query failed: %s — query=%r", exc, query)
            return []

    async def search_contractors(
        self,
        query: str,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """SZUKAJ kontrahentów przez FTS5 (ASYNC)."""
        if not query.strip():
            return []

        try:
            return await self.fetchall(
                """SELECT c.*, fts.rank
                   FROM contractors_fts fts
                   JOIN contractors c ON c.id = fts.contractor_id
                   WHERE contractors_fts MATCH ?
                   ORDER BY fts.rank
                   LIMIT ?""",
                (query, limit),
            )
        except Exception as exc:
            logger.warning("[FTS] Contractor search failed: %s — query=%r", exc, query)
            return []

    async def search_events(
        self,
        query: str,
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        """SZUKAJ eventów przez FTS5 (ASYNC)."""
        if not query.strip():
            return []

        try:
            conn = await self.get_conn()

            def _sync() -> list[dict[str, Any]]:
                cursor = conn.execute(
                    """SELECT fts.*
                       FROM events_fts fts
                       WHERE events_fts MATCH ?
                       ORDER BY rank
                       LIMIT ?""",
                    (query, limit),
                )
                return [dict(r) for r in cursor.fetchall()]

            return await asyncio.to_thread(_sync)
        except Exception as exc:
            logger.warning("[FTS] Event search failed: %s — query=%r", exc, query)
            return []

    async def search_all(
        self,
        query: str,
        limit_per_type: int = 5,
    ) -> dict[str, list[dict[str, Any]]]:
        """SZUKAJ we wszystkich tabelach FTS5 jednocześnie (ASYNC)."""
        invoices = await self.search_invoices(query, limit=limit_per_type)
        contractors = await self.search_contractors(query, limit=limit_per_type)
        events = await self.search_events(query, limit=limit_per_type)
        return {
            "invoices": invoices,
            "contractors": contractors,
            "events": events,
        }

    async def search_hybrid(
        self,
        keyword_query: str,
        query_vector: list[float] | None = None,
        alpha: float = 0.7,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Hybrydowe wyszukiwanie FTS5 + vec0 (ASYNC)."""
        if not keyword_query.strip() and query_vector is None:
            return []

        conn = await self.get_conn()

        def _sync_hybrid() -> list[dict[str, Any]]:
            # Krok 1: Wyniki FTS5
            fts_results: list[dict[str, Any]] = []
            if keyword_query.strip():
                cursor = conn.execute(
                    """SELECT i.*, fts.rank
                       FROM invoices_fts fts
                       JOIN invoices i ON i.id = fts.invoice_id
                       WHERE invoices_fts MATCH ?
                       ORDER BY fts.rank
                       LIMIT ?""",
                    (keyword_query, limit * 3),
                )
                fts_results = [dict(r) for r in cursor.fetchall()]
                if fts_results:
                    max_rank = max(r.get("rank", 0) for r in fts_results)
                    min_rank = min(r.get("rank", 0) for r in fts_results)
                    rank_range = max(max_rank - min_rank, 1e-10)
                    for r in fts_results:
                        r["_fts_score"] = 1.0 - (r.get("rank", 0) - min_rank) / rank_range
                        r["_hybrid_score"] = alpha * r["_fts_score"]

            # Krok 2: Wyniki vec0
            if query_vector:
                try:
                    import sqlite_vec

                    query_blob = sqlite_vec.serialize_float32(query_vector)
                    cursor = conn.execute(
                        """SELECT i.*, vec_distance_cosine(v.embedding, ?) AS _vec_distance
                           FROM invoice_vectors v
                           JOIN invoices i ON i.id = v.rowid
                           WHERE v.embedding MATCH ?
                           ORDER BY _vec_distance ASC
                           LIMIT ?""",
                        (query_blob, query_blob, limit * 3),
                    )
                    vec_rows = cursor.fetchall()
                    vec_results = [dict(r) for r in vec_rows]
                    if vec_results:
                        max_dist = max(r["_vec_distance"] for r in vec_results)
                        min_dist = min(r["_vec_distance"] for r in vec_results)
                        dist_range = max(max_dist - min_dist, 1e-10)
                        for r in vec_results:
                            r["_vec_score"] = 1.0 - (r["_vec_distance"] - min_dist) / dist_range
                            r["_hybrid_score"] = (1.0 - alpha) * r["_vec_score"]
                except Exception:
                    logger.debug("[FTS] vec0 unavailable for hybrid search", exc_info=True)
                    vec_results = []
            else:
                vec_results = []

            # Krok 3: Połącz wyniki
            combined: dict[str, dict[str, Any]] = {}
            for r in fts_results:
                inv_id = r.get("id", "")
                if inv_id:
                    combined[inv_id] = r
            for r in vec_results:
                inv_id = r.get("id", "")
                if inv_id in combined:
                    combined[inv_id]["_hybrid_score"] = (
                        combined[inv_id].get("_hybrid_score", 0.0)
                        + (1.0 - alpha) * r.get("_vec_score", 0.0)
                    )
                else:
                    r["_hybrid_score"] = (1.0 - alpha) * r.get("_vec_score", 0.0)
                    combined[inv_id] = r

            results = list(combined.values())
            results.sort(key=lambda x: x.get("_hybrid_score", 0.0), reverse=True)
            return results[:limit]

        try:
            return await asyncio.to_thread(_sync_hybrid)
        except Exception as exc:
            logger.warning("[FTS] Hybrid search failed: %s", exc)
            if keyword_query.strip():
                return await self.search_invoices(keyword_query, limit=limit)
            return []

    # ── Indexing methods (ASYNC) ───────────────────────────────────────

    async def index_invoice(
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
        """Indeksuj pojedynczą fakturę (ASYNC)."""
        await self.execute("DELETE FROM invoices_fts WHERE invoice_id = ?", (invoice_id,))
        await self.execute(
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
        await self.commit()

    async def index_contractor(
        self,
        contractor_id: str,
        nip: str = "",
        name: str = "",
        address: str = "",
        vat_status: str = "",
    ) -> None:
        """Indeksuj pojedynczego kontrahenta (ASYNC)."""
        await self.execute(
            "DELETE FROM contractors_fts WHERE contractor_id = ?", (contractor_id,)
        )
        await self.execute(
            """INSERT INTO contractors_fts(
                   contractor_id, nip, name, address, vat_status
               ) VALUES (?, ?, ?, ?, ?)""",
            (contractor_id, nip, name, address, vat_status),
        )
        await self.commit()

    async def delete_invoice(self, invoice_id: str) -> None:
        """Usuń fakturę z indeksu FTS5 (ASYNC)."""
        await self.execute("DELETE FROM invoices_fts WHERE invoice_id = ?", (invoice_id,))
        await self.commit()

    async def rebuild_index(self) -> None:
        """Przebuduj wszystkie indeksy FTS5 (ASYNC)."""
        conn = await self.get_conn()

        def _sync() -> None:
            conn.execute("INSERT INTO invoices_fts(invoices_fts) VALUES('rebuild')")
            conn.execute("INSERT INTO contractors_fts(contractors_fts) VALUES('rebuild')")
            conn.execute("INSERT INTO audit_logs_fts(audit_logs_fts) VALUES('rebuild')")
            conn.execute("INSERT INTO events_fts(events_fts) VALUES('rebuild')")
            conn.commit()

        await asyncio.to_thread(_sync)
        logger.info("[FTS] All indexes rebuilt (async)")


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
FTSManager = AsyncFTSManager


# ── Global singleton ─────────────────────────────────────────────────────

_default_fts: AsyncFTSManager | None = None


def get_fts_manager(db_path: str | Path | None = None) -> AsyncFTSManager:
    """Zwróć globalną instancję FTSManager."""
    global _default_fts
    if _default_fts is None:
        if db_path is None:
            from nexus_ai.core.config import AppConfig

            config = AppConfig.from_toml()
            db_path = config.sqlite_path
        _default_fts = AsyncFTSManager(db_path)
    return _default_fts
