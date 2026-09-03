#!/usr/bin/env python3
"""
NexusAI JDG — REVERSE COVERAGE SENTINEL (V3-P01-I02)
=====================================================
Automat: każdy węzeł materialny prawa (artykuł z wartością/terminem/stawką)
bez co najmniej jednej reguły → issue z priorytetem per severity przepisu.

Kierunek odwrotny do forward coverage: nie „czy reguła ma podstawę prawną?”,
lecz „czy prawo, które system zna, jest przez reguły wykonywane?”.
Węzeł materialny bez reguły = alarm „prawo istnieje, system go nie zna”.

Czytaj:  bundles/legal_graph.json (nodes, uncovered_articles, by_act)
Pisz:    bundles/v3_p01_reverse_coverage_sentinel.json

Usage:
  python v3_p01_reverse_coverage_sentinel.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_reverse_coverage_sentinel.json"

P1_ACTS = ("podatku od towarów i usług", "podatku dochodowym od osób fizycznych",
           "Ordynacja podatkowa", "systemie ubezpieczeń społecznych")

SEVERITY_RULES = [
    ("vat", r"VAT|towarów i usług"),
    ("pit", r"PIT|dochodowym od osób fizycznych"),
    ("zus", r"SUS|ubezpieczeń społecznych"),
    ("ord", r"Ordynacja"),
]


def severity_of(node: dict) -> str:
    act = str(node.get("act", "")) + " " + str(node.get("article", ""))
    for dom, pat in SEVERITY_RULES:
        if re.search(pat, act, re.I):
            return "P1"
    return "P2"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])

    material = [n for n in nodes if n.get("node_type") in ("ARTICLE", "PARAGRAPH", "POINT")]
    uncovered: list[dict] = []
    for n in material:
        rule_ids = n.get("rule_ids") or []
        rules = n.get("rules") or []
        if not rule_ids and not rules:
            uncovered.append({
                "legal_node_id": n.get("legal_node_id"),
                "act": n.get("act"),
                "act_dz_u": n.get("act_dz_u"),
                "article": n.get("article"),
                "valid_from": n.get("valid_from"),
                "valid_to": n.get("valid_to"),
                "severity": severity_of(n),
                "issue": "prawo istnieje, system go nie zna (brak reguły)",
                "suggested_action": "utworzyć regułę SHADOW przez V3-P01-I06 lub NEEDS_ADVICE",
            })

    by_severity: dict[str, int] = {}
    for u in uncovered:
        by_severity[u["severity"]] = by_severity.get(u["severity"], 0) + 1

    return {
        "innovation": "V3-P01-I02",
        "generated_at": now(),
        "direction": "reverse coverage: legal_node → rule (brak reguły = issue)",
        "material_nodes": len(material),
        "covered_nodes": len(material) - len(uncovered),
        "uncovered_nodes": len(uncovered),
        "lci_reverse_pct": round((len(material) - len(uncovered)) / len(material) * 100, 2) if material else 0.0,
        "by_severity": by_severity,
        "issues": uncovered,
        "gate": {"rule": "nowy przepis materialny w LKG bez reguły = fail CI (V3-P01-I08)", "status": "AKTYWNY"},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Reverse Coverage Sentinel (V3-P01-I02)")
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
        print(f"V3-P01-I02 Reverse Coverage Sentinel: material={data['material_nodes']} "
              f"uncovered={data['uncovered_nodes']} by_severity={data['by_severity']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
