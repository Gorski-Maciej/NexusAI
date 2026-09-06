#!/usr/bin/env python3
"""NexusAI JDG — V3-P27-I04 MDR HALLMARK SCORER V2.

Dowód wdrożenia: scoring + HUMAN REVIEW — nigdy automatyczny raport (kontrakt P22)
"""
from __future__ import annotations

from v3_p27_common import (P27_RULES, THRESHOLDS, MAIN_JDG, emit, legacy_stub_hits,
                           main_jdg_wired, now, read, rule_present,
                           stub_scan, threshold_present)

INNOVATION = "V3-P27-I04"
RULE = "jdg.v3_p27_cfc_exit_mdr.mdr_hallmark_scorer_v2"


def main() -> int:
    hay = read(P27_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p27_mdr_human_review_score"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "BLOCK_AND_ALERT" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: BLOCK_AND_ALERT (brak human approval = BLOCK)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p91"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p27_mdr_hallmark_scorer")


if __name__ == "__main__":
    raise SystemExit(main())
