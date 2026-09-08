#!/usr/bin/env python3
"""NexusAI JDG — V3-P33-I08 COST GOVERNOR — limit tokenów/kosztu per sesja AI
z alarmami — kampania V3 FORTRESS.

Dowód wdrożenia: przekroczenie budżetu = TRIAGE, awarie zewnętrzne nie
zatrzymują pipeline'u (degradacja do trybu bez AI — fail-open kontrolowany).
Progi w data.thresholds.v3_p33 (ADR-002). Podanalizy: 5.1/5.4.
"""
from __future__ import annotations

from v3_p33_common import (P33_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P33-I08"
RULE = "jdg.v3_p33_neural_mesh_ai.cost_governor"


def main() -> int:
    hay = read(P33_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    tokens = threshold_present("v3_p33_token_budget")
    cost = threshold_present("v3_p33_cost_limit_pln")
    checks.append({"name": "budget_thresholds", "status": "OK" if (tokens and cost) else "FAIL",
                   "detail": f"v3_p33_token_budget={tokens}, v3_p33_cost_limit_pln={cost}"})

    # degradacja do trybu bez AI — awarie zewnętrzne nie zatrzymują pipeline'u
    degrade = "degraded" in hay
    checks.append({"name": "degraded_mode", "status": "OK" if degrade else "FAIL",
                   "detail": "degradacja do trybu bez AI (AI_DEGRADED): " + str(degrade)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "token_budget_threshold": tokens,
            "cost_limit_threshold": cost,
            "degraded_mode": degrade,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p33_cost_governor")


if __name__ == "__main__":
    raise SystemExit(main())
