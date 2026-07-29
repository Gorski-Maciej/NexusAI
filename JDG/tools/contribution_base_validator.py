#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Contribution Base Auto-Validator (INN05 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Automatyczna walidacja podstawy wymiaru składek ZUS.
Sprawdza czy podstawa spełnia minima ustawowe:
  - Standard: ≥60% przeciętnego wynagrodzenia
  - Ulgowe (preferencyjny/Mały ZUS+): ≥30% minimalnego
  - Zdrowotna: ≥75% przeciętnego (minimum)
  - Ryczałt: 60%/100%/180% przeciętnego

Użycie:
    python JDG/tools/contribution_base_validator.py --base 5000 --relief PREFERENTIAL
    python JDG/tools/contribution_base_validator.py --base 3000 --health
    python JDG/tools/contribution_base_validator.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── 2026 thresholds ─────────────────────────────────────────────────────────
AVERAGE_SALARY_2026 = 8190.00
MINIMUM_SALARY_2026 = 4666.00

# ── Contribution base rules ─────────────────────────────────────────────────

BASE_RULES = {
    "STANDARD": {
        "name": "Standardowy ZUS",
        "base_min": round(AVERAGE_SALARY_2026 * 0.60, 2),
        "base_formula": "60% przeciętnego wynagrodzenia",
        "base_max": None,  # no upper limit
        "social_rates": {
            "emerytalna": 0.1952, "rentowa": 0.08,
            "chorobowa": 0.0245, "wypadkowa": 0.0167,
        },
        "total_social_rate": 0.3164,  # 19.52 + 8 + 2.45 + 1.67
    },
    "START_RELIEF": {
        "name": "Ulga na start (6 miesięcy)",
        "duration_months": 6,
        "social_base_min": 0,  # No social contributions
        "health_base_min": round(AVERAGE_SALARY_2026 * 0.75, 2),
        "description": "Tylko składka zdrowotna — ZUS społeczne = 0 PLN",
    },
    "PREFERENTIAL": {
        "name": "Preferencyjny ZUS (24 miesiące)",
        "duration_months": 24,
        "base_min": round(MINIMUM_SALARY_2026 * 0.30, 2),
        "base_formula": "30% minimalnego wynagrodzenia",
        "social_rates": {
            "emerytalna": 0.1952, "rentowa": 0.08,
            "chorobowa": 0.0245, "wypadkowa": 0.0167,
        },
        "total_social_rate": 0.3164,
    },
    "SMALL_ZUS_PLUS": {
        "name": "Mały ZUS+ (36 miesięcy)",
        "duration_months": 36,
        "revenue_limit": 120000,
        "base_min": round(MINIMUM_SALARY_2026 * 0.30, 2),
        "base_formula": "30% minimalnego wynagrodzenia (limit przychodu 120k)",
        "social_rates": {
            "emerytalna": 0.1952, "rentowa": 0.08,
            "chorobowa": 0.0245, "wypadkowa": 0.0167,
        },
        "total_social_rate": 0.3164,
    },
}

HEALTH_RULES = {
    "SCALE": {"rate": 0.09, "base_min": None, "base_type": "dochód"},
    "LINEAR": {"rate": 0.049, "base_min": None, "base_type": "dochód"},
    "LUMP_SUM": {
        "rate": 0.09,
        "tiers": {
            "TIER_I": {"max_revenue": 60000, "base": round(AVERAGE_SALARY_2026 * 0.60, 2)},
            "TIER_II": {"max_revenue": 300000, "base": round(AVERAGE_SALARY_2026 * 1.00, 2)},
            "TIER_III": {"max_revenue": float("inf"), "base": round(AVERAGE_SALARY_2026 * 1.80, 2)},
        },
    },
    "TAX_CARD": {
        "rate": 0.09,
        "base_min": MINIMUM_SALARY_2026,
        "base_type": "minimalne wynagrodzenie",
    },
}


