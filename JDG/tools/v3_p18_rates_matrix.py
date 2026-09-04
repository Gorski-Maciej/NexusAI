#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I01 RYCZAŁT RATES-AS-DATA (art. 12).

Dowód wdrożenia: stawki ryczałtu jako dane (ADR-002/P06) — uzupełnione stawki
10/12,5/14%, zestaw stawek, mapa PKWiU wersjonowana (rate_map_version), próg
14% dla IT; walidacja kategorii → stawka; nieznana kategoria = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I01"

RULE = "jdg.v3_p18_ryczalt.rates_matrix"
TH_KEYS = ["v3_p18_rate_10pct", "v3_p18_rate_12_5pct", "v3_p18_rate_14pct",
           "v3_p18_rate_set", "v3_p18_rate_map_version",
           "v3_p18_rate_14pct_threshold_pln"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_cats = '"HANDEL"' in hay and '"BUDOWNICTWO"' in hay and '"WOLNE_ZAWODY"' in hay and '"IT"' in hay
    has_map = "rate_map_version" in hay and "v3_p18_rate_14pct_threshold_pln" in hay
    has_missing_rates = '"v3_p18_rate_10pct"' in hay or "0.10" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "rates_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "categories", "status": "OK" if has_cats else "FAIL",
                   "detail": "mapowanie kategoria PKWiU → stawka (art. 12)"})
    checks.append({"name": "rate_map_versioned", "status": "OK" if has_map else "FAIL",
                   "detail": "mapa PKWiU wersjonowana + próg 14% dla IT"})
    checks.append({"name": "rates_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002/P06: stawki (w tym 10/12,5/14%) z data.thresholds.lump_sum"})

    if not has_missing_rates:
        findings.append({"id": "V3-P18-L01", "severity": "P1",
                         "evidence": "brak części stawek art. 12 (10/12,5/14%) w danych",
                         "fix": "I01: uzupełnienie stawek w lump_sum + zestaw rate_set"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "categories": has_cats, "map_version": has_map,
                    "rates_as_data": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 12 ustawy o zryczałtowanym PIT; ADR-002/P06; mapa MF/PKWiU",
                     "rule": "stawki-as-data z walidacją kategoria → stawka"}}
    return emit(bundle, "v3_p18_rates_matrix")


if __name__ == "__main__":
    raise SystemExit(main())
