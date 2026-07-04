from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import HTTPException
from structlog import get_logger

from nexus_ai.api.dto import (
    TAG_SYSTEM,
    OutboxProcessResponseDTO,
    OutboxReplayResponseDTO,
    OutboxStatsDTO,
)
from nexus_ai.api.rbac import owner_only_guard

logger = get_logger("nexus.api.outbox_ops")


class OutboxOpsController(Controller):
    """Operational outbox controls -- stats, process trigger, and dead-letter replay.

    **DEPRECATED**: Funkcjonalność zastąpiona przez NATS JetStream:
      - Publikacja zdarzeń -> NATS JetStream (nexus-outbox stream)
      - Retry i DLQ -> ConsumerConfig.max_deliver=5 + JetStream DLQ
      - Monitorowanie -> NatsSupervisor w nats_health.py

    Endpointy pozostawione jako pasywne wrappery SQL (stats).
    Procesowanie i replay zlecone NATS JetStream.
    """

    path = "/system/outbox"
    guards = (owner_only_guard,)
    tags = (TAG_SYSTEM,)

    # ── GET /stats -- statystyki z SQL (pasywne, bez relaya) ───────────

    @get(
        "/stats",
        return_dto=OutboxStatsDTO,
        summary="Get outbox stats",
        description="Returns detailed outbox event statistics including pending, processing, failed, and dead-letter counts.",
        operation_id="getOutboxStats",
    )
    async def stats(self, request: Request) -> dict:
        """Zwróć szczegółowe statystyki outbox z SQL.

        **Odpowiedź JSON:**
        .. code-block:: json

            {
                "pending": 5,
                "failed": 1,
                "dead_letter": 2
            }
        """
        from sqlmodel import func, select

        from core.config import AppConfig
        from db.database import create_oltp_engine, create_session_factory
        from nexus_ai.db.models import OutboxEvent, OutboxStatus

        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)
        try:
            async with session_factory() as session:
                pending = int(
                    (
                        await session.execute(
                            select(func.count())
                            .select_from(OutboxEvent)
                            .where(OutboxEvent.status == OutboxStatus.PENDING)
                        )
                    ).scalar_one()
                )
                failed = int(
                    (
                        await session.execute(
                            select(func.count())
                            .select_from(OutboxEvent)
                            .where(OutboxEvent.status == OutboxStatus.FAILED)
                        )
                    ).scalar_one()
                )
                dead = int(
                    (
                        await session.execute(
                            select(func.count())
                            .select_from(OutboxEvent)
                            .where(OutboxEvent.status == OutboxStatus.DEAD_LETTER)
                        )
                    ).scalar_one()
                )
                return {"pending": pending, "failed": failed, "dead_letter": dead}
        finally:
            await engine.dispose()

    # ── POST /process -- placeholder (zastąpione przez NATS JetStream) ──

    @post(
        "/process",
        return_dto=OutboxProcessResponseDTO,
        summary="Trigger outbox processing -- DEPRECATED",
        description="DEPRECATED: Outbox processing is now handled by NATS JetStream. This endpoint is kept for compatibility.",
        operation_id="triggerOutboxProcessing",
    )
    async def process(self, request: Request) -> dict:
        """DEPRECATED: Zastąpione przez NATS JetStream.

        **Kody błędów:**
           - ``410`` -- GONE, użyj NATS JetStream
        """
        raise HTTPException(
            status_code=410,
            detail="Outbox relay processing is now handled by NATS JetStream. See docs for migration.",
        )

    # ── POST /replay-dead-letter -- placeholder ────────────────────────

    @post(
        "/replay-dead-letter",
        return_dto=OutboxReplayResponseDTO,
        summary="Replay dead-letter events -- DEPRECATED",
        description="DEPRECATED: Dead-letter replay is now handled by NATS JetStream DLQ (ConsumerConfig.max_deliver).",
        operation_id="replayDeadLetterOutbox",
    )
    async def replay_dead_letter(self, request: Request) -> dict:
        """DEPRECATED: Zastąpione przez NATS JetStream DLQ.

        **Kody błędów:**
           - ``410`` -- GONE, użyj NATS JetStream
        """
        raise HTTPException(
            status_code=410,
            detail="Dead-letter replay is now handled by NATS JetStream DLQ. See docs for migration.",
        )
