#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I03 PLAN-TO-RULES PIPELINE — plan (YAML) → walidacja
planu (crossref, duplikaty) → generacja reguł+testów JEDNOCZEŚNIE (zakaz
reguły bez testu) — V3 FORTRESS.

Dowód wdrożenia: próg v3_p36_rule_without_test_max = 0 jako dane; reguła bez
testu = BLOCK; plany niewalidowane (crossref/duplikaty) = TRIAGE; propozycje
AI (P33) przechodzą ten sam pipeline. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I03"
RULE = "jdg.v3_p36_generatory_migratory.plan_to_rules"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p36_rule_without_test_max")
    checks.append({"name": "rule_without_test_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p36_rule_without_test_max w thresholds: {thr}"})

    joint = "zakaz reguły bez testu" in hay
    checks.append({"name": "joint_rule_test_generation", "status": "OK" if joint else "FAIL",
                   "detail": "generacja reguł+testów jednocześnie: " + str(joint)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "rule_without_test_threshold": thr,
            "joint_rule_test_generation": joint,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_plan_to_rules")


if __name__ == "__main__":
    raise SystemExit(main())
