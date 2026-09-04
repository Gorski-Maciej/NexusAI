#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I09 RELIEF EXPIRY SENTINEL.

Alarmy wygasania ulg czasowych: PIT-0 (wiek 26 lat — ulga młodych; powrót do
pracy — 4 lata art. 21 ust. 1 pkt 152), robotyzacja (okno inwestycyjne
art. 26gb — do 2026). Alert z wyprzedzeniem (months_left <= alert_window)
→ TRIAGE_QUEUE; monitoring okien z data.thresholds.pit (ADR-002).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P14-I09"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.relief_expiry_sentinel", hay)
    has_young = "young_relief_max_age" in hay and "young_relief_months_left" in hay
    has_return = "return_work_window_years" in hay and "return_work_months_left" in hay
    has_robot = "robotization_window_alert" in hay and "robotization_last_year" in hay
    missing = thresholds_missing(["young_relief_max_age", "return_work_relief_years",
                                  "robotization_relief_last_year", "relief_expiry_alert_months"])

    checks.append({"name": "sentinel_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła relief_expiry_sentinel: {has_rule}"})
    checks.append({"name": "young_age_26", "status": "OK" if has_young else "FAIL",
                   "detail": "granica wieku 26 lat (ulga młodych, pkt 148)"})
    checks.append({"name": "return_4yr", "status": "OK" if has_return else "FAIL",
                   "detail": "okno 4 lat powrotu do pracy (pkt 152)"})
    checks.append({"name": "robotization_window", "status": "OK" if has_robot else "FAIL",
                   "detail": "okno inwestycyjne robotyzacji (26gb — do 2026)"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów okien: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P14-L09", "severity": "P2",
                         "evidence": f"brak parametrów okien czasowych: {missing}",
                         "fix": "I09: dodać okna do data.thresholds.pit + alert z wyprzedzeniem"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "young": has_young, "return": has_return,
                    "robotization": has_robot, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P36 (kalendarz), P37 (obserwowalność)",
                     "rule": "sentinel wygasania ulg czasowych (wiek 26, powrót 4 lata, robotyzacja 2026)"}}
    return emit(bundle, "v3_p14_expiry_sentinel")


if __name__ == "__main__":
    raise SystemExit(main())
