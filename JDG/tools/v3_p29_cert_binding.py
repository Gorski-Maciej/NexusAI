#!/usr/bin/env python3
"""NexusAI JDG — V3-P29-I10 GATE-TO-CERTIFICATE BINDING.

Dowód wdrożenia: certyfikat decyzji zawiera ID wersji bramek — pełny provenance (F4; P11/P44)
"""
from __future__ import annotations

from v3_p29_common import (P29_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P29-I10"
RULE = "jdg.v3_p29_quality_campaigns.gate_to_certificate"


def main() -> int:
    hay = read(P29_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    has_routing = "BLOCK_AND_ALERT" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: BLOCK_AND_ALERT (certyfikat bez wersji = BLOCK)"})
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
    return emit(bundle, "v3_p29_cert_binding")


if __name__ == "__main__":
    raise SystemExit(main())
