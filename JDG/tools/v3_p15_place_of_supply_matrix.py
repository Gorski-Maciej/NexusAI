#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I01 PLACE-OF-SUPPLY MATRIX (art. 28a-28o VAT).

Pełna macierz ścieżek place of supply: usługa → kontrahent (B2B/B2C) → kraj →
reguła → status. Dowód: reguła jdg.v3_p15_crossborder.place_of_supply_matrix
+ parametry pos_*_rule w data.thresholds.crossborder (ADR-002, P06).
"""
from __future__ import annotations

from v3_p15_common import (BUNDLES, P15_RULES, now, read, rule_present,
                           thresholds_missing, emit)

INNOVATION = "V3-P15-I01"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.place_of_supply_matrix", hay)
    has_zones = all(z in hay for z in ("B2B_MIEJSCE_NABYWCY", "B2C_MIEJSCE_SWIADCZENIA",
                                       "NIERUCHOMOSCI", "GASTRONOMIA", "BRAK_ŚCIEŻKI"))
    has_fail_closed = "NEEDS_ADVICE" in hay and "BRAK_ŚCIEŻKI" in hay
    params = ["pos_b2b_rule", "pos_b2c_rule", "pos_real_estate_rule",
              "pos_restaurant_rule", "pos_accommodation_rule", "pos_digital_b2c_rule"]
    missing = thresholds_missing(params)

    checks.append({"name": "place_of_supply_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła place_of_supply_matrix: {has_rule}"})
    checks.append({"name": "zone_coverage", "status": "OK" if has_zones else "FAIL",
                   "detail": "strefy B2B/B2C/nieruchomości/gastronomia/brak-ścieżki obecne"})
    checks.append({"name": "fail_closed_unknown_path", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "nieznana ścieżka → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów pos_* w thresholds: {missing or 'BRAK'}"})

    if not has_rule or not has_zones:
        findings.append({"id": "V3-P15-L01", "severity": "P1",
                         "evidence": "macierz place of supply niepełna w rego v3_p15",
                         "fix": "I01: uzupełnij macierz 28a-28o ze ścieżkami decyzyjnymi"})
    if missing:
        findings.append({"id": "V3-P15-L02", "severity": "P2",
                         "evidence": f"brak parametrów pos_*_rule: {missing}",
                         "fix": "I01: dodaj parametry do data.thresholds.crossborder (ADR-002)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"place_of_supply_rule": has_rule, "zone_coverage": has_zones,
                    "fail_closed": has_fail_closed, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P12 (stawki), P16 (JPK pola UE), P44",
                     "rule": "każda ścieżka place of supply ma regułę + status; nieznana = NEEDS_ADVICE"}}
    return emit(bundle, "v3_p15_place_of_supply_matrix")


if __name__ == "__main__":
    raise SystemExit(main())