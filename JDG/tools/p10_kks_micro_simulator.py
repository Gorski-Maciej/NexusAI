#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P10 INN03: Micro Sanction Simulator
═══════════════════════════════════════════════════════════════════════════════

Pełna symulacja sankcji KKS na podstawie reguł atomowych:
  - Klasyfikacja czynu (wykroczenie/przestępstwo) z dynamicznymi progami
  - Kalkulacja grzywny (stawki × daily_rate × liczba)
  - Szacowane ryzyko PW (lata)
  - Optymalna strategia (PATH A/B/C/D/E)
  - Wynik po zastosowaniu strategii (redukcja %)
  - Integracja z micro-kks regułami

Użycie:
    python JDG/tools/p10_kks_micro_simulator.py --amount 250000 --offense tax_evasion
    python JDG/tools/p10_kks_micro_simulator.py --amount 5000000 --offense empty_invoice
    python JDG/tools/p10_kks_micro_simulator.py --simulate-all --income 15000

Autor: NexusAI
Data: 2026-07-29
"""

import argparse, json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MIN_WAGE = 4666.00
DAILY_RATE_MIN = round(MIN_WAGE / 30, 2)  # 155.53 PLN

# ═══ Sanction Tiers (aligned with sanctions_optimization + _kks_macro_rates) ═══
SANCTION_GRADUATION = [
    {"level": "Znikoma szkodliwość", "threshold": MIN_WAGE * 1, "max_rates": 0, "max_pw": "brak", "offense_type": "NONE"},
    {"level": "Wykroczenie skarbowe", "threshold": MIN_WAGE * 200, "max_rates": 180, "max_pw": "30 dni aresztu", "offense_type": "MISDEMEANOR"},
    {"level": "Przestępstwo — mała wartość", "threshold": MIN_WAGE * 500, "max_rates": 360, "max_pw": "3 lata", "offense_type": "CRIME"},
    {"level": "Przestępstwo — znaczna wartość", "threshold": MIN_WAGE * 2000, "max_rates": 720, "max_pw": "5 lat", "offense_type": "CRIME"},
    {"level": "Przestępstwo — wielka wartość", "threshold": float("inf"), "max_rates": 1080, "max_pw": "10 lat", "offense_type": "AGGRAVATED"},
]

# ═══ Offense types → articles mapping ═══
OFFENSE_MAP = {
    "tax_evasion": {"article": 54, "description": "Uchylanie się od opodatkowania", "severity": "HIGH"},
    "unreliable_books": {"article": 56, "description": "Nierzetelne PKPiR/księgi", "severity": "MEDIUM"},
    "vat_discrepancy": {"article": 57, "description": "Nierzetelna ewidencja VAT", "severity": "MEDIUM"},
    "empty_invoice": {"article": 62, "description": "Puste faktury", "severity": "CRITICAL"},
    "declaration_failure": {"article": 77, "description": "Niezłożenie deklaracji", "severity": "MEDIUM"},
    "non_payment": {"article": 79, "description": "Niezapłacenie podatku", "severity": "HIGH"},
}

# ═══ Decision Paths ═══
DECISION_PATHS = {
    "PATH_A": {"name": "Czynny żal", "reduction": 1.0, "condition": "us_not_initiated", "cost": 0},
    "PATH_B": {"name": "Korekta + zapłata", "reduction": 0.80, "condition": "us_initiated_lt_100k", "cost": 0.05},
    "PATH_C": {"name": "Odwołanie do IAS", "reduction": 0.50, "condition": "us_initiated_gt_100k", "cost": 0.10},
    "PATH_D": {"name": "Pełna obrona sądowa", "reduction": 0.75, "condition": "legal_dispute", "cost": 0.15},
    "PATH_E": {"name": "Ugoda z US", "reduction": 0.40, "condition": "large_amount_settlement", "cost": 0.05},
}


class MicroSanctionSimulator:
    """P10 Micro Sanction Simulator — full KKS penalty simulation."""

    def classify_offense(self, tax_shortfall, offense_type="tax_evasion", has_prior=False):
        tier = SANCTION_GRADUATION[0]
        for t in SANCTION_GRADUATION:
            if tax_shortfall < t["threshold"]:
                tier = t
                break

        is_crime = tier["offense_type"] in ("CRIME", "AGGRAVATED")
        offense = OFFENSE_MAP.get(offense_type, OFFENSE_MAP["tax_evasion"])

        return {
            "tax_shortfall": tax_shortfall,
            "offense_type": offense_type,
            "offense_description": offense["description"],
            "article": f"Art. {offense['article']} KKS",
            "classification": tier["level"],
            "is_crime": is_crime,
            "max_rates": tier["max_rates"],
            "max_pw": tier["max_pw"],
            "limitation_years": 5 if is_crime else 3,
            "legal_basis": f"Art. {offense['article']} KKS, Art. 53 §3 KKS",
        }

    def calculate_fine(self, tax_shortfall, offense_type="tax_evasion", monthly_income=MIN_WAGE, recidivism=False):
        classification = self.classify_offense(tax_shortfall, offense_type)
        daily_rate = max(DAILY_RATE_MIN, monthly_income / 30)
        recidivism_mult = 1.5 if recidivism else 1.0

        if classification["classification"] == "Znikoma szkodliwość":
            fine = 0
            rates_count = 0
        elif classification["max_rates"] <= 180:
            rates_count = min(180, max(10, int(tax_shortfall / 10000)))
        elif classification["max_rates"] <= 360:
            rates_count = min(360, max(20, int(tax_shortfall / 5000)))
        elif classification["max_rates"] <= 720:
            rates_count = min(720, max(50, int(tax_shortfall / 2000)))
        else:
            rates_count = min(1080, max(100, int(tax_shortfall / 1000)))

        fine = round(daily_rate * rates_count * recidivism_mult, 2)
        pct_of_shortfall = round(fine / tax_shortfall * 100, 1) if tax_shortfall > 0 else 0

        return {
            "daily_rate_pln": round(daily_rate, 2),
            "rates_count": rates_count,
            "recidivism_multiplier": recidivism_mult,
            "estimated_fine_pln": fine,
            "fine_as_pct_of_shortfall": pct_of_shortfall,
            "fine_range": f"{round(DAILY_RATE_MIN * 10, 2):,.2f} – {round(DAILY_RATE_MIN * classification['max_rates'], 2):,.2f} PLN",
        }

    def estimate_pw_risk(self, tax_shortfall, offense_type="tax_evasion", offense_date=None):
        classification = self.classify_offense(tax_shortfall, offense_type)
        offense = OFFENSE_MAP.get(offense_type, OFFENSE_MAP["tax_evasion"])

        if tax_shortfall > 5_000_000 and offense_type in ("empty_invoice", "tax_evasion"):
            pw_years = 5
            pw_note = "OBLIGATORYJNE PW (Art. 62 §3 / Art. 54 — >5M PLN)"
        elif classification["max_pw"] == "10 lat":
            pw_years = 2
            pw_note = "Wysokie ryzyko — wielka wartość"
        elif classification["max_pw"] == "5 lat":
            pw_years = 1
            pw_note = "Średnie ryzyko — znaczna wartość"
        elif "30 dni" in str(classification["max_pw"]):
            pw_years = 0
            pw_note = "Brak PW — wykroczenie (max 30 dni aresztu)"
        else:
            pw_years = 0
            pw_note = "Brak PW"

        return {
            "pw_risk_years": pw_years,
            "pw_note": pw_note,
            "is_mandatory": "OBLIGATORYJNE" in pw_note,
            "legal_basis": "Art. 62 §3 KKS" if "OBLIGATORYJNE" in pw_note else "Art. 53-54 KKS",
        }

    def select_optimal_strategy(self, tax_shortfall, us_initiated=False, has_fraud=False, amount_over_100k=None):
        if amount_over_100k is None:
            amount_over_100k = tax_shortfall > 100_000

        if not us_initiated and not has_fraud:
            path = "PATH_A"
        elif us_initiated and not amount_over_100k:
            path = "PATH_B"
        elif us_initiated and amount_over_100k:
            path = "PATH_C"
        elif tax_shortfall > 5_000_000:
            path = "PATH_D"
        else:
            path = "PATH_E"

        path_info = DECISION_PATHS[path]
        reduction = path_info["reduction"]

        return {
            "selected_path": path,
            "path_name": path_info["name"],
            "reduction_pct": int(reduction * 100),
            "condition": path_info["condition"],
            "legal_basis": "Art. 16 KKS" if path == "PATH_A" else "Art. 16a KKS" if path == "PATH_B" else "Art. 220 OrdPU" if path == "PATH_C" else "Art. 113-122 KKS" if path == "PATH_D" else "Art. 54 OrdPU",
            "all_paths": {k: {"name": v["name"], "reduction_pct": int(v["reduction"] * 100)} for k, v in DECISION_PATHS.items()},
        }

    def full_simulation(self, tax_shortfall, offense_type="tax_evasion", monthly_income=MIN_WAGE,
                         recidivism=False, us_initiated=False, has_fraud=False):
        classification = self.classify_offense(tax_shortfall, offense_type, recidivism)
        fine = self.calculate_fine(tax_shortfall, offense_type, monthly_income, recidivism)
        pw = self.estimate_pw_risk(tax_shortfall, offense_type)
        strategy = self.select_optimal_strategy(tax_shortfall, us_initiated, has_fraud)
        optimal_path = DECISION_PATHS[strategy["selected_path"]]
        fine_after = round(fine["estimated_fine_pln"] * (1 - optimal_path["reduction"]), 2)

        return {
            "tax_shortfall": tax_shortfall,
            "offense_type": offense_type,
            "classification": classification,
            "fine_before_strategy_pln": fine["estimated_fine_pln"],
            "fine_after_strategy_pln": fine_after,
            "savings_pln": round(fine["estimated_fine_pln"] - fine_after, 2),
            "pw_risk": pw,
            "optimal_strategy": strategy,
            "total_cost_estimate_pln": round(fine_after + tax_shortfall * optimal_path["cost"], 2),
            "recommendation": f"Zastosuj {optimal_path['name']} — oszczędność {int(optimal_path['reduction']*100)}% na grzywnie = {round(fine['estimated_fine_pln']-fine_after, 2):,.2f} PLN",
            "legal_overview": f"Art. {OFFENSE_MAP.get(offense_type, OFFENSE_MAP['tax_evasion'])['article']} KKS + {strategy['legal_basis']}",
        }


def main():
    parser = argparse.ArgumentParser(description="P10 KKS Micro Sanction Simulator")
    parser.add_argument("--amount", type=float, default=0, help="Tax shortfall PLN")
    parser.add_argument("--offense", type=str, default="tax_evasion", help="Offense type")
    parser.add_argument("--income", type=float, default=MIN_WAGE, help="Monthly income")
    parser.add_argument("--recidivism", action="store_true", help="Prior conviction")
    parser.add_argument("--us-initiated", action="store_true", help="US already initiated proceedings")
    parser.add_argument("--has-fraud", action="store_true", help="Fraud elements present")
    parser.add_argument("--classify", action="store_true", help="Classify only")
    parser.add_argument("--fine", action="store_true", help="Fine calculation only")
    parser.add_argument("--pw", action="store_true", help="PW risk only")
    parser.add_argument("--strategy", action="store_true", help="Strategy only")
    parser.add_argument("--simulate-all", action="store_true", help="Full simulation")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    sim = MicroSanctionSimulator()

    if args.classify:
        r = sim.classify_offense(args.amount or 100000, args.offense, args.recidivism)
        print(f"\n  ⚖️  CLASSIFICATION: {r['classification']} ({r['article']})")
        print(f"     Max stawek: {r['max_rates']} | Max PW: {r['max_pw']} | Przedawnienie: {r['limitation_years']} lat")

    if args.fine:
        r = sim.calculate_fine(args.amount or 100000, args.offense, args.income, args.recidivism)
        print(f"\n  💰 FINE: {r['estimated_fine_pln']:,.2f} PLN ({r['rates_count']} stawek × {r['daily_rate_pln']:.2f} PLN)")
        print(f"     Grzywna jako % uszczuplenia: {r['fine_as_pct_of_shortfall']}%")

    if args.pw:
        r = sim.estimate_pw_risk(args.amount or 100000, args.offense)
        print(f"\n  🔒 PW RISK: {r['pw_risk_years']} lat — {r['pw_note']}")

    if args.strategy:
        r = sim.select_optimal_strategy(args.amount or 100000, args.us_initiated, args.has_fraud)
        print(f"\n  🎯 OPTIMAL PATH: {r['path_name']} ({r['reduction_pct']}% redukcji)")

    if args.simulate_all or (args.amount and not any([args.classify, args.fine, args.pw, args.strategy])):
        r = sim.full_simulation(args.amount or 250000, args.offense, args.income, args.recidivism, args.us_initiated, args.has_fraud)
        if args.json:
            print(json.dumps(r, indent=2, ensure_ascii=False, default=str))
        else:
            print(f"\n  🧮 FULL KKS SIMULATION")
            print(f"     Czyn: {r['offense_type']} | Kwota: {r['tax_shortfall']:,.2f} PLN")
            print(f"     Klasyfikacja: {r['classification']['classification']}")
            print(f"     Grzywna przed: {r['fine_before_strategy_pln']:,.2f} PLN")
            print(f"     PW ryzyko: {r['pw_risk']['pw_risk_years']} lat")
            print(f"     Strategia: {r['optimal_strategy']['path_name']} ({r['optimal_strategy']['reduction_pct']}%)")
            print(f"     Grzywna po: {r['fine_after_strategy_pln']:,.2f} PLN")
            print(f"     Oszczędność: {r['savings_pln']:,.2f} PLN")
            print(f"     Szacowany koszt całkowity: ~{r['total_cost_estimate_pln']:,.2f} PLN")


if __name__ == "__main__":
    main()
