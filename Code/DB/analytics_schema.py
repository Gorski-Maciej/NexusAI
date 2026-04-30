from db.analytics import DuckDBManager
from services.telemetry import ensure_telemetry_schema
from db.zpk_schema import ensure_zpk_schema
from services.document_fingerprint import ensure_fingerprint_schema


class AnalyticsSchemaManager:
    """Zarządza wersjonowaniem schematu DuckDB (odpowiednik migracji)."""

    @staticmethod
    def ensure_latest_schema(duck_mgr: DuckDBManager):
        """Dodaje brakujące kolumny do repliki, jeśli schemat się zmienił."""

        # Przykład: Dodanie kolumny issue_date, jeśli nie istnieje w starszej wersji bazy
        existing_cols = duck_mgr.execute("PRAGMA table_info('invoices_replica')")
        col_names = [col[1] for col in existing_cols]

        if 'issue_date' not in col_names:
            duck_mgr.execute("ALTER TABLE invoices_replica ADD COLUMN issue_date DATE")

        # Tworzenie indeksów dla przyspieszenia raportów OLAP
        duck_mgr.execute("CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices_replica (issue_date)")
        duck_mgr.execute("CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices_replica (status)")

        # Telemetry schema for performance & system health dashboards
        ensure_telemetry_schema(duck_mgr)

        # ZPK engine schema bootstrap
        ensure_zpk_schema(duck_mgr)

        # Document fingerprint / Merkle audit schema
        ensure_fingerprint_schema(duck_mgr)