class ContributionBaseValidator:
    """INN05: Contribution Base Auto-Validator."""

    def __init__(self):
        self.violations = []
        self.warnings = []
        self.corrections = []

    def validate_social_base(self, declared_base, relief_type="STANDARD", months_active=1, annual_revenue=0):
        """Validate social insurance contribution base."""
        rules = BASE_RULES.get(relief_type)
        if not rules:
            return {"error": f"Unknown relief type: {relief_type}"}

        result = {
            "relief": rules["name"],
            "declared_base": declared_base,
            "valid": True,
            "checks": [],
        }

        # Check minimum
        base_min = rules.get("base_min", rules.get("social_base_min", 0))
        if base_min and declared_base < base_min:
            result["valid"] = False
            result["checks"].append({
                "check": "below_minimum",
                "declared": declared_base,
                "required_min": base_min,
                "shortfall": round(base_min - declared_base, 2),
                "message": f"Podstawa {declared_base:.2f} PLN poniżej minimum {base_min:.2f} PLN ({rules['base_formula']})",
            })
            self.violations.append(result["checks"][-1]["message"])

        # Check maximum (for SMALL_ZUS_PLUS)
        if relief_type == "SMALL_ZUS_PLUS" and annual_revenue > rules.get("revenue_limit", float("inf")):
            result["valid"] = False
            result["checks"].append({
                "check": "revenue_limit_exceeded",
                "annual_revenue": annual_revenue,
                "limit": rules["revenue_limit"],
                "message": f"Przychód {annual_revenue:.2f} PLN przekracza limit {rules['revenue_limit']} PLN dla Małego ZUS+",
            })

        # Calculate contributions
        if "social_rates" in rules:
            contributions = {}
            total = 0
            for name, rate in rules["social_rates"].items():
                amount = round(declared_base * rate, 2)
                contributions[name] = amount
                total += amount
            result["contributions"] = contributions
            result["total_monthly"] = round(total, 2)
        else:
            result["contributions"] = {}
            result["total_monthly"] = 0

        # Duration check
        if "duration_months" in rules and months_active > rules["duration_months"]:
            self.warnings.append(
                f"⚠️  {rules['name']}: przekroczono limit {rules['duration_months']} miesięcy "
                f"(aktywny {months_active} miesięcy). Przejdź na kolejny poziom."
            )

        return result

    def validate_health_base(self, declared_base, variant="SCALE", annual_income=0, ytd_revenue=0):
        """Validate health insurance contribution base."""
        rules = HEALTH_RULES.get(variant)
        if not rules:
            return {"error": f"Unknown health variant: {variant}"}

        result = {
            "variant": variant,
            "declared_base": declared_base,
            "valid": True,
            "checks": [],
        }

        if variant == "SCALE" or variant == "LINEAR":
            rate = rules["rate"]
            contribution = round(declared_base * rate, 2)
            result["rate"] = rate
            result["monthly_contribution"] = contribution
            result["deductible"] = (variant == "LINEAR")

        elif variant == "LUMP_SUM":
            # Determine tier
            if ytd_revenue <= 60000:
                tier_name = "TIER_I"
            elif ytd_revenue <= 300000:
                tier_name = "TIER_II"
            else:
                tier_name = "TIER_III"

            tier = rules["tiers"][tier_name]
            expected_base = tier["base"]
            expected_contribution = round(expected_base * 0.09, 2)

            if declared_base != expected_base:
                result["valid"] = False
                result["checks"].append({
                    "check": "wrong_tier_base",
                    "declared": declared_base,
                    "expected": expected_base,
                    "tier": tier_name,
                    "message": f"Błędna podstawa dla {tier_name}: zadeklarowano {declared_base}, powinno być {expected_base}",
                })

            result["tier"] = tier_name
            result["expected_base"] = expected_base
            result["monthly_contribution"] = expected_contribution

        elif variant == "TAX_CARD":
            min_base = rules["base_min"]
            effective_base = max(declared_base, min_base)
            contribution = round(effective_base * 0.09, 2)

            if declared_base < min_base:
                result["checks"].append({
                    "check": "below_minimum",
                    "declared": declared_base,
                    "minimum": min_base,
                    "message": f"Podstawa poniżej minimum ({min_base} PLN) — wyrównano do {effective_base}",
                })

            result["effective_base"] = effective_base
            result["monthly_contribution"] = contribution

        return result

    def auto_correct_base(self, declared_base, relief_type="STANDARD"):
        """Auto-correct to the minimum valid base."""
        rules = BASE_RULES.get(relief_type, BASE_RULES["STANDARD"])
        base_min = rules.get("base_min", round(AVERAGE_SALARY_2026 * 0.60, 2))

        if declared_base < base_min:
            correction = {
                "from": declared_base,
                "to": base_min,
                "increase": round(base_min - declared_base, 2),
                "message": f"Auto-korekta: {declared_base:.2f} → {base_min:.2f} PLN"
            }
            self.corrections.append(correction)
            return correction
        return None

    def generate_report(self):
        """Generate validation report."""
        return {
            "tool": "Contribution Base Auto-Validator (INN05)",
            "version": "1.0.0",
            "parameters_2026": {
                "average_salary": AVERAGE_SALARY_2026,
                "minimum_salary": MINIMUM_SALARY_2026,
                "standard_min_60pct": round(AVERAGE_SALARY_2026 * 0.60, 2),
                "preferential_min_30pct": round(MINIMUM_SALARY_2026 * 0.30, 2),
                "health_min_75pct": round(AVERAGE_SALARY_2026 * 0.75, 2),
            },
            "violations": self.violations,
            "warnings": self.warnings,
            "corrections": self.corrections,
        }


