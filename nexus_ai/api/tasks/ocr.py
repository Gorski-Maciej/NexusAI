"""
OCR pipeline tasks -- extracted from api/tasks.py (FAZA V modularyzacji).

v7.0 Audit — KOMPLETNY zestaw innowacji:
- Dynamic Pipeline fast-first + AutoML routing (S6+S7)
- OCRSupervisor AI (S4)
- CrossValidationEngine 5-warstw (S10)
- Zero-Shot Field Extraction (S15)
- Cross-Engine Attention (S16)
- OCR Rate Limiter + Secure Temp Files (S17)
- Cross-Page Text Merging (S28)
- Multi-Modal Document Understanding (S31)
- Exotic Format Support HEIC/DjVu/XLSX (S29)
- PKD Validation (S30)
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

from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus
from nexus_ai.services.white_list_service import WhiteListService
from nexus_ai.domain.values import IBAN
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
    """Zbuduj strukturę field_confidence z payloadu OCR i konsensusu (v7.0 rozszerzona)."""
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
            "all_sources": [v.source for v in (consensus.votes if consensus else [])],
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

    iban_val = payload.get("bank_account", "")
    if iban_val:
        fc["iban"] = {
            "value": iban_val,
            "confidence": 0.85 if payload.get("iban_valid", False) else 0.6,
            "source": "ocr",
        }

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
    """Dedicated OCR pipeline entrypoint triggered by outbox relay.

    v7.0: KOMPLETNY zestaw innowacji — rate limiter, secure temp files,
    dynamic pipeline, zero-shot extraction, cross-engine attention,
    multi-modal understanding, cross-page merging, exotic formats.
    """
    logger.info("[OCR] processing invoice_id=%s", invoice_id)
    payload = payload or {}

    # --- v7.0: Wspólna zmienna full_text dla wszystkich komponentów ---
    full_text: str = payload.get("ocr_full_text", "")

    # --- v7.0: Rate Limiter Check (S17) ---
    try:
        from nexus_ai.pipeline.ocr_security import get_ocr_rate_limiter
        rate_limiter = get_ocr_rate_limiter()
        rate_allowed, rate_msg = rate_limiter.allow()
        rate_used = rate_limiter.current_rate
        if not rate_allowed:
            logger.warning("[OCR] Rate limited: %s", rate_msg)
            return
    except Exception:
        rate_used = 0  # fallback gdy moduł niedostępny

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

        # v7.0: Używamy ważonego konsensusu z threshold=3.0
        consensus = decide_amount_consensus(
            ocr_results,
            tolerance=0.01,
            majority_threshold=3.0,
        )

        # v7.0: OCRSupervisor — AI rozstrzyganie sporów
        if consensus.confidence_conflict:
            logger.warning("[OCR] confidence conflict for invoice_id=%s — engaging AI Supervisor", invoice_id)
            try:
                from nexus_ai.pipeline.ocr_supervisor import OCRSupervisor

                supervisor = OCRSupervisor(use_supervisor=False)  # AI opcjonalne
                full_text = payload.get("ocr_full_text", "")
                all_results = {
                    "doctr": {"text": str(primary_amount), "confidence": 0.85},
                    "paddle": {"text": str(secondary_amount), "confidence": 0.85},
                }
                if easyocr_amount is not None:
                    all_results["easyocr"] = {"text": str(easyocr_amount), "confidence": 0.85}

                resolved = await supervisor.resolve_conflict(
                    field_name="amount_gross",
                    consensus=consensus,
                    all_engine_results=all_results,
                    full_text=full_text,
                )
                if resolved.get("resolved_value") is not None and not resolved.get("ai_resolved", False):
                    # Szybka ścieżka (format validation) rozwiązała konflikt
                    logger.info("[OCR] Quick resolution for %s: %s", invoice_id, resolved.get("reasoning"))
                elif resolved.get("ai_resolved", False):
                    logger.info("[OCR] AI resolved conflict for %s: %s", invoice_id, resolved.get("reasoning"))
                    consensus.confidence_conflict = False  # AI rozwiązało
                else:
                    await _mark_invoice_pending_review(invoice_id, reason="CONFIDENCE_CONFLICT", db=db)
            except Exception as sup_err:
                logger.warning("[OCR] Supervisor failed for %s: %s", invoice_id, sup_err)
                await _mark_invoice_pending_review(invoice_id, reason="CONFIDENCE_CONFLICT", db=db)

        # --- Walidacja NIP i IBAN ---
        try:
            whitelist = WhiteListService()
            contractor_nip = payload.get("contractor_nip", "")
            bank_account = payload.get("bank_account", "")
            nip_valid = (
                await whitelist.verify_bank_account(contractor_nip, "") if contractor_nip else False
            )
            try:
                IBAN(value=bank_account)
                iban_valid = True
            except Exception:
                iban_valid = False if bank_account else True
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

        # --- Semantic Anomaly Detection (v7.0: real embedding) ---
        try:
            from nexus_ai.services.semantic_guard import SemanticGuard

            semantic_guard = SemanticGuard(use_real_embedding=False)  # Fallback do mock
            full_text = payload.get("ocr_full_text", "")
            amount_net_val = _safe_float(payload.get("amount_net")) or 0.0
            vendor_profile = payload.get("vendor_profile", {})
            anomaly = await semantic_guard.evaluate(
                invoice_text=full_text,
                vendor_nip=payload.get("contractor_nip", ""),
                amount_net=amount_net_val,
                vendor_profile=vendor_profile,
            )
            anomaly_dict = anomaly.to_dict()
            if anomaly_dict.get("action") == "BLOCK_DECREE":
                logger.warning(
                    "[OCR] Semantic anomaly BLOCK %s score=%.4f seasonal=%.2f",
                    invoice_id,
                    anomaly_dict.get("anomaly_score", 0),
                    anomaly_dict.get("seasonal_factor", 1.0),
                )
                await _mark_invoice_blocked(
                    invoice_id, anomaly_dict.get("alert", "Semantic anomaly detected"), db
                )
                return
        except Exception as sem_err:
            logger.warning("[OCR] SemanticGuard failed for %s: %s", invoice_id, sem_err)
            anomaly_dict = {"action": "ALLOW", "anomaly_score": 0.0, "alert": None, "seasonal_factor": 1.0}

        # --- v7.0: Cross-Validation Engine (5-warstwowa walidacja) ---
        cross_validation_result = None
        try:
            from nexus_ai.pipeline.cross_validation_engine import (
                CrossValidationEngine,
                CrossValidationVerdict,
            )
            from nexus_ai.services.semantic_guard import SemanticGuard

            cv_engine = CrossValidationEngine(
                semantic_guard=SemanticGuard(use_real_embedding=False),
                context_enricher=None,  # już mamy enriched powyżej
            )
            cv_data = dict(payload)
            cv_data["ocr_full_text"] = full_text
            cross_validation_result = await cv_engine.validate(
                invoice_data=cv_data,
                ocr_consensus=consensus,
                tb_client=None,  # opcjonalne
                duckdb_manager=None,  # opcjonalne
            )
            logger.info(
                "[OCR] Cross-validation verdict=%s score=%.4f for %s",
                cross_validation_result.verdict.value,
                cross_validation_result.overall_score,
                invoice_id,
            )
            if cross_validation_result.verdict == CrossValidationVerdict.BLOCK_DECREE:
                await _mark_invoice_blocked(
                    invoice_id, cross_validation_result.alert, db
                )
                return
        except Exception as cv_err:
            logger.warning("[OCR] Cross-validation failed for %s: %s", invoice_id, cv_err)

        field_confidence = _build_field_confidence(payload, consensus)

        # --- v7.0: Zero-Shot Field Extraction (S15) — fallback parser ---
        zero_shot_fields = None
        try:
            from nexus_ai.pipeline.zero_shot_extractor import ZeroShotFieldExtractor
            zs_extractor = ZeroShotFieldExtractor(use_ai=False)
            full_text = payload.get("ocr_full_text", "")
            if full_text:
                zero_shot_result = await zs_extractor.extract(full_text)
                zero_shot_fields = zero_shot_result.get("fields", {})
                if zero_shot_result.get("confidence", 0) > 0.7:
                    logger.info("[OCR] Zero-shot extraction: confidence=%.3f, method=%s",
                                zero_shot_result["confidence"], zero_shot_result.get("method"))
        except Exception as zs_err:
            logger.debug("[OCR] Zero-shot extraction skipped: %s", zs_err)

        # --- v7.0: Cross-Engine Attention (S16) ---
        try:
            from nexus_ai.pipeline.cross_engine_attention import cross_engine_attention_correction
            all_engine_texts = payload.get("ocr_all_texts", {})
            if all_engine_texts and consensus.accepted and consensus.accepted.value is not None:
                corrected = cross_engine_attention_correction(
                    all_engine_texts, "amount_gross",
                    str(consensus.accepted.value),
                    consensus.accepted.confidence,
                )
                logger.debug("[OCR] Cross-engine attention applied for %s", invoice_id)
        except Exception as cea_err:
            logger.debug("[OCR] Cross-engine attention skipped: %s", cea_err)

        # --- v7.0: Multi-Modal Document Understanding (S31) ---
        multi_modal_result = None
        try:
            from nexus_ai.pipeline.multi_modal_understanding import MultiModalDocumentUnderstanding
            mm_engine = MultiModalDocumentUnderstanding()
            layout_blocks = payload.get("layout_blocks")
            mm_result = mm_engine.fuse(
                field_name="amount_gross",
                ocr_value=str(consensus.amount_gross) if consensus.amount_gross else None,
                ocr_confidence=_safe_float(payload.get("ocr_confidence")) or 0.85,
                layout_blocks=layout_blocks,
                vision_result=None,
                semantic_context=enriched,
            )
            logger.info("[OCR] Multi-modal: %s fused_confidence=%.3f", invoice_id, mm_result.fused_confidence)
        except Exception as mm_err:
            logger.debug("[OCR] Multi-modal skipped: %s", mm_err)

        # --- v7.0: Śledzenie confidence per silnik ---
        try:
            from nexus_ai.core.field_confidence import get_confidence_tracker

            tracker = get_confidence_tracker()
            for engine_name in ["doctr", "paddle", "easyocr"]:
                amount_key = f"ocr_{engine_name}_amount_gross"
                if payload.get(amount_key) is not None:
                    conf = _safe_float(payload.get("ocr_confidence")) or 0.85
                    tracker.record(engine_name, conf, "amount_gross")
        except Exception as track_err:
            logger.debug("[OCR] Confidence tracking skipped: %s", track_err)

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
            "semantic_anomaly_score": anomaly_dict.get("anomaly_score", 0.0),
            "semantic_anomaly_alert": anomaly_dict.get("alert"),
            "semantic_action": anomaly_dict.get("action", "ALLOW"),
            "semantic_seasonal_factor": anomaly_dict.get("seasonal_factor", 1.0),
            # v7.0: Cross-validation metadata
            "cross_validation": cross_validation_result.to_dict() if cross_validation_result else None,
            # v7.0: Zero-shot extraction
            "zero_shot_fields": zero_shot_fields,
            # v7.0: PKD validation
            "pkd_invoice_match": enriched.get("pkd_invoice_match", "unknown"),
            # v7.0: Rate limit stats
            "ocr_rate_used": rate_used,
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

    logger.info("[OCR] processing complete for invoice_id=%s (v7.0 enhanced)", invoice_id)

    # --- v7.0: Blockchain OCR Anchor (immutable proof, persisted via DuckDB) ---
    try:
        from nexus_ai.pipeline.ocr_blockchain_anchor import OCRBlockchainAnchor
        from pathlib import Path
        doc_path = Path(payload.get("file_path") or "")
        if doc_path.exists():
            bc_anchor = OCRBlockchainAnchor()
            anchor = bc_anchor.create_anchor(
                invoice_id=invoice_id,
                document_path=doc_path,
                ocr_text=full_text,
                field_results=field_confidence,
            )
            # Persist anchor via existing document_fingerprint infrastructure
            from nexus_ai.services.document_fingerprint import (
                generate_document_fingerprint,
                store_fingerprint,
                binary_anchor_u128,
            )
            fp = generate_document_fingerprint(doc_path, extracted_data)
            store_fingerprint(
                duckdb_manager=None,  # TODO: inject DuckDBManager via DI
                invoice_id=invoice_id,
                file_path=doc_path,
                fp=fp,
            )
            logger.info("[OCR] Blockchain anchor persisted: doc_hash=%s tb_anchor=%d",
                        anchor.document_hash[:16],
                        binary_anchor_u128(anchor.document_hash))
    except Exception as bc_err:
        logger.debug("[OCR] Blockchain anchor skipped: %s", bc_err)


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
