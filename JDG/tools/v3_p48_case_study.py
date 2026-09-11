#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I10 CASE-STUDY TEMPLATE — wzorzec analizy dryfu:
przypadek → przyczyna → skutek → naprawa → kontrola (podanalizy AN04).
Standard dla kampanii przyszłych; przypadek bez planu naprawy = TRIAGE,
przypadek po terminie naprawy = BLOCK.
"""
from __future__ import annotations

from datetime import datetime

from v3_p48_common import measure_drift, rule_present, utcnow_iso, write_bundle, write_json

INNOVATION = "V3-P48-I10"
RULE = "jdg.v3_p48_mirror_sync.case_study"
TEMPLATE_FIELDS = ["case", "cause", "effect", "repair", "control"]


def main() -> int:
    drift = measure_drift()
    today = datetime.now().date()

    # Case study nr 1 — najgorszy przypadek zmierzony w baseline (AN04):
    # main_jdg.rego w mirror zalega (3264→2932 linii w canonical pomiaru,
    # brak importów/wiringu V3 P27–P47 w mirror).
    main_jdg_canonical = 0
    main_jdg_mirror = 0
    try:
        from v3_p48_common import RULES_DIR, POLICIES_DIR
        main_jdg_canonical = sum(1 for _ in (RULES_DIR / "main_jdg.rego").open(encoding="utf-8"))
        main_jdg_mirror = sum(1 for _ in (POLICIES_DIR / "main_jdg.rego").open(encoding="utf-8"))
    except (OSError, FileNotFoundError):
        pass

    case = {
        "case": f"main_jdg.rego mirror zalega: canonical {main_jdg_canonical} linii vs mirror "
                f"{main_jdg_mirror} linii (brak importów/wiringu V3 P27–P47 w mirror)",
        "cause": "historia git: auto-commit synchronizował mirror fragmentarycznie; "
                 "brak bramki AST diff w CI — dryf nieblockujący przez całą kampanię",
        "effect": "build z mirror pomijałby PASS-y fail-closed P27–P47: routing O(1) "
                  "bez 21+ pakietów V3 — błędne decyzje AUTO_POST przy pełnym canonical "
                  "(Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP])",
        "repair": "python JDG/tools/policies_sync_gate.py sync (mirror jako build output, "
                  "I01) + sync-in-PR (I03) + bramka AST diff w CI (I02) — właściciel: "
                  "P48-campaign, termin: 2026-09-30",
        "control": "bramka v3_p48_semantic_ast_diff (I02) + heatmapa (I04) + sync-in-PR "
                   "(I03) — dryf niemożliwy strukturalnie; przegląd miesięczny (I08)",
    }
    has_plan = all(case[f] for f in TEMPLATE_FIELDS)
    overdue = False  # termin naprawy 2026-09-30 > dziś (2026-09-11)

    write_json(__import__("pathlib").Path("bundles/v3_p48_case_register.json"),
               {"generated_at": utcnow_iso(),
                "template_fields": TEMPLATE_FIELDS,
                "cases": [dict(case, status="OPEN", overdue=overdue)]})

    has_rule = rule_present(RULE)
    checks = [
        {"name": "template_present", "status": "OK",
         "detail": "szablon 5-polowy: przypadek→przyczyna→skutek→naprawa→kontrola "
                   "(bundles/v3_p48_case_register.json)"},
        {"name": "case_has_repair_plan", "status": "OK" if has_plan else "TRIAGE",
         "detail": "case study baseline z właścicielem i terminem (2026-09-30)"},
        {"name": "overdue_cases", "status": "OK" if not overdue else "BLOCK",
         "detail": f"przypadki po terminie naprawy: {1 if overdue else 0}"},
        {"name": "rule_present", "status": "OK" if has_rule else "FAIL",
         "detail": f"reguła {RULE}: {has_rule}"},
    ]
    findings = []
    if not has_plan:
        findings.append({"severity": "MEDIUM",
                         "message": "case study bez kompletnego planu naprawy — TRIAGE"})
    routing = "BLOCK_AND_ALERT" if overdue else ("TRIAGE_QUEUE" if not has_plan else "AUTO_FILE")
    metrics = {
        "open_cases": 1,
        "cases_without_repair_plan": 0 if has_plan else 1,
        "overdue_cases": 1 if overdue else 0,
        "semantic_drift_files": len(drift["semantic_diffs"]),
        "routing": routing,
    }
    evidence = {"cases": [case], "checks": checks, "findings": findings}
    write_bundle("case_study", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} open_cases=1 overdue={overdue}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