def print_report(validator):
    """Print validation summary."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Contribution Base Auto-Validator (INN05)")
    print(f"  Przeciętne wynagrodzenie 2026: {AVERAGE_SALARY_2026:.2f} PLN")
    print(f"  Minimalne wynagrodzenie 2026: {MINIMUM_SALARY_2026:.2f} PLN")
    print("═" * 78)

    print(f"\n  📏 MINIMA USTAWOWE:")
    print(f"     Standard ZUS (60% przeciętnego):      {AVERAGE_SALARY_2026 * 0.60:.2f} PLN")
    print(f"     Preferencyjny/Mały ZUS+ (30% min.):    {MINIMUM_SALARY_2026 * 0.30:.2f} PLN")
    print(f"     Zdrowotna minimum (75% przeciętnego):  {AVERAGE_SALARY_2026 * 0.75:.2f} PLN")
    print(f"     Ryczałt Tier I (60% przeciętnego):     {AVERAGE_SALARY_2026 * 0.60:.2f} PLN")
    print(f"     Ryczałt Tier II (100% przeciętnego):   {AVERAGE_SALARY_2026 * 1.00:.2f} PLN")
    print(f"     Ryczałt Tier III (180% przeciętnego):  {AVERAGE_SALARY_2026 * 1.80:.2f} PLN")

    print(f"\n  💰 SKŁADKI (przy standardowej podstawie {AVERAGE_SALARY_2026 * 0.60:.2f} PLN):")
    base = AVERAGE_SALARY_2026 * 0.60
    for name, rate in [("Emerytalna", 0.1952), ("Rentowa", 0.08), ("Chorobowa", 0.0245), ("Wypadkowa", 0.0167)]:
        print(f"     {name} ({rate*100:.2f}%): {base * rate:.2f} PLN")
    print(f"     ŁĄCZNIE społeczne: {base * 0.3164:.2f} PLN")

    if validator.violations:
        print(f"\n  🔴 NARUSZENIA:")
        for v in validator.violations:
            print(f"     {v}")

    if validator.corrections:
        print(f"\n  🔧 AUTO-KOREKTY:")
        for c in validator.corrections:
            print(f"     {c['message']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Contribution Base Validator (INN05)")
    parser.add_argument("--base", type=float, default=0, help="Declared contribution base")
    parser.add_argument("--relief", type=str, default="STANDARD",
                        choices=["STANDARD", "START_RELIEF", "PREFERENTIAL", "SMALL_ZUS_PLUS"],
                        help="Relief type")
    parser.add_argument("--health", action="store_true", help="Validate health contribution")
    parser.add_argument("--variant", type=str, default="SCALE",
                        choices=["SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"],
                        help="Health variant")
    parser.add_argument("--revenue", type=float, default=0, help="Annual/YTD revenue")
    parser.add_argument("--months", type=int, default=1, help="Months active under relief")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    validator = ContributionBaseValidator()

    if args.health:
        result = validator.validate_health_base(args.base, args.variant, ytd_revenue=args.revenue)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🏥 WALIDACJA SKŁADKI ZDROWOTNEJ ({args.variant}):")
            print(f"     Podstawa: {args.base:.2f} PLN")
            if "monthly_contribution" in result:
                print(f"     Składka: {result['monthly_contribution']:.2f} PLN/mies.")
            if "tier" in result:
                print(f"     Próg: {result['tier']}")
            if not result.get("valid", True):
                for check in result.get("checks", []):
                    print(f"     ❌ {check['message']}")

    elif args.base > 0:
        result = validator.validate_social_base(args.base, args.relief, months_active=args.months, annual_revenue=args.revenue)
        correction = validator.auto_correct_base(args.base, args.relief)

        if args.json:
            output = {"validation": result, "correction": correction}
            print(json.dumps(output, indent=2, ensure_ascii=False))
        else:
            print(f"\n  📊 WALIDACJA PODSTAWY ZUS ({args.relief}):")
            print(f"     Zadeklarowana: {args.base:.2f} PLN")
            if "total_monthly" in result:
                print(f"     Składki społeczne: {result['total_monthly']:.2f} PLN/mies.")
            if result["valid"]:
                print(f"     ✅ Podstawa prawidłowa")
            if correction:
                print(f"     🔧 {correction['message']}")
            for check in result.get("checks", []):
                print(f"     ❌ {check['message']}")

    else:
        print_report(validator)

    for w in validator.warnings:
        print(f"     {w}")

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN05_CONTRIBUTION_VALIDATOR.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        r = validator.generate_report()
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN05 — Contribution Base Auto-Validator\n")
            f.write(f"Minima: standard={r['parameters_2026']['standard_min_60pct']}, ")
            f.write(f"pref={r['parameters_2026']['preferential_min_30pct']}\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
