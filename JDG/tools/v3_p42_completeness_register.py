#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I09 SYSTEM COMPLETENESS REGISTER — wymogi enterprise
(RBAC, quota, multi-tenant, i18n, a11y) ze statusem jest/brak/plan.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p42_common import SYSTEM_REGISTER, emit, main_jdg_wired, now, read_json, rule_present

INNOVATION = "V3-P42-I09"
RULE = "jdg.v3_p42_enterprise_reszta.completeness_register"
REQUIRED = ["rbac", "rate_limiting", "multi_tenant", "i18n", "a11y", "quota", "audit_worm"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SYSTEM_REGISTER)
    reqs = reg.get("enterprise_requirements", {}) if isinstance(reg, dict) else {}
    missing_reqs = [r for r in REQUIRED if r not in reqs]
    registered_ok = not missing_reqs
    checks.append({"name": "all_requirements_registered", "status": "OK" if registered_ok else "FAIL",
                   "detail": f"wymogi w rejestrze: {sorted(reqs)} brakujące={missing_reqs}"})

    # Statusy tylko z dozwolonego zbioru (jest/brak/plan) — prawdziwa luka widoczna
    valid = {"present", "missing", "planned"}
    bad_status = {k: v.get("status") for k, v in reqs.items()
                  if isinstance(v, dict) and v.get("status") not in valid}
    status_ok = not bad_status
    checks.append({"name": "statuses_valid", "status": "OK" if status_ok else "FAIL",
                   "detail": f"statusy poza zbioru: {bad_status if bad_status else 'brak'}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "all_requirements_registered": registered_ok,
            "statuses_valid": status_ok,
            "requirements": {k: v.get("status") for k, v in reqs.items() if isinstance(v, dict)},
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_completeness_register")


if __name__ == "__main__":
    raise SystemExit(main())
