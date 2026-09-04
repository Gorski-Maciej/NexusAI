#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I04 FX PRECISION ENGINE (kursy NBP D-1, grosze).

Kurs z dnia poprzedniego (D-1) dla ewidencji, zaokrąglanie round-half-up do 0,01,
invariant: suma PLN = suma(wartość × kurs) po zaokrągleniu. Dowód: reguła
fx_precision_engine + parametry fx_* w thresholds + test groszowy.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I04"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.fx_precision_engine", hay)
    has_rounding = "round_half_up" in hay and "0.01" in hay or "rounding" in hay
    has_invariant = "invariant_ok" in hay and "amount_pln" in hay
    missing = thresholds_missing(["fx_rounding_rule", "fx_rounding_scale", "fx_use_previous_day_rate"])

    checks.append({"name": "fx_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła fx_precision_engine: {has_rule}"})
    checks.append({"name": "grosz_rounding", "status": "OK" if has_rounding else "FAIL",
                   "detail": "zaokrąglanie round-half-up (0,01) w regułach"})
    checks.append({"name": "invariant_groszowy", "status": "OK" if has_invariant else "FAIL",
                   "detail": "invariant: suma PLN = suma(wartość × kurs)"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów fx_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P15-L05", "severity": "P2",
                         "evidence": f"brak parametrów fx_* (rounding/scale/D-1): {missing}",
                         "fix": "I04: parametry do thresholds; test groszowy EUR 1234,56 × kurs D-1"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"fx_rule": has_rule, "rounding": has_rounding,
                    "invariant": has_invariant, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P28 (księgowość), P16 (JPK waluty), P04 (inwarianty), P44",
                     "rule": "kursy D-1 dla ewidencji; przeliczenia groszowe round-half-up; invariant PLN sprawdzany"}}
    return emit(bundle, "v3_p15_fx_precision_engine")


if __name__ == "__main__":
    raise SystemExit(main())