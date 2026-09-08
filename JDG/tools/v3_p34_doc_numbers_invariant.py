#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I07 DOC-NUMBERS INVARIANT — dowolna liczba w dokumentacji
musi mieć anchor do narzędzia liczącego — kampania V3 FORTRESS.

Dowód wdrożenia: liczba bez anchora = [DEKLARACJA] = TRIAGE (limit jako dane);
sfabrykowane liczby = BLOCK (kanon P00: dowód bez uruchomienia = twierdzenie).
Narząd: doc_consistency_validator.py. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, emit, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P34-I07"
RULE = "jdg.v3_p34_walidacja_narzedzia.doc_numbers_invariant"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    limit = threshold_present("v3_p34_doc_unanchored_max")
    checks.append({"name": "unanchored_limit_threshold", "status": "OK" if limit else "FAIL",
                   "detail": "v3_p34_doc_unanchored_max w thresholds: " + str(limit)})

    decl = "DEKLARACJA" in hay
    checks.append({"name": "declaration_tag_semantics", "status": "OK" if decl else "FAIL",
                   "detail": "etykieta [DEKLARACJA] w regule: " + str(decl)})

    validator = (BASE / "tools" / "doc_consistency_validator.py").exists()
    checks.append({"name": "doc_validator_present", "status": "OK" if validator else "FAIL",
                   "detail": "tools/doc_consistency_validator.py: " + str(validator)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "unanchored_limit_threshold": limit,
            "declaration_tag_semantics": decl,
            "doc_validator_present": validator,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_doc_numbers_invariant")


if __name__ == "__main__":
    raise SystemExit(main())
