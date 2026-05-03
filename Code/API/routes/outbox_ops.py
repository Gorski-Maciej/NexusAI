from __future__ import annotations

from litestar import Controller, get, post
from sqlalchemy import text

from api.rbac import owner_only_guard
from core.config import AppConfig
from db.database import create_oltp_engine, create_session_factory
from services.outbox_replay import replay_dead_letter_events


class OutboxOpsController(Controller):
    """Operational outbox controls (dead-letter visibility and replay)."""

    path = "/api/v1/system/outbox"
    guards = [owner_only_guard]

    @get("/stats")
    async def stats(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)
        try:
            async with session_factory() as session:
                pending = int((await session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status='PENDING'"))).scalar_one())
                failed = int((await session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status='FAILED'"))).scalar_one())
                dead = int((await session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status='DEAD_LETTER'"))).scalar_one())
            return {"pending": pending, "failed": failed, "dead_letter": dead}
        finally:
            await engine.dispose()

    @post("/replay-dead-letter")
    async def replay_dead_letter(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)
        try:
            async with session_factory() as session:
                moved = await replay_dead_letter_events(session, limit=config.outbox_replay_limit)
            return {"replayed": int(moved)}
        finally:
            await engine.dispose()
