#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I07 FRAUD SIGNAL FRAMEWORK (art. 105a-105c VAT).

Graf transakcji → sygnały (puste faktury, karuzele, shell company, MTIC) →
human review WYMUSZONY (nigdy automatyczna wina). Scoring 0-100 wpływa na
certainty_class (kontrakt V3-P03). Dowód: reguła fraud_signal_framework +
parametry fraud_* w thresholds.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I07"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.fraud_signal_framework", hay)
    has_signals = "empty_invoice_signal" in hay and "carousel_signal" in hay and "is_fraud_graph_match" in hay
    has_human_review = "human_review_required" in hay and "never_auto_conviction" in hay
    has_routing = "MANUAL_REVIEW" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["fraud_score_high", "fraud_score_medium", "fraud_human_review_required"])

    checks.append({"name": "fraud_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła fraud_signal_framework: {has_rule}"})
    checks.append({"name": "graph_signals", "status": "OK" if has_signals else "FAIL",
                   "detail": "sygnały grafu (puste faktury, karuzele, MTIC, graph match)"})
    checks.append({"name": "human_review", "status": "OK" if has_human_review else "FAIL",
                   "detail": "human review WYMUSZONY — nigdy automatyczna wina"})
    checks.append({"name": "fail_closed_routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "scoring HIGH/MEDIUM → MANUAL_REVIEW/NEEDS_ADVICE"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów fraud_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L09", "severity": "P2",
                         "evidence": f"brak parametrów fraud scoring: {missing}",
                         "fix": "I07: sygnały + human review + integracja z fraud detection (scoring 0-100)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"fraud_rule": has_rule, "signals": has_signals,
                    "human_review": has_human_review, "routing": has_routing,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (werdykt), P05 (temporalność), P10 (golden), P39 (bramki CI), P36 (procesy), P41 (UI review)",
                     "rule": "fraud = SYGNAŁ z human review (nigdy wina); scoring wpływa na certainty_class (P03)"}}
    return emit(bundle, "v3_p13_fraud_signal_framework")


if __name__ == "__main__":
    raise SystemExit(main())