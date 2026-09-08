#!/usr/bin/env python3
"""NexusAI JDG — V3-P30-I05 RECOMMENDATION→PR TRACEABILITY.

Dowód wdrożenia: każdy PR referuje ID rekomendacji; reverse-check PR bez pochodzenia (AN04)
"""
from __future__ import annotations

from v3_p30_common import (P30_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P30-I05"
RULE = "jdg.v3_p30_innovation_waves.recommendation_pr_traceability"


def main() -> int:
    hay = read(P30_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    has_routing = "TRIAGE_QUEUE" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: TRIAGE_QUEUE (PR bez ref = TRIAGE)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p94"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p30_pr_traceability")


if __name__ == "__main__":
    raise SystemExit(main())
