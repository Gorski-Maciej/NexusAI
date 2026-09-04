#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I04 FOUR-FORM ADVISOR.

Dowód wdrożenia: porównanie 4 form opodatkowania (ryczałt / skala / liniowy /
karta) na danych 12-miesięcznych z kosztami składkowymi (zdrowotna 4,9%);
stawki form z danych (v3_p18_scale_*, linear, karta); rekomendacja karty =
TRIAGE (decyzja człowieka, art. 21-30); brak danych = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I04"

RULE = "jdg.v3_p18_ryczalt.four_form_advisor"
TH_KEYS = ["v3_p18_health_rate_pct", "v3_p18_scale_low_rate", "v3_p18_scale_high_rate",
           "v3_p18_scale_threshold_pln", "v3_p18_linear_rate", "v3_p18_karta_monthly_pln"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_forms = '"tax_ryczalt_total_pln"' in hay and '"tax_scale_total_pln"' in hay and \
                '"tax_linear_total_pln"' in hay and '"tax_karta_total_pln"' in hay
    has_best = '"recommendation"' in hay and "_fa_best" in hay
    has_karta = "_fa_karta_recommended" in hay and "art. 21-30" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "advisor_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "four_forms", "status": "OK" if has_forms else "FAIL",
                   "detail": "porównanie ryczałt/skala/liniowy/karta (12M)"})
    checks.append({"name": "recommendation", "status": "OK" if has_best else "FAIL",
                   "detail": "rekomendacja formy + kwoty po podatku"})
    checks.append({"name": "karta_decision", "status": "OK" if has_karta else "FAIL",
                   "detail": "karta = TRIAGE (warunki art. 21-30, decyzja człowieka)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: stawki form/zdrowotna z data.thresholds.lump_sum"})

    if not has_forms:
        findings.append({"id": "V3-P18-L04", "severity": "P1",
                         "evidence": "brak porównania 4 form z kosztami składkowymi",
                         "fix": "I04: doradca 4 form (integracja V3_P14)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "forms": has_forms, "recommendation": has_best,
                    "karta": has_karta, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 12 ustawy o zryczałtowanym PIT; art. 21-30 (karta) "
                                "[NIEZWERYFIKOWANE]; integracja V3_P14 (form_changer)",
                     "rule": "doradca 4 form z kosztami składkowymi na danych 12M"}}
    return emit(bundle, "v3_p18_four_form_advisor")


if __name__ == "__main__":
    raise SystemExit(main())
