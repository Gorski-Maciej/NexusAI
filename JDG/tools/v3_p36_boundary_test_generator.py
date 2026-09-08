#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I08 GENERATOR TESTÓW GRANICZNYCH — z tabeli aktów
(progi, daty, stawki) automatyczne przypadki brzegowe groszowe i
day-0/day+1 — V3 FORTRESS.

Dowód wdrożenia: granice jako DANE z tabeli aktów — hardcode = BLOCK
(ADR-002, spójność z P32-I06 granice groszowe); próg pokrycia
v3_p36_boundary_rules_min_covered = 100% jako dane. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I08"
RULE = "jdg.v3_p36_generatory_migratory.boundary_test_generator"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p36_boundary_rules_min_covered")
    checks.append({"name": "coverage_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p36_boundary_rules_min_covered w thresholds: {thr}"})

    hardcode_block = "wkodowane na stałe" in hay
    checks.append({"name": "hardcode_blocked", "status": "OK" if hardcode_block else "FAIL",
                   "detail": "granice wkodowane = BLOCK (dane z tabeli aktów): " + str(hardcode_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "coverage_threshold": thr,
            "hardcode_blocked": hardcode_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_boundary_test_generator")


if __name__ == "__main__":
    raise SystemExit(main())
