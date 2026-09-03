#!/usr/bin/env python3
"""
NexusAI JDG — INTERPRETATION LAYER ISOLATION (V3-P01-I05)
==========================================================
Sztywna separacja prawa powszechnego (ustawy/rozporządzenia) od
interpretacji/orzeczeń (KIS indywidualne, MF ogólne, WIS, NSA, TSUE)
w regułach i werdyktach.

  • layer STATUTE — norma powszechnie obowiązująca; może być podstawą ACTIVE.
  • layer INTERP  — interpretacja/orzeczenie; NIGDY nie jest samodzielną
    podstawą AUTO_POST — wspiera decyzję albo wymusza NEEDS_ADVICE.

Czytaj:  bundles/legal_basis_audit.json (rows)
Pisz:    bundles/v3_p01_interpretation_layer.json

Usage:
  python v3_p01_interpretation_layer.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
AUDIT = BASE_DIR / "bundles" / "legal_basis_audit.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_interpretation_layer.json"

INTERP_PATTERNS = [
    r"interpretacj[ei].*(?:KIS|indywidualn)",
    r"interpretacj[ei] ogóln",
    r"WIS\b", r"WIA\b",
    r"wyrok", r"orzeczen",
    r"NSA\b", r"WSA\b", r"TSUE",
    r"objaśnienia podatkowe",
]


def classify(legal_basis: str) -> tuple[str, str]:
    lb = legal_basis or ""
    if not lb.strip():
        return "NONE", "brak podstawy"
    for pat in INTERP_PATTERNS:
        if re.search(pat, lb, re.I):
            return "INTERP", lb[:120]
    return "STATUTE", lb[:120]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    audit = json.loads(AUDIT.read_text(encoding="utf-8")) if AUDIT.exists() else {}
    rows = audit.get("rows", [])
    stats = Counter()
    interp_rules: list[dict] = []
    none_rules: list[dict] = []
    for r in rows:
        layer, snippet = classify(r.get("legal_basis", ""))
        stats[layer] += 1
        if layer == "INTERP":
            interp_rules.append({"rule_id": r.get("rule_id"), "file": r.get("file"), "legal_basis": snippet})
        elif layer == "NONE":
            none_rules.append({"rule_id": r.get("rule_id"), "file": r.get("file")})

    return {
        "innovation": "V3-P01-I05",
        "generated_at": now(),
        "rules_total": len(rows),
        "layer_stats": dict(stats),
        "isolation_contract": {
            "STATUTE": "może być jedyną podstawą AUTO_POST",
            "INTERP": "wspiera decyzję; samodzielnie = NEEDS_ADVICE/MANUAL_REVIEW",
            "NONE": "fail-closed: brak podstawy = brak AUTO_POST",
        },
        "interp_examples": interp_rules[:10],
        "interp_total": stats.get("INTERP", 0),
        "none_total": stats.get("NONE", 0),
        "verdict_field": "_legal_layers: [STATUTE|INTERP|NONE] — pole kontraktu werdyktu (P03)",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Interpretation Layer Isolation (V3-P01-I05)")
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
        print(f"V3-P01-I05 Interpretation Layer Isolation: rules={data['rules_total']} "
              f"STATUTE={data['layer_stats'].get('STATUTE', 0)} INTERP={data['interp_total']} NONE={data['none_total']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
