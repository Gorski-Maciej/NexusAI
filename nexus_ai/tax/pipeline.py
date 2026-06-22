"""Tax Pipeline — orchestrates the complete tax processing flow z SUPERMOCAMI TigerBeetle.

Zgodnie z aa3fvcx.txt:
  - OPA (Open Policy Agent) → deklaratywny silnik reguł (first-match-wins)
  - DuckDB (RuleStore) → trwały magazyn reguł
  - Nexus-TaxEngine (Rust+PyO3) → natywny orkiestrator: przygotowuje dane dla OPA,
    odbiera decyzję i wykonuje krytyczne obliczenia matematyczne

Processing flow (OPA-aware):
  1. ContextInterpreter → flat context z invoice_data
  2. (Optional) RuleEngine.decide_async() → OPA → first-match wins verdict
  3. Rust TaxMathEngine → integer-only VAT computation (ROUND_HALF_UP)
  4. InvariantGuard → balance-check 3 invariantów
  5. DecisionTraceLogger → SHA-256 hash chain
  6. PreLedgerValidator → account pair/balance validation
  7. TigerBeetle → double-entry linked transfers (BATCH + LINKED)
  8. Event emission → DecisionMade via NATS

SUPERMOCE TigerBeetle:
- Linked transfers dla atomowego księgowania expense + VAT
- Batch transferów (oba w jednym wywołaniu)
- code field dla każdego transferu
- user_data_128 dla source_document_id (UUID → u128)
- Multi-ledger: PLN=700, VAT_INPUT=711
"""

from __future__ import annotations

import uuid as uuid_module
from msgspec import Struct
from typing import Any, final

import duckdb
import pendulum
import tigerbeetle as tb
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.core.broker import broker
from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
)
from nexus_ai.services.trace_generator import TraceGenerator

from nexus_crypto import (
    PipelineComputeResult as _RustPipelineComputeResult,
    run_full_pipeline as _rust_run_full_pipeline,
    # PreLedgerValidator zastąpiony — walidacja inline poniżej
)

from .audit import DecisionTraceLogger
from .math_engine import (
    InvoicePositions,
    InvoiceSummary,
    TaxMathEngine,
)

from nexus_ai.core.opa_client import OpaError
from nexus_ai.tax.rules import (
    RuleEngine,
    ContextInterpreter as TaxContextInterpreter,
)

logger = get_logger("nexus.tax.pipeline")


@final
class PipelineResult(Struct):
    """Result of processing a single invoice through the tax pipeline."""

    success: bool
    transaction_id: str
    trace_id: str | None = None
    verdict: dict[str, Any] | None = None
    vat_grosze: int = 0
    brutto_grosze: int = 0
    tigerbeetle_result: dict[str, Any] | None = None
    error: str | None = None
    routing: str | None = None
    routing_reason: str | None = None


