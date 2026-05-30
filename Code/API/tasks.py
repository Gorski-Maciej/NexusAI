from __future__ import annotations

import atexit
import hashlib
import logging
import json
import os
import resource
import time
from pathlib import Path
from datetime import datetime, timedelta
from taskiq_nats import PullBasedJetStreamBroker
from sqlalchemy import text
import httpx

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
from sqlalchemy import text as sql_text
from services.autopilot import CouncilOrchestrator
from services.council_agents import AlphaAgent, BetaAgent, GammaAgent, ModelManager
from services.decision_logger import DecisionLogger
from services.rules_agent import RulesAgent
from services.analytics_agent import AnalyticsAgent, FinDetective
from services.decision_agent import DecisionOrchestrator, JambaStrategist, GraniteExecutor
from services.orchestrator_agent import OrchestratorAgent
from services.accounting import AccountingService

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

# Singleton for Orchestrator Agent
_ORCHESTRATOR_AGENT: OrchestratorAgent | None = None

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


def _ensure_orchestrator_agent(config: AppConfig, manager: ModelManager) -> OrchestratorAgent:
    """Lazy-init OrchestratorAgent as module-level singleton.
    Shares ModelManager with Council agents for RAM mutual exclusion.
    """
    global _ORCHESTRATOR_AGENT
    if _ORCHESTRATOR_AGENT is None:
        _ORCHESTRATOR_AGENT = OrchestratorAgent(
            model_name="orchestrator",
            model_path=config.orchestrator_model_path,
            model_manager=manager,
            config=config,
        )
    return _ORCHESTRATOR_AGENT


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
    Timeout: 90 seconds dla prostych zadań analitycznych.
    Rozwiązanie 17: Publikuje postęp zadania przez WebSocket.
    """
    config = AppConfig()
    manager, _, _ = _ensure_council_components(config)
    agent = _ensure_analytics_agent(config, manager)
    detective = _ensure_fin_detective(config)

    task_id = f"analytics_{invoice_id}"
    logger.info("[ANALYTICS] running analysis for invoice_id=%s", invoice_id)

    # Publikuj postęp (Rozwiązanie 17)
    try:
        from api.routes.ws import broadcast_progress, get_cancel_event
        await broadcast_progress(task_id, {"type": "progress", "task_id": task_id, "percent": 10, "stage": "initializing"})
    except Exception:
        pass

    try:
        # Extract vendor history from extracted_data if available
        vendor_history = extracted_data.get("vendor_profile", {})

        # Run both analyses concurrently
        # Timeout dla zadań analitycznych (90s)
        analysis_task = agent.analyze(
            invoice_data=extracted_data,
            vendor_history=vendor_history,
        )
        detection_task = detective.detect_anomalies(extracted_data)

        analysis_result, ml_anomalies = await asyncio.wait_for(
            asyncio.gather(analysis_task, detection_task),
            timeout=90.0,
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
    Timeout: 30 seconds.
    """
    config = AppConfig()
    manager, _, _ = _ensure_council_components(config)
    agent = _ensure_rules_agent(config, manager)

    logger.info("[RULES] checking invoice_id=%s", invoice_id)

    try:
        result = await asyncio.wait_for(
            agent.evaluate(extracted_data),
            timeout=30.0,
        )

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
    """Council of Agents decision task triggered after OCR extraction.
    Timeout: 120 seconds for complex LLM deliberation."""
    config = AppConfig()
    _, orchestrator, decision_logger = _ensure_council_components(config)

    logger.info("[COUNCIL] starting deliberation for invoice_id=%s", invoice_id)

    try:
        decision = await asyncio.wait_for(
            orchestrator.evaluate(
                invoice_id=invoice_id,
                invoice_data=extracted_data,
            ),
            timeout=120.0,
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

    # --- Walidacja NIP i IBAN (asynchroniczna, nie blokuje głównego przepływu) ---
    try:
        accounting = AccountingService()
        contractor_nip = payload.get("contractor_nip", "")
        bank_account = payload.get("bank_account", "")

        nip_verification = await accounting.verify_nip(contractor_nip) if contractor_nip else None
        nip_valid = nip_verification is not None
        iban_valid = accounting.validate_iban(bank_account) if bank_account else True  # IBAN nie jest wymagany

        if nip_verification:
            logger.info("[OCR] NIP verified invoice_id=%s name=%s", invoice_id, nip_verification.get("name", "unknown"))
        else:
            logger.warning("[OCR] NIP verification failed for invoice_id=%s nip=%s", invoice_id, contractor_nip)

        if not iban_valid and bank_account:
            logger.warning("[OCR] IBAN validation failed for invoice_id=%s iban=%s", invoice_id, bank_account)

        # Dodaj flagi walidacji do payloadu
        payload["nip_valid"] = nip_valid
        payload["iban_valid"] = iban_valid
    except Exception as ve:
        logger.warning("[OCR] NIP/IBAN validation error for invoice_id=%s: %s", invoice_id, ve)
        nip_valid = False
        iban_valid = False
        payload["nip_valid"] = False
        payload["iban_valid"] = False

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

        # Dynamic workflow orchestration — decide which agents to run
        manager, _, _ = _ensure_council_components(config)
        orchestrator = _ensure_orchestrator_agent(config, manager)
        workflow = await orchestrator.decide_workflow(
            invoice_data=extracted_data,
            vendor_profile=extracted_data.get("vendor_profile", {}),
        )
        for task_name in workflow["agents"]:
            await broker.kick(task_name, invoice_id=invoice_id, extracted_data=extracted_data)
        logger.info(
            "[OCR] orchestrated agents=%s for invoice_id=%s (reasoning=%s)",
            workflow["agents"],
            invoice_id,
            workflow.get("reasoning", ""),
        )
    except Exception as trigger_err:
        logger.warning("[OCR] failed to trigger checks: %s", trigger_err)

    # Zero-ETL path: no OLTP->OLAP row replication in worker.
    # Invoice OCR lifecycle is event-driven; analytics layer reads SQLite via DuckDB ATTACH.
    await OLAP_CIRCUIT_BREAKER.call(_refresh_cashflow_for_event)

    # Wyczyść bufor ramek OCR dla tego dokumentu (Rozwiązanie 12)
    try:
        from api.shared_image_buffer import SharedImageBuffer
        from api.dependencies import provide_shared_image_buffer
        # Użyj globalnego bufora - w środowisku workers nie ma dostępu do app.state
        # Dlatego czyszczenie jest opcjonalne i best-effort
        logger.info("[OCR] processing complete for invoice_id=%s, buffer can be cleared", invoice_id)
    except Exception:
        pass

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


@broker.task(schedule=[{"cron": "*/5 * * * *"}], task_name="dead_letter_processor")
async def dead_letter_processor_task() -> None:
    """
    Okresowe zadanie (co 5 minut) monitorujące Dead Letter Queue.
    Subskrybuje subjekt nats.deadletter, zapisuje błędy do tabeli failed_tasks
    i loguje ostrzeżenia dla administratora.
    """
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)

    try:
        import nats
        nc = await nats.connect(config.nats_url)
        sub = await nc.subscribe("nats.deadletter", queue="nexus-dlq-workers")

        # Sprawdź, czy tabela failed_tasks istnieje, jeśli nie - utwórz
        async with session_factory() as session:
            await session.execute(
                text(
                    """
                    CREATE TABLE IF NOT EXISTS failed_tasks (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        task_type TEXT NOT NULL,
                        task_id TEXT,
                        error_message TEXT,
                        stack_trace TEXT,
                        payload TEXT,
                        failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        acknowledged BOOLEAN DEFAULT 0
                    )
                    """
                )
            )
            await session.commit()

        # Sprawdź wiadomości w DLQ
        try:
            msg = await asyncio.wait_for(sub.fetch(1, timeout=2.0), timeout=5.0)
            while msg:
                try:
                    data = json.loads(msg.data.decode())
                    error_message = data.get("error", "Unknown error")
                    task_type = data.get("task_type", "unknown")
                    task_id = data.get("task_id", None)
                    stack_trace = data.get("stack_trace", "")
                    payload = data.get("payload", {})

                    # Zapisz błąd do tabeli failed_tasks
                    async with session_factory() as session:
                        await session.execute(
                            text(
                                """
                                INSERT INTO failed_tasks (task_type, task_id, error_message, stack_trace, payload)
                                VALUES (:task_type, :task_id, :error_message, :stack_trace, :payload)
                                """
                            ),
                            {
                                "task_type": task_type,
                                "task_id": task_id,
                                "error_message": error_message,
                                "stack_trace": stack_trace,
                                "payload": json.dumps(payload),
                            },
                        )
                        await session.commit()

                    logger.error(
                        "[DLQ] Dead letter received: task_type=%s task_id=%s error=%s",
                        task_type,
                        task_id,
                        error_message,
                    )

                    # TODO: Powiadom administratora przez webhook, jeśli skonfigurowano
                    dpo_webhook = os.getenv("NEXUS_DPO_ALERT_WEBHOOK", "")
                    if dpo_webhook:
                        try:
                            async with httpx.AsyncClient(timeout=5.0) as client:
                                await client.post(
                                    dpo_webhook,
                                    json={
                                        "type": "dead_letter",
                                        "task_type": task_type,
                                        "error": error_message,
                                        "timestamp": datetime.now(timezone.utc).isoformat(),
                                    },
                                )
                        except Exception:
                            logger.warning("[DLQ] Failed to notify webhook")

                except Exception as parse_err:
                    logger.warning("[DLQ] Failed to parse DLQ message: %s", parse_err)

                try:
                    msg = await asyncio.wait_for(sub.fetch(1, timeout=2.0), timeout=5.0)
                except asyncio.TimeoutError:
                    break

        except asyncio.TimeoutError:
            pass  # Brak wiadomości w DLQ

        await nc.close()
    except Exception as dlq_err:
        logger.warning("[DLQ] Dead letter processor error: %s", dlq_err)
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="relay_outbox_events")
async def relay_outbox_events() -> None:
    """
    Relay pending outbox events with atomic UPDATE semantics (Rozwiązanie 11).
    Uses two-step atomic UPDATE to prevent duplicate processing by concurrent workers.
    Detects stale PROCESSING tasks (>= 5 min) and reclaims them.
    Records idempotency key in processed_events to prevent double-dispatch.
    """
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)

    async with session_factory() as session:
        # Upewnij się, że tabela dead_letter_events istnieje
        await session.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS dead_letter_events (
                    id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT,
                    payload TEXT,
                    error_message TEXT,
                    stack_trace TEXT,
                    retry_count INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    dead_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )

        # 1. Odblokuj stare zadania w statusie PROCESSING (timeout >= 5 minut)
        stale_timeout = 300  # 5 minutes
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET status = 'FAILED', processing_started_at = NULL
                WHERE status = 'PROCESSING'
                  AND processing_started_at IS NOT NULL
                  AND (strftime('%%s', 'now') - strftime('%%s', processing_started_at)) > :timeout
                """
            ),
            {"timeout": stale_timeout},
        )

        # 2. Atomowa rezerwacja: UPDATE z warunkiem na status = 'PENDING'/'FAILED'
        # Dwa etapy: najpierw zaznaczamy zdarzenia do przetworzenia
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET status = 'PROCESSING',
                    processing_started_at = CURRENT_TIMESTAMP
                WHERE id IN (
                    SELECT id FROM outbox_events
                    WHERE status IN ('PENDING', 'FAILED')
                      AND processed = 0
                      AND COALESCE(retry_count, 0) < :max_retries
                    ORDER BY created_at ASC
                    LIMIT 100
                )
                """
            ),
            {"max_retries": MAX_OUTBOX_RETRIES},
        )

        # 3. Pobierz zarezerwowane wiersze
        rows = (
            await session.execute(
                text(
                    """
                    SELECT id, event_type, aggregate_id, payload, COALESCE(retry_count, 0) as retry_count
                    FROM outbox_events
                    WHERE status = 'PROCESSING'
                      AND processing_started_at IS NOT NULL
                    ORDER BY created_at ASC
                    LIMIT 100
                    """
                ),
            )
        ).mappings().all()

        for row in rows:
            try:
                # Idempotentność: sprawdź czy to zdarzenie było już przetworzone
                event_id = row["id"]
                existing = await session.execute(
                    text(
                        "SELECT 1 FROM processed_events WHERE id = :id"
                    ),
                    {"id": event_id},
                )
                if existing.fetchone():
                    logger.info("[OUTBOX] Skipping already processed event id=%s", event_id)
                    await session.execute(
                        text("UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"),
                        {"id": event_id},
                    )
                    continue

                await _dispatch_outbox_event(row)

                # Zapisz do tabeli idempotentności
                payload_raw = row.get("payload") or "{}"
                payload_hash = hashlib.sha256(payload_raw.encode()).hexdigest()
                await session.execute(
                    text(
                        """
                        INSERT OR IGNORE INTO processed_events (id, event_type, aggregate_id, payload_hash, processed_at)
                        VALUES (:id, :event_type, :aggregate_id, :payload_hash, CURRENT_TIMESTAMP)
                        """
                    ),
                    {
                        "id": event_id,
                        "event_type": row["event_type"],
                        "aggregate_id": row["aggregate_id"],
                        "payload_hash": payload_hash,
                    },
                )

                await session.execute(
                    text("UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"),
                    {"id": event_id},
                )
            except Exception as exc:
                logger.exception("[OUTBOX] Failed to relay event id=%s: %s", row["id"], exc)
                new_retry_count = row["retry_count"] + 1
                is_dead_letter = new_retry_count >= MAX_OUTBOX_RETRIES

                if is_dead_letter:
                    try:
                        await session.execute(
                            text(
                                """
                                INSERT OR IGNORE INTO dead_letter_events
                                    (id, event_type, aggregate_id, payload, error_message, stack_trace, retry_count)
                                VALUES (:id, :event_type, :aggregate_id, :payload, :error_message, :stack_trace, :retry_count)
                                """
                            ),
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
                    except Exception as dle:
                        logger.warning("[OUTBOX] Failed to write dead_letter_event: %s", dle)

                await session.execute(
                    text(
                        """
                        UPDATE outbox_events
                        SET retry_count = retry_count + 1,
                            processing_started_at = NULL,
                            status = CASE
                                WHEN retry_count + 1 >= :max_retries THEN 'DEAD_LETTER'
                                ELSE 'FAILED'
                            END
                        WHERE id = :id
                        """
                    ),
                    {"id": row["id"], "max_retries": MAX_OUTBOX_RETRIES},
                )

        # 4. Cleanup starych wpisów processed_events (> 24h)
        await session.execute(
            text(
                "DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')"
            )
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
    if not log_dir.exists():
        return

    now = datetime.now()
    cutoff_compress = now - timedelta(days=7)   # Kompresuj logi starsze niż 7 dni
    cutoff_delete = now - timedelta(days=30)    # Usuń logi starsze niż 30 dni

    removed = 0
    compressed = 0

    for f in log_dir.iterdir():
        if not f.is_file():
            continue
        try:
            mtime = datetime.fromtimestamp(f.stat().st_mtime)

            # Usuń bardzo stare pliki
            if mtime < cutoff_delete:
                f.unlink(missing_ok=True)
                removed += 1
                logger.debug("[CLEANUP] removed old log: %s", f.name)
                continue

            # Skompresuj pliki .log starsze niż 7 dni (jeśli jeszcze nie skompresowane)
            if mtime < cutoff_compress and f.suffix in (".log", ".json"):
                compressed_name = f.with_suffix(f.suffix + ".gz")
                if not compressed_name.exists():
                    try:
                        import gzip
                        import shutil
                        with open(f, "rb") as f_in:
                            with gzip.open(compressed_name, "wb") as f_out:
                                shutil.copyfileobj(f_in, f_out)
                        f.unlink()
                        compressed += 1
                        logger.debug("[CLEANUP] compressed log: %s -> %s", f.name, compressed_name.name)
                    except Exception as e:
                        logger.warning("[CLEANUP] failed to compress %s: %s", f.name, e)

        except (FileNotFoundError, OSError):
            continue

    logger.info("[CLEANUP] old logs removed=%s compressed=%s", removed, compressed)


@broker.task(schedule=[{"cron": "*/5 * * * *"}], task_name="cleanup_temp_upload_files")
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
    # Dodatkowo: czyść stare pliki tymczasowe, które mogły zostać pominięte (np. z błędów)
    for f in uploads_dir.glob("tmp_*"):
        try:
            # Usuń pliki starsze niż 1 godzina
            age = time.time() - f.stat().st_mtime
            if age > 3600:
                f.unlink(missing_ok=True)
                removed += 1
        except (FileNotFoundError, OSError):
            continue
    logger.info("[CLEANUP] temp upload files removed=%s", removed)


@broker.task(schedule=[{"cron": "30 6 * * *"}], task_name="daily_briefing_send")
async def daily_briefing_send(user_id: str | None = None) -> dict:
    """
    Generuj i wyślij codzienne podsumowanie finansowe (Daily Briefing).

    Domyślnie uruchamiany codziennie o 6:30 rano (cron).
    Może być też wywołany ręcznie z określonym user_id.

    Wysyła briefing przez kanał in_app (SQLite).
    Jeśli skonfigurowano, również przez push/email/SMS.
    """
    config = AppConfig()
    logger.info("[DAILY-BRIEFING] starting generation for user_id=%s", user_id or "all")

    try:
        # Lazy init komponentów
        from services.notification_service import NotificationService
        from services.daily_briefing import DailyBriefingService
        from services.ple_engine import PLEEngine
        from services.decision_logger import DecisionLogger
        from db.analytics import DuckDBManager

        db_path = config.base_dir / "app_data" / "notifications.db"
        notification = NotificationService(db_path=db_path, config=config)
        duckdb: DuckDBManager | None = None
        try:
            duckdb = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
            decision_logger = DecisionLogger(duckdb)
            ple = PLEEngine(config=config)

            briefing_service = DailyBriefingService(
                config=config,
                notification_service=notification,
                ple_engine=ple,
                decision_logger=decision_logger,
                duckdb_manager=duckdb,
            )

            # Jeśli podano user_id, generuj tylko dla niego
            if user_id:
                result = await briefing_service.generate_and_send(user_id, channels=["in_app"])
                logger.info("[DAILY-BRIEFING] sent for user_id=%s status=%s", user_id, result["status"])
                return {"result": "OK", "user_id": user_id, **result}

            # W przeciwnym razie dla wszystkich aktywnych użytkowników
            default_users = ["default", "admin"]
            results: list[dict[str, Any]] = []
            for uid in default_users:
                try:
                    result = await briefing_service.generate_and_send(uid, channels=["in_app"])
                    results.append({"user_id": uid, "status": result["status"]})
                except Exception as exc:
                    logger.error("[DAILY-BRIEFING] failed for user=%s: %s", uid, exc)
                    results.append({"user_id": uid, "status": "error", "error": str(exc)})

            return {"result": "OK", "users": results}
        finally:
            if duckdb is not None:
                duckdb.close()

    except Exception as exc:
        logger.exception("[DAILY-BRIEFING] generation failed: %s", exc)
        return {"result": "ERROR", "error": str(exc)}


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


@broker.task(schedule=[{"cron": "0 * * * *"}], task_name="check_hanging_transactions")
async def check_hanging_transactions_task() -> None:
    """
    Okresowe zadanie (co godzinę) wykrywające wiszące transakcje.
    Sprawdza dziennik WAL SQLite - jeśli plik WAL jest duży, może to wskazywać
    na otwartą transakcję. Loguje ostrzeżenie.
    """
    config = AppConfig()
    wal_path = config.sqlite_path.with_suffix(".db-wal")
    if wal_path.exists():
        wal_size_mb = wal_path.stat().st_size / (1024 * 1024)
        if wal_size_mb > 50:
            logger.warning(
                "[HANGING-TX] Plik WAL ma %.2f MB - może wskazywać na wiszącą transakcję. "
                "Sprawdź aktywne połączenia i sesje.",
                wal_size_mb,
            )
        else:
            logger.debug("[HANGING-TX] Plik WAL ma %.2f MB - OK", wal_size_mb)
    else:
        logger.debug("[HANGING-TX] Brak pliku WAL - SQLite działa w trybie DELETE lub WAL jest pusty")

    # Dodatkowo: sprawdź długo trwające zapytania przez PRAGMA
    engine = create_oltp_engine(config)
    try:
        async with engine.connect() as conn:
            result = await conn.execute(sql_text("PRAGMA wal_checkpoint;"))
            cp_info = result.fetchone()
            # Jeśli wal_checkpoint zwraca błąd (busy), logujemy ostrzeżenie
            if cp_info and len(cp_info) > 0 and cp_info[0] < 0:
                logger.warning(
                    "[HANGING-TX] PRAGMA wal_checkpoint zwrócił kod %s - "
                    "baza danych jest zajęta przez inną sesję.",
                    cp_info[0],
                )
    except Exception as e:
        logger.warning("[HANGING-TX] Nie udało się sprawdzić stanu WAL: %s", e)
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "0 6 * * 1"}], task_name="weekly_nip_reverification")
async def weekly_nip_reverification_task() -> None:
    """
    Cotygodniowe zadanie ponownej weryfikacji NIP-ów kontrahentów.
    Sprawdza NIP-y w Białej Liście MF i aktualizuje status w tabeli contractors.
    """
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    accounting = AccountingService()

    try:
        async with session_factory() as session:
            # Pobierz wszystkich kontrahentów
            from sqlalchemy import select as sa_select
            from models.contractor import Contractor

            result = await session.execute(sa_select(Contractor))
            contractors = result.scalars().all()

            verified_count = 0
            failed_count = 0
            for contractor in contractors:
                try:
                    verification = await accounting.verify_nip(contractor.nip)
                    if verification:
                        verified_count += 1
                        logger.info(
                            "[NIP-VERIFY] Contractors NIP=%s verified: %s",
                            contractor.nip,
                            verification.get("name", "unknown"),
                        )
                    else:
                        failed_count += 1
                        logger.warning(
                            "[NIP-VERIFY] Contractors NIP=%s verification FAILED",
                            contractor.nip,
                        )
                except Exception as ve:
                    failed_count += 1
                    logger.warning("[NIP-VERIFY] Error verifying NIP=%s: %s", contractor.nip, ve)

            logger.info(
                "[NIP-VERIFY] Weekly reverification complete: verified=%d, failed=%d, total=%d",
                verified_count,
                failed_count,
                len(contractors),
            )
    finally:
        await engine.dispose()


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


@broker.task(schedule=[{"cron": "0 5 * * *"}], task_name="cleanup_expired_refresh_tokens")
async def cleanup_expired_refresh_tokens_task() -> None:
    """
    Codzienne zadanie czyszczenia wygasłych i odwołanych refresh tokenów.
    Rozwiązanie 16: Usuwa tokeny starsze niż 7 dni od daty wygaśnięcia.
    """
    config = AppConfig()
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            result = await session.execute(
                text(
                    """
                    DELETE FROM refresh_tokens
                    WHERE expires_at < datetime('now', '-7 days')
                       OR (is_revoked = 1 AND created_at < datetime('now', '-30 days'))
                    """
                )
            )
            deleted = result.rowcount
            await session.commit()
            logger.info("[TOKEN-CLEANUP] Removed %d expired/revoked refresh tokens", deleted)
    finally:
        await engine.dispose()

