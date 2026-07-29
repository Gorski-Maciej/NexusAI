#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Health Tier Dynamic Recalculator (INN02 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Automatyczna rekalkulacja progu ryczałtowego składki zdrowotnej
przy zmianie przychodu JDG. Monitoruje YTD revenue i ostrzega
o przekroczeniu progów 60 000 / 300 000 PLN.

Użycie:
    python JDG/tools/health_tier_recalculator.py --revenue 65000 [--ytd 45000]
    python JDG/tools/health_tier_recalculator.py --simulate 55000 61000 250000 310000
    python JDG/tools/health_tier_recalculator.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── 2026 thresholds (based on przeciętne wynagrodzenie ~8190 PLN) ────────────
AVERAGE_SALARY_2026 = 8190.00
MINIMUM_SALARY_2026 = 4666.00

HEALTH_TIERS = {
    "TIER_I": {
        "name": "Tier I — do 60 000 PLN",
        "max_revenue": 60000,
        "rate_pct": 60,
        "base_formula": "60% przeciętnego wynagrodzenia",
        "monthly_base": round(AVERAGE_SALARY_2026 * 0.60, 2),
        "monthly_contribution_9pct": round(AVERAGE_SALARY_2026 * 0.60 * 0.09, 2),
    },
    "TIER_II": {
        "name": "Tier II — 60 001-300 000 PLN",
        "min_revenue": 60001,
        "max_revenue": 300000,
        "rate_pct": 100,
        "base_formula": "100% przeciętnego wynagrodzenia",
        "monthly_base": round(AVERAGE_SALARY_2026 * 1.00, 2),
        "monthly_contribution_9pct": round(AVERAGE_SALARY_2026 * 1.00 * 0.09, 2),
    },
    "TIER_III": {
        "name": "Tier III — powyżej 300 000 PLN",
        "min_revenue": 300001,
        "rate_pct": 180,
        "base_formula": "180% przeciętnego wynagrodzenia",
        "monthly_base": round(AVERAGE_SALARY_2026 * 1.80, 2),
        "monthly_contribution_9pct": round(AVERAGE_SALARY_2026 * 1.80 * 0.09, 2),
    },
}

HEALTH_VARIANTS = {
    "SCALE": {"rate": 0.09, "deductible": False, "name": "Skala PIT 9%"},
    "LINEAR": {"rate": 0.049, "deductible": True, "name": "Liniowy 4.9%"},
    "LUMP_SUM": {"rate": None, "deductible": False, "name": "Ryczałt (3 progi)"},
    "TAX_CARD": {"rate": 0.09, "deductible": False, "base": "minimalne", "name": "Karta 9% min."},
}


