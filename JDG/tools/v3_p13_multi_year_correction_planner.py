#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I02 MULTI-YEAR CORRECTION PLANNER (art. 91 VAT).

Harmonogram korekt wieloletnich: nieruchomości 10 lat, inne środki trwałe 5 lat,
< 15 000 zł — 1 rok; automatyczne korekty roczne (IN_PLUS/IN_MINUS) + testy
krańcowe lat 5/10. Dowód: reguła multi_year_correction_planner + parametry
multi_year_* + asset_correction_threshold w thresholds.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I02"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.multi_year_correction_planner", hay)
    has_schedule = "multi_year_years_real_estate" in hay and "multi_year_years_other" in hay
    has_annual = "annual_correction_pct" in hay and "adjustment_direction" in hay
    has_fail_closed = "NEEDS_ADVICE" in hay and "within_schedule" in hay
    missing = thresholds_missing(["multi_year_years_real_estate", "multi_year_years_other",
                                  "multi_year_years_low_value", "asset_correction_threshold"])

    checks.append({"name": "planner_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła multi_year_correction_planner: {has_rule}"})
    checks.append({"name": "schedule_5_10_years", "status": "OK" if has_schedule else "FAIL",
                   "detail": "harmonogram 5/10/1 lat (art. 91) w regułach"})
    checks.append({"name": "annual_correction", "status": "OK" if has_annual else "FAIL",
                   "detail": "korekty roczne IN_PLUS/IN_MINUS + % roczny"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "rok poza harmonogramem → NEEDS_ADVICE"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów multi_year_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L04", "severity": "P2",
                         "evidence": f"brak parametrów harmonogramu korekt: {missing}",
                         "fix": "I02: harmonogram art. 91 (5/10 lat) z korektami rocznymi; testy krańcowe lat 5/10"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"planner_rule": has_rule, "schedule": has_schedule,
                    "annual": has_annual, "fail_closed": has_fail_closed,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P10 (golden), P39 (bramki CI), P16 (JPK korekty)",
                     "rule": "harmonogram korekt wieloletnich art. 91 (10/5/1 lat) z korektą roczną"}}
    return emit(bundle, "v3_p13_multi_year_correction_planner")


if __name__ == "__main__":
    raise SystemExit(main())