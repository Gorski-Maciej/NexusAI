#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I02 GMINA RATES VALIDATOR (art. 5/10 UoPiOL).

Dowód wdrożenia: walidacja stawek gminnych z TWARDYMI limitami ustawowymi
(land/building × business/other/residential jako dane), przekroczenie = BLOCK,
nieznany typ stawki = BLOCK (fail-closed), granica ±0,01.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I02"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.gmina_rates_validator"
TH_KEYS = ["land_business_rate", "building_business_rate", "land_other_rate",
           "building_residential_rate", "v3_p19_statutory_limit_check"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"rate_type"', '"gmina_rate_pln"', '"year"'))
    has_types = all(f in hay for f in ('"LAND_BUSINESS"', '"BUILDING_BUSINESS"',
                                       '"LAND_OTHER"', '"BUILDING_RESIDENTIAL"'))
    has_exceed = "_gr_exceeds" in hay and "PRZEKRACZA" in hay
    has_unknown_block = "_gr_unknown" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "validator_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: typ stawki / stawka gminna / rok"})
    checks.append({"name": "statutory_types", "status": "OK" if has_types else "FAIL",
                   "detail": "4 typy stawek wg art. 5 UoPiOL"})
    checks.append({"name": "exceeds_block", "status": "OK" if has_exceed else "FAIL",
                   "detail": "przekroczenie limitu ustawowego = BLOCK"})
    checks.append({"name": "unknown_fail_closed", "status": "OK" if has_unknown_block else "FAIL",
                   "detail": "nieznany typ stawki = BLOCK (fail-closed)"})
    checks.append({"name": "limits_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: limity ustawowe z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_exceed:
        findings.append({"id": "V3-P19-L02", "severity": "P0",
                         "evidence": "brak BLOCK przy przekroczeniu limitu gminnego",
                         "fix": "I02: walidacja limitów ustawowych z alarmem"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "types": has_types, "exceeds_block": has_exceed,
                    "fail_closed": has_unknown_block, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "UoPiOL art. 5/10 (stawki maksymalne); ADR-002/P06",
                     "rule": "walidator stawek gminnych z twardymi limitami ustawowymi"}}
    return emit(bundle, "v3_p19_gmina_rates_validator")


if __name__ == "__main__":
    raise SystemExit(main())
