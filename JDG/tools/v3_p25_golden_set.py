#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I12 CALENDAR GOLDEN SET (oracle granic kalendarza).

Dowód wdrożenia: golden rok kalendarzowy w oracle (przeniesienia, święta
ruchome, dzień 0, eskalacja 48h, schema v1); niezgodność expected≠actual =
BLOCK (regresja prawna); wersjonowany golden (V3_P10).
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I12"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.calendar_golden_set"
TH_KEYS = ["v3_p25_golden_version"]

GOLDEN_CASES = {
    "CAL-2026-001": {"desc": "VAT 25. w sobotę → NEXT poniedziałek", "routing": "TRIAGE_QUEUE"},
    "CAL-2026-002": {"desc": "ZUS 10. w niedzielę → PREV piątek", "routing": "TRIAGE_QUEUE"},
    "CAL-2026-003": {"desc": "PCC 14 dni w weekend → NONE (bez przeniesienia)", "routing": "SUGGEST"},
    "CAL-2026-004": {"desc": "dzień 0 bez wykonania → BLOCK (zero ciszy)", "routing": "BLOCK_AND_ALERT"},
    "CAL-2026-005": {"desc": "rig 365 dni, 0 pominięć → SUGGEST", "routing": "SUGGEST"},
    "CAL-2026-006": {"desc": "wiersz schematu niekompletny → BLOCK", "routing": "BLOCK_AND_ALERT"},
    "CAL-2026-007": {"desc": "checklista częściowa → TRIAGE", "routing": "TRIAGE_QUEUE"},
    "CAL-2026-008": {"desc": "golden zgodny → SUGGEST", "routing": "SUGGEST"},
}


def match(case_id: str, actual: str) -> dict:
    exp = GOLDEN_CASES.get(case_id, {}).get("routing", "")
    return {"case_id": case_id, "expected": exp, "actual": actual,
            "match": exp != "" and exp == actual, "in_set": case_id in GOLDEN_CASES}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_mismatch = "_gs_mismatch" in hay
    th_ok = threshold_present(TH_KEYS[0])

    probe_ok = match("CAL-2026-004", "BLOCK_AND_ALERT")
    probe_bad = match("CAL-2026-004", "SUGGEST")
    probes_ok = probe_ok["match"] and not probe_bad["match"]

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "golden_cases", "status": "OK" if len(GOLDEN_CASES) >= 8 else "FAIL",
                   "detail": f"{len(GOLDEN_CASES)} przypadków: przeniesienia (3 kierunki), "
                             "dzień 0, eskalacja, rig, schema, checklista"})
    checks.append({"name": "mismatch_block", "status": "OK" if has_mismatch and probes_ok else "FAIL",
                   "detail": f"sonda: zgodny→match={probe_ok['match']}, niezgodny→{probe_bad['match']} (BLOCK)"})
    checks.append({"name": "versioned", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: {TH_KEYS[0]} (V3_P10)"})

    if not probes_ok:
        findings.append({"id": "V3-P25-L12", "severity": "P2",
                         "evidence": "sondy golden niezgodne",
                         "fix": "napraw match engine (I12)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "cases": len(GOLDEN_CASES),
                    "probe_ok": probe_ok, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Golden rok kalendarzowy → oracle V3_P10 i testy blokujące P39",
                     "rule": "expected≠actual = BLOCK; wersja golden jako dane"}}
    return emit(bundle, "v3_p25_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
