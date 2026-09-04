#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I05 FORM CHANGER PROACTIVE (art. 9 ust. 2 PIT).

Doradca zmiany formy: zmiana skala↔liniowy na NOWY rok podatkowy do 20 lutego
(art. 9 ust. 2 PIT). Po terminie → NEEDS_ADVICE. Alert proaktywny + porównanie
podatku skala (12%/32% + kwota wolna) vs liniowy (19%).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I05"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.form_changer_proactive", hay)
    has_deadline = '"02-20"' in hay and "_before_deadline" in hay and "within_deadline" in hay
    has_compare = "_scale_tax" in hay and "_linear_tax" in hay and "recommended_form" in hay
    has_late_gate = "form_change_late" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["scale_low_rate", "scale_high_rate", "scale_threshold",
                                  "tax_free_amount", "linear_rate"])
    domain_ok = pit_domain_file("tax_form_transition_intelligence.rego")

    checks.append({"name": "form_changer_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła form_changer_proactive: {has_rule}"})
    checks.append({"name": "deadline_20_02", "status": "OK" if has_deadline else "FAIL",
                   "detail": "termin art. 9 ust. 2 (20.02) + okno decyzyjne"})
    checks.append({"name": "tax_compare", "status": "OK" if has_compare else "FAIL",
                   "detail": "porównanie skala vs liniowy (12%/32%+kwota wolna vs 19%)"})
    checks.append({"name": "late_gate", "status": "OK" if has_late_gate else "FAIL",
                   "detail": "zmiana po terminie → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów form: {missing or 'BRAK'}"})
    checks.append({"name": "domain_transition", "status": "OK" if domain_ok else "FAIL",
                   "detail": "rules/pit/tax_form_transition_intelligence.rego obecny — rozszerzenie"})

    if not has_late_gate:
        findings.append({"id": "V3-P14-L05", "severity": "P1",
                         "evidence": "brak fail-closed dla zmiany formy po terminie 20.02",
                         "fix": "I05: zmiana po terminie → NEEDS_ADVICE (wyjątki ustawowe art. 9 ust. 2)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "deadline": has_deadline, "compare": has_compare,
                    "late_gate": has_late_gate, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P41 (UI doradcy), P36 (kalendarz)",
                     "rule": "proaktywny doradca formy z terminem 20.02 (art. 9 ust. 2) i porównaniem podatku"}}
    return emit(bundle, "v3_p14_form_changer")


if __name__ == "__main__":
    raise SystemExit(main())
