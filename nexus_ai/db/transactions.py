"""
Transactions -- transactional outbox pattern + async worker.

Łączy db/outbox.py i db/transaction.py w jeden moduł.
Transactional Outbox: gwarantowana dostawa zdarzeń przez tę samą transakcję co dane.
SQLite does NOT support SKIP LOCKED; we use atomic UPDATE ... RETURNING for optimistic claim.
"""

from __future__ import annotations

from typing import Any

import pendulum
from sqlmodel import Session, select, update
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import OutboxEvent, OutboxStatus

logger = get_logger("nexus.db.transactions")
BATCH_SIZE = 100


class OutboxManager:
    """Transactional Outbox -- gwarantowana dostawa zdarzeń."""
    __slots__ = ()

    @staticmethod
    def publish(
        session: Session, event_type: str, payload: dict[str, Any], aggregate_id: str
    ) -> None:
        """Zapisz zdarzenie w tej samej transakcji co dane biznesowe."""
        session.add(
            OutboxEvent(
                event_type=event_type,
                aggregate_id=aggregate_id,
                payload=payload,  # msgspec.Struct or dict — JSON column handles it
                status=OutboxStatus.PENDING,
                created_at=pendulum.now("UTC"),
            )
        )


async def process_events(
    async_session_factory, nats_client, *, batch_size: int = BATCH_SIZE
) -> int:
    """Przetwarzaj partię zdarzeń outbox z atomic optimistic claim.

    SQLite does not support SKIP LOCKED; we use UPDATE ... RETURNING
    to atomically claim a batch of pending events (FIFO by created_at).
    """
    now = pendulum.now("UTC")
    async with async_session_factory() as session:
        # Atomic claim via UPDATE ... RETURNING (SQLite 3.35+)
        claim_stmt = (
            update(OutboxEvent)
            .where(
                OutboxEvent.processed == False,  # noqa: E712
                OutboxEvent.status == OutboxStatus.PENDING,
            )
            .order_by(OutboxEvent.created_at.asc())
            .limit(batch_size)
            .values(status=OutboxStatus.PROCESSING, processing_started_at=now)
            .returning(OutboxEvent.id)
        )
        claimed_ids = (await session.execute(claim_stmt)).scalars().all()
        if not claimed_ids:
            return 0

        # Fetch full rows for the claimed IDs
        events = (
            await session.execute(
                select(OutboxEvent).where(OutboxEvent.id.in_(claimed_ids))
            )
        ).scalars().all()

        processed = 0
        for event in events:
            try:
                payload_bytes = msgspec_dumps(event.payload).encode("utf-8")
                await nats_client.publish(f"outbox.{event.event_type}", payload_bytes)
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
