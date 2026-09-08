#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I11 MIGRACJA JAKO DANE — definicja migracji
(mapowania, wyjątki) w danych (YAML); narzędzie jest silnikiem — przegląd
migracji bez kodu — V3 FORTRESS.

Dowód wdrożenia: migracja bez definicji w danych = BLOCK; mapowania wkodowane
w kod = BLOCK (ADR-002); spójne z P34-I11 (wyjątki jako dane z właścicielem
i wygasaniem). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P36-I11"
RULE = "jdg.v3_p36_generatory_migratory.migration_as_data"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    undefined_block = "Migracje bez definicji w danych" in hay
    checks.append({"name": "definition_required", "status": "OK" if undefined_block else "FAIL",
                   "detail": "migracja bez definicji = BLOCK: " + str(undefined_block)})

    hardcoded_block = "Mapowania migracji wkodowane w kod" in hay
    checks.append({"name": "hardcoded_mappings_blocked", "status": "OK" if hardcoded_block else "FAIL",
                   "detail": "mapowania w kodzie = BLOCK (ADR-002): " + str(hardcoded_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "definition_required": undefined_block,
            "hardcoded_mappings_blocked": hardcoded_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_migration_as_data")


if __name__ == "__main__":
    raise SystemExit(main())
