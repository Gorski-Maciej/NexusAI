"""
Transactions — transactional outbox pattern + async worker.

Łączy db/outbox.py i db/transaction.py w jeden moduł.
Transactional Outbox: gwarantowana dostawa zdarzeń przez tę samą transakcję co dane.
Używa with_for_update(skip_locked=True) dla pessimistic locking.
"""

from __future__ import annotations

from typing import Any

import pendulum
from sqlmodel import select, Session
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import OutboxEvent, OutboxStatus

logger = get_logger("nexus.db.transactions")
BATCH_SIZE = 100


class OutboxManager:
    """Transactional Outbox — gwarantowana dostawa zdarzeń."""

    @staticmethod
    def publish(
        session: Session, event_type: str, payload: dict[str, Any], aggregate_id: str
    ) -> None:
        """Zapisz zdarzenie w tej samej transakcji co dane biznesowe."""
        session.add(
            OutboxEvent(
                event_type=event_type,
                aggregate_id=aggregate_id,
                payload=msgspec_dumps(payload, ensure_ascii=False),
                status=OutboxStatus.PENDING,
                created_at=pendulum.now("UTC"),
            )
        )


async def process_events(
    async_session_factory, nats_client, *, batch_size: int = BATCH_SIZE
) -> int:
    """Przetwarzaj partię zdarzeń outbox z pessimistic locking.

    SUPERMOCE: with_for_update(skip_locked=True) — blokuje wiersze,
    pomija już zablokowane. order_by(created_at): FIFO.
    """
    async with async_session_factory() as session:
        stmt = (
            select(OutboxEvent)
            .where(OutboxEvent.processed == False)  # noqa: E712
            .order_by(OutboxEvent.created_at.asc())
            .limit(batch_size)
            .with_for_update(skip_locked=True)
            .execution_options(populate_existing=True)
        )
        events = (await session.execute(stmt)).scalars().all()
        if not events:
            return 0

        processed = 0
        for event in events:
            try:
                event.status = OutboxStatus.PROCESSING
                event.processing_started_at = pendulum.now("UTC")
                await session.flush()
                await nats_client.publish(f"outbox.{event.event_type}", event.payload.encode())
                event.processed = True
                event.processed_at = pendulum.now("UTC")
                event.status = OutboxStatus.PROCESSED
                processed += 1
            except (ConnectionError, TimeoutError, OSError) as exc:
                logger.warning("[OUTBOX] Transient error: %s", exc)
                event.retry_count += 1
                event.status = OutboxStatus.FAILED
                if event.retry_count >= 5:
                    event.status = OutboxStatus.DEAD_LETTER
            except Exception as exc:
                logger.error("[OUTBOX] Unexpected error: %s", exc)
                event.retry_count += 1
                event.status = OutboxStatus.FAILED
                if event.retry_count >= 5:
                    event.status = OutboxStatus.DEAD_LETTER
        await session.commit()
        return processed
