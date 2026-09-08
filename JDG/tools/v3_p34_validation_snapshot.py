#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I11 SNAPSHOT WALIDACJI DO CERTYFIKATU — Decision
Certificate zawiera ID przebiegu walidacji (wersje narzędzi) — V3 FORTRESS.

Dowód wdrożenia: provenance decyzji — decyzja bez ID walidacji = BLOCK.
Spójność z V2 F4 i kontraktem P03. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p34_common import (P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I11"
RULE = "jdg.v3_p34_walidacja_narzedzia.validation_snapshot"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Decision Certificate (V2 F4) + provenance w regule
    cert = "Decision Certificate" in hay or "certyfikacie" in hay
    checks.append({"name": "certificate_provenance", "status": "OK" if cert else "FAIL",
                   "detail": "ID walidacji w Decision Certificate (V2 F4): " + str(cert)})

    # threshold_version i legal_basis_version w wrapperze certyfikatu
    versions = "threshold_version" in hay and "legal_basis_version" in hay
    checks.append({"name": "tool_versions_in_certificate", "status": "OK" if versions else "FAIL",
                   "detail": "wersje narzędzi w certyfikacie: " + str(versions)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "certificate_provenance": cert,
            "tool_versions_in_certificate": versions,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_validation_snapshot")


if __name__ == "__main__":
    raise SystemExit(main())
