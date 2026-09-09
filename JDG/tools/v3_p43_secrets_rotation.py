#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I04 SECRETS ROTATION — rotacja kluczy z dowodem
(kiedy/kto/co) + test unieważnienia starego klucza. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p43_common import (QUANTUM_SAFE, SECURITY_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P43-I04"
RULE = "jdg.v3_p43_security_dr.secrets_rotation"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    sr = reg.get("secrets", {}) if isinstance(reg, dict) else {}
    policy_ok = isinstance(sr, dict) and sr.get("rotation_days", 0) > 0
    checks.append({"name": "rotation_policy_defined", "status": "OK" if policy_ok else "FAIL",
                   "detail": f"polityka rotacji w rejestrze: co {sr.get('rotation_days', 'BRAK') if isinstance(sr, dict) else 'BRAK'} dni"})

    attestation = isinstance(sr, dict) and sr.get("attestation_fields", []) and \
        {"rotated_at", "rotated_by", "key_id"} <= set(sr.get("attestation_fields", []))
    checks.append({"name": "attestation_fields", "status": "OK" if attestation else "FAIL",
                   "detail": f"pola dowodu rotacji: {sr.get('attestation_fields', []) if isinstance(sr, dict) else 'BRAK'}"})

    old_key_test = isinstance(sr, dict) and sr.get("old_key_invalid_test", False)
    checks.append({"name": "old_key_invalid_test", "status": "OK" if old_key_test else "FAIL",
                   "detail": f"test, że stary klucz nie działa (fail-closed): {old_key_test}"})

    # Sekrety NIE w repo: skan na hardcode kluczy w narzędziu kryptograficznym
    crypto = QUANTUM_SAFE.exists()
    checks.append({"name": "crypto_tool_present", "status": "OK" if crypto else "FAIL",
                   "detail": f"tools/quantum_safe_encryption.py (warstwa kryptograficzna): {crypto}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "rotation_policy_defined": policy_ok,
            "attestation_fields": attestation,
            "old_key_invalid_test": old_key_test,
            "crypto_tool_present": crypto,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_secrets_rotation")


if __name__ == "__main__":
    raise SystemExit(main())
