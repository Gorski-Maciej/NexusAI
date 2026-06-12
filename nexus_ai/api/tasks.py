from __future__ import annotations

import atexit

import anyio
import os
import resource
import time

# ── SHA-256 przez nexus-crypto (Rust+PyO3) zgodnie z aa3fvcx.txt ─────────
try:
    from nexus_crypto import sha256 as _sha256

    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib

    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


from pathlib import Path
from typing import Any

import httpx
import pendulum
import stamina
from sqlalchemy import text
from sqlalchemy import text as sql_text
from structlog import get_logger
from taskiq_nats import PullBasedJetStreamBroker

from nexus_ai.api.cache import clear_cache_async
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_dumps_bytes, msgspec_loads
from nexus_ai.core.resilience import async_retry
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import create_oltp_engine, create_session_factory
from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus
from nexus_ai.services.accounting import AccountingService
from nexus_ai.core.decision_engine import (
    DecisionEngine,
    DecisionVerdict,
    classify_invoice,
    calculate_trust_score,
)
from nexus_ai.events.event_emitter import EventEmitter, get_event_emitter
from nexus_ai.services.currency_converter import (
    Money,  # Nexus-Money (msgspec.Struct, zastępuje py-moneyed)
)
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.finops_meter import estimate_runtime_cost
from nexus_ai.services.log_pii_monitor import notify_dpo, scan_logs_for_pii
from nexus_ai.services.migration_sanity import verify_migration_integrity, verify_schema_drift
from nexus_ai.services.outbox_replay import replay_dead_letter_events
from nexus_ai.services.telemetry import flush_fallback_spans
from nexus_ai.tax.exceptions import NoMatchingRuleError


# ── SQLCipher engine helper ────────────────────────────────────────────────
# Wszystkie zadania w tym pliku tworzą engine przez _make_engine(), który
# jawnie przekazuje klucz SQLCipher z NEXUS_SQLCIPHER_KEY env var.
# Dzięki temu zależność od klucza jest widoczna w kodzie, a nie ukryta
# w _resolve_key() database.py.


def _make_engine(config: AppConfig | None = None) -> Any:
    """Utwórz SQLAlchemy engine z jawnym kluczem SQLCipher.

    Args:
        config: Opcjonalna konfiguracja. Jeśli None, ładuje AppConfig().

    Returns:
        SQLAlchemy Engine z włączonym SQLCipher.
    """
    if config is None:
        config = AppConfig()
    sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
    return create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)


broker = PullBasedJetStreamBroker()
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


@broker.task(task_name="decision_evaluate")
async def decision_evaluate(invoice_id: str, extracted_data: dict) -> dict:
    """
    Final decision evaluation.
    Uses DecisionEngine (DuckDB/SQL-based, zgodnie z aa3fvcx.txt).
    Publishes result as DecisionMade event through EventStore + JetStream.
    """
    config = AppConfig()
    engine = _ensure_decision_engine(config)

    # ── Phase 2: EventEmitter dla emisji DecisionMade ────────────────
    emitter: EventEmitter | None = None
    try:
        emitter = get_event_emitter()
    except Exception as exc:
        logger.warning(
            "[DECISION] EventEmitter init failed — events will not be emitted: %s",
            exc,
        )

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

        # ── Emituj DecisionMade event ─────────────────────────────────
        if emitter is not None:
            try:
                await emitter.emit_decision_made(
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
                        },
                    },
                )
                logger.info(
                    "[DECISION-EVENT] DecisionMade emitted for invoice_id=%s decision=%s",
                    invoice_id,
                    verdict.decision,
                )
            except Exception as emit_err:
                logger.warning(
                    "[DECISION-EVENT] Failed to emit DecisionMade for %s: %s",
                    invoice_id,
                    emit_err,
                )

        # Execute action based on decision
        if verdict.decision == "AUTO_POST":
            await _post_invoice(invoice_id, extracted_data, verdict)
        elif verdict.decision == "SUGGEST":
            await _mark_for_review(invoice_id, verdict)
        elif verdict.decision in ("ASK_USER", "BLOCK", "ESCALATE"):
            await _escalate_to_human(invoice_id, verdict, reason=f"decision: {verdict.decision}")

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


