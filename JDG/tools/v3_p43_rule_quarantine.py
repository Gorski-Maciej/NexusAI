#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I02 RULE QUARANTINE — izolacja pojedynczej reguły
bez rollbacku bundle (chirurgiczna reakcja). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p43_common import (RULES, SECURITY_REGISTER, SYSTEM_REGISTER_P42,
                           emit, main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P43-I02"
RULE = "jdg.v3_p43_security_dr.rule_quarantine"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Mechanizm kwarantanny jako dane: lista wyłączonych reguł + deadline + owner
    reg = read_json(SECURITY_REGISTER)
    q = reg.get("rule_quarantine", {}) if isinstance(reg, dict) else {}
    mechanism = isinstance(q, dict) and "quarantined_rules" in q and "procedure" in q
    checks.append({"name": "quarantine_mechanism_defined", "status": "OK" if mechanism else "FAIL",
                   "detail": f"mechanizm (lista + procedura) w rejestrze: {mechanism}"})

    # Spójność z P42: tier QUARANTINE zdefiniowany w health tiers (rejestr P42)
    reg42 = read_json(SYSTEM_REGISTER_P42)
    ht = reg42.get("health_tiers", {}) if isinstance(reg42, dict) else {}
    tier_ok = "QUARANTINE" in ht.get("tiers", [])
    checks.append({"name": "quarantine_tier_from_p42", "status": "OK" if tier_ok else "FAIL",
                   "detail": f"tier QUARANTINE (P42 health tiers): {tier_ok}"})

    # Procedura nie wymaga pełnego rollbacku (mitygacja przez flagę, nie bundle)
    surgical = isinstance(q, dict) and q.get("without_full_rollback", False)
    checks.append({"name": "surgical_isolation", "status": "OK" if surgical else "FAIL",
                   "detail": f"izolacja bez pełnego rollbacku bundle: {surgical}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "quarantine_mechanism_defined": mechanism,
            "quarantine_tier_from_p42": tier_ok,
            "surgical_isolation": surgical,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_rule_quarantine")


if __name__ == "__main__":
    raise SystemExit(main())
