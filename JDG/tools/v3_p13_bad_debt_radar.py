#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I03 BAD DEBT RADAR (art. 89a/89b VAT).

Monitoring 90 dni od terminu płatności: alert + automatyczna korekta in minus
(days_overdue >= 90 + debtor_notified). Brak potwierdzenia zawiadomienia =
NEEDS_ADVICE (fail-closed). Dowód: reguła bad_debt_radar + parametr bad_debt_days.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I03"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.bad_debt_radar", hay)
    has_90d = "days_overdue" in hay and "bad_debt_days" in hay
    has_auto = "auto_in_minus_correction" in hay and "debtor_notified" in hay
    has_fail_closed = "debtor_notified" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["bad_debt_days"])

    checks.append({"name": "radar_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła bad_debt_radar: {has_rule}"})
    checks.append({"name": "90_days", "status": "OK" if has_90d else "FAIL",
                   "detail": "monitoring 90 dni (art. 89a/89b) w regułach"})
    checks.append({"name": "auto_in_minus", "status": "OK" if has_auto else "FAIL",
                   "detail": "automatyczna korekta in minus + zawiadomienie dłużnika"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "brak zawiadomienia → NEEDS_ADVICE"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów bad_debt_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L05", "severity": "P3",
                         "evidence": f"brak parametrów złych długów: {missing}",
                         "fix": "I03: monitoring 90 dni + korekta in minus + testy krańcowe 90 dni"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"radar_rule": has_rule, "days90": has_90d, "auto": has_auto,
                    "fail_closed": has_fail_closed, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P10 (golden), P39 (bramki CI), P16 (JPK korekty)",
                     "rule": "złe długi art. 89a/89b: 90 dni + zawiadomienie → korekta in minus"}}
    return emit(bundle, "v3_p13_bad_debt_radar")


if __name__ == "__main__":
    raise SystemExit(main())