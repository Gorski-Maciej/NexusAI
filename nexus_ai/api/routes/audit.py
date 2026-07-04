"""
Audit explain endpoint -- kryptograficzny ślad audytowy decyzji podatkowych.

Element 2 z dokumentu: "Kryptograficzny Ślad Audytowy Decyzji (Explainable AI dla US)".

Endpointy:
- GET /api/v2/audit/tax-decision/{transaction_id}
  -> Czytelny raport JSON decyzji podatkowej dla Urzędu Skarbowego.
- GET /api/v2/audit/tax-decision/{transaction_id}?format=html
  -> Czytelny raport HTML z trace_json i context_snapshot.
"""

from __future__ import annotations

from typing import Any

import pendulum
from litestar import Controller, get
from litestar.exceptions import NotFoundException
from litestar.response import Response
from structlog import get_logger

from nexus_ai.api.dto import TAG_AUDIT, AuditDecisionReportDTO
from nexus_ai.api.rbac import requires_permission
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.api.audit")


class AuditController(Controller):
    """Audit explainability endpoints -- cryptographic decision trail."""

    path = "/api/v2/audit"
    tags = (TAG_AUDIT,)

    @get(
        "/tax-decision/{transaction_id:str}",
        guards=[requires_permission("audit:view")],
        return_dto=AuditDecisionReportDTO,
        summary="Explain tax decision",
        description="Returns a detailed audit report of a tax decision for tax authorities, including cryptographic proof and evaluation trace.",
        operation_id="explainTaxDecision",
    )
    async def explain_tax_decision(
        self,
        transaction_id: str,
        format: str = "json",
    ) -> Response:
        """Generate a report of a tax decision for tax authorities.

        Returns a JSON or HTML report containing:
          - Decision identifiers (trace_id, transaction_id, rule_id)
          - Context snapshot + trace_json (detailed evaluation trace)
          - Verdict (VAT rate, rounding method, KUP qualification, GTU code)
          - Calculations (net, VAT, gross in PLN)
          - Human-readable decision_trace
          - RiskGuard decision (did it pass automatically, why not)
          - Hash chain proof (current_hash, integrity verification status)

        Args:
            transaction_id: UUID of the invoice / transaction.
            format: Response format -- ``"json"`` (default) or ``"html"``.

        Returns:
            JSON dict or HTML string with formatted decision report.
        """
        try:
            import duckdb

            from config import AppConfig
            from nexus_ai.tax import DecisionTraceLogger, verify_chain_integrity
        except ImportError as exc:
            logger.error("Failed to import audit modules: %s", exc)
            raise NotFoundException(detail="Audit module not available") from exc

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
            trace_json_raw = trace.get("trace_json")
            decision_trace_text = trace.get("decision_trace")

            # Parse calculation amounts from JSON strings if needed
            calc_in = {}
            calc_out = {}
            inv_result = {}
            if calc_input:
                try:
                    calc_in = (
                        msgspec_loads(calc_input) if isinstance(calc_input, str) else calc_input
                    )
                except (DecodeError, TypeError):
                    calc_in = {"raw": str(calc_input)}
            if calc_output:
                try:
                    calc_out = (
                        msgspec_loads(calc_output) if isinstance(calc_output, str) else calc_output
                    )
                except (DecodeError, TypeError):
                    calc_out = {"raw": str(calc_output)}
            if invariants:
                try:
                    inv_result = (
                        msgspec_loads(invariants) if isinstance(invariants, str) else invariants
                    )
                except (DecodeError, TypeError):
                    inv_result = {"raw": str(invariants)}

            # Extract amounts from calc_in / calc_out using canonical field names
            # calc_in: {"positions_net_grosze": [12345], "vat_rate": "0.23", "rounding_level": "position"}
            # calc_out: {"netto_grosze": 12345, "vat_grosze": 2839, "brutto_grosze": 15184}
            positions_raw = calc_in.get("positions_net_grosze", [])
            net_grosze = (
                sum(positions_raw)
                if isinstance(positions_raw, list)
                else _safe_int(calc_in.get("net", 0))
            )
            vat_grosze = _safe_int(calc_out.get("vat_grosze", calc_out.get("vat", 0)))
            brutto_grosze = _safe_int(calc_out.get("brutto_grosze", calc_out.get("brutto", 0)))

            # Run integrity verification for the proof section
            integrity_issues = verify_chain_integrity(conn)
            chain_intact = len(integrity_issues) == 0
            last_verified = pendulum.now().isoformat()

            # Parse trace_json for detailed evaluation trace
            evaluated_rules = None
            trace_json_snapshot = None
            if trace_json_raw:
                try:
                    tj = (
                        msgspec_loads(trace_json_raw)
                        if isinstance(trace_json_raw, str)
                        else trace_json_raw
                    )
                    evaluated_rules = tj.get("evaluated_rules")
                    trace_json_snapshot = tj.get("context_snapshot")
                except (DecodeError, TypeError):
                    pass

            # ── Build the full report dict ──────────────────────────────
            report = _build_report_dict(
                trace=trace,
                context=context,
                verdict=verdict,
                calc_in=calc_in,
                calc_out=calc_out,
                inv_result=inv_result,
                risk_verdict=risk_verdict,
                net_grosze=net_grosze,
                vat_grosze=vat_grosze,
                brutto_grosze=brutto_grosze,
                integrity_issues=integrity_issues,
                chain_intact=chain_intact,
                last_verified=last_verified,
                trace_json_raw=trace_json_raw,
                decision_trace_text=decision_trace_text,
                evaluated_rules=evaluated_rules,
                trace_json_snapshot=trace_json_snapshot,
            )

            # ── Return in requested format ──────────────────────────────
            if format == "html":
                html_body = _render_html_report(report)
                return Response(
                    content=html_body,
                    headers={"Content-Type": "text/html; charset=utf-8"},
                    status_code=200,
                )
            return Response(
                content=report,
                headers={"Content-Type": "application/json"},
                status_code=200,
            )

        finally:
            conn.close()


