from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import HTTPException
from litestar.status_codes import HTTP_500_INTERNAL_SERVER_ERROR, HTTP_503_SERVICE_UNAVAILABLE
from structlog import get_logger

from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.api.telemetry_metrics import record_outbox_relay_triggered

logger = get_logger("nexus.api.outbox_ops")


class OutboxOpsController(Controller):
    """Operational outbox controls — stats, process trigger, and dead-letter replay.

    Wykorzystuje **OutboxRelay** (Transactional Outbox) dla gwarantowanej dostawy
    zdarzeń do TigerBeetle.

    Endpointy:
      - ``GET  /stats``                → szczegółowe statystyki outbox
      - ``POST /process``              → ręczne wyzwolenie przetwarzania
      - ``POST /replay-dead-letter``   → przywrócenie DEAD_LETTER do FAILED
    """

    path = "/api/v1/system/outbox"
    guards = [owner_only_guard]
    tags = ["System"]

    # ── GET /stats — szczegółowe statystyki ─────────────────────────────

    @get("/stats")
    async def stats(self, request: Request) -> dict:
        """Zwróć szczegółowe statystyki outbox.

        Gdy ``OutboxRelay`` jest zainicjalizowany, używa ``relay.get_stats()``
        dla pełniejszych danych (wliczając ``processing``, ``sent``, ``total``,
        ``dead_letter_events_table``).

        Falls back do podstawowych zapytań SQL gdy relay nie jest dostępny.

        **Odpowiedź JSON:**
        .. code-block:: json

            {
                "pending": 5,
                "processing": 0,
                "failed": 1,
                "dead_letter": 2,
                "sent": 100,
                "total": 108,
                "dead_letter_events_table": 2
            }
        """
        relay = getattr(request.app.state, "outbox_relay", None)
        if relay is not None:
            return await relay.get_stats()

        # Fallback: podstawowe zapytania SQL bez OutboxRelay
        from sqlalchemy import text

        from core.config import AppConfig
        from db.database import create_oltp_engine, create_session_factory

        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)
        try:
            async with session_factory() as session:
                pending = int(
                    (await session.execute(
                        text("SELECT COUNT(*) FROM outbox_events WHERE status='PENDING'")
                    )).scalar_one()
                )
                failed = int(
                    (await session.execute(
                        text("SELECT COUNT(*) FROM outbox_events WHERE status='FAILED'")
                    )).scalar_one()
                )
                dead = int(
                    (await session.execute(
                        text("SELECT COUNT(*) FROM outbox_events WHERE status='DEAD_LETTER'")
                    )).scalar_one()
                )
                return {"pending": pending, "failed": failed, "dead_letter": dead}
        finally:
            await engine.dispose()

    # ── POST /process — ręczne wyzwolenie procesowania ─────────────────

    @post("/process")
    async def process(self, request: Request) -> dict:
        """Ręcznie wyzwól przetwarzanie oczekujących zdarzeń outbox.

        Używa ``OutboxRelay.process_pending()`` do pełnego cyklu:
          1. Odblokowanie stuck PROCESSING zdarzeń
          2. Atomowa rezerwacja PENDING/FAILED
          3. Dispatch do TigerBeetle (lub log w trybie dry-run)
          4. Idempotentność i DLQ

        **Odpowiedź JSON:**
        .. code-block:: json

            {
                "status": "OK",
                "processed": 5,
                "failed": 1,
                "dead_letter": 0,
                "skipped": 0,
                "total": 6,
                "processing_time_ms": 123.45
            }

        **Kody błędów:**
           - ``503`` — OutboxRelay not initialized
           - ``500`` — błąd przetwarzania
        """
        relay = getattr(request.app.state, "outbox_relay", None)
        if relay is None:
            raise HTTPException(
                status_code=HTTP_503_SERVICE_UNAVAILABLE,
                detail="OutboxRelay not initialized",
            )

        try:
            stats = await relay.process_pending()

            # Metryka Prometheus
            record_outbox_relay_triggered(stats.total)

            return {
                "status": "OK",
                "processed": stats.processed,
                "failed": stats.failed,
                "dead_letter": stats.dead_letter,
                "skipped": stats.skipped_idempotent,
                "total": stats.total,
                "processing_time_ms": round(stats.processing_time_ms, 2),
            }
        except Exception as exc:
            logger.exception("[OUTBOX-RELAY] Manual process trigger failed: %s", exc)
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Outbox relay processing failed",
            )

    # ── POST /replay-dead-letter — przywrócenie DLQ do FAILED ─────────

    @post("/replay-dead-letter")
    async def replay_dead_letter(self, request: Request) -> dict:
        """Przywróć zdarzenia DEAD_LETTER do statusu FAILED (do ponownej próby).

        Używa ``services.outbox_replay.replay_dead_letter_events()``
        z sesją z ``app.state.db_session_factory``.

        **Odpowiedź JSON:**
        .. code-block:: json

            {
                "replayed": 3
            }
        """
        from services.outbox_replay import replay_dead_letter_events

        session_factory = request.app.state.db_session_factory
        try:
            async with session_factory() as session:
                moved = await replay_dead_letter_events(session, limit=100)
            return {"replayed": int(moved)}
        except Exception as exc:
            logger.exception("[OUTBOX-REPLAY] Dead-letter replay failed: %s", exc)
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Dead-letter replay failed",
            )
