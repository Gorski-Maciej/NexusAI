#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I08 SANDBOX CI RIG (cotygodniowy test sandbox MF).

Dowód wdrożenia: reguła sandbox_ci_rig + parametr cadence 7 dni; brak testu
w cyklu = TRIAGE_QUEUE; raport z trendem awaryjności (P16-AN09).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I08"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.sandbox_ci_rig", hay)
    has_cadence = "cadence_days" in hay and "days_since_last_test" in hay
    has_trend = "failure_trend_pct" in hay
    has_overdue = "overdue" in hay
    missing = thresholds_missing(["v3_p16_sandbox_cadence_days"])

    checks.append({"name": "sandbox_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła sandbox_ci_rig: {has_rule}"})
    checks.append({"name": "cadence", "status": "OK" if has_cadence else "FAIL",
                   "detail": "cykl cotygodniowy (7 dni) jako dane"})
    checks.append({"name": "trend_report", "status": "OK" if has_trend else "FAIL",
                   "detail": "raport z trendem awaryjności"})
    checks.append({"name": "overdue_triage", "status": "OK" if has_overdue else "FAIL",
                   "detail": "test poza cyklem → TRIAGE_QUEUE"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_trend:
        findings.append({"id": "V3-P16-L08", "severity": "P2",
                         "evidence": "sandbox CI bez trendu awaryjności",
                         "fix": "I08: cotygodniowy raport sandboxa z trendami"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "cadence": has_cadence, "trend": has_trend,
                    "overdue": has_overdue, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (bramki CI), ksef_sandbox_harness (MF sandbox), P16-AN09",
                     "rule": "cotygodniowy sandbox CI z raportem i trendami"}}
    return emit(bundle, "v3_p16_sandbox_ci_rig")


if __name__ == "__main__":
    raise SystemExit(main())
