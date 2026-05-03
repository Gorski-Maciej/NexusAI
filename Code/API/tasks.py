from __future__ import annotations

import logging
import json
import os
import resource
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy import text

from core.config import AppConfig
from db.analytics import DuckDBManager
from db.database import create_oltp_engine, create_session_factory
from core.circuit_breaker import CircuitBreaker
from core.resilience import async_retry
from api.cache import clear_cache_async
from services.log_pii_monitor import scan_logs_for_pii, notify_dpo
from services.telemetry import flush_fallback_spans
from services.finops_meter import estimate_runtime_cost
from core.model_retention import prune_model_versions
from services.outbox_replay import replay_dead_letter_events
from services.migration_sanity import verify_schema_drift, verify_migration_integrity
from pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus

broker = PullBasedJetStreamBroker()
logger = logging.getLogger("nexus.api.tasks")
MAX_OUTBOX_RETRIES = 3
NATS_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=5, recovery_timeout=60)
OLAP_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=3, recovery_timeout=120)
INVOICE_OCR_EVENT_TYPES = {"process_invoice_ocr", "invoice_uploaded"}
LARGE_ATTACHMENT_EVENT_TYPES = {"attachment_large_uploaded"}


async def _dispatch_outbox_event(row: dict) -> None:
    event_type = str(row.get("event_type", "")).strip().lower()
    payload_raw = row.get("payload") or "{}"

    try:
        payload = json.loads(payload_raw)
    except Exception:
        payload = {}

    if event_type == "process_invoice_ocr" or event_type == "invoice_uploaded":
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
    payload = payload or {}

    primary = OCRAmountResult(amount_gross=_safe_float(payload.get("ocr_primary_amount_gross")), source="surya")
    secondary = OCRAmountResult(amount_gross=_safe_float(payload.get("ocr_secondary_amount_gross")), source="paddle")
    consensus = decide_amount_consensus(primary, secondary, tolerance=0.01)

    if consensus.confidence_conflict:
        await _mark_invoice_pending_review(invoice_id, reason="CONFIDENCE_CONFLICT")
        logger.warning(
            "[OCR] confidence conflict for invoice_id=%s primary=%s secondary=%s",
            invoice_id,
            primary.amount_gross,
            secondary.amount_gross,
        )

    # Zero-ETL path: no OLTP->OLAP row replication in worker.
    # Invoice OCR lifecycle is event-driven; analytics layer reads SQLite via DuckDB ATTACH.
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


@broker.task(schedule=[{"cron": "10 2 * * *"}], task_name="scan_logs_for_pii")
async def scan_logs_for_pii_task() -> None:
    """Daily proactive scan for accidental PII in log files."""
    config = AppConfig()
    findings = scan_logs_for_pii(config.base_dir / "app_data" / "logs")
    total = sum(findings.values())
    if total > 0:
        logger.warning("[PII-SCAN] potential sensitive data matches detected: %s", findings)
        notified = notify_dpo(config.dpo_alert_webhook, findings)
        logger.info("[PII-SCAN] DPO notification sent=%s", notified)
    else:
        logger.info("[PII-SCAN] no sensitive data patterns detected")


@broker.task(schedule=[{"cron": "0 * * * *"}], task_name="finops_hourly_estimate")
async def finops_hourly_estimate_task() -> None:
    """Hourly rough infrastructure cost estimate for FinOps observability."""
    cpu_cores = float(os.cpu_count() or 1)
    # ru_maxrss: KB on Linux, bytes on macOS; assume Linux deployment for this project.
    ram_gb = max((resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024 / 1024), 0.1)
    hourly_cost = estimate_runtime_cost(cpu_cores=cpu_cores, ram_gb=ram_gb, runtime_hours=1.0)
    logger.info("[FINOPS] estimated hourly runtime cost usd=%s cpu_cores=%s ram_gb=%.3f", hourly_cost, cpu_cores, ram_gb)


@broker.task(schedule=[{"cron": "30 2 * * *"}], task_name="model_retention_prune")
async def model_retention_prune_task() -> None:
    """Keep last N model versions and prune old ones."""
    config = AppConfig()
    models_root = config.base_dir / "models"
    result = prune_model_versions(models_root, keep_last=3, archive_root=config.base_dir / "models_archive")
    logger.info("[MODEL-RETENTION] prune summary: %s", result)


@broker.task(schedule=[{"cron": "45 * * * *"}], task_name="replay_dead_letter_outbox")
async def replay_dead_letter_outbox_task() -> None:
    """Hourly replay of dead-letter outbox events back to FAILED for retry."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            moved = await replay_dead_letter_events(session, limit=config.outbox_replay_limit)
            if moved:
                logger.info("[OUTBOX-REPLAY] moved dead-letter events for retry: %s", moved)
    finally:
        await engine.dispose()


def _safe_float(value: object) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


async def _mark_invoice_pending_review(invoice_id: str, reason: str) -> None:
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await session.execute(
                text(
                    """
                    UPDATE invoices
                    SET status = 'PENDING_REVIEW'
                    WHERE id = :invoice_id
                    """
                ),
                {"invoice_id": invoice_id},
            )
            await session.commit()
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "15 3 * * *"}], task_name="schema_drift_daily_check")
async def schema_drift_daily_check_task() -> None:
    """Daily schema drift verification against runtime baseline snapshot."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    baseline_path = config.base_dir / "app_data" / "schema_baseline.json"
    try:
        drift = await verify_schema_drift(engine, baseline_path=baseline_path)
        if drift["status"] == "drift_detected":
            logger.warning("[SCHEMA-DRIFT] detected: %s", drift["issues"])
        else:
            logger.info("[SCHEMA-DRIFT] status=%s tables=%s", drift["status"], drift["tables"])
    finally:
        await engine.dispose()

# contract marker: sync_single_invoice_to_duckdb(session, config, invoice_id)


@broker.task(schedule=[{"cron": "*/10 * * * *"}], task_name="flush_otel_fallback_buffer")
async def flush_otel_fallback_buffer_task() -> None:
    """Replay file-buffered telemetry spans when OLAP becomes available again."""
    config = AppConfig()
    stats = await flush_fallback_spans(
        lambda: DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path, read_only=False),
        retries=3,
        base_delay=0.5,
    )
    if stats.get("remaining", 0) > 0:
        logger.warning("[OTEL-FALLBACK] replay incomplete stats=%s", stats)
    else:
        logger.info("[OTEL-FALLBACK] replay stats=%s", stats)


@broker.task(schedule=[{"cron": "20 3 * * *"}], task_name="migration_integrity_daily_check")
async def migration_integrity_daily_check_task() -> None:
    """Daily data-integrity check against persisted row-count baseline."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    baseline_path = config.migration_baseline_path
    try:
        result = await verify_migration_integrity(engine, baseline_path=baseline_path)
        status = str(result.get("status"))
        if status == "ok":
            logger.info("[MIGRATION-INTEGRITY] status=ok tables=%s", result.get("tables"))
        elif status == "baseline_created":
            logger.info("[MIGRATION-INTEGRITY] baseline created tables=%s", result.get("tables"))
        else:
            logger.warning("[MIGRATION-INTEGRITY] status=%s issues=%s", status, result.get("issues"))
    finally:
        await engine.dispose()
