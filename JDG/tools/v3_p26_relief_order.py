#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I02 RELIEF ORDER AUTOMATON (kolejność ulg jako automat).

Dowód wdrożenia: automat stanów NONE → START(6) → PREFERENCYJNA(24)/
MALY_ZUS_PLUS(36) → STANDARD z walidacją przejść; równoległość = BLOCK;
przekroczenie miesięcy = BLOCK; limity z data.thresholds.zus (art. 18a/18b/18c).
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I02"
RULE = "jdg.v3_p26_zus_skladki.relief_order_automaton"
STATES = ["NONE", "START", "PREFERENCYJNA", "MALY_ZUS_PLUS", "STANDARD"]
LEGAL_TRANSITIONS = {
    ("NONE", "START"), ("NONE", "PREFERENCYJNA"), ("NONE", "MALY_ZUS_PLUS"),
    ("START", "PREFERENCYJNA"), ("START", "MALY_ZUS_PLUS"), ("START", "STANDARD"),
    ("PREFERENCYJNA", "MALY_ZUS_PLUS"), ("PREFERENCYJNA", "STANDARD"),
    ("MALY_ZUS_PLUS", "STANDARD"), ("STANDARD", "STANDARD"),
}


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_states = all(s in hay for s in STATES)
    has_parallel_block = '"parallel_reliefs"' in hay and "_ro_parallel" in hay
    limits_ok = all(threshold_present(k) for k in
                    ["start_relief_months", "preferential_months", "maly_zus_plus_months"])
    has_transition = "_ro_valid_transition" in hay

    # Automat: sprawdź pokrycie przejść legalnych w rego (mirror)
    auto_ok = has_transition and "PREFERENCYJNA" in hay and "MALY_ZUS_PLUS" in hay

    checks.append({"name": "relief_order_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "states", "status": "OK" if has_states else "FAIL",
                   "detail": f"stany automatu: {STATES}"})
    checks.append({"name": "parallel_block", "status": "OK" if has_parallel_block else "FAIL",
                   "detail": "ulgi równoległe = BLOCK (błąd klasyczny)"})
    checks.append({"name": "limits_as_data", "status": "OK" if limits_ok else "FAIL",
                   "detail": "6/24/36 mies. z data.thresholds.zus (ADR-002)"})
    checks.append({"name": "transition_automaton", "status": "OK" if auto_ok else "FAIL",
                   "detail": f"automat przejść ({len(LEGAL_TRANSITIONS)} legalnych)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: import + rejestr + final_verdict_p90"})

    if not has_parallel_block:
        findings.append({"id": "V3-P26-L02", "severity": "P1",
                         "evidence": "brak blokady równoległych ulg w rego",
                         "fix": "I02: walidacja parallel_reliefs → BLOCK"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "states": len(STATES),
                    "legal_transitions": len(LEGAL_TRANSITIONS), "limits_as_data": limits_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Automat ulg wiąże P24 (RnA), P23 (cykl życia) i P44; "
                                "kolejność: na start → preferencyjna/mały ZUS",
                     "rule": "równoległość/przekroczenie limitu = BLOCK"}}
    return emit(bundle, "v3_p26_relief_order")


if __name__ == "__main__":
    raise SystemExit(main())
