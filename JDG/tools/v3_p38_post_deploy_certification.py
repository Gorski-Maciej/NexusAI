#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I09 POST-DEPLOY CERTIFICATION — automatyczny certyfikat
po każdym deploy (wyniki canary, golden replay, SLO) — do rejestru wdrożeń.

Dowód wdrożenia: reguła I09 (BLOCK deploy bez certyfikatu; BLOCK golden fail)
+ kontrakt deploy (cert fields) + P11/P10 kontrakty. Podanalizy: AN04.
"""
from __future__ import annotations

import json

from v3_p38_common import DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I09"
RULE = "jdg.v3_p38_bundle_deploy.post_deploy_certification"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    cert = contract.get("post_deploy_certificate", {})
    ok_cert = all(k in cert for k in ("canary_result", "golden_replay", "slo_snapshot"))
    checks.append({"name": "post_deploy_certificate_fields", "status": "OK" if ok_cert else "FAIL",
                   "detail": f"pola certyfikatu powdrożeniowego: {list(cert.keys())}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "certificate_fields_ok": ok_cert,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_post_deploy_certification")


if __name__ == "__main__":
    raise SystemExit(main())
