"""Core services -- consolidated from replication.py, validation_service.py, analytics_service.py.

Contains:
- ReplicationBridge: Zero-ETL bridge (DuckDB read SQLite through ATTACH)
- is_duplicate / ValidationService: Business validation, duplicate detection
- AnalyticsService: Spending trends, top suppliers analysis
"""

from __future__ import annotations

from decimal import Decimal
from typing import final

from sqlmodel import Session, and_, select

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice


# ── ReplicationBridge (from replication.py) ────────────────────────────────


@final
class ReplicationBridge:
    """Zero-ETL bridge.

    Legacy row-by-row OLTP->OLAP replication is intentionally disabled.
    DuckDB reads SQLite directly through ATTACH (TYPE SQLITE).
    """
    __slots__ = ('olap',)

    def __init__(self, duckdb_manager: DuckDBManager):
        self.olap = duckdb_manager

    def sync_invoice(self, invoice: Invoice) -> None:
        """Compatibility no-op for deprecated API.

        Keeping the method avoids breaking callers while preventing duplicate,
        non-transactional replication writes.
        """
        _ = invoice
        self.olap.setup_zero_etl()
        self.olap.refresh_materialized_cashflow()

    def refresh_projections(self) -> None:
        """Explicit projection refresh entrypoint for schedulers/workers."""
        self.olap.setup_zero_etl()
        self.olap.refresh_materialized_cashflow()


# ── Validation (from validation_service.py) ────────────────────────────────


def is_duplicate(session: Session, nip: str, number: str, amount_gross: Decimal) -> bool:
    """Check if invoice already exists (column-level select, ~70% less data transfer)."""
    return (
        session.execute(
            select(Invoice.id).where(
                and_(
                    Invoice.contractor_nip == nip,
                    Invoice.number == number,
                    Invoice.amount_gross == amount_gross,
                )
            ).limit(1)
        ).scalar_one_or_none()
        is not None
    )


@final
class ValidationService:  # backward compat
    """Backward-compat alias. Use module-level is_duplicate() directly."""
    is_duplicate = staticmethod(is_duplicate)
    __slots__ = ()


# ── Analytics (from analytics_service.py) ──────────────────────────────────


@final
class AnalyticsService:
    __slots__ = ('duckdb',)

    def __init__(self, duckdb: DuckDBManager):
        self.duckdb = duckdb

    def get_monthly_spending_trend(self) -> list[dict]:
        """Return spending totals grouped by months for charts."""
        query = """
        SELECT
            strftime('%Y-%m', issue_date) as month,
            SUM(amount_gross) as total_gross,
            COUNT(id) as invoice_count
        FROM invoices_replica
        WHERE status = 'APPROVED'
        GROUP BY 1
        ORDER BY 1 DESC
        LIMIT 12
        """
        return self.duckdb.execute_query(query)

    def get_top_suppliers(self, limit: int = 5) -> list[dict]:
        """Analyze which contractors receive the most spending."""
        query = f"""
        SELECT
            contractor_nip,
            SUM(amount_gross) as total_spent
        FROM invoices_replica
        WHERE status = 'APPROVED'
        GROUP BY 1
        ORDER BY 2 DESC
        LIMIT {limit}
        """
        return self.duckdb.execute_query(query)
