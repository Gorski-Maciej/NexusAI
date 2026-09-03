#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL BASIS HEALTH SCORE (V3-P01-I04)
====================================================
Scoring każdej reguły wg statusu weryfikacji podstawy prawnej
(klasy z bundles/legal_basis_audit.json) z dashboardem trendu.

  klasa OK            → score 1.00 (podstawa kanoniczna, zweryfikowana)
  klasa NON_CANONICAL → score 0.60 (format poza kanonem — do normalizacji)
  klasa UNKNOWN_ACT   → score 0.30 (akt nierozpoznany — do weryfikacji)
  klasa MISSING       → score 0.00 (brak podstawy — fail)

Czytaj:  bundles/legal_basis_audit.json (rows, stats, by_act)
Pisz:    bundles/v3_p01_legal_basis_health.json

Usage:
  python v3_p01_legal_basis_health.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
AUDIT = BASE_DIR / "bundles" / "legal_basis_audit.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_legal_basis_health.json"

CLASS_SCORE = {"OK": 1.0, "NON_CANONICAL": 0.6, "UNKNOWN_ACT": 0.3, "MISSING": 0.0}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    audit = json.loads(AUDIT.read_text(encoding="utf-8")) if AUDIT.exists() else {}
    rows = audit.get("rows", [])
    per_act: dict[str, dict] = defaultdict(lambda: {"rules": 0, "score_sum": 0.0})
    per_class: dict[str, int] = {}
    scored = 0
    for r in rows:
        cls = r.get("class", "MISSING")
        per_class[cls] = per_class.get(cls, 0) + 1
        score = CLASS_SCORE.get(cls, 0.0)
        if score > 0 or cls == "MISSING":
            scored += 1
        act = r.get("canonical_act") or "(nieznany akt)"
        per_act[act]["rules"] += 1
        per_act[act]["score_sum"] += score

    act_dashboard = []
    for act, d in sorted(per_act.items(), key=lambda kv: -kv[1]["rules"]):
        act_dashboard.append({
            "act": act,
            "rules": d["rules"],
            "avg_health": round(d["score_sum"] / d["rules"], 4) if d["rules"] else 0.0,
        })

    total = len(rows)
    overall = round(sum(CLASS_SCORE.get(r.get("class", "MISSING"), 0.0) for r in rows) / total, 4) if total else 0.0

    return {
        "innovation": "V3-P01-I04",
        "generated_at": now(),
        "rules_total": total,
        "overall_health": overall,
        "classes": per_class,
        "score_scale": CLASS_SCORE,
        "by_act_dashboard": act_dashboard,
        "worst_acts": act_dashboard[-5:],
        "trend": {"basis": "kolejne audyty legal_basis_audit.py — porównywać RV i rozkład klas w czasie"},
        "gate": {
            "rule": "reguła krytyczna z klasą MISSING lub UNKNOWN_ACT = fail CI (V3-P01-I08)",
            "overall_min": 0.8,
            "overall_now": overall,
            "pass": overall >= 0.8,
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Basis Health Score (V3-P01-I04)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true", help="bramka CI: exit 1 gdy overall < 0.8")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P01-I04 Legal Basis Health: rules={data['rules_total']} "
              f"overall={data['overall_health']} classes={data['classes']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: overall_health < 0.8")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
