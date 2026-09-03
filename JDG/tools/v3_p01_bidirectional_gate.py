#!/usr/bin/env python3
"""
NexusAI JDG — BIDIRECTIONAL CONSISTENCY GATE (V3-P01-I08)
=========================================================
Bramka CI dwukierunkowej spójności prawo↔reguła:

  • FORWARD:  każda reguła krytyczna ma _legal_basis wskazujący węzeł LKG
              (reguła bez węzła prawnego = fail);
  • REVERSE:  każdy węzeł materialny ma ≥1 regułę (węzeł bez reguły = fail);
  • CLASS:    klasy legal_basis_audit OK/UNKNOWN_ACT/MISSING liczone do gate.

Czytaj:  bundles/legal_basis_audit.json, bundles/legal_graph.json
Pisz:    bundles/v3_p01_bidirectional_gate.json

Usage:
  python v3_p01_bidirectional_gate.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
AUDIT = BASE_DIR / "bundles" / "legal_basis_audit.json"
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_bidirectional_gate.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    audit = json.loads(AUDIT.read_text(encoding="utf-8")) if AUDIT.exists() else {}
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    rows = audit.get("rows", [])
    nodes: list[dict] = graph.get("nodes", [])

    # FORWARD: klasy podstaw prawnych wszystkich reguł
    by_class: dict[str, int] = {}
    for r in rows:
        cls = r.get("class", "MISSING")
        by_class[cls] = by_class.get(cls, 0) + 1

    # REVERSE: węzły materialne bez reguły
    material = [n for n in nodes if n.get("node_type") in ("ARTICLE", "PARAGRAPH", "POINT")]
    uncovered = [n for n in material if not (n.get("rule_ids") or n.get("rules"))]

    forward_ok = by_class.get("OK", 0) + by_class.get("NON_CANONICAL", 0)
    forward_fail = by_class.get("MISSING", 0) + by_class.get("UNKNOWN_ACT", 0)
    reverse_fail = len(uncovered)

    # próg: forward_fail == 0 i reverse_fail == 0 (fail-closed CI); dopuszczalne
    # wyjątki tylko z jawnym wpisem do rejestru mediacji (V3-P01-Lxx)
    forward_pass = forward_fail == 0
    reverse_pass = reverse_fail == 0
    gate_pass = forward_pass and reverse_pass

    return {
        "innovation": "V3-P01-I08",
        "generated_at": now(),
        "forward": {"direction": "reguła → węzeł prawny (_legal_basis)",
                    "ok": forward_ok, "fail": forward_fail, "pass": forward_pass,
                    "fail_classes": {k: v for k, v in by_class.items() if k in ("MISSING", "UNKNOWN_ACT")}},
        "reverse": {"direction": "węzeł materialny → reguła",
                    "material_nodes": len(material), "uncovered": reverse_fail, "pass": reverse_pass},
        "gate": {"pass": gate_pass, "rule": "oba kierunki muszą być spójne przed AUTO_POST; "
                                           "wyjątki tylko przez rejestr mediacji"},
        "note": "wartości fail są celowo raportowane (nie ukrywane) — gate to pomiar, nie fikcja",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Bidirectional Consistency Gate (V3-P01-I08)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true", help="bramka CI: exit 1 gdy niespójność")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P01-I08 Bidirectional Gate: forward_fail={data['forward']['fail']} "
              f"reverse_uncovered={data['reverse']['uncovered']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: niespójność dwukierunkowa prawo↔reguła")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
