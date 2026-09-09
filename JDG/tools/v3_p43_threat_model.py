#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I01 THREAT MODEL AS CODE — atak → wektor → kontrola →
test; testy kontrol w CI. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p43_common import (RODO_DOC, SECURITY_REGISTER, emit, main_jdg_wired,
                           now, read_json, rule_present)

INNOVATION = "V3-P43-I01"
RULE = "jdg.v3_p43_security_dr.threat_model"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Threat model jako dane w rejestrze (nie fasada): atak→wektor→kontrola→test
    reg = read_json(SECURITY_REGISTER)
    threats = reg.get("threat_model", []) if isinstance(reg, dict) else []
    full = [t for t in threats if isinstance(t, dict)
            and t.get("attack") and t.get("vector") and t.get("control") and t.get("test")]
    facade = bool(threats) and len(full) < len(threats)
    complete = len(threats) > 0 and len(full) == len(threats)
    checks.append({"name": "threat_model_complete", "status": "OK" if complete else "FAIL",
                   "detail": f"wpisy pełne (atak/wektor/kontrola/test): {len(full)}/{len(threats)} fasada={facade}"})

    # RBAC administrowania regułami w zakresie threat modelu
    rbac_scope = any(isinstance(t, dict) and "rule_admin" in str(t.get("vector", ""))
                     for t in threats)
    checks.append({"name": "rule_admin_in_scope", "status": "OK" if rbac_scope else "FAIL",
                   "detail": f"wektor 'rule_admin' (kto zmienia regułę produkcyjną) w modelu: {rbac_scope}"})

    # Kotwica dokumentacyjna (P16 RODO/AML)
    doc_ok = RODO_DOC.exists()
    checks.append({"name": "rodo_aml_doc_exists", "status": "OK" if doc_ok else "FAIL",
                   "detail": f"docs/RODO_AML_BEZPIECZENSTWO_P16.md: {doc_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "threat_entries": len(threats),
            "threat_model_complete": complete,
            "rule_admin_in_scope": rbac_scope,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_threat_model")


if __name__ == "__main__":
    raise SystemExit(main())
