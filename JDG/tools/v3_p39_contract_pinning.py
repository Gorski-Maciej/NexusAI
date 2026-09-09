#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I08 CONTRACT VERSION PINNING — testy kontraktowe pinują
wersję schematu werdyktu; breaking change wymaga jawnego PR migracyjnego.
Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I08"
RULE = "jdg.v3_p39_testy_ci.contract_pinning"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    strategy = json.loads(read(__import__("v3_p39_common").TEST_STRATEGY)) if read(__import__("v3_p39_common").TEST_STRATEGY) else {}
    pin = strategy.get("contract_pinning", {})
    ok_pin = pin.get("verdict_schema_pinned") is True and pin.get("certificate_schema_pinned") is True
    checks.append({"name": "contract_pins_as_data", "status": "OK" if ok_pin else "FAIL",
                   "detail": f"piny: werdykt={pin.get('verdict_schema_pinned')}, certyfikat={pin.get('certificate_schema_pinned')}"})

    # Kontrakt 25-polowy (P03) istnieje jako dowód wersjonowania
    cert = read(__import__("v3_p39_common").BUNDLES / "v3_p37_slo_catalog.json")
    checks.append({"name": "p37_slo_catalog_available", "status": "OK" if cert else "FAIL",
                   "detail": "P37 SLO catalog (kontrakt progów) dostępny"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "contract_pins_ok": ok_pin,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_contract_pinning")


if __name__ == "__main__":
    raise SystemExit(main())
