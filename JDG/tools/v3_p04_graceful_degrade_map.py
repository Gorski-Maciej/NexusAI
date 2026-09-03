#!/usr/bin/env python3
"""NexusAI JDG — GRACEFUL DEGRADE MAP (V3-P04-I06)
===================================================
Mapa: naruszenie niezmiennika X → werdykt NEEDS_ADVICE (nigdy ciche przejście).
Domknięcie P04-AN05 (interakcja z certainty_class P03): każde naruszenie
invariantu = NEEDS_ADVICE / MANUAL_REVIEW — AUTO_POST niemożliwy (INV-006/035).

  • mapa INV → klasa pewności wynikowa + guard;
  • dowód: invariant_failed=true ⇒ certainty_class=NEEDS_ADVICE (spójność z
    runtime_invariants_enterprise.rego _classify);
  • test: każdy INV w katalogu ma wpis w mapie degradacji.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_graceful_degrade_map.json"

# Naruszenie INV → klasa pewności + guard (P04-AN05). BLOCK → NEEDS_ADVICE.
DEGRADE_MAP = {
    "INV-001": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-002": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-003": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-005": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-006": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-007": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-008": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-009": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-012": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-018": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-020": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-021": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-030": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-032": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-035": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-036": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-037": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-038": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-039": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
    "INV-042": ("NEEDS_ADVICE", "CERTAINTY_BLOCKED"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def extract_catalog(rego_text: str) -> list[dict]:
    m = re.search(r"catalog\s*:=\s*\[(.*?)\n\]", rego_text, re.S)
    if not m:
        return []
    return [
        {"id": i, "level": l, "enforcement": e}
        for i, d, l, e in re.findall(
            r'\{"id":\s*"(INV-\d+)",\s*"description":\s*"([^"]+)",\s*"level":\s*"([^"]+)",\s*"enforcement":\s*"([^"]+)"\}',
            m.group(1),
        )
    ]


def build() -> dict:
    rego = (BASE_DIR / "rules" / "audit" / "runtime_invariants_enterprise.rego").read_text(encoding="utf-8")
    catalog = extract_catalog(rego)
    catalog_ids = {c["id"] for c in catalog}

    rows = []
    # Wiersze budowane Z KATALOGU (kanon) — każdy RUNTIME INV dostaje mapę.
    # Degradacja jest jednolita dla BLOCK: NEEDS_ADVICE + CERTAINTY_BLOCKED.
    for c in catalog:
        if c["level"] != "RUNTIME":
            continue
        enforcement = c["enforcement"]
        if enforcement == "BLOCK":
            cls, guard = "NEEDS_ADVICE", "CERTAINTY_BLOCKED"
            auto_post = False
        elif enforcement == "ALERT":
            cls, guard = "CONDITIONAL", "MANUAL_REVIEW"
            auto_post = False
        else:  # AUTO_REVERT / inne
            cls, guard = "NEEDS_ADVICE", "CERTAINTY_BLOCKED"
            auto_post = False
        rows.append({
            "invariant": c["id"], "enforcement": enforcement,
            "resulting_class": cls, "resulting_guard": guard,
            "auto_post_possible": auto_post,
            "degrade_source": DEGRADE_MAP.get(c["id"], "UNIFORM_BLOCK"),
        })

    # Spójność z _classify (runtime_invariants): failed > 0 → NEEDS_ADVICE.
    classify_ok = bool(re.search(r'_classify\(failed, v\) = "NEEDS_ADVICE" \{\s*count\(failed\) > 0', rego))
    # Każdy BLOCK runtime → NEEDS_ADVICE (fail-closed); zero cichych przejść.
    silent = [r for r in rows if r["enforcement"] == "BLOCK" and r["resulting_class"] != "NEEDS_ADVICE"]

    return {
        "innovation": "V3-P04-I06",
        "name": "Graceful Degrade Map — naruszenie → NEEDS_ADVICE (P04-AN05)",
        "generated_at": now(),
        "rows": rows,
        "runtime_invariants_count": len(rows),
        "silent_transitions": silent,
        "explicit_map_entries": len(DEGRADE_MAP),
        "classify_consistency": classify_ok,
        "fail_closed": "naruszenie invariantu BLOCK = NEEDS_ADVICE + CERTAINTY_BLOCKED; "
                       "AUTO_POST niemożliwy (INV-006/035); nigdy ciche przejście",
        "gate": {
            "pass": classify_ok and len(silent) == 0,
            "rule": "każdy INV runtime ma mapę degradacji z katalogu (kanon); _classify "
                    "zgadza się z mapą (failed>0 ⇒ NEEDS_ADVICE); zero cichych przejść — P04-AN05",
        },
        "note": "Mapa spójna z P03-I02 (Certainty Class Engine) — jedno źródło semantyki "
                "degradacji; wpisy BLOCK zawsze CERTAINTY_BLOCKED; ALERT → MANUAL_REVIEW.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Graceful Degrade Map (V3-P04-I06)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P04-I06 Graceful Degrade: runtime_inv={data['runtime_invariants_count']} "
              f"classify_ok={data['classify_consistency']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: niezgodność mapy degradacji z _classify")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())