#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I01 HEALTH TIER AS DATA — kryteria tierów (testy,
legal basis, dryf, wiek) jako dane; engine oblicza, CI wymusza.
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p42_common import (HEALTH_TIER_ENGINE, HEALTH_TIER_RECALC, RULES,
                           SYSTEM_REGISTER, emit, main_jdg_wired, now,
                           read_json, rule_present)

INNOVATION = "V3-P42-I01"
RULE = "jdg.v3_p42_enterprise_reszta.health_tier"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    engine_ok = HEALTH_TIER_ENGINE.exists() and HEALTH_TIER_RECALC.exists()
    checks.append({"name": "engine_and_recalculator_exist", "status": "OK" if engine_ok else "FAIL",
                   "detail": f"health_tier_engine.py + health_tier_recalculator.py: {engine_ok}"})

    # Kryteria tierów jako data (nie fasada): rejestr systemowy definiuje kryteria
    reg = read_json(SYSTEM_REGISTER)
    tiers = reg.get("health_tiers", {}) if isinstance(reg, dict) else {}
    criteria = tiers.get("criteria", [])
    required = ["tests_passing", "legal_basis_verified", "drift_free", "not_stale"]
    criteria_ok = all(c in criteria for c in required)
    checks.append({"name": "tier_criteria_as_data", "status": "OK" if criteria_ok else "FAIL",
                   "detail": f"kryteria tierów w rejestrze: {criteria} (wymagane: {required})"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "engine_and_recalculator_exist": engine_ok,
            "tier_criteria_as_data": criteria_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_health_tier")


if __name__ == "__main__":
    raise SystemExit(main())
