#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I12 RELIEF EXPLANATION ENGINE.

Wyjaśnienie decyzji ulgowej prostym językiem (PL) — do Decision Certificate
(V2 filar F4) i raportu P11: co policzono, jaka podstawa prawna, jaki routing,
jakie dokumenty wymagane. Nieznana ulga w katalogu → NEEDS_ADVICE.
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, emit

INNOVATION = "V3-P14-I12"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.relief_explanation_engine", hay)
    has_pl = "explanation_pl" in hay and "_explanation_lines" in hay and "certificate_ready" in hay
    has_basis = "_relief_legal_basis" in hay and "legal_basis" in hay
    has_unknown_gate = "explanation_unknown" in hay and "NEEDS_ADVICE" in hay

    checks.append({"name": "explanation_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła relief_explanation_engine: {has_rule}"})
    checks.append({"name": "plain_language", "status": "OK" if has_pl else "FAIL",
                   "detail": "narracja PL (co policzono/podstawa/routing/dokumenty) + certificate_ready"})
    checks.append({"name": "legal_basis_chain", "status": "OK" if has_basis else "FAIL",
                   "detail": "legal_basis z katalogu ulg (traceability)"})
    checks.append({"name": "unknown_gate", "status": "OK" if has_unknown_gate else "FAIL",
                   "detail": "nieznana ulga → NEEDS_ADVICE (fail-closed)"})

    if not has_pl:
        findings.append({"id": "V3-P14-L12", "severity": "P3",
                         "evidence": "wyjaśnienie decyzji niekompletne",
                         "fix": "I12: pełna narracja PL per decyzja do certyfikatu P11"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "plain_language": has_pl, "basis": has_basis,
                    "unknown_gate": has_unknown_gate},
        "checks": checks, "findings": findings,
        "contract": {"binding": "V2 F4 (Decision Certificate), P11, P03 (certainty_class)",
                     "rule": "wyjaśnienie decyzji ulgowej prostym językiem (PDF do certyfikatu)"}}
    return emit(bundle, "v3_p14_explanation")


if __name__ == "__main__":
    raise SystemExit(main())
