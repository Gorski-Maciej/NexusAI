import asyncio
import pendulum
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import OutboxEvent


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
            payload=msgspec_dumps(payload, ensure_ascii=False),
            status="PENDING",
            created_at=pendulum.now("UTC")
        )
        session.add(event)

# Pseudo-kod workera wyciągający dane do NATS
async def _outbox_processor(session_factory, nats_client):
    while True:
        async with session_factory() as session:
            # Pobierz nieprzetworzone zdarzenia
            # Uwaga: not OutboxEvent.processed nie działa z SQLAlchemy
            stmt = select(OutboxEvent).where(OutboxEvent.processed == False)  # noqa: E712
            events = await session.execute(stmt)

            for event in events.scalars():
                try:
                    # Używamy event_type jako tematu NATS (event.topic nie istnieje)
                    subject = f"outbox.{event.event_type}"
                    await nats_client.publish(subject, event.payload.encode())
                    event.processed = True
                    await session.commit()
                except Exception:
                    await session.rollback()

        await asyncio.sleep(1)  # Oddech dla bazy
