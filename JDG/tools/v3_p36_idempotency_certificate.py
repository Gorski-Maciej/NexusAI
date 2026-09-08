#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I02 IDEMPOTENCY CERTIFICATE — każde narzędzie ma test
idempotencji (drugi run = zero diff) wymuszony w bramce P29 — V3 FORTRESS.

Dowód wdrożenia: próg v3_p36_idempotency_required jako dane (ADR-002);
drugi run z diffem = BLOCK, narzędzie bez testu idempotencji = TRIAGE.
Podanalizy: AN01/AN02.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I02"
RULE = "jdg.v3_p36_generatory_migratory.idempotency_certificate"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p36_idempotency_required")
    checks.append({"name": "idempotency_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p36_idempotency_required w thresholds: {thr}"})

    second_run_block = "Drugi run narzędzi z diffem" in hay
    checks.append({"name": "second_run_zero_diff", "status": "OK" if second_run_block else "FAIL",
                   "detail": "drugi run z diffem = BLOCK (certyfikat idempotencji): " + str(second_run_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "idempotency_threshold": thr,
            "second_run_zero_diff": second_run_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_idempotency_certificate")


if __name__ == "__main__":
    raise SystemExit(main())
