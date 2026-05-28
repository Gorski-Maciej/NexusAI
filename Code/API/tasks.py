from __future__ import annotations

import atexit
import logging
import json
import os
import resource
from pathlib import Path
from datetime import datetime, timedelta
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
from services.autopilot import CouncilOrchestrator
from services.council_agents import AlphaAgent, BetaAgent, GammaAgent, ModelManager
from services.decision_logger import DecisionLogger
from services.rules_agent import RulesAgent
from services.analytics_agent import AnalyticsAgent, FinDetective
from services.decision_agent import DecisionOrchestrator, JambaStrategist, GraniteExecutor

broker = PullBasedJetStreamBroker()
logger = logging.getLogger("nexus.api.tasks")
MAX_OUTBOX_RETRIES = 3
NATS_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=5, recovery_timeout=60)
OLAP_CIRCUIT_BREAKER = CircuitBreaker(failure_threshold=3, recovery_timeout=120)
INVOICE_OCR_EVENT_TYPES = {"process_invoice_ocr", "invoice_uploaded"}
LARGE_ATTACHMENT_EVENT_TYPES = {"attachment_large_uploaded"}


# Singleton instances for council agents (lazy init, shared across tasks)
_COUNCIL_MANAGER: ModelManager | None = None
_COUNCIL_ORCHESTRATOR: CouncilOrchestrator | None = None
_COUNCIL_DECISION_LOGGER: DecisionLogger | None = None
_COUNCIL_DUCKDB: DuckDBManager | None = None

# Singleton for Rules Agent
_RULES_AGENT: RulesAgent | None = None

# Singleton for Analytics Agent
_ANALYTICS_AGENT: AnalyticsAgent | None = None
_FIN_DETECTIVE: FinDetective | None = None

# Singleton for Decision Agent
_DECISION_ORCHESTRATOR: DecisionOrchestrator | None = None


def _ensure_council_components(config: AppConfig) -> tuple[ModelManager, CouncilOrchestrator, DecisionLogger]:
    """Lazy-init council components as module-level singletons."""
    global _COUNCIL_MANAGER, _COUNCIL_ORCHESTRATOR, _COUNCIL_DECISION_LOGGER, _COUNCIL_DUCKDB

    if _COUNCIL_ORCHESTRATOR is not None:
        return _COUNCIL_MANAGER, _COUNCIL_ORCHESTRATOR, _COUNCIL_DECISION_LOGGER  # type: ignore[return-value]

    _COUNCIL_DUCKDB = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    decision_logger = DecisionLogger(_COUNCIL_DUCKDB)
    manager = ModelManager(config)
    alpha = AlphaAgent("alpha", config.council_alpha_model_path, manager)
    beta = BetaAgent("beta", config.council_beta_model_path, manager)
    gamma = GammaAgent("gamma", config.council_gamma_model_path, manager)
    orchestrator = CouncilOrchestrator(
        model_manager=manager,
        alpha=alpha,
        beta=beta,
        gamma=gamma,
        decision_logger=decision_logger,
        config=config,
    )

    _COUNCIL_MANAGER = manager
    _COUNCIL_ORCHESTRATOR = orchestrator
    _COUNCIL_DECISION_LOGGER = decision_logger
    return manager, orchestrator, decision_logger


def _close_council_components() -> None:
    """Cleanup council DuckDB connection on shutdown."""
    global _COUNCIL_DUCKDB
    if _COUNCIL_DUCKDB is not None:
        try:
            _COUNCIL_DUCKDB.close()
        except Exception:
            pass
        _COUNCIL_DUCKDB = None


def _ensure_rules_agent(config: AppConfig, manager: ModelManager) -> RulesAgent:
    """Lazy-init RulesAgent as module-level singleton.
    Shares ModelManager with Council agents for RAM mutual exclusion.
    """
    global _RULES_AGENT
    if _RULES_AGENT is None:
        _RULES_AGENT = RulesAgent(
            model_name="rules",
            model_path=config.rules_model_path,
            model_manager=manager,
            config=config,
        )
    return _RULES_AGENT


def _ensure_analytics_agent(config: AppConfig, manager: ModelManager) -> AnalyticsAgent:
    """Lazy-init AnalyticsAgent as module-level singleton.
    Shares ModelManager with Council agents for RAM mutual exclusion.
    """
    global _ANALYTICS_AGENT
    if _ANALYTICS_AGENT is None:
        _ANALYTICS_AGENT = AnalyticsAgent(
            model_name="analytics",
            model_path=config.analytics_model_path,
            model_manager=manager,
            config=config,
        )
    return _ANALYTICS_AGENT


