#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Preferential Period Atom Tracker (INN07 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Atomowe śledzenie okresów ulgowych ZUS:
  - START_RELIEF: 6 miesięcy (Art. 18a SUS)
  - PREFERENTIAL: 24 miesiące (Art. 18c SUS)
  - SMALL_ZUS_PLUS: 36 miesięcy (Art. 18c ust. 8 SUS)
  - STANDARD: bez limitu

Śledzi pozostałe miesiące, ostrzega 3 miesiące przed końcem,
auto-przejście między poziomami.

Użycie:
    python JDG/tools/preferential_period_tracker.py --relief PREFERENTIAL --months 21
    python JDG/tools/preferential_period_tracker.py --simulate
    python JDG/tools/preferential_period_tracker.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── Relief definitions ───────────────────────────────────────────────────────

RELIEF_PERIODS = {
    "START_RELIEF": {
        "name": "Ulga na start",
        "max_months": 6,
        "legal_basis": "Art. 18a SUS",
        "social_base": 0,  # No social contributions
        "health_required": True,
        "next_relief": "PREFERENTIAL",
        "description": "6 miesięcy bez składek społecznych (tylko zdrowotna)",
        "requirements": {
            "no_previous_jdg_60m": True,
            "not_previously_used": True,
        },
    },
    "PREFERENTIAL": {
        "name": "Preferencyjny ZUS",
        "max_months": 24,
        "legal_basis": "Art. 18c SUS",
        "social_base_pct": 30,  # 30% minimalnego wynagrodzenia
        "next_relief": "SMALL_ZUS_PLUS",
        "description": "24 miesiące na 30% minimalnego wynagrodzenia",
        "requirements": {
            "not_exceeded_24m": True,
            "after_start_relief_or_new": True,
        },
    },
    "SMALL_ZUS_PLUS": {
        "name": "Mały ZUS+",
        "max_months": 36,
        "legal_basis": "Art. 18c ust. 8 SUS",
        "social_base_pct": 30,  # 30% minimalnego
        "revenue_limit": 120000,
        "next_relief": "STANDARD",
        "description": "36 miesięcy na 30% minimalnego, limit przychodu 120k/rok",
        "requirements": {
            "revenue_below_120k": True,
            "not_exceeded_36m": True,
            "after_preferential": True,
        },
    },
    "STANDARD": {
        "name": "Standardowy ZUS",
        "max_months": None,  # Unlimited
        "legal_basis": "Art. 18 SUS",
        "social_base_pct": 60,  # 60% przeciętnego wynagrodzenia
        "next_relief": None,
        "description": "Standardowa składka: 60% przeciętnego wynagrodzenia",
    },
}

RELIEF_TRANSITIONS = [
    ("START_RELIEF", "PREFERENTIAL"),
    ("PREFERENTIAL", "SMALL_ZUS_PLUS"),
    ("SMALL_ZUS_PLUS", "STANDARD"),
]


class PreferentialPeriodTracker:
    """INN07: Preferential Period Atom Tracker."""

    def __init__(self, current_relief="PREFERENTIAL", months_used=0,
                 start_date=None, annual_revenue=0):
        self.current_relief = current_relief
        self.months_used = months_used
        self.start_date = start_date or date.today()
        self.annual_revenue = annual_revenue
        self.alerts = []
        self.timeline = []

    def track(self):
        """Track current relief period."""
        relief = RELIEF_PERIODS.get(self.current_relief)
        if not relief:
            return {"error": f"Unknown relief: {self.current_relief}"}

        max_months = relief["max_months"]
        remaining = max_months - self.months_used if max_months else float("inf")

        result = {
            "relief": self.current_relief,
            "name": relief["name"],
            "months_used": self.months_used,
            "max_months": max_months if max_months else "bez limitu",
            "remaining_months": remaining if isinstance(remaining, (int, float)) and remaining != float("inf") else "bez limitu",
            "legal_basis": relief["legal_basis"],
            "next_relief": relief["next_relief"],
            "end_date": None,
            "status": "ACTIVE",
        }

        if max_months:
            end_date = self.start_date + timedelta(days=max_months * 30)
            result["end_date"] = end_date.isoformat()

            if remaining <= 0:
                result["status"] = "EXPIRED"
                self.alerts.append(
                    f"🔴 {relief['name']}: OKRES WYGASŁ! "
                    f"Przejdź na {relief['next_relief']}."
                )
            elif remaining <= 3:
                result["status"] = "EXPIRING_SOON"
                self.alerts.append(
                    f"🟡 {relief['name']}: zostało {remaining} miesięcy! "
                    f"Przygotuj się na przejście do {relief['next_relief']}."
                )
                self._predict_next_relief_cost(relief)
            elif remaining <= 6:
                result["status"] = "MID_TERM"
                self.alerts.append(
                    f"🔵 {relief['name']}: pozostało {remaining} miesięcy."
                )

        # Check SMALL_ZUS_PLUS revenue limit
        if self.current_relief == "SMALL_ZUS_PLUS" and self.annual_revenue > RELIEF_PERIODS["SMALL_ZUS_PLUS"]["revenue_limit"]:
            result["status"] = "REVENUE_LIMIT_EXCEEDED"
            self.alerts.append(
                f"🔴 Mały ZUS+: Przychód {self.annual_revenue:,.0f} PLN przekracza "
                f"limit {RELIEF_PERIODS['SMALL_ZUS_PLUS']['revenue_limit']:,} PLN!"
            )

        return result

    def _predict_next_relief_cost(self, current_relief):
        """Predict cost of next relief level."""
        next_relief = RELIEF_PERIODS.get(current_relief["next_relief"], {})
        if next_relief:
            current_pct = current_relief.get("social_base_pct", 0)
            next_pct = next_relief.get("social_base_pct", 60)
            delta = next_pct - current_pct

            if delta > 0:
                # Estimate based on 2026 minimal wage (4666 PLN)
                current_base = 4666 * current_pct / 100 if current_pct else 0
                next_base = 4666 * next_pct / 100
                monthly_diff = (next_base * 0.3164) - (current_base * 0.3164) if current_base else (next_base * 0.3164)

                self.alerts.append(
                    f"💰 Szacowany wzrost składek: +{monthly_diff:.0f} PLN/miesiąc "
                    f"przy przejściu {self.current_relief} → {current_relief['next_relief']}"
                )

    def simulate_timeline(self):
        """Simulate full relief timeline from start to standard."""
        self.timeline = []

        for relief_name, next_name in RELIEF_TRANSITIONS:
            relief = RELIEF_PERIODS[relief_name]
            months = relief["max_months"]
            monthly_social = 0

            if relief.get("social_base_pct"):
                base = 4666 * relief["social_base_pct"] / 100
                monthly_social = round(base * 0.3164, 2)
            elif relief.get("social_base") == 0:
                monthly_social = 0

            self.timeline.append({
                "phase": relief_name,
                "name": relief["name"],
                "months": months,
                "monthly_social_contribution": monthly_social,
                "total_social_cost": round(monthly_social * months, 2) if months else "ongoing",
                "legal_basis": relief["legal_basis"],
            })

        # Add STANDARD (ongoing)
        standard = RELIEF_PERIODS["STANDARD"]
        base = 8190 * 0.60
        self.timeline.append({
            "phase": "STANDARD",
            "name": standard["name"],
            "months": "ongoing",
            "monthly_social_contribution": round(base * 0.3164, 2),
            "total_social_cost": "ongoing",
            "legal_basis": standard["legal_basis"],
        })

        return self.timeline

    def generate_report(self):
        """Generate comprehensive report."""
        self.simulate_timeline()

        total_saved = sum(
            (8190 * 0.60 * 0.3164 - t["monthly_social_contribution"]) * t["months"]
            for t in self.timeline[:-1]
            if isinstance(t["months"], int) and t["monthly_social_contribution"] < 8190 * 0.60 * 0.3164
        )

        return {
            "tool": "Preferential Period Atom Tracker (INN07)",
            "version": "1.0.0",
            "current_relief": self.current_relief,
            "months_used": self.months_used,
            "timeline": self.timeline,
            "total_relief_savings": round(total_saved, 2),
            "alerts": self.alerts,
        }


