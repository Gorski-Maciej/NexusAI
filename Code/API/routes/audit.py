"""
Audit explain endpoint — kryptograficzny ślad audytowy decyzji podatkowych.

Element 2 z dokumentu: "Kryptograficzny Ślad Audytowy Decyzji (Explainable AI dla US)".

Endpoint:
- GET /api/v2/audit/tax-decision/{transaction_id}
  → Czytelny raport decyzji podatkowej dla Urzędu Skarbowego.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime

from litestar import Controller, get
from litestar.exceptions import NotFoundException
from litestar.response import Response

from api.rbac import requires_permission

logger = logging.getLogger("nexus.api.audit")


class AuditController(Controller):
    """Audit explainability endpoints — cryptographic decision trail."""

    path = "/api/v2/audit"

    @get("/tax-decision/{transaction_id:str}", guards=[requires_permission("audit:view")])
    async def explain_tax_decision(self, transaction_id: str) -> dict:
        """Generate a human-readable report of a tax decision for tax authorities.

        Returns a JSON report containing:
          - Decision identifiers (trace_id, transaction_id, rule_id)
          - Context snapshot (date, category, tax form, white list status, AI confidence)
          - Verdict (VAT rate, rounding method, KUP qualification, GTU code)
          - Calculations (net, VAT, gross in PLN)
          - RiskGuard decision (did it pass automatically, why not)
          - Hash chain proof (current_hash, integrity verification status)

        Args:
            transaction_id: UUID of the invoice / transaction.

        Returns:
            dict with formatted decision report.
        """
        try:
            import duckdb
            from config import AppConfig
            from tax.audit import DecisionTraceLogger, verify_chain_integrity
        except ImportError as exc:
            logger.error("Failed to import audit modules: %s", exc)
            raise NotFoundException(
                detail="Audit module not available"
            ) from exc

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            trace_logger = DecisionTraceLogger(conn)
            traces = trace_logger.get_trace(transaction_id)

            if not traces:
                raise NotFoundException(
                    detail=f"No decision traces found for transaction: {transaction_id}"
                )

            # Build the explain report from the most recent trace
            trace = traces[-1]  # newest entry

            context = trace.get("context") or {}
            verdict = trace.get("verdict") or {}
            risk_verdict = trace.get("risk_verdict")
            calc_input = trace.get("calculation_input")
            calc_output = trace.get("calculation_output")
            invariants = trace.get("invariants_result")

            # Parse calculation amounts from JSON strings if needed
            calc_in = {}
            calc_out = {}
            inv_result = {}
            if calc_input:
                try:
                    calc_in = json.loads(calc_input) if isinstance(calc_input, str) else calc_input
                except (json.JSONDecodeError, TypeError):
                    calc_in = {"raw": str(calc_input)}
            if calc_output:
                try:
                    calc_out = json.loads(calc_output) if isinstance(calc_output, str) else calc_output
                except (json.JSONDecodeError, TypeError):
                    calc_out = {"raw": str(calc_output)}
            if invariants:
                try:
                    inv_result = json.loads(invariants) if isinstance(invariants, str) else invariants
                except (json.JSONDecodeError, TypeError):
                    inv_result = {"raw": str(invariants)}

            # Format amounts in PLN
            net_grosze = calc_in.get("net", 0) or 0
            vat_grosze = _safe_int(calc_out.get("vat", 0))
            brutto_grosze = _safe_int(calc_out.get("brutto", 0))

            # Run integrity verification for the proof section
            integrity_issues = verify_chain_integrity(conn)
            chain_intact = len(integrity_issues) == 0
            last_verified = datetime.now().isoformat()

            report = {
                "transaction_id": trace.get("transaction_id"),
                "trace_id": trace.get("trace_id"),
                "rule_id": trace.get("rule_id"),
                "timestamp": trace.get("timestamp"),
                "decision_date": _format_date(trace.get("timestamp", "")),
                # Context section — readable for a tax officer
                "context": {
                    "category_code": context.get("category_code", "—"),
                    "company_tax_form": context.get("company_tax_form", "—"),
                    "vendor_nip": context.get("vendor_nip", "—"),
                    "vendor_vat_status": context.get("vendor_vat_status", "—"),
                    "vendor_account_on_whitelist": context.get("vendor_account_on_whitelist", "—"),
                    "vendor_trust": context.get("vendor_trust", "—"),
                    "confidence_fields": context.get("fields_with_confidence", {}),
                    "expense_type": context.get("expense_type", "—"),
                },
                # Verdict section
                "verdict": {
                    "vat_rate": verdict.get("vat_rate", "—"),
                    "rounding_level": verdict.get("rounding_level", "—"),
                    "kup_qualification": verdict.get("kup_qualification", "—"),
                    "gtu_code": verdict.get("gtu_code", "—"),
                    "procedure_code": verdict.get("procedure_code", "—"),
                    "action": verdict.get("action", "—"),
                    "reason": verdict.get("reason", "—"),
                },
                # Calculations in readable PLN format
                "calculations": {
                    "net_pln": f"{net_grosze / 100:.2f}" if net_grosze else "—",
                    "net_grosze": net_grosze,
                    "vat_pln": f"{vat_grosze / 100:.2f}" if vat_grosze else "—",
                    "vat_grosze": vat_grosze,
                    "brutto_pln": f"{brutto_grosze / 100:.2f}" if brutto_grosze else "—",
                    "brutto_grosze": brutto_grosze,
                },
                # RiskGuard decision (already parsed by get_trace)
                "risk_verdict": risk_verdict if isinstance(risk_verdict, (dict, type(None))) else None,
                # Invariant validation
                "invariant_validation": {
                    "passed": inv_result.get("is_valid", inv_result.get("passed", "—")),
                    "details": inv_result,
                },
                # Cryptographic proof
                "integrity": {
                    "previous_hash": trace.get("previous_hash"),
                    "current_hash": trace.get("current_hash"),
                    "chain_intact": chain_intact,
                    "last_verified": last_verified,
                    "issues_count": len(integrity_issues),
                    "issues": integrity_issues if integrity_issues else None,
                },
            }

            return report

        finally:
            conn.close()


def _safe_int(val: object) -> int:
    """Safely convert a value to int, returning 0 on failure."""
    try:
        return int(val)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return 0


def _format_date(iso_str: str) -> str:
    """Format ISO timestamp to a human-readable date in Polish locale style."""
    try:
        dt = datetime.fromisoformat(iso_str)
        return dt.strftime("%d.%m.%Y %H:%M:%S")
    except (ValueError, TypeError):
        return iso_str or "—"
