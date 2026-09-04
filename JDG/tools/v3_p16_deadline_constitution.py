#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I05 DEADLINE CONSTITUTION (terminy jako konstytucja).

Dowód wdrożenia: reguła deadline_constitution + kalendarz terminów jako dane
(v3_p16_deadlines: VAT 25./JPK 25./PIT 30.04/ZUS 20.) z invariantem
(termin minął i brak deklaracji = alarm) i przeniesieniami weekendowymi.
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, THRESHOLDS, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I05"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    thay = read(THRESHOLDS)
    has_rule = rule_present("jdg.v3_p16_ksef_jpk.deadline_constitution", hay)
    has_calendar = '"v3_p16_deadlines"' in thay and '"vat7_day"' in thay and '"pit36_deadline"' in thay
    has_overdue = "overdue" in hay and "NIEZŁOŻONA" in hay
    has_shift = "shifted_to" in hay and "weekend_shift" in hay
    has_alert = "alert_days_before" in thay
    missing = thresholds_missing(["v3_p16_deadlines"])

    checks.append({"name": "deadline_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła deadline_constitution: {has_rule}"})
    checks.append({"name": "calendar_as_data", "status": "OK" if has_calendar else "FAIL",
                   "detail": "kalendarz terminów jako dane (ADR-002)"})
    checks.append({"name": "overdue_alarm", "status": "OK" if has_overdue else "FAIL",
                   "detail": "invariant: brak deklaracji po terminie = alarm"})
    checks.append({"name": "weekend_shift", "status": "OK" if has_shift else "FAIL",
                   "detail": "przeniesienia weekendowe/świąteczne (shifted_to)"})
    checks.append({"name": "n_day_alert", "status": "OK" if has_alert else "FAIL",
                   "detail": "alert N-dni przed terminem"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_calendar:
        findings.append({"id": "V3-P16-L05", "severity": "P1",
                         "evidence": "terminy bez kalendarza-as-danych",
                         "fix": "I05: kalendarz terminów jako konstytucja (dane + invarianty)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "calendar": has_calendar, "overdue": has_overdue,
                    "shift": has_shift, "alert": has_alert, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (kalendarz), P05 (temporalność), V3_P04 (invarianty)",
                     "rule": "terminy fiskalne jako konstytucja z invariantami"}}
    return emit(bundle, "v3_p16_deadline_constitution")


if __name__ == "__main__":
    raise SystemExit(main())