def _ensure_fin_detective(config: AppConfig) -> FinDetective:
    """Lazy-init FinDetective as module-level singleton.
    Fin-RWKV uses PyTorch (not llama-cpp), so it does NOT share ModelManager.
    """
    global _FIN_DETECTIVE
    if _FIN_DETECTIVE is None:
        _FIN_DETECTIVE = FinDetective(
            model_path=config.fin_detective_model_path,
            config=config,
        )
    return _FIN_DETECTIVE


def _ensure_decision_agent(config: AppConfig, manager: ModelManager) -> DecisionOrchestrator:
    """Lazy-init DecisionOrchestrator as module-level singleton.
    Shares ModelManager with all other agents for RAM mutual exclusion.
    """
    global _DECISION_ORCHESTRATOR
    if _DECISION_ORCHESTRATOR is None:
        jamba = JambaStrategist(
            model_name="jamba",
            model_path=config.decision_jamba_model_path,
            model_manager=manager,
            config=config,
        )
        granite = GraniteExecutor(
            model_name="granite_executor",
            model_path=config.decision_granite_model_path,
            model_manager=manager,
            config=config,
        )
        _DECISION_ORCHESTRATOR = DecisionOrchestrator(
            jamba_strategist=jamba,
            granite_executor=granite,
            config=config,
        )
    return _DECISION_ORCHESTRATOR


def _close_all_components() -> None:
    """Cleanup all singleton components on shutdown."""
    _close_council_components()


atexit.register(_close_all_components)


