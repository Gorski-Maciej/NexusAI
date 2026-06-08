from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.orm import Session


def replay_dead_letter_events(session: Session, *, limit: int = 100) -> int:
    rows = (
        session.execute(
            text(
                """
                SELECT id FROM outbox_events
                WHERE status = 'DEAD_LETTER'
                ORDER BY created_at ASC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        )
    ).all()
    ids = [r[0] for r in rows]
    if not ids:
        return 0
    for event_id in ids:
        session.execute(
            text("UPDATE outbox_events SET status='FAILED', retry_count=0 WHERE id = :id"),
            {"id": event_id},
        )
    session.commit()
    return len(ids)
