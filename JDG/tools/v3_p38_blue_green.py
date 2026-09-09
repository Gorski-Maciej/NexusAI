#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I04 BLUE-GREEN DLA REGUŁ — dwie pełne wersje bundle
równolegle; przełączenie atomowe; stara wersja żyje do zamknięcia miesiąca.

Dowód wdrożenia: reguła I04 (BLOCK zamknięcie starej wersji przed close month)
+ kontrakt deploy (blue_green contract). Podanalizy: AN02/AN03.
"""
from __future__ import annotations

import json

from v3_p38_common import DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I04"
RULE = "jdg.v3_p38_bundle_deploy.blue_green"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = json.loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    bg = contract.get("blue_green", {})
    ok_bg = bool(bg.get("atomic_switch")) and bool(bg.get("old_version_kept_until_month_close"))
    checks.append({"name": "blue_green_contract", "status": "OK" if ok_bg else "FAIL",
                   "detail": f"blue_green w kontrakcie deploy: atomic_switch={bg.get('atomic_switch')}, retencja do close month={bg.get('old_version_kept_until_month_close')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "blue_green_contract_ok": ok_bg,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_blue_green")


if __name__ == "__main__":
    raise SystemExit(main())
