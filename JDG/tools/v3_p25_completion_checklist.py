#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I09 COMPLETION CHECKLISTS (zero częściowego wykonania).

Dowód wdrożenia: checklista per obowiązek z tabeli MASTER (deklaracja +
zapłata + ewidencja); brak pozycji = TRIAGE; pusta checklista w MASTER = BLOCK.
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present

INNOVATION = "V3-P25-I09"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.completion_checklist"


def check(obligation: str, master: dict, reported: list[str]) -> dict:
    row = master.get(obligation, {})
    items = row.get("checklist", [])
    missing = [i for i in items if i not in reported]
    return {"obligation": obligation, "master": items, "reported": reported,
            "missing": missing, "complete": len(items) > 0 and not missing,
            "empty_master": obligation in master and len(items) == 0,
            "unknown": obligation not in master}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_missing = "_ck_missing" in hay
    has_empty_gate = "pustą checklistę" in hay or "pusta checklista" in hay

    master = {"VAT_JPK_MONTHLY": {"checklist": ["JPK_V7", "ZAPLATA"]}}
    probe_partial = check("VAT_JPK_MONTHLY", master, ["JPK_V7"])
    probe_ok = check("VAT_JPK_MONTHLY", master, ["JPK_V7", "ZAPLATA"])
    probe_unknown = check("ALIEN", master, [])
    probe_ok_all = (probe_partial["missing"] == ["ZAPLATA"]
                    and probe_ok["complete"] and probe_unknown["unknown"])

    checks.append({"name": "checklist_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "diff_engine", "status": "OK" if probe_ok_all else "FAIL",
                   "detail": f"sonda: partial→{probe_partial['missing']}, ok→complete={probe_ok['complete']}, "
                             f"unknown→{probe_unknown['unknown']}"})
    checks.append({"name": "partial_is_triage", "status": "OK" if has_missing else "FAIL",
                   "detail": "brak pozycji checklisty = TRIAGE (zero częściowego wykonania)"})
    checks.append({"name": "empty_master_block", "status": "OK" if has_empty_gate else "FAIL",
                   "detail": "pusta checklista w MASTER = BLOCK (pustynia)"})
    checks.append({"name": "zero_silence_link", "status": "OK" if "kompletna" in hay else "FAIL",
                   "detail": "komplet → obowiązek domknięty w całości (spójne z I03)"})

    if not has_missing:
        findings.append({"id": "V3-P25-L09", "severity": "P2",
                         "evidence": "brak różnicowania checklisty (master vs reported)",
                         "fix": "I09: missing_items + TRIAGE"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "probe_partial": probe_partial,
                    "probe_ok": probe_ok, "thresholds": True},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Komplet = deklaracja + zapłata + ewidencja; kontrakt z P16/P14/P26",
                     "rule": "checklist z tabeli MASTER; częściowe wykonanie nigdy nie jest DONE"}}
    return emit(bundle, "v3_p25_completion_checklist")


if __name__ == "__main__":
    raise SystemExit(main())
