#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I08 DESERT HEATMAP BY MONEY IMPACT — mapa cieplna
pustyni ważona przepływem kwot.

Ryzyko pustyni widoczne liczbowo: score pieniężny = risk_score (I02) × waga
przepływu domeny (udział reguł domeny w silniku jako proxy wolumenu
operacji — jawne założenie, [ZAŁOŻENIE]: brak danych przepływów w repo).
Wyjście: ranking kwadrantów cieplnych per domena (HIGH/MED/LOW/COLD) +
JSON z datagridem dla P37 dashboardu.
"""
from __future__ import annotations

from collections import Counter

from v3_p51_common import read_json, write_p51_bundle


def main() -> int:
    reg = read_json(_entries_path()) or {}
    entries = reg.get("evidence", {}).get("entries", [])
    dom_rules = Counter(e["domain"] for e in entries)
    total = sum(dom_rules.values()) or 1
    # Proxy wolumenu: udział domeny w liczbie pustyni (im więcej pustyni w
    # domenie codziennej, tym większy przepływ kwot przez obszar bez reguły).
    rows, quadrants = [], {"HIGH": 0, "MED": 0, "LOW": 0, "COLD": 0}
    for e in entries:
        flow = dom_rules[e["domain"]] / total
        money = e["risk_score"] * (1.0 + flow)
        q = ("HIGH" if money >= 60 else
             "MED" if money >= 30 else
             "LOW" if money >= 15 else "COLD")
        quadrants[q] += 1
        rows.append({"legal_node_id": e["legal_node_id"],
                     "domain": e["domain"], "article": e["article"],
                     "risk_score": e["risk_score"],
                     "flow_proxy": round(flow, 4),
                     "money_impact_score": round(money, 2),
                     "quadrant": q})
    rows.sort(key=lambda r: -r["money_impact_score"])
    metrics = {
        "analysis": "desert_heatmap",
        "routing": "TRIAGE_QUEUE" if quadrants["HIGH"] > 0 else "AUTO_FILE",
        "scored_deserts": len(rows),
        "quadrants": quadrants,
        "top_quadrant": max(quadrants, key=quadrants.get),
        "assumption_flow_proxy": "[ZAŁOŻENIE] proxy przepływu = udział domeny "
                                 "w pustyniach (brak danych przepływów w repo).",
    }
    write_p51_bundle("desert_heatmap", "V3-P51-I08", metrics, {
        "top25": rows[:25],
        "quadrant_thresholds": {"HIGH": ">=60", "MED": ">=30",
                                "LOW": ">=15", "COLD": "<15"},
        "method": "money = risk_score(I02) × (1 + flow_proxy).",
    })
    return 0


def _entries_path():
    from v3_p51_common import BUNDLES_DIR
    return BUNDLES_DIR / "v3_p51_desert_entries.json"


if __name__ == "__main__":
    raise SystemExit(main())
