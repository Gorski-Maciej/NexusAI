"""
Tax Pipeline — orchestrates the complete tax processing flow.

Łączy wszystkie trzy warstwy w jeden deterministyczny pipeline:

  1. ContextInterpreter  → flat context dict
  2. RuleEngine.decide   → verdict (or NoMatchingRuleError)
  3. TaxMathEngine       → VAT calculation in grosze
  4. TaxInvariantGuard   → three invariants check
  5. TigerBeetle         → double-entry transfers
  6. DecisionTraceLogger → persistent cryptographic trace
"""

from __future__ import annotations

import json
import logging
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

import duckdb

from .audit import DecisionTraceLogger
from .exceptions import NoMatchingRuleError
from .math_engine import (
    InvoicePositions,
    InvoiceSummary,
    TaxMathEngine,
    validate_invariants,
)
from .rules import RuleEngine
from CORE.context_interpreter import ContextInterpreter
from services.trace_generator import TraceGenerator
from services.pre_ledger_validator import (
    PreLedgerValidator,
    TransferSpec,
    LedgerValidationError,
)

logger = logging.getLogger("nexus.tax.pipeline")


@dataclass
class PipelineResult:
    """Result of processing a single invoice through the tax pipeline.

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


class TaxPipeline:
    """Orchestrates the complete tax processing pipeline.

    Connects layers I (rules), II (math), and III (audit) into one flow.

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
        self._rule_engine = RuleEngine(conn)
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
        tx_id = transaction_id or str(uuid.uuid4())
        context = ContextInterpreter.build(invoice_data)

        # ── Step 2: Rule Engine ──────────────────────────────────────────
        try:
            verdict = self._rule_engine.decide(context)
        except NoMatchingRuleError as exc:
            self._logger.log(
                transaction_id=tx_id,
                context=context,
                invariants_result=json.dumps({"error": str(exc)}),
            )
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                error=f"NO_MATCHING_RULE: {exc}",
            )

        # Extract verdict fields and remove internal metadata
        rule_id = verdict.pop("_rule_id", None)
        evaluated_rules = verdict.pop("_evaluated_rules", [])

        # ── Step 2b: _routing check (field confidence / RiskGuard rules) ──
        routing = verdict.pop("_routing", None)
        routing_reason = verdict.pop("_routing_reason", None)
        if routing:
            logger.warning(
                "[TAX-PIPELINE] Verdict has _routing=%s reason=%s tx_id=%s",
                routing, routing_reason, tx_id,
            )

        vat_rate = TaxMathEngine.parse_rate(verdict.get("vat_rate", "0.23"))
        rounding_level = verdict.get("rounding_level", "position")

        # Generate human-readable decision trace
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

        # ── Step 3: Tax Math Engine ──────────────────────────────────────
        raw_positions = invoice_data.get("positions", [])
        if raw_positions:
            positions_net = [
                TaxMathEngine.to_grosze(p.get("net_amount", Decimal("0")))
                for p in raw_positions
            ]
        else:
            # Single-line invoice: use amount_net directly
            positions_net = [
                TaxMathEngine.to_grosze(
                    invoice_data.get("amount_net", Decimal("0"))
                )
            ]

        total_vat_grosze, inv_positions = TaxMathEngine.calculate_positions_vat(
            positions_net, vat_rate, rounding_level
        )
        total_net_grosze = sum(positions_net)
        total_brutto_grosze = TaxMathEngine.add_tax(
            total_net_grosze, total_vat_grosze
        )

        # ── Step 4: Invariant Guard ──────────────────────────────────────
        summary = InvoiceSummary(
            netto_grosze=total_net_grosze,
            vat_grosze=total_vat_grosze,
            brutto_grosze=total_brutto_grosze,
        )

        validation = validate_invariants(inv_positions, summary)
        invariants_json = json.dumps({
            "is_valid": validation.is_valid,
            "error_message": validation.error_message,
        })

        # ── Step 5: PreLedgerValidator (przed TigerBeetle) ────────────────
        tb_ok = validation.is_valid
        pre_ledger_ok = True

        if validation.is_valid:
            transfer_specs = [
                TransferSpec(
                    debit_account_id=self._account_expense_id,
                    credit_account_id=self._account_payables_id,
                    amount_grosze=total_net_grosze,
                    transfer_type="expense",
                ),
                TransferSpec(
                    debit_account_id=self._account_vat_input_id,
                    credit_account_id=self._account_payables_id,
                    amount_grosze=total_vat_grosze,
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

        # ── Step 6: TigerBeetle (via outbox or direct) ─────────────────
        tb_result = None

        # Jeśli werdykt zawiera _routing, nie wysyłaj do TigerBeetle
        # BLOCK_AND_ALERT → blokada, TRIAGE_QUEUE → weryfikacja
        if routing:
            tb_ok = False
            if routing == "BLOCK_AND_ALERT":
                logger.warning(
                    "[TAX-PIPELINE] BLOCKED by routing=%s tid=%s reason=%s",
                    routing, tx_id, routing_reason,
                )
            else:
                logger.info(
                    "[TAX-PIPELINE] Routing=%s tid=%s reason=%s",
                    routing, tx_id, routing_reason,
                )
        elif not validation.is_valid or not pre_ledger_ok:
            # Skip TigerBeetle — invariant failure or pre-ledger check
            tb_ok = False
        elif self._write_outbox is not None and callable(self._write_outbox):
            # OUTBOX MODE: write event instead of calling TB directly
            outbox_payload = {
                "transaction_id": tx_id,
                "rule_id": rule_id or "",
                "net_grosze": total_net_grosze,
                "vat_grosze": total_vat_grosze,
                "brutto_grosze": total_brutto_grosze,
                "account_debit": "expenses",
                "account_credit": "liabilities",
                "timestamp": __import__("datetime").datetime.now(
                    __import__("datetime").timezone.utc
                ).isoformat(),
            }
            try:
                await self._write_outbox(outbox_payload)
                tb_result = {"status": "OUTBOX_ENQUEUED", "transaction_id": tx_id}
                logger.info("[TAX-OUTBOX] Enqueued tid=%s net=%d vat=%d",
                            tx_id, total_net_grosze, total_vat_grosze)
            except Exception as exc:
                tb_result = {"status": "ERROR", "error": str(exc)}
                tb_ok = False
        elif self._tigerbeetle is not None:
            # DIRECT MODE: call TigerBeetle synchronously (legacy/testing)
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

        # ── Step 7: Decision Trace Logger ────────────────────────────────
        calc_input = json.dumps({
            "positions_net_grosze": positions_net,
            "vat_rate": str(vat_rate),
            "rounding_level": rounding_level,
        })
        calc_output = json.dumps({
            "netto_grosze": total_net_grosze,
            "vat_grosze": total_vat_grosze,
            "brutto_grosze": total_brutto_grosze,
        })

        # Generate detailed trace_json with evaluated rules
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

        # ── Step 8: Result ───────────────────────────────────────────────
        # Jeśli werdykt ma _routing, zwróć informację o routingu zamiast
        # normalnego wyniku. BLOCK_AND_ALERT → błąd, TRIAGE_QUEUE → success z flagą.
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
            # TRIAGE_QUEUE, HUMAN_VERIFICATION itp. — obliczono, ale nie postowano
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

        if not validation.is_valid:
            return PipelineResult(
                success=False,
                transaction_id=tx_id,
                trace_id=trace_id,
                verdict=verdict,
                vat_grosze=total_vat_grosze,
                brutto_grosze=total_brutto_grosze,
                tigerbeetle_result=tb_result,
                error=f"INVARIANT_FAILURE: {validation.error_message}",
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
        import json
        import uuid
        from datetime import datetime, timezone

        example_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

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
                json.dumps(original_data, ensure_ascii=False, default=str),
                json.dumps(corrected_data, ensure_ascii=False, default=str),
                verified_by,
                now,
            ),
        )
        logger.info(
            "[ACTIVE-LEARNING] Recorded correction tid=%s example_id=%s by=%s",
            transaction_id, example_id, verified_by,
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

        total = self._conn.execute(
            "SELECT COUNT(*) FROM active_learning_examples"
        ).fetchone()
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
