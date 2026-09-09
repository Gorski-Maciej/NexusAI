#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I07 CERTIFICATE WORM + SIGNATURE — certyfikat finalny
podpisany i archiwizowany WORM z retencją ≥ próg (UoR art. 74-75
[NIEZWERYFIKOWANE]; eIDAS [NIEZWERYFIKOWANE]). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p44_common import (CERT_REGISTER, CERT_SERVICE, WORM_STORAGE, emit,
                           now, read_json, rule_present)

INNOVATION = "V3-P44-I07"
RULE = "jdg.v3_p44_certyfikacja_finalna.certificate_worm_signature"
RETENTION_MIN = 5


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    cert = reg.get("final_certificate", {}) if isinstance(reg, dict) else {}
    signed = bool(cert.get("signature"))
    worm = cert.get("worm") is True
    retention = cert.get("retention_years", 0)
    checks.append({"name": "certificate_signed", "status": "OK" if signed else "FAIL",
                   "detail": f"podpis certyfikatu: {cert.get('signature', 'BRAK')}"})
    checks.append({"name": "certificate_worm", "status": "OK" if worm else "FAIL",
                   "detail": f"WORM: {worm}; ref: {cert.get('worm_ref', 'BRAK')}"})
    checks.append({"name": "retention_meets_minimum", "status": "OK" if retention >= RETENTION_MIN else "FAIL",
                   "detail": f"retencja {retention} lat ≥ {RETENTION_MIN} (UoR art. 74-75 [NIEZWERYFIKOWANE])"})

    # Mechanizm istnieje w kodzie (P38/P43), nie tylko deklaracja
    mech_ok = WORM_STORAGE.exists() and CERT_SERVICE.exists()
    checks.append({"name": "worm_and_signature_mechanism", "status": "OK" if mech_ok else "FAIL",
                   "detail": f"tools/worm_storage.py + tools/certificate_service.py: {mech_ok}"})

    if not (signed and worm and retention >= RETENTION_MIN):
        findings.append({"severity": "BLOCKER", "message": "certyfikat bez podpisu/WORM/retencji = dowód nietrwały"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "signed": signed,
            "worm": worm,
            "retention_years": retention,
            "retention_min": RETENTION_MIN,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_worm_signature")


if __name__ == "__main__":
    raise SystemExit(main())
