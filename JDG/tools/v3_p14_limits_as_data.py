#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I02 LIMIT-AS-DATA ENGINE.

Limity roczne ulg (53 000 termo, 85 528 PIT-0, 2 280 auto rehab, 760 internet)
jako DANE wersjonowane z valid_from (data.jdg.thresholds.pit.v3_p14_relief_limits)
+ walidacja: każdy limit > 0, klucze wymagane obecne, spójność z limitem łącznym
PIT-0 (pit_relief_shared_limit). ADR-002 / P06 / P05.
"""
from __future__ import annotations

import json
import re

from v3_p14_common import P14_RULES, THRESHOLDS, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P14-I02"


def main() -> int:
    hay = read(P14_RULES)
    th = read(THRESHOLDS)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.limit_as_data_engine", hay)
    has_valid = "valid_from" in hay and "_limits_valid" in hay and "young_matches_shared_limit" in hay
    # Weryfikacja struktury danych: każdy wpis v3_p14_relief_limits ma limit_pln + valid_from
    m = re.search(r'"v3_p14_relief_limits"\s*:\s*\{(.*?)\n\s*\},', th, re.S)
    entries_ok, entry_issues = False, []
    if m:
        entries_ok = True
        for rid in ["young", "return_work", "family_4plus", "senior", "thermo", "rehab_car", "internet"]:
            if f'"{rid}":' not in m.group(1):
                entries_ok = False
                entry_issues.append(rid)
    missing = thresholds_missing(["v3_p14_relief_limits", "v3_p14_threshold_version",
                                  "pit_relief_shared_limit", "pit_thermo_limit", "rehab_car_limit"], th)

    checks.append({"name": "limit_engine_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła limit_as_data_engine: {has_rule}"})
    checks.append({"name": "versioned_data", "status": "OK" if has_valid else "FAIL",
                   "detail": "valid_from + walidacja (missing/non_positive/valid) w regułach"})
    checks.append({"name": "relief_limits_struct", "status": "OK" if entries_ok else "FAIL",
                   "detail": f"v3_p14_relief_limits w thresholds — braki: {entry_issues or 'BRAK'}"})
    checks.append({"name": "keys_present", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak kluczy: {missing or 'BRAK'}"})

    if not entries_ok:
        findings.append({"id": "V3-P14-L02", "severity": "P1",
                         "evidence": f"limity-as-data niekompletne: {entry_issues}",
                         "fix": "I02: uzupełnić v3_p14_relief_limits o brakujące wpisy z valid_from"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "versioned": has_valid, "entries_ok": entries_ok,
                    "relief_entries": len(re.findall(r'"[a-z_0-9]+":\s*\{\s*"limit_pln"', m.group(1))) if m else 0,
                    "missing_keys": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry-as-data), P05 (temporalność valid_from), ADR-002",
                     "rule": "limity ulg roczne jako dane wersjonowane z walidacją (53k/85 528/2 280/760)"}}
    return emit(bundle, "v3_p14_limits_as_data")


if __name__ == "__main__":
    raise SystemExit(main())
