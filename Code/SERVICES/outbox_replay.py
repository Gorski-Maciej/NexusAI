from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def replay_dead_letter_events(session: AsyncSession, *, limit: int = 100) -> int:
    rows = (
        await session.execute(
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
        await session.execute(
            text("UPDATE outbox_events SET status='FAILED', retry_count=0 WHERE id = :id"),
            {"id": event_id},
        )
    await session.commit()
    return len(ids)
