#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I10 NAMING CONVENTION ENFORCER — walidator konwencji
nazewniczych (rule_id, pakiety, pliki) jako wymóg generatorów — V3 FORTRESS.

Dowód wdrożenia: standardy nazewnicze P00 (11.5) wiążące — naruszenie =
BLOCK; generatory produkują zgodne rule_id i ścieżki BEZ wyjątków (kontrakt
wejściowy P36 z P00). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P36-I10"
RULE = "jdg.v3_p36_generatory_migratory.naming_convention_enforcer"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    violation_block = "Naruszenia konwencji nazewniczych" in hay and "BLOCK" in hay
    checks.append({"name": "violation_blocked", "status": "OK" if violation_block else "FAIL",
                   "detail": "naruszenie konwencji = BLOCK (kanon P00 11.5): " + str(violation_block)})

    canon = "standardy P00" in hay or "P00 (11.5)" in hay
    checks.append({"name": "p00_canon_binding", "status": "OK" if canon else "FAIL",
                   "detail": "kanon P00 jako źródło konwencji: " + str(canon)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "violation_blocked": violation_block,
            "p00_canon_binding": canon,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_naming_convention_enforcer")


if __name__ == "__main__":
    raise SystemExit(main())
