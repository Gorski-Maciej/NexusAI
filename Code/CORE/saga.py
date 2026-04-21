# core/reconciliation.py
from datetime import datetime, timedelta
from sqlalchemy import select
from models.invoice import Invoice
# from core.broker import nats # import szyny komunikatów

async def reconciliation_loop(session_factory, ksef_service):
    """Pętla naprawcza sprawdzająca 'zawieszone' procesy."""
    while True:
        async with session_factory() as session:
            # Szukaj faktur wysłanych do KSeF ponad 2 godziny temu, które nie mają UPO
            stuck_invoices = await session.execute(
                select(Invoice).where(
                    Invoice.status == 'SENT_TO_KSEF',
                    Invoice.updated_at < datetime.now() - timedelta(hours=2)
                )
            )

            for inv in stuck_invoices.scalars():
                # Sprawdź status bezpośrednio w API (może UPO już jest, tylko NATS nie dotarł)
                status = await ksef_service.check_status(inv.external_id)
                if status == "COMPLETED":
                    inv.status = "SUCCESS"
                else:
                    # Ponów próbę lub powiadom operatora
                    pass
                    # await nats.publish("alerts.stuck", payload)

            await session.commit()

        await asyncio.sleep(600) # Sprawdza co 10 minut
