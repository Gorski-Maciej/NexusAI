"""
Tax Pipeline — orchestrates the complete tax processing flow.

Łączy wszystkie trzy warstwy w jeden deterministyczny pipeline:

  Steps 1-5 (Rust+PyO3 — **one call to run_full_pipeline**):
    1. ContextInterpreter  → flat context dict (JSON)
    2. RuleEngine          → first-match-wins SQL evaluation
    3. TaxMathEngine       → VAT calculation in grosze
    4. TaxInvariantGuard   → three invariants check
    5. AuditHashChain      → SHA-256 hash for decision trace

  Steps 6-8 (Python async I/O):
    6. PreLedgerValidator  → account pair/balance validation
    7. TigerBeetle         → double-entry transfers (via outbox or direct)
    8. Event emission      → DecisionMade event via NATS

  DecisionTraceLogger — uses Rust prepare_log() + DuckDB INSERT
"""

from __future__ import annotations

import uuid
from msgspec import Struct
from typing import Any, final

import duckdb
import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.events.event_emitter import get_event_emitter
from nexus_ai.services.pre_ledger_validator import (
    PreLedgerValidator,
    TransferSpec,
)
from nexus_crypto import TemporalManager as _RustTemporalManager
from nexus_ai.services.trace_generator import TraceGenerator

from nexus_crypto import (
    PipelineComputeResult as _RustPipelineComputeResult,
    run_full_pipeline as _rust_run_full_pipeline,
)

from .audit import DecisionTraceLogger
from .math_engine import (
    InvoicePositions,
    InvoiceSummary,
    TaxMathEngine,
    to_money,
)

logger = get_logger("nexus.tax.pipeline")


