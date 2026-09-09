#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I12 ENTERPRISE MATURITY LADDER — skala L0–L5
z kryteriami testowalnymi; P44 certyfikuje poziom, nie deklarację.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p42_common import SYSTEM_REGISTER, emit, main_jdg_wired, now, read_json, rule_present, threshold_present

INNOVATION = "V3-P42-I12"
RULE = "jdg.v3_p42_enterprise_reszta.maturity_ladder"
LEVELS = ["L0_initial", "L1_repeatable", "L2_defined", "L3_managed", "L4_quantified", "L5_optimizing"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SYSTEM_REGISTER)
    ml = reg.get("maturity_ladder", {}) if isinstance(reg, dict) else {}
    levels = ml.get("levels", [])
    levels_ok = levels == LEVELS
    checks.append({"name": "ladder_levels_complete", "status": "OK" if levels_ok else "FAIL",
                   "detail": f"poziomy w rejestrze: {levels}"})

    # Każdy poziom ma kryteria testowalne (nie deklaracje)
    criteria = ml.get("criteria_per_level", {}) if isinstance(ml, dict) else {}
    criteria_ok = all(isinstance(criteria.get(l), list) and len(criteria.get(l, [])) >= 1
                      for l in LEVELS)
    checks.append({"name": "criteria_testable_per_level", "status": "OK" if criteria_ok else "FAIL",
                   "detail": f"kryteria testowalne dla każdego poziomu: {criteria_ok}"})

    t = threshold_present("v3_p42_maturity_level_max")
    checks.append({"name": "level_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p42_maturity_level_max w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "ladder_levels_complete": levels_ok,
            "criteria_testable_per_level": criteria_ok,
            "level_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_maturity_ladder")


if __name__ == "__main__":
    raise SystemExit(main())