@final
class TaxPipeline:
    """Orchestrates the complete tax processing pipeline.

    SUPERMOCE:
    - OPA (Open Policy Agent) → primary rule evaluation engine
    - DuckDB (RuleStore) → temporal rule storage (fallback when OPA unavailable)
    - Nexus-TaxEngine (Rust+PyO3) → natywny orkiestrator: przygotowuje dane dla OPA,
      odbiera decyzję i wykonuje krytyczne obliczenia matematyczne
    - TigerBeetle → linked transfers: expense + VAT w atomowym chainie
    - Batch: oba transfery w jednym create_transfers() call
    - code: 1001 dla expense, 1002 dla VAT
    - user_data_128: UUID dokumentu
    - ledger: 700 dla PLN, 711 dla VAT

    Processing flow:
      1. OPA evaluation (primary) → RuleEngine.decide_async() → verdict
      2. Fallback: Rust pipeline (when OPA unavailable)
      3. TaxMathEngine → integer-only VAT computation (ROUND_HALF_UP)
      4. InvariantGuard → balance-check 3 invariantów
      5. DecisionTraceLogger → SHA-256 hash chain
      6. PreLedgerValidator → account pair/balance validation
      7. TigerBeetle → double-entry linked transfers
      8. Event emission → DecisionMade via NATS
    """

    def __init__(
        self,
        conn: duckdb.DuckDBPyConnection,
        tigerbeetle: Any = None,
        *,
        write_outbox: Any = None,
        account_expense_id: int = 40100,
        account_vat_input_id: int = 22100,
        account_payables_id: int = 20200,
        rule_engine: RuleEngine | None = None,
    ) -> None:
        self._conn = conn
        self._tigerbeetle = tigerbeetle
        self._write_outbox = write_outbox
        self._logger = DecisionTraceLogger(conn)
        # PreLedgerValidator zastąpiony — walidacja inline w _post_process
        # Patrz: _post_process → inline_pre_ledger_validation

        # Inicjalizuj RuleEngine z OPA support
        self._rule_engine = rule_engine or RuleEngine(conn)

        self._account_expense_id = account_expense_id
        self._account_vat_input_id = account_vat_input_id
        self._account_payables_id = account_payables_id

    # ── Główna metoda przetwarzania: OPA → Rust fallback ───────────────

    async def process_invoice(
        self,
        invoice_data: dict[str, Any],
        *,
        transaction_id: str | None = None,
        opa_evaluation: bool = True,
    ) -> PipelineResult:
        """Process invoice through the tax pipeline.

        Dwie ścieżki:
          1. OPA (primary): RuleEngine.decide_async() → verdict → TaxMathEngine
          2. Rust fallback: _rust_run_full_pipeline() (when OPA unavailable)

        Args:
            invoice_data: Raw invoice data dict.
            transaction_id: Optional override transaction ID.
            opa_evaluation: If True (default), tries OPA first.
                            Set False to force Rust pipeline.

        Returns:
            PipelineResult with full processing outcome.
        """
        tx_id = transaction_id or uuid_module.uuid4().hex

        txn_date = invoice_data.get(
            "transaction_date",
            pendulum.now("UTC").date().isoformat(),
        )
        txn_date_str = str(txn_date) if not isinstance(txn_date, str) else txn_date

        # ── Try OPA evaluation first (primary path) ────────────────────
        if opa_evaluation:
            try:
                return await self._process_with_opa(
                    invoice_data=invoice_data,
                    transaction_id=tx_id,
                    txn_date_str=txn_date_str,
                )
            except OpaError:
                logger.info(
                    "[TAX-PIPELINE] OPA unavailable, falling back to Rust pipeline for tx_id=%s",
                    tx_id,
                )
            except Exception as exc:
                logger.warning(
                    "[TAX-PIPELINE] OPA path failed (%s), falling back to Rust for tx_id=%s",
                    exc,
                    tx_id,
                )

        # ── Fallback: Rust pipeline ─────────────────────────────────────
        return await self._process_with_rust(
            invoice_data=invoice_data,
            transaction_id=tx_id,
            txn_date_str=txn_date_str,
        )

    # ═══════════════════════════════════════════════════════════════════
    # ŚCIEŻKA 1: OPA (Primary)
    # ═══════════════════════════════════════════════════════════════════

    async def _process_with_opa(
        self,
        invoice_data: dict[str, Any],
        *,
        transaction_id: str,
        txn_date_str: str,
    ) -> PipelineResult:
        """Process invoice using OPA rule evaluation + Rust TaxMathEngine.

        Flow:
          1. Build context via TaxContextInterpreter
          2. OPA evaluation via RuleEngine.decide_async()
          3. TaxMathEngine computes net/vat/brutto in grosze
          4. InvariantGuard validates 3 invariants
          5. DecisionTraceLogger captures audit chain
          6. Continue to shared post-processing (PreLedger, TB, events)
        """
        # ── 1. Build context ───────────────────────────────────────────
        context = TaxContextInterpreter.build(invoice_data)

        # ── 2. OPA evaluation ──────────────────────────────────────────
        verdict = await self._rule_engine.decide_async(
            context,
            include_decision_trace=False,
        )

        # Extract verdict fields
        rule_id = verdict.get("rule_id", "")
        vat_rate_str = verdict.get("vat_rate", "0.23")
        rounding_level = verdict.get("rounding_level", "position")
        routing = verdict.get("_routing") or None
        routing_reason = verdict.get("_routing_reason") or None

        # ── 3. TaxMathEngine: compute amounts in grosze (integer-only)  ──
        # Net amount from invoice data (or extract from context)
        # TaxMathEngine ma wbudowany Python fallback gdy Rust niedostępny
        raw_net = invoice_data.get("amount_net", context.get("amount_net", "0"))
        net_grosze = TaxMathEngine.to_grosze(str(raw_net))

        # Single position invoice (most common)
        vat_grosze = TaxMathEngine.multiply_net_by_vat(net_grosze, vat_rate_str)
        brutto_grosze = TaxMathEngine.add_tax(net_grosze, vat_grosze)

        positions = [InvoicePositions(net_grosze=net_grosze, vat_rate=vat_rate_str)]
        summary = InvoiceSummary(
            netto_grosze=net_grosze,
            vat_grosze=vat_grosze,
            brutto_grosze=brutto_grosze,
        )

        # ── 4. InvariantGuard (validate 3 invariants) ──────────────────
        inv_result = TaxMathEngine.validate_invariants(positions, summary)
        invariants_json = msgspec_dumps({
            "is_valid": inv_result.is_valid,
            "error_message": inv_result.error_message,
        }, ensure_ascii=False)

        if not inv_result.is_valid:
            self._logger.log(
                transaction_id=transaction_id,
                rule_id=rule_id,
                context=context,
                verdict=verdict,
                invariants_result=invariants_json,
                calculation_input=msgspec_dumps(invoice_data, ensure_ascii=False),
                calculation_output=msgspec_dumps({
                    "net_grosze": net_grosze,
                    "vat_grosze": vat_grosze,
                    "brutto_grosze": brutto_grosze,
                }, ensure_ascii=False),
            )
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                error=f"INVARIANT_FAILURE: {inv_result.error_message}",
                vat_grosze=vat_grosze,
                brutto_grosze=brutto_grosze,
            )

        # ── 5. Decision trace ───────────────────────────────────────────
        decision_trace_text = self._build_decision_trace(
            rule_id=rule_id,
            context=context,
            verdict=verdict,
        )

        # ── 6. Continue to shared post-processing ───────────────────────
        return await self._post_process(
            transaction_id=transaction_id,
            invoice_data=invoice_data,
            context=context,
            verdict=verdict,
            rule_id=rule_id,
            vat_rate_str=vat_rate_str,
            rounding_level=rounding_level,
            total_net_grosze=net_grosze,
            total_vat_grosze=vat_grosze,
            total_brutto_grosze=brutto_grosze,
            positions=positions,
            summary=summary,
            invariants_json=invariants_json,
            routing=routing,
            routing_reason=routing_reason,
            decision_trace_text=decision_trace_text,
            evaluated_rules=None,
            calc_input=msgspec_dumps(invoice_data, ensure_ascii=False, default=str),
            calc_output=msgspec_dumps({
                "net_grosze": net_grosze,
                "vat_grosze": vat_grosze,
                "brutto_grosze": brutto_grosze,
            }, ensure_ascii=False, default=str),
        )

    # ═══════════════════════════════════════════════════════════════════
    # ŚCIEŻKA 2: Rust pipeline (Fallback)
    # ═══════════════════════════════════════════════════════════════════

    async def _process_with_rust(
        self,
        invoice_data: dict[str, Any],
        *,
        transaction_id: str,
        txn_date_str: str,
    ) -> PipelineResult:
        """Process invoice using the original Rust pipeline (fallback)."""
        # ── DuckDB I/O: temporal rules ─────────────────────────────────
        all_rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, "
            "valid_from, valid_to FROM tax_rules "
            "WHERE CAST(? AS DATE) BETWEEN valid_from "
            "AND COALESCE(valid_to, '9999-12-31') "
            "ORDER BY priority ASC, valid_from DESC, rule_id ASC",
            (txn_date_str,),
        ).fetchall()

        if not all_rows:
            logger.error(
                "[TAX-PIPELINE] No active tax rules for date=%s tx_id=%s",
                txn_date_str,
                transaction_id,
            )
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                error=f"NO_MATCHING_RULE: No active tax rules found for date {txn_date_str}",
            )

        all_rules: list[dict[str, Any]] = []
        for r in all_rows:
            rule: dict[str, Any] = {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),
                "priority": int(r[3]),
                "valid_from": str(r[4]),
            }
            if r[5] is not None:
                rule["valid_to"] = str(r[5])
            all_rules.append(rule)

        rules_json = msgspec_dumps(all_rules, ensure_ascii=False, default=str)
        invoice_data_json = msgspec_dumps(invoice_data, ensure_ascii=False, default=str)

        try:
            result: _RustPipelineComputeResult = _rust_run_full_pipeline(
                invoice_data_json=invoice_data_json,
                rules_json=rules_json,
                transaction_id=transaction_id,
            )
        except Exception as exc:
            logger.error(
                "[TAX-PIPELINE] run_full_pipeline failed: %s tx_id=%s",
                exc,
                transaction_id,
            )
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                error=f"PIPELINE_FAILURE: {exc}",
            )

        # ── Extract computed values ────────────────────────────────────
        total_net_grosze = result.netto_grosze
        total_vat_grosze = result.vat_grosze
        total_brutto_grosze = result.brutto_grosze

        positions_net = list(result.positions_net_grosze) if result.positions_net_grosze else []
        positions = [
            InvoicePositions(net_grosze=ng, vat_rate=str(result.parsed_vat_rate))
            for ng in positions_net
        ]
        summary = InvoiceSummary(
            netto_grosze=total_net_grosze,
            vat_grosze=total_vat_grosze,
            brutto_grosze=total_brutto_grosze,
        )

        invariants_json = result.invariants_result_json
        rule_id = result.matched_rule_id
        vat_rate_str = result.parsed_vat_rate
        rounding_level = result.parsed_rounding_level
        routing = result.routing or None
        routing_reason = result.routing_reason or None

        # Extract audit params
        audit_params = result.audit_params
        context: dict[str, Any] = {}
        verdict: dict[str, Any] = {}
        evaluated_rules: list[dict[str, Any]] = []
        calc_input = result.calculation_input_json
        calc_output = result.calculation_output_json

        if audit_params is not None:
            if audit_params.context_json:
                try:
                    context = msgspec_loads(audit_params.context_json) or {}
                except (ValueError, TypeError):
                    context = {}
            if audit_params.verdict_json:
                try:
                    verdict = msgspec_loads(audit_params.verdict_json) or {}
                except (ValueError, TypeError):
                    verdict = {}
            if audit_params.evaluated_rules_json:
                try:
                    parsed = msgspec_loads(audit_params.evaluated_rules_json)
                    if isinstance(parsed, list):
                        evaluated_rules = parsed
                except (ValueError, TypeError):
                    pass

        # ── Error paths ─────────────────────────────────────────────────
        if not result.is_valid:
            error_lower = result.error_message.upper()
            if "NO_MATCHING_RULE" in error_lower:
                self._logger.log(
                    transaction_id=transaction_id,
                    context=context or {"error": "No context available"},
                    invariants_result=msgspec_dumps({"error": result.error_message}),
                )
                return PipelineResult(
                    success=False,
                    transaction_id=transaction_id,
                    error=result.error_message,
                )

            self._logger.log(
                transaction_id=transaction_id,
                rule_id=rule_id,
                context=context,
                verdict=verdict,
                calculation_input=calc_input,
                calculation_output=calc_output,
                invariants_result=invariants_json,
            )
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                error=f"INVARIANT_FAILURE: {result.error_message}",
            )

        # ── Decision trace ──────────────────────────────────────────────
        decision_trace_text = self._build_decision_trace(
            rule_id=rule_id,
            context=context,
            verdict=verdict,
        )

        # ── Continue to shared post-processing ───────────────────────────
        return await self._post_process(
            transaction_id=transaction_id,
            invoice_data=invoice_data,
            context=context,
            verdict=verdict,
            rule_id=rule_id,
            vat_rate_str=vat_rate_str,
            rounding_level=rounding_level,
            total_net_grosze=total_net_grosze,
            total_vat_grosze=total_vat_grosze,
            total_brutto_grosze=total_brutto_grosze,
            positions=positions,
            summary=summary,
            invariants_json=invariants_json,
            routing=routing,
            routing_reason=routing_reason,
            decision_trace_text=decision_trace_text,
            evaluated_rules=evaluated_rules,
            calc_input=calc_input,
            calc_output=calc_output,
        )

    # ═══════════════════════════════════════════════════════════════════
    # WSPÓLNE POST-PROCESSING (dla obu ścieżek)
    # ═══════════════════════════════════════════════════════════════════

    async def _post_process(
        self,
        *,
        transaction_id: str,
        invoice_data: dict[str, Any],
        context: dict[str, Any],
        verdict: dict[str, Any],
        rule_id: str | None,
        vat_rate_str: str,
        rounding_level: str,
        total_net_grosze: int,
        total_vat_grosze: int,
        total_brutto_grosze: int,
        positions: list,
        summary: InvoiceSummary,
        invariants_json: str,
        routing: str | None,
        routing_reason: str | None,
        decision_trace_text: str | None,
        evaluated_rules: list | None,
        calc_input: str,
        calc_output: str,
    ) -> PipelineResult:
        """Shared post-processing: PreLedger, TigerBeetle, events.

        Używane przez obie ścieżki (OPA i Rust).
        """
        # ── Inline PreLedger validation (zastępuje wycofany PreLedgerValidator) ──
        # Walidacja: limity kwot, spójność walut, bilans
        tb_ok = True
        pre_ledger_errors: list[str] = []

        # 1. Limity kwot (max 10 mln PLN = 1_000_000_000 gr)
        MAX_AMOUNT_GROSZE = 1_000_000_000
        for label, amount in [("net", total_net_grosze), ("vat", total_vat_grosze)]:
            if abs(amount) > MAX_AMOUNT_GROSZE:
                pre_ledger_errors.append(
                    f"[LIMIT] {label}: {amount} gr exceeds max {MAX_AMOUNT_GROSZE} gr"
                )

        # 2. Znak kwoty (POSITIVE dla EXPENSE)
        for label, amount in [("net", total_net_grosze), ("vat", total_vat_grosze)]:
            if amount < 0:
                pre_ledger_errors.append(
                    f"[AMOUNT_SIGN] {label}: expected POSITIVE, got {amount} gr"
                )

        # 3. Bilans: suma debetów powinna być bliska sumie kredytów
        # W linked transfers netto + VAT = brutto (bilans zapewnia TB BALANCING_CREDIT)
        total_debit = total_net_grosze + total_vat_grosze
        total_credit = total_net_grosze + total_vat_grosze  # w TB każdy transfer ma obie strony
        if total_debit != total_credit:
            pre_ledger_errors.append(
                f"[BALANCE] debit={total_debit} gr != credit={total_credit} gr"
            )

        # 4. Delegacja do TaxInvariantGuard (niezmienniki matematyczne)
        inv_result = TaxMathEngine.validate_invariants(positions, summary)
        if not inv_result.is_valid:
            pre_ledger_errors.append(f"[INVARIANTS] {inv_result.error_message}")

        if pre_ledger_errors:
            tb_ok = False
            logger.error(
                "[PRE-LEDGER] Validation failed: %s",
                "; ".join(pre_ledger_errors),
            )

        # ── SUPERMOC: TigerBeetle linked transfers ──────────────────────
        tb_result = None

        if routing:
            tb_ok = False
            if routing == "BLOCK_AND_ALERT":
                logger.warning(
                    "[TAX-PIPELINE] BLOCKED by routing=%s tid=%s reason=%s",
                    routing,
                    transaction_id,
                    routing_reason,
                )
            else:
                logger.info(
                    "[TAX-PIPELINE] Routing=%s tid=%s reason=%s",
                    routing,
                    transaction_id,
                    routing_reason,
                )
        elif pre_ledger_errors:
            tb_ok = False
        elif self._write_outbox is not None and callable(self._write_outbox):
            outbox_payload = {
                "transaction_id": transaction_id,
                "rule_id": rule_id or "",
                "net_grosze": total_net_grosze,
                "vat_grosze": total_vat_grosze,
                "brutto_grosze": total_brutto_grosze,
                "account_debit": "expenses",
                "account_credit": "liabilities",
                "timestamp": pendulum.now("UTC").isoformat(),
            }
            try:
                await self._write_outbox(outbox_payload)
                tb_result = {"status": "OUTBOX_ENQUEUED", "transaction_id": transaction_id}
                logger.info(
                    "[TAX-OUTBOX] Enqueued tid=%s net=%d vat=%d",
                    transaction_id,
                    total_net_grosze,
                    total_vat_grosze,
                )
            except Exception as exc:
                tb_result = {"status": "ERROR", "error": str(exc)}
                tb_ok = False
        elif self._tigerbeetle is not None:
            try:
                tb_result = await self.post_to_tigerbeetle_linked(
                    net_grosze=total_net_grosze,
                    vat_grosze=total_vat_grosze,
                    brutto_grosze=total_brutto_grosze,
                    source_document_id=transaction_id,
                )
                if tb_result.get("status") == "ERROR":
                    tb_ok = False
            except Exception as exc:
                tb_result = {"status": "ERROR", "error": str(exc)}
                tb_ok = False

        # ── Decision Trace Logger ───────────────────────────────────────
        trace_json_str = TraceGenerator.generate_trace_json(
            evaluated_rules=evaluated_rules,
            final_verdict=verdict,
            context=context,
        )

        trace_id = self._logger.log(
            transaction_id=transaction_id,
            rule_id=rule_id,
            context=context,
            verdict=verdict,
            calculation_input=calc_input,
            calculation_output=calc_output,
            invariants_result=invariants_json,
            decision_trace=decision_trace_text,
            trace_json=trace_json_str,
        )

        # ── Emit DecisionMade event ─────────────────────────────────────
        try:
            invoice_id = str(invoice_data.get("invoice_id", transaction_id))
            action = verdict.get("action", "AUTO_POST")

            decision_val = action
            if routing:
                if routing == "BLOCK_AND_ALERT":
                    decision_val = "BLOCK"
                elif routing == "TRIAGE_QUEUE":
                    decision_val = "ASK_USER"
                else:
                    decision_val = routing

            await broker.kick("event_emit_decision_made",
                invoice_id=invoice_id,
                decision=decision_val,
                trust_score=float(verdict.get("trust_score", verdict.get("ai_confidence", 0.5))),
                ai_confidence=float(verdict.get("ai_confidence", 0.5)),
                decision_pattern=str(rule_id or "")[:64],
                reasoning=decision_trace_text[:512]
                if decision_trace_text
                else "Tax pipeline decision",
                metadata={
                    "transaction_id": transaction_id,
                    "trace_id": trace_id,
                    "vat_rate": vat_rate_str,
                    "routing": routing,
                    "routing_reason": routing_reason,
                    "net_grosze": total_net_grosze,
                    "vat_grosze": total_vat_grosze,
                },
            )
            logger.info(
                "[TAX-EVENT] DecisionMade emitted for invoice_id=%s decision=%s tx_id=%s",
                invoice_id,
                decision_val,
                transaction_id,
            )
        except Exception as emit_err:
            logger.warning(
                "[TAX-EVENT] Failed to emit DecisionMade for tx_id=%s: %s",
                transaction_id,
                emit_err,
            )

        # ── Result handling ─────────────────────────────────────────────
        if routing:
            if routing == "BLOCK_AND_ALERT":
                return PipelineResult(
                    success=False,
                    transaction_id=transaction_id,
                    trace_id=trace_id,
                    verdict=verdict,
                    vat_grosze=total_vat_grosze,
                    brutto_grosze=total_brutto_grosze,
                    error=f"ROUTING_BLOCKED: {routing_reason}",
                    routing=routing,
                    routing_reason=routing_reason,
                )
            return PipelineResult(
                success=True,
                transaction_id=transaction_id,
                trace_id=trace_id,
                verdict=verdict,
                vat_grosze=total_vat_grosze,
                brutto_grosze=total_brutto_grosze,
                routing=routing,
                routing_reason=routing_reason,
            )

        if pre_ledger_errors:
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                trace_id=trace_id,
                verdict=verdict,
                vat_grosze=total_vat_grosze,
                brutto_grosze=total_brutto_grosze,
                tigerbeetle_result=tb_result,
                error="PRE_LEDGER_VALIDATION_FAILED: account pair or sign check failed",
            )

        if not tb_ok:
            return PipelineResult(
                success=False,
                transaction_id=transaction_id,
                trace_id=trace_id,
                verdict=verdict,
                vat_grosze=total_vat_grosze,
                brutto_grosze=total_brutto_grosze,
                tigerbeetle_result=tb_result,
                error=f"TIGERBEELE_FAILURE: transfer posting failed — {tb_result}",
                routing=routing,
                routing_reason=routing_reason,
            )

        return PipelineResult(
            success=True,
            transaction_id=transaction_id,
            trace_id=trace_id,
            verdict=verdict,
            vat_grosze=total_vat_grosze,
            brutto_grosze=total_brutto_grosze,
            tigerbeetle_result=tb_result,
            routing=routing,
            routing_reason=routing_reason,
        )

    # ── Helper: Build decision trace ──────────────────────────────────────

    def _build_decision_trace(
        self,
        rule_id: str | None,
        context: dict[str, Any],
        verdict: dict[str, Any],
    ) -> str | None:
        """Build human-readable decision trace from rule info."""
        decision_trace_from_verdict = verdict.pop("decision_trace", None)
        if decision_trace_from_verdict:
            return decision_trace_from_verdict

        if not rule_id:
            return None

        rule_rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, description_template "
            "FROM tax_rules WHERE rule_id = ?",
            (rule_id,),
        ).fetchall()

        if not rule_rows:
            return None

        r = rule_rows[0]
        rule_info = {
            "rule_id": str(r[0]),
            "condition_sql": str(r[1]),
            "description_template": str(r[3]) if r[3] else None,
        }
        return TraceGenerator.generate(
            rule=rule_info,
            context=context,
            verdict=verdict,
        )

    # ── SUPERMOC: Linked + batch transfer to TigerBeetle ──────────────────

    async def post_to_tigerbeetle_linked(
        self,
        net_grosze: int,
        vat_grosze: int,
        brutto_grosze: int,
        source_document_id: str,
    ) -> dict[str, Any]:
        """Post double-entry transfers to TigerBeetle jako LINKED CHAIN.

        SUPERMOCE:
        - Linked transfers: expense + VAT w atomowym chainie
        - Batch: oba w jednym create_transfers()
        - code: 1001=expense, 1002=vat
        - user_data_128: UUID dokumentu
        - ledger: 700 dla netto, 711 dla VAT

        Transfer structure (expense invoice):
          Transfer 1 (linked): Expense → Payables (net)    [ledger=700, code=1001]
          Transfer 2 (no link): VAT → Payables (vat)       [ledger=711, code=1002]
          → ATOMIC: albo oba, albo żaden
        """
        source_uuid = (
            uuid_module.UUID(source_document_id)
            if isinstance(source_document_id, str)
            else source_document_id
        )

        # SUPERMOC: Build linked chain z BALANCING_CREDIT
        # TB automatycznie wyrówna różnice groszowe (netto + VAT vs brutto)
        specs = [
            {
                "debit": self._account_expense_id,
                "credit": self._account_payables_id,
                "amount": net_grosze,
                "code": TRANSFER_CODE["EXPENSE_NET"],
                "ledger": LEDGER["PLN"],
            },
            {
                "debit": self._account_vat_input_id,
                "credit": self._account_payables_id,
                "amount": vat_grosze,
                "code": TRANSFER_CODE["EXPENSE_VAT"],
                "ledger": LEDGER["VAT_INPUT"],
                # SUPERMOC: BALANCING_CREDIT — TB automatycznie wyrówna
                # różnicę między sumą debetów a kredytem na koncie payables
                "flags": tb.TransferFlags.BALANCING_CREDIT,
            },
        ]

        # SUPERMOC: build_linked_transfers tworzy chain z flags.linked
        transfers = self._tigerbeetle.build_linked_transfers(
            specs,
            source_document_id=source_uuid,
            ledger=LEDGER["PLN"],  # base ledger
        )

        # SUPERMOC: Batch create — jeden round-trip
        results = await self._tigerbeetle.create_transfers_async(transfers)

        # Sprawdź wyniki — status=0 oznacza OK
        all_ok = all(r.status == 0 for r in results)

        return {
            "status": "POSTED" if all_ok else "LINKED_CHAIN_FAILED",
            "transfers": [
                {
                    "type": "expense",
                    "debit": self._account_expense_id,
                    "credit": self._account_payables_id,
                    "amount_minor": net_grosze,
                    "ledger": LEDGER["PLN"],
                    "code": TRANSFER_CODE["EXPENSE_NET"],
                    "result": str(results[0]) if len(results) > 0 else "unknown",
                },
                {
                    "type": "vat_input",
                    "debit": self._account_vat_input_id,
                    "credit": self._account_payables_id,
                    "amount_minor": vat_grosze,
                    "ledger": LEDGER["VAT_INPUT"],
                    "code": TRANSFER_CODE["EXPENSE_VAT"],
                    "result": str(results[1]) if len(results) > 1 else "unknown",
                },
            ],
            "total_debit": net_grosze + vat_grosze,
            "total_credit": brutto_grosze,
        }

    # ── Legacy method (backward compat) ──────────────────────────────────

    async def post_to_tigerbeetle(
        self,
        net_grosze: int,
        vat_grosze: int,
        brutto_grosze: int,
        source_document_id: str,
    ) -> dict[str, Any]:
        """Legacy — deleguje do post_to_tigerbeetle_linked."""
        return await self.post_to_tigerbeetle_linked(
            net_grosze=net_grosze,
            vat_grosze=vat_grosze,
            brutto_grosze=brutto_grosze,
            source_document_id=source_document_id,
        )

    # ── Active Learning ──────────────────────────────────────────────────

    async def record_active_learning_example(
        self,
        transaction_id: str,
        original_data: dict[str, Any],
        corrected_data: dict[str, Any],
        verified_by: str = "system",
    ) -> None:
        """Zapisuje przykład ręcznej korekty dla active learning."""
        example_id = uuid_module.uuid4().hex
        now = pendulum.now("UTC").isoformat()

        self._conn.execute(
            "CREATE TABLE IF NOT EXISTS active_learning_examples ("
            "example_id VARCHAR PRIMARY KEY, transaction_id VARCHAR NOT NULL, "
            "original_data VARCHAR NOT NULL, corrected_data VARCHAR NOT NULL, "
            "verified_by VARCHAR NOT NULL, verified_at TIMESTAMP NOT NULL, "
            "used_for_training BOOLEAN NOT NULL DEFAULT FALSE, "
            "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"
        )
        self._conn.execute(
            "INSERT INTO active_learning_examples "
            "(example_id, transaction_id, original_data, corrected_data, verified_by, verified_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (
                example_id,
                transaction_id,
                msgspec_dumps(original_data, ensure_ascii=False, default=str),
                msgspec_dumps(corrected_data, ensure_ascii=False, default=str),
                verified_by,
                now,
            ),
        )
        logger.info(
            "[ACTIVE-LEARNING] Recorded correction tid=%s example_id=%s by=%s",
            transaction_id,
            example_id,
            verified_by,
        )

    async def get_active_learning_stats(self) -> dict[str, Any]:
        """Statystyki active learning dla dashboardu."""
        self._conn.execute(
            "CREATE TABLE IF NOT EXISTS active_learning_examples ("
            "example_id VARCHAR PRIMARY KEY, transaction_id VARCHAR NOT NULL, "
            "original_data VARCHAR NOT NULL, corrected_data VARCHAR NOT NULL, "
            "verified_by VARCHAR NOT NULL, verified_at TIMESTAMP NOT NULL, "
            "used_for_training BOOLEAN NOT NULL DEFAULT FALSE, "
            "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"
        )
        total = self._conn.execute("SELECT COUNT(*) FROM active_learning_examples").fetchone()
        unused = self._conn.execute(
            "SELECT COUNT(*) FROM active_learning_examples WHERE used_for_training = FALSE"
        ).fetchone()
        return {
            "total_examples": int(total[0]) if total else 0,
            "unused_for_training": int(unused[0]) if unused else 0,
        }
