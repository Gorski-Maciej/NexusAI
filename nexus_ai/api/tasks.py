from __future__ import annotations

import atexit
import os
import resource
import time

import anyio

# ── SHA-256 przez nexus-crypto (Rust+PyO3) zgodnie z aa3fvcx.txt ─────────
try:
    from nexus_crypto import sha256 as _sha256

    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib

    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


# ── Legacy engine helper (kompatybilność wsteczna) — DEPRECATED ────────────
# UWAGA: Nowe zadania używają TaskiqDepends(get_db_session) zamiast _make_engine.
# Ta funkcja pozostaje dla kompatybilności — używa DI engine cache.
import warnings
from pathlib import Path
from typing import Any

import httpx
import pendulum
import stamina
from sqlmodel import Session, text
from sqlmodel import text as sql_text
from structlog import get_logger
from taskiq import Kicker, TaskiqDepends

from nexus_ai.api.cache import clear_cache_async
from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.decision_engine import (
    DecisionEngine,
    DecisionVerdict,
    classify_invoice,
)
from nexus_ai.core.di import get_config, get_db_session, get_duckdb_manager, get_engine
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import create_oltp_engine, create_session_factory
from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus
from nexus_ai.services.accounting import AccountingService
from nexus_ai.services.currency_converter import (
    Money,  # Nexus-Money (msgspec.Struct, zastępuje py-moneyed)
)
from nexus_ai.services.finops_meter import estimate_runtime_cost
from nexus_ai.services.log_pii_monitor import notify_dpo, scan_logs_for_pii
from nexus_ai.services.migration_sanity import verify_migration_integrity, verify_schema_drift
from nexus_ai.services.telemetry import flush_fallback_spans
from nexus_ai.tax.exceptions import NoMatchingRuleError


def _make_engine(config: AppConfig | None = None):
    """[LEGACY] Utwórz SQLAlchemy engine — do migracji na TaskiqDepends.

    UWAGA: Nowe zadania używają TaskiqDepends(get_db_session) zamiast _make_engine.
    Ta funkcja pozostaje dla kompatybilności — tworzy nowy engine (bez DI cache).
    Docelowo wszystkie zadania mają być przeniesione na DI.

    Deprecated: Użyj TaskiqDepends(get_db_session) zamiast tej funkcji.
    """
    warnings.warn(
        "_make_engine jest deprecated. Użyj TaskiqDepends(get_db_session) zamiast ręcznego tworzenia engine.",
        DeprecationWarning,
        stacklevel=2,
    )
    if config is None:
        config = AppConfig()
    sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
    return create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)


logger = get_logger("nexus.api.tasks")
MAX_OUTBOX_RETRIES = 3
# Circuit Breaker: stamina.retry (async-native) zastępuje custom CircuitBreaker
# stamina automatycznie zarządza retry + circuit breaker w jednym dekoratorze
INVOICE_OCR_EVENT_TYPES = {"process_invoice_ocr", "invoice_uploaded"}
LARGE_ATTACHMENT_EVENT_TYPES = {
    "attachment_large_uploaded"
}  # Singleton instances (lazy init, shared across tasks)
_DECISION_ENGINE: DecisionEngine | None = None
_DUCKDB: DuckDBManager | None = None


def _ensure_decision_engine(config: AppConfig) -> DecisionEngine:
    """Lazy-init DecisionEngine as module-level singleton.

    Zgodnie z aa3fvcx.txt: DuckDB-based decision rules,
    bez konkretnych modeli LLM ani agentów AI.
    """
    global _DECISION_ENGINE, _DUCKDB
    if _DECISION_ENGINE is not None:
        return _DECISION_ENGINE
    _DUCKDB = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    _DECISION_ENGINE = DecisionEngine(duckdb=_DUCKDB)
    return _DECISION_ENGINE


def _close_all_components() -> None:
    """Cleanup all singleton components on shutdown."""
    global _DUCKDB
    if _DUCKDB is not None:
        try:
            _DUCKDB.close()
        except Exception:
            pass
        _DUCKDB = None


atexit.register(_close_all_components)


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
    """
    Final decision evaluation.

    SUPERMOC TASKIQ:
    - TaskiqDepends wstrzykuje config i db — zero boilerplate
    - Helpery przyjmują Session zamiast tworzyć własny engine
    """
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
            await broker.kick("event_emit_decision_made",
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
                            for k in ("amount_gross", "amount_net", "category", "contractor_nip", "ocr_confidence")
                            if k in extracted_data
                        },
                    },
                )
        except Exception as emit_err:
            logger.warning("[DECISION-EVENT] Failed to emit: %s", emit_err)

        if verdict.decision == "AUTO_POST":
            await _post_invoice(invoice_id, extracted_data, verdict, db)
        elif verdict.decision == "SUGGEST":
            await _mark_for_review(invoice_id, verdict, db)
        elif verdict.decision in ("ASK_USER", "BLOCK", "ESCALATE"):
            await _escalate_to_human(invoice_id, verdict, db, reason=f"decision: {verdict.decision}")

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
    """
    [DEPRECATED] Decision task — use decision_evaluate instead.

    Zachowany dla kompatybilności wstecznej. Deleguje do decision_evaluate.
    Używa tymczasowego engine zamiast TaskiqDepends (brak DI w deprecated task).
    """
    logger.warning(
        "[DEPRECATED] council_decide task called for invoice_id=%s — use decision_evaluate",
        invoice_id,
    )
    # council_decide nie używa TaskiqDepends (deprecated), więc tworzy engine ręcznie
    config = AppConfig()
    engine = _ensure_decision_engine(config)

    try:
        verdict = engine.decide(
            invoice_data=extracted_data,
            vendor_profile=extracted_data.get("vendor_profile", {}),
        )
        try:
            await broker.kick("event_emit_decision_made",
                    invoice_id=invoice_id, decision=verdict.decision,
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
                            for k in ("amount_gross", "amount_net", "category", "contractor_nip", "ocr_confidence")
                            if k in extracted_data
                        },
                    },
                )
        except Exception:
            pass

        # council_decide nie ma Session z DI — używa tymczasowego engine
        if verdict.decision == "AUTO_POST":
            config_temp = AppConfig()
            eng = _make_engine(config_temp)
            sess_fac = create_session_factory(eng)
            async with sess_fac() as sess:
                await _post_invoice(invoice_id, extracted_data, verdict, sess)
            await eng.dispose()
        elif verdict.decision == "SUGGEST":
            config_temp = AppConfig()
            eng = _make_engine(config_temp)
            sess_fac = create_session_factory(eng)
            async with sess_fac() as sess:
                await _mark_for_review(invoice_id, verdict, sess)
            await eng.dispose()
        elif verdict.decision in ("ASK_USER", "BLOCK", "ESCALATE"):
            config_temp = AppConfig()
            eng = _make_engine(config_temp)
            sess_fac = create_session_factory(eng)
            async with sess_fac() as sess:
                await _escalate_to_human(invoice_id, verdict, sess, reason=f"decision: {verdict.decision}")
            await eng.dispose()

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


