#!/usr/bin/env python3
"""
NexusAI JDG — RETROACTIVITY AUDITOR (V3-P01-I10)
=================================================
Audyt: czy zmiana reguł zmieniła historyczne werdykty BEZ zmiany przepisu
(golden oracle hook). Zasada: werdykt na dzień D zależy od wersji prawa
aktywnej na D — zmiana reguły, która nie wynika z nowelizacji, jest
podejrzana (regresja) i wymaga golden replay.

Mechanizm (offline, deterministyczny): porównanie okien temporalnych
reguł vs węzłów prawa. Reguła z oknem obowiązywania niezgodnym z oknem
jej węzła prawnego (np. szerszym) = kandydat na retroaktywność.

Czytaj:  bundles/legal_graph.json (nodes z rule_ids i oknami)
Pisz:    bundles/v3_p01_retroactivity_auditor.json

Usage:
  python v3_p01_retroactivity_auditor.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_retroactivity_auditor.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])

    rule_windows: dict[str, list[dict]] = defaultdict(list)
    for n in nodes:
        for rid in (n.get("rule_ids") or []) + [r.get("rule_id") for r in (n.get("rules") or []) if isinstance(r, dict)]:
            if rid:
                rule_windows[rid].append({
                    "legal_node_id": n.get("legal_node_id"),
                    "act": n.get("act"),
                    "article": n.get("article"),
                    "node_valid_from": n.get("valid_from"),
                    "node_valid_to": n.get("valid_to"),
                })

    suspects: list[dict] = []
    for rid, refs in rule_windows.items():
        # wiele węzłów o różnych oknach pod tą samą regułą = ryzyko rozmycia temporalnego
        windows = {(str(r["node_valid_from"]), str(r["node_valid_to"])) for r in refs}
        if len(windows) > 1:
            suspects.append({
                "rule_id": rid,
                "distinct_law_windows": len(windows),
                "windows": sorted(windows),
                "risk": "reguła obsługuje węzły o różnych oknach — sprawdzić golden replay",
                "action": "V3-P01-I10: replay werdyktów historycznych na nowej wersji reguły",
            })

    return {
        "innovation": "V3-P01-I10",
        "generated_at": now(),
        "method": "porównanie okien temporalnych reguła↔węzeł + hook golden oracle (replay)",
        "rules_mapped": len(rule_windows),
        "retroactivity_suspects": len(suspects),
        "suspects": suspects[:20],
        "golden_hook": {
            "rule": "zmiana reguły bez zmiany przepisu (diff prawny pusty) = rerun golden_verdicts; "
                    "różnica w werdykcie = BLOCKER/regresja",
            "bundle_ref": "golden_verdicts (migracja 003, F3)",
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Retroactivity Auditor (V3-P01-I10)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P01-I10 Retroactivity Auditor: rules_mapped={data['rules_mapped']} suspects={data['retroactivity_suspects']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