# ═══════════════════════════════════════════════════════════════════════════════
# Report builders
# ═══════════════════════════════════════════════════════════════════════════════


def _build_report_dict(
    trace: dict[str, Any],
    context: dict[str, Any],
    verdict: dict[str, Any],
    calc_in: dict[str, Any],
    calc_out: dict[str, Any],
    inv_result: dict[str, Any],
    risk_verdict: Any,
    net_grosze: int,
    vat_grosze: int,
    brutto_grosze: int,
    integrity_issues: list[dict[str, Any]],
    chain_intact: bool,
    last_verified: str,
    trace_json_raw: Any,
    decision_trace_text: str | None,
    evaluated_rules: Any,
    trace_json_snapshot: Any,
) -> dict[str, Any]:
    """Build the full audit report dict."""
    return {
        "transaction_id": trace.get("transaction_id"),
        "trace_id": trace.get("trace_id"),
        "rule_id": trace.get("rule_id"),
        "timestamp": trace.get("timestamp"),
        "decision_date": _format_date(trace.get("timestamp", "")),
        # Human-readable decision trace text
        "decision_trace": decision_trace_text,
        # Context section -- readable for a tax officer
        "context": {
            "category_code": context.get("category_code", "--"),
            "company_tax_form": context.get("company_tax_form", "--"),
            "vendor_nip": context.get("vendor_nip", "--"),
            "vendor_vat_status": context.get("vendor_vat_status", "--"),
            "vendor_account_on_whitelist": context.get("vendor_account_on_whitelist", "--"),
            "vendor_trust": context.get("vendor_trust", "--"),
            "confidence_fields": context.get("fields_with_confidence", {}),
            "expense_type": context.get("expense_type", "--"),
        },
        # Context snapshot from trace_json (detailed evaluation)
        "context_snapshot": trace_json_snapshot,
        # Verdict section
        "verdict": {
            "vat_rate": verdict.get("vat_rate", "--"),
            "rounding_level": verdict.get("rounding_level", "--"),
            "income_tax_qualification": verdict.get("income_tax_qualification", "--"),
            "gtu_code": verdict.get("gtu_code", "--"),
            "procedure": verdict.get("procedure", "--"),
            "procedure_code": verdict.get("procedure_code", "--"),
            "action": verdict.get("action", "--"),
            "reason": verdict.get("reason", "--"),
        },
        # Calculations in readable PLN format
        "calculations": {
            "net_pln": f"{net_grosze / 100:.2f}" if net_grosze else "0.00",
            "net_grosze": net_grosze,
            "vat_pln": f"{vat_grosze / 100:.2f}" if vat_grosze else "0.00",
            "vat_grosze": vat_grosze,
            "brutto_pln": f"{brutto_grosze / 100:.2f}" if brutto_grosze else "0.00",
            "brutto_grosze": brutto_grosze,
            "vat_rate_raw": calc_in.get("vat_rate", "--"),
            "rounding_level_raw": calc_in.get("rounding_level", "--"),
        },
        # Detailed evaluation trace (list of evaluated rules)
        "trace_json": {
            "evaluated_rules": evaluated_rules,
            "context_snapshot": trace_json_snapshot,
            "raw": trace_json_raw,
        }
        if trace_json_raw
        else None,
        # RiskGuard decision (already parsed by get_trace)
        "risk_verdict": risk_verdict if isinstance(risk_verdict, (dict, type(None))) else None,
        # Invariant validation
        "invariant_validation": {
            "passed": inv_result.get("is_valid", inv_result.get("passed", "--")),
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


def _safe_int(val: object) -> int:
    """Safely convert a value to int, returning 0 on failure."""
    try:
        return int(val)  # int() accepts object, mypy flags as arg-type
    except (TypeError, ValueError):
        return 0


def _format_date(iso_str: str) -> str:
    """Format ISO timestamp to a human-readable date in Polish locale style."""
    try:
        dt = pendulum.parse(iso_str)
        return dt.format("DD.MM.YYYY HH:mm:ss")
    except (ValueError, TypeError):
        return iso_str or "--"


# ═══════════════════════════════════════════════════════════════════════════════
# HTML renderer
# ═══════════════════════════════════════════════════════════════════════════════


def _render_html_report(report: dict[str, Any]) -> str:
    """Render the audit report as a styled HTML page."""
    ctx = report.get("context", {})
    vrd = report.get("verdict", {})
    calc = report.get("calculations", {})
    inv = report.get("invariant_validation", {})
    intg = report.get("integrity", {})
    trace_json = report.get("trace_json", {})
    risk_v = report.get("risk_verdict", {}) or {}
    decision_trace_text = report.get("decision_trace", "")

    evaluated_rules = (trace_json or {}).get("evaluated_rules") or []
    ctx_snapshot = (trace_json or {}).get("context_snapshot", {})

    # ── Context snapshot table ──────────────────────────────────────
    context_rows = _html_table_rows(
        {
            "Kategoria wydatku": ctx.get("category_code", "--"),
            "Forma opodatkowania": ctx.get("company_tax_form", "--"),
            "NIP kontrahenta": ctx.get("vendor_nip", "--"),
            "Status VAT kontrahenta": ctx.get("vendor_vat_status", "--"),
            "Konto na Białej Liście": "TAK"
            if ctx.get("vendor_account_on_whitelist") is True
            else "NIE",
            "Zaufanie do kontrahenta": ctx.get("vendor_trust", "--"),
            "Typ wydatku": ctx.get("expense_type", "--"),
        }
    )

    if ctx_snapshot:
        for k, v in ctx_snapshot.items():
            context_rows += f"<tr><td>trace_json.{k}</td><td>{_html_escape(str(v))}</td></tr>\n"

    # ── Verdict table ───────────────────────────────────────────────
    verdict_rows = _html_table_rows(
        {
            "Stawka VAT": vrd.get("vat_rate", "--"),
            "Metoda zaokrąglania": vrd.get("rounding_level", "--"),
            "Kwalifikacja KUP": vrd.get("income_tax_qualification", "--"),
            "Kod GTU": vrd.get("gtu_code", "--"),
            "Procedura": vrd.get("procedure", vrd.get("procedure_code", "--")),
            "Akcja": vrd.get("action", "--"),
            "Routing reason": vrd.get("reason", "--"),
        }
    )

    # ── Calculations table ──────────────────────────────────────────
    calc_rows = _html_table_rows(
        {
            "Netto": f"{calc.get('net_pln', '0.00')} PLN ({calc.get('net_grosze', 0)} gr)",
            "VAT": f"{calc.get('vat_pln', '0.00')} PLN ({calc.get('vat_grosze', 0)} gr)",
            "Brutto": f"{calc.get('brutto_pln', '0.00')} PLN ({calc.get('brutto_grosze', 0)} gr)",
            "Stawka VAT (surowa)": calc.get("vat_rate_raw", "--"),
            "Poziom zaokrąglania": calc.get("rounding_level_raw", "--"),
        }
    )

    # ── Evaluated rules table ───────────────────────────────────────
    rules_rows = ""
    for r in evaluated_rules:
        rid = r.get("rule_id", "?")
        cond = _html_escape(str(r.get("condition_sql", "")))
        res = r.get("result", False)
        selected = r.get("selected", False)
        icon = "✅" if res else "❌"
        highlight = ' class="selected-rule"' if selected else ""
        rules_rows += (
            f"<tr{highlight}>"
            f"<td style='font-family:monospace;font-size:0.8em'>{rid[:12]}…</td>"
            f"<td style='font-family:monospace;font-size:0.8em'><code>{cond}</code></td>"
            f"<td>{icon}</td>"
            f"<td>{'🏆 WYGRANA' if selected else '--'}</td>"
            f"</tr>\n"
        )
    if not rules_rows:
        rules_rows = (
            "<tr><td colspan='4' style='color:#888'>Brak danych o ewaluowanych regułach</td></tr>\n"
        )

    # ── Integrity section ───────────────────────────────────────────
    integrity_color = "#27ae60" if intg.get("chain_intact") else "#e74c3c"
    integrity_label = (
        "✅ Łańcuch nienaruszony" if intg.get("chain_intact") else "❌ NARUSZENIE INTEGRALNOŚCI"
    )

    # ── Risk verdict ────────────────────────────────────────────────
    risk_rows = ""
    if isinstance(risk_v, dict) and risk_v:
        risk_rows = _html_table_rows(
            {
                "Decyzja": risk_v.get("action", risk_v.get("decision", "--")),
                "Powód": risk_v.get("reason", "--"),
                "Bezpieczna": risk_v.get("is_safe", "--"),
            }
        )
    else:
        risk_rows = "<tr><td colspan='2'>Brak danych RiskGuard</td></tr>\n"

    # ── Assembled HTML ──────────────────────────────────────────────
    return f"""<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Raport decyzji podatkowej – {_html_escape(str(report.get("transaction_id", "")))[:16]}…</title>
<style>
  * {{ margin:0; padding:0; box-sizing:border-box; }}
  body {{ font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif; background:#f5f6fa; color:#2c3e50; padding:2rem; }}
  .container {{ max-width:960px; margin:0 auto; }}
  h1 {{ font-size:1.4rem; color:#2c3e50; margin-bottom:0.25rem; }}
  h2 {{ font-size:1.1rem; color:#34495e; margin:2rem 0 0.75rem; padding-bottom:0.3rem; border-bottom:2px solid #3498db; }}
  h3 {{ font-size:1rem; color:#555; margin:1.5rem 0 0.5rem; }}
  .meta {{ font-size:0.85rem; color:#888; margin-bottom:1.5rem; }}
  table {{ width:100%; border-collapse:collapse; margin-bottom:0.5rem; background:#fff; border-radius:6px; overflow:hidden; box-shadow:0 1px 3px rgba(0,0,0,0.08); }}
  th, td {{ text-align:left; padding:0.5rem 0.75rem; border-bottom:1px solid #eee; font-size:0.9rem; }}
  th {{ background:#f8f9fa; color:#555; font-weight:600; width:30%; }}
  td {{ width:70%; }}
  .selected-rule {{ background:#eafaf1; }}
  .selected-rule td {{ font-weight:600; }}
  .integrity-bar {{ display:inline-block; padding:0.25rem 0.75rem; border-radius:4px; color:#fff; font-weight:600; font-size:0.85rem; background:{integrity_color}; }}
  .section-break {{ margin-bottom:1rem; }}
  code {{ background:#f0f0f0; padding:0.1rem 0.3rem; border-radius:3px; font-size:0.85em; }}
  .decision-trace {{ background:#fff; border-left:4px solid #3498db; padding:0.75rem 1rem; border-radius:0 6px 6px 0; margin:0.5rem 0 1rem; font-size:0.9rem; line-height:1.5; box-shadow:0 1px 3px rgba(0,0,0,0.08); }}
  .hash {{ font-family:monospace; font-size:0.75rem; color:#888; word-break:break-all; }}
  .print-btn {{ float:right; padding:0.4rem 1rem; background:#3498db; color:#fff; border:none; border-radius:4px;cursor:pointer;font-size:0.85rem; }}
  .print-btn:hover {{ background:#2980b9; }}
  @media print {{ body {{ padding:0; background:#fff; }} .print-btn {{ display:none; }} }}
</style>
</head>
<body>
<div class="container">

<button class="print-btn" onclick="window.print()">🖨️ Drukuj</button>
<h1>📋 Raport decyzji podatkowej</h1>
<p class="meta">
  Transakcja: <code>{_html_escape(str(report.get("transaction_id", "")))}</code><br>
  Ślad audytowy: <code>{_html_escape(str(report.get("trace_id", "")))}</code><br>
  ID reguły: <code>{_html_escape(str(report.get("rule_id", "--"))) if report.get("rule_id") else "--"}</code><br>
  Data decyzji: {_html_escape(str(report.get("decision_date", "")))}
</p>

<h2>🏷️ Kontekst decyzyjny</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
{context_rows}</table>

<h2>📜 Ślad decyzyjny (decision_trace)</h2>
<div class="decision-trace">{_html_escape(decision_trace_text) if decision_trace_text else "--"}</div>

<h2>⚖️ Werdykt</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
{verdict_rows}</table>

<h2>🧮 Obliczenia (w groszach)</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
{calc_rows}</table>

<h2>🔍 Ewaluacja reguł ({len(evaluated_rules)})</h2>
<table>
<tr><th>ID reguły</th><th>Warunek SQL</th><th>Pasuje?</th><th>Wybrana</th></tr>
{rules_rows}</table>

<h2>🛡️ Strażnik Ryzyka (RiskGuard)</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
{risk_rows}</table>

<h2>✅ Walidacja niezmienników</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
<tr><td>Wynik</td><td>{"✅ Przeszła" if inv.get("passed") in (True, "True", "true") else ("❌ NIE PRZESZŁA -- " + _html_escape(str(inv.get("details", {}).get("error_message", ""))))}</td></tr>
</table>

<h2>🔗 Dowód kryptograficzny</h2>
<table>
<tr><th>Pole</th><th>Wartość</th></tr>
<tr><td>Integralność łańcucha</td><td><span class="integrity-bar">{integrity_label}</span></td></tr>
<tr><td>Poprzedni hash</td><td class="hash">{intg.get("previous_hash", "--")}</td></tr>
<tr><td>Bieżący hash</td><td class="hash">{intg.get("current_hash", "--")}</td></tr>
<tr><td>Liczba naruszeń</td><td>{intg.get("issues_count", 0)}</td></tr>
<tr><td>Ostatnia weryfikacja</td><td>{intg.get("last_verified", "--")}</td></tr>
</table>

<p class="meta" style="margin-top:2rem; text-align:center;">
  Wygenerowano przez NexusAI Audit System • {pendulum.now().format("DD.MM.YYYY HH:mm:ss")}
</p>

</div>
</body>
</html>"""


def _html_table_rows(data: dict[str, Any]) -> str:
    """Build HTML table rows from a key-value dict."""
    rows = []
    for key, val in data.items():
        display = _html_escape(str(val)) if val is not None else "--"
        rows.append(f"<tr><td>{_html_escape(str(key))}</td><td>{display}</td></tr>\n")
    return "".join(rows)


def _html_escape(text: str) -> str:
    """Escape HTML special characters."""
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&#x27;")
    )
