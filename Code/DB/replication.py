import pandas as pd
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from loguru import logger
from models.invoice import Invoice
from db.analytics import DuckDBManager
from core.config import AppConfig
from core.resilience.circuit_breaker import CircuitBreaker

async def sync_sqlite_to_duckdb(db_session: AsyncSession, config: AppConfig):
    """Most replikacyjny z mechanizmem Watermark."""
    duck_mgr = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    duck_mgr.connect()

    # 1. Pobierz czas ostatniej synchronizacji z DuckDB
    result = duck_mgr.execute("SELECT MAX(updated_at) FROM invoices_replica")
    last_sync = result[0][0] if result and result[0] and result[0][0] else None

    # 2. Wybierz tylko rekordy zmienione po tej dacie
    query = select(Invoice)
    if last_sync:
        query = query.where(Invoice.updated_at > last_sync)

    result = await db_session.execute(query)
    invoices = result.scalars().all()

    if not invoices:
        return {"status": "up-to-date", "count": 0}

    # 3. Masowy Upsert do DuckDB (przez DataFrame)
    data = [{
        "id": str(inv.id),
        "number": inv.number,
        "contractor_nip": inv.contractor_nip,
        "amount_net": float(inv.amount_net.amount if hasattr(inv.amount_net, 'amount') else inv.amount_net),
        "amount_gross": float(inv.amount_gross.amount if hasattr(inv.amount_gross, 'amount') else inv.amount_gross),
        "currency": inv.currency,
        "status": inv.status,
        "updated_at": inv.updated_at
    } for inv in invoices]

    df = pd.DataFrame(data)

    # Atomowe wstawienie do DuckDB
    duck_mgr.execute("INSERT INTO invoices_replica SELECT * FROM df ON CONFLICT (id) DO UPDATE SET ALL")

    return {"status": "success", "count": len(invoices)}


async def sync_single_invoice_to_duckdb(db_session: AsyncSession, config: AppConfig, invoice_id: str) -> dict[str, object]:
    """Synchronizuje pojedynczą fakturę do DuckDB (near-real-time)."""
    duck_mgr = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    duck_mgr.connect()
    result = await db_session.execute(select(Invoice).where(Invoice.id == invoice_id))
    invoice = result.scalar_one_or_none()
    if not invoice:
        return {"status": "not-found", "invoice_id": invoice_id}

    df = pd.DataFrame([
        {
            "id": str(invoice.id),
            "number": invoice.number,
            "contractor_nip": invoice.contractor_nip,
            "amount_net": float(invoice.amount_net.amount if hasattr(invoice.amount_net, 'amount') else invoice.amount_net),
            "amount_gross": float(invoice.amount_gross.amount if hasattr(invoice.amount_gross, 'amount') else invoice.amount_gross),
            "currency": invoice.currency,
            "status": invoice.status,
            "updated_at": invoice.updated_at,
        }
    ])
    duck_mgr.execute("INSERT INTO invoices_replica SELECT * FROM df ON CONFLICT (id) DO UPDATE SET ALL")
    return {"status": "success", "invoice_id": invoice_id}


class ReplicationBridge:
    def __init__(self, duckdb_conn):
        self.duck = duckdb_conn
        # Inicjalizujemy Bezpiecznik: max 3 błędy, 60 sekund blokady
        self.breaker = CircuitBreaker(failure_threshold=3, recovery_timeout=60)

    async def replicate_invoice(self, invoice_data: dict) -> bool:
        """Kopiuje dane faktury do DuckDB, chroniąc się Circuit Breakerem."""
        # 1. Strażnik: Czy obwód pozwala na wykonanie żądania?
        if not self.breaker.allow_request():
            logger.debug("[ReplicationBridge] Pominięto zapis do DuckDB (Obwód Otwarty).")
            # Tutaj można opcjonalnie zapisać ID faktury do kolejki "Zaległa Replikacja"
            return False

        # 2. Próba wykonania operacji
        try:
            # Używamy prepared statements w DuckDB
            self.duck.execute(
                """
                INSERT INTO invoices_replica (id, contractor_nip, amount_gross, issue_date, status)
                VALUES (?, ?, ?, ?, ?)
                """,
                [
                    invoice_data["id"],
                    invoice_data["contractor_nip"],
                    invoice_data["amount_gross"],
                    invoice_data["issue_date"],
                    invoice_data["status"]
                ]
            )
            # 3. Sukces: Resetujemy bezpiecznik
            self.breaker.record_success()
            return True

        except Exception as e:
            # 4. Awaria: Rejestrujemy błąd w bezpieczniku
            self.breaker.record_failure(str(e))
            # KLUCZOWE: Nie rzucamy wyjątku (raise) dalej!
            # Główny proces zapisu do SQLite nie może wiedzieć, że analityka zawiodła.
            return False
