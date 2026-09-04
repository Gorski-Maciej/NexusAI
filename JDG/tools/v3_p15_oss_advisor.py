#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I09 OSS DECISION ADVISOR (art. 28k-28m VAT).

Decyzja: czy JDG powinien być na OSS (progi sprzedaży wysyłkowej B2C, korzyści)
z symulatorem; rekomendacja SUGGEST — decyzja człowieka. Dowód: reguła
oss_decision_advisor + parametry oss_* w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I09"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.oss_decision_advisor", hay)
    has_suggest = "SUGGEST" in hay and "no_auto_post" in hay
    missing = thresholds_missing(["oss_distance_selling_threshold_eur", "oss_annual_threshold_eur"])

    checks.append({"name": "oss_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła oss_decision_advisor: {has_rule}"})
    checks.append({"name": "suggest_no_auto", "status": "OK" if has_suggest else "FAIL",
                   "detail": "rekomendacja SUGGEST + no_auto_post (decyzja człowieka)"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów oss_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P15-L10", "severity": "P2",
                         "evidence": f"brak parametrów progów OSS: {missing}",
                         "fix": "I09: progi OSS jako dane (ADR-002); symulator korzyści"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"oss_rule": has_rule, "suggest": has_suggest, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P12 (stawki), P44",
                     "rule": "OSS = rekomendacja SUGGEST z symulatorem; nigdy automatyczna rejestracja"}}
    return emit(bundle, "v3_p15_oss_advisor")


if __name__ == "__main__":
    raise SystemExit(main())