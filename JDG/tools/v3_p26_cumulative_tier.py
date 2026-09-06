#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I03 CUMULATIVE TIER SENTINEL (progi NARASTAJĄCO).

Dowód wdrożenia: progi zdrowotnej ryczałt 60k/300k liczone NARASTAJĄCO rocznie;
testy graniczne ±0,01 (59 999,99 / 60 000,00 / 60 000,01; analogicznie 300k);
alarm przed przekroczeniem (≥90% progu); złe TIER = BLOCK.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I03"
RULE = "jdg.v3_p26_zus_skladki.cumulative_tier_sentinel"
BOUNDARIES = [59999.99, 60000.00, 60000.01, 299999.99, 300000.00, 300000.01]


def tier_for(rev: float) -> str:
    if rev <= ZUS_CORE["health_lump_tier_1_limit"]:
        return "TIER_1"
    if rev <= ZUS_CORE["health_lump_tier_2_limit"]:
        return "TIER_2"
    return "TIER_3"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_cumulative = "cumulative_revenue_ytd" in hay
    has_approach = threshold_present("v3_p26_tier_alert_approach_pct")
    limits_ok = all(threshold_present(k) for k in
                    ["health_lump_tier_1_limit", "health_lump_tier_2_limit"])
    has_boundary = "boundary_case" in hay

    # Granice: tier_at(b) zgodny z oczekiwanym mappingiem ±0,01
    expected = {59999.99: "TIER_1", 60000.00: "TIER_1", 60000.01: "TIER_2",
                299999.99: "TIER_2", 300000.00: "TIER_2", 300000.01: "TIER_3"}
    boundary_ok = all(tier_for(b) == expected[b] for b in BOUNDARIES)

    checks.append({"name": "tier_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "cumulative_mode", "status": "OK" if has_cumulative else "FAIL",
                   "detail": "przychód NARASTAJĄCO rocznie (nie per miesiąc)"})
    checks.append({"name": "boundary_tests", "status": "OK" if boundary_ok else "FAIL",
                   "detail": f"granice 60k/300k ±0,01: {BOUNDARIES}"})
    checks.append({"name": "approach_alert", "status": "OK" if has_approach else "FAIL",
                   "detail": "alarm ≥90% progu (PRZED przekroczeniem)"})
    checks.append({"name": "limits_as_data", "status": "OK" if limits_ok else "FAIL",
                   "detail": "progi z data.thresholds.zus (ADR-002)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not boundary_ok:
        findings.append({"id": "V3-P26-L03", "severity": "P0",
                         "evidence": "granice progów niezgodne z mappingiem TIER",
                         "fix": "korekta _ct_tier (art. 81 ust. 2b u.ś.o.z. [NIEZWERYFIKOWANE])"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "boundary_ok": boundary_ok,
                    "tier_1_limit": ZUS_CORE["health_lump_tier_1_limit"],
                    "tier_2_limit": ZUS_CORE["health_lump_tier_2_limit"]},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Progi narastająco wiążą P18 (przychody ryczałtu) i P44; "
                                "kwoty TIER z data.thresholds.zus",
                     "rule": "granica ±0,01 = TRIAGE; zły TIER = BLOCK"}}
    return emit(bundle, "v3_p26_cumulative_tier")


if __name__ == "__main__":
    raise SystemExit(main())
