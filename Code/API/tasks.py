import os
import asyncio
from datetime import datetime
from decimal import Decimal
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy.ext.asyncio import AsyncSession
from db.replication import sync_sqlite_to_duckdb
from db.database import get_session
from core.config import AppConfig

broker = PullBasedJetStreamBroker()

@broker.task(schedule=[{"cron": "*/5 * * * *"}])
async def run_data_replication():
    """Zadanie w tle synchronizujące główną bazę danych z bazą analityczną."""
    config = AppConfig()
    # Tworzymy osobną sesję dla workera
    async for db_session in get_session():
        result = await sync_sqlite_to_duckdb(db_session, config)
        print(f"[REPLICATION] Status: {result['status']}. Rows: {result.get('synced_rows', 0)}")

@broker.task(task_name="process_invoice_ocr")
async def process_invoice_task(invoice_id: str, image_path: str):
    async with session_factory() as session:
        loop = asyncio.get_running_loop()

        # 3. Surya to kod synchroniczny (blokujący), w osobnym wątku
        ai_result = await loop.run_in_executor(
            None,
            ocr_engine.process_image,
            image_path
        )

        # 4. Analiza wyników i aktualizacja bazy
        if ai_result.nip:
            invoice.contractor_nip = ai_result.nip

        if ai_result.amount_gross:
            invoice.amount_gross = Decimal(str(ai_result.amount_gross))
            invoice.amount_net = Decimal(str(ai_result.amount_gross / 1.23))

        await session.commit() # Zapis do SQLite
        await session.refresh(invoice)

        data = {
            "id": invoice.id,
            "number": invoice.number,
            "contractor_nip": invoice.contractor_nip,
            "amount_net": invoice.amount_net,
            "amount_gross": invoice.amount_gross,
            "currency": invoice.currency,
            "status": invoice.status,
            "updated_at": datetime.now()
        }

        # SYNCHRONIZACJA: Po pomyślnym commicie w SQLite, aktualizujemy DuckDB
        await loop.run_in_executor(None, olap_manager.upsert_invoice, data)
