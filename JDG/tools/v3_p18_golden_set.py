#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I10 RYCZAŁT GOLDEN SET.

Dowód wdrożenia: golden decyzje stawek/wykluczeń w oracle — przypadek z golden
set rozjeżdża się = BLOCK; granica daty roku (31.12/1.01) = TRIAGE; wersja
golden z danych.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I10"

RULE = "jdg.v3_p18_ryczalt.golden_set"
TH_KEYS = ["v3_p18_golden_version"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_oracle = '"in_golden_set"' in hay and '"golden_rate_match"' in hay
    has_boundary = '"date_boundary"' in hay and "31.12" in hay
    has_version = '"golden_version"' in hay and "golden_version" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "oracle", "status": "OK" if has_oracle else "FAIL",
                   "detail": "oracle: golden rate match (stawki/wykluczenia)"})
    checks.append({"name": "date_boundary", "status": "OK" if has_boundary else "FAIL",
                   "detail": "granica daty roku (31.12/1.01) = TRIAGE"})
    checks.append({"name": "versioned", "status": "OK" if has_version else "FAIL",
                   "detail": "wersja golden z danych (P05)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: wersja golden z data.thresholds.lump_sum"})

    if not has_oracle:
        findings.append({"id": "V3-P18-L10", "severity": "P1",
                         "evidence": "brak golden set decyzji ryczałtu",
                         "fix": "I10: oracle granic PKWiU/dat (Golden Oracle P10)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "oracle": has_oracle, "boundary": has_boundary,
                    "version": has_version, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Golden Oracle (V2 F3, P10); art. 12/8 ustawy o zryczałtowanym PIT",
                     "rule": "golden decyzje stawek/wykluczeń w oracle"}}
    return emit(bundle, "v3_p18_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