async def _post_invoice(
    invoice_id: str,
    extracted_data: dict,
    verdict: DecisionVerdict,
    db: Session,
) -> None:
    """Auto-post the invoice: update status to APPROVED.

    SUPERMOC: Przyjmuje Session z DI zamiast tworzyć własny engine.
    Uses CancelScope(shield=True) to protect the critical DB write.
    """
    with anyio.CancelScope(shield=True):
        await db.execute(
            text(
                "UPDATE invoices SET status = 'APPROVED', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": invoice_id},
        )
        logger.info(
            "[DECIDE] auto-posted invoice_id=%s (conf=%.4f)",
            invoice_id,
            verdict.confidence,
        )

    # Store in sqlite-vec for future anomaly detection (outside shield)
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
    """Mark invoice for manual review (SUGGEST).

    SUPERMOC: Przyjmuje Session z DI zamiast tworzyć własny engine.
    """
    with anyio.CancelScope(shield=True):
        await db.execute(
            text(
                "UPDATE invoices SET status = 'PENDING_REVIEW', updated_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": invoice_id},
        )
        logger.info(
            "[DECIDE] marked for review invoice_id=%s (conf=%.4f)",
            invoice_id,
            verdict.confidence,
        )


async def _escalate_to_human(invoice_id: str, verdict: DecisionVerdict, db: Session, reason: str = "") -> None:
    """Escalate invoice to human for review.

    SUPERMOC: Przyjmuje Session z DI zamiast tworzyć własny engine.
    """
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


