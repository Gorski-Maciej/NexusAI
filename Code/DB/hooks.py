import logging

from sqlalchemy import event
from models.invoice import Invoice
from db.analytics import DuckDBManager
from core.config import AppConfig

logger = logging.getLogger("nexus.db.hooks")

def register_db_hooks(config: AppConfig):
    """Rejestruje hooki, które automatycznie replikują dane do DuckDB po każdym komicie."""

    # Inicjalizacja managera analityki
    duck_mgr = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    duck_mgr.connect()

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
        }
        try:
            duck_mgr.execute(
                """
                INSERT INTO invoices_replica (id, number, contractor_nip, amount_net, amount_gross, currency, status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    number = EXCLUDED.number,
                    contractor_nip = EXCLUDED.contractor_nip,
                    amount_net = EXCLUDED.amount_net,
                    amount_gross = EXCLUDED.amount_gross,
                    currency = EXCLUDED.currency,
                    status = EXCLUDED.status
                """,
                [
                    str(data["id"]),
                    data["number"],
                    data["contractor_nip"],
                    data["amount_net"],
                    data["amount_gross"],
                    data["currency"],
                    data["status"],
                ],
            )
        except Exception as e:
            logger.warning("Failed to replicate invoice %s to DuckDB: %s", target.id, e)
