#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I02 EU VAT RATES FEED (stawki UE jako dane).

Stawki VAT krajów UE jako DANE z valid_from (feed komisji) — walidacja per kraj,
okna temporalne, źródło. Dowód: reguła eu_vat_rates_feed + parametry
eu_vat_rates_* w data.thresholds.crossborder (P06 parametry-as-data, P05).
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I02"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.eu_vat_rates_feed", hay)
    has_fail_closed = "rate_found" in hay and "NEEDS_ADVICE" in hay
    missing = thresholds_missing(["eu_vat_rates_feed_source", "eu_vat_rates_version"])

    checks.append({"name": "eu_rates_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła eu_vat_rates_feed: {has_rule}"})
    checks.append({"name": "fail_closed_missing_rate", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "brak stawki kraju → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów eu_vat_rates_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P15-L03", "severity": "P2",
                         "evidence": f"brak parametrów źródła/wersji stawek UE: {missing}",
                         "fix": "I02: dodaj eu_vat_rates_feed_source/version do thresholds (P06)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"eu_rates_rule": has_rule, "fail_closed": has_fail_closed,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry-as-data), P05 (temporalność), P44",
                     "rule": "stawki VAT UE wyłącznie jako dane z valid_from i źródłem; brak = NEEDS_ADVICE"}}
    return emit(bundle, "v3_p15_eu_vat_rates_feed")


if __name__ == "__main__":
    raise SystemExit(main())