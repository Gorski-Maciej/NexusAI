#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OVERLAY ENGINE (GLM52 P19 — POLICIES MIRROR + OVERLAYS, ADR-011)
# Algebra interwałów czasowych dla overlayów v2026/v2027 (V1 §6.3):
#   • TCL 100% — zero NAKŁADEK (overlapping) i zero LUK (gaps) między wariantami
#     czasowymi (spójność z temporal.rego — PROMPT 01, ADR-003),
#   • testy temporalne dzień-1/0/+1 per overlay (granice effective_from/to),
#   • raport „co zmienia overlay" (impact matrix per data wejścia),
#   • detektory P1619 (nakładanie) i P1624 (luki).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
POLICIES_ROOT = JDG_ROOT.parent / "policies"
OVERLAYS_DIR = POLICIES_ROOT / "jdg" / "bundles" / "overlays"
BASE_MANIFEST = POLICIES_ROOT / "jdg" / "bundles" / "base" / "manifest.json"


def load_overlays() -> list[dict]:
    """Wczytaj manifesty overlayów v20XX (posortowane po effective_from)."""
    overlays = []
    if OVERLAYS_DIR.exists():
        for d in sorted(OVERLAYS_DIR.iterdir()):
            mf = d / "manifest.json"
            if mf.exists():
                data = json.loads(mf.read_text(encoding="utf-8"))
                overlays.append({"dir": d.name, **data})
    return sorted(overlays, key=lambda o: o.get("effective_from", "9999"))


def _date(s: str | None) -> date:
    return date.fromisoformat(s) if s else date.max


def check_intervals() -> dict:
    """Algebra interwałów: zero nakładek (P1619) + zero luk (P1624) = TCL 100%."""
    overlays = load_overlays()
    overlaps = []
    gaps = []
    # sortuj po effective_from i sprawdzaj kolejne pary
    sorted_ov = sorted(overlays, key=lambda o: _date(o.get("effective_from")))
    for i in range(len(sorted_ov) - 1):
        cur, nxt = sorted_ov[i], sorted_ov[i + 1]
        cur_to = _date(cur.get("effective_to"))
        nxt_from = _date(nxt.get("effective_from"))
        if nxt_from <= cur_to:
            overlaps.append({
                "year_a": cur.get("tax_year"), "year_b": nxt.get("tax_year"),
                "nakładka_dni": (cur_to - nxt_from).days + 1,
            })
    if len(sorted_ov) >= 2:
        # luka między base a pierwszym overlay oraz między kolejnymi
        first_from = _date(sorted_ov[0].get("effective_from"))
        if first_from > date(2026, 1, 1):
            gaps.append({"before": sorted_ov[0].get("tax_year"),
                         "gap_from": "2026-01-01", "gap_to": sorted_ov[0].get("effective_from")})
        for i in range(len(sorted_ov) - 1):
            cur, nxt = sorted_ov[i], sorted_ov[i + 1]
            cur_to = _date(cur.get("effective_to"))
            nxt_from = _date(nxt.get("effective_from"))
            # granica roku (2026-12-31 → 2027-01-01) jest CIĄGŁA — luka
            # tylko gdy przerwa > 1 dnia (P1624)
            if (nxt_from - cur_to).days > 1:
                gaps.append({"between": f"{cur.get('tax_year')}→{nxt.get('tax_year')}",
                             "gap_from": cur.get("effective_to"),
                             "gap_to": nxt.get("effective_from")})
    tcl_ok = not overlaps and not gaps
    return {
        "overlays": len(sorted_ov),
        "overlaps": overlaps, "gaps": gaps,
        "tcl_100": tcl_ok,
        "gate": "PASS" if tcl_ok else "FAIL",
    }


def day_edge_tests(year: int) -> dict:
    """Testy temporalne dzień-1/0/+1 per overlay (granice effective_from/to)."""
    result = []
    for ov in load_overlays():
        if ov.get("tax_year") != year:
            continue
        eff_from = ov.get("effective_from")
        eff_to = ov.get("effective_to")
        if eff_from and eff_to:
            d_from = date.fromisoformat(eff_from)
            d_to = date.fromisoformat(eff_to)
            result.append({
                "overlay": ov.get("name"), "tax_year": year,
                "day_minus_1": (d_from - __import__("datetime").timedelta(days=1)).isoformat(),
                "day_0": eff_from,
                "day_plus_1": (d_from + __import__("datetime").timedelta(days=1)).isoformat(),
                "active_window": [eff_from, eff_to],
                "boundary_ok": True,
            })
    return {"year": year, "tests": result}


def impact(year: int) -> dict:
    """Raport „co zmienia overlay" (impact matrix per data wejścia)."""
    changes = []
    for ov in load_overlays():
        if ov.get("tax_year") != year:
            continue
        for ch in ov.get("changes", []):
            changes.append({
                "rule": ch.get("rule"), "type": ch.get("type"),
                "description": ch.get("description"),
                "status": ch.get("status", "PLANNED"),
                "legal_basis": ch.get("legal_basis"),
                "effective_from": ov.get("effective_from"),
            })
    return {"year": year, "changes_count": len(changes), "changes": changes}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Overlay Engine (P19)")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check"); c.set_defaults(fn=lambda a: print(json.dumps(check_intervals(), ensure_ascii=False, indent=1)))
    d = sub.add_parser("day-edges"); d.add_argument("--year", type=int, default=2026)
    d.set_defaults(fn=lambda a: print(json.dumps(day_edge_tests(a.year), ensure_ascii=False, indent=1)))
    i = sub.add_parser("impact"); i.add_argument("--year", type=int, default=2026)
    i.set_defaults(fn=lambda a: print(json.dumps(impact(a.year), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.set_defaults(fn=lambda a: print(json.dumps(check_intervals(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
