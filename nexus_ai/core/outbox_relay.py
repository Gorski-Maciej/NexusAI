# core/outbox_relay.py
import anyio

from sqlalchemy import select

from nexus_ai.core.logger import logger
from nexus_ai.db.models import OutboxEvent


async def run_outbox_relay(session_factory, nats_client):
    """
    Pętla przekaźnika: Odczyt z DB -> Publikacja do NATS -> Usunięcie z DB.

    Używa ``event_type`` jako tematu NATS (zamiast nieistniejącego ``event.topic``).
    """
    logger.info("Uruchamianie Outbox Relay (At-least-once delivery)...")

    while True:
        try:
            async with session_factory() as session:
                # 1. Pobierz nieprzetworzone zdarzenia
                # Uwaga: not OutboxEvent.processed nie działa z SQLAlchemy
                # Poprawna składnia: OutboxEvent.processed == False
                stmt = (
                    select(OutboxEvent)
                    .where(OutboxEvent.processed == False)  # noqa: E712
                    .limit(50)
                )
                result = await session.execute(stmt)
                events = result.scalars().all()

                if not events:
                    await anyio.sleep(0.5)  # Czekaj 500ms jeśli brak pracy
                    continue

                for event in events:
                    try:
                        # 2. Publikacja do NATS — używamy event_type jako tematu
                        # (event.topic nie istnieje w modelu OutboxEvent)
                        subject = f"outbox.{event.event_type}"
                        await nats_client.publish(subject, event.payload.encode())
                        event.processed = True
                    except Exception as err:
                        logger.error(f"Nie powiodła się wysyłka do NATS: {err}")

                await session.commit()
        except Exception as e:
            logger.error(f"Błąd Outbox Relay: {e}")
            await anyio.sleep(2)
