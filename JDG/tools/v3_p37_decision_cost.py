#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I11 METRYKI KOSZTU DECYZJI — CPU/tokeny per decyzja
(szczególnie ścieżki AI z P33) — budżetowanie warstwy AI — V3 FORTRESS.

Dowód wdrożenia: decyzja AI bez telemetrii kosztu = BLOCK (spójne z cost
governorem P33-I08); koszt > limit = TRIAGE. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I11"
RULE = "jdg.v3_p37_obserwowalnosc.decision_cost"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_ai_cost_limit_per_decision")
    checks.append({"name": "ai_cost_limit_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_ai_cost_limit_per_decision w thresholds: {thr}"})

    p33_link = "P33" in hay
    checks.append({"name": "ai_path_p33_contract", "status": "OK" if p33_link else "FAIL",
                   "detail": "koszt ścieżek AI (kontrakt P33-I08): " + str(p33_link)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "ai_cost_limit_threshold": thr,
            "ai_path_p33_contract": p33_link,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_decision_cost")


if __name__ == "__main__":
    raise SystemExit(main())
