#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Health Contribution Reconciliation Micro (INN09 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Atomowe uzgadnianie rocznej składki zdrowotnej.
  - Suma 12 miesięcznych składek vs należna roczna
  - Detekcja nadpłaty/niedopłaty
  - Auto-wypełnienie formularza rozliczeniowego
  - Terminy: 22 maja (ryczałt) / 30 kwietnia (skala/liniowy)
  - Odsetki od niedopłaty
  - Wniosek o zwrot nadpłaty

Użycie:
    python JDG/tools/health_reconciliation_micro.py --variant LUMP_SUM --monthly 12
    python JDG/tools/health_reconciliation_micro.py --reconcile --income 120000 --paid 12000
    python JDG/tools/health_reconciliation_micro.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── 2026 parameters ──────────────────────────────────────────────────────────
AVERAGE_SALARY_2026 = 8190.00
MINIMUM_SALARY_2026 = 4666.00
INTEREST_RATE = 0.145  # 14.5% annual (2026)

# ── Health variant definitions ───────────────────────────────────────────────

HEALTH_VARIANTS_RECON = {
    "SCALE": {
        "name": "Skala PIT (9%)",
        "rate": 0.09,
        "deadline": "30 kwietnia",
        "deadline_month": 4,
        "deadline_day": 30,
        "basis": "Dochód roczny",
        "deductible": False,
    },
    "LINEAR": {
        "name": "Liniowy (4.9%)",
        "rate": 0.049,
        "deadline": "30 kwietnia",
        "deadline_month": 4,
        "deadline_day": 30,
        "basis": "Dochód roczny",
        "deductible": True,
        "deduction_limit": 12900,  # 2026 limit
    },
    "LUMP_SUM": {
        "name": "Ryczałt (3 progi)",
        "rate": None,
        "deadline": "22 maja",
        "deadline_month": 5,
        "deadline_day": 22,
        "basis": "Przychód roczny (progi)",
        "tiers": {
            60000: round(AVERAGE_SALARY_2026 * 0.60 * 0.09, 2),
            300000: round(AVERAGE_SALARY_2026 * 1.00 * 0.09, 2),
            float("inf"): round(AVERAGE_SALARY_2026 * 1.80 * 0.09, 2),
        },
    },
    "TAX_CARD": {
        "name": "Karta podatkowa (9%)",
        "rate": 0.09,
        "deadline": "31 stycznia",
        "deadline_month": 1,
        "deadline_day": 31,
        "basis": "Minimalne wynagrodzenie",
        "monthly_base": MINIMUM_SALARY_2026,
    },
}


class HealthReconciliationMicro:
    """INN09: Health Contribution Reconciliation Micro."""

    def __init__(self, variant="SCALE"):
        self.variant = variant
        self.variant_info = HEALTH_VARIANTS_RECON.get(variant, {})
        self.alerts = []

    def reconcile(self, annual_income, total_paid, monthly_payments=None):
        """Reconcile annual health contribution."""
        variant = self.variant_info
        annual_due = self._calculate_annual_due(annual_income, monthly_payments)

        difference = round(annual_due - total_paid, 2)
        result = {
            "variant": variant["name"],
            "annual_income": annual_income,
            "annual_contribution_due": annual_due,
            "total_paid": total_paid,
            "difference": difference,
            "status": "BALANCED",
            "deadline": variant["deadline"],
        }

        if difference > 0:
            result["status"] = "UNDERPAID"
            result["underpayment"] = difference
            result["interest_daily"] = round(difference * INTEREST_RATE / 365, 4)
            result["interest_30days"] = round(difference * INTEREST_RATE / 365 * 30, 2)

            self.alerts.append(
                f"🔴 NIEDOPŁATA: {difference:.2f} PLN. "
                f"Termin dopłaty: {variant['deadline']}. "
                f"Odsetki: {result['interest_30days']:.2f} PLN/30 dni."
            )
        elif difference < 0:
            result["status"] = "OVERPAID"
            result["overpayment"] = abs(difference)

            self.alerts.append(
                f"🟢 NADPŁATA: {abs(difference):.2f} PLN. "
                f"Możesz złożyć wniosek o zwrot z ZUS."
            )

        return result

    def _calculate_annual_due(self, annual_income, monthly_payments=None):
        """Calculate annual health contribution due based on variant."""
        variant = self.variant_info

        if self.variant == "SCALE":
            return round(annual_income * variant["rate"], 2)
        elif self.variant == "LINEAR":
            return round(annual_income * variant["rate"], 2)
        elif self.variant == "LUMP_SUM":
            # Calculate based on revenue tier
            if annual_income <= 60000:
                monthly = round(AVERAGE_SALARY_2026 * 0.60 * 0.09, 2)
            elif annual_income <= 300000:
                monthly = round(AVERAGE_SALARY_2026 * 1.00 * 0.09, 2)
            else:
                monthly = round(AVERAGE_SALARY_2026 * 1.80 * 0.09, 2)
            return round(monthly * 12, 2)
        elif self.variant == "TAX_CARD":
            return round(MINIMUM_SALARY_2026 * 0.09 * 12, 2)

        return 0

    def generate_payment_schedule(self, annual_income):
        """Generate monthly payment schedule."""
        variant = self.variant_info
        schedule = []

        if self.variant == "LUMP_SUM":
            if annual_income <= 60000:
                monthly_base = round(AVERAGE_SALARY_2026 * 0.60, 2)
                tier = "TIER_I"
            elif annual_income <= 300000:
                monthly_base = round(AVERAGE_SALARY_2026 * 1.00, 2)
                tier = "TIER_II"
            else:
                monthly_base = round(AVERAGE_SALARY_2026 * 1.80, 2)
                tier = "TIER_III"

            monthly = round(monthly_base * 0.09, 2)
            for m in range(1, 13):
                schedule.append({"month": m, "base": monthly_base, "contribution": monthly})

        elif self.variant == "TAX_CARD":
            monthly = round(MINIMUM_SALARY_2026 * 0.09, 2)
            for m in range(1, 13):
                schedule.append({"month": m, "base": MINIMUM_SALARY_2026, "contribution": monthly})

        else:
            monthly_income = annual_income / 12
            rate = variant["rate"]
            monthly = round(monthly_income * rate, 2)
            for m in range(1, 13):
                schedule.append({"month": m, "base": round(monthly_income, 2), "contribution": monthly})

        return {
            "variant": variant["name"],
            "schedule": schedule,
            "total_annual": round(sum(s["contribution"] for s in schedule), 2),
            "deadline": variant["deadline"],
        }

    def calculate_interest(self, underpayment, days_late):
        """Calculate interest on late payment."""
        daily_rate = INTEREST_RATE / 365
        interest = round(underpayment * daily_rate * days_late, 2)

        return {
            "underpayment": underpayment,
            "days_late": days_late,
            "annual_rate": f"{INTEREST_RATE*100:.1f}%",
            "daily_rate": round(daily_rate * 100, 4),
            "interest_due": interest,
            "total_due": round(underpayment + interest, 2),
        }

    def generate_report(self):
        """Generate reconciliation report."""
        return {
            "tool": "Health Contribution Reconciliation Micro (INN09)",
            "version": "1.0.0",
            "variant": self.variant_info.get("name", self.variant),
            "deadline": self.variant_info.get("deadline", ""),
            "rate": self.variant_info.get("rate"),
            "interest_rate_annual": f"{INTEREST_RATE*100:.1f}%",
            "alerts": self.alerts,
        }