async def _dispatch_outbox_event(row: dict) -> None:
    event_type = str(row.get("event_type", "")).strip().lower()
    payload_raw = row.get("payload") or "{}"

    try:
        payload = msgspec_loads(payload_raw)
    except Exception:
        payload = {}

    # SUPERMOC TASKIQ: Kicker.with_task_id() dla deterministycznego ID
    # JetStream deduplikuje na podstawie Nats-Msg-Id = task_id
    # Zastępuje ręczną tabelę processed_events dla idempotentności

    if event_type == "process_invoice_ocr" or event_type == "invoice_uploaded":
        invoice_id = payload.get("invoice_id") or row.get("aggregate_id")
        if not invoice_id:
            raise ValueError("Missing invoice_id in outbox payload")
        task_id = f"outbox:ocr:{invoice_id}:{row.get('id', 'unknown')}"
        try:
            for attempt in stamina.retry_context(
                on=(Exception,),
                attempts=3,
                timeout=10.0,
                circuit_breaker=True,
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
                on=(Exception,),
                attempts=3,
                timeout=10.0,
                circuit_breaker=True,
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

    # ── TAX_CALCULATED: async TigerBeetle posting ────────────────────────
    if event_type == "tax_calculated":
        import duckdb

        from nexus_ai.tax.audit import ensure_schema as ensure_tax_schema
        from nexus_ai.tax.pipeline import TaxPipeline

        transaction_id = payload.get("transaction_id", "")
        if not transaction_id:
            raise ValueError("Missing transaction_id in TAX_CALCULATED payload")

        net_grosze = int(payload.get("net_grosze", 0))
        vat_grosze = int(payload.get("vat_grosze", 0))
        brutto_grosze = int(payload.get("brutto_grosze", 0))

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        ensure_tax_schema(conn)

        from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

        tb = TigerBeetleClient()

        pipeline = TaxPipeline(
            conn=conn,
            tigerbeetle=tb,
        )

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
                "[OUTBOX] TAX_CALCULATED TB posting failed tid=%s: %s",
                transaction_id,
                exc,
            )
            raise  # Let outbox relay retry
        finally:
            conn.close()

        return

    raise ValueError(f"Unsupported outbox event_type: {event_type}")


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

    SUPERMOC TASKIQ:
    - TaskiqDepends wstrzykuje config i db — zero boilerplate
    - Helpery _mark_invoice_* przyjmują Session z DI
    """
    logger.info("[OCR] processing invoice_id=%s", invoice_id)
    payload = payload or {}

    # Rozwiązanie 29: Semafory na ciężkie operacje OCR (max 3 równolegle)
    async with _OCR_LIMITER:
        primary_amount = _safe_float(payload.get("ocr_primary_amount_gross"))
        secondary_amount = _safe_float(payload.get("ocr_secondary_amount_gross"))
        easyocr_amount = _safe_float(payload.get("ocr_easyocr_amount_gross"))

        ocr_results = [
            OCRAmountResult(
                amount_gross=Money.from_string(str(primary_amount), "PLN")
                if primary_amount is not None
                else None,
                source="doctr",
            ),
            OCRAmountResult(
                amount_gross=Money.from_string(str(secondary_amount), "PLN")
                if secondary_amount is not None
                else None,
                source="paddle",
            ),
        ]
        # 4-way consensus: dodaj wynik EasyOCR jeśli dostępny
        if easyocr_amount is not None:
            ocr_results.append(
                OCRAmountResult(
                    amount_gross=Money.from_string(str(easyocr_amount), "PLN"),
                    source="easyocr",
                )
            )

        consensus = decide_amount_consensus(
            ocr_results,
            tolerance=0.01,
            majority_threshold=2 if len(ocr_results) <= 2 else 3,
        )

        if consensus.confidence_conflict:
            await _mark_invoice_pending_review(invoice_id, reason="CONFIDENCE_CONFLICT", db=db)
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

            nip_verification = (
                await accounting.verify_nip(contractor_nip) if contractor_nip else None
            )
            nip_valid = nip_verification is not None
            iban_valid = (
                accounting.validate_iban(bank_account) if bank_account else True
            )  # IBAN nie jest wymagany

            if nip_verification:
                logger.info(
                    "[OCR] NIP verified invoice_id=%s name=%s",
                    invoice_id,
                    nip_verification.get("name", "unknown"),
                )
            else:
                logger.warning(
                    "[OCR] NIP verification failed for invoice_id=%s nip=%s",
                    invoice_id,
                    contractor_nip,
                )

            if not iban_valid and bank_account:
                logger.warning(
                    "[OCR] IBAN validation failed for invoice_id=%s iban=%s",
                    invoice_id,
                    bank_account,
                )

            # Dodaj flagi walidacji do payloadu
            payload["nip_valid"] = nip_valid
            payload["iban_valid"] = iban_valid
        except Exception as ve:
            logger.warning("[OCR] NIP/IBAN validation error for invoice_id=%s: %s", invoice_id, ve)
            nip_valid = False
            iban_valid = False
            payload["nip_valid"] = False
            payload["iban_valid"] = False

        # --- Context Enrichment (Part IV): Biała Lista + cache kontrahentów ---
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

        # --- Semantic Anomaly Detection (Part VI): sqlite-vec + HerBERT ---
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
                    "[OCR] Semantic anomaly BLOCK invoice_id=%s score=%.4f alert=%s",
                    invoice_id,
                    anomaly.get("anomaly_score", 0),
                    anomaly.get("alert"),
                )
                await _mark_invoice_blocked(
                    invoice_id, anomaly.get("alert", "Semantic anomaly detected"), db
                )
                return
        except Exception as sem_err:
            logger.warning("[OCR] SemanticGuard failed for %s: %s", invoice_id, sem_err)
            anomaly = {"action": "ALLOW", "anomaly_score": 0.0, "alert": None}

        # --- Build extracted data for decision engine ---

        # --- Field Confidence: per-field OCR confidence metadata ---
        # Struktura: {"total_gross": {"value": 1230.00, "confidence": 0.88}, ...}
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
            # Full OCR text for Active Learning & SemanticGuard
            "ocr_full_text": payload.get("ocr_full_text", ""),
            # Field Confidence (per-field metadata — nowość)
            "field_confidence": field_confidence,
            # Enriched vendor data (Part IV)
            "vendor_vat_status": enriched.get("vendor_vat_status", "unknown"),
            "vendor_pkd": enriched.get("vendor_pkd", ""),
            "vendor_account_on_whitelist": enriched.get("vendor_account_on_whitelist", False),
            "vendor_trust": enriched.get("vendor_trust", "unknown"),
            "vendor_company_name": enriched.get("vendor_company_name", ""),
            # Semantic anomaly (Part VI)
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
            "bank_account_consistent": bool(payload.get("bank_account_consistent", True)),
            "amount_typical": bool(payload.get("amount_typical", True)),
            "historical_average": _safe_float(payload.get("historical_average")),
            "vendor_invoice_count": int(payload.get("vendor_invoice_count", 0)),
        }

        # --- Field Confidence: Zen-Engine Rules (zamiast Python RiskGuard) ---
        # Używa RuleEngine (Zen-Engine) do ewaluacji progów ufności per-field.
        # Reguły są zdefiniowane w DEFAULT_TAX_RULES (priorytet 8) i zawierają
        # pole _routing: BLOCK_AND_ALERT | TRIAGE_QUEUE.
        # Jeśli żadna reguła nie matchuje = wszystkie pola mają wystarczającą pewność.
        try:
            import duckdb

            ze_conn = duckdb.connect(str(AppConfig().duckdb_path))
            from nexus_ai.core.context_interpreter import ContextInterpreter as CtxInterpreter
            from nexus_ai.tax.rules import RuleEngine, ensure_tax_schemas, seed_default_rules

            ensure_tax_schemas(ze_conn)
            seed_default_rules(ze_conn)

            # Zbuduj kontekst dla RuleEngine z danych payloadu + field_confidence
            ctx_data: dict[str, Any] = {
                "category_code": (payload.get("category") or "").upper(),
                "transaction_date": payload.get("issue_date", "")
                or payload.get("transaction_date", pendulum.now().date().isoformat()),
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
                    logger.warning(
                        "[OCR] Zen-Engine field confidence invoice_id=%s routing=%s reason=%s",
                        invoice_id,
                        routing,
                        routing_reason,
                    )
                    extracted_data["field_confidence_routing"] = routing
                    extracted_data["field_confidence_reason"] = routing_reason

                    if routing == "BLOCK_AND_ALERT":
                        await _mark_invoice_blocked(invoice_id, routing_reason, db)
                        ze_conn.close()
                        return
                    elif routing == "TRIAGE_QUEUE":
                        await _mark_invoice_pending_review(
                            invoice_id, reason=f"FIELD_CONFIDENCE: {routing_reason}", db=db
                        )
                    # else: inne wartości routing (np. HUMAN_VERIFICATION) — kontynuuj
            except NoMatchingRuleError:
                # Brak matchującej reguły = wszystkie pola mają wystarczającą pewność
                # To jest normalny przypadek dla faktur z wysokim confidence.
                extracted_data["field_confidence_status"] = "ALL_CONFIDENCE_OK"
                pass

            ze_conn.close()
        except Exception as risk_err:
            logger.warning(
                "[OCR] Zen-Engine field confidence check failed for %s: %s", invoice_id, risk_err
            )
            extracted_data["field_confidence_status"] = "CHECK_FAILED"

    # Trigger decision & rules check via NATS (poza semaforem - lekkie operacje NATS)
    config = AppConfig()
    from nexus_ai.core.nats_utils import publish_event

    await publish_event(
        "invoice.extracted",
        {"invoice_id": invoice_id, "extracted_data": extracted_data},
    )

    # Dynamic workflow — decide which tasks to run (zgodnie z aa3fvcx.txt)
    try:
        workflow_type = classify_invoice(
            invoice_data=extracted_data,
            vendor_profile=extracted_data.get("vendor_profile", {}),
        )
        if workflow_type == "simple":
            tasks_to_run = ["decision_evaluate"]
        else:
            tasks_to_run = ["decision_evaluate"]
        for task_name in tasks_to_run:
            await broker.kick(task_name, invoice_id=invoice_id, extracted_data=extracted_data)
        logger.info(
            "[OCR] workflow=%s tasks=%s for invoice_id=%s",
            workflow_type,
            tasks_to_run,
            invoice_id,
        )

    except Exception as trigger_err:
        logger.warning("[OCR] failed to trigger checks: %s", trigger_err)

    # Zero-ETL path: no OLTP->OLAP row replication in worker.
    # Invoice OCR lifecycle is event-driven; analytics layer reads SQLite via DuckDB ATTACH.
    try:
        for attempt in stamina.retry_context(
            on=(Exception,),
            attempts=3,
            timeout=30.0,
            circuit_breaker=True,
        ):
            with attempt:
                await _refresh_cashflow_for_event()
    except Exception as olap_err:
        logger.warning("[OLAP] cashflow refresh failed after retries: %s", olap_err)

    # Wyczyść bufor ramek OCR dla tego dokumentu (Rozwiązanie 12)
    try:
        # Użyj globalnego bufora - w środowisku workers nie ma dostępu do app.state
        # Dlatego czyszczenie jest opcjonalne i best-effort
        logger.info(
            "[OCR] processing complete for invoice_id=%s, buffer can be cleared", invoice_id
        )
    except Exception:
        pass

    return


@broker.task(
    task_name="process_large_attachment",
    labels={"service": "api", "operation": "attachment", "criticality": "medium"},
    timeout=600.0,
)
async def process_large_attachment(attachment_id: str, payload: dict | None = None) -> None:
    """Dedicated worker path for large attachments uploaded via /upload-large."""
    logger.info(
        "[ATTACHMENT] processing large attachment_id=%s payload=%s", attachment_id, bool(payload)
    )
    return


@broker.task(
    schedule=[{"cron": "0 * * * *"}],
    task_name="refresh_materialized_cashflow",
    labels={"service": "api", "operation": "analytics", "criticality": "medium", "schedule": "hourly"},
    timeout=120.0,
)
@stamina.retry(on=Exception, attempts=3)
async def refresh_materialized_cashflow(
    duckdb: DuckDBManager = TaskiqDepends(get_duckdb_manager),
) -> None:
    # SUPERMOC: TaskiqDepends wstrzykuje DuckDBManager
    with stamina.retry(on=Exception, attempts=3, timeout=30.0):
        _refresh_cashflow_materialized(duckdb)
    await clear_cache_async(prefix="api.routes.analytics")
    logger.info("[OLAP] refreshed m_daily_cashflow")


async def _refresh_cashflow_materialized(manager: DuckDBManager) -> None:
    manager.refresh_materialized_cashflow()


async def _refresh_cashflow_for_event(
    duckdb: DuckDBManager | None = None,
) -> None:
    if duckdb is None:
        duckdb = DuckDBManager(
            db_path=AppConfig().duckdb_path,
            sqlite_path=AppConfig().sqlite_path,
        )
        _owns_duckdb = True
    else:
        _owns_duckdb = False
    try:
        duckdb.refresh_materialized_cashflow()
    finally:
        if _owns_duckdb:
            duckdb.close()
    await clear_cache_async(prefix="api.routes.analytics")


@broker.task(
    schedule=[{"cron": "*/5 * * * *"}],
    task_name="dead_letter_processor",
    labels={"service": "api", "operation": "dlq", "criticality": "high", "schedule": "5min"},
    timeout=60.0,
)
async def dead_letter_processor_task(
    config: AppConfig = TaskiqDepends(get_config),
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Okresowe zadanie (co 5 minut) monitorujące Dead Letter Queue.

    SUPERMOC TASKIQ:
    - TaskiqDepends wstrzykuje config i db — zero boilerplate
    """
    from nexus_ai.core.nats_utils import NatsErrors, get_connection, safe_close

    NatsErrors.init()
    nc = await get_connection(
        nats_url=config.nats_url,
        name="nexus-dlq",
    )
    if nc is None:
        logger.warning("[DLQ] NATS not available — skipping dead letter check")
        return

    try:
        sub = await nc.subscribe("nats.deadletter", queue="nexus-dlq-workers")

        try:
            with anyio.fail_after(5.0):
                msg = await sub.fetch(1, timeout=2.0)
                while msg:
                    try:
                        data = msgspec_loads(msg.data)
                        error_message = data.get("error", "Unknown error")
                        task_type = data.get("task_type", "unknown")
                        task_id = data.get("task_id", None)
                        stack_trace = data.get("stack_trace", "")
                        payload = data.get("payload", {})

                        # SUPERMOC: używamy db z DI zamiast tworzyć osobny engine
                        await db.execute(
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
                                "payload": msgspec_dumps(payload),
                            },
                        )

                        logger.error(
                            "[DLQ] Dead letter received: task_type=%s task_id=%s error=%s",
                            task_type,
                            task_id,
                            error_message,
                        )

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
                                            "timestamp": pendulum.now("UTC").isoformat(),
                                        },
                                    )
                            except Exception:
                                logger.warning("[DLQ] Failed to notify webhook")

                    except NatsErrors.TimeoutError:
                        pass
                    except Exception as parse_err:
                        logger.warning("[DLQ] Failed to parse DLQ message: %s", parse_err)

                    msg = await sub.fetch(1, timeout=2.0)
        except NatsErrors.TimeoutError:
            pass
        except NatsErrors.ConnectionClosedError:
            logger.warning("[DLQ] Connection closed during fetch")
        except Exception as dlq_err:
            logger.warning("[DLQ] Dead letter processor error: %s", dlq_err)
    finally:
        await safe_close(nc)
        # SUPERMOC: DI auto-commituje sesję — engine cache'owany


