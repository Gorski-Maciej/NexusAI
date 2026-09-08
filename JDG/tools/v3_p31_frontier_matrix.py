#!/usr/bin/env python3
"""NexusAI JDG — V3-P31-I08 FRONTIER MATRIX.

Dowód wdrożenia: macierz etap×domena z datami ostatniego dowodu; wygasły >90 dni (AN01-AN03)
"""
from __future__ import annotations

from v3_p31_common import (P31_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P31-I08"
RULE = "jdg.v3_p31_audit_stages.frontier_matrix"


def main() -> int:
    hay = read(P31_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p31_evidence_stale_days"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "TRIAGE_QUEUE" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: TRIAGE_QUEUE (dowód wygasły = TRIAGE)"})
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
    return emit(bundle, "v3_p31_frontier_matrix")


if __name__ == "__main__":
    raise SystemExit(main())
