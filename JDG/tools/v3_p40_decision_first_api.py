#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I01 DECISION-FIRST API — każda odpowiedź decyzyjna
zawiera pełny Decision Certificate (P11/F4); front-end i audytor korzystają
z tego samego dowodu. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p40_common import CERT_SERVICE, OPENAPI, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P40-I01"
RULE = "jdg.v3_p40_api_dane_ui.decision_first"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    openapi = read(OPENAPI)
    has_evaluate = "/jdg/decide" in openapi or "/evaluate" in openapi
    checks.append({"name": "openapi_evaluate_path", "status": "OK" if has_evaluate else "FAIL",
                   "detail": f"api/openapi.yaml zawiera endpoint decyzyjny (/jdg/decide): {has_evaluate}"})
    if not has_evaluate:
        findings.append("P0: /evaluate nieobecne w openapi.yaml — brak endpointu decyzyjnego.")

    cert_service = CERT_SERVICE.exists()
    checks.append({"name": "certificate_service_exists", "status": "OK" if cert_service else "FAIL",
                   "detail": f"tools/certificate_service.py (P11): {cert_service}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "openapi_evaluate_path": has_evaluate,
            "certificate_service_exists": cert_service,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_decision_first_api")


if __name__ == "__main__":
    raise SystemExit(main())
