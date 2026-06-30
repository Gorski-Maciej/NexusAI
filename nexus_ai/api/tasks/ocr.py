"""
OCR pipeline tasks -- extracted from api/tasks.py (FAZA V modularyzacji).

Zawiera:
- process_invoice_ocr: główny pipeline OCR
- process_large_attachment: przetwarzanie dużych załączników
- Helpery: _mark_invoice_blocked, _mark_invoice_pending_review
- _safe_float, _build_field_confidence
"""

from __future__ import annotations

from typing import Any

import anyio
import pendulum
from sqlmodel import Session, text
from structlog import get_logger
from taskiq import TaskiqDepends

from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.decision_engine import classify_invoice
from nexus_ai.core.di import get_config, get_db_session, get_engine

# Niepotrzebne importy usunięte -- DecodeError i msgspec_loads nie są używane w tym module
from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus
from nexus_ai.services.accounting import AccountingService
from nexus_ai.tax.exceptions import NoMatchingRuleError

logger = get_logger("nexus.api.tasks.ocr")

# Semafory dla limitów współbieżności
_OCR_LIMITER = anyio.CapacityLimiter(3)  # max 3 równoległe OCR


def _safe_float(value: object) -> float | None:
    """Bezpieczna konwersja na float."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _build_field_confidence(
    payload: dict[str, Any],
    consensus: Any,
) -> dict[str, dict[str, Any]]:
    """Zbuduj strukturę field_confidence z payloadu OCR i konsensusu."""
    fc: dict[str, dict[str, Any]] = {}

    gross_str = payload.get("amount_gross")
    gross_val = (
        consensus.amount_gross
        if consensus and consensus.amount_gross is not None
        else _safe_float(gross_str)
    )
    if gross_val is not None:
        base_conf = _safe_float(payload.get("ocr_confidence")) or 0.5
        gross_conf = base_conf * 0.7 if consensus and consensus.confidence_conflict else base_conf
        fc["total_gross"] = {
            "value": gross_val,
            "confidence": round(min(gross_conf, 1.0), 4),
            "source": "ocr_consensus",
        }

    net_val = _safe_float(payload.get("amount_net"))
    if net_val is not None:
        fc["total_net"] = {
            "value": net_val,
            "confidence": round(min(float(payload.get("ocr_confidence", 0.5)) * 0.95, 1.0), 4),
            "source": "ocr",
        }

    vat_rate_val = payload.get("vat_rate") or payload.get("vat_rate_from_llm")
    if vat_rate_val is not None:
        vat_conf = _safe_float(payload.get("llm_validation")) or 0.5
        fc["vat_rate"] = {
            "value": vat_rate_val,
            "confidence": round(min(vat_conf, 1.0), 4),
            "source": "llm",
        }

    vat_val = _safe_float(payload.get("vat"))
    if vat_val is not None:
        fc["vat_amount"] = {
            "value": vat_val,
            "confidence": round(min(float(payload.get("ocr_confidence", 0.5)) * 0.9, 1.0), 4),
            "source": "ocr",
        }

    nip_val = payload.get("contractor_nip", "")
    if nip_val:
        fc["vendor_nip"] = {
            "value": nip_val,
            "confidence": 0.95 if payload.get("nip_valid", False) else 0.7,
            "source": "ocr",
        }

    inv_num = payload.get("number", "")
    if inv_num:
        fc["invoice_number"] = {"value": inv_num, "confidence": 0.85, "source": "ocr"}

    issue_date = payload.get("issue_date", "")
    if issue_date:
        fc["issue_date"] = {"value": issue_date, "confidence": 0.85, "source": "ocr"}

    category = payload.get("category", "")
    if category:
        fc["category_code"] = {"value": category, "confidence": 0.80, "source": "llm"}

    return fc


@broker.task(
    task_name="process_invoice_ocr",
    labels={"service": "api", "operation": "ocr", "criticality": "high"},
    timeout=300.0,
)
async def process_invoice_ocr(
    invoice_id: str,
    payload: dict | None = None,
    config: AppConfig = TaskiqDepends(get_config),
    db: Session = TaskiqDepends(get_db_session),
    engine: Any = TaskiqDepends(get_engine),
) -> None:
    """Dedicated OCR pipeline entrypoint triggered by outbox relay."""
    logger.info("[OCR] processing invoice_id=%s", invoice_id)
    payload = payload or {}

    async with _OCR_LIMITER:
        primary_amount = _safe_float(payload.get("ocr_primary_amount_gross"))
        secondary_amount = _safe_float(payload.get("ocr_secondary_amount_gross"))
        easyocr_amount = _safe_float(payload.get("ocr_easyocr_amount_gross"))

        ocr_results = [
            OCRAmountResult(
                amount_gross=float(primary_amount) if primary_amount is not None else None,
                source="doctr",
            ),
            OCRAmountResult(
                amount_gross=float(secondary_amount) if secondary_amount is not None else None,
                source="paddle",
            ),
        ]
        if easyocr_amount is not None:
            ocr_results.append(
                OCRAmountResult(amount_gross=float(easyocr_amount), source="easyocr")
            )

        consensus = decide_amount_consensus(
            ocr_results,
            tolerance=0.01,
            majority_threshold=2 if len(ocr_results) <= 2 else 3,
        )

        if consensus.confidence_conflict:
            await _mark_invoice_pending_review(invoice_id, reason="CONFIDENCE_CONFLICT", db=db)
            logger.warning(
                "[OCR] confidence conflict for invoice_id=%s",
                invoice_id,
            )

        # --- Walidacja NIP i IBAN ---
        try:
            accounting = AccountingService()
            contractor_nip = payload.get("contractor_nip", "")
            bank_account = payload.get("bank_account", "")
            nip_verification = (
                await accounting.verify_nip(contractor_nip) if contractor_nip else None
            )
            nip_valid = nip_verification is not None
            iban_valid = accounting.validate_iban(bank_account) if bank_account else True
            payload["nip_valid"] = nip_valid
            payload["iban_valid"] = iban_valid
        except Exception as ve:
            logger.warning("[OCR] NIP/IBAN validation error for %s: %s", invoice_id, ve)
            payload["nip_valid"] = False
            payload["iban_valid"] = False

        # --- Context Enrichment ---
        try:
            import duckdb

            conn = duckdb.connect(str(AppConfig().duckdb_path))
            from nexus_ai.services.context_enricher import ContextEnricher, ensure_cache_schema

            ensure_cache_schema(conn)
            enricher = ContextEnricher(conn)
            enriched = await enricher.enrich(payload)
            conn.close()
        except Exception as enrich_err:
            logger.warning("[OCR] ContextEnrichment failed for %s: %s", invoice_id, enrich_err)
            enriched = {
                "vendor_vat_status": "unknown",
                "vendor_pkd": "",
                "vendor_account_on_whitelist": False,
                "vendor_trust": "unknown",
                "vendor_company_name": "",
            }

        # --- Semantic Anomaly Detection ---
        try:
            from nexus_ai.services.semantic_guard import SemanticGuard

            semantic_guard = SemanticGuard()
            full_text = payload.get("ocr_full_text", "")
            amount_net_val = _safe_float(payload.get("amount_net")) or 0.0
            anomaly = semantic_guard.evaluate(
                invoice_text=full_text,
                vendor_nip=payload.get("contractor_nip", ""),
                amount_net=amount_net_val,
            )
            if anomaly.get("action") == "BLOCK_DECREE":
                logger.warning(
                    "[OCR] Semantic anomaly BLOCK %s score=%.4f",
                    invoice_id,
                    anomaly.get("anomaly_score", 0),
                )
                await _mark_invoice_blocked(
                    invoice_id, anomaly.get("alert", "Semantic anomaly detected"), db
                )
                return
        except Exception as sem_err:
            logger.warning("[OCR] SemanticGuard failed for %s: %s", invoice_id, sem_err)
            anomaly = {"action": "ALLOW", "anomaly_score": 0.0, "alert": None}

        field_confidence = _build_field_confidence(payload, consensus)

        extracted_data = {
            "invoice_id": invoice_id,
            "contractor_nip": payload.get("contractor_nip", ""),
            "amount_net": _safe_float(payload.get("amount_net")),
            "amount_gross": consensus.amount_gross or _safe_float(payload.get("amount_gross")),
            "vat": _safe_float(payload.get("vat")),
            "number": payload.get("number", ""),
            "issue_date": payload.get("issue_date", ""),
            "category": payload.get("category", ""),
            "ocr_confidence": _safe_float(payload.get("ocr_confidence"))
            or (1.0 - float(consensus.confidence_conflict) * 0.5),
            "layout_confidence": _safe_float(payload.get("layout_confidence")) or 0.5,
            "amount_consensus": not consensus.confidence_conflict,
            "llm_validation": _safe_float(payload.get("llm_validation")) or 0.5,
            "ocr_full_text": payload.get("ocr_full_text", ""),
            "field_confidence": field_confidence,
            **enriched,
            "semantic_anomaly_score": anomaly.get("anomaly_score", 0.0),
            "semantic_anomaly_alert": anomaly.get("alert"),
            "semantic_action": anomaly.get("action", "ALLOW"),
            "vendor_profile": {
                "known": bool(payload.get("vendor_known", False)),
                "invoice_count": int(payload.get("vendor_invoice_count", 0)),
                "trust_score": float(payload.get("vendor_trust_score", 0.5)),
                "category_consistent": bool(payload.get("vendor_category_consistent", True)),
                "auto_approve": bool(payload.get("vendor_auto_approve", False)),
                "category_preference_match": bool(
                    payload.get("vendor_category_preference_match", True)
                ),
            },
        }

        # --- Field Confidence: Zen-Engine Rules ---
        try:
            import duckdb

            ze_conn = duckdb.connect(str(AppConfig().duckdb_path))
            from nexus_ai.core.context_interpreter import ContextInterpreter as CtxInterpreter
            from nexus_ai.tax.rules import RuleEngine, ensure_tax_schemas, seed_default_rules

            ensure_tax_schemas(ze_conn)
            seed_default_rules(ze_conn)
            ctx_data: dict[str, Any] = {
                "category_code": (payload.get("category") or "").upper(),
                "transaction_date": payload.get("issue_date", "")
                or pendulum.now().date().isoformat(),
                "company_tax_form": payload.get("company_tax_form", "CIT_STANDARD"),
                "vendor_country": payload.get("vendor_country", "PL"),
                "vendor_nip": payload.get("contractor_nip", ""),
                "amount_net": _safe_float(payload.get("amount_net")) or 0,
                "vendor_vat_status": payload.get("vendor_vat_status", "unknown"),
                "field_confidence": field_confidence,
            }
            context = CtxInterpreter.interpret(ctx_data)
            rule_engine = RuleEngine(ze_conn)
            try:
                verdict = rule_engine.decide(context)
                routing = verdict.get("_routing", "")
                routing_reason = verdict.get("_routing_reason", "")
                if routing:
                    extracted_data["field_confidence_routing"] = routing
                    extracted_data["field_confidence_reason"] = routing_reason
                    match routing:
                        case "BLOCK_AND_ALERT":
                            await _mark_invoice_blocked(invoice_id, routing_reason, db)
                            ze_conn.close()
                            return
                        case "TRIAGE_QUEUE":
                            await _mark_invoice_pending_review(
                            invoice_id, reason=f"FIELD_CONFIDENCE: {routing_reason}", db=db
                        )
            except NoMatchingRuleError:
                extracted_data["field_confidence_status"] = "ALL_CONFIDENCE_OK"
            ze_conn.close()
        except Exception as risk_err:
            logger.warning("[OCR] Zen-Engine check failed for %s: %s", invoice_id, risk_err)
            extracted_data["field_confidence_status"] = "CHECK_FAILED"

    # Trigger decision via NATS (poza semaforem)
    from nexus_ai.core.nats_utils import publish_event

    await publish_event(
        "invoice.extracted", {"invoice_id": invoice_id, "extracted_data": extracted_data}
    )

    # Trigger decision task
    try:
        workflow_type = classify_invoice(
            invoice_data=extracted_data, vendor_profile=extracted_data.get("vendor_profile", {})
        )
        await broker.kick("decision_evaluate", invoice_id=invoice_id, extracted_data=extracted_data)
        logger.info("[OCR] workflow=%s for invoice_id=%s", workflow_type, invoice_id)
    except Exception as trigger_err:
        logger.warning("[OCR] failed to trigger checks: %s", trigger_err)

    logger.info("[OCR] processing complete for invoice_id=%s", invoice_id)


@broker.task(
    task_name="process_large_attachment",
    labels={"service": "api", "operation": "attachment", "criticality": "medium"},
    timeout=600.0,
)
async def process_large_attachment(attachment_id: str, payload: dict | None = None) -> None:
    """Dedicated worker path for large attachments uploaded via /upload-large."""
    logger.info("[ATTACHMENT] processing large attachment_id=%s", attachment_id)


async def _mark_invoice_blocked(invoice_id: str, reason: str, db: Session) -> None:
    """Mark invoice as BLOCKED_FRAUD_SUSPICION."""
    await db.execute(
        text(
            "UPDATE invoices SET status = 'BLOCKED_FRAUD_SUSPICION', updated_at = CURRENT_TIMESTAMP WHERE id = :invoice_id"
        ),
        {"invoice_id": invoice_id},
    )
    logger.warning("[FRAUD] Invoice %s blocked: %s", invoice_id, reason)


async def _mark_invoice_pending_review(invoice_id: str, reason: str, db: Session) -> None:
    """Mark invoice for manual review."""
    await db.execute(
        text("UPDATE invoices SET status = 'PENDING_REVIEW' WHERE id = :invoice_id"),
        {"invoice_id": invoice_id},
    )