def print_report(tracker, report):
    """Print human-readable report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Preferential Period Atom Tracker (INN07)")
    print(f"  Obecna ulga: {report['current_relief']} ({report['months_used']} miesięcy)")
    print(f"  Łączne oszczędności na ulgach: {report['total_relief_savings']:,.2f} PLN")
    print("═" * 78)

    print(f"\n  📅 TIMELINE ULG ZUS:")
    print(f"  {'Faza':<20s} | {'Miesiące':>8s} | {'Składka/mies.':>12s} | {'Koszt całkowity':>14s}")
    print(f"  {'-'*20}-+-{'-'*8}-+-{'-'*12}-+-{'-'*14}")

    for t in report["timeline"]:
        months = str(t["months"]) if t["months"] else "∞"
        monthly = f"{t['monthly_social_contribution']:.2f} PLN" if isinstance(t['monthly_social_contribution'], (int, float)) else str(t['monthly_social_contribution'])
        total = f"{t['total_social_cost']:,.2f} PLN" if isinstance(t['total_social_cost'], (int, float)) else str(t['total_social_cost'])
        print(f"  {t['name']:<20s} | {months:>8s} | {monthly:>12s} | {total:>14s}")

    if tracker.alerts:
        print(f"\n  ⚠️  ALERTY:")
        for alert in tracker.alerts:
            print(f"     {alert}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Preferential Period Tracker (INN07)")
    parser.add_argument("--relief", type=str, default="PREFERENTIAL",
                        choices=["START_RELIEF", "PREFERENTIAL", "SMALL_ZUS_PLUS", "STANDARD"])
    parser.add_argument("--months", type=int, default=0, help="Months already used")
    parser.add_argument("--revenue", type=float, default=0, help="Annual revenue (for SMALL_ZUS_PLUS)")
    parser.add_argument("--simulate", action="store_true", help="Simulate full timeline")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tracker = PreferentialPeriodTracker(
        current_relief=args.relief,
        months_used=args.months,
        annual_revenue=args.revenue,
    )

    track_result = tracker.track()

    if args.json:
        report = tracker.generate_report()
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        if args.simulate:
            timeline = tracker.simulate_timeline()
            print(f"\n  📅 SYMULACJA PEŁNEJ ŚCIEŻKI:")
            for t in timeline:
                monthly = f"{t['monthly_social_contribution']:.2f} PLN" if isinstance(t['monthly_social_contribution'], (int, float)) else "—"
                print(f"     {t['name']}: {t['months']} mies. × {monthly} = {t['total_social_cost']}")

        if args.months > 0:
            print(f"\n  📊 STATUS: {track_result['name']}")
            print(f"     Wykorzystano: {track_result['months_used']}/{track_result['max_months']} miesięcy")
            print(f"     Pozostało: {track_result['remaining_months']}")
            print(f"     Status: {track_result['status']}")

        report = tracker.generate_report()
        print_report(tracker, report)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN07_PREFERENTIAL_TRACKER.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        rep = tracker.generate_report()
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN07 — Preferential Period Atom Tracker\n")
            f.write(f"Savings: {rep['total_relief_savings']:,.2f} PLN\n\n")
            for t in rep["timeline"]:
                f.write(f"{t['name']}: {t['months']}m × {t['monthly_social_contribution']} PLN\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
