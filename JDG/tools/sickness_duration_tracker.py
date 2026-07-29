#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Sickness Duration Tracker (INN03 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Śledzenie łącznego czasu choroby w roku kalendarzowym.
Ostrzega o zbliżającym się limicie 182/270 dni.
Integracja z zasiłkiem chorobowym, macierzyńskim, opiekuńczym.

Parametry:
  - Zasiłek chorobowy: 80% podstawy (70% szpital), max 182 dni (270 gruźlica/ciąża)
  - Zasiłek macierzyński: 100% podstawy, 20-37 tygodni
  - Zasiłek opiekuńczy: 80% podstawy, 60 dni (dziecko) / 14 dni (rodzina)
  - Okres wyczekiwania: 90 dni

Użycie:
    python JDG/tools/sickness_duration_tracker.py --sick-days 45 --ytd-sick 120
    python JDG/tools/sickness_duration_tracker.py --simulate
    python JDG/tools/sickness_duration_tracker.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── Sickness benefit parameters ──────────────────────────────────────────────

SICKNESS_PARAMS = {
    "standard": {
        "max_days": 182,
        "benefit_rate": 0.80,
        "hospital_rate": 0.70,
        "waiting_period_days": 90,
        "name": "Zasiłek chorobowy (standard)",
    },
    "extended": {
        "max_days": 270,
        "benefit_rate": 0.80,
        "conditions": ["gruźlica", "ciąża"],
        "name": "Zasiłek chorobowy (przedłużony)",
    },
}

MATERNITY_PARAMS = {
    "standard": {"weeks": 20, "benefit_rate": 1.00, "name": "Macierzyński standard"},
    "extended": {"weeks": 37, "benefit_rate": 1.00, "name": "Macierzyński max (łączenie)"},
    "waiting_period_days": 90,
}

CARE_PARAMS = {
    "child": {"max_days": 60, "benefit_rate": 0.80, "child_age": 14, "name": "Opiekuńczy — dziecko (do 14 lat)"},
    "family": {"max_days": 14, "benefit_rate": 0.80, "name": "Opiekuńczy — rodzina"},
}


class SicknessDurationTracker:
    """INN03: Sickness Duration Tracker."""

    def __init__(self, ytd_sick_days=0, ytd_care_child_days=0, ytd_care_family_days=0,
                 ytd_maternity_weeks=0, is_hospital=False, has_tb_or_pregnancy=False,
                 monthly_contribution_base=5000.00):
        self.ytd_sick_days = ytd_sick_days
        self.ytd_care_child_days = ytd_care_child_days
        self.ytd_care_family_days = ytd_care_family_days
        self.ytd_maternity_weeks = ytd_maternity_weeks
        self.is_hospital = is_hospital
        self.has_tb_or_pregnancy = has_tb_or_pregnancy
        self.monthly_base = monthly_contribution_base
        self.alerts = []

    def track_sickness(self, new_sick_days):
        """Track new sickness days and check against limits."""
        total = self.ytd_sick_days + new_sick_days
        max_days = SICKNESS_PARAMS["extended"]["max_days"] if self.has_tb_or_pregnancy else SICKNESS_PARAMS["standard"]["max_days"]
        rate = SICKNESS_PARAMS["standard"]["hospital_rate"] if self.is_hospital else SICKNESS_PARAMS["standard"]["benefit_rate"]

        remaining = max_days - total
        daily_benefit = round(self.monthly_base * rate / 30, 2)

        result = {
            "days_used": total,
            "new_days": new_sick_days,
            "max_days": max_days,
            "remaining_days": remaining,
            "benefit_rate": f"{rate*100:.0f}%",
            "daily_benefit": daily_benefit,
            "incremental_benefit": round(daily_benefit * new_sick_days, 2),
            "total_benefit_ytd": round(daily_benefit * total, 2),
            "status": "OK",
        }

        if remaining <= 0:
            result["status"] = "EXHAUSTED"
            self.alerts.append("🔴 WYCZERPANO limit zasiłku chorobowego! Rozważ zasiłek rehabilitacyjny.")
        elif remaining <= 30:
            result["status"] = "WARNING"
            self.alerts.append(f"🟡 Zostało tylko {remaining} dni zasiłku chorobowego!")
        elif remaining <= 60:
            result["status"] = "INFO"
            self.alerts.append(f"🔵 Pozostało {remaining} dni zasiłku chorobowego.")

        return result

    def track_maternity(self, claim_weeks=20):
        """Track maternity leave."""
        total_weeks = self.ytd_maternity_weeks + claim_weeks
        max_weeks = MATERNITY_PARAMS["extended"]["weeks"]
        rate = MATERNITY_PARAMS["standard"]["benefit_rate"]

        weekly_benefit = round(self.monthly_base * rate / 4.33, 2)

        result = {
            "weeks_claimed": claim_weeks,
            "total_weeks": total_weeks,
            "max_weeks": max_weeks,
            "remaining_weeks": max_weeks - total_weeks,
            "benefit_rate": f"{rate*100:.0f}%",
            "weekly_benefit": weekly_benefit,
            "total_benefit": round(weekly_benefit * claim_weeks, 2),
            "can_continue_business": True,
            "requires_sickness_insurance": True,
            "waiting_period_days": MATERNITY_PARAMS["waiting_period_days"],
        }

        if total_weeks > max_weeks:
            result["status"] = "EXCEEDED"
            self.alerts.append("🔴 Przekroczono maksymalny wymiar zasiłku macierzyńskiego!")

        return result

    def track_care(self, care_type, days):
        """Track care leave."""
        params = CARE_PARAMS[care_type]
        ytd = self.ytd_care_child_days if care_type == "child" else self.ytd_care_family_days
        total = ytd + days
        remaining = params["max_days"] - total
        rate = params["benefit_rate"]

        daily_benefit = round(self.monthly_base * rate / 30, 2)

        result = {
            "care_type": params["name"],
            "days_used": total,
            "max_days": params["max_days"],
            "remaining_days": remaining,
            "benefit_rate": f"{rate*100:.0f}%",
            "daily_benefit": daily_benefit,
            "total_benefit": round(daily_benefit * days, 2),
        }

        if remaining <= 0:
            self.alerts.append(f"🔴 Wyczerpano limit zasiłku opiekuńczego ({params['name']})!")
        elif remaining <= 7:
            self.alerts.append(f"🟡 Zostało tylko {remaining} dni zasiłku opiekuńczego.")

        return result

    def check_waiting_period(self, months_insured):
        """Check if waiting period is satisfied."""
        if months_insured >= 3:  # 90 days ≈ 3 months
            return {"satisfied": True, "months_insured": months_insured}
        else:
            remaining = 90 - months_insured * 30
            return {
                "satisfied": False,
                "months_insured": months_insured,
                "days_remaining": remaining,
                "message": f"Okres wyczekiwania: pozostało {remaining} dni"
            }

    def generate_annual_summary(self):
        """Generate annual sickness benefit summary."""
        sick = self.track_sickness(0)
        return {
            "tool": "Sickness Duration Tracker (INN03)",
            "version": "1.0.0",
            "2026_limits": {
                "sickness_standard_days": 182,
                "sickness_extended_days": 270,
                "maternity_weeks": 37,
                "care_child_days": 60,
                "care_family_days": 14,
                "waiting_period_days": 90,
            },
            "ytd_usage": {
                "sick_days": self.ytd_sick_days,
                "care_child_days": self.ytd_care_child_days,
                "care_family_days": self.ytd_care_family_days,
                "maternity_weeks": self.ytd_maternity_weeks,
            },
            "remaining": {
                "sick_days": max(0, 182 - self.ytd_sick_days),
                "care_child_days": max(0, 60 - self.ytd_care_child_days),
                "care_family_days": max(0, 14 - self.ytd_care_family_days),
                "maternity_weeks": max(0, 37 - self.ytd_maternity_weeks),
            },
            "monthly_contribution_base": self.monthly_base,
            "alerts": self.alerts,
        }


