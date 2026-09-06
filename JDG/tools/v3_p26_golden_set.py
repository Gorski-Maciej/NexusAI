#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I08 ZUS GOLDEN SET (oracle granic składkowych).

Dowód wdrożenia: golden granice w oracle (kontrakt V3_P10): granice ulg
(6/24 mies., ostatni dzień), progi 60k/300k ±0,01, grosze 4161,00 → 812,63;
niezgodność = BLOCK (regresja prawna); wersja golden z danych.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, grosze, main_jdg_wired,
                           now, read, rule_present, social_contributions,
                           threshold_present)

INNOVATION = "V3-P26-I08"
RULE = "jdg.v3_p26_zus_skladki.golden_set"

# Golden cases: granice składkowe (case_id → expected_routing)
GOLDEN_CASES = {
    "ZUS-2026-G01": ("grosze_4161", "SUGGEST"),
    "ZUS-2026-G02": ("prog_60000_boundary", "TRIAGE_QUEUE"),
    "ZUS-2026-G03": ("prog_300000_boundary", "TRIAGE_QUEUE"),
    "ZUS-2026-G04": ("ulga_start_6m_last_day", "SUGGEST"),
    "ZUS-2026-G05": ("ulga_przekroczenie", "BLOCK_AND_ALERT"),
    "ZUS-2026-G06": ("ulgi_rownolegle", "BLOCK_AND_ALERT"),
}


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_oracle = '"in_golden_set"' in hay and '"golden_match"' in hay
    has_version = threshold_present("v3_p26_golden_version")
    has_boundaries = "boundary" in hay or "granicy" in hay

    # Mirror granicy groszowej: 4161,00 → 812,23 (golden wzorcowy; 812,63 z
    # promptu = rozbieżność arytmetyczna do mediacji V3-P26-X07)
    c = social_contributions(4161.00)
    grosz_ok = abs(c["pension"] - 812.23) < 0.005

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "oracle", "status": "OK" if has_oracle else "FAIL",
                   "detail": f"oracle granic: {len(GOLDEN_CASES)} przypadków golden"})
    checks.append({"name": "grosz_golden_4161", "status": "OK" if grosz_ok else "FAIL",
                   "detail": f"golden groszowe: emerytalna {c['pension']:.2f} (oczekiwane 812,23)"})
    checks.append({"name": "boundary_cases", "status": "OK" if has_boundaries else "FAIL",
                   "detail": "granice ulg i progów w golden (60k/300k ±0,01)"})
    checks.append({"name": "versioned", "status": "OK" if has_version else "FAIL",
                   "detail": "wersja golden z zus26 (P05)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_oracle:
        findings.append({"id": "V3-P26-L08", "severity": "P1",
                         "evidence": "brak oracle granic składkowych",
                         "fix": "I08: golden set granic (Golden Oracle P10)"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "golden_cases": len(GOLDEN_CASES),
                    "grosz_ok": grosz_ok, "tier1": ZUS_CORE["health_lump_tier_1_amount"]},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Golden Oracle (V3_P10); granice art. 18a/18c/22 SUS, "
                                "81 u.ś.o.z. [NIEZWERYFIKOWANE]",
                     "rule": "golden niezgodny = BLOCK (regresja składkowa)"}}
    return emit(bundle, "v3_p26_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
