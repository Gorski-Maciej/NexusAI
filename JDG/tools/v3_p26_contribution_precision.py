#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I01 CONTRIBUTION PRECISION ENGINE (składki groszowe).

Dowód wdrożenia: mirror matematyki groszowej rego — podstawa → 4 składki →
total; test wzorcowy 4161,00 → emerytalna 812,63; walidacja zakresu podstawy
(min 60% prognozy bez ulgi); tolerancja 0,005 z data.thresholds.zus26.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, grosze, main_jdg_wired, now,
                           read, rule_present, social_contributions,
                           threshold_present)

INNOVATION = "V3-P26-I01"
RULE = "jdg.v3_p26_zus_skladki.contribution_precision"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_grosze = "_grosze(" in hay and "floor" in hay
    has_bounds = "social_base_standard" in hay and "_cp_base_min" in hay
    rates_ok = all(threshold_present(k) for k in
                   ["pension_rate", "disability_rate", "sickness_voluntary_rate", "accident_rate"])
    has_tolerance = threshold_present("v3_p26_grosz_tolerance")

    # Test wzorcowy groszowy: 4161,00 × 19,52% = 812,23 (half-up).
    # UWAGA (V3-P26-X07): prompt pyta o "812,63" — wartość arymetycznie
    # niespójna z 4161 × 0,1952; przyjęto 812,23 (dowód: mirror matematyki).
    c = social_contributions(4161.00)
    expected = {"pension": 812.23, "disability": 332.88, "sickness": 101.94, "accident": 69.49}
    penny_ok = all(abs(c[k] - expected[k]) < 0.005 for k in expected)

    checks.append({"name": "precision_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "grosze_rounding", "status": "OK" if has_grosze else "FAIL",
                   "detail": "zaokrąglenie half-up do grosza w rego (I01/I07/I12)"})
    checks.append({"name": "base_bounds", "status": "OK" if has_bounds else "FAIL",
                   "detail": "zakres podstawy: min 60% prognozy bez ulgi (art. 18a)"})
    checks.append({"name": "rates_as_data", "status": "OK" if rates_ok else "FAIL",
                   "detail": "stopy 19,52/8/2,45/1,67 z data.thresholds.zus (ADR-002)"})
    checks.append({"name": "penny_test_4161", "status": "OK" if penny_ok else "FAIL",
                   "detail": f"4161,00 → emerytalna {c['pension']:.2f} (oczekiwane 812,23; "
                             "prompt 812,63 = rozbieżność do mediacji V3-P26-X07)"})
    checks.append({"name": "tolerance", "status": "OK" if has_tolerance else "FAIL",
                   "detail": "tolerancja groszowa 0,005 z zus26 (I01)"})

    if not penny_ok:
        findings.append({"id": "V3-P26-L01", "severity": "P0",
                         "evidence": f"mirror groszowy niezgodny: {c}",
                         "fix": "korekta zaokrągleń w rego I01 (art. 22 SUS [NIEZWERYFIKOWANE])"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "penny_ok": penny_ok, "rates_as_data": rates_ok,
                    "sample": c, "wiring_main_jdg": main_jdg_wired()},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Kontrakt składki: podstawa → stopa → grosze; wiąże P24 "
                                "(RnA/zasiłki), P18 (ryczałt progi) i P44",
                     "rule": "składki groszowe half-up; zakres podstawy fail-closed"}}
    return emit(bundle, "v3_p26_contribution_precision")


if __name__ == "__main__":
    raise SystemExit(main())