@broker.task(task_name="analytics_run")
async def analytics_run(invoice_id: str, extracted_data: dict) -> dict:
    """
    Analytics & trend analysis triggered after OCR extraction.
    Runs Qwen2.5-1.5B analysis + Fin-RWKV anomaly detection.
    Shares ModelManager with Council agents for RAM mutual exclusion.
    Publishes result to invoice.analytics_result topic.
    """
    config = AppConfig()
    manager, _, _ = _ensure_council_components(config)
    agent = _ensure_analytics_agent(config, manager)
    detective = _ensure_fin_detective(config)

    logger.info("[ANALYTICS] running analysis for invoice_id=%s", invoice_id)

    try:
        # Extract vendor history from extracted_data if available
        vendor_history = extracted_data.get("vendor_profile", {})

        # Run both analyses concurrently
        analysis_task = agent.analyze(
            invoice_data=extracted_data,
            vendor_history=vendor_history,
        )
        detection_task = detective.detect_anomalies(extracted_data)

        analysis_result, ml_anomalies = await asyncio.gather(
            analysis_task, detection_task,
        )

        # Merge ML anomalies into analysis result
        all_anomalies = analysis_result.get("anomalies", []) + ml_anomalies
        analysis_result["anomalies"] = all_anomalies

        logger.info(
            "[ANALYTICS] invoice_id=%s trends=%d anomalies=%d confidence=%.4f",
            invoice_id,
            len(analysis_result.get("trends", [])),
            len(all_anomalies),
            analysis_result.get("confidence", 0.0),
        )

        # Publish result to NATS
        try:
            import nats
            nc = await nats.connect(config.nats_url)
            await nc.publish(
                "invoice.analytics_result",
                json.dumps({
                    "invoice_id": invoice_id,
                    "trends": analysis_result.get("trends", []),
                    "anomalies": all_anomalies,
                    "summary": analysis_result.get("summary", ""),
                    "confidence": analysis_result.get("confidence", 0.0),
                }).encode(),
            )
            await nc.close()
        except Exception as pub_err:
            logger.warning("[ANALYTICS] failed to publish result to NATS: %s", pub_err)

        return {
            "result": "OK",
            "invoice_id": invoice_id,
            "trends": analysis_result.get("trends", []),
            "anomalies": all_anomalies,
            "summary": analysis_result.get("summary", ""),
        }

    except Exception as exc:
        logger.exception("[ANALYTICS] analysis failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}


@broker.task(task_name="decision_evaluate")
async def decision_evaluate(invoice_id: str, extracted_data: dict) -> dict:
    """
    Final decision evaluation — the last step in the pipeline.
    Aggregates reports from Council, Rules, and Analytics agents,
    then runs Jamba 3B reasoning + optional Granite function calling
    to produce the ultimate decision.
    Subscribes to council.decision_required topic.
    Publishes result to invoice.decision.final topic.
    Shares ModelManager with all other agents for RAM mutual exclusion.
    """
    config = AppConfig()
    manager, council_orch, _ = _ensure_council_components(config)
    orchestrator = _ensure_decision_agent(config, manager)

    logger.info("[DECISION] evaluating final decision for invoice_id=%s", invoice_id)

    try:
        # Build reports from the extracted data context
        # (In production, these would be fetched from NATS or DuckDB)
        council_report = {
            "alpha_decision": extracted_data.get("council_alpha", "N/A"),
            "beta_decision": extracted_data.get("council_beta", "N/A"),
            "gamma_decision": extracted_data.get("council_gamma", "N/A"),
            "council_decision": extracted_data.get("council_final", "N/A"),
            "trust_score": extracted_data.get("council_trust_score"),
        }
        rules_report = {
            "passed": extracted_data.get("rules_passed"),
            "violations": extracted_data.get("rules_violations", []),
            "confidence": extracted_data.get("rules_confidence"),
        }
        analytics_report = {
            "trends": extracted_data.get("analytics_trends", []),
            "anomalies": extracted_data.get("analytics_anomalies", []),
            "summary": extracted_data.get("analytics_summary", ""),
            "confidence": extracted_data.get("analytics_confidence"),
        }

        final = await orchestrator.evaluate(
            invoice_id=invoice_id,
            extracted_data=extracted_data,
            council_report=council_report,
            rules_report=rules_report,
            analytics_report=analytics_report,
        )

        logger.info(
            "[DECISION] invoice_id=%s final=%s confidence=%.4f",
            invoice_id,
            final.decision,
            final.confidence,
        )

        # Execute action based on final decision
        if final.decision == "AUTO_POST":
            await _council_post_invoice(invoice_id, extracted_data, final)
        elif final.decision == "SUGGEST":
            await _council_mark_for_review(invoice_id, final)
        elif final.decision == "ESCALATE":
            await _council_escalate_to_human(invoice_id, final, reason="escalated by decision agent")

        # Publish final decision to NATS
        try:
            import nats
            nc = await nats.connect(config.nats_url)
            await nc.publish(
                "invoice.decision.final",
                json.dumps({
                    "invoice_id": invoice_id,
                    "decision": final.decision,
                    "confidence": final.confidence,
                    "reasoning": final.reasoning,
                    "strategy_summary": final.strategy_summary,
                }).encode(),
            )
            await nc.close()
        except Exception as pub_err:
            logger.warning("[DECISION] failed to publish to NATS: %s", pub_err)

        return {
            "result": "OK",
            "invoice_id": invoice_id,
            "decision": final.decision,
            "confidence": final.confidence,
            "reasoning": final.reasoning,
        }

    except Exception as exc:
        logger.exception("[DECISION] evaluation failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}


@broker.task(task_name="rules_check")
async def rules_check(invoice_id: str, extracted_data: dict) -> dict:
    """
    Rules & Compliance check triggered after OCR extraction.
    Subscribes to invoice.extracted topic.
    Publishes result to invoice.rules_result topic.
    Shares ModelManager with Council agents for RAM mutual exclusion.
    """
    config = AppConfig()
    manager, _, _ = _ensure_council_components(config)
    agent = _ensure_rules_agent(config, manager)

    logger.info("[RULES] checking invoice_id=%s", invoice_id)

    try:
        result = await agent.evaluate(extracted_data)

        logger.info(
            "[RULES] invoice_id=%s passed=%s confidence=%.4f violations=%d",
            invoice_id,
            result.get("passed"),
            result.get("confidence", 0.0),
            len(result.get("violations", [])),
        )

        # Publish result to NATS
        try:
            import nats
            nc = await nats.connect(config.nats_url)
            await nc.publish(
                "invoice.rules_result",
                json.dumps({
                    "invoice_id": invoice_id,
                    "passed": result.get("passed"),
                    "violations": result.get("violations", []),
                    "confidence": result.get("confidence", 0.0),
                    "reasoning": result.get("reasoning", ""),
                }).encode(),
            )
            await nc.close()
        except Exception as pub_err:
            logger.warning("[RULES] failed to publish result to NATS: %s", pub_err)

        return {
            "result": "OK",
            "invoice_id": invoice_id,
            "passed": result.get("passed"),
            "violations": result.get("violations", []),
        }

    except Exception as exc:
        logger.exception("[RULES] check failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}


@broker.task(task_name="council_decide")
async def council_decide(invoice_id: str, extracted_data: dict) -> dict:
    """Council of Agents decision task triggered after OCR extraction."""
    config = AppConfig()
    _, orchestrator, decision_logger = _ensure_council_components(config)

    logger.info("[COUNCIL] starting deliberation for invoice_id=%s", invoice_id)

    try:
        decision = await orchestrator.evaluate(
            invoice_id=invoice_id,
            invoice_data=extracted_data,
        )

        logger.info(
            "[COUNCIL] invoice_id=%s final=%s trust=%.4f",
            invoice_id,
            decision.decision,
            decision.trust_score,
        )

        # Execute action based on decision
        if decision.decision == "AUTO_POST":
            await _council_post_invoice(invoice_id, extracted_data, decision)
        elif decision.decision == "SUGGEST":
            await _council_mark_for_review(invoice_id, decision)
        elif decision.decision == "ASK_USER":
            await _council_escalate_to_human(invoice_id, decision, reason="requires user input")
        elif decision.decision == "BLOCK":
            await _council_escalate_to_human(invoice_id, decision, reason="blocked by council")

        # Publish final decision to NATS
        try:
            import nats
            nc = await nats.connect(config.nats_url)
            await nc.publish(
                "invoice.decision.final",
                json.dumps({
                    "invoice_id": invoice_id,
                    "decision": decision.decision,
                    "trust_score": decision.trust_score,
                    "deliberation": decision.deliberation,
                }).encode(),
            )
            await nc.close()
        except Exception as pub_err:
            logger.warning("[COUNCIL] failed to publish decision to NATS: %s", pub_err)

        return {
            "result": "OK",
            "decision": decision.decision,
            "trust_score": decision.trust_score,
        }

    except Exception as exc:
        logger.exception("[COUNCIL] deliberation failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "error": str(exc)}


async def _council_post_invoice(invoice_id: str, extracted_data: dict, decision: Any) -> None:
    """Auto-post the invoice: update status to APPROVED."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await session.execute(
                text(
                    "UPDATE invoices SET status = 'APPROVED', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
                ),
                {"id": invoice_id},
            )
            await session.commit()
            logger.info("[COUNCIL] auto-posted invoice_id=%s (trust=%.4f)", invoice_id, decision.trust_score)
    finally:
        await engine.dispose()


async def _council_mark_for_review(invoice_id: str, decision: Any) -> None:
    """Mark invoice for manual review (SUGGEST)."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await session.execute(
                text(
                    "UPDATE invoices SET status = 'PENDING_REVIEW', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
                ),
                {"id": invoice_id},
            )
            await session.commit()
            logger.info("[COUNCIL] marked for review invoice_id=%s (trust=%.4f)", invoice_id, decision.trust_score)
    finally:
        await engine.dispose()


async def _council_escalate_to_human(invoice_id: str, decision: Any, reason: str) -> None:
    """Escalate invoice to human for review (ASK_USER or BLOCK)."""
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await session.execute(
                text(
                    "UPDATE invoices SET status = 'MANUAL_REVIEW', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
                ),
                {"id": invoice_id},
            )
            await session.commit()
            logger.info(
                "[COUNCIL] escalated to human invoice_id=%s reason=%s (trust=%.4f)",
                invoice_id,
                reason,
                decision.trust_score,
            )
    finally:
        await engine.dispose()


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

    # --- Build extracted data for council decision ---
    extracted_data = {
        "invoice_id": invoice_id,
        "contractor_nip": payload.get("contractor_nip", ""),
        "amount_net": _safe_float(payload.get("amount_net")),
        "amount_gross": consensus.amount_gross or _safe_float(payload.get("amount_gross")),
        "vat": _safe_float(payload.get("vat")),
        "number": payload.get("number", ""),
        "issue_date": payload.get("issue_date", ""),
        "category": payload.get("category", ""),
        "ocr_confidence": _safe_float(payload.get("ocr_confidence")) or (1.0 - float(consensus.confidence_conflict) * 0.5),
        "layout_confidence": _safe_float(payload.get("layout_confidence")) or 0.5,
        "amount_consensus": not consensus.confidence_conflict,
        "llm_validation": _safe_float(payload.get("llm_validation")) or 0.5,
        "vendor_profile": {
            "known": bool(payload.get("vendor_known", False)),
            "invoice_count": int(payload.get("vendor_invoice_count", 0)),
            "trust_score": float(payload.get("vendor_trust_score", 0.5)),
            "category_consistent": bool(payload.get("vendor_category_consistent", True)),
            "auto_approve": bool(payload.get("vendor_auto_approve", False)),
            "category_preference_match": bool(payload.get("vendor_category_preference_match", True)),
        },
        "bank_account_consistent": bool(payload.get("bank_account_consistent", True)),
        "amount_typical": bool(payload.get("amount_typical", True)),
        "historical_average": _safe_float(payload.get("historical_average")),
        "vendor_invoice_count": int(payload.get("vendor_invoice_count", 0)),
    }

    # Trigger council decision & rules check via NATS
    config = AppConfig()
    try:
        import nats
        nc = await nats.connect(config.nats_url)
        # Publish to invoice.extracted for rules_check subscriber
        await nc.publish(
            "invoice.extracted",
            json.dumps({"invoice_id": invoice_id, "extracted_data": extracted_data}).encode(),
        )
        await nc.close()

        # Kick all downstream tasks directly
        await broker.kick("council_decide", invoice_id=invoice_id, extracted_data=extracted_data)
        await broker.kick("rules_check", invoice_id=invoice_id, extracted_data=extracted_data)
        await broker.kick("analytics_run", invoice_id=invoice_id, extracted_data=extracted_data)
        await broker.kick("decision_evaluate", invoice_id=invoice_id, extracted_data=extracted_data)
        logger.info("[OCR] triggered council + rules + analytics + decision for invoice_id=%s", invoice_id)
    except Exception as trigger_err:
        logger.warning("[OCR] failed to trigger checks: %s", trigger_err)

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


@broker.task(schedule=[{"cron": "0 3 * * 0"}], task_name="cleanup_old_logs")
async def cleanup_old_logs_task() -> None:
    log_dir = Path("app_data/logs")
    cutoff = datetime.now() - timedelta(days=7)
    if not log_dir.exists():
        return
    removed = 0
    for f in log_dir.glob("*.log*"):
        try:
            if datetime.fromtimestamp(f.stat().st_mtime) < cutoff:
                f.unlink(missing_ok=True)
                removed += 1
        except FileNotFoundError:
            continue
    logger.info("[CLEANUP] old logs removed=%s", removed)


@broker.task(schedule=[{"cron": "*/15 * * * *"}], task_name="cleanup_temp_upload_files")
async def cleanup_temp_upload_files_task() -> None:
    uploads_dir = Path("app_data/uploads")
    if not uploads_dir.exists():
        return
    removed = 0
    for f in uploads_dir.glob("upload_*.tmp"):
        try:
            f.unlink(missing_ok=True)
            removed += 1
        except FileNotFoundError:
            continue
    logger.info("[CLEANUP] temp upload files removed=%s", removed)


@broker.task(schedule=[{"cron": "0 5 * * 0"}], task_name="cleanup_old_reports")
async def cleanup_old_reports_task() -> None:
    cutoff = datetime.now() - timedelta(days=30)
    report_dirs = [Path("reports/performance"), Path("reports/security"), Path("reports/pii")]
    removed = 0
    for d in report_dirs:
        if not d.exists():
            continue
        for pattern in ("*.json", "*.html", "*.txt"):
            for f in d.glob(pattern):
                try:
                    if datetime.fromtimestamp(f.stat().st_mtime) < cutoff:
                        f.unlink(missing_ok=True)
                        removed += 1
                except FileNotFoundError:
                    continue
    logger.info("[CLEANUP] old reports removed=%s", removed)


@broker.task(schedule=[{"cron": "0 4 * * 0"}], task_name="compact_lancedb")
async def compact_lancedb_task() -> None:
    try:
        import lancedb
    except Exception:
        logger.warning("[LANCEDB] lancedb unavailable, skip compaction")
        return

    db = lancedb.connect("nexus_lancedb", mode="file")
    compacted = 0
    for table_name in db.table_names():
        table = db.open_table(table_name, index_cache_size=100 * 1024 * 1024)
        if hasattr(table, "compact_files"):
            table.compact_files()
            compacted += 1
        if hasattr(table, "cleanup_old_versions"):
            table.cleanup_old_versions()
    logger.info("[LANCEDB] compacted tables=%s", compacted)


@broker.task(schedule=[{"cron": "30 4 * * 0"}], task_name="sqlite_weekly_vacuum")
async def sqlite_weekly_vacuum_task() -> None:
    config = AppConfig()
    engine = create_oltp_engine(config)
    try:
        async with engine.connect() as conn:
            await conn.execute(text("VACUUM;"))
        logger.info("[SQLITE] weekly VACUUM completed")
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "15 4 * * 0"}], task_name="cleanup_duckdb_temp")
async def cleanup_duckdb_temp_task() -> None:
    config = AppConfig()
    temp_dir = config.duckdb_path.parent / "duckdb_tmp"
    if not temp_dir.exists():
        return
    removed = 0
    for item in temp_dir.glob("*"):
        try:
            if item.is_file():
                item.unlink(missing_ok=True)
                removed += 1
        except FileNotFoundError:
            continue
    logger.info("[DUCKDB] temp files removed=%s", removed)
