#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I01 DEDUCTION RIGHTS ENGINE (art. 86-88 VAT).

Pełny silnik art. 86: warunki → moment (art. 86b: miesiąc/3 miesiące,
prefinansowanie) → ograniczenia (art. 88: kategorie zablokowane + auta
50%/0%/użycie mieszane) z datami. Dowód: reguła deduction_rights_engine +
parametry deduction_*/blocked_* w thresholds + fail-closed (BLOCK/NEEDS_ADVICE).
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I01"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.deduction_rights_engine", hay)
    has_moment = "deduction_moment_months" in hay and "prefinancing" in hay
    has_car = "car_vat_deduction_no_log" in hay and "mixed_use" in hay
    has_fail_closed = "BLOCK_AND_ALERT" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["deduction_moment_months", "deduction_prefinancing_months",
                                  "blocked_deduction_categories"])

    checks.append({"name": "rights_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła deduction_rights_engine: {has_rule}"})
    checks.append({"name": "moment_art86b", "status": "OK" if has_moment else "FAIL",
                   "detail": "moment odliczenia (3 miesiące, prefinansowanie) w regułach"})
    checks.append({"name": "car_art88", "status": "OK" if has_car else "FAIL",
                   "detail": "auta art. 88 (50%/100%, użycie mieszane) w regułach"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "routing BLOCK_AND_ALERT/NEEDS_ADVICE obecny"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów deduction_*/blocked_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L01", "severity": "P2",
                         "evidence": f"brak parametrów momentu odliczenia: {missing}",
                         "fix": "I01: parametry do thresholds; testy momentu (3 miesiące, prefinansowanie)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rights_rule": has_rule, "moment": has_moment, "car": has_car,
                    "fail_closed": has_fail_closed, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry-as-data), P05 (temporalność), P10 (golden), P39 (bramki CI)",
                     "rule": "prawo do odliczenia (art. 86) + moment (art. 86b) + ograniczenia (art. 88, auta 50%)"}}
    return emit(bundle, "v3_p13_deduction_rights_engine")


if __name__ == "__main__":
    raise SystemExit(main())