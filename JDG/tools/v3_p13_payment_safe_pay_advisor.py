#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I12 PAYMENT SAFE-PAY ADVISOR (art. 96b/108a VAT).

Doradca płatności: kontrahent (counterparty_risk_score) + MPP (obowiązek +
użycie) + Biała Lista (status) → „bezpiecznie zapłać tak” (SUGGEST) lub
NEEDS_ADVICE. Nigdy automatyczny nakaz płatności. Dowód: reguła
payment_safe_pay_advisor.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, emit

INNOVATION = "V3-P13-I12"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.payment_safe_pay_advisor", hay)
    has_triple = "counterparty_risk_score" in hay and "counterparty_on_whitelist" in hay and "mpp_required" in hay
    has_verdict = "BEZPIECZNIE_ZAPŁAĆ_TAK" in hay and "safe_to_pay" in hay
    has_suggest = "SUGGEST" in hay and "NEEDS_ADVICE" in hay

    checks.append({"name": "safe_pay_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła payment_safe_pay_advisor: {has_rule}"})
    checks.append({"name": "triple_evidence", "status": "OK" if has_triple else "FAIL",
                   "detail": "kontrahent + MPP + Biała Lista (pełny łańcuch dowodów)"})
    checks.append({"name": "verdict", "status": "OK" if has_verdict else "FAIL",
                   "detail": "„bezpiecznie zapłać tak” / NEEDS_ADVICE"})
    checks.append({"name": "suggest_no_auto", "status": "OK" if has_suggest else "FAIL",
                   "detail": "SUGGEST/no_auto_post — nigdy automatyczny nakaz płatności"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"safe_pay_rule": has_rule, "triple": has_triple,
                    "verdict": has_verdict, "suggest": has_suggest},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (werdykt), P10 (golden), P39 (bramki CI), P41 (UI review), P13 (cross-border)",
                     "rule": "doradca płatności: kontrahent + MPP + Biała Lista → bezpiecznie zapłać (SUGGEST)"}}
    return emit(bundle, "v3_p13_payment_safe_pay_advisor")


if __name__ == "__main__":
    raise SystemExit(main())