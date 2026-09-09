#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I11 CROSS-DOMAIN HEALTH CONTRACTS — ryczałt↔ZUS,
VAT↔PKPiR: domena chora → sąsiad ostrzeżony. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p42_common import (RYCZALT_ZUS_HARMONIZER, HEALTH_RECONCILIATION,
                           SYSTEM_REGISTER, emit, main_jdg_wired, now,
                           read_json, rule_present)

INNOVATION = "V3-P42-I11"
RULE = "jdg.v3_p42_enterprise_reszta.cross_domain_health"
REQUIRED_CONTRACTS = [("ryczalt", "zus"), ("vat", "pkpir")]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    tools_ok = RYCZALT_ZUS_HARMONIZER.exists() and HEALTH_RECONCILIATION.exists()
    checks.append({"name": "harmonizer_tools_exist", "status": "OK" if tools_ok else "FAIL",
                   "detail": f"ryczalt_zus_health_harmonizer.py + health_reconciliation_micro.py: {tools_ok}"})

    reg = read_json(SYSTEM_REGISTER)
    contracts = reg.get("cross_domain_health_contracts", []) if isinstance(reg, dict) else []
    pairs = {(c.get("domain_a"), c.get("domain_b")) for c in contracts if isinstance(c, dict)}
    missing = [pair for pair in REQUIRED_CONTRACTS if pair not in pairs]
    contracts_ok = not missing
    checks.append({"name": "health_contracts_defined", "status": "OK" if contracts_ok else "FAIL",
                   "detail": f"kontrakty w rejestrze: {sorted(str(p) for p in pairs)} brakujące={missing}"})

    propagation = all(isinstance(c, dict) and c.get("propagation") for c in contracts)
    checks.append({"name": "propagation_defined", "status": "OK" if propagation else "FAIL",
                   "detail": f"propagacja ostrzeżeń zdefiniowana: {propagation}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "harmonizer_tools_exist": tools_ok,
            "health_contracts_defined": contracts_ok,
            "propagation_defined": propagation,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_cross_domain_health")


if __name__ == "__main__":
    raise SystemExit(main())
