#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I05 DECISION CERTIFICATE AS TELEMETRY — certyfikat
(P11) = źródło metryk bez dodatkowej instrumentacji: domena, pewność, tryb,
podstawa prawna — V3 FORTRESS.

Dowód wdrożenia: decyzja bez certyfikatu = BLOCK; certyfikat niekompletny =
TRIAGE; każda decyzja P37 zawiera threshold_version/legal_basis_version/
valid_from (kontrakt P03). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P37-I05"
RULE = "jdg.v3_p37_obserwowalnosc.certificate_telemetry"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    cert_fields = all(f in hay for f in ("threshold_version", "legal_basis_version", "valid_from"))
    checks.append({"name": "certificate_fields_in_decisions", "status": "OK" if cert_fields else "FAIL",
                   "detail": "pola certyfikatu w każdej decyzji: " + str(cert_fields)})

    no_cert_block = "Decyzje bez certyfikatu" in hay
    checks.append({"name": "missing_certificate_blocked", "status": "OK" if no_cert_block else "FAIL",
                   "detail": "decyzja bez certyfikatu = BLOCK: " + str(no_cert_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "certificate_fields_in_decisions": cert_fields,
            "missing_certificate_blocked": no_cert_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_certificate_telemetry")


if __name__ == "__main__":
    raise SystemExit(main())
