"""
Outbox relay tasks — extracted from api/tasks.py.

Zawiera:
- relay_outbox_events: główne zadanie przekazywania eventów outbox
- _dispatch_outbox_event: helper do wysyłki eventu
- _refresh_cashflow_for_event: helper do odświeżenia cashflow
"""

from __future__ import annotations


import duckdb
import stamina
from sqlmodel import Session, text
from sqlalchemy import exc as sa_exc
from structlog import get_logger
from taskiq import Kicker, TaskiqDepends

from nexus_ai.api.cache import clear_cache_async
from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.di import get_db_session
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.db.analytics import DuckDBManager

logger = get_logger("nexus.api.tasks.outbox")

MAX_OUTBOX_RETRIES = 3


@broker.task(
    schedule=[{"cron": "*/1 * * * *"}],
    task_name="relay_outbox_events",
    labels={"service": "api", "operation": "outbox", "criticality": "high", "schedule": "1min"},
    timeout=120.0,
)
async def relay_outbox_events(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """Relay pending outbox events with atomic UPDATE semantics."""
    stale_timeout = 300
    await db.execute(
        text("""UPDATE outbox_events SET status = 'FAILED', processing_started_at = NULL
            WHERE status = 'PROCESSING' AND processing_started_at IS NOT NULL
            AND (strftime('%%s', 'now') - strftime('%%s', processing_started_at)) > :timeout"""),
        {"timeout": stale_timeout},
    )
    await db.execute(
        text("""UPDATE outbox_events SET status = 'PROCESSING', processing_started_at = CURRENT_TIMESTAMP
            WHERE id IN (SELECT id FROM outbox_events WHERE status IN ('PENDING', 'FAILED')
            AND processed = 0 AND COALESCE(retry_count, 0) < :max_retries ORDER BY created_at ASC LIMIT 100)"""),
        {"max_retries": MAX_OUTBOX_RETRIES},
    )
    rows = (
        (
            await db.execute(
                text(
                    "SELECT id, event_type, aggregate_id, payload, COALESCE(retry_count, 0) as retry_count FROM outbox_events WHERE status = 'PROCESSING' AND processing_started_at IS NOT NULL ORDER BY created_at ASC LIMIT 100"
                ),
            )
        )
        .mappings()
        .all()
    )

    for row in rows:
        try:
            await _dispatch_outbox_event(row)
            await db.execute(
                text(
                    "UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"
                ),
                {"id": row["id"]},
            )
        except Exception as exc:
            logger.exception("[OUTBOX] Failed to relay event id=%s: %s", row["id"], exc)
            new_retry_count = row["retry_count"] + 1
            is_dead_letter = new_retry_count >= MAX_OUTBOX_RETRIES
            if is_dead_letter:
                try:
                    await db.execute(
                        text("""INSERT OR IGNORE INTO dead_letter_events
                        (id, event_type, aggregate_id, payload, error_message, stack_trace, retry_count)
                        VALUES (:id, :event_type, :aggregate_id, :payload, :error_message, :stack_trace, :retry_count)"""),
                        {
                            "id": row["id"],
                            "event_type": row["event_type"],
                            "aggregate_id": row["aggregate_id"],
                            "payload": row["payload"],
                            "error_message": str(exc),
                            "stack_trace": __import__("traceback").format_exc(),
                            "retry_count": new_retry_count,
                        },
                    )
                except (ConnectionError, OSError) as dle:
                    logger.warning(
                        "[OUTBOX] Failed to write dead_letter_event (connection): %s", dle
                    )
                except Exception as dle:
                    logger.warning("[OUTBOX] Failed to write dead_letter_event: %s", dle)
            await db.execute(
                text("""UPDATE outbox_events SET retry_count = retry_count + 1, processing_started_at = NULL,
                status = CASE WHEN retry_count + 1 >= :max_retries THEN 'DEAD_LETTER' ELSE 'FAILED' END WHERE id = :id"""),
                {"id": row["id"], "max_retries": MAX_OUTBOX_RETRIES},
            )

    try:
        await db.execute(
            text("DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')")
        )
    except (sa_exc.OperationalError, sa_exc.ProgrammingError) as exc:
        logger.debug("[OUTBOX] processed_events table may not exist: %s", exc)
    except Exception as exc:
        logger.warning("[OUTBOX] Error cleaning processed_events: %s", exc)


async def _dispatch_outbox_event(row: dict) -> None:
    """Dispatch a single outbox event to the appropriate Taskiq task."""
    event_type = str(row.get("event_type", "")).strip().lower()
    payload_raw = row.get("payload") or "{}"
    try:
        payload = msgspec_loads(payload_raw)
    except (ValueError, TypeError, DecodeError) as exc:
        logger.warning(
            "[OUTBOX] Failed to parse payload for event %s: %s", row.get("id", "unknown"), exc
        )
        payload = {}
    except Exception as exc:
        logger.error(
            "[OUTBOX] Unexpected error parsing payload for event %s: %s",
            row.get("id", "unknown"),
            exc,
        )
        payload = {}

    if event_type in ("process_invoice_ocr", "invoice_uploaded"):
        invoice_id = payload.get("invoice_id") or row.get("aggregate_id")
        if not invoice_id:
            raise ValueError("Missing invoice_id in outbox payload")
        task_id = f"outbox:ocr:{invoice_id}:{row.get('id', 'unknown')}"
        try:
            for attempt in stamina.retry_context(
                on=(Exception,), attempts=3, timeout=10.0, circuit_breaker=True
            ):
                with attempt:
                    await (
                        Kicker("process_invoice_ocr", broker=broker)
                        .with_task_id(task_id)
                        .kiq(invoice_id=str(invoice_id), payload=payload)
                    )
        except Exception as exc:
            logger.warning("[OUTBOX] Kicker failed after retries: %s", exc)
            raise
        return

    if event_type == "attachment_large_uploaded":
        attachment_id = payload.get("attachment_id") or row.get("aggregate_id")
        if not attachment_id:
            raise ValueError("Missing attachment_id in outbox payload")
        task_id = f"outbox:attachment:{attachment_id}:{row.get('id', 'unknown')}"
        try:
            for attempt in stamina.retry_context(
                on=(Exception,), attempts=3, timeout=10.0, circuit_breaker=True
            ):
                with attempt:
                    await (
                        Kicker("process_large_attachment", broker=broker)
                        .with_task_id(task_id)
                        .kiq(attachment_id=str(attachment_id), payload=payload)
                    )
        except Exception as exc:
            logger.warning("[OUTBOX] Kicker failed after retries: %s", exc)
            raise
        return

    if event_type == "tax_calculated":
        from nexus_ai.tax.audit import ensure_schema as ensure_tax_schema
        from nexus_ai.tax.pipeline import TaxPipeline
        from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

        transaction_id = payload.get("transaction_id", "")
        if not transaction_id:
            raise ValueError("Missing transaction_id in TAX_CALCULATED payload")
        net_grosze = int(payload.get("net_grosze", 0))
        vat_grosze = int(payload.get("vat_grosze", 0))
        brutto_grosze = int(payload.get("brutto_grosze", 0))
        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        ensure_tax_schema(conn)
        tb = TigerBeetleClient()
        pipeline = TaxPipeline(conn=conn, tigerbeetle=tb)
        try:
            tb_result = await pipeline.post_to_tigerbeetle(
                net_grosze=net_grosze,
                vat_grosze=vat_grosze,
                brutto_grosze=brutto_grosze,
                source_document_id=transaction_id,
            )
            logger.info(
                "[OUTBOX] TAX_CALCULATED posted tid=%s status=%s",
                transaction_id,
                tb_result.get("status"),
            )
        except Exception as exc:
            logger.exception(
                "[OUTBOX] TAX_CALCULATED TB posting failed tid=%s: %s", transaction_id, exc
            )
            raise
        finally:
            conn.close()
        return

    raise ValueError(f"Unsupported outbox event_type: {event_type}")


async def _refresh_cashflow_for_event(duckdb: DuckDBManager | None = None) -> None:
    """Refresh materialized cashflow view after event processing."""
    if duckdb is None:
        duckdb = DuckDBManager(db_path=AppConfig().duckdb_path, sqlite_path=AppConfig().sqlite_path)
        _owns_duckdb = True
    else:
        _owns_duckdb = False
    try:
        duckdb.refresh_materialized_cashflow()
    finally:
        if _owns_duckdb:
            duckdb.close()
    await clear_cache_async(prefix="api.routes.analytics")
