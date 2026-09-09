#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I07 BUNDLE SIGNATURE VERIFICATION — OPA ładuje wyłącznie
podpisane bundle (weryfikacja przy load); unsigned = odrzucenie (fail-closed).

Dowód wdrożenia: reguła I07 (BLOCK unsigned load; BLOCK weryfikacja wyłączona)
+ kontrakt deploy (signature policy). Podanalizy: AN01.
"""
from __future__ import annotations

import json

from v3_p38_common import DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I07"
RULE = "jdg.v3_p38_bundle_deploy.signature_verification"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    sp = contract.get("signature_policy", {})
    ok_sp = sp.get("require_signed_bundle") is True and sp.get("reject_unsigned_at_load") is True
    checks.append({"name": "signature_policy_fail_closed", "status": "OK" if ok_sp else "FAIL",
                   "detail": f"signature_policy: require_signed={sp.get('require_signed_bundle')}, reject_unsigned={sp.get('reject_unsigned_at_load')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "signature_policy_ok": ok_sp,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_signature_verification")


if __name__ == "__main__":
    raise SystemExit(main())
