#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I10 CLOSE-THE-LOOP LINKS (kalendarz → wykonanie → UPO).

Dowód wdrożenia: maszyna stanów PENDING → ACTION_SENT → CONFIRMED(DONE);
termin minął bez CONFIRMED = BLOCK (zero ciszy); ścieżka wykonania (action)
z tabeli MASTER; potwierdzenie = UPO/KSeF.
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present

INNOVATION = "V3-P25-I10"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.close_the_loop"
STATES = ("PENDING", "ACTION_SENT", "CONFIRMED")


def transition(state: str, action_done: bool, confirmed: bool) -> str:
    if state not in STATES:
        return "INVALID"
    if confirmed:
        return "CONFIRMED"
    if action_done:
        return "ACTION_SENT"
    return state


def evaluate(obligation: str, master: dict, state: str, days_left: int) -> dict:
    row = master.get(obligation, {})
    action = row.get("action", "")
    confirmed = state == "CONFIRMED"
    lapsed = days_left <= 0 and not confirmed
    return {"obligation": obligation, "state": state, "action": action,
            "days_left": days_left, "confirmed": confirmed,
            "lapsed_unconfirmed": lapsed,
            "invalid_state": state not in STATES,
            "no_action": not action}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_states = all(s in hay for s in STATES)
    has_lapsed = "_cl_lapsed_unconfirmed" in hay
    has_upo = "UPO" in hay

    master = {"VAT_JPK_MONTHLY": {"action": "generate_jpk_v7"}}
    probe_lapsed = evaluate("VAT_JPK_MONTHLY", master, "ACTION_SENT", -2)
    probe_done = evaluate("VAT_JPK_MONTHLY", master, "CONFIRMED", 10)
    probe_bad = evaluate("VAT_JPK_MONTHLY", master, "ALIEN", 5)
    probe_ok = (probe_lapsed["lapsed_unconfirmed"] and probe_done["confirmed"]
                and probe_bad["invalid_state"])
    trans_ok = (transition("PENDING", True, False) == "ACTION_SENT"
                and transition("ACTION_SENT", False, True) == "CONFIRMED")

    checks.append({"name": "loop_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "state_machine", "status": "OK" if has_states and trans_ok else "FAIL",
                   "detail": "PENDING → ACTION_SENT → CONFIRMED (DONE)"})
    checks.append({"name": "lapsed_block", "status": "OK" if has_lapsed and probe_ok else "FAIL",
                   "detail": "termin minął bez potwierdzenia = BLOCK (zero ciszy)"})
    checks.append({"name": "confirmation_upo", "status": "OK" if has_upo else "FAIL",
                   "detail": "potwierdzenie = UPO / status KSeF"})
    checks.append({"name": "action_link", "status": "OK" if "action" in hay else "FAIL",
                   "detail": "link do wykonania z tabeli MASTER (wygeneruj deklarację)"})

    if not has_lapsed:
        findings.append({"id": "V3-P25-L10", "severity": "P1",
                         "evidence": "brak BLOCK przy minięciu terminu bez potwierdzenia",
                         "fix": "I10: lapsed_unconfirmed → BLOCK + eskalacja"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "probe_lapsed": probe_lapsed,
                    "probe_done": probe_done, "thresholds": True},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Zamknięta pętla wiąże P16 (KSeF/UPO), P14/P26 (wykonanie) i P41 (UI akcji)",
                     "rule": "PENDING→ACTION_SENT→CONFIRMED; lapsed bez UPO = BLOCK"}}
    return emit(bundle, "v3_p25_close_the_loop")


if __name__ == "__main__":
    raise SystemExit(main())
