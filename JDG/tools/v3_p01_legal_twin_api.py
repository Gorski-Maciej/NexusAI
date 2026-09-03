#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL TWIN API (V3-P01-I12)
==========================================
API /legal/nodes + /legal/proof z historią wersji dla UI księgowej i
certyfikatów. Narzędzie buduje OFFLINE index zapytań (bez serwera):
każdy wpis = endpoint, parametry, przykład odpowiedzi na podstawie
realnych danych bundles/legal_graph.json.

Endpoints:
  GET /legal/nodes?act=<akt>&article=<art>&date=<YYYY-MM-DD>
      → wersja węzła aktywna na date (time-travel)
  GET /legal/proof?legal_node_id=<id>&date=<YYYY-MM-DD>
      → dowód: treść, okno temporalne, merkle leaf, source, status

Czytaj:  bundles/legal_graph.json, bundles/v3_p01_legal_node_versioning.json
Pisz:    bundles/v3_p01_legal_twin_api.json

Usage:
  python v3_p01_legal_twin_api.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_legal_twin_api.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def leaf_hash(n: dict) -> str:
    parts = [str(n.get("legal_node_id", "")), str(n.get("act", "")), str(n.get("article", "")),
             str(n.get("node_text", "")), str(n.get("valid_from", "")), str(n.get("valid_to", ""))]
    return hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest()


def active_at(nodes: list[dict], date_str: str) -> list[dict]:
    out = []
    for n in nodes:
        vf = str(n.get("valid_from") or "0001-01-01")[:10]
        vt = n.get("valid_to")
        vt = str(vt)[:10] if vt else "9999-12-31"
        if vf <= date_str <= vt:
            out.append(n)
    return out


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])
    sample_date = "2026-02-01"
    active = active_at(nodes, sample_date)

    # endpoint /legal/nodes — wersja węzła na dzień
    first = active[0] if active else (nodes[0] if nodes else {})
    nodes_endpoint = {
        "method": "GET", "path": "/legal/nodes",
        "params": {"act": "string", "article": "string", "date": "YYYY-MM-DD (time-travel)"},
        "sample_response": {
            "legal_node_id": first.get("legal_node_id"),
            "act": first.get("act"),
            "article": first.get("article"),
            "node_text": first.get("node_text"),
            "valid_from": first.get("valid_from"),
            "valid_to": first.get("valid_to"),
            "source": first.get("source"),
            "status": first.get("status"),
            "rule_ids": (first.get("rule_ids") or [])[:3],
        },
    }

    # endpoint /legal/proof — dowód przepisu na dzień transakcji
    proof_endpoint = {
        "method": "GET", "path": "/legal/proof",
        "params": {"legal_node_id": "LKG-xxxx", "date": "YYYY-MM-DD"},
        "sample_response": {
            "legal_node_id": first.get("legal_node_id"),
            "merkle_leaf_sha256": leaf_hash(first) if first else "",
            "isap_snapshot_ref": "ISAP-PROOF-xxx (V3-P01-I03)",
            "certification_state": "PENDING_ISAP (V3-P01-I11)",
            "decision_eligibility": "NEEDS_ADVICE do czasu CERTIFIED",
        },
    }

    return {
        "innovation": "V3-P01-I12",
        "generated_at": now(),
        "api_version": "v1",
        "endpoints": [nodes_endpoint, proof_endpoint],
        "sample_date": sample_date,
        "active_nodes_on_sample_date": len(active),
        "index_note": "offline index — dane z bundles/legal_graph.json; produkcyjny serwer wystawia "
                     "te same kontrakty z cache i kontrolą dostępu",
        "ui_consumer": "ekran księgowy pokazuje podstawę prawną decyzji z linkiem proof",
        "certificate_consumer": "Decision Certificate (V2/F4) cytuje /legal/proof na dzień transakcji",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Twin API index (V3-P01-I12)")
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
        print(f"V3-P01-I12 Legal Twin API: endpoints={len(data['endpoints'])} "
              f"active@{data['sample_date']}={data['active_nodes_on_sample_date']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