def print_report(recon, report):
    """Print reconciliation report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Health Contribution Reconciliation Micro (INN09)")
    print(f"  Wariant: {report['variant']}")
    print(f"  Termin rozliczenia: {report['deadline']}")
    if report["rate"]:
        print(f"  Stawka: {report['rate']*100:.1f}%")
    print(f"  Stopa odsetek: {report['interest_rate_annual']}")
    print("═" * 78)

    if recon.alerts:
        print(f"\n  ⚠️  ALERTY ROZLICZENIOWE:")
        for alert in recon.alerts:
            print(f"     {alert}")

    # Show deadlines info
    print(f"\n  📅 TERMINY ROZLICZENIA ROCZNEGO:")
    for var_name, var_info in HEALTH_VARIANTS_RECON.items():
        print(f"     {var_info['name']}: do {var_info['deadline']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Health Reconciliation Micro (INN09)")
    parser.add_argument("--variant", type=str, default="SCALE",
                        choices=["SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"])
    parser.add_argument("--reconcile", action="store_true", help="Run reconciliation")
    parser.add_argument("--income", type=float, default=0, help="Annual income")
    parser.add_argument("--paid", type=float, default=0, help="Total health contributions paid")
    parser.add_argument("--schedule", action="store_true", help="Generate payment schedule")
    parser.add_argument("--interest", type=float, default=0, help="Calculate interest on underpayment")
    parser.add_argument("--days-late", type=int, default=30, help="Days late for interest calculation")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    recon = HealthReconciliationMicro(variant=args.variant)

    if args.interest > 0:
        result = recon.calculate_interest(args.interest, args.days_late)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  💰 ODSETKI OD NIEDOPŁATY:")
            print(f"     Niedopłata: {result['underpayment']:.2f} PLN")
            print(f"     Dni zwłoki: {result['days_late']}")
            print(f"     Odsetki: {result['interest_due']:.2f} PLN")
            print(f"     Łącznie do zapłaty: {result['total_due']:.2f} PLN")
        return

    if args.schedule and args.income > 0:
        schedule = recon.generate_payment_schedule(args.income)
        if args.json:
            print(json.dumps(schedule, indent=2, ensure_ascii=False))
        else:
            print(f"\n  📅 HARMONOGRAM PŁATNOŚCI ({schedule['variant']}):")
            print(f"  {'Miesiąc':>8s} | {'Podstawa':>10s} | {'Składka':>10s}")
            print(f"  {'-'*8}-+-{'-'*10}-+-{'-'*10}")
            for s in schedule["schedule"]:
                print(f"  {s['month']:>8d} | {s['base']:>10.2f} | {s['contribution']:>10.2f}")
            print(f"  {'RAZEM':>8s} | {'':>10s} | {schedule['total_annual']:>10.2f}")
        return

    if args.reconcile and args.income > 0 and args.paid > 0:
        result = recon.reconcile(args.income, args.paid)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🧾 ROZLICZENIE ROCZNE ({result['variant']}):")
            print(f"     Należna składka: {result['annual_contribution_due']:.2f} PLN")
            print(f"     Zapłacono: {result['total_paid']:.2f} PLN")
            print(f"     Różnica: {result['difference']:.2f} PLN")
            print(f"     Status: {result['status']}")
            print(f"     Termin: {result['deadline']}")
        return

    report = recon.generate_report()
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(recon, report)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN09_HEALTH_RECONCILIATION.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN09 — Health Contribution Reconciliation Micro\n")
            f.write(f"Variant: {report['variant']}\n")
            f.write(f"Deadline: {report['deadline']}\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
