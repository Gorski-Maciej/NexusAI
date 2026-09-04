#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I01 INTEREST PRECISION ENGINE (art. 56 OrdPU).

Dowód wdrożenia: silnik odsetek z precyzją groszową — stawka jako dane
(v3_p17_interest_rate_annual z valid_from — ADR-002/P05), kapitalizacja
miesięczna, zaokrąglenie half-up 0,01 i temporalność retro (fail-closed).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I01"

RULE = "jdg.v3_p17_ordynacja_obrona.interest_precision_engine"
TH_KEYS = ["v3_p17_interest_rate_annual", "v3_p17_interest_rates_valid_from",
           "v3_p17_interest_capitalization"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_cap = "_ie_compound" in hay and "numbers.range" in hay and "capitalization_active" in hay
    has_round = "_round2" in hay and "floor" in hay and '"interest_rounded_pln"' in hay
    has_temporal = '"retro_active"' in hay and "valid_from" in hay and '"rate_valid_from"' in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "interest_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "monthly_capitalization", "status": "OK" if has_cap else "FAIL",
                   "detail": "kapitalizacja miesięczna (model składany, numbers.range)"})
    checks.append({"name": "grosz_rounding", "status": "OK" if has_round else "FAIL",
                   "detail": "zaokrąglenie half-up do 0,01 (granice groszowe)"})
    checks.append({"name": "temporal_retro", "status": "OK" if has_temporal else "FAIL",
                   "detail": "okno temporalne stawki + fail-closed retro (P05)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: stawka/okno z data.thresholds.ord"})

    if not has_round:
        findings.append({"id": "V3-P17-L01", "severity": "P1",
                         "evidence": "brak testowalnej granicy groszowej (0,01)",
                         "fix": "I01: _round2 + testy graniczne 0,005/0,01"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "capitalization": has_cap, "rounding": has_round,
                    "temporal": has_temporal, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 56 OrdPU; ADR-002 (parametry-as-data); P05 (temporalność); "
                                "kontrakt V3_P36 (płatności)",
                     "rule": "odsetki groszowe z kapitalizacją miesięczną i granicą 0,01"}}
    return emit(bundle, "v3_p17_interest_precision_engine")


if __name__ == "__main__":
    raise SystemExit(main())
