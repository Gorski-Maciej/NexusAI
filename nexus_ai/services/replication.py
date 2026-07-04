from __future__ import annotations

from typing import final

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice


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
        # Ensure Zero-ETL attachment is active and refresh aggregate projections.
        self.olap.setup_zero_etl()
        self.olap.refresh_materialized_cashflow()

    def refresh_projections(self) -> None:
        """Explicit projection refresh entrypoint for schedulers/workers."""
        self.olap.setup_zero_etl()
        self.olap.refresh_materialized_cashflow()
