#!/usr/bin/env python3
"""NexusAI JDG — V3-P31-I09 CONFLICT RESOLUTION PROCEDURE.

Dowód wdrożenia: najnowszy dowód wygrywa; stara deklaracja do rejestru mediacji z reason (AN04)
"""
from __future__ import annotations

from v3_p31_common import (P31_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P31-I09"
RULE = "jdg.v3_p31_audit_stages.conflict_resolution"


def main() -> int:
    hay = read(P31_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    has_routing = "TRIAGE_QUEUE" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: TRIAGE_QUEUE (mediacja bez reason = TRIAGE)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p95"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p31_conflict_resolution")


if __name__ == "__main__":
    raise SystemExit(main())
