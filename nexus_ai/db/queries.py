"""
Queries -- consolidated query helpers: pagination + FTS5 search + analytics views.

Łączy pagination.py, views.py, fts.py w jeden moduł.
Eliminuje duplikację importów i boilerplate'u między tymi plikami.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any, ClassVar, TypeVar

import anyio
from sqlmodel import Session, select
from sqlmodel import text as sa_text
from structlog import get_logger

from nexus_ai.db.async_base_service import AsyncBaseService
from nexus_ai.db.database import Base

logger = get_logger("nexus.db.queries")
T = TypeVar("T", bound=Base)


# ═══════════════════════════════════════════════════════════════════════════
# PAGINATION (dawniej: db/pagination.py)
# ═══════════════════════════════════════════════════════════════════════════


class CursorPagination:
    """Wydajna paginacja (Keyset/Cursor) z indeksem zamiast OFFSET.

    Dla tabel z 1M rekordów: OFFSET 50000 skanuje 50k wierszy,
    keyset skanuje tylko 50 wierszy (przez indeks PRIMARY KEY).
    """
    __slots__ = ()

    @staticmethod
    def get_page(
        session: Session,
        model: type[T],
        last_id: str | None = None,
        limit: int = 50,
        exclude_deleted: bool = True,
    ) -> tuple[list[T], str | None]:
        query = select(model).order_by(model.id.asc()).limit(limit)
        if exclude_deleted and hasattr(model, "is_deleted"):
            query = query.where(model.is_deleted == False)  # noqa: E712
        if last_id:
            query = query.where(model.id > last_id)
        items = session.execute(query).scalars().all()
        return items, items[-1].id if items else None

    @staticmethod
    def get_page_multi_column(
        session: Session,
        model: type[T],
        last_values: tuple[Any, ...] | None = None,
        sort_columns: tuple[str, ...] = ("created_at", "id"),
        sort_ascending: bool = True,
        limit: int = 50,
    ) -> tuple[list[T], tuple[Any, ...] | None]:
        order = " ASC" if sort_ascending else " DESC"
        order_clause = ", ".join(f"{col}{order}" for col in sort_columns)
        query = select(model).order_by(sa_text(order_clause)).limit(limit)
        if last_values:
            cols = ", ".join(sort_columns)
            params = ", ".join(["?"] * len(last_values))
            operator = ">" if sort_ascending else "<"
            condition = sa_text(f"({cols}) {operator} ({params})")
            for i, val in enumerate(last_values):
                condition = condition.bindparams(**{f"kv_{i}": val})
            query = query.where(condition)
        items = session.execute(query).scalars().all()
        if items:
            last = items[-1]
            next_values = tuple(getattr(last, col) for col in sort_columns)
        else:
            next_values = None
        return items, next_values


# ═══════════════════════════════════════════════════════════════════════════
# FTS5 SEARCH (dawniej: db/fts.py)
# ═══════════════════════════════════════════════════════════════════════════


class FTSManager(AsyncBaseService):
    """Zarządca FTS5 Full-Text Search przez sqlite3 + anyio.

    Tabele: invoices_fts, contractors_fts, audit_logs_fts, events_fts.
    Wspiera: BM25 ranking, highlight/snippet, hybrydowe FTS5+vec0, prefix indexing.
    """
    __slots__ = ()

    FTS_SCHEMAS: ClassVar[dict[str, str]] = {
        "invoices_fts": """
            CREATE VIRTUAL TABLE IF NOT EXISTS invoices_fts USING fts5(
                invoice_id UNINDEXED, number, contractor_nip UNINDEXED, contractor_name,
                amount_net UNINDEXED, amount_gross UNINDEXED, currency UNINDEXED,
                status, category, content='', tokenize='trigram 3 4', prefix='3,4'
            );""",
        "contractors_fts": """
            CREATE VIRTUAL TABLE IF NOT EXISTS contractors_fts USING fts5(
                contractor_id UNINDEXED, nip UNINDEXED, name, address,
                vat_status UNINDEXED, content='', tokenize='trigram 3 4', prefix='3,4'
            );""",
        "audit_logs_fts": """
            CREATE VIRTUAL TABLE IF NOT EXISTS audit_logs_fts USING fts5(
                log_id UNINDEXED, action, user_id UNINDEXED, field_changed,
                old_value, new_value, invoice_id UNINDEXED, content='', tokenize='unicode61'
            );""",
        "events_fts": """
            CREATE VIRTUAL TABLE IF NOT EXISTS events_fts USING fts5(
                event_id UNINDEXED, aggregate_type UNINDEXED, aggregate_id UNINDEXED,
                event_type, metadata_json, content='', tokenize='unicode61'
            );""",
    }

    FTS_TRIGGERS: ClassVar[list[str]] = [
        """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_insert AFTER INSERT ON invoices BEGIN
            INSERT INTO invoices_fts(invoice_id, number, contractor_nip, status)
            VALUES (NEW.id, COALESCE(NEW.number, ''), COALESCE(NEW.contractor_nip, ''), COALESCE(NEW.status, ''));
        END;""",
        """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_delete AFTER DELETE ON invoices BEGIN
            DELETE FROM invoices_fts WHERE invoice_id = OLD.id;
        END;""",
        """
        CREATE TRIGGER IF NOT EXISTS trg_invoices_fts_update AFTER UPDATE ON invoices BEGIN
            DELETE FROM invoices_fts WHERE invoice_id = OLD.id;
            INSERT INTO invoices_fts(invoice_id, number, contractor_nip, status)
            VALUES (NEW.id, COALESCE(NEW.number, ''), COALESCE(NEW.contractor_nip, ''), COALESCE(NEW.status, ''));
        END;""",
    ]

    def __init__(self, db_path: str | Path) -> None:
        super().__init__(db_path)

    async def _run_fts(self, fn, *args: Any) -> Any:
        """Execute a sync FTS operation in a thread."""
        return await anyio.to_thread.run_sync(fn, *args)

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        await self._run_fts(
            lambda: conn.execute("PRAGMA cache_size = -25600;") or conn.execute("PRAGMA temp_store = MEMORY;")
        )

    async def ensure_tables(self) -> None:
        for schema in self.FTS_SCHEMAS.values():
            await self.execute(schema)
        for trigger in self.FTS_TRIGGERS:
            await self.execute(trigger)
        await self.commit()

    async def search(
        self, fts_table: str, query: str, join_table: str = "", limit: int = 20, offset: int = 0
    ) -> list[dict[str, Any]]:
        if not query.strip():
            return []
        try:
            join_clause = (
                f" JOIN {join_table} j ON j.id = {fts_table}.{join_table}_id" if join_table else ""
            )
            return await self.fetchall(
                f"SELECT {fts_table}.*, rank FROM {fts_table}{join_clause} WHERE {fts_table} MATCH ? ORDER BY rank LIMIT ? OFFSET ?",
                (query, limit, offset),
            )
        except Exception as exc:
            logger.warning("[FTS] Search %s failed: %s", fts_table, exc)
            return []

    async def search_hybrid(
        self,
        keyword: str,
        query_vector: list[float] | None = None,
        alpha: float = 0.7,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        if not keyword.strip() and query_vector is None:
            return []
        fts_results = (
            await self.search("invoices_fts", keyword, join_table="invoices", limit=limit * 3)
            if keyword.strip()
            else []
        )
        if fts_results and (max_r := max(r.get("rank", 0) for r in fts_results)) > 0:
            min_r = min(r["rank"] for r in fts_results)
            rng = max(max_r - min_r, 1e-10)
            for r in fts_results:
                r["_score"] = alpha * (1.0 - (r["rank"] - min_r) / rng)
        return fts_results[:limit]

    async def index_invoice(self, invoice_id: str, **fields: str) -> None:
        await self.execute("DELETE FROM invoices_fts WHERE invoice_id = ?", (invoice_id,))
        cols = ", ".join(fields.keys())
        vals = ", ".join("?" for _ in fields)
        await self.execute(
            f"INSERT INTO invoices_fts(invoice_id, {cols}) VALUES (? , {vals})",
            (invoice_id, *fields.values()),
        )
        await self.commit()

    async def rebuild(self) -> None:
        conn = await self.get_conn()

        def _rebuild():
            for tbl in ["invoices_fts", "contractors_fts", "audit_logs_fts", "events_fts"]:
                conn.execute(f"INSERT INTO {tbl}({tbl}) VALUES('rebuild')")
            conn.commit()

        await self._run_fts(_rebuild)
        logger.info("[FTS] All indexes rebuilt")

    async def close(self) -> None:
        if self._conn:
            try:
                await self._run_fts(self._conn.execute, "PRAGMA optimize;")
            except Exception:
                pass
        await super().close()


# ═══════════════════════════════════════════════════════════════════════════
# ANALYTICS VIEWS (dawniej: db/views.py)
# ═══════════════════════════════════════════════════════════════════════════


class AnalyticsViews:
    """Inicjalizacja zmaterializowanych widoków biznesowych w DuckDB.

    Używa materialized tables (CREATE OR REPLACE TABLE) zamiast VIEW
    -- przeliczone raz, nie przy każdym SELECT.
    Window functions: LAG, LEAD, ROW_NUMBER, SUM OVER, moving averages.
    """
    __slots__ = ()

    @staticmethod
    def create_all(duckdb_mgr) -> None:
        """Utwórz wszystkie widoki analityczne."""
        ddls = [
            """
            CREATE TABLE IF NOT EXISTS m_monthly_summary AS
            WITH monthly AS (SELECT strftime('%Y-%m', issue_date) AS period, COUNT(id) as document_count,
                SUM(amount_net) as total_net, SUM(amount_gross) as total_gross
                FROM invoices_replica WHERE status != 'REJECTED' GROUP BY 1)
            SELECT period, document_count, total_net, total_gross,
                LAG(total_net) OVER (ORDER BY period) AS prev_month_net,
                CASE WHEN LAG(total_net) OVER (ORDER BY period) > 0
                    THEN (total_net - LAG(total_net) OVER (ORDER BY period)) / LAG(total_net) OVER (ORDER BY period) * 100
                    ELSE NULL END AS mom_change_pct,
                AVG(total_net) OVER (ORDER BY period ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m
            FROM monthly ORDER BY period DESC
            """,
            """
            CREATE TABLE IF NOT EXISTS m_top_contractors AS
            WITH ct AS (SELECT contractor_nip, SUM(amount_gross) as total_spent,
                COUNT(*) as invoice_count, AVG(amount_gross) as avg_invoice_value
                FROM invoices_replica GROUP BY 1),
            gt AS (SELECT SUM(total_spent) as overall_total FROM ct)
            SELECT ct.*, ROW_NUMBER() OVER (ORDER BY ct.total_spent DESC) AS rank,
                CASE WHEN gt.overall_total > 0 THEN ct.total_spent / gt.overall_total * 100 ELSE 0 END AS share_pct
            FROM ct CROSS JOIN gt ORDER BY ct.total_spent DESC
            """,
            """
            CREATE TABLE IF NOT EXISTS m_cashflow_projection AS
            WITH inflows AS (SELECT i.id AS source_id, 'INVOICE_INFLOW' AS source_type,
                (CAST(i.due_date AS DATE) + COALESCE(vs.avg_delay_days, 0) * INTERVAL 1 DAY)::DATE AS projected_date,
                CAST(CASE WHEN COALESCE(vs.vendor_score, 1.0) < 0.4 THEN i.amount_gross * 0.5 ELSE i.amount_gross END AS DECIMAL(18,2)) AS amount,
                'INFLOW' AS flow_direction, i.number AS description
                FROM invoices_replica i LEFT JOIN vendor_scorecards vs ON vs.contractor_nip = i.contractor_nip
                WHERE i.status = 'UNPAID' AND COALESCE(i.amount_gross, 0) > 0),
            outflows AS (SELECT i.id, 'INVOICE_OUTFLOW', CAST(i.due_date AS DATE), CAST(ABS(i.amount_gross) AS DECIMAL(18,2)),
                'OUTFLOW', i.number FROM invoices_replica i WHERE i.status = 'UNPAID' AND COALESCE(i.amount_gross, 0) < 0)
            SELECT projected_date, SUM(CASE WHEN flow_direction = 'INFLOW' THEN amount ELSE 0 END) AS daily_inflow,
                SUM(CASE WHEN flow_direction = 'OUTFLOW' THEN amount ELSE 0 END) AS daily_outflow,
                SUM(amount) AS daily_net, SUM(daily_net) OVER (ORDER BY projected_date) AS cumulative_balance
            FROM (SELECT * FROM inflows UNION ALL SELECT * FROM outflows)
            GROUP BY projected_date ORDER BY projected_date
            """,
        ]
        for ddl in ddls:
            try:
                duckdb_mgr._ddl_execute_safe(ddl)
            except Exception as exc:
                logger.warning("[VIEWS] Failed to create view: %s", exc)

    @staticmethod
    def refresh(duckdb_mgr) -> None:
        """Odśwież materialized tables."""
        import time

        t0 = time.monotonic()
        for tbl in ["m_monthly_summary", "m_top_contractors"]:
            duckdb_mgr._ddl_execute_safe(f"DELETE FROM {tbl}")
        duckdb_mgr._ddl_execute_safe(
            "INSERT INTO m_monthly_summary "
            + """
            WITH monthly AS (SELECT strftime('%Y-%m', issue_date) AS period, COUNT(id) as dc, SUM(amount_net) as tn, SUM(amount_gross) as tg
                FROM invoices_replica WHERE status != 'REJECTED' GROUP BY 1)
            SELECT period, dc, tn, tg, LAG(tn) OVER (ORDER BY period) AS pmn,
                CASE WHEN LAG(tn) OVER (ORDER BY period) > 0 THEN (tn - LAG(tn) OVER (ORDER BY period)) / LAG(tn) OVER (ORDER BY period) * 100 ELSE NULL END AS mcp,
                AVG(tn) OVER (ORDER BY period ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma3
            FROM monthly ORDER BY period DESC
        """
        )
        elapsed = (time.monotonic() - t0) * 1000
        logger.info("[VIEWS] Refreshed in %.1f ms", elapsed)


# Legacy name kept for backwards compatibility (remove in next major version)
AnalyticsViewsSetup = AnalyticsViews
