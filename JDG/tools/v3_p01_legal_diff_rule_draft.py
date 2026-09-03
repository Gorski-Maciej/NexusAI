#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL DIFF → RULE DRAFT PIPELINE (V3-P01-I06)
===========================================================
Pipeline: diff nowelizacji (zmiana aktu) → automatyczny szkic zmian reguł
jako wersje SHADOW z wymogiem 4-eyes przed aktywacją.

Wejście:  wpisy zmian prawnych (bundles/legal_change_calendar.json — DRAFT_LAW)
Wyjście:  szkice reguł (SHADOW) z mapowaniem dotkniętych artykułów.

Czytaj:  bundles/legal_change_calendar.json, bundles/legal_graph.json
Pisz:    bundles/v3_p01_legal_diff_rule_draft.json

Usage:
  python v3_p01_legal_diff_rule_draft.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
CAL = BASE_DIR / "bundles" / "legal_change_calendar.json"
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_legal_diff_rule_draft.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    cal = json.loads(CAL.read_text(encoding="utf-8")) if CAL.exists() else {}
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    changes = cal.get("changes", {})
    if isinstance(changes, dict):
        change_items = list(changes.values())
    elif isinstance(changes, list):
        change_items = changes
    else:
        change_items = []

    drafts: list[dict] = []
    for c in change_items:
        if not isinstance(c, dict):
            continue
        cid = c.get("id") or c.get("change_id") or "?"
        title = c.get("title") or c.get("name") or "?"
        drafts.append({
            "draft_id": f"SHADOW-{cid}",
            "source_change": cid,
            "title": title,
            "status": "SHADOW",
            "lifecycle": "SHADOW → CANDIDATE (po 4-eyes) → ACTIVE (po testach golden)",
            "affected_articles": c.get("affected_articles", []),
            "rules_prepared": c.get("rules_prepared", []),
            "expected_enactment": c.get("expected_enactment"),
            "countdown_days": c.get("countdown_days"),
            "confidence_draft": c.get("confidence_draft", 0.0),
            "four_eyes_required": True,
            "four_eyes_done": False,
        })

    return {
        "innovation": "V3-P01-I06",
        "generated_at": now(),
        "pipeline": "diff nowelizacji (RCL/ISAP) → wektoryzacja zmian artykułów → "
                    "szkice reguł SHADOW → przegląd 4-eyes (prawnik+engineer) → "
                    "CANDIDATE → golden replay → ACTIVE",
        "changes_scanned": len(change_items),
        "drafts_generated": len(drafts),
        "drafts": drafts,
        "gate": {
            "rule": "żaden szkic SHADOW nie przechodzi do ACTIVE bez 4-eyes i golden replay (V3-P01-I10)",
            "status": "AKTYWNY",
        },
        "contract": "wiąże P08 (Law Radar) i P09 (Declarative Change) — szkic zmian reguł zamiast ręcznej edycji",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Diff → Rule Draft Pipeline (V3-P01-I06)")
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
        print(f"V3-P01-I06 Legal Diff→Rule Draft: changes={data['changes_scanned']} drafts={data['drafts_generated']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
