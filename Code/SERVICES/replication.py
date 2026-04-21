from db.analytics import DuckDBManager
from models.invoice import Invoice


class ReplicationBridge:
    def __init__(self, duckdb_manager: DuckDBManager):
        self.olap = duckdb_manager

    def sync_invoice(self, invoice: Invoice):
        """Replikuje fakturę z SQLite do analitycznego DuckDB."""
        query = """
        INSERT OR REPLACE INTO invoices_replica (
            id, number, contractor_nip, amount_net,
            amount_gross, currency, status, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        params = (
            str(invoice.id),
            invoice.number or "BRAK",
            invoice.contractor_nip,
            float(invoice.amount_net),
            float(invoice.amount_gross),
            invoice.currency,
            invoice.status,
            invoice.updated_at or invoice.created_at
        )
        self.olap.execute(query, params)
