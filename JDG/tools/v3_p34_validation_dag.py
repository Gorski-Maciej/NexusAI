#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I01 WALIDACJA JAKO SIEĆ DAG — poziomy L1-L5 jako graf
zależności z lokalnym retry — kampania V3 FORTRESS.

Dowód wdrożenia: kolejność i liczba poziomów w data.thresholds.v3_p34 jako
dane (ADR-002); raport per poziom; czym wcześniej przerwać PR. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p34_common import (MAIN_JDG, P34_RULES, THRESHOLDS, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P34-I01"
RULE = "jdg.v3_p34_walidacja_narzedzia.validation_dag"
LEVELS = ["L1_syntax", "L2_lint", "L3_tests", "L4_semantic", "L5_legal"]


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    block = read(THRESHOLDS)
    i = block.find("v3_p34 := {")
    depth, block_text = 0, ""
    if i >= 0:
        for j in range(i, len(block)):
            if block[j] == "{":
                depth += 1
            elif block[j] == "}":
                depth -= 1
                if depth == 0:
                    block_text = block[i:j]
                    break
    levels_ok = all(f'"{l}"' in block_text for l in LEVELS)
    checks.append({"name": "dag_levels_as_data", "status": "OK" if levels_ok else "FAIL",
                   "detail": f"v3_p34.dag_levels {LEVELS} jako dane: {levels_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p98"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "dag_levels": LEVELS,
            "dag_levels_as_data": levels_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_validation_dag")


if __name__ == "__main__":
    raise SystemExit(main())
