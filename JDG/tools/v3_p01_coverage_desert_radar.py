#!/usr/bin/env python3
"""
NexusAI JDG — COVERAGE DESERT RADAR (V3-P01-I07)
=================================================
Mapa pustyń pokrycia per domena z planem zasiedlenia i alertem tygodniowym.
Wykrywa obszary prawa, w których NIE MA reguł (reverse coverage deserts) —
podstawa alertu „prawo istnieje, system go nie zna”.

Czytaj:  bundles/legal_graph.json (nodes, by_act), bundles/coverage_deserts.json
Pisz:    bundles/v3_p01_coverage_desert_radar.json

Usage:
  python v3_p01_coverage_desert_radar.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
DESERTS = BASE_DIR / "bundles" / "coverage_deserts.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_coverage_desert_radar.json"

ACT_DOMAIN = [
    ("vat", r"towarów i usług|VAT"),
    ("pit", r"PIT|dochodowym od osób fizycznych"),
    ("ryczalt", r"zryczałtowanym"),
    ("zus", r"ubezpieczeń społecznych|SUS|zdrowotn"),
    ("uor", r"rachunkowości"),
    ("ord", r"Ordynacja"),
    ("business", r"przedsiębiorc"),
    ("kks", r"karny skarbowy"),
    ("pkpir", r"PKPiR|księgi przychodów"),
]


def domain_of(act: str) -> str:
    for dom, pat in ACT_DOMAIN:
        if re.search(pat, act, re.I):
            return dom
    return "other"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    deserts_data = json.loads(DESERTS.read_text(encoding="utf-8")) if DESERTS.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])
    desert_ids = set()
    sample = deserts_data.get("sample", [])
    for s in sample:
        if isinstance(s, dict) and s.get("legal_node_id"):
            desert_ids.add(s["legal_node_id"])

    by_domain: dict[str, dict] = defaultdict(lambda: {"nodes": 0, "desert": 0})
    for n in nodes:
        dom = domain_of(str(n.get("act", "")))
        by_domain[dom]["nodes"] += 1
        if n.get("legal_node_id") in desert_ids or not (n.get("rule_ids") or n.get("rules")):
            by_domain[dom]["desert"] += 1

    radar = []
    for dom, d in sorted(by_domain.items()):
        desert_pct = round(d["desert"] / d["nodes"] * 100, 1) if d["nodes"] else 0.0
        radar.append({
            "domain": dom,
            "nodes": d["nodes"],
            "desert_nodes": d["desert"],
            "desert_pct": desert_pct,
            "severity": "ALARM" if desert_pct > 50 else ("UWAGA" if desert_pct > 20 else "OK"),
            "settlement_plan": f"domknąć {d['desert']} węzłów przez V3-P01-I02/I06 (SHADOW+4-eyes)",
        })

    return {
        "innovation": "V3-P01-I07",
        "generated_at": now(),
        "by_domain": radar,
        "weekly_alert": {"cadence": "tydzień", "threshold": "nowy węzeł materialny bez reguły = alert",
                         "channel": "CI + raport V3"},
        "graph_nodes": len(nodes),
        "desert_catalog_sample": len(sample),
        "contract": "pustynia pokrycia jako bramka CI (V3-P01-I08): nowy przepis w Bbb bez reguły = fail",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Coverage Desert Radar (V3-P01-I07)")
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
        doms = ", ".join(f"{r['domain']}={r['desert_pct']}%" for r in data["by_domain"])
        print(f"V3-P01-I07 Coverage Desert Radar: {doms}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
