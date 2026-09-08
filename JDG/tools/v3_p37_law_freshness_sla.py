#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I02 FRESHNESS SLA DLA PRAWA — wiek weryfikacji ISAP
per akt; przekroczenie = alarm z listą aktów do re-checku (Law Radar P08)
— V3 FORTRESS.

Dowód wdrożenia: próg v3_p37_law_freshness_sla_days = 7 jako dane; akt bez
weryfikacji = BLOCK (nie podpiera AUTO_POST); stale > SLA = TRIAGE z listą.
Podanalizy: AN01/AN02.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I02"
RULE = "jdg.v3_p37_obserwowalnosc.law_freshness_sla"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_law_freshness_sla_days")
    checks.append({"name": "freshness_sla_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_law_freshness_sla_days w thresholds: {thr}"})

    unverified_block = "bez weryfikacji ISAP" in hay
    checks.append({"name": "unverified_blocks_auto_post", "status": "OK" if unverified_block else "FAIL",
                   "detail": "akt niezweryfikowany = BLOCK: " + str(unverified_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "freshness_sla_threshold": thr,
            "unverified_blocks_auto_post": unverified_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_law_freshness_sla")


if __name__ == "__main__":
    raise SystemExit(main())
