from sqlalchemy import event
from models.invoice import Invoice
from db.analytics import DuckDBManager
from core.config import AppConfig

def register_db_hooks(config: AppConfig):
    """Rejestruje hooki, które automatycznie replikują dane do DuckDB po każdym komicie."""

    # Inicjalizacja managera analityki
    duck_mgr = DuckDBManager(config)

    @event.listens_for(Invoice, 'after_insert')
    @event.listens_for(Invoice, 'after_update')
    def replicate_to_duckdb(mapper, connection, target):
        """Automatyczny Upsert do DuckDB przy zmianie w SQLite."""
        data = {
            "id": str(target.id),
            "number": target.number,
            "contractor_nip": target.contractor_nip,
            "amount_net": float(target.amount_net) if target.amount_net else 0.0,
            "amount_gross": float(target.amount_gross) if target.amount_gross else 0.0,
            "currency": target.currency,
            "status": target.status,
            "updated_at": target.updated_at
        }
        duck_mgr.upsert_invoice(data)
