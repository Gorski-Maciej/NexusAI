#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I11 SCHEMA-FIRST SDK — generatory klientów Python/TS
z openapi; integracje bez ręcznego mapowania pól; pin wersji schematu
obowiązkowy (P38/P39). Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p40_common import OPENAPI, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P40-I11"
RULE = "jdg.v3_p40_api_dane_ui.schema_first_sdk"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    openapi = read(OPENAPI)
    has_version = "version:" in openapi and "openapi:" in openapi
    checks.append({"name": "openapi_versioned", "status": "OK" if has_version else "FAIL",
                   "detail": f"openapi.yaml wersjonowane (info.version): {has_version}"})

    has_schema_pin = "schema_version" in openapi or "x-schema-version" in openapi
    checks.append({"name": "schema_pin_available", "status": "OK" if has_schema_pin else "FAIL",
                   "detail": f"pin wersji schematu w openapi: {has_schema_pin}"})
    if not has_schema_pin:
        findings.append("P1: brak pinu wersji schematu w openapi — SDK nie wykryje breaking change.")

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "openapi_versioned": has_version,
            "schema_pin_available": has_schema_pin,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_schema_first_sdk")


if __name__ == "__main__":
    raise SystemExit(main())
