#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I06 ERROR BUDGET FREEZE — automatyczne zamrożenie
wdrożeń reguł przy wyczerpaniu budżetu (workflow CI odmawia merge) —
V3 FORTRESS.

Dowód wdrożenia: deploy w trakcie freeze = BLOCK; budżet ≤ min% = TRIAGE
(freeze + eskalacja); polityka budżetu w katalogu SLO jako dane.
Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p37_common import (P37_RULES, SLO_CATALOG, emit, main_jdg_wired, now,
                           read, rule_present)

INNOVATION = "V3-P37-I06"
RULE = "jdg.v3_p37_obserwowalnosc.error_budget_freeze"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    catalog = json.loads(read(SLO_CATALOG)) if read(SLO_CATALOG) else {}
    policy = catalog.get("error_budget_policy", {})
    has_policy = bool(policy) and "freeze_below_pct" in policy
    checks.append({"name": "error_budget_policy_as_data", "status": "OK" if has_policy else "FAIL",
                   "detail": f"error_budget_policy w katalogu SLO: {has_policy}"})

    deploy_block = "freeze" in hay and "BLOCK" in hay
    checks.append({"name": "deploy_during_freeze_blocked", "status": "OK" if deploy_block else "FAIL",
                   "detail": "wdrożenie w trakcie freeze = BLOCK: " + str(deploy_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "error_budget_policy_as_data": has_policy,
            "deploy_during_freeze_blocked": deploy_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_error_budget_freeze")


if __name__ == "__main__":
    raise SystemExit(main())
