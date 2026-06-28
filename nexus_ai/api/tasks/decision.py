"""
Decision engine tasks — extracted from api/tasks.py.

Zawiera:
- decision_evaluate: główna ewaluacja decyzji
- council_decide: deprecated delegacja
- _post_invoice, _mark_for_review, _escalate_to_human: helpery
"""

from __future__ import annotations

from typing import Any

import anyio
from sqlmodel import Session, text
from structlog import get_logger
from taskiq import TaskiqDepends

from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.decision_engine import DecisionEngine, DecisionVerdict
from nexus_ai.core.di import get_config, get_db_session
from nexus_ai.db.analytics import DuckDBManager

logger = get_logger("nexus.api.tasks.decision")

# DecisionEngine singleton (lazy init)
_DECISION_ENGINE: DecisionEngine | None = None
_DUCKDB: DuckDBManager | None = None


def _ensure_decision_engine(config: AppConfig) -> DecisionEngine:
    """Lazy-init DecisionEngine."""
    global _DECISION_ENGINE, _DUCKDB
    if _DECISION_ENGINE is not None:
        return _DECISION_ENGINE
    _DUCKDB = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    _DECISION_ENGINE = DecisionEngine(duckdb=_DUCKDB)
    return _DECISION_ENGINE


@broker.task(
    task_name="decision_evaluate",
    labels={"service": "api", "operation": "decision", "criticality": "high"},
    timeout=60.0,
)
async def decision_evaluate(
    invoice_id: str,
    extracted_data: dict,
    config: AppConfig = TaskiqDepends(get_config),
    db: Session = TaskiqDepends(get_db_session),
) -> dict:
    """Final decision evaluation."""
    engine = _ensure_decision_engine(config)
    logger.info("[DECISION] evaluating for invoice_id=%s", invoice_id)

    try:
        verdict = engine.decide(
            invoice_data=extracted_data,
            vendor_profile=extracted_data.get("vendor_profile", {}),
        )
        logger.info(
            "[DECISION] invoice_id=%s decision=%s confidence=%.4f",
            invoice_id,
            verdict.decision,
            verdict.confidence,
        )

        try:
            await broker.kick(
                "event_emit_decision_made",
                invoice_id=invoice_id,
                decision=verdict.decision,
                trust_score=extracted_data.get("trust_score", 0.0),
                ai_confidence=verdict.confidence,
                alpha_vote=extracted_data.get("alpha_vote", ""),
                beta_vote=extracted_data.get("beta_vote", ""),
                gamma_vote=extracted_data.get("gamma_vote", ""),
                decision_pattern=verdict.matched_rule[:64] if verdict.matched_rule else "",
                reasoning=verdict.reasoning,
                metadata={
                    "extracted_data_snapshot": {
                        k: extracted_data[k]
                        for k in (
                            "amount_gross",
                            "amount_net",
                            "category",
                            "contractor_nip",
                            "ocr_confidence",
                        )
                        if k in extracted_data
                    }
                },
            )
        except (ConnectionError, TimeoutError, OSError) as emit_err:
            logger.warning("[DECISION-EVENT] Failed to emit: %s", emit_err)

        if verdict.decision == "AUTO_POST":
            await _post_invoice(invoice_id, extracted_data, verdict, db)
        elif verdict.decision == "SUGGEST":
            await _mark_for_review(invoice_id, verdict, db)
        elif verdict.decision in ("ASK_USER", "BLOCK", "ESCALATE"):
            await _escalate_to_human(
                invoice_id, verdict, db, reason=f"decision: {verdict.decision}"
            )

        return {
            "result": "OK",
            "invoice_id": invoice_id,
            "decision": verdict.decision,
            "confidence": verdict.confidence,
            "reasoning": verdict.reasoning,
        }
    except Exception as exc:
        logger.exception("[DECISION] evaluation failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}


@broker.task(
    task_name="council_decide",
    labels={"service": "api", "operation": "decision", "criticality": "high", "deprecated": "true"},
    timeout=60.0,
)
async def council_decide(invoice_id: str, extracted_data: dict) -> dict:
    """[DEPRECATED] Deleguje do decision_evaluate."""
    logger.warning(
        "[DEPRECATED] council_decide called for invoice_id=%s — use decision_evaluate", invoice_id
    )
    config = AppConfig()
    engine = _ensure_decision_engine(config)
    try:
        verdict = engine.decide(
            invoice_data=extracted_data, vendor_profile=extracted_data.get("vendor_profile", {})
        )
        try:
            await broker.kick(
                "event_emit_decision_made",
                invoice_id=invoice_id,
                decision=verdict.decision,
                trust_score=extracted_data.get("trust_score", 0.0),
                ai_confidence=verdict.confidence,
                alpha_vote=extracted_data.get("alpha_vote", ""),
                beta_vote=extracted_data.get("beta_vote", ""),
                gamma_vote=extracted_data.get("gamma_vote", ""),
                decision_pattern=verdict.matched_rule[:64] if verdict.matched_rule else "",
                reasoning=verdict.reasoning,
                metadata={
                    k: extracted_data[k]
                    for k in (
                        "amount_gross",
                        "amount_net",
                        "category",
                        "contractor_nip",
                        "ocr_confidence",
                    )
                    if k in extracted_data
                },
            )
        except (ConnectionError, TimeoutError, OSError) as exc:
            logger.warning("[COUNCIL] Failed to emit event for %s: %s", invoice_id, exc)

        from nexus_ai.db.database import create_oltp_engine, create_session_factory

        config_temp = AppConfig()
        eng = create_oltp_engine(config_temp)
        sess_fac = create_session_factory(eng)
        if verdict.decision == "AUTO_POST":
            async with sess_fac() as sess:
                await _post_invoice(invoice_id, extracted_data, verdict, sess)
        elif verdict.decision == "SUGGEST":
            async with sess_fac() as sess:
                await _mark_for_review(invoice_id, verdict, sess)
        elif verdict.decision in ("ASK_USER", "BLOCK", "ESCALATE"):
            async with sess_fac() as sess:
                await _escalate_to_human(
                    invoice_id, verdict, sess, reason=f"decision: {verdict.decision}"
                )
        await eng.dispose()

        return {
            "result": "OK",
            "invoice_id": invoice_id,
            "decision": verdict.decision,
            "confidence": verdict.confidence,
            "reasoning": verdict.reasoning,
        }
    except Exception as exc:
        logger.exception("[DECISION] council_decide failed for invoice_id=%s: %s", invoice_id, exc)
        return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}


