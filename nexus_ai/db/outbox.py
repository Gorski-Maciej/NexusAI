import time
from typing import Any

import pendulum
from sqlalchemy import select
from sqlalchemy.orm import Session

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import OutboxEvent


class OutboxManager:
    """Zarządza wzorcem Transactional Outbox dla gwarantowanej dostawy zdarzeń."""

    @staticmethod
    def publish_event(
        session: Session, event_type: str, payload: dict[str, Any], aggregate_id: str
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
            created_at=pendulum.now("UTC"),
        )
        session.add(event)


# Pseudo-kod workera wyciągający dane do NATS
def _outbox_processor(session_factory, nats_client):
    while True:
        with session_factory() as session:
            stmt = select(OutboxEvent).where(OutboxEvent.processed == False)  # noqa: E712
            events = session.execute(stmt)

            for event in events.scalars():
                try:
                    subject = f"outbox.{event.event_type}"
                    nats_client.publish(subject, event.payload.encode())
                    event.processed = True
                    session.commit()
                except Exception:
                    session.rollback()

        time.sleep(1)  # Oddech dla bazy
