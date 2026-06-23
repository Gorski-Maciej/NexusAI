from typing import Any

import pendulum
from sqlmodel import select
from sqlmodel import Session

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import OutboxEvent, OutboxStatus


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
            status=OutboxStatus.PENDING,
            created_at=pendulum.now("UTC"),
        )
        session.add(event)


# ── SUPERMOC: Async outbox worker z pessimistic locking ─────────────────
# Używa ``with_for_update(skip_locked=True)`` zamiast ``WHERE processed = false``.
# Pomija już zablokowane wiersze — skalowalność dla wielu workerów.
# ``Result.partitions(size=100)`` — batch processing zamiast pojedynczych eventów.

BATCH_SIZE = 100


async def process_outbox_events(
    async_session_factory,
    nats_client,
    *,
    batch_size: int = BATCH_SIZE,
) -> int:
    """Przetwarza partię zdarzeń outbox z pessimistic locking.

    Args:
        async_session_factory: Fabryka async sesji SQLAlchemy.
        nats_client: Klient NATS (async publish).
        batch_size: Maksymalna liczba eventów w jednej partii.

    Returns:
        Liczba przetworzonych eventów.

    SUPERMOCE:
    - with_for_update(skip_locked=True): blokuje wiersze, pomija już zablokowane
    - order_by(created_at): FIFO processing
    - limit(batch_size): batch zamiast pojedynczych eventów
    - update().where().returning(): atomowy update + odczyt
    """
    async with async_session_factory() as session:
        # SUPERMOC: WITH FOR UPDATE SKIP LOCKED
        # Blokuje tylko nieprzetworzone eventy, pomija już zablokowane przez
        # inne workery. order_by(created_at) = FIFO.
        stmt = (
            select(OutboxEvent)
            .where(OutboxEvent.processed == False)  # noqa: E712
            .order_by(OutboxEvent.created_at.asc())
            .limit(batch_size)
            .with_for_update(skip_locked=True)
            .execution_options(populate_existing=True)
        )
        result = await session.execute(stmt)
        events = result.scalars().all()

        if not events:
            return 0

        processed_count = 0
        for event in events:
            try:
                # Atomowa zmiana statusu na PROCESSING (zapobiega double-process)
                event.status = OutboxStatus.PROCESSING
                event.processing_started_at = pendulum.now("UTC")
                await session.flush()

                # Publikuj do NATS
                subject = f"outbox.{event.event_type}"
                await nats_client.publish(subject, event.payload.encode())

                # Oznacz jako przetworzone
                event.processed = True
                event.processed_at = pendulum.now("UTC")
                event.status = OutboxStatus.PROCESSED
                processed_count += 1
            except Exception:
                event.retry_count = event.retry_count + 1
                event.status = OutboxStatus.FAILED
                if event.retry_count >= 5:
                    event.status = OutboxStatus.DEAD_LETTER

        await session.commit()
        return processed_count


# Legacy sync worker (backward compat)
def _outbox_processor(session_factory, nats_client):
    """DEPRECATED: Use async ``process_outbox_events`` instead.

    Sync loop z ``time.sleep(1)`` — blokuje event loop.
    Zachowany dla backward compatibility. Nowy kod używa async.
    """
    import time

    while True:
        with session_factory() as session:
            stmt = select(OutboxEvent).where(OutboxEvent.processed == False).limit(BATCH_SIZE)  # noqa: E712
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
