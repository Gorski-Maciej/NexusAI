#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I04 RBAC + DATA MINIMIZATION — role mapowane na pola
werdyktu (przedsiębiorca nie widzi metryk wewnętrznych; audytor read-only).
RODO art. 5 (minimalizacja). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present)

INNOVATION = "V3-P40-I04"
RULE = "jdg.v3_p40_api_dane_ui.rbac_minimization"
ROLES = ["entrepreneur", "accountant", "auditor", "admin"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    rbac = contract.get("rbac", {}) if contract else {}
    role_map = rbac.get("role_field_map", {}) if isinstance(rbac, dict) else {}
    missing_roles = [r for r in ROLES if r not in role_map]
    map_ok = bool(role_map) and not missing_roles
    checks.append({"name": "role_field_map_complete", "status": "OK" if map_ok else "FAIL",
                   "detail": f"mapa rola→pola w kontrakcie API: role={sorted(role_map)} brakujące={missing_roles}"})
    if not map_ok:
        findings.append(f"P0: mapa rola→pola niekompletna (brak: {missing_roles}) — RBAC fail-open.")

    auditor_readonly = rbac.get("auditor_read_only", False) if isinstance(rbac, dict) else False
    checks.append({"name": "auditor_read_only", "status": "OK" if auditor_readonly else "FAIL",
                   "detail": f"audytor tylko odczyt: {auditor_readonly}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "role_field_map_complete": map_ok,
            "roles": sorted(role_map),
            "auditor_read_only": auditor_readonly,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_rbac_minimization")


if __name__ == "__main__":
    raise SystemExit(main())