def print_report(tracker):
    """Print human-readable tracker report."""
    summary = tracker.generate_annual_summary()
    print()
    print("═" * 78)
    print("  NexusAI JDG — Sickness Duration Tracker (INN03)")
    print(f"  Podstawa wymiaru: {tracker.monthly_base:.2f} PLN")
    print("═" * 78)

    print(f"\n  📊 WYKORZYSTANIE YTD:")
    y = summary["ytd_usage"]
    r = summary["remaining"]
    print(f"     Zasiłek chorobowy: {y['sick_days']}/182 dni (pozostało: {r['sick_days']})")
    print(f"     Zasiłek opiekuńczy (dziecko): {y['care_child_days']}/60 dni (pozostało: {r['care_child_days']})")
    print(f"     Zasiłek opiekuńczy (rodzina): {y['care_family_days']}/14 dni (pozostało: {r['care_family_days']})")
    print(f"     Zasiłek macierzyński: {y['maternity_weeks']}/37 tygodni (pozostało: {r['maternity_weeks']})")

    print(f"\n  💰 STAWKI DZIENNE (przy podstawie {tracker.monthly_base:.2f} PLN):")
    print(f"     Chorobowy (80%): {tracker.monthly_base * 0.80 / 30:.2f} PLN/dzień")
    print(f"     Chorobowy szpital (70%): {tracker.monthly_base * 0.70 / 30:.2f} PLN/dzień")
    print(f"     Macierzyński (100%): {tracker.monthly_base * 1.00 / 4.33:.2f} PLN/tydzień")
    print(f"     Opiekuńczy (80%): {tracker.monthly_base * 0.80 / 30:.2f} PLN/dzień")

    if tracker.alerts:
        print(f"\n  ⚠️  ALERTY:")
        for alert in tracker.alerts:
            print(f"     {alert}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Sickness Duration Tracker (INN03)")
    parser.add_argument("--sick-days", type=int, default=0, help="New sickness days to track")
    parser.add_argument("--ytd-sick", type=int, default=0, help="YTD sickness days already used")
    parser.add_argument("--care-child", type=int, default=0, help="New child care days")
    parser.add_argument("--care-family", type=int, default=0, help="New family care days")
    parser.add_argument("--maternity-weeks", type=int, default=0, help="Maternity weeks claimed")
    parser.add_argument("--hospital", action="store_true", help="Hospital stay (70% rate)")
    parser.add_argument("--extended", action="store_true", help="Extended limit (270 days, TB/pregnancy)")
    parser.add_argument("--base", type=float, default=5000.00, help="Monthly contribution base")
    parser.add_argument("--simulate", action="store_true", help="Run full simulation")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tracker = SicknessDurationTracker(
        ytd_sick_days=args.ytd_sick,
        ytd_care_child_days=0,
        ytd_care_family_days=0,
        ytd_maternity_weeks=0,
        is_hospital=args.hospital,
        has_tb_or_pregnancy=args.extended,
        monthly_contribution_base=args.base,
    )

    if args.simulate:
        print(f"\n  🏥 SYMULACJA PEŁNEGO ROKU:")
        # Simulate various scenarios
        for sick_days in [30, 90, 150, 182, 200]:
            result = tracker.track_sickness(sick_days)
            print(f"     Po {sick_days} dniach: {result['remaining_days']} pozostało, {result['total_benefit_ytd']:.2f} PLN")
        return

    if args.sick_days > 0:
        result = tracker.track_sickness(args.sick_days)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🏥 ZASIŁEK CHOROBOWY:")
            print(f"     Wykorzystano: {result['days_used']}/{result['max_days']} dni")
            print(f"     Pozostało: {result['remaining_days']} dni")
            print(f"     Stawka: {result['benefit_rate']} = {result['daily_benefit']:.2f} PLN/dzień")
            print(f"     Świadczenie YTD: {result['total_benefit_ytd']:.2f} PLN")

    if args.care_child > 0:
        result = tracker.track_care("child", args.care_child)
        print(f"\n  👶 ZASIŁEK OPIEKUŃCZY (dziecko):")
        print(f"     Wykorzystano: {result['days_used']}/{result['max_days']} dni")
        print(f"     Świadczenie: {result['total_benefit']:.2f} PLN")

    if args.maternity_weeks > 0:
        result = tracker.track_maternity(args.maternity_weeks)
        print(f"\n  🤰 ZASIŁEK MACIERZYŃSKI:")
        print(f"     Wymiar: {result['total_weeks']}/{result['max_weeks']} tygodni")
        print(f"     Świadczenie: {result['total_benefit']:.2f} PLN")

    if not any([args.sick_days, args.care_child, args.maternity_weeks, args.simulate]):
        print_report(tracker)

    for alert in tracker.alerts:
        print(f"     {alert}")

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN03_SICKNESS_TRACKER.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        summary = tracker.generate_annual_summary()
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN03 — Sickness Duration Tracker\n")
            f.write(f"Limits: 182/270 sick, 37 maternity, 60/14 care\n")
            f.write(f"Alerts: {len(tracker.alerts)}\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
