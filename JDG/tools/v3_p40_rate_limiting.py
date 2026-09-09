#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I06 RATE LIMITING — limit per rola/endpoint chroni
silnik (eval kosztowny przy dużym bundle) i dane (exfiltration).
Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present, threshold_present)

INNOVATION = "V3-P40-I06"
RULE = "jdg.v3_p40_api_dane_ui.rate_limiting"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p40_rate_limit_default_per_min")
    checks.append({"name": "rate_limit_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p40_rate_limit_default_per_min w data.thresholds: {t}"})

    contract = read_json(API_CONTRACT)
    rl = contract.get("rate_limiting", {}) if contract else {}
    unbounded = rl.get("unlimited_endpoints", []) if isinstance(rl, dict) else []
    no_unbounded = isinstance(rl, dict) and len(unbounded) == 0
    checks.append({"name": "no_unlimited_endpoints", "status": "OK" if no_unbounded else "FAIL",
                   "detail": f"endpointy bez limitu w kontrakcie: {unbounded}"})
    if not no_unbounded:
        findings.append("P0: endpointy bez limitu — exfiltration możliwe (fail-open).")

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "rate_limit_threshold_as_data": t,
            "no_unlimited_endpoints": no_unbounded,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_rate_limiting")


if __name__ == "__main__":
    raise SystemExit(main())