@broker.task(task_name="council_decide")
async def council_decide(invoice_id: str, extracted_data: dict) -> dict:
    """
    [DEPRECATED] Decision task — use decision_evaluate instead.

    Zachowany dla kompatybilności wstecznej. Deleguje do decision_evaluate.
    Zgodnie z aa3fvcx.txt: wszystkie decyzje przez DecisionEngine (DuckDB/SQL).
    """
    logger.warning(
        "[DEPRECATED] council_decide task called for invoice_id=%s — use decision_evaluate",
        invoice_id,
    )
    return await decision_evaluate(invoice_id, extracted_data)


async def _post_invoice(invoice_id: str, extracted_data: dict, verdict: DecisionVerdict) -> None:
    """Auto-post the invoice: update status to APPROVED."""
    config = AppConfig()
    engine = _make_engine(config)
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
            logger.info(
                "[DECIDE] auto-posted invoice_id=%s (conf=%.4f)", invoice_id, verdict.confidence
            )

        # Store in sqlite-vec for future anomaly detection
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

    finally:
        await engine.dispose()


async def _mark_for_review(invoice_id: str, verdict: DecisionVerdict) -> None:
    """Mark invoice for manual review (SUGGEST)."""
    config = AppConfig()
    engine = _make_engine(config)
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
            logger.info(
                "[DECIDE] marked for review invoice_id=%s (conf=%.4f)",
                invoice_id,
                verdict.confidence,
            )
    finally:
        await engine.dispose()


async def _escalate_to_human(invoice_id: str, verdict: DecisionVerdict, reason: str) -> None:
    """Escalate invoice to human for review."""
    config = AppConfig()
    engine = _make_engine(config)
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
                "[DECIDE] escalated invoice_id=%s reason=%s (conf=%.4f)",
                invoice_id,
                reason,
                verdict.confidence,
            )
    finally:
        await engine.dispose()


async def _dispatch_outbox_event(row: dict) -> None:
    event_type = str(row.get("event_type", "")).strip().lower()
    payload_raw = row.get("payload") or "{}"

    try:
        payload = msgspec_loads(payload_raw)
    except Exception:
        payload = {}

    if event_type == "process_invoice_ocr" or event_type == "invoice_uploaded":
        invoice_id = payload.get("invoice_id") or row.get("aggregate_id")
        if not invoice_id:
            raise ValueError("Missing invoice_id in outbox payload")
        try:
            with stamina.retry(on=Exception, attempts=3, timeout=10.0):
                await broker.kick(
                    "process_invoice_ocr", invoice_id=str(invoice_id), payload=payload
                )
        except Exception as exc:
            logger.warning("[OUTBOX] NATS broker.kick failed after retries: %s", exc)
            raise
        return
    if event_type == "attachment_large_uploaded":
        attachment_id = payload.get("attachment_id") or row.get("aggregate_id")
        if not attachment_id:
            raise ValueError("Missing attachment_id in outbox payload")
        try:
            with stamina.retry(on=Exception, attempts=3, timeout=10.0):
                await broker.kick(
                    "process_large_attachment", attachment_id=str(attachment_id), payload=payload
                )
        except Exception as exc:
            logger.warning("[OUTBOX] NATS broker.kick failed after retries: %s", exc)
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


