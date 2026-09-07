#!/usr/bin/env python3
"""NexusAI JDG — V3-P28-I05 MARGINAL DOMAIN DECISIONS.

Dowód wdrożenia: rejestr decyzji taxfree/seasonal/insurance/advertising/regulated/procurement/esig (AN05; P44)
"""
from __future__ import annotations

from v3_p28_common import (P28_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P28-I05"
RULE = "jdg.v3_p28_hyper_plan45.marginal_domain_register"


def main() -> int:
    hay = read(P28_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p28_marginal_register_version"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "SUGGEST" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: SUGGEST (rejestr dokumentowany)"})
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
    return emit(bundle, "v3_p28_marginal_register")


if __name__ == "__main__":
    raise SystemExit(main())
