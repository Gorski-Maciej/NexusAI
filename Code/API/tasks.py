from __future__ import annotations

import logging
import json
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy import text

from core.config import AppConfig
from db.replication import sync_single_invoice_to_duckdb, sync_sqlite_to_duckdb
from db.database import create_oltp_engine, create_session_factory

broker = PullBasedJetStreamBroker()
logger = logging.getLogger("nexus.api.tasks")
MAX_OUTBOX_RETRIES = 3


async def _dispatch_outbox_event(row: dict) -> None:
    event_type = str(row.get("event_type", "")).strip().lower()
    payload_raw = row.get("payload") or "{}"

    try:
        payload = json.loads(payload_raw)
    except Exception:
        payload = {}

    if event_type == "process_invoice_ocr":
        invoice_id = payload.get("invoice_id") or row.get("aggregate_id")
        if not invoice_id:
            raise ValueError("Missing invoice_id in outbox payload")
        await broker.kick("process_invoice_ocr", invoice_id=str(invoice_id), payload=payload)
        return

    raise ValueError(f"Unsupported outbox event_type: {event_type}")


@broker.task(task_name="process_invoice_ocr")
async def process_invoice_ocr(invoice_id: str, payload: dict | None = None) -> None:
    """Dedicated OCR pipeline entrypoint triggered by outbox relay."""
    logger.info("[OCR] processing invoice_id=%s", invoice_id)

    # Placeholder for OCR worker orchestration; after successful OCR write,
    # trigger near-real-time OLAP delta sync for dashboard freshness.
    await broker.kick("sync_single_invoice_to_olap", invoice_id=invoice_id)


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
                    WHERE status IN ('PENDING', 'FAILED')
                      AND processed = 0
                      AND COALESCE(retry_count, 0) < :max_retries
                    ORDER BY created_at ASC
                    LIMIT 100
                    """
                ),
                {"max_retries": MAX_OUTBOX_RETRIES},
            )
        ).mappings().all()

        for row in rows:
            await session.execute(
                text("UPDATE outbox_events SET status = 'PROCESSING' WHERE id = :id AND status = 'PENDING'"),
                {"id": row["id"]},
            )
            try:
                await _dispatch_outbox_event(row)
                await session.execute(
                    text("UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"),
                    {"id": row["id"]},
                )
            except Exception as exc:
                logger.exception("[OUTBOX] Failed to relay event id=%s: %s", row["id"], exc)
                await session.execute(
                    text(
                        """
                        UPDATE outbox_events
                        SET retry_count = retry_count + 1,
                            status = CASE
                                WHEN retry_count + 1 >= :max_retries THEN 'DEAD_LETTER'
                                ELSE 'FAILED'
                            END
                        WHERE id = :id
                        """
                    ),
                    {"id": row["id"], "max_retries": MAX_OUTBOX_RETRIES},
                )

        await session.commit()

    await engine.dispose()
