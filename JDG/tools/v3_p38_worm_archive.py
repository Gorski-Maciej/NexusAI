#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I05 WORM ARCHIVE WERSJI — każda wersja bundle
archiwizowana WORM (write-once-read-many) — dowód „jak liczyliśmy" bez błędów
odtwarzania.

Dowód wdrożenia: reguła I05 (BLOCK wersja bez WORM) + tools/worm_storage.py
(rdzeń P43) + kontrakt deploy (worm policy). Podanalizy: AN01/AN04.
"""
from __future__ import annotations

import json

from v3_p38_common import BASE, DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I05"
RULE = "jdg.v3_p38_bundle_deploy.worm_archive"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Rdzeń WORM z kampanii GLM52 (rozszerzamy, nie duplikujemy)
    worm = BASE / "tools" / "worm_storage.py"
    worm_exists = worm.exists()
    checks.append({"name": "core_worm_storage_exists", "status": "OK" if worm_exists else "FAIL",
                   "detail": f"tools/worm_storage.py: {worm_exists} (rdzeń, P43)"})

    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    wp = contract.get("worm_policy", {})
    ok_wp = wp.get("archive_every_version") is True and wp.get("immutable") is True
    checks.append({"name": "worm_policy_in_contract", "status": "OK" if ok_wp else "FAIL",
                   "detail": f"worm_policy: archive_every_version={wp.get('archive_every_version')}, immutable={wp.get('immutable')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "core_worm_storage_exists": worm_exists,
            "worm_policy_ok": ok_wp,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_worm_archive")


if __name__ == "__main__":
    raise SystemExit(main())
