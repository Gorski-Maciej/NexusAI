#!/usr/bin/env python3
"""
NexusAI JDG — KALENDARZ ZMIAN PRAWNYCH (P02 — sekcja 7, V1 §4.1, V2 F5)
=======================================================================
Kalendarz zmian prawa z countdownem (proaktywna adaptacja): łączy projekty
ustaw (law_radar.json, DRAFT_LAW) z kalendarzem wejścia w życie. Każda zmiana:
status, przewidywana data wejścia, countdown (dni), lead days (KPI ≥ 30),
reguły SHADOW przygotowane, confidence_draft.

  • calendar — pełny kalendarz zmian + raport MD,
  • next     — najbliższa zmiana (countdown),
  • seed     — dodaj znaną zmianę prawa ręcznie (np. z Dz.U.),
  • gate     — bramka: alert, gdy nadchodząca zmiana ma lead < 30 dni.

Usage:
  python legal_change_calendar.py calendar
  python legal_change_calendar.py next
  python legal_change_calendar.py seed --title "Nowe progi PIT" --date 2027-01-01 \
      --act "ustawa o PIT"
  python legal_change_calendar.py gate
"""

import argparse
import json
import sys
from datetime import date, datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RADAR = JDG_ROOT / "bundles" / "law_radar.json"
CAL_PATH = JDG_ROOT / "bundles" / "legal_change_calendar.json"
OUT_MD = JDG_ROOT / "docs" / "KALENDARZ_ZMIAN_PRAWNYCH.md"

LEAD_TARGET_DAYS = 30


def load() -> dict:
    if CAL_PATH.exists():
        return json.loads(CAL_PATH.read_text(encoding="utf-8"))
    return {"changes": {}}


def save(data: dict) -> None:
    CAL_PATH.parent.mkdir(parents=True, exist_ok=True)
    CAL_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def import_radar() -> list[dict]:
    """Import projektów z law_radar.json do kalendarza."""
    changes = []
    if RADAR.exists():
        radar = json.loads(RADAR.read_text(encoding="utf-8"))
        for draft in radar.get("drafts", {}).values():
            if draft.get("status") != "DRAFT_LAW":
                continue
            changes.append({
                "id": draft["draft_id"],
                "title": draft["title"],
                "source": draft["source"],
                "expected_enactment": draft["expected_enactment"],
                "status": "DRAFT_LAW",
                "confidence_draft": draft.get("confidence_draft", 0.7),
                "rules_prepared": draft.get("rule_ids_prepared", []),
            })
    return changes


def merge() -> dict:
    data = load()
    data.setdefault("changes", {})
    for ch in import_radar():
        data["changes"].setdefault(ch["id"], ch)
    today = date.today()
    for ch in data["changes"].values():
        try:
            delta = (date.fromisoformat(ch["expected_enactment"]) - today).days
        except ValueError:
            delta = 0
        ch["countdown_days"] = max(0, delta)
        ch["lead_ok"] = delta >= LEAD_TARGET_DAYS
    save(data)
    return data


def cmd_calendar(args) -> None:
    data = merge()
    changes = sorted(data["changes"].values(), key=lambda c: c["expected_enactment"])
    lines = [
        "# 📅 KALENDARZ ZMIAN PRAWNYCH (countdown) — P02 sekcja 7 / V2 F5",
        "",
        f"> Wygenerowano: {datetime.now(timezone.utc).isoformat()} · generator: `legal_change_calendar.py`",
        f"> KPI: lead ≥ {LEAD_TARGET_DAYS} dni przed wejściem w życie (V2 §6.2.5)",
        "",
        "| ID | Zmiana | Źródło | Wejście | Countdown | Lead OK | Confidence | Reguły SHADOW |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for c in changes:
        lines.append(f"| {c['id']} | {c['title']} | {c['source']} | {c['expected_enactment']} | "
                     f"{c['countdown_days']} dni | {'✅' if c['lead_ok'] else '⚠️'} | "
                     f"{c.get('confidence_draft', '—')} | {len(c.get('rules_prepared', []))} |")
    lines += ["", "*Źródło: law_radar.json (projekty ustaw) + wpisy ręczne (seed).*", ""]
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"📅 KALENDARZ: {len(changes)} zmian · raport: {OUT_MD.relative_to(JDG_ROOT)}")
    if args.json:
        print(json.dumps(changes, indent=2, ensure_ascii=False))


def cmd_next(args) -> None:
    data = merge()
    changes = [c for c in data["changes"].values() if c.get("countdown_days", 0) > 0]
    changes.sort(key=lambda c: c["countdown_days"])
    if not changes:
        print("ℹ️  Brak nadchodzących zmian prawa.")
        return
    nxt = changes[0]
    print(json.dumps({"next": nxt}, indent=2, ensure_ascii=False))


def cmd_seed(args) -> None:
    data = load()
    data.setdefault("changes", {})
    cid = f"CHG-{len(data['changes']) + 1:04d}"
    data["changes"][cid] = {
        "id": cid, "title": args.title, "source": args.source,
        "expected_enactment": args.date, "status": args.status,
        "confidence_draft": args.confidence, "rules_prepared": [],
        "act": args.act,
    }
    save(data)
    print(f"✅ Dodano do kalendarza: {cid} — {args.title} ({args.date})")


def cmd_gate(args) -> None:
    data = merge()
    today = date.today()
    risky = []
    for ch in data["changes"].values():
        if ch.get("status") != "DRAFT_LAW":
            continue
        try:
            delta = (date.fromisoformat(ch["expected_enactment"]) - today).days
        except ValueError:
            continue
        if 0 <= delta < LEAD_TARGET_DAYS:
            risky.append(ch)
    if risky:
        print(f"❌ BRAMKA KALENDARZA: {len(risky)} zmian z lead < {LEAD_TARGET_DAYS} dni:")
        for ch in risky:
            print(f"   • {ch['title']} — wejście {ch['expected_enactment']} "
                  f"({ch['countdown_days']} dni) — tryb PILNY (SLO 24 h/4 h)")
        sys.exit(1)
    print(f"✅ BRAMKA KALENDARZA: wszystkie zmiany z lead ≥ {LEAD_TARGET_DAYS} dni (proaktywność OK)")


def main() -> None:
    p = argparse.ArgumentParser(description="Kalendarz zmian prawnych — P02 sekcja 7")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("calendar"); c.add_argument("--json", action="store_true"); c.set_defaults(fn=cmd_calendar)
    n = sub.add_parser("next"); n.set_defaults(fn=cmd_next)
    s = sub.add_parser("seed")
    s.add_argument("--title", required=True)
    s.add_argument("--date", required=True)
    s.add_argument("--source", default="ISAP")
    s.add_argument("--status", default="DRAFT_LAW")
    s.add_argument("--act", default="")
    s.add_argument("--confidence", type=float, default=0.7)
    s.set_defaults(fn=cmd_seed)
    g = sub.add_parser("gate"); g.set_defaults(fn=cmd_gate)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
