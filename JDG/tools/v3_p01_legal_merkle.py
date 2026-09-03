#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL GRAPH MERKLE ROOT (V3-P01-I09)
==================================================
Deterministyczny hash drzewa grafu prawnego: uporządkowany zbiór węzłów
(legal_node_id + treść + okno temporalne) → pojedynczy root hash, który
może trafić do każdego werdyktu jako dowód spójności zbioru podstaw prawnych.

  • kanoniczna serializacja: posortowane węzły (sorted by legal_node_id);
  • leaf hash  = sha256("legal_node_id|act|article|node_text|valid_from|valid_to");
  • root hash  = sha256(concat połączonych leaf hashów) — Merkle-style commit.

Czytaj:  bundles/legal_graph.json (nodes)
Pisz:    bundles/v3_p01_legal_merkle.json

Usage:
  python v3_p01_legal_merkle.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_legal_merkle.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def node_leaf(n: dict) -> str:
    parts = [
        str(n.get("legal_node_id", "")),
        str(n.get("act", "")),
        str(n.get("article", "")),
        str(n.get("node_text", "")),
        str(n.get("valid_from", "")),
        str(n.get("valid_to", "")),
    ]
    return hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest()


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])
    ordered = sorted(nodes, key=lambda n: str(n.get("legal_node_id", "")))
    leaves = [node_leaf(n) for n in ordered]
    # Merkle-drzewo: łączenie par aż do jednego korzenia (deterministyczne)
    layer = leaves
    while len(layer) > 1:
        nxt = []
        for i in range(0, len(layer), 2):
            a = layer[i]
            b = layer[i + 1] if i + 1 < len(layer) else layer[i]
            nxt.append(hashlib.sha256((a + b).encode("utf-8")).hexdigest())
        layer = nxt
    root = layer[0] if layer else hashlib.sha256(b"empty-legal-graph").hexdigest()

    return {
        "innovation": "V3-P01-I09",
        "generated_at": now(),
        "nodes_hashed": len(nodes),
        "root_hash": root,
        "algorithm": "sha256 Merkle commit: leaf(legal_node_id|act|article|node_text|valid_from|valid_to) → root",
        "commit": {
            "verdict_field": "_legal_graph_merkle_root",
            "purpose": "dowód spójności zbioru podstaw prawnych w certyfikacie (P11) — "
                       "zmiana grafu = inny root = werdykt do ponownej weryfikacji",
            "offline_check": "root liczony lokalnie z bundles/legal_graph.json — niezależny od ISAP uptime",
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Graph Merkle Root (V3-P01-I09)")
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
        print(f"V3-P01-I09 Legal Merkle Root: nodes={data['nodes_hashed']} root={data['root_hash'][:16]}…")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