class HealthTierRecalculator:
    """INN02: Health Tier Dynamic Recalculator."""

    def __init__(self):
        self.alerts = []
        self.recommendations = []

    def calculate_tier(self, ytd_revenue):
        """Determine current health contribution tier based on YTD revenue."""
        if ytd_revenue <= 60000:
            return "TIER_I", HEALTH_TIERS["TIER_I"]
        elif ytd_revenue <= 300000:
            return "TIER_II", HEALTH_TIERS["TIER_II"]
        else:
            return "TIER_III", HEALTH_TIERS["TIER_III"]

    def predict_tier_change(self, ytd_revenue, projected_additional):
        """Predict if adding revenue would change the tier."""
        current_tier, current_info = self.calculate_tier(ytd_revenue)
        future_tier, future_info = self.calculate_tier(ytd_revenue + projected_additional)

        result = {
            "current_tier": current_tier,
            "current_monthly": current_info["monthly_contribution_9pct"],
            "future_tier": future_tier,
            "future_monthly": future_info["monthly_contribution_9pct"],
            "ytd_revenue": ytd_revenue,
            "projected": projected_additional,
            "future_total": ytd_revenue + projected_additional,
            "tier_changes": current_tier != future_tier,
        }

        if result["tier_changes"]:
            delta = future_info["monthly_contribution_9pct"] - current_info["monthly_contribution_9pct"]
            result["monthly_delta"] = round(delta, 2)
            result["alert"] = (
                f"⚠️  PRZEKROCZENIE PROGU! Składka zdrowotna wzrośnie "
                f"z {current_info['monthly_contribution_9pct']:.2f} PLN "
                f"do {future_info['monthly_contribution_9pct']:.2f} PLN "
                f"(+{delta:.2f} PLN/miesiąc)"
            )
            self.alerts.append(result["alert"])

        return result

    def simulate_thresholds(self, revenue_points):
        """Simulate tier changes across multiple revenue points."""
        results = []
        for rev in revenue_points:
            tier, info = self.calculate_tier(rev)
            results.append({
                "revenue": rev,
                "tier": tier,
                "monthly_contribution": info["monthly_contribution_9pct"],
                "annual_contribution": round(info["monthly_contribution_9pct"] * 12, 2),
                "base_amount": info["monthly_base"],
            })
        return results

    def calculate_health_for_variant(self, variant, income, ytd_revenue=0):
        """Calculate health contribution for a specific variant."""
        variant_info = HEALTH_VARIANTS.get(variant)
        if not variant_info:
            return {"error": f"Unknown variant: {variant}"}

        if variant == "LUMP_SUM":
            tier, tier_info = self.calculate_tier(ytd_revenue)
            return {
                "variant": variant_info["name"],
                "tier": tier,
                "monthly_base": tier_info["monthly_base"],
                "monthly_contribution": tier_info["monthly_contribution_9pct"],
                "annual_contribution": round(tier_info["monthly_contribution_9pct"] * 12, 2),
            }
        elif variant == "TAX_CARD":
            base = MINIMUM_SALARY_2026
            contribution = round(base * 0.09, 2)
            return {
                "variant": variant_info["name"],
                "base": base,
                "monthly_contribution": contribution,
                "annual_contribution": round(contribution * 12, 2),
            }
        else:
            rate = variant_info["rate"]
            contribution = round(income * rate, 2)
            return {
                "variant": variant_info["name"],
                "rate": f"{rate*100}%",
                "income_basis": income,
                "monthly_contribution": contribution,
                "deductible": variant_info["deductible"],
            }

    def optimize_variant(self, annual_income, ytd_revenue, has_employees=False):
        """Recommend the optimal health contribution variant."""
        results = {}
        for variant in HEALTH_VARIANTS:
            results[variant] = self.calculate_health_for_variant(variant, annual_income / 12, ytd_revenue)

        # Find cheapest monthly contribution
        cheapest = min(results.items(), key=lambda x: x[1].get("monthly_contribution", float("inf")))

        self.recommendations.append({
            "annual_income": annual_income,
            "cheapest_variant": cheapest[0],
            "cheapest_monthly": cheapest[1].get("monthly_contribution", 0),
            "all_variants": {k: v.get("monthly_contribution", 0) for k, v in results.items()},
        })

        return {
            "optimal_variant": cheapest[0],
            "optimal_monthly": cheapest[1].get("monthly_contribution", 0),
            "savings_vs_worst": round(max(v.get("monthly_contribution", 0) for v in results.values()) - cheapest[1].get("monthly_contribution", 0), 2),
            "all_calculations": results,
            "note": "Ryczałt jest opłacalny przy dochodach > ~8000 PLN/miesiąc",
        }

    def generate_report(self):
        """Generate comprehensive report."""
        return {
            "tool": "Health Tier Dynamic Recalculator (INN02)",
            "version": "1.0.0",
            "parameters_2026": {
                "average_salary": AVERAGE_SALARY_2026,
                "minimum_salary": MINIMUM_SALARY_2026,
            },
            "tiers": {k: {"monthly": v["monthly_contribution_9pct"], "annual": round(v["monthly_contribution_9pct"] * 12, 2)} for k, v in HEALTH_TIERS.items()},
            "alerts": self.alerts,
            "recommendations": self.recommendations,
        }


