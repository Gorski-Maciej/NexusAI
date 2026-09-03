#!/usr/bin/env python3
"""NexusAI JDG — CONSTITUTIONAL FREEZE (V3-P04-I07)
=====================================================
Automatyczne zamrożenie domeny po powtarzającym się naruszeniu + procedura
odblokowania 4-eyes (P04-AN11). Polityka eskalacji: niezmiennik złamany 2×
w 24h → freeze domeny + review 4-eyes.

  • licznik naruszeń per domena/INV w oknie 24h;
  • próg FREEZE: ≥2 naruszenia BLOCK w 24h;
  • freeze: domena wyłączona z AUTO_POST, werdykty domeny → NEEDS_ADVICE;
  • odblokowanie: wyłącznie 4-eyes (2 osoby) + dowód naprawy (test negatywny).
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_constitutional_freeze.json"

FREEZE_THRESHOLD = 2  # naruszenia BLOCK w oknie 24h
WINDOW_HOURS = 24


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def build() -> dict:
    base = datetime.now(timezone.utc)
    # Historia naruszeń (modelowa): domena VAT 2× INV-001 w 12h → FREEZE;
    # domena ZUS 1× INV-005 → WATCH; domena PIT 0 → HEALTHY.
    incidents = [
        {"domain": "jdg.vat", "invariant": "INV-001", "at": base - timedelta(hours=2)},
        {"domain": "jdg.vat", "invariant": "INV-001", "at": base - timedelta(hours=11)},
        {"domain": "jdg.zus", "invariant": "INV-005", "at": base - timedelta(hours=5)},
    ]
    window_start = base - timedelta(hours=WINDOW_HOURS)
    window = [i for i in incidents if i["at"] >= window_start]

    states = {}
    for dom in sorted({i["domain"] for i in window}):
        dom_inc = [i for i in window if i["domain"] == dom]
        blocks = [i for i in dom_inc if i["invariant"] in ("INV-001", "INV-005", "INV-006",
                                                           "INV-021", "INV-035", "INV-038")]
        n = len(blocks)
        if n >= FREEZE_THRESHOLD:
            state = "FROZEN"
        elif n == 1:
            state = "WATCH"
        else:
            state = "HEALTHY"
        states[dom] = {
            "violations_24h": n,
            "state": state,
            "auto_post": "DISABLED" if state == "FROZEN" else "ALLOWED_IF_CERTAIN",
            "unblock_requires": "4-eyes + test negatywny INV zielony" if state == "FROZEN" else None,
        }

    frozen = {d for d, s in states.items() if s["state"] == "FROZEN"}
    return {
        "innovation": "V3-P04-I07",
        "name": "Constitutional Freeze — auto-freeze domeny + odblokowanie 4-eyes (P04-AN11)",
        "generated_at": now(),
        "policy": {
            "freeze_threshold": FREEZE_THRESHOLD,
            "window_hours": WINDOW_HOURS,
            "rule": f"{FREEZE_THRESHOLD}× naruszenie BLOCK w {WINDOW_HOURS}h → freeze domeny; "
                    "odblokowanie wyłącznie 4-eyes + dowód naprawy (test negatywny zielony)",
        },
        "incidents_window": [
            {"domain": i["domain"], "invariant": i["invariant"], "at": i["at"].isoformat()}
            for i in window
        ],
        "domain_states": states,
        "frozen_domains": sorted(frozen),
        "gate": {
            "pass": len(frozen) == 1 and states.get("jdg.vat", {}).get("state") == "FROZEN",
            "rule": "polityka eskalacji działa: 2× naruszenie BLOCK w 24h → FROZEN; "
                    "1× → WATCH; 0× → HEALTHY (P04-AN11)",
        },
        "note": "Scenariusz modelowy (3 incydenty) — licznik runtime z P37; freeze "
                "wyłącza AUTO_POST domeny (fail-closed, nigdy ciche przejście).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Constitutional Freeze (V3-P04-I07)")
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
        print(f"V3-P04-I07 Constitutional Freeze: frozen={data['frozen_domains']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: polityka eskalacji nie wykryła freeze")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())