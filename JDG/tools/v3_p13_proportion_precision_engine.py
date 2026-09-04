#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I08 PROPORTION PRECISION ENGINE (art. 90 VAT).

Proporcja z groszówką: factor = obrót opodatkowany / obrót ogółem, zaokrąglenie
do 0,001; granice 2%/98%; test graniczny 1% (98% vs 100%); pre-proporcja nowego
podatnika (art. 90 ust. 8-10) z obrotami planowanymi i korektą wstępną.
Dowód: reguła proportion_precision_engine + parametry proportion_* w thresholds.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I08"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.proportion_precision_engine", hay)
    has_rounding = "0.001" in hay and "factor_rounded" in hay
    has_boundaries = "proportion_min_threshold" in hay and "proportion_max_threshold" in hay
    has_1pct = "boundary_1pct_test" in hay
    has_preprop = "pre_proportion" in hay and "preliminary_correction" in hay
    missing = thresholds_missing(["proportion_min_threshold", "proportion_max_threshold"])

    checks.append({"name": "proportion_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła proportion_precision_engine: {has_rule}"})
    checks.append({"name": "grosz_rounding", "status": "OK" if has_rounding else "FAIL",
                   "detail": "zaokrąglanie 0,001 (proporcja art. 90)"})
    checks.append({"name": "boundaries_2_98", "status": "OK" if has_boundaries else "FAIL",
                   "detail": "granice 2%/98% (0% / 100% odliczenia)"})
    checks.append({"name": "test_1pct", "status": "OK" if has_1pct else "FAIL",
                   "detail": "test graniczny 1% (proporcja 98% vs 100%)"})
    checks.append({"name": "pre_proportion", "status": "OK" if has_preprop else "FAIL",
                   "detail": "pre-proporcja nowego podatnika (art. 90 ust. 8-10) + korekta wstępna"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów proportion_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L03", "severity": "P2",
                         "evidence": f"brak parametrów proporcji: {missing}",
                         "fix": "I08: proporcja z groszówką + testy 1% + pre-proporcja nowego podatnika"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"proportion_rule": has_rule, "rounding": has_rounding,
                    "boundaries": has_boundaries, "test_1pct": has_1pct,
                    "pre_proportion": has_preprop, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P05 (temporalność), P10 (golden), P39 (bramki CI), P16 (JPK proporcje)",
                     "rule": "proporcja art. 90 z groszówką (0,001), granice 2%/98%, test 1%, pre-proporcja nowego podatnika"}}
    return emit(bundle, "v3_p13_proportion_precision_engine")


if __name__ == "__main__":
    raise SystemExit(main())