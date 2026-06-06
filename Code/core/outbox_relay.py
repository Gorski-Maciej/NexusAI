# core/outbox_relay.py
import asyncio

from sqlalchemy import select

from core.logger import logger
from db.models import OutboxEvent


async def run_outbox_relay(session_factory, nats_client):
    """
    Pętla przekaźnika: Odczyt z DB -> Publikacja do NATS -> Usunięcie z DB.
    """
    logger.info("Uruchamianie Outbox Relay (At-least-once delivery)...")

    while True:
        try:
            async with session_factory() as session:
                # 1. Pobierz nieprzetworzone zdarzenia
                stmt = select(OutboxEvent).where(not OutboxEvent.processed).limit(50)
                result = await session.execute(stmt)
                events = result.scalars().all()

                if not events:
                    await asyncio.sleep(0.5) # Czekaj 500ms jeśli brak pracy
                    continue

                for event in events:
                    try:
                        # 2. Publikacja do NATS
                        # Używamy JetStream, by mieć gwarancję dostarczenia
                        await nats_client.publish(event.topic, event.payload.encode())
                        event.processed = True
                    except Exception as err:
                        logger.error(f"Nie powiodła się wysyłka do NATS: {err}")

                await session.commit()
        except Exception as e:
            logger.error(f"Błąd Outbox Relay: {e}")
            await asyncio.sleep(2)