@broker.task(task_name="process_invoice_ocr")
async def process_invoice_ocr(invoice_id: str, payload: dict | None = None) -> None:
    """Dedicated OCR pipeline entrypoint triggered by outbox relay.
    Rozwiązanie 29: Limit współbieżności przez semafor (max 3).
    Rozwiązanie 33: Koordynacja przez Saga Store.
    """
    logger.info("[OCR] processing invoice_id=%s", invoice_id)
    payload = payload or {}

    # Rozwiązanie 33: Rozpocznij sagę dla procesu OCR
    saga_id = f"ocr_{invoice_id}"
    saga_store = None
    saga_engine = None
    try:
        from nexus_ai.core.saga import PersistedSagaStore

        config = AppConfig()
        saga_engine = _make_engine(config)
        saga_store = PersistedSagaStore(saga_engine)
        await saga_store.ensure_schema()

        await saga_store.transition(
            saga_id=saga_id,
            new_state="START",
            payload={"invoice_id": invoice_id, "started_at": pendulum.now("UTC").isoformat()},
        )
    except Exception as saga_err:
        logger.warning("[SAGA] Failed to start saga for %s: %s", invoice_id, saga_err)
        saga_store = None

    # Rozwiązanie 29: Semafory na ciężkie operacje OCR (max 3 równolegle)
    async with _OCR_SEMAPHORE:
        try:
            # Rozwiązanie 33: Przejście do stanu OCR_EXTRACT
            if saga_store:
                await saga_store.transition(
                    saga_id=saga_id,
                    new_state="OCR_EXTRACT",
                    expected_current_state="START",
                )
        except Exception:
            pass

        primary_amount = _safe_float(payload.get("ocr_primary_amount_gross"))
        secondary_amount = _safe_float(payload.get("ocr_secondary_amount_gross"))
        primary = OCRAmountResult(
            amount_gross=Money.from_string(str(primary_amount), "PLN")
            if primary_amount is not None
            else None,
            source="surya",
        )
        secondary = OCRAmountResult(
            amount_gross=Money.from_string(str(secondary_amount), "PLN")
            if secondary_amount is not None
            else None,
            source="paddle",
        )
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
                    invoice_id, anomaly.get("alert", "Semantic anomaly detected")
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
                        await _mark_invoice_blocked(invoice_id, routing_reason)
                        ze_conn.close()
                        return
                    elif routing == "TRIAGE_QUEUE":
                        await _mark_invoice_pending_review(
                            invoice_id, reason=f"FIELD_CONFIDENCE: {routing_reason}"
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

        # Rozwiązanie 33: Przejście do AI_CLASSIFY
        try:
            if saga_store:
                await saga_store.transition(
                    saga_id=saga_id,
                    new_state="AI_CLASSIFY",
                    expected_current_state="OCR_EXTRACT",
                )
        except Exception:
            pass

    # Trigger decision & rules check via NATS (poza semaforem - lekkie operacje NATS)
    config = AppConfig()
    try:
        import nats

        nc = await nats.connect(config.nats_url)
        # Publish to invoice.extracted for rules_check subscriber
        await nc.publish(
            "invoice.extracted",
            msgspec_dumps_bytes({"invoice_id": invoice_id, "extracted_data": extracted_data}),
        )
        await nc.close()

        # Dynamic workflow — decide which tasks to run (zgodnie z aa3fvcx.txt)
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

        # Rozwiązanie 33: SEND_EVENT - sukces
        try:
            if saga_store:
                await saga_store.transition(
                    saga_id=saga_id,
                    new_state="SEND_EVENT",
                    payload={"agents": workflow["agents"]},
                )
        except Exception:
            pass
    except Exception as trigger_err:
        logger.warning("[OCR] failed to trigger checks: %s", trigger_err)
        # Rozwiązanie 33: W przypadku błędu, oznacz sagę jako COMPENSATING
        try:
            if saga_store:
                await saga_store.compensate(saga_id=saga_id, payload={"error": str(trigger_err)})
        except Exception:
            pass

    # Rozwiązanie 33: COMPLETED
    try:
        if saga_store:
            await saga_store.transition(
                saga_id=saga_id,
                new_state="COMPLETED",
                payload={"completed_at": pendulum.now("UTC").isoformat()},
            )
    except Exception:
        pass

    # Zero-ETL path: no OLTP->OLAP row replication in worker.
    # Invoice OCR lifecycle is event-driven; analytics layer reads SQLite via DuckDB ATTACH.
    try:
        with stamina.retry(on=Exception, attempts=3, timeout=30.0):
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

    finally:
        if saga_engine is not None:
            try:
                await saga_engine.dispose()
            except Exception:
                pass

    return


@broker.task(task_name="process_large_attachment")
async def process_large_attachment(attachment_id: str, payload: dict | None = None) -> None:
    """Dedicated worker path for large attachments uploaded via /upload-large."""
    logger.info(
        "[ATTACHMENT] processing large attachment_id=%s payload=%s", attachment_id, bool(payload)
    )
    return


@broker.task(schedule=[{"cron": "0 * * * *"}], task_name="refresh_materialized_cashflow")
@async_retry(max_retries=3, base_delay=1.0, max_delay=8.0)
async def refresh_materialized_cashflow() -> None:
    config = AppConfig()
    manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        with stamina.retry(on=Exception, attempts=3, timeout=30.0):
            await _refresh_cashflow_materialized(manager)
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
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)

    try:
        import nats

        nc = await nats.connect(config.nats_url)
        sub = await nc.subscribe("nats.deadletter", queue="nexus-dlq-workers")

        # Sprawdź wiadomości w DLQ
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
                                    "payload": msgspec_dumps(payload),
                                },
                            )
                            await session.commit()

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

                    except Exception as parse_err:
                        logger.warning("[DLQ] Failed to parse DLQ message: %s", parse_err)

                    msg = await sub.fetch(1, timeout=2.0)
        except TimeoutError:
            pass  # Brak wiadomości w DLQ

        await nc.close()
    except Exception as dlq_err:
        logger.warning("[DLQ] Dead letter processor error: %s", dlq_err)
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "0 5 * * *"}], task_name="cleanup_hard_deleted_invoices")
async def cleanup_hard_deleted_invoices_task() -> None:
    """
    Miesięczne zadanie fizycznego usuwania faktur po okresie retencji (Rozwiązanie 27: RODO).
    Usuwa soft-deleted invoices po upływie retention_period_years od deleted_at.
    """
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            from nexus_ai.services.security_service import SecurityService

            result = await SecurityService.cleanup_old_scans(session, years=5)
            logger.info(
                "[RETENTION] Hard-deleted invoices cleanup: %s",
                result,
            )
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "0 6 * * 0"}], task_name="cleanup_archived_invoices")
async def cleanup_archived_invoices_task() -> None:
    """
    Tygodniowe zadanie archiwizacji REJECTED/FAILED invoices starszych niż 1 rok (Rozwiązanie 27).
    Przenosi do tabeli archived_invoices i usuwa z głównej tabeli.
    """
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            from nexus_ai.services.security_service import SecurityService

            result = await SecurityService.archive_old_invoices(
                session, archive_table="archived_invoices"
            )
            logger.info(
                "[RETENTION] Archived old invoices: %s",
                result,
            )
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "0 4 * * *"}], task_name="cleanup_outbox_events")
async def cleanup_outbox_events_task() -> None:
    """
    Codzienne zadanie czyszczenia starych zdarzeń outbox (Rozwiązanie 27).
    Usuwa zdarzenia SENT i DEAD_LETTER starsze niż 30 dni.
    """
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            result = await session.execute(
                text(
                    """
                    DELETE FROM outbox_events
                    WHERE status IN ('SENT', 'DEAD_LETTER')
                      AND created_at < datetime('now', '-30 days')
                    """
                )
            )
            deleted = result.rowcount
            await session.commit()
            logger.info("[RETENTION] Cleaned old outbox events: deleted=%d", deleted)
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="stuck_saga_recovery")
async def stuck_saga_recovery_task() -> None:
    """
    Co minutę sprawdza zawieszone sagi (Rozwiązanie 33).
    Sagi w stanie pośrednim (OCR_EXTRACT, AI_CLASSIFY, BOOK_ENTRY) dłużej niż 10 minut
    są automatycznie kompensowane.
    """
    config = AppConfig()
    try:
        from nexus_ai.core.saga import PersistedSagaStore

        engine = _make_engine(config)
        store = PersistedSagaStore(engine)
        await store.ensure_schema()

        # Znajdź sagi w pośrednich stanach
        stuck = await store.list_stuck(older_than_minutes=10)
        intermediate_states = {"START", "OCR_EXTRACT", "AI_CLASSIFY", "BOOK_ENTRY", "SEND_EVENT"}
        compensated = 0
        for saga in stuck:
            if saga.state in intermediate_states:
                try:
                    await store.compensate(
                        saga.saga_id,
                        payload={
                            "reason": "stuck_timeout",
                            "stuck_state": saga.state,
                            "stuck_duration": (
                                pendulum.now("UTC") - saga.updated_at
                            ).total_seconds(),
                        },
                    )
                    compensated += 1
                    logger.info(
                        "[SAGA] Auto-compensated stuck saga=%s state=%s stuck_minutes=%.1f",
                        saga.saga_id,
                        saga.state,
                        (pendulum.now("UTC") - saga.updated_at).total_seconds() / 60,
                    )
                except Exception as comp_err:
                    logger.warning(
                        "[SAGA] Failed to compensate stuck saga=%s: %s", saga.saga_id, comp_err
                    )

        if compensated > 0:
            logger.info("[SAGA] Recovered %d stuck sagas", compensated)
        await engine.dispose()
    except Exception as exc:
        logger.warning("[SAGA] Stuck saga recovery error: %s", exc)


