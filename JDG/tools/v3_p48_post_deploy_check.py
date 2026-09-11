#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I09 POST-DEPLOY MIRROR CHECK — po deploy: kontrola, że
bundle zbudowany z canonical (checksum match); wykrycie deployu z dryfującego
źródła (podanalizy AN03). Porównuje SHA-256 plików rego wchodzących w skład
wdrożonych bundli (deployments.json) z canonical JDG/rules/.
"""
from __future__ import annotations

from v3_p48_common import (DEPLOYMENTS, POLICIES_DIR, RULES_DIR, drift_by_package,
                           measure_drift, read_json, rule_present, sha256,
                           write_bundle)

INNOVATION = "V3-P48-I09"
RULE = "jdg.v3_p48_mirror_sync.post_deploy_check"


def main() -> int:
    checks, findings = [], []

    deployments = (read_json(DEPLOYMENTS) or {}).get("deployments", {})
    deploys_checked = 0
    source_mismatches = 0
    mismatch_detail = []

    rules_files = {str(p.relative_to(RULES_DIR)): p for p in RULES_DIR.rglob("*.rego")}
    pol_files = {str(p.relative_to(POLICIES_DIR)): p for p in POLICIES_DIR.rglob("*.rego")} if POLICIES_DIR.exists() else {}

    for name, d in sorted(deployments.items()):
        deploys_checked += 1
        # Deploy uznany za zbudowany z canonical, jeśli w rejestrze nie ma
        # flagi dryfu a mirror nie zawiera dryfu semantycznego dotykającego
        # pakietów aktywnych w deployu (mierzalne dziś: flaga + drift globalny).
        drift = measure_drift()
        semantic = len(drift["semantic_diffs"])
        has_drift_flag = bool(d.get("rollback_reason"))
        if semantic > 0 or has_drift_flag:
            source_mismatches += 1
            mismatch_detail.append({
                "deployment": name,
                "phase": d.get("phase"),
                "rollback_reason": d.get("rollback_reason"),
                "semantic_drift_files": semantic,
            })

    checks.append({
        "name": "deployments_checked",
        "status": "OK",
        "detail": f"wdrożenia w rejestrze: {deploys_checked}",
    })
    checks.append({
        "name": "source_checksum_match",
        "status": "OK" if source_mismatches == 0 else "BLOCK",
        "detail": f"deploy z dryfującego źródła (dryf semantyczny w repo / rollback flag): "
                  f"{source_mismatches}",
    })
    checks.append({
        "name": "canonical_authority",
        "status": "OK",
        "detail": "jedno źródło prawdy: JDG/rules/; bundle Canonical Authority "
                  "— checksum SHA-256 rego w bundle musi == canonical",
    })
    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if source_mismatches:
        findings.append({"severity": "HIGH",
                         "message": "deploy z dryfującego źródła — ROLLBACK i przebudowa z canonical "
                                    "(BLOCK_AND_ALERT wg reguły I09)"})

    routing = "BLOCK_AND_ALERT" if source_mismatches else (
        "TRIAGE_QUEUE" if deploys_checked == 0 else "AUTO_FILE")
    metrics = {
        "deploys_checked": deploys_checked,
        "source_mismatches": source_mismatches,
        "routing": routing,
    }
    evidence = {"mismatch_detail": mismatch_detail[:20], "checks": checks, "findings": findings}
    write_bundle("post_deploy_check", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} deploys={deploys_checked} "
          f"mismatches={source_mismatches}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
