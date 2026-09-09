#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I11 ZERO STANDING ACCESS — dostęp produkcyjny tylko
JIT z dowodem użycia (zero stałych uprawnień admina). Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p43_common import (CERT_SERVICE, SECURITY_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P43-I11"
RULE = "jdg.v3_p43_security_dr.zero_standing_access"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    za = reg.get("zero_standing_access", {}) if isinstance(reg, dict) else {}
    jit = isinstance(za, dict) and za.get("model", "") == "JIT"
    checks.append({"name": "jit_model_defined", "status": "OK" if jit else "FAIL",
                   "detail": f"model dostępu: {za.get('model', 'BRAK') if isinstance(za, dict) else 'BRAK'} (wymagane JIT)"})

    ttl_ok = isinstance(za, dict) and isinstance(za.get("max_session_minutes"), int) \
        and 0 < za.get("max_session_minutes", 0) <= 240
    checks.append({"name": "session_ttl_bounded", "status": "OK" if ttl_ok else "FAIL",
                   "detail": f"maksymalna sesja JIT: {za.get('max_session_minutes', 'BRAK') if isinstance(za, dict) else 'BRAK'} min"})

    proof = isinstance(za, dict) and za.get("usage_proof_required", False)
    checks.append({"name": "usage_proof_required", "status": "OK" if proof else "FAIL",
                   "detail": f"dowód użycia (kto/co/kiedy → WORM): {proof}"})

    # Audyt wywołań w WORM (spójność z P40-I05)
    audit_ok = CERT_SERVICE.exists()
    checks.append({"name": "audit_destination_present", "status": "OK" if audit_ok else "FAIL",
                   "detail": f"tools/certificate_service.py (P11/P40 audit chain): {audit_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "jit_model_defined": jit,
            "session_ttl_bounded": ttl_ok,
            "usage_proof_required": proof,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_zero_standing")


if __name__ == "__main__":
    raise SystemExit(main())
