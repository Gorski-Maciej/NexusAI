from __future__ import annotations

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from nexus_ai.db.models import OutboxEvent, OutboxStatus


def replay_dead_letter_events(session: Session, *, limit: int = 100) -> int:
    rows = session.execute(
        select(OutboxEvent.id)
        .where(OutboxEvent.status == OutboxStatus.DEAD_LETTER)
        .order_by(OutboxEvent.created_at.asc())
        .limit(limit)
    ).all()
    ids = [r[0] for r in rows]
    if not ids:
        return 0
    for event_id in ids:
        session.execute(
            text(f"UPDATE outbox_events SET status='{OutboxStatus.FAILED.value}', retry_count=0 WHERE id = :id"),
            {"id": event_id},
        )
    session.commit()
    return len(ids)
