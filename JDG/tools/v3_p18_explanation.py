#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I12 RYCZAŁT EXPLANATION ENGINE.

Dowód wdrożenia: wyjaśnienie decyzji (stawka/wykluczenie/forma) prostym
językiem do PDF — komplet (decyzja+podstawa+kwota+krok) = SUGGEST; brak
podstawy prawnej = TRIAGE; nieznany typ = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, emit

INNOVATION = "V3-P18-I12"

RULE = "jdg.v3_p18_ryczalt.explanation_engine"


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_types = '"RATE"' in hay and '"EXCLUSION"' in hay and '"FORM"' in hay
    has_complete = '"explanation_complete"' in hay and "legal_basis_present" in hay
    has_fail = "_ex_unknown" in hay and "fail_closed" in hay

    checks.append({"name": "explanation_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "types", "status": "OK" if has_types else "FAIL",
                   "detail": "typy wyjaśnień: stawka / wykluczenie / forma"})
    checks.append({"name": "completeness", "status": "OK" if has_complete else "FAIL",
                   "detail": "komplet: decyzja + podstawa + kwota (PDF)"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "nieznany typ = BLOCK (fail-closed)"})

    if not has_complete:
        findings.append({"id": "V3-P18-L12", "severity": "P1",
                         "evidence": "decyzje ryczałtu bez wyjaśnienia prostym językiem",
                         "fix": "I12: wyjaśnienie do PDF (V2 F4)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "types": has_types, "complete": has_complete,
                    "fail_closed": has_fail},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 12/8 ustawy o zryczałtowanym PIT; V2 F4 "
                                "(Decision Certificate — wytłumaczalność)",
                     "rule": "wyjaśnienie wyboru stawki/wykluczeń prostym językiem"}}
    return emit(bundle, "v3_p18_explanation")


if __name__ == "__main__":
    raise SystemExit(main())
