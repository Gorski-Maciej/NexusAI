#!/usr/bin/env python3
"""NexusAI JDG — V3-P28-I09 HYPER INVARIANTS PACK.

Dowód wdrożenia: INV-H01 sanctions human-only / INV-H02 FM kalendarz-only / INV-H03 fx jednolity / INV-H04 zero AUTO_POST (P04)
"""
from __future__ import annotations

from v3_p28_common import (P28_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P28-I09"
RULE = "jdg.v3_p28_hyper_plan45.hyper_invariants_pack"


def main() -> int:
    hay = read(P28_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p28_invariants_active", "v3_p28_sanctions_human_only", "v3_p28_fm_calendar_only", "v3_p28_fx_single_engine", "v3_p28_hyper_no_silent_auto_post"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "BLOCK_AND_ALERT" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: BLOCK_AND_ALERT (naruszenie = BLOCK)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p92"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p28_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
