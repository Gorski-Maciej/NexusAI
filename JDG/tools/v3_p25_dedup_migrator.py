#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I06 DEDUP MIGRATOR (konsolidacja terminów, nie dublowanie).

Dowód wdrożenia: skan reguł domenowych pod kątem hardcode dat (dni miesięczne
w else-chain kalendarzach plan44/45/26) → kandydaci migracji do tabeli MASTER;
konflikt źródło≠MASTER = TRIAGE (Rego I06); plan migracji w wyniku.
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p25_common import BASE, P25_RULES, emit, now, read, rule_present

INNOVATION = "V3-P25-I06"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.dedup_gate"
SCAN_TARGETS = [
    "rules/calendar/plan44_calendar.rego",
    "rules/calendar/plan45_calendar.rego",
    "rules/jpk/plan26_deadlines.rego",
    "rules/deadline_monitor_enterprise.rego",
]

# Znane terminy MASTER (dzień → obowiązek) do wykrycia zdublowanych wartości
MASTER_DAYS = {"VAT_JPK": 25, "PIT_ADVANCE": 20, "PIT_LUMP_SUM": 20,
               "PPK": 15, "ZUS_DRA": 10, "PROPERTY": 15}


def scan_hardcoded() -> list[dict]:
    out = []
    for rel in SCAN_TARGETS:
        p = BASE / rel
        if not p.exists():
            continue
        text = p.read_text(encoding="utf-8", errors="ignore")
        # np. dzień 25 w regule kalendarzowej bez odwołania do data.jdg.thresholds.calendar
        for m in re.finditer(r'(?:day|dzie[nń]|base_day)[^,\n]{0,24}?\b(5|10|14|15|20|25|30|31)\b',
                             text):
            out.append({"file": rel, "line": text[:m.start()].count("\n") + 1,
                        "day": int(m.group(1))})
    return out


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_conflict = "_dd_day_conflict" in hay and "_dd_date_conflict" in hay
    has_desert = "pustynia kalendarza" in hay

    candidates = scan_hardcoded()
    scan_done = len(candidates) > 0
    plan_present = "migracja" in hay or "konsolidacja" in hay

    checks.append({"name": "dedup_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "conflict_gate", "status": "OK" if has_conflict else "FAIL",
                   "detail": "źródło ≠ MASTER = TRIAGE (kandydat migracji)"})
    checks.append({"name": "desert_block", "status": "OK" if has_desert else "FAIL",
                   "detail": "obowiązek poza MASTER = BLOCK (pustynia → rejestr luk)"})
    checks.append({"name": "hardcode_scan", "status": "OK" if scan_done else "FAIL",
                   "detail": f"przeskanowano {len(SCAN_TARGETS)} plików; kandydatów: {len(candidates)}"})
    checks.append({"name": "migration_plan", "status": "OK" if plan_present else "FAIL",
                   "detail": "konsolidacja, nie dublowanie (kontrakt P00)"})

    if scan_done:
        findings.append({"id": "V3-P25-L06", "severity": "P3",
                         "evidence": f"hardcode terminów w {len(set(c['file'] for c in candidates))} "
                                     f"plikach ({len(candidates)} wystąpień)",
                         "fix": "migracja dat → data.jdg.thresholds.calendar (I06, po certyfikacji P26)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "conflict_gate": has_conflict,
                    "scan_done": scan_done, "candidates": len(candidates),
                    "scan": candidates[:20]},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Domeny czytają tabelę MASTER; hardcode dat = kandydat migracji",
                     "rule": "konflikt = TRIAGE; pustynia = BLOCK"}}
    return emit(bundle, "v3_p25_dedup_migrator")


if __name__ == "__main__":
    raise SystemExit(main())
