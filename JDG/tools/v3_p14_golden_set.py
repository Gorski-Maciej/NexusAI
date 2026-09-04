#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I10 RELIEF GOLDEN SET (P10 golden oracle).

Zbiór wzorcowych decyzji ulgowych z granicami limitów i wieku — dla testów
regresji i bramek blokujących merge (P39): kwota wolna 30 000 (29 999,99 /
30 000 / 30 000,01), wiek 25/26 (młodzi), PIT-0 85 528, termo 53 000.
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P14-I10"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.relief_golden_set", hay)
    cases = {c: f'"{c}"' in hay for c in ["tax_free_boundary", "young_age_boundary",
                                          "pit0_income_boundary", "thermo_limit_boundary"]}
    has_unknown_gate = "golden_unknown_case" in hay and "recognized" in hay
    missing = thresholds_missing(["tax_free_amount", "pit_relief_shared_limit",
                                  "pit_thermo_limit", "young_relief_max_age"])

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła relief_golden_set: {has_rule}"})
    checks.append({"name": "golden_cases", "status": "OK" if all(cases.values()) else "FAIL",
                   "detail": "golden cases: " + ", ".join(f"{k}={v}" for k, v in cases.items())})
    checks.append({"name": "unknown_gate", "status": "OK" if has_unknown_gate else "FAIL",
                   "detail": "nieznany golden case → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów granic: {missing or 'BRAK'}"})

    if not all(cases.values()):
        findings.append({"id": "V3-P14-L10", "severity": "P2",
                         "evidence": "golden set nie pokrywa wszystkich granic limitów/wieku",
                         "fix": "I10: dodać przypadki graniczne (30k, 26 lat, 85 528, 53k) do golden oracle"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "cases": cases, "unknown_gate": has_unknown_gate,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P10 (golden oracle), P39 (bramki CI blokujące merge), P05 (temporalność)",
                     "rule": "golden decyzje ulgowe z granicami limitów i wieku (testy regresji)"}}
    return emit(bundle, "v3_p14_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