@final
class PipelineResult(Struct):
    """Result of processing a single invoice through the tax pipeline.

    @final: mypyc devirtualizes property access.

    Attributes:
        success: Whether the pipeline completed without errors.
        transaction_id: UUID of the processed transaction.
        trace_id: UUID of the decision trace entry (None on early failure).
        verdict: Rule engine verdict dict (None on early failure).
        vat_grosze: Calculated VAT in grosze.
        brutto_grosze: Calculated gross in grosze.
        tigerbeetle_result: Result from TigerBeetle posting (None if not configured).
        error: Error message if success is False.
        routing: Routing action from verdict (e.g. BLOCK_AND_ALERT, TRIAGE_QUEUE).
            None if no routing was requested (normal processing).
        routing_reason: Human-readable reason for the routing action.
    """

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

    @final: mypyc devirtualizes all method calls.
    process_invoice() is called for EVERY invoice — 2-5× speedup matters.

    **Steps 1-5 are executed in a single Rust call** (``run_full_pipeline``):
      context → rules → math → invariants → audit hash

    This eliminates 2 FFI boundary crossings and intermediate Python
    serialization compared to the previous 3-call approach.

    Async I/O (TigerBeetle, events, active learning) remains in Python.

    Args:
        conn: DuckDB connection with ``tax_rules`` and ``decision_traces`` tables.
        tigerbeetle: Optional TigerBeetle client for double-entry posting.
        write_outbox: Optional async callback to write outbox events.
            Signature: ``async write_outbox(payload: dict) -> None``.
            When provided, TigerBeetle posting is deferred to outbox relay.
        account_expense_id: TigerBeetle account ID for expense (Wn).
        account_vat_input_id: TigerBeetle account ID for VAT input (Wn).
        account_payables_id: TigerBeetle account ID for payables (Ma).
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
    ) -> None:
        self._conn = conn
        self._tigerbeetle = tigerbeetle
        self._write_outbox = write_outbox
        self._logger = DecisionTraceLogger(conn)
        self._pre_ledger = PreLedgerValidator(conn)
        self._pre_ledger.ensure_default_rules(
            expense_account_id=account_expense_id,
            vat_account_id=account_vat_input_id,
            payables_account_id=account_payables_id,
        )

        # Default TigerBeetle account IDs (Polish chart of accounts)
        self._account_expense_id = account_expense_id
        self._account_vat_input_id = account_vat_input_id
        self._account_payables_id = account_payables_id

    async def process_invoice(
        self,
        invoice_data: dict[str, Any],
        *,
        transaction_id: str | None = None,
    ) -> PipelineResult:
        """Process a single invoice through the entire tax pipeline.

        **Steps 1-5 are executed in a single Rust call** via
        ``run_full_pipeline``: context → rules → math → invariants → audit hash

        Steps 6-8 are executed in Python:
          PreLedgerValidator → TigerBeetle/outbox → events

        Args:
            invoice_data: Normalized invoice dictionary (from OCR pipeline).
                Must include at minimum:
                - ``category_code``: str
                - ``transaction_date``: str (YYYY-MM-DD) or date
                - ``company_tax_form``: str
                - ``vendor_country``: str
                - ``amount_net``: Decimal | str | float
                Optional:
                - ``positions``: list[dict] with ``net_amount`` keys
                - ``vendor_vat_status``: str
                - ``vendor_pkd``: str
            transaction_id: Optional pre-assigned UUID. Auto-generated if None.

        Returns:
            :class:`PipelineResult` with success/failure and full trace.
        """
        tx_id = transaction_id or uuid.uuid4().hex

        # ── DuckDB I/O: temporal rules + previous hash ─────────────────────
        # These are the only I/O operations before Rust computation:
        #   1. Load temporal rules active on transaction date
        #   2. Fetch previous_hash for audit chain

        txn_date = invoice_data.get(
            "transaction_date",
            pendulum.now("UTC").date().isoformat(),
        )
        txn_date_str = str(txn_date) if not isinstance(txn_date, str) else txn_date

        # ── DuckDB I/O: load ALL rules + filter in Rust ──────────────────────
        # Load all rules without temporal WHERE clause — Rust TemporalManager
        # handles date filtering + temporal sorting in memory.

        all_rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, "
            "valid_from, valid_to FROM tax_rules"
        ).fetchall()

        if not all_rows:
            logger.error(
                "[TAX-PIPELINE] No tax rules in database tx_id=%s",
                tx_id,
            )
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                error=f"NO_RULES: No tax rules in database",
            )

        # Serialize all rules to JSON (include temporal fields for Rust TemporalManager)
        all_rules: list[dict[str, Any]] = []
        for r in all_rows:
            rule: dict[str, Any] = {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),  # already JSON string from DuckDB
                "priority": int(r[3]),
                "valid_from": str(r[4]),
            }
            if r[5] is not None:
                rule["valid_to"] = str(r[5])
            all_rules.append(rule)

        all_rules_json = msgspec_dumps(all_rules, ensure_ascii=False, default=str)

        # Filter temporally using Rust TemporalManager.filter_rules()
        # (date filtering + temporal sorting — no DuckDB temporal WHERE)
        filtered_rules_json = _RustTemporalManager.filter_rules(all_rules_json, txn_date_str)
        filtered_rules = msgspec_loads(filtered_rules_json)

        if not filtered_rules:
            logger.error(
                "[TAX-PIPELINE] No active tax rules for date=%s tx_id=%s",
                txn_date_str,
                tx_id,
            )
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                error=f"NO_MATCHING_RULE: No active tax rules found for date {txn_date_str}",
            )

        # Rust TemporalManager already sorts by (priority ASC, valid_from DESC, rule_id ASC)
        rules_json = msgspec_dumps(filtered_rules, ensure_ascii=False, default=str)

        # ── Steps 1-5: Single Rust call (run_full_pipeline) ────────────────
        #   1. ContextInterpreter  → flat context dict
        #   2. RuleEngine          → first-match-wins
        #   3. TaxMathEngine       → VAT calculation in grosze
        #   4. TaxInvariantGuard   → three invariants check
        #   5. AuditHashChain      → SHA-256 current_hash
        #
        # All five steps execute in Rust without Python intervention.
        # The audit hash chain is NOT computed on the Rust side — the Python
        # DecisionTraceLogger handles it via prepare_log() + DuckDB INSERT.
        # This saves 1 DuckDB query (previous_hash fetch) per invoice.

        invoice_data_json = msgspec_dumps(invoice_data, ensure_ascii=False, default=str)
        timestamp_iso = pendulum.now("UTC").isoformat()

        try:
            result: _RustPipelineComputeResult = _rust_run_full_pipeline(
                invoice_data_json=invoice_data_json,
                rules_json=rules_json,
                # previous_hash, trace_id, timestamp_iso: NOT passed — audit hash
                # chain is handled by Python DecisionTraceLogger.
                transaction_id=tx_id,
            )
        except Exception as exc:
            logger.error(
                "[TAX-PIPELINE] run_full_pipeline failed: %s tx_id=%s",
                exc,
                tx_id,
            )
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                error=f"PIPELINE_FAILURE: {exc}",
            )

        # ── Extract computed values from PipelineComputeResult ─────────────
        total_net_grosze = result.netto_grosze
        total_vat_grosze = result.vat_grosze
        total_brutto_grosze = result.brutto_grosze

        positions_net = list(result.positions_net_grosze) if result.positions_net_grosze else []
        inv_positions = [
            InvoicePositions(net_grosze=ng, vat_rate=str(result.parsed_vat_rate))
            for ng in positions_net
        ]
        summary = InvoiceSummary(
            netto_grosze=total_net_grosze,
            vat_grosze=total_vat_grosze,
            brutto_grosze=total_brutto_grosze,
        )

        validation_valid = result.is_valid
        invariants_json = result.invariants_result_json
        rule_id = result.matched_rule_id
        vat_rate_str = result.parsed_vat_rate
        rounding_level = result.parsed_rounding_level
        routing = result.routing or None
        routing_reason = result.routing_reason or None

        # Extract audit context and verdict from AuditParams (if available)
        audit_params = result.audit_params
        context: dict[str, Any] = {}
        verdict: dict[str, Any] = {}
        evaluated_rules: list[dict[str, Any]] = []
        current_hash: str = ""

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
            current_hash = audit_params.current_hash

        # ── Error paths (no match / invariant failure) ─────────────────────
        if not result.is_valid:
            error_lower = result.error_message.upper()
            if "NO_MATCHING_RULE" in error_lower:
                self._logger.log(
                    transaction_id=tx_id,
                    context=context or {"error": "No context available"},
                    invariants_result=msgspec_dumps(
                        {"error": result.error_message}
                    ),
                )
                return PipelineResult(
                    success=False,
                    transaction_id=tx_id,
                    error=result.error_message,
                )

            # Invariant failure
            self._logger.log(
                transaction_id=tx_id,
                rule_id=rule_id,
                context=context,
                verdict=verdict,
                calculation_input=result.calculation_input_json,
                calculation_output=result.calculation_output_json,
                invariants_result=invariants_json,
            )
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                error=f"INVARIANT_FAILURE: {result.error_message}",
            )

        # ── Decision trace text ───────────────────────────────────────────
        decision_trace_from_verdict = verdict.pop("decision_trace", None)
        if decision_trace_from_verdict:
            decision_trace_text = decision_trace_from_verdict
        else:
            rule_info = None
            if rule_id:
                rule_rows = self._conn.execute(
                    "SELECT rule_id, condition_sql, action_json, description_template "
                    "FROM tax_rules WHERE rule_id = ?",
                    (rule_id,),
                ).fetchall()
                if rule_rows:
                    r = rule_rows[0]
                    rule_info = {
                        "rule_id": str(r[0]),
                        "condition_sql": str(r[1]),
                        "description_template": str(r[3]) if r[3] else None,
                    }
            decision_trace_text = TraceGenerator.generate(
                rule=rule_info,
                context=context,
                verdict=verdict,
            )

        # ── Currency for amounts ──────────────────────────────────────────
        currency = str(invoice_data.get("currency", "PLN")).upper()
        total_net_money = to_money(total_net_grosze, currency)
        total_vat_money = to_money(total_vat_grosze, currency)

        # ── PreLedgerValidator (before TigerBeetle) ───────────────────────
        tb_ok = True
        pre_ledger_ok = True

        transfer_specs = [
            TransferSpec(
                debit_account_id=self._account_expense_id,
                credit_account_id=self._account_payables_id,
                amount_money=total_net_money,
                transfer_type="expense",
            ),
            TransferSpec(
                debit_account_id=self._account_vat_input_id,
                credit_account_id=self._account_payables_id,
                amount_money=total_vat_money,
                transfer_type="vat_input",
            ),
        ]
        pre_ledger_result = self._pre_ledger.validate(
            transfers=transfer_specs,
            transaction_type="EXPENSE",
            positions=inv_positions,
            summary=summary,
        )
        if not pre_ledger_result.is_valid:
            pre_ledger_ok = False
            tb_ok = False
            logger.error(
                "[PRE-LEDGER] Validation failed: %s",
                pre_ledger_result.error_message,
            )

        # ── TigerBeetle (via outbox or direct) ────────────────────────────
        tb_result = None

        if routing:
            tb_ok = False
            if routing == "BLOCK_AND_ALERT":
                logger.warning(
                    "[TAX-PIPELINE] BLOCKED by routing=%s tid=%s reason=%s",
                    routing,
                    tx_id,
                    routing_reason,
                )
            else:
                logger.info(
                    "[TAX-PIPELINE] Routing=%s tid=%s reason=%s",
                    routing,
                    tx_id,
                    routing_reason,
                )
        elif not pre_ledger_ok:
            tb_ok = False
        elif self._write_outbox is not None and callable(self._write_outbox):
            outbox_payload = {
                "transaction_id": tx_id,
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
                tb_result = {"status": "OUTBOX_ENQUEUED", "transaction_id": tx_id}
                logger.info(
                    "[TAX-OUTBOX] Enqueued tid=%s net=%d vat=%d",
                    tx_id,
                    total_net_grosze,
                    total_vat_grosze,
                )
            except Exception as exc:
                tb_result = {"status": "ERROR", "error": str(exc)}
                tb_ok = False
        elif self._tigerbeetle is not None:
            try:
                tb_result = await self.post_to_tigerbeetle(
                    net_grosze=total_net_grosze,
                    vat_grosze=total_vat_grosze,
                    brutto_grosze=total_brutto_grosze,
                    source_document_id=tx_id,
                )
                if tb_result.get("status") == "ERROR":
                    tb_ok = False
            except Exception as exc:
                tb_result = {"status": "ERROR", "error": str(exc)}
                tb_ok = False

        # ── Decision Trace Logger ─────────────────────────────────────────
        calc_input = result.calculation_input_json
        calc_output = result.calculation_output_json
        trace_json_str = TraceGenerator.generate_trace_json(
            evaluated_rules=evaluated_rules or None,
            final_verdict=verdict,
            context=context,
        )

        trace_id = self._logger.log(
            transaction_id=tx_id,
            rule_id=rule_id,
            context=context,
            verdict=verdict,
            calculation_input=calc_input,
            calculation_output=calc_output,
            invariants_result=invariants_json,
            decision_trace=decision_trace_text,
            trace_json=trace_json_str,
        )

        # ── Emit DecisionMade event ───────────────────────────────────────
        try:
            emitter = get_event_emitter()
            invoice_id = str(invoice_data.get("invoice_id", tx_id))
            action = verdict.get("action", "AUTO_POST")

            decision_val = action
            if routing:
                if routing == "BLOCK_AND_ALERT":
                    decision_val = "BLOCK"
                elif routing == "TRIAGE_QUEUE":
                    decision_val = "ASK_USER"
                else:
                    decision_val = routing

            await emitter.emit_decision_made(
                invoice_id=invoice_id,
                decision=decision_val,
                trust_score=float(verdict.get("trust_score", verdict.get("ai_confidence", 0.5))),
                ai_confidence=float(verdict.get("ai_confidence", 0.5)),
                decision_pattern=str(rule_id or "")[:64],
                reasoning=decision_trace_text[:512]
                if decision_trace_text
                else "Tax pipeline decision",
                metadata={
                    "transaction_id": tx_id,
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
                tx_id,
            )
        except Exception as emit_err:
            logger.warning(
                "[TAX-EVENT] Failed to emit DecisionMade for tx_id=%s: %s",
                tx_id,
                emit_err,
            )

        # ── Result ────────────────────────────────────────────────────────
        if routing:
            if routing == "BLOCK_AND_ALERT":
                return PipelineResult(
                    success=False,
                    transaction_id=tx_id,
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
                transaction_id=tx_id,
                trace_id=trace_id,
                verdict=verdict,
                vat_grosze=total_vat_grosze,
                brutto_grosze=total_brutto_grosze,
                routing=routing,
                routing_reason=routing_reason,
            )

        if not pre_ledger_ok:
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
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
                transaction_id=tx_id,
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
            transaction_id=tx_id,
            trace_id=trace_id,
            verdict=verdict,
            vat_grosze=total_vat_grosze,
            brutto_grosze=total_brutto_grosze,
            tigerbeetle_result=tb_result,
            routing=routing,
            routing_reason=routing_reason,
        )

    # ── Active Learning: record corrections from manual verification ───

    async def record_active_learning_example(
        self,
        transaction_id: str,
        original_data: dict[str, Any],
        corrected_data: dict[str, Any],
        verified_by: str = "system",
    ) -> None:
        """Zapisuje przykład ręcznej korekty dla active learning.

        Args:
            transaction_id: UUID transakcji.
            original_data: Surowe dane przed korektą (AI guess).
            corrected_data: Dane poprawione przez księgowego.
            verified_by: Login księgowego.
        """
        example_id = uuid.uuid4().hex
        now = pendulum.now("UTC").isoformat()

        # Ensure schema exists
        self._conn.execute(
            """CREATE TABLE IF NOT EXISTS active_learning_examples (
                example_id      VARCHAR PRIMARY KEY,
                transaction_id  VARCHAR NOT NULL,
                original_data   VARCHAR NOT NULL,
                corrected_data  VARCHAR NOT NULL,
                verified_by     VARCHAR NOT NULL,
                verified_at     TIMESTAMP NOT NULL,
                used_for_training BOOLEAN NOT NULL DEFAULT FALSE,
                created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )"""
        )

        self._conn.execute(
            """INSERT INTO active_learning_examples
               (example_id, transaction_id, original_data, corrected_data,
                verified_by, verified_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
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
            """CREATE TABLE IF NOT EXISTS active_learning_examples (
                example_id      VARCHAR PRIMARY KEY,
                transaction_id  VARCHAR NOT NULL,
                original_data   VARCHAR NOT NULL,
                corrected_data  VARCHAR NOT NULL,
                verified_by     VARCHAR NOT NULL,
                verified_at     TIMESTAMP NOT NULL,
                used_for_training BOOLEAN NOT NULL DEFAULT FALSE,
                created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )"""
        )

        total = self._conn.execute("SELECT COUNT(*) FROM active_learning_examples").fetchone()
        unused = self._conn.execute(
            "SELECT COUNT(*) FROM active_learning_examples WHERE used_for_training = FALSE"
        ).fetchone()

        return {
            "total_examples": int(total[0]) if total else 0,
            "unused_for_training": int(unused[0]) if unused else 0,
        }

    async def post_to_tigerbeetle(
        self,
        net_grosze: int,
        vat_grosze: int,
        brutto_grosze: int,
        source_document_id: str,
    ) -> dict[str, Any]:
        """Post double-entry transfers to TigerBeetle.

        Transfer structure (expense invoice):
          - Debit  (Wn): Expense account   → Credit (Ma): Payables  (net)
          - Debit  (Wn): VAT input account  → Credit (Ma): Payables  (VAT)
          Balance: net + vat = gross
        """
        source_uuid = (
            uuid.UUID(source_document_id)
            if isinstance(source_document_id, str)
            else source_document_id
        )

        # Transfer 1: expense (net)
        t1 = await self._tigerbeetle.create_two_phase_transfer(
            debit_account=self._account_expense_id,
            credit_account=self._account_payables_id,
            amount_minor=net_grosze,
            source_document_id=source_uuid,
        )
        posted1 = await self._tigerbeetle.post_pending_transfer(t1.pending_id)

        # Transfer 2: VAT input (vat)
        t2 = await self._tigerbeetle.create_two_phase_transfer(
            debit_account=self._account_vat_input_id,
            credit_account=self._account_payables_id,
            amount_minor=vat_grosze,
            source_document_id=source_uuid,
        )
        posted2 = await self._tigerbeetle.post_pending_transfer(t2.pending_id)

        return {
            "status": "POSTED" if (posted1 and posted2) else "PARTIAL",
            "transfers": [
                {
                    "type": "expense",
                    "debit": self._account_expense_id,
                    "credit": self._account_payables_id,
                    "amount_minor": net_grosze,
                    "pending_id": t1.pending_id,
                    "posted": posted1,
                },
                {
                    "type": "vat_input",
                    "debit": self._account_vat_input_id,
                    "credit": self._account_payables_id,
                    "amount_minor": vat_grosze,
                    "pending_id": t2.pending_id,
                    "posted": posted2,
                },
            ],
            "total_debit": net_grosze + vat_grosze,  # = gross
            "total_credit": brutto_grosze,
        }
