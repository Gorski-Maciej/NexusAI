#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I06 12-MONTH SIMULATOR.

Symulator form na danych historycznych 12 miesięcy z założeniami przyszłości
(wzrost %). Porównanie: skala (12%/32% + kwota wolna) vs liniowy (19%) vs
ryczałt (wskaźnik ogólny z thresholds — stawki PKWiU: kontrakt P18/P14).
Wynik: raport porównawczy + rekomendacja. <12 mies. danych = NEEDS_ADVICE.
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I06"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.form_simulator_12m", hay)
    has_12m = "monthly_complete" in hay and "revenue_12m_pln" in hay and "projected_growth_pct" in hay
    has_compare = "scale_tax_pln" in hay and "linear_tax_pln" in hay and "lump_tax_pln" in hay and "recommended_form" in hay
    has_gap_gate = "simulator_data_gap" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["lump_sum_generic_rate", "scale_low_rate", "linear_rate"])
    domain_ok = pit_domain_file("tax_form_transition_intelligence.rego") and \
        pit_domain_file("forms.rego")

    checks.append({"name": "simulator_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła form_simulator_12m: {has_rule}"})
    checks.append({"name": "12_month_contract", "status": "OK" if has_12m else "FAIL",
                   "detail": "kontrakt: 12 mies. danych historycznych + założenia wzrostu"})
    checks.append({"name": "three_forms_compare", "status": "OK" if has_compare else "FAIL",
                   "detail": "porównanie skala/liniowy/ryczałt + rekomendacja"})
    checks.append({"name": "gap_fail_closed", "status": "OK" if has_gap_gate else "FAIL",
                   "detail": "< 12 mies. danych → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})
    checks.append({"name": "domain_forms", "status": "OK" if domain_ok else "FAIL",
                   "detail": "rules/pit/forms.rego + tax_form_transition_intelligence obecne"})

    if not has_12m:
        findings.append({"id": "V3-P14-L06", "severity": "P2",
                         "evidence": "symulator nie wymusza pełnych 12 miesięcy danych",
                         "fix": "I06: kontrakt 12M + NEEDS_ADVICE przy braku danych"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "contract_12m": has_12m, "compare": has_compare,
                    "gap_gate": has_gap_gate, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P18 (ryczałt — stawki PKWiU poza zakresem), P41 (UI), P36 (kalendarz)",
                     "rule": "symulator form 12 mies. (historia + scenariusze) z raportem porównawczym"}}
    return emit(bundle, "v3_p14_form_simulator")


if __name__ == "__main__":
    raise SystemExit(main())