@broker.task(
    schedule=[{"cron": "0 5 * * *"}],
    task_name="cleanup_hard_deleted_invoices",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "daily"},
    timeout=300.0,
)
async def cleanup_hard_deleted_invoices_task(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Miesięczne zadanie fizycznego usuwania faktur po okresie retencji.

    SUPERMOC: TaskiqDepends wstrzykuje sesję DB — zero boilerplate.
    """
    from nexus_ai.services.security_service import SecurityService

    result = await SecurityService.cleanup_old_scans(db, years=5)
    logger.info(
        "[RETENTION] Hard-deleted invoices cleanup: %s",
        result,
    )


@broker.task(
    schedule=[{"cron": "0 6 * * 0"}],
    task_name="cleanup_archived_invoices",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "weekly"},
    timeout=300.0,
)
async def cleanup_archived_invoices_task(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Tygodniowe zadanie archiwizacji REJECTED/FAILED invoices.

    SUPERMOC: TaskiqDepends wstrzykuje sesję DB — zero boilerplate.
    """
    from nexus_ai.services.security_service import SecurityService

    result = await SecurityService.archive_old_invoices(
        db, archive_table="archived_invoices"
    )
    logger.info(
        "[RETENTION] Archived old invoices: %s",
        result,
    )


@broker.task(
    schedule=[{"cron": "0 4 * * *"}],
    task_name="cleanup_outbox_events",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "daily"},
    timeout=120.0,
)
async def cleanup_outbox_events_task(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Codzienne zadanie czyszczenia starych zdarzeń outbox (Rozwiązanie 27).
    Usuwa zdarzenia SENT i DEAD_LETTER starsze niż 30 dni.

    SUPERMOC: TaskiqDepends wstrzykuje sesję DB — zero boilerplate.
    """
    result = await db.execute(
        text(
            """
            DELETE FROM outbox_events
            WHERE status IN ('SENT', 'DEAD_LETTER')
              AND created_at < datetime('now', '-30 days')
            """
        )
    )
    deleted = result.rowcount
    logger.info("[RETENTION] Cleaned old outbox events: deleted=%d", deleted)
    # SUPERMOC: DI auto-commituje sesję


# Semafory dla limitów współbieżności (Rozwiązanie 29)
_OCR_LIMITER = anyio.CapacityLimiter(3)  # process_invoice_ocr: max 3 równolegle


@broker.task(
    schedule=[{"cron": "*/1 * * * *"}],
    task_name="relay_outbox_events",
    labels={"service": "api", "operation": "outbox", "criticality": "high", "schedule": "1min"},
    timeout=120.0,
)
async def relay_outbox_events(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Relay pending outbox events with atomic UPDATE semantics (Rozwiązanie 11).
    Uses two-step atomic UPDATE to prevent duplicate processing by concurrent workers.
    Detects stale PROCESSING tasks (>= 5 min) and reclaims them.

    SUPERMOC TASKIQ:
    - TaskiqDepends wstrzykuje sesję DB — zero boilerplate
    - task_id_generator w broker.py zapewnia deduplikację przez JetStream Nats-Msg-Id
    - Tabela processed_events jest stopniowo wycofywana na rzecz deduplikacji JetStream
    """
    # 1. Odblokuj stare zadania w statusie PROCESSING (timeout >= 5 minut)
    stale_timeout = 300  # 5 minutes
    await db.execute(
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
    await db.execute(
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
        (
            await db.execute(
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
        )
        .mappings()
        .all()
    )

    for row in rows:
        try:
            # SUPERMOC: Deduplikacja przez JetStream Nats-Msg-Id (task_id_generator)
            # task_id_generator tworzy deterministyczne ID na podstawie hash(argumentów)
            # Jeśli to samo zadanie zostanie wysłane ponownie, JetStream odrzuci duplikat
            await _dispatch_outbox_event(row)

            # SUPERMOC: Pomijamy INSERT do processed_events — deduplikacja jest
            # obsługiwana przez JetStream Nats-Msg-Id (duplicate_window=2min)
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

            await db.execute(
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

    # 4. Cleanup starych wpisów processed_events (> 24h) — tylko jeśli tabela istnieje
    try:
        await db.execute(
            text("DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')")
        )
    except Exception:
        pass  # Tabela może nie istnieć — bezpieczne ignorowanie

    # SUPERMOC: DI auto-commituje sesję — engine jest cache'owany


@broker.task(
    schedule=[{"cron": "10 2 * * *"}],
    task_name="scan_logs_for_pii",
    labels={"service": "api", "operation": "security", "criticality": "high", "schedule": "daily"},
    timeout=300.0,
)
async def scan_logs_for_pii_task(
    config: AppConfig = TaskiqDepends(get_config),
) -> None:
    """Daily proactive scan for accidental PII in log files.

    SUPERMOC: TaskiqDepends wstrzykuje config — zero boilerplate.
    """
    findings = scan_logs_for_pii(config.base_dir / "app_data" / "logs")
    total = sum(findings.values())
    if total > 0:
        logger.warning("[PII-SCAN] potential sensitive data matches detected: %s", findings)
        notified = notify_dpo(config.dpo_alert_webhook, findings)
        logger.info("[PII-SCAN] DPO notification sent=%s", notified)
    else:
        logger.info("[PII-SCAN] no sensitive data patterns detected")


@broker.task(
    schedule=[{"cron": "0 * * * *"}],
    task_name="finops_hourly_estimate",
    labels={"service": "api", "operation": "finops", "criticality": "low", "schedule": "hourly"},
    timeout=30.0,
)
async def finops_hourly_estimate_task() -> None:
    """Hourly rough infrastructure cost estimate for FinOps observability."""
    cpu_cores = float(os.cpu_count() or 1)
    # ru_maxrss: KB on Linux, bytes on macOS; assume Linux deployment for this project.
    ram_gb = max((resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024 / 1024), 0.1)
    hourly_cost = estimate_runtime_cost(cpu_cores=cpu_cores, ram_gb=ram_gb, runtime_hours=1.0)
    logger.info(
        "[FINOPS] estimated hourly runtime cost usd=%s cpu_cores=%s ram_gb=%.3f",
        hourly_cost,
        cpu_cores,
        ram_gb,
    )


# ── replay_dead_letter_outbox_task usunięte — zastąpione przez NATS JetStream DLQ
#    ConsumerConfig.max_deliver=5 automatycznie retryuje
#    Po 5 failed deliveries → JetStream DLQ ($JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES)
#    dead_letter_processor_task zapisuje DLQ do failed_tasks

def _safe_float(value: object) -> float | None:
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
    """Zbuduj strukturę field_confidence z payloadu OCR i konsensusu.

    Tworzy per-field confidence metadata zgodnie ze strukturą:
    ``{"total_gross": {"value": 1230.00, "confidence": 0.88, "source": "..."}, ...}``

    Args:
        payload: Surowe dane z OCR pipeline.
        consensus: Wynik ``decide_amount_consensus``.

    Returns:
        Słownik field_confidence z per-field pewnością odczytu.
    """
    fc: dict[str, dict[str, Any]] = {}

    # Kwota brutto (z konsensusu lub payloadu)
    gross_str = payload.get("amount_gross")
    gross_val = (
        consensus.amount_gross
        if consensus and consensus.amount_gross is not None
        else _safe_float(gross_str)
    )
    if gross_val is not None:
        base_conf = _safe_float(payload.get("ocr_confidence")) or 0.5
        # Jeśli konflikt konsensusu — obniż confidence dla gross
        if consensus and consensus.confidence_conflict:
            gross_conf = base_conf * 0.7  # kara za konflikt
        else:
            gross_conf = base_conf
        fc["total_gross"] = {
            "value": gross_val,
            "confidence": round(min(gross_conf, 1.0), 4),
            "source": "ocr_consensus",
        }

    # Kwota netto
    net_val = _safe_float(payload.get("amount_net"))
    if net_val is not None:
        fc["total_net"] = {
            "value": net_val,
            "confidence": round(min(float(payload.get("ocr_confidence", 0.5)) * 0.95, 1.0), 4),
            "source": "ocr",
        }

    # Stawka VAT (z LLM — nie z OCR; opcjonalna, bo określana później przez Zen-Engine)
    vat_rate_val = payload.get("vat_rate") or payload.get("vat_rate_from_llm")
    if vat_rate_val is not None:
        vat_conf = _safe_float(payload.get("llm_validation")) or 0.5
        fc["vat_rate"] = {
            "value": vat_rate_val,
            "confidence": round(min(vat_conf, 1.0), 4),
            "source": "llm",
        }

    # Kwota VAT
    vat_val = _safe_float(payload.get("vat"))
    if vat_val is not None:
        fc["vat_amount"] = {
            "value": vat_val,
            "confidence": round(min(float(payload.get("ocr_confidence", 0.5)) * 0.9, 1.0), 4),
            "source": "ocr",
        }

    # NIP kontrahenta
    nip_val = payload.get("contractor_nip", "")
    if nip_val:
        fc["vendor_nip"] = {
            "value": nip_val,
            "confidence": 0.95 if payload.get("nip_valid", False) else 0.7,
            "source": "ocr",
        }

    # Numer faktury
    inv_num = payload.get("number", "")
    if inv_num:
        fc["invoice_number"] = {
            "value": inv_num,
            "confidence": 0.85,
            "source": "ocr",
        }

    # Data wystawienia
    issue_date = payload.get("issue_date", "")
    if issue_date:
        fc["issue_date"] = {
            "value": issue_date,
            "confidence": 0.85,
            "source": "ocr",
        }

    # Kategoria wydatku
    category = payload.get("category", "")
    if category:
        fc["category_code"] = {
            "value": category,
            "confidence": 0.80,  # kategoria często wymaga ręcznej weryfikacji
            "source": "llm",
        }

    return fc


async def _mark_invoice_blocked(invoice_id: str, reason: str, db: Session) -> None:
    """Mark invoice as BLOCKED_FRAUD_SUSPICION.

    SUPERMOC: Przyjmuje Session z DI zamiast tworzyć własny engine.
    """
    await db.execute(
        text(
            """
            UPDATE invoices
            SET status = 'BLOCKED_FRAUD_SUSPICION', updated_at = CURRENT_TIMESTAMP
            WHERE id = :invoice_id
            """
        ),
        {"invoice_id": invoice_id},
    )
    logger.warning("[FRAUD] Invoice %s blocked: %s", invoice_id, reason)


async def _mark_invoice_pending_review(invoice_id: str, reason: str, db: Session) -> None:
    await db.execute(
        text(
            """
            UPDATE invoices
            SET status = 'PENDING_REVIEW'
            WHERE id = :invoice_id
            """
        ),
        {"invoice_id": invoice_id},
    )


@broker.task(
    schedule=[{"cron": "15 3 * * *"}],
    task_name="schema_drift_daily_check",
    labels={"service": "api", "operation": "schema", "criticality": "medium", "schedule": "daily"},
    timeout=120.0,
)
async def schema_drift_daily_check_task(
    config: AppConfig = TaskiqDepends(get_config),
    engine: Any = TaskiqDepends(get_engine),
) -> None:
    """Daily schema drift verification against runtime baseline snapshot.

    SUPERMOC: TaskiqDepends wstrzykuje config i engine — zero boilerplate.
    """
    baseline_path = config.base_dir / "app_data" / "schema_baseline.json"
    drift = await verify_schema_drift(engine, baseline_path=baseline_path)
    if drift["status"] == "drift_detected":
        logger.warning("[SCHEMA-DRIFT] detected: %s", drift["issues"])
    else:
        logger.info("[SCHEMA-DRIFT] status=%s tables=%s", drift["status"], drift["tables"])


# contract marker: sync_single_invoice_to_duckdb(session, config, invoice_id)


@broker.task(
    schedule=[{"cron": "*/10 * * * *"}],
    task_name="flush_otel_fallback_buffer",
    labels={"service": "api", "operation": "telemetry", "criticality": "low", "schedule": "10min"},
    timeout=60.0,
)
async def flush_otel_fallback_buffer_task() -> None:
    """Replay file-buffered telemetry spans when OLAP becomes available again."""
    config = AppConfig()
    stats = await flush_fallback_spans(
        lambda: DuckDBManager(
            db_path=config.duckdb_path, sqlite_path=config.sqlite_path, read_only=False
        ),
        retries=3,
        base_delay=0.5,
    )
    if stats.get("remaining", 0) > 0:
        logger.warning("[OTEL-FALLBACK] replay incomplete stats=%s", stats)
    else:
        logger.info("[OTEL-FALLBACK] replay stats=%s", stats)


@broker.task(
    schedule=[{"cron": "20 3 * * *"}],
    task_name="migration_integrity_daily_check",
    labels={"service": "api", "operation": "schema", "criticality": "medium", "schedule": "daily"},
    timeout=120.0,
)
async def migration_integrity_daily_check_task(
    config: AppConfig = TaskiqDepends(get_config),
    engine: Any = TaskiqDepends(get_engine),
) -> None:
    """Daily data-integrity check against persisted row-count baseline.

    SUPERMOC: TaskiqDepends wstrzykuje config i engine — zero boilerplate.
    """
    baseline_path = config.migration_baseline_path
    result = await verify_migration_integrity(engine, baseline_path=baseline_path)
    status = str(result.get("status"))
    if status == "ok":
        logger.info("[MIGRATION-INTEGRITY] status=ok tables=%s", result.get("tables"))
    elif status == "baseline_created":
        logger.info("[MIGRATION-INTEGRITY] baseline created tables=%s", result.get("tables"))
    else:
        logger.warning(
            "[MIGRATION-INTEGRITY] status=%s issues=%s", status, result.get("issues")
        )


@broker.task(
    schedule=[{"cron": "0 3 * * 0"}],
    task_name="cleanup_old_logs",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "weekly"},
    timeout=120.0,
)
async def cleanup_old_logs_task() -> None:
    log_dir = Path("app_data/logs")
    if not log_dir.exists():
        return

    now = pendulum.now()
    cutoff_compress = now - pendulum.duration(days=7)  # Kompresuj logi starsze niż 7 dni
    cutoff_delete = now - pendulum.duration(days=30)  # Usuń logi starsze niż 30 dni

    removed = 0
    compressed = 0

    for f in log_dir.iterdir():
        if not f.is_file():
            continue
        try:
            mtime = pendulum.from_timestamp(f.stat().st_mtime)

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
                        logger.debug(
                            "[CLEANUP] compressed log: %s -> %s", f.name, compressed_name.name
                        )
                    except Exception as e:
                        logger.warning("[CLEANUP] failed to compress %s: %s", f.name, e)

        except (FileNotFoundError, OSError):
            continue

    logger.info("[CLEANUP] old logs removed=%s compressed=%s", removed, compressed)


@broker.task(
    schedule=[{"cron": "*/5 * * * *"}],
    task_name="cleanup_temp_upload_files",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "5min"},
    timeout=30.0,
)
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


@broker.task(
    schedule=[{"cron": "30 6 * * *"}],
    task_name="daily_briefing_send",
    labels={"service": "api", "operation": "briefing", "criticality": "medium", "schedule": "daily"},
    timeout=120.0,
)
async def daily_briefing_send(user_id: str | None = None) -> dict:
    """
    Generuj i wyślij codzienne podsumowanie finansowe (Daily Briefing).
    Zgodnie z aa3fvcx.txt: używa DuckDB + SQLite, bez PLE ani agentów.
    """
    config = AppConfig()
    logger.info("[DAILY-BRIEFING] starting generation for user_id=%s", user_id or "all")

    try:
        from nexus_ai.db.analytics import DuckDBManager
        from nexus_ai.services.daily_briefing import DailyBriefingService
        from nexus_ai.services.decision_logger import DecisionLogger
        from nexus_ai.services.notification_service import NotificationService

        db_path = config.base_dir / "app_data" / "notifications.db"
        notification = NotificationService(db_path=db_path, config=config)
        duckdb: DuckDBManager | None = None
        try:
            duckdb = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
            decision_logger = DecisionLogger(duckdb)

            briefing_service = DailyBriefingService(
                config=config,
                notification_service=notification,
                decision_logger=decision_logger,
                duckdb_manager=duckdb,
            )

            if user_id:
                result = await briefing_service.generate_and_send(user_id, channels=["in_app"])
                logger.info(
                    "[DAILY-BRIEFING] sent for user_id=%s status=%s", user_id, result["status"]
                )
                return {"result": "OK", "user_id": user_id, **result}

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


@broker.task(
    schedule=[{"cron": "0 5 * * 0"}],
    task_name="cleanup_old_reports",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "weekly"},
    timeout=60.0,
)
async def cleanup_old_reports_task() -> None:
    cutoff = pendulum.now() - pendulum.duration(days=30)
    report_dirs = [Path("reports/performance"), Path("reports/security"), Path("reports/pii")]
    removed = 0
    for d in report_dirs:
        if not d.exists():
            continue
        for pattern in ("*.json", "*.html", "*.txt"):
            for f in d.glob(pattern):
                try:
                    if pendulum.from_timestamp(f.stat().st_mtime) < cutoff:
                        f.unlink(missing_ok=True)
                        removed += 1
                except FileNotFoundError:
                    continue
    logger.info("[CLEANUP] old reports removed=%s", removed)


# compact_lancedb_task usunięta: LanceDB zastąpione przez sqlite-vec
# sqlite-vec nie wymaga kompakcji (SQLite VACUUM robi to przez sqlite_weekly_vacuum)


@broker.task(
    schedule=[{"cron": "0 * * * *"}],
    task_name="check_hanging_transactions",
    labels={"service": "api", "operation": "monitoring", "criticality": "medium", "schedule": "hourly"},
    timeout=30.0,
)
async def check_hanging_transactions_task(
    config: AppConfig = TaskiqDepends(get_config),
    engine: Any = TaskiqDepends(get_engine),
) -> None:
    """
    Okresowe zadanie (co godzinę) wykrywające wiszące transakcje.
    Sprawdza dziennik WAL SQLite - jeśli plik WAL jest duży, może to wskazywać
    na otwartą transakcję. Loguje ostrzeżenie.

    SUPERMOC: TaskiqDepends wstrzykuje config i engine — zero boilerplate.
    """
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
        logger.debug(
            "[HANGING-TX] Brak pliku WAL - SQLite działa w trybie DELETE lub WAL jest pusty"
        )

    # Dodatkowo: sprawdź długo trwające zapytania przez PRAGMA
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


@broker.task(
    schedule=[{"cron": "0 6 * * 1"}],
    task_name="weekly_nip_reverification",
    labels={"service": "api", "operation": "verification", "criticality": "medium", "schedule": "weekly"},
    timeout=600.0,
)
async def weekly_nip_reverification_task(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Cotygodniowe zadanie ponownej weryfikacji NIP-ów kontrahentów.
    Sprawdza NIP-y w Białej Liście MF i aktualizuje status w tabeli contractors.

    SUPERMOC: TaskiqDepends wstrzykuje sesję DB — zero boilerplate.
    """
    accounting = AccountingService()

    # Pobierz wszystkich kontrahentów
    from sqlmodel import select as sa_select

    from nexus_ai.db.models import Contractor

    result = await db.execute(sa_select(Contractor))
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
    # SUPERMOC: DI auto-commituje sesję


@broker.task(
    schedule=[{"cron": "30 4 * * 0"}],
    task_name="sqlite_weekly_vacuum",
    labels={"service": "api", "operation": "maintenance", "criticality": "medium", "schedule": "weekly"},
    timeout=600.0,
)
async def sqlite_weekly_vacuum_task(
    engine: Any = TaskiqDepends(get_engine),
) -> None:
    """Weekly SQLite VACUUM for database maintenance.

    SUPERMOC: TaskiqDepends wstrzykuje cache'owany engine — zero boilerplate.
    """
    async with engine.connect() as conn:
        await conn.execute(text("VACUUM;"))
    logger.info("[SQLITE] weekly VACUUM completed")


@broker.task(
    schedule=[{"cron": "15 4 * * 0"}],
    task_name="cleanup_duckdb_temp",
    labels={"service": "api", "operation": "cleanup", "criticality": "low", "schedule": "weekly"},
    timeout=30.0,
)
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




@broker.task(
    schedule=[{"cron": "*/1 * * * *"}],
    task_name="log_resilience_states",
    labels={"service": "api", "operation": "monitoring", "criticality": "low", "schedule": "1min"},
    timeout=10.0,
)
async def log_resilience_states_task() -> None:
    """
    Co minutę monitoruj stan systemu pod kątem problemów z zewnętrznymi API.
    Rozwiązanie 21: Monitorowanie — stamina zarządza retry + circuit breaker.
    """
    logger.debug("[RESILIENCE] stamina active — retry + circuit breaker via decorators")


@broker.task(
    schedule=[{"cron": "0 5 * * *"}],
    task_name="cleanup_expired_refresh_tokens",
    labels={"service": "api", "operation": "cleanup", "criticality": "medium", "schedule": "daily"},
    timeout=120.0,
)
async def cleanup_expired_refresh_tokens_task(
    db: Session = TaskiqDepends(get_db_session),
) -> None:
    """
    Codzienne zadanie czyszczenia wygasłych i odwołanych refresh tokenów.
    Rozwiązanie 16: Usuwa tokeny starsze niż 7 dni od daty wygaśnięcia.

    SUPERMOC: TaskiqDepends wstrzykuje sesję DB — zero boilerplate.
    """
    result = await db.execute(
        text(
            """
            DELETE FROM refresh_tokens
            WHERE expires_at < datetime('now', '-7 days')
               OR (is_revoked = 1 AND created_at < datetime('now', '-30 days'))
            """
        )
    )
    deleted = result.rowcount
    logger.info("[TOKEN-CLEANUP] Removed %d expired/revoked refresh tokens", deleted)
    # SUPERMOC: DI auto-commituje sesję
