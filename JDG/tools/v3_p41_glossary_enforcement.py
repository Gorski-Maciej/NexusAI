#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I05 GLOSSARY ENFORCEMENT — SLOWNIK_REFERENCJI_PRAWNYCH
jako jedyne źródło terminów; naruszenia = BLOCKER. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p41_common import (BBB, GLOSSARY, LEGAL_ACTS, LEGAL_REGISTRY,
                           emit, main_jdg_wired, now, read, rule_present, threshold_present)

INNOVATION = "V3-P41-I05"
RULE = "jdg.v3_p41_dokumentacja.glossary_enforcement"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    glossary = read(GLOSSARY)
    has_source = len(glossary) > 0
    checks.append({"name": "glossary_source_exists", "status": "OK" if has_source else "FAIL",
                   "detail": f"SLOWNIK_REFERENCJI_PRAWNYCH.md: {len(glossary.splitlines())} linii"})

    # Spójność rejestrów: LEGAL_REFERENCE_ACTS (katalog akt) ↔ Bbb (źródła)
    # — ten sam akt (kotwica: Ustawa o rachunkowości) w obu dokumentach
    acts, bbb = read(LEGAL_ACTS), read(BBB)
    uor_in_acts = "rachunkowo" in acts.lower()
    uor_in_bbb = "rachunkowo" in bbb.lower()
    consistent = uor_in_acts and uor_in_bbb
    checks.append({"name": "legal_registries_consistent", "status": "OK" if consistent else "FAIL",
                   "detail": f"UoR w LEGAL_REFERENCE_ACTS: {uor_in_acts}, w Bbb: {uor_in_bbb} (LEGAL_SOURCE_REGISTRY = rejestr procesu, nie akt)"})

    t = threshold_present("v3_p41_glossary_violations_max")
    checks.append({"name": "glossary_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p41_glossary_violations_max w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "glossary_source_exists": has_source,
            "legal_registries_consistent": consistent,
            "glossary_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_glossary_enforcement")


if __name__ == "__main__":
    raise SystemExit(main())