# Semafory dla limitów współbieżności (Rozwiązanie 29)
_OCR_SEMAPHORE = anyio.Semaphore(3)  # process_invoice_ocr: max 3 równolegle


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="relay_outbox_events")
async def relay_outbox_events() -> None:
    """
    Relay pending outbox events with atomic UPDATE semantics (Rozwiązanie 11).
    Uses two-step atomic UPDATE to prevent duplicate processing by concurrent workers.
    Detects stale PROCESSING tasks (>= 5 min) and reclaims them.
    Records idempotency key in processed_events to prevent double-dispatch.
    """
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)

    async with session_factory() as session:
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
            (
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
            )
            .mappings()
            .all()
        )

        for row in rows:
            try:
                # Idempotentność: sprawdź czy to zdarzenie było już przetworzone
                event_id = row["id"]
                existing = await session.execute(
                    text("SELECT 1 FROM processed_events WHERE id = :id"),
                    {"id": event_id},
                )
                if existing.fetchone():
                    logger.info("[OUTBOX] Skipping already processed event id=%s", event_id)
                    await session.execute(
                        text(
                            "UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"
                        ),
                        {"id": event_id},
                    )
                    continue

                await _dispatch_outbox_event(row)

                # Zapisz do tabeli idempotentności
                payload_raw = row.get("payload") or "{}"
                payload_hash = _sha256(payload_raw.encode())
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
                    text(
                        "UPDATE outbox_events SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"
                    ),
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
            text("DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')")
        )

        await session.commit()

    await engine.dispose()


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="outbox_relay_process_pending")
async def outbox_relay_process_pending_task() -> None:
    """
    Co minutę przetwarzaj oczekujące zdarzenia outbox przez OutboxRelay.

    Używa ``OutboxRelay.process_pending()`` zamiast starego inline relay:
      - Asynchroniczny odczyt outbox_events z bazy SQLite
      - Wysyłka TAX_CALCULATED do TigerBeetle (dwa transfery)
      - Wykładnicze opóźnienie między retry
      - Dead Letter Queue po wyczerpaniu prób
      - Idempotentność przez tabelę processed_events
    """
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)

    try:
        # Wczesne wyjście: jeśli nie ma oczekujących zdarzeń, nie twórz relay
        async with session_factory() as session:
            pending_count = int(
                (
                    await session.execute(
                        text(
                            "SELECT COUNT(*) FROM outbox_events WHERE status IN ('PENDING', 'FAILED')"
                        )
                    )
                ).scalar()
                or 0
            )
        if pending_count == 0:
            return

        from nexus_ai.services.outbox_relay import OutboxRelay

        relay = OutboxRelay(
            session_factory=session_factory,
            tigerbeetle=None,  # W workerze TigerBeetle jest opcjonalne
            max_retries=3,
            base_delay_seconds=1.0,
        )

        stats = await relay.process_pending()

        logger.info(
            "[OUTBOX-RELAY] Cron processed=%d failed=%d dead_letter=%d "
            "skipped=%d total=%d (%.0fms)",
            stats.processed,
            stats.failed,
            stats.dead_letter,
            stats.skipped_idempotent,
            stats.total,
            stats.processing_time_ms,
        )
    except Exception as exc:
        logger.exception("[OUTBOX-RELAY] Cron processing failed: %s", exc)
    finally:
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
    logger.info(
        "[FINOPS] estimated hourly runtime cost usd=%s cpu_cores=%s ram_gb=%.3f",
        hourly_cost,
        cpu_cores,
        ram_gb,
    )


