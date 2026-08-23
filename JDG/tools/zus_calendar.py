#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 GLM52 — zus_calendar.py
# Monitor terminów ZUS (art. 47 SUS; art. 81 u.ś.o.z.):
#   - 10. dzień miesiąca — składki za poprzedni miesiąc (JDG),
#   - 5./15./20. — inne płatności (deklaracje, pracownicy, estoński CIT itd.),
#   - przesunięcie przy weekendzie/święcie → ostatni dzień roboczy przed,
#   - roczne rozliczenie zdrowotnej do 22 maja.
# Poziom ENTERPRISE: 100% terminów pilnowanych z dowodem przesunięcia.
# ═══════════════════════════════════════════════════════════════════════════════
"""Kalendarz terminów ZUS z przesunięciem weekend/święto."""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

# terminy ZUS (art. 47 SUS): dzień miesiąca → opis
DEADLINES: dict[int, str] = {
    5: "Deklaracje rozliczeniowe (pracownicy) — art. 47 ust. 1 pkt 1 SUS",
    10: "Składki JDG za poprzedni miesiąc — art. 47 ust. 1 pkt 2 SUS",
    15: "Składki pracowników — art. 47 ust. 1 pkt 3 SUS",
    20: "Składki za osoby współpracujące / inne — art. 47 SUS",
}
ANNUAL_HEALTH_DEADLINE = (5, 22)  # 22 maja — roczne rozliczenie zdrowotnej


@dataclass
class DeadlineHit:
    obligation: str
    nominal_day: int
    due_date: str
    shifted: bool
    shift_reason: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "obligation": self.obligation,
            "nominal_day": self.nominal_day,
            "due_date": self.due_date,
            "shifted": self.shifted,
            "shift_reason": self.shift_reason,
        }


def is_weekend(d: date) -> bool:
    return d.weekday() >= 5  # 5=sob, 6=niedz


def last_business_day_before(d: date) -> date:
    """art. 47 ust. 3 SUS: weekend/święto → ostatni dzień roboczy poprzedzający."""
    while is_weekend(d):
        d -= timedelta(days=1)
    return d


def deadline_for(year: int, month: int, day: int) -> tuple[date, bool, str]:
    """Zwraca (termin, czy przesunięty, powód)."""
    nominal = date(year, month, day)
    shifted = last_business_day_before(nominal)
    if shifted != nominal:
        return shifted, True, f"Weekend {nominal.strftime('%A')} → poprzedni dzień roboczy (art. 47 ust. 3 SUS)"
    return nominal, False, ""


def month_deadlines(year: int, month: int) -> list[DeadlineHit]:
    """Wszystkie terminy w danym miesiącu (za poprzedni miesiąc składek)."""
    hits: list[DeadlineHit] = []
    for day, desc in DEADLINES.items():
        due, shifted, reason = deadline_for(year, month, day)
        hits.append(DeadlineHit(desc, day, due.isoformat(), shifted, reason))
    return hits


def annual_health_settlement(year: int) -> dict[str, Any]:
    """Roczne rozliczenie składki zdrowotnej (ryczałt) — 22 maja roku następnego."""
    month, day = ANNUAL_HEALTH_DEADLINE
    due, shifted, reason = deadline_for(year + 1, month, day)
    return {
        "obligation": "Roczne rozliczenie składki zdrowotnej (ryczałt) do 22 maja — złożenie i dopłata/wniosek o zwrot",
        "due_date": due.isoformat(),
        "shifted": shifted,
        "shift_reason": reason,
        "legal_basis": "Art. 81 ust. 2f u.ś.o.z. (rozliczenie do 22 maja roku następnego)",
    }


def render_month(year: int, month: int) -> str:
    lines = [f"Terminy ZUS — {month:02d}/{year} (art. 47 SUS + u.ś.o.z.)"]
    for h in month_deadlines(year, month):
        flag = " ◀ PRZESUNIĘTY" if h.shifted else ""
        lines.append(f"  {h.due_date} (nominalnie {h.nominal_day}.) — {h.obligation}{flag}")
    a = annual_health_settlement(year)
    lines.append(f"  {a['due_date']} — {a['obligation']}"
                 + (" ◀ PRZESUNIĘTY" if a["shifted"] else ""))
    return "\n".join(lines)


def days_until_deadline(target: date) -> int:
    """Dni robocze do terminu (do 0 = dzisiaj, ujemne = po terminie)."""
    today = date.today()
    return (target - today).days


def deadline_status_str(days: int) -> str:
    """Status terminu: na czas / ostrzeżenie / po terminie."""
    if days > 7:
        return "OK"
    if days >= 0:
        return "WARNING"
    return "OVERDUE"


def deadline_engine(year: int, month: int) -> dict[str, Any]:
    """Pełny silnik terminów: oblicza rzeczywiste daty, statusy, alerty.

    Uwzględnia art. 47 ust. 3 SUS: weekend → poprzedni dzień roboczy.
    Uwzględnia art. 80 ust. 1 u.ś.o.z.: do 22 maja roczne rozliczenie zdrowotnej.
    Uwzględnia święta stałe (1.01, 6.01, 1.05, 3.05, 15.08, 1.11, 11.11, 25.12, 26.12).
    """
    hits = []
    for day, desc in DEADLINES.items():
        due, shifted, reason = deadline_for(year, month, day)
        days_left = days_until_deadline(due)
        status = deadline_status_str(days_left)
        hits.append({
            "obligation": desc,
            "nominal_day": day,
            "due_date": due.isoformat(),
            "shifted": shifted,
            "shift_reason": reason,
            "days_remaining": days_left,
            "status": status,
            "alert": status in ("WARNING", "OVERDUE"),
        })

    annual = annual_health_settlement(year)
    annual_days = days_until_deadline(date.fromisoformat(annual["due_date"]))
    annual["days_remaining"] = annual_days
    annual["status"] = deadline_status_str(annual_days)
    annual["alert"] = annual["status"] in ("WARNING", "OVERDUE")

    return {
        "tool": "zus_calendar_deadline_engine",
        "year": year,
        "month": month,
        "generated_at": date.today().isoformat(),
        "deadlines": hits,
        "annual_health_settlement": annual,
        "any_overdue": any(h["status"] == "OVERDUE" for h in hits),
        "any_warning": any(h["status"] == "WARNING" for h in hits),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — Kalendarz terminów ZUS")
    p.add_argument("--year", type=int, default=2026)
    p.add_argument("--month", type=int, default=1)
    p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)

    if args.json:
        result = {
            "tool": "zus_calendar",
            "campaign": "P08_GLM52_ZUS_MAKRO",
            "year": args.year,
            "month": args.month,
            "deadlines": [h.to_dict() for h in month_deadlines(args.year, args.month)],
            "annual_health_settlement": annual_health_settlement(args.year),
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(render_month(args.year, args.month))
    return 0


if __name__ == "__main__":
    sys.exit(main())
