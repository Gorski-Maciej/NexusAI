#!/usr/bin/env python3
"""
NexusAI JDG — LIMITATIONS CALENDAR (P02 Warstwa Decyzyjna — Sekcja 4 Enterprise)
=================================================================================
Kalendarz przedawnień per zobowiązanie z alertami:
  • build    — zbuduj kalendarz przedawnień z listy zobowiązań (JSON/CSV)
  • alerts   — listuj alerty (EXPIRED/CRITICAL/ALERT) dla danego roku
  • emit     — wygeneruj JSON dla input.limitations_calendar (OPA)

Podstawa prawna:
  • Art. 70 §1 Ordynacji podatkowej — 5 lat (koniec roku terminu płatności)
  • Art. 70 §2 OP — 10 lat (przestępstwo skarbowe)
  • Art. 118 ustawy o SUS — 5 lat (składki ZUS)
  • Art. 86 §1 OP — 5 lat retencji dokumentów

Usage:
  python limitations_calendar.py build --file obligations.json
  python limitations_calendar.py alerts --year 2026
  python limitations_calendar.py emit --file obligations.json
"""

import argparse
import json
import sys
from pathlib import Path

# Okresy przedawnienia per typ zobowiązania (art. 70 §1/§2 OP)
PERIOD_YEARS = {"VAT": 5, "PIT": 5, "ZUS": 5, "MDR": 5, "CIT": 5, "FISCAL_CRIME": 10}

# Art. 70 §1 OP: 5 lat LICZĄC OD KOŃCA ROKU KALENDARZOWEGO, w którym upłynął
# termin płatności. Dla zobowiązań rocznych (PIT, CIT, MDR) termin płatności
# przypada w roku NASTĘPNYM po roku podatkowym (np. PIT za 2020 → 30.04.2021),
# więc okno zamyka się na koniec tax_year + 1 + okresu.
DEADLINE_YEAR_OFFSET = {"VAT": 0, "PIT": 1, "ZUS": 0, "MDR": 1, "CIT": 1, "FISCAL_CRIME": 0}


def load_obligations(path: Path) -> list:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data if isinstance(data, list) else data.get("obligations", [])


def build_calendar(obligations: list, today_year: int) -> list:
    entries = []
    for ob in obligations:
        ob_type = ob.get("type", "VAT")
        tax_year = int(ob.get("tax_year", today_year))
        years = PERIOD_YEARS.get(ob_type, 5)
        offset = DEADLINE_YEAR_OFFSET.get(ob_type, 0)
        # Przedawnienie na koniec roku, w którym upłynął termin płatności + okres
        expire_year = tax_year + offset + years
        remaining = expire_year - today_year
        status = ("EXPIRED" if remaining < 0
                  else "CRITICAL" if remaining == 0
                  else "ALERT" if remaining == 1
                  else "WATCH" if remaining <= 3
                  else "OK")
        entries.append({
            "obligation_type": ob_type,
            "tax_year": tax_year,
            "expire_year": expire_year,
            "remaining_years": remaining,
            "status": status,
            "legal_basis": "Art. 70 §2 OP (10 lat)" if ob_type == "FISCAL_CRIME" else "Art. 70 §1 OP (5 lat)",
        })
    return entries


def cmd_build(args) -> None:
    obligations = load_obligations(Path(args.file))
    today_year = int(args.today_year)
    calendar = build_calendar(obligations, today_year)
    out = Path(args.output) if args.output else Path(__file__).resolve().parent.parent / "bundles" / "limitations_calendar.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(calendar, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(calendar, indent=2, ensure_ascii=False))
    print(f"✅ Kalendarz zapisany: {out}")


def cmd_alerts(args) -> None:
    obligations = load_obligations(Path(args.file))
    today_year = int(args.today_year)
    calendar = build_calendar(obligations, today_year)
    alerts = [e for e in calendar if e["status"] in ("EXPIRED", "CRITICAL", "ALERT")]
    if not alerts:
        print(f"✅ Brak alertów przedawnień w roku {today_year} — kalendarz czysty")
        return
    print(f"⚠️  {len(alerts)} alertów przedawnień w roku {today_year}:")
    print(json.dumps(alerts, indent=2, ensure_ascii=False))
    sys.exit(2)  # sygnał dla CI


def cmd_emit(args) -> None:
    obligations = load_obligations(Path(args.file))
    today_year = int(args.today_year)
    calendar = build_calendar(obligations, today_year)
    # Format do wstrzyknięcia w input.limitations_calendar.obligations (OPA)
    payload = {"obligations": [{"type": e["obligation_type"], "tax_year": e["tax_year"]} for e in calendar]}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    print("# Host wstrzykuje: input.limitations_calendar (rego: jdg.decision_core_completeness)")


def main() -> None:
    p = argparse.ArgumentParser(description="Limitations Calendar — P02 Sekcja 4")
    p.add_argument("--today-year", default="2026", help="Rok odniesienia")
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("build")
    b.add_argument("--file", required=True)
    b.add_argument("--output", default=None)
    b.set_defaults(fn=cmd_build)

    a = sub.add_parser("alerts")
    a.add_argument("--file", required=True)
    a.set_defaults(fn=cmd_alerts)

    e = sub.add_parser("emit")
    e.add_argument("--file", required=True)
    e.set_defaults(fn=cmd_emit)

    args = p.parse_args()
    args.today_year = args.today_year
    args.fn(args)


if __name__ == "__main__":
    main()
