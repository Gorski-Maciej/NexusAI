#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I06 DEPLOYMENT WINDOW — okna wdrożeniowe wyłączone w
okresach krytycznych (deklaracje VAT/PIT, ZUS) — kalendarz (P25) jako źródło blokad.

Dowód wdrożenia: reguła I06 (BLOCK deploy w zablokowanym oknie) + kalendarz
zbiorczy P25. Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p38_common import BUNDLES, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I06"
RULE = "jdg.v3_p38_bundle_deploy.deployment_window"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Kalendarz P25 jako źródło blokad (rozszerzamy, nie duplikujemy)
    cal = BUNDLES / "v3_p25_tenant_calendar.json"
    cal_ok = cal.exists()
    checks.append({"name": "p25_calendar_available", "status": "OK" if cal_ok else "FAIL",
                   "detail": f"bundles/v3_p25_tenant_calendar.json: {cal_ok} (źródło okien)"})

    contract = json.loads(read(__import__("v3_p38_common").DEPLOY_CONTRACT)) if read(__import__("v3_p38_common").DEPLOY_CONTRACT) else {}
    dw = contract.get("deployment_windows", {})
    ok_dw = dw.get("source") == "P25_master_deadline_calendar" and dw.get("block_in_critical_windows") is True
    checks.append({"name": "deployment_windows_contract", "status": "OK" if ok_dw else "FAIL",
                   "detail": f"deployment_windows: source={dw.get('source')}, block={dw.get('block_in_critical_windows')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "p25_calendar_available": cal_ok,
            "deployment_windows_contract_ok": ok_dw,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_deployment_window")


if __name__ == "__main__":
    raise SystemExit(main())
