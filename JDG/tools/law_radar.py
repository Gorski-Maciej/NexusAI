#!/usr/bin/env python3
"""
NexusAI JDG — LAW RADAR (P01 Fundament — Sekcja 12, WIZJA V2 F5 §6)
====================================================================
Proaktywna adaptacja do zmian prawa: monitoring PROJEKTÓW ustaw (RCL, Sejm,
Senat) — nie tylko opublikowanych nowelizacji. Zmiana paradygmatu V2 §6.1:
reakcja (publikacja → 24 h) → proakcja (projekt → przygotowanie z wyprzedzeniem).

  • track    — dodaj projekt ustawy (źródło, tytuł, przewidywana data wejścia,
    confidence_draft, przewidywany diff prawny),
  • status   — aktualizacja statusu (DRAFT_LAW → ENACTED / WITHDRAWN),
  • radar    — tablica: countdown do wejścia, lead_days (KPI ≥ 30 dni),
    reguły SHADOW przygotowane,
  • prepare  — powiąż przygotowane reguły SHADOW z projektem (F6 pipeline).

Usage:
  python law_radar.py track --source RCL --title "Nowelizacja ustawy o VAT" \
      --enactment 2027-01-01 --confidence 0.8 --diff diff.json
  python law_radar.py radar
  python law_radar.py status --draft-id <id> --new-status ENACTED
"""

import argparse
import json
import sys
from datetime import date, datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RADAR_PATH = JDG_ROOT / "bundles" / "law_radar.json"

SOURCES = {"RCL", "SEJM", "SENAT", "ISAP"}
STATUSES = {"DRAFT_LAW", "ENACTED", "WITHDRAWN"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load() -> dict:
    if RADAR_PATH.exists():
        return json.loads(RADAR_PATH.read_text(encoding="utf-8"))
    return {"drafts": {}, "kpi": {"lead_time_avg_days": 0, "target_lead_days": 30}}


def save(data: dict) -> None:
    RADAR_PATH.parent.mkdir(parents=True, exist_ok=True)
    RADAR_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def cmd_track(args) -> None:
    data = load()
    draft_id = f"DRL-{len(data['drafts']) + 1:04d}"
    diff = None
    if args.diff:
        diff = json.loads(Path(args.diff).read_text(encoding="utf-8"))
    enactment = date.fromisoformat(args.enactment)
    lead = (enactment - date.today()).days
    data["drafts"][draft_id] = {
        "draft_id": draft_id,
        "source": args.source,
        "title": args.title,
        "detected_at": now(),
        "status": "DRAFT_LAW",
        "confidence_draft": args.confidence,
        "expected_enactment": args.enactment,
        "lead_days": max(0, lead),
        "predicted_diff": diff,
        "rule_ids_prepared": [],
        "reviewed_by": None,
    }
    # KPI: średni lead time
    drafts = [d for d in data["drafts"].values() if d.get("lead_days") is not None]
    data["kpi"]["lead_time_avg_days"] = round(
        sum(d["lead_days"] for d in drafts) / len(drafts), 1) if drafts else 0
    save(data)
    print(f"📡 LAW RADAR: {draft_id} — {args.title} ({args.source})")
    print(f"   Wejście w życie: {args.enactment} · lead: {lead} dni (cel ≥ 30) · "
          f"confidence: {args.confidence}")
    if lead < 30:
        print(f"   ⚠️  LEAD < 30 dni — tryb PILNY (SLO V1: 24 h / 4 h P0 jako fallback)")


def cmd_radar(args) -> None:
    data = load()
    today = date.today()
    rows = []
    for d in data["drafts"].values():
        if d["status"] != "DRAFT_LAW":
            continue
        enactment = date.fromisoformat(d["expected_enactment"])
        rows.append({
            "draft_id": d["draft_id"],
            "title": d["title"],
            "source": d["source"],
            "countdown_days": (enactment - today).days,
            "lead_days": d["lead_days"],
            "confidence_draft": d["confidence_draft"],
            "rules_prepared_shadow": len(d.get("rule_ids_prepared", [])),
            "status": d["status"],
        })
    rows.sort(key=lambda r: r["countdown_days"])
    print(json.dumps({
        "kpi": data["kpi"],
        "active_drafts": rows,
        "rule": "Reguły przygotowane na bazie projektu NIGDY nie wpływają na werdykty przed wejściem (SHADOW)",
    }, indent=2, ensure_ascii=False))
    if not rows:
        print("ℹ️  Brak aktywnych projektów — radar czysty")


def cmd_status(args) -> None:
    data = load()
    if args.draft_id not in data["drafts"]:
        sys.exit(f"❌ Brak projektu {args.draft_id}")
    if args.new_status not in STATUSES:
        sys.exit(f"❌ Status {args.new_status} ∉ {sorted(STATUSES)}")
    data["drafts"][args.draft_id]["status"] = args.new_status
    save(data)
    print(f"✅ {args.draft_id}: status → {args.new_status}")


def cmd_prepare(args) -> None:
    data = load()
    if args.draft_id not in data["drafts"]:
        sys.exit(f"❌ Brak projektu {args.draft_id}")
    rules = [r.strip() for r in args.rules.split(",") if r.strip()]
    data["drafts"][args.draft_id]["rule_ids_prepared"] = rules
    data["drafts"][args.draft_id]["reviewed_by"] = args.reviewer
    save(data)
    print(f"✅ {args.draft_id}: {len(rules)} reguł SHADOW przygotowanych "
          f"(review: {args.reviewer}) — w dniu wejścia tylko PROMOTE (zero wysiłku o północy)")


def main() -> None:
    p = argparse.ArgumentParser(description="Law Radar — V2 F5 (proaktywna adaptacja)")
    sub = p.add_subparsers(dest="cmd", required=True)

    t = sub.add_parser("track")
    t.add_argument("--source", choices=sorted(SOURCES), required=True)
    t.add_argument("--title", required=True)
    t.add_argument("--enactment", required=True)
    t.add_argument("--confidence", type=float, default=0.7)
    t.add_argument("--diff", default=None)
    t.set_defaults(fn=cmd_track)

    r = sub.add_parser("radar"); r.set_defaults(fn=cmd_radar)
    s = sub.add_parser("status")
    s.add_argument("--draft-id", required=True)
    s.add_argument("--new-status", choices=sorted(STATUSES), required=True)
    s.set_defaults(fn=cmd_status)
    pr = sub.add_parser("prepare")
    pr.add_argument("--draft-id", required=True)
    pr.add_argument("--rules", required=True)
    pr.add_argument("--reviewer", default="4-eyes")
    pr.set_defaults(fn=cmd_prepare)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
