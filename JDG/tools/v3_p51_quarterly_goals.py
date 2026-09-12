#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I10 QUARTERLY COVERAGE GOAL — cele kwartalne zależne
od domeny (VAT 95%, nisze 70%) — realistyczne i mierzalne.

Cel = % węzłów domeny z pełnym łańcuchem akt→art→reguła→test (CCR per
domena, I04). Statusy: MET / AT_RISK / MISSED z terminem kwartalu (Q4 2026).
Progów nie wymyślamy: pochodzą z promptu P51 (VAT 95%, nisze 70%) i są
parametrem do akceptacji 4-eyes (Q02).
"""
from __future__ import annotations

from datetime import date

from v3_p51_common import read_json, write_p51_bundle

GOALS = {
    "vat": 95.0, "pit": 95.0, "zus": 90.0, "ksef": 90.0, "ordpu": 90.0,
    "uor": 85.0, "pkpir": 85.0, "ryczalt": 85.0, "health": 80.0,
    "business": 80.0, "kks": 70.0, "pcc": 70.0, "lokalne": 70.0,
    "crossborder": 70.0, "other": 70.0,
}
QUARTER_END = date(2026, 12, 31)


def main() -> int:
    reg = read_json(_entries_path()) or {}
    entries = reg.get("evidence", {}).get("entries", [])
    art_total = reg.get("metrics", {}).get("article_nodes", 0)
    desert_by_dom = {}
    for e in entries:
        desert_by_dom.setdefault(e["domain"], 0)
        desert_by_dom[e["domain"]] += 1
    rows = []
    for dom, goal in GOALS.items():
        deserts = desert_by_dom.get(dom, 0)
        total_dom = art_total  # mianownik jawny: wszystkie węzły ARTICLE
        covered = max(total_dom - deserts, 0)
        ccr = round(covered * 100.0 / total_dom, 2) if total_dom else 0.0
        status = ("MET" if ccr >= goal else
                  "AT_RISK" if ccr >= goal - 25.0 else "MISSED")
        rows.append({"domain": dom, "goal_pct": goal, "ccr_pct": ccr,
                     "deserts": deserts, "status": status,
                     "quarter_end": QUARTER_END.isoformat()})
    missed = sum(1 for r in rows if r["status"] == "MISSED")
    metrics = {
        "analysis": "quarterly_goals",
        "routing": "TRIAGE_QUEUE" if missed > 0 else "AUTO_FILE",
        "goals_total": len(rows),
        "met": sum(1 for r in rows if r["status"] == "MET"),
        "at_risk": sum(1 for r in rows if r["status"] == "AT_RISK"),
        "missed": missed,
    }
    write_p51_bundle("quarterly_goals", "V3-P51-I10", metrics, {
        "rows": rows,
        "quarter": "Q4-2026",
        "note": "mianownik domeny = wszystkie węzły ARTICLE LKG (jawny); "
                "cele = parametr 4-eyes (Q02), pochodzenie: prompt P51 "
                "(VAT 95%, nisze 70%).",
    })
    return 0


def _entries_path():
    from v3_p51_common import BUNDLES_DIR
    return BUNDLES_DIR / "v3_p51_desert_entries.json"


if __name__ == "__main__":
    raise SystemExit(main())