async def _post_invoice(
    invoice_id: str, extracted_data: dict, verdict: DecisionVerdict, db: Session
) -> None:
    """Auto-post the invoice: update status to APPROVED."""
    with anyio.CancelScope(shield=True):
        await db.execute(
            text(
                "UPDATE invoices SET status = 'APPROVED', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": invoice_id},
        )
        logger.info(
            "[DECIDE] auto-posted invoice_id=%s (conf=%.4f)", invoice_id, verdict.confidence
        )
    try:
        from nexus_ai.services.semantic_guard import SemanticGuard

        sg = SemanticGuard()
        full_text = extracted_data.get("ocr_full_text", "") or ""
        if full_text:
            sg.store_invoice(
                vendor_nip=extracted_data.get("contractor_nip", ""),
                invoice_text=full_text,
                category_code=extracted_data.get("category", ""),
                amount_net=float(extracted_data.get("amount_net", 0) or 0),
                transaction_id=invoice_id,
            )
    except Exception as al_err:
        logger.warning("[ACTIVE-LEARNING] Failed to store in sqlite-vec: %s", al_err)


async def _mark_for_review(invoice_id: str, verdict: DecisionVerdict, db: Session) -> None:
    """Mark invoice for manual review."""
    with anyio.CancelScope(shield=True):
        await db.execute(
            text(
                "UPDATE invoices SET status = 'PENDING_REVIEW', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": invoice_id},
        )
        logger.info(
            "[DECIDE] marked for review invoice_id=%s (conf=%.4f)", invoice_id, verdict.confidence
        )


async def _escalate_to_human(
    invoice_id: str, verdict: DecisionVerdict, db: Session, reason: str = ""
) -> None:
    """Escalate invoice to human for review."""
    with anyio.CancelScope(shield=True):
        await db.execute(
            text(
                "UPDATE invoices SET status = 'MANUAL_REVIEW', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": invoice_id},
        )
        logger.info(
            "[DECIDE] escalated invoice_id=%s reason=%s (conf=%.4f)",
            invoice_id,
            reason,
            verdict.confidence,
        )