def print_report(calculator, report):
    """Print human-readable report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Health Tier Dynamic Recalculator (INN02)")
    print(f"  Przeciętne wynagrodzenie 2026: {AVERAGE_SALARY_2026:.2f} PLN")
    print(f"  Minimalne wynagrodzenie 2026: {MINIMUM_SALARY_2026:.2f} PLN")
    print("═" * 78)

    print(f"\n  📊 PROGI RYCZAŁTOWE (2026):")
    for tier_name, tier_info in HEALTH_TIERS.items():
        print(f"     {tier_name}: {tier_info['name']}")
        print(f"       Podstawa: {tier_info['monthly_base']:.2f} PLN ({tier_info['rate_pct']}% przeciętnego)")
        print(f"       Składka miesięczna: {tier_info['monthly_contribution_9pct']:.2f} PLN")
        print(f"       Składka roczna: {tier_info['monthly_contribution_9pct'] * 12:.2f} PLN")

    if calculator.alerts:
        print(f"\n  ⚠️  ALERTY:")
        for alert in calculator.alerts:
            print(f"     {alert}")

    if calculator.recommendations:
        print(f"\n  💡 REKOMENDACJE:")
        for rec in calculator.recommendations:
            print(f"     Przychód roczny: {rec['annual_income']:,.0f} PLN")
            print(f"     Optymalny wariant: {rec['cheapest_variant']} ({rec['cheapest_monthly']:.2f} PLN/mies.)")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Health Tier Recalculator (INN02)")
    parser.add_argument("--revenue", type=float, help="Current YTD revenue")
    parser.add_argument("--ytd", type=float, default=0, help="Current YTD revenue (alias)")
    parser.add_argument("--projected", type=float, default=0, help="Projected additional revenue")
    parser.add_argument("--simulate", type=float, nargs="+", help="Simulate tier changes at revenue points")
    parser.add_argument("--optimize", type=float, help="Find optimal health variant for annual income")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    calc = HealthTierRecalculator()

    if args.optimize:
        result = calc.optimize_variant(args.optimize, args.optimize)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  💡 OPTYMALIZACJA dla {args.optimize:,.0f} PLN rocznie:")
            print(f"     Najtańszy wariant: {result['optimal_variant']}")
            print(f"     Miesięczna składka: {result['optimal_monthly']:.2f} PLN")
            print(f"     Oszczędność vs najdroższy: {result['savings_vs_worst']:.2f} PLN/mies.")
        return

    if args.simulate:
        results = calc.simulate_thresholds(args.simulate)
        if args.json:
            print(json.dumps(results, indent=2, ensure_ascii=False))
        else:
            print(f"\n  📈 SYMULACJA PROGÓW:")
            print(f"  {'Revenue':>12s} | {'Tier':>10s} | {'Monthly':>10s} | {'Annual':>10s}")
            print(f"  {'-'*12}-+-{'-'*10}-+-{'-'*10}-+-{'-'*10}")
            for r in results:
                print(f"  {r['revenue']:>12,.0f} | {r['tier']:>10s} | {r['monthly_contribution']:>10.2f} | {r['annual_contribution']:>10.2f}")
        return

    ytd = args.revenue or args.ytd
    if ytd > 0 and args.projected > 0:
        prediction = calc.predict_tier_change(ytd, args.projected)
        if args.json:
            print(json.dumps(prediction, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🔮 PREDYKCJA ZMIANY PROGU:")
            print(f"     YTD: {ytd:,.0f} PLN → +{args.projected:,.0f} PLN = {ytd + args.projected:,.0f} PLN")
            print(f"     Obecny próg: {prediction['current_tier']} ({prediction['current_monthly']:.2f} PLN/mies.)")
            if prediction['tier_changes']:
                print(f"     {prediction['alert']}")
            else:
                print(f"     ✅ Brak zmiany progu — pozostajesz w {prediction['current_tier']}")
        return

    # Default: show all tiers
    report = calc.generate_report()
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(calc, report)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN02_HEALTH_TIER_RECALCULATOR.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN02 — Health Tier Dynamic Recalculator\n")
            f.write(f"Przeciętne wynagrodzenie: {AVERAGE_SALARY_2026} PLN\n\n")
            for tier_name, tier_info in HEALTH_TIERS.items():
                f.write(f"{tier_name}: {tier_info['monthly_contribution_9pct']:.2f} PLN/mies.\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
