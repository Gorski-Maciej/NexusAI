#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — KKS Limitations Calendar (INN04 — P09 Report)
═══════════════════════════════════════════════════════════════════════════════

Kalendarz przedawnień KKS:
  - Przestępstwa skarbowe: 5 lat (Art. 44 § 1) + max 10 lat
  - Wykroczenia skarbowe: 3 lata (Art. 51 § 1) + max 5 lat
  - Przedawnienie wykonania kary: 10 lat (Art. 44 § 5)
  - Zatarcie skazania: 3 lata (wykr.) / 5 lat (przestęp.)

Użycie:
    python JDG/tools/kks_limitations_calendar.py --offense-date 2021-06-15 --type CRIME
    python JDG/tools/kks_limitations_calendar.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse, json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

LIMITATION_RULES = {
    "CRIME": {"name": "Przestępstwo skarbowe", "years": 5, "max_years": 10, "legal_basis": "Art. 44 § 1-2 KKS"},
    "MISDEMEANOR": {"name": "Wykroczenie skarbowe", "years": 3, "max_years": 5, "legal_basis": "Art. 51 § 1 KKS"},
    "EXECUTION": {"name": "Wykonanie kary", "years": 10, "max_years": 10, "legal_basis": "Art. 44 § 5 KKS"},
    "REHABILITATION_CRIME": {"name": "Zatarcie skazania (przestępstwo)", "years": 5, "max_years": 5, "legal_basis": "Art. 21 KKS"},
    "REHABILITATION_MISD": {"name": "Zatarcie skazania (wykroczenie)", "years": 3, "max_years": 3, "legal_basis": "Art. 21 KKS"},
}


class KKSLimitationsCalendar:
    """INN04 P09: KKS Statute of Limitations Calendar."""

    def _safe_add_years(self, d, years):
        """Safely add years to a date, avoiding leap year crashes."""
        try:
            return d.replace(year=d.year + years)
        except ValueError:
            # Feb 29 in non-leap year → Feb 28
            return d.replace(year=d.year + years, day=28)

    def calculate(self, offense_date_str, offense_type="CRIME", proceedings_interrupted=False, extension_triggered=False):
        offense_date = date.fromisoformat(offense_date_str)
        rules = LIMITATION_RULES[offense_type]
        base_years = rules["years"]
        effective_years = rules["max_years"] if extension_triggered else base_years

        limitation_date = self._safe_add_years(offense_date, effective_years)

        if proceedings_interrupted:
            limitation_date = self._safe_add_years(date.today(), effective_years)

        today = date.today()
        days_remaining = (limitation_date - today).days
        is_barred = days_remaining <= 0

        result = {
            "offense_type": rules["name"],
            "offense_date": offense_date.isoformat(),
            "limitation_date": limitation_date.isoformat(),
            "base_years": base_years,
            "effective_years": effective_years,
            "days_remaining": days_remaining,
            "is_barred": is_barred,
            "proceedings_interrupted": proceedings_interrupted,
            "extension_triggered": extension_triggered,
            "legal_basis": rules["legal_basis"],
        }

        if is_barred:
            result["status"] = "PRZEDAWNIONE — brak odpowiedzialności"
        elif days_remaining <= 180:
            result["status"] = f"UWAGA: tylko {days_remaining} dni do przedawnienia!"
        elif days_remaining <= 365:
            result["status"] = f"Przedawnienie za {days_remaining} dni"
        else:
            result["status"] = "AKTYWNE"

        return result

    def generate_timeline(self, offense_date_str):
        """Generate full timeline of all limitation types."""
        offense_date = date.fromisoformat(offense_date_str)
        timeline = []

        for key, rules in LIMITATION_RULES.items():
            lim_date = self._safe_add_years(offense_date, rules["years"])
            days_left = (lim_date - date.today()).days
            timeline.append({
                "type": rules["name"],
                "limitation_date": lim_date.isoformat(),
                "years": rules["years"],
                "days_remaining": days_left,
                "barred": days_left <= 0,
                "legal_basis": rules["legal_basis"],
            })

        return sorted(timeline, key=lambda x: x["days_remaining"])

    def generate_report(self):
        return {
            "tool": "KKS Limitations Calendar (INN04 P09)",
            "version": "1.0.0",
            "rules": {k: {"years": v["years"], "max_years": v["max_years"]} for k, v in LIMITATION_RULES.items()},
        }


def main():
    parser = argparse.ArgumentParser(description="KKS Limitations Calendar (INN04 P09)")
    parser.add_argument("--offense-date", type=str, default="2024-01-01", help="Offense date (YYYY-MM-DD)")
    parser.add_argument("--type", type=str, default="CRIME", choices=LIMITATION_RULES.keys())
    parser.add_argument("--interrupted", action="store_true", help="Proceedings interrupted limitation")
    parser.add_argument("--extended", action="store_true", help="Extension to max years triggered")
    parser.add_argument("--timeline", action="store_true", help="Show full timeline")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    cal = KKSLimitationsCalendar()

    if args.timeline:
        timeline = cal.generate_timeline(args.offense_date)
        print(f"\n  📅 KALENDARZ PRZEDAWNIEŃ KKS:")
        print(f"  {'Typ':<35s} | {'Data przedawn.':>12s} | {'Lata':>4s} | {'Dni':>6s} | Status")
        print(f"  {'-'*35}-+-{'-'*12}-+-{'-'*4}-+-{'-'*6}-+-------")
        for t in timeline:
            icon = "✅" if t["barred"] else "⏳" if t["days_remaining"] < 365 else "🔵"
            print(f"  {t['type']:<35s} | {t['limitation_date']:>12s} | {t['years']:>4d} | {t['days_remaining']:>6d} | {icon}")
        return

    result = cal.calculate(args.offense_date, args.type, args.interrupted, args.extended)

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"\n  ⏰ PRZEDAWNIENIE KKS:")
        print(f"     Typ: {result['offense_type']}")
        print(f"     Data czynu: {result['offense_date']}")
        print(f"     Przedawnienie: {result['limitation_date']} ({result['effective_years']} lat)")
        print(f"     Status: {result['status']}")
        print(f"     Podstawa: {result['legal_basis']}")

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P09_INN04_KKS_LIMITATIONS.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write("P09 INN04 — KKS Limitations Calendar\n")
        print(f"  📄 {path}")


if __name__ == "__main__":
    main()
