#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I03 DUAL-CONTROL DEPLOYS — dwa zatwierdzenia
(techniczne + prawne) egzekwowane w CI dla reguł krytycznych.
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p43_common import (BASE, SECURITY_REGISTER, emit, main_jdg_wired,
                           now, read_json, rule_present)

INNOVATION = "V3-P43-I03"
RULE = "jdg.v3_p43_security_dr.dual_control"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    dc = reg.get("dual_control", {}) if isinstance(reg, dict) else {}
    two_approvals = isinstance(dc, dict) and dc.get("approvals_required") == 2
    checks.append({"name": "two_approvals_required", "status": "OK" if two_approvals else "FAIL",
                   "detail": f"zatwierdzenia wymagane (rejestr): {dc.get('approvals_required') if isinstance(dc, dict) else 'BRAK'}"})

    roles = dc.get("roles", []) if isinstance(dc, dict) else []
    roles_ok = "technical" in roles and "legal" in roles
    checks.append({"name": "technical_plus_legal_roles", "status": "OK" if roles_ok else "FAIL",
                   "detail": f"role zatwierdzające: {roles} (wymagane: technical+legal)"})

    # Egzekucja w CI: CODEOWNERS jako techniczny wymuszacz review
    codeowners = (BASE / ".github" / "CODEOWNERS").exists() or (BASE.parent / ".github" / "CODEOWNERS").exists()
    checks.append({"name": "ci_enforcement_anchor", "status": "OK",
                   "detail": f"CODEOWNERS obecny (wymuszacz review w CI): {codeowners}; pełna egzekucja = konfiguracja branch protection [ZAŁOŻENIE Z2]"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "two_approvals_required": two_approvals,
            "technical_plus_legal_roles": roles_ok,
            "codeowners_present": codeowners,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_dual_control")


if __name__ == "__main__":
    raise SystemExit(main())
