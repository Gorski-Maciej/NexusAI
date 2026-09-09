#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I10 INFRASTRUCTURE AS LEGAL RECORD — deployments.json
jako artefakt prawny (kto wdrożył jaką wersję kiedy) z podpisem i WORM.

Dowód wdrożenia: reguła I10 (BLOCK wpis bez podpisu; TRIAGE niekompletny)
+ kontrakt deploy (legal record fields). Podanalizy: AN04.
"""
from __future__ import annotations

import json

from v3_p38_common import BASE, DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I10"
RULE = "jdg.v3_p38_bundle_deploy.legal_record"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    deployments = BASE / "bundles" / "deployments.json"
    dep_ok = deployments.exists()
    checks.append({"name": "deployments_registry_exists", "status": "OK" if dep_ok else "FAIL",
                   "detail": f"bundles/deployments.json: {dep_ok} (rejestr wdrożeń)"})

    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    lr = contract.get("legal_record_required_fields", [])
    ok_lr = all(f in lr for f in ("version", "deployed_at", "deployed_by", "reason", "canary_result", "signature"))
    checks.append({"name": "legal_record_fields", "status": "OK" if ok_lr else "FAIL",
                   "detail": f"pola prawne wpisu: {lr}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "deployments_registry_exists": dep_ok,
            "legal_record_fields_ok": ok_lr,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_legal_record")


if __name__ == "__main__":
    raise SystemExit(main())
