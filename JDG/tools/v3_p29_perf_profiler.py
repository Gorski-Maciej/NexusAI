#!/usr/bin/env python3
"""NexusAI JDG — V3-P29-I05 GATE PERFORMANCE PROFILER.

Dowód wdrożenia: czas wykonania bramek; dryf >50% = TRIAGE — sygnał degradacji repo (AN02)
"""
from __future__ import annotations

from v3_p29_common import (P29_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P29-I05"
RULE = "jdg.v3_p29_quality_campaigns.gate_performance_profiler"


def main() -> int:
    hay = read(P29_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p29_max_gate_seconds", "v3_p29_perf_drift_pct"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "TRIAGE_QUEUE" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: TRIAGE_QUEUE (dryf/limit = TRIAGE)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p93"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p29_perf_profiler")


if __name__ == "__main__":
    raise SystemExit(main())