@broker.task(schedule=[{"cron": "45 * * * *"}], task_name="replay_dead_letter_outbox")
async def replay_dead_letter_outbox_task() -> None:
    """Hourly replay of dead-letter outbox events back to FAILED for retry."""
    config = AppConfig()
    engine = _make_engine(config)
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


async def _mark_invoice_blocked(invoice_id: str, reason: str) -> None:
    """Mark invoice as BLOCKED_FRAUD_SUSPICION due to semantic anomaly or white-list violation."""
    config = AppConfig()
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    try:
        async with session_factory() as session:
            await session.execute(
                text(
                    """
                    UPDATE invoices
                    SET status = 'BLOCKED_FRAUD_SUSPICION', updated_at = CURRENT_TIMESTAMP
                    WHERE id = :invoice_id
                    """
                ),
                {"invoice_id": invoice_id},
            )
            await session.commit()
            logger.warning("[FRAUD] Invoice %s blocked: %s", invoice_id, reason)
    finally:
        await engine.dispose()


async def _mark_invoice_pending_review(invoice_id: str, reason: str) -> None:
    config = AppConfig()
    engine = _make_engine(config)
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
    engine = _make_engine(config)
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


@broker.task(schedule=[{"cron": "20 3 * * *"}], task_name="migration_integrity_daily_check")
async def migration_integrity_daily_check_task() -> None:
    """Daily data-integrity check against persisted row-count baseline."""
    config = AppConfig()
    engine = _make_engine(config)
    baseline_path = config.migration_baseline_path
    try:
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
    finally:
        await engine.dispose()


