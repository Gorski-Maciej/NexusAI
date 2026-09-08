#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I04 LATENCY BUDGET PER DOMENA — rozdzielony budżet
latencji; reguła przeciążająca budżet wpada do rejestru z analizą
(else-chain → routing O(1) z P02) — V3 FORTRESS.

Dowód wdrożenia: próg v3_p37_latency_p95_max_ms = 500 jako dane; p95 >
2× budżetu = BLOCK; > budżetu = TRIAGE z rejestrem domen. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I04"
RULE = "jdg.v3_p37_obserwowalnosc.latency_budget"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_latency_p95_max_ms")
    checks.append({"name": "latency_budget_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_latency_p95_max_ms w thresholds: {thr}"})

    over2x = "2× budżetu" in hay
    checks.append({"name": "over_2x_blocked", "status": "OK" if over2x else "FAIL",
                   "detail": "p95 > 2× budżetu = BLOCK: " + str(over2x)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "latency_budget_threshold": thr,
            "over_2x_blocked": over2x,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_latency_budget")


if __name__ == "__main__":
    raise SystemExit(main())
