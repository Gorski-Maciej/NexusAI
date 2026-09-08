#!/usr/bin/env python3
"""NexusAI JDG — V3-P30-I04 V4 SELECTION CONTRACT.

Dowód wdrożenia: scoring rekomendacji: wpływ na AUTO_POST, koszt, ryzyko prawne (AN04)
"""
from __future__ import annotations

from v3_p30_common import (P30_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P30-I04"
RULE = "jdg.v3_p30_innovation_waves.v4_selection_contract"


def main() -> int:
    hay = read(P30_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p30_v4_high_roi_min"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "TRIAGE_QUEUE" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: TRIAGE_QUEUE (brak scoringu = TRIAGE)"})
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
    return emit(bundle, "v3_p30_v4_selection")


if __name__ == "__main__":
    raise SystemExit(main())