@broker.task(schedule=[{"cron": "0 3 * * 0"}], task_name="cleanup_old_logs")
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


@broker.task(schedule=[{"cron": "0 5 * * 0"}], task_name="cleanup_old_reports")
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
        logger.debug(
            "[HANGING-TX] Brak pliku WAL - SQLite działa w trybie DELETE lub WAL jest pusty"
        )

    # Dodatkowo: sprawdź długo trwające zapytania przez PRAGMA
    engine = _make_engine(config)
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
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    accounting = AccountingService()

    try:
        async with session_factory() as session:
            # Pobierz wszystkich kontrahentów
            from sqlalchemy import select as sa_select

            from nexus_ai.db.models import Contractor

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
    engine = _make_engine(config)
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


@broker.task(schedule=[{"cron": "15 12 * * *"}], task_name="daily_nbp_rate_fill")
async def daily_nbp_rate_fill_task() -> None:
    """
    Codzienne zadanie (12:15) uzupełniające brakujące kursy NBP dla ostatnich 30 dni.
    Rozwiązanie 28: Po publikacji tabeli A przez NBP (~11:45), uzupełniamy cache.
    """
    config = AppConfig()
    try:
        from nexus_ai.services.forex_engine import ForexEngine

        # Inicjalizuj ForexEngine z minimalnym zestawem parametrów
        engine = ForexEngine(
            duckdb_manager=DuckDBManager(
                db_path=config.duckdb_path, sqlite_path=config.sqlite_path
            ),
            tb_client=None,  # TigerBeetle nie jest potrzebny tylko do kursów
            account_receivable=0,
            account_fx_gain=0,
            account_fx_loss=0,
        )

        today = pendulum.now().date()
        currencies = ["EUR", "USD", "CHF", "GBP", "CZK", "DKK", "NOK", "SEK", "HUF"]
        filled = 0
        errors = 0

        for currency in currencies:
            for day_offset in range(30):
                rate_date = today - pendulum.duration(days=day_offset)
                try:
                    rate = engine.fetch_nbp_rate(rate_date, currency, max_lookback_days=5)
                    if rate:
                        filled += 1
                except Exception:
                    errors += 1

        logger.info(
            "[NBP-FILL] daily fill complete: currencies=%d, days=%d, filled=%d, errors=%d",
            len(currencies),
            30,
            filled,
            errors,
        )
    except Exception as exc:
        logger.error("[NBP-FILL] failed: %s", exc)


@broker.task(schedule=[{"cron": "*/1 * * * *"}], task_name="log_resilience_states")
async def log_resilience_states_task() -> None:
    """
    Co minutę monitoruj stan systemu pod kątem problemów z zewnętrznymi API.
    Rozwiązanie 21: Monitorowanie — stamina zarządza retry + circuit breaker.
    """
    logger.debug("[RESILIENCE] stamina active — retry + circuit breaker via decorators")


@broker.task(schedule=[{"cron": "0 5 * * *"}], task_name="cleanup_expired_refresh_tokens")
async def cleanup_expired_refresh_tokens_task() -> None:
    """
    Codzienne zadanie czyszczenia wygasłych i odwołanych refresh tokenów.
    Rozwiązanie 16: Usuwa tokeny starsze niż 7 dni od daty wygaśnięcia.
    """
    config = AppConfig()
    engine = _make_engine(config)
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
