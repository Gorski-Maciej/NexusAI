#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I06 CROSS-DOMAIN DESERT SWEEP — pustynie systemowe.

Przekrojowe klasy pustyni łatwe do przeoczenia w podziale domenowym:
odsetki, przedawnienie, ulgi specjalne, KSeF terminy, waluty/kursy (NBP),
korekty i przeniesienia, terminy kalendarzowe (kalendarz P25). Detekcja z
treści artykułów LKG (artykuł→klasa po regex) + status pokrycia z rejestru
I01 (klasy no_rule/rule_no_test = pustynia systemowa aktywna).
"""
from __future__ import annotations

import re

from v3_p51_common import read_json, write_p51_bundle

SYSTEMIC_CLASSES = {
    "odsetki": re.compile(r"odsetk", re.IGNORECASE),
    "przedawnienie": re.compile(r"przedawni", re.IGNORECASE),
    "ulgi_specjalne": re.compile(r"ulga|ulgi|odlicz", re.IGNORECASE),
    "ksef_terminy": re.compile(r"ksef|faktur", re.IGNORECASE),
    "waluty": re.compile(r"walut|kurs|euro|dolar|NBP", re.IGNORECASE),
    "korekty": re.compile(r"korekt", re.IGNORECASE),
    "terminy": re.compile(r"termin", re.IGNORECASE),
}


def main() -> int:
    from v3_p51_common import LEGAL_GRAPH
    graph = read_json(LEGAL_GRAPH) or {}
    reg = read_json(_entries_path()) or {}
    desert_ids = {e["legal_node_id"] for e in
                  reg.get("evidence", {}).get("entries", [])}
    rows, per_class = [], {}
    for n in graph.get("nodes", []):
        if n.get("node_type") != "ARTICLE":
            continue
        label = n.get("article_label", "") or ""
        matched = [c for c, rx in SYSTEMIC_CLASSES.items() if rx.search(label)]
        if not matched:
            continue
        for c in matched:
            per_class.setdefault(c, {"total": 0, "desert": 0})
            per_class[c]["total"] += 1
            if n["legal_node_id"] in desert_ids:
                per_class[c]["desert"] += 1
                rows.append({"legal_node_id": n["legal_node_id"],
                             "act": n.get("act"), "article": n.get("article"),
                             "article_label": label, "systemic_class": c,
                             "desert_class": _desert_class(reg, n)})
    active = {c: v for c, v in per_class.items() if v["desert"] > 0}
    metrics = {
        "analysis": "systemic_sweep",
        "routing": "TRIAGE_QUEUE" if active else "AUTO_FILE",
        "systemic_classes": len(per_class),
        "active_systemic_classes": len(active),
        "systemic_deserts": sum(v["desert"] for v in active.values()),
    }
    write_p51_bundle("systemic_sweep", "V3-P51-I06", metrics, {
        "per_class": per_class,
        "active": active,
        "rows_sample": rows[:40],
        "method": "artykuł→klasa po regexie article_label; pustynia = węzeł "
                  "z rejestru I01 (no_rule / rule_no_test).",
    })
    return 0


def _desert_class(reg: dict, node: dict) -> str:
    for e in reg.get("evidence", {}).get("entries", []):
        if e["legal_node_id"] == node["legal_node_id"]:
            return e["desert_class"]
    return "unknown"


def _entries_path():
    from v3_p51_common import BUNDLES_DIR
    return BUNDLES_DIR / "v3_p51_desert_entries.json"


if __name__ == "__main__":
    raise SystemExit(main())
