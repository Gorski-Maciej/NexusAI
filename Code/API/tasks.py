from __future__ import annotations

import logging
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy import text

from core.config import AppConfig
from db.replication import sync_single_invoice_to_duckdb, sync_sqlite_to_duckdb
from db.database import create_oltp_engine, create_session_factory

broker = PullBasedJetStreamBroker()
logger = logging.getLogger("nexus.api.tasks")


@broker.task(schedule=[{"cron": "*/5 * * * *"}])
async def run_data_replication() -> None:
    """Periodic full sync OLTP -> OLAP."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    async with session_factory() as session:
        result = await sync_sqlite_to_duckdb(session, config)
        logger.info("[REPLICATION] Status=%s rows=%s", result.get("status"), result.get("synced_rows", 0))
    await engine.dispose()


@broker.task(task_name="sync_single_invoice_to_olap")
async def sync_single_invoice_to_olap(invoice_id: str) -> None:
    """Near-real-time single-invoice sync after OCR/processing commit."""
    logger.info("[REPLICATION] queued single-invoice sync for invoice_id=%s", invoice_id)
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    async with session_factory() as session:
        result = await sync_single_invoice_to_duckdb(session, config, invoice_id)
        logger.info("[REPLICATION] single invoice sync status=%s invoice_id=%s", result.get("status"), invoice_id)
    await engine.dispose()


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="relay_outbox_events")
async def relay_outbox_events() -> None:
    """Relay pending outbox events in a separate worker loop."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)

    async with session_factory() as session:
        rows = (
            await session.execute(
                text(
                    """
                    SELECT id, event_type, aggregate_id, payload
                    FROM outbox_events
                    WHERE status = 'PENDING' AND processed = 0
                    ORDER BY created_at ASC
                    LIMIT 100
                    """
                )
            )
        ).mappings().all()

        for row in rows:
            await session.execute(
                text("UPDATE outbox_events SET status = 'PROCESSING' WHERE id = :id AND status = 'PENDING'"),
                {"id": row["id"]},
            )
            try:
                await broker.kick("sync_single_invoice_to_olap", invoice_id=row["aggregate_id"])
                await session.execute(
                    text("UPDATE outbox_events SET status = 'SENT', processed = 1 WHERE id = :id"),
                    {"id": row["id"]},
                )
            except Exception as exc:
                logger.exception("[OUTBOX] Failed to relay event id=%s: %s", row["id"], exc)
                await session.execute(
                    text("UPDATE outbox_events SET status = 'FAILED' WHERE id = :id"),
                    {"id": row["id"]},
                )

        await session.commit()

    await engine.dispose()
