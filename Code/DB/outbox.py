import json
import asyncio
from datetime import datetime, timezone
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from db.models import OutboxEvent

class OutboxManager:
    """Zarządza wzorcem Transactional Outbox dla gwarantowanej dostawy zdarzeń."""

    @staticmethod
    async def publish_event(
        session: AsyncSession,
        event_type: str,
        payload: dict[str, Any],
        aggregate_id: str
    ) -> None:
        """
        Zapisuje zdarzenie (np. eksport_erp, wysylka_ksef) w tej samej transakcji co dane.
        Zostanie wypchnięte do NATS przez oddzielnego workera.
        """
        event = OutboxEvent(
            event_type=event_type,
            aggregate_id=aggregate_id,
            payload=json.dumps(payload, ensure_ascii=False),
            status="PENDING",
            created_at=datetime.now(timezone.utc)
        )
        session.add(event)

# Pseudo-kod workera wyciągający dane do NATS
async def _outbox_processor(session_factory, nats_client):
    while True:
        async with session_factory() as session:
            # Pobierz nieprzetworzone zdarzenia
            events = await session.execute(select(OutboxEvent).where(OutboxEvent.processed == False))

            for event in events.scalars():
                try:
                    await nats_client.publish(event.topic, event.payload.encode())
                    event.processed = True
                    await session.commit()
                except Exception:
                    await session.rollback()

        await asyncio.sleep(1) # Oddech dla bazy
