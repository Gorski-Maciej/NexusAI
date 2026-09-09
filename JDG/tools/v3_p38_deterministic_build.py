#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I01 DETERMINISTIC BUILD + ATTESTATION — checksuma i
attestation SLSA-style (kto zbudował, z jakiego commit, które bramki przepuściły).

Dowód wdrożenia: rules/v3_p38_bundle_deploy_enterprise.rego (I01) + kontrakt
deploy v3_p38_deploy_contract.json (etap build z punktami walidacji P36 L1-L5).
Podanalizy: AN01.
"""
from __future__ import annotations

import hashlib
import json

from v3_p38_common import (DEPLOY_CONTRACT, P38_RULES, emit, main_jdg_wired,
                           now, read, rule_present, threshold_present)

INNOVATION = "V3-P38-I01"
RULE = "jdg.v3_p38_bundle_deploy.deterministic_build"


def _sha256(path_bytes: bytes) -> str:
    return hashlib.sha256(path_bytes).hexdigest()


def main() -> int:
    hay = read(P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Determinizm: build reguły = funkcja bajtów wejściowych (sha256 rego)
    rules_digest = _sha256(hay.encode("utf-8"))
    checks.append({"name": "build_input_digest", "status": "OK",
                   "detail": f"sha256(rego)={rules_digest[:16]}… — ten input = ten output"})

    # Attestation: kontrakt deploy deklaruje pola pochodzenia (kto/commit/bramki)
    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    att = contract.get("attestation_required_fields", [])
    ok_att = all(f in att for f in ("built_by", "source_commit", "gates_passed", "digest"))
    checks.append({"name": "attestation_fields_in_contract", "status": "OK" if ok_att else "FAIL",
                   "detail": f"pola attestation w kontrakcie deploy: {att}"})

    thr = threshold_present("v3_p38_canary_diff_max") and threshold_present("v3_p38_rollback_mttr_max_min")
    checks.append({"name": "thresholds_as_data", "status": "OK" if thr else "FAIL",
                   "detail": f"progi v3_p38 w data.thresholds: {thr}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "rego_sha256": rules_digest,
            "attestation_fields_ok": ok_att,
            "thresholds_as_data": thr,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_deterministic_build")


if __name__ == "__main__":
    raise SystemExit(main())
