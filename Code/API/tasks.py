from __future__ import annotations

import logging
import json
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy import text

from core.config import AppConfig
from db.analytics import DuckDBManager
from db.database import create_oltp_engine, create_session_factory
from db.replication import sync_single_invoice_to_duckdb
from core.circuit_breaker import CircuitBreaker
from core.resilience import async_retry
from api.cache import clear_cache_async

broker = PullBasedJetStreamBroker()
logger = logging.getLogger("nexus.api.tasks")
MAX_OUTBOX_RETRIES = 3
NATS_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=5, recovery_timeout=60)
OLAP_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=3, recovery_timeout=120)


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
        try:
            await broker.kick("process_invoice_ocr", invoice_id=str(invoice_id), payload=payload)
        except Exception as exc:
            NATS_CIRCUIT_BREAKER.record_failure(str(exc))
            raise
        NATS_CIRCUIT_BREAKER.record_success()
        return
    if event_type == "attachment_large_uploaded":
        attachment_id = payload.get("attachment_id") or row.get("aggregate_id")
        if not attachment_id:
            raise ValueError("Missing attachment_id in outbox payload")
        try:
            await broker.kick("process_large_attachment", attachment_id=str(attachment_id), payload=payload)
        except Exception as exc:
            NATS_CIRCUIT_BREAKER.record_failure(str(exc))
            raise
        NATS_CIRCUIT_BREAKER.record_success()
        return

    raise ValueError(f"Unsupported outbox event_type: {event_type}")


@broker.task(task_name="process_invoice_ocr")
async def process_invoice_ocr(invoice_id: str, payload: dict | None = None) -> None:
    """Dedicated OCR pipeline entrypoint triggered by outbox relay."""
    logger.info("[OCR] processing invoice_id=%s", invoice_id)

    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await sync_single_invoice_to_duckdb(session, config, invoice_id)
    except Exception as exc:
        logger.warning("[OCR] single-invoice OLAP sync failed for invoice_id=%s: %s", invoice_id, exc)
    finally:
        await engine.dispose()

    # Zero-ETL: no row replication; trigger lightweight OLAP materialization refresh.
    await OLAP_CIRCUIT_BREAKER.call(_refresh_cashflow_for_event)
    return


@broker.task(task_name="process_large_attachment")
async def process_large_attachment(attachment_id: str, payload: dict | None = None) -> None:
    """Dedicated worker path for large attachments uploaded via /upload-large."""
    logger.info("[ATTACHMENT] processing large attachment_id=%s payload=%s", attachment_id, bool(payload))
    return




@broker.task(schedule=[{"cron": "0 * * * *"}], task_name="refresh_materialized_cashflow")
@async_retry(max_retries=3, base_delay=1.0, max_delay=8.0)
async def refresh_materialized_cashflow() -> None:
    config = AppConfig()
    manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        await OLAP_CIRCUIT_BREAKER.call(_refresh_cashflow_materialized, manager)
    finally:
        manager.close()
    await clear_cache_async(prefix="api.routes.analytics")
    logger.info("[OLAP] refreshed m_daily_cashflow")




async def _refresh_cashflow_materialized(manager: DuckDBManager) -> None:
    manager.refresh_materialized_cashflow()


async def _refresh_cashflow_for_event() -> None:
    config = AppConfig()
    manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        manager.refresh_materialized_cashflow()
    finally:
        manager.close()
    await clear_cache_async(prefix="api.routes.analytics")


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
