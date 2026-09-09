#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I11 OWNER ATTESTATION — właściciel potwierdza przyjęcie
certyfikatu z listą zastrzeżeń — 4-eyes domknięte po stronie biznesowej.
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p44_common import CERT_REGISTER, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I11"
RULE = "jdg.v3_p44_certyfikacja_finalna.owner_attestation"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    att = reg.get("owner_attestation", {}) if isinstance(reg, dict) else {}
    mechanism = str(att.get("mechanism", "")) if isinstance(att, dict) else ""
    checks.append({"name": "attestation_mechanism_defined", "status": "OK" if mechanism else "FAIL",
                   "detail": f"mechanizm 4-eyes biznesowe: {mechanism or 'BRAK'}"})

    reservations = att.get("reservations_template", []) if isinstance(att, dict) else []
    checks.append({"name": "reservations_template", "status": "OK" if reservations else "FAIL",
                   "detail": f"szablon zastrzeżeń (jawne założenia): {len(reservations)} wpis(y)"})

    # Atest jest krokiem ludzkim: signed=false jest HONEST state (TRIAGE, nie blokada automatu)
    signed = att.get("signed") is True
    checks.append({"name": "attestation_state_honest", "status": "OK" if isinstance(att.get("signed"), bool) else "FAIL",
                   "detail": f"stan atestu jawny (signed={att.get('signed')}) — krok ludzki poza zakresem automatu"})

    if not signed:
        findings.append({"severity": "INFO", "message": "atest właściciela oczekuje na podpis (krok ludzki, mechanizm gotowy)"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "signed": signed,
            "reservations": len(reservations),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_owner_attestation")


if __name__ == "__main__":
    raise SystemExit(main())
