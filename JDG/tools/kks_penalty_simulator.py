#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — KKS Penalty Simulator (INN01 — P09 Report)
═══════════════════════════════════════════════════════════════════════════════

Symulator kar KKS — kalkulacja grzywny, stawek dziennych, ryzyka PW.
Parametry 2026:
  - Stawka dzienna: 1/30 minimalnego wynagrodzenia (56 PLN) do 400× (56 000 PLN)
  - Próg przestępstwo/wykroczenie: 200× minimalne wynagrodzenie (~933 200 PLN)
  - Max stawki: 720 (ciężkie przestępstwa), 240 (wykroczenia)
  - PW: od 5 dni do 15 lat

Użycie:
    python JDG/tools/kks_penalty_simulator.py --amount 150000 --severity HIGH
    python JDG/tools/kks_penalty_simulator.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse, json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MIN_WAGE_2026 = 4666.00
DAILY_RATE_MIN = round(MIN_WAGE_2026 / 30, 2)  # ~155.53 PLN
DAILY_RATE_MAX = MIN_WAGE_2026 * 400  # 1 866 400 PLN
CRIME_THRESHOLD = MIN_WAGE_2026 * 200  # ~933 200 PLN

OFFENSE_MATRIX = {
    "Art. 54 §1": {"name": "Uchylanie się od opodatkowania", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "Art. 54 §2": {"name": "Uchylanie — duża wartość", "max_rates": 720, "max_pw_years": 10, "severity": "CRITICAL"},
    "Art. 56 §1": {"name": "Nierzetelne PKPiR", "max_rates": 240, "max_pw_years": 0, "severity": "HIGH"},
    "Art. 56 §3": {"name": "Fikcyjne wpisy PKPiR", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "Art. 57 §1": {"name": "Nierzetelna ewidencja VAT", "max_rates": 360, "max_pw_years": 0, "severity": "HIGH"},
    "Art. 62 §2": {"name": "Puste faktury", "max_rates": 720, "max_pw_years": 8, "severity": "CRITICAL"},
    "Art. 62 §3": {"name": "Korzyść >5M → obligatoryjne PW", "max_rates": 1080, "max_pw_years": 15, "severity": "CRITICAL"},
    "Art. 64": {"name": "Niewłaściwa stawka VAT", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
    "Art. 77 §1": {"name": "Niezłożenie deklaracji (wykroczenie)", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
    "Art. 77 §2": {"name": "Uporczywe niezłożenie (przestępstwo)", "max_rates": 720, "max_pw_years": 3, "severity": "HIGH"},
    "Art. 79": {"name": "Niezapłacenie podatku", "max_rates": 720, "max_pw_years": 3, "severity": "HIGH"},
}


class KKSPenaltySimulator:
    """INN01 P09: KKS Penalty Simulator."""

    def simulate(self, amount_pln, offense_article="Art. 54 §1", severity="MEDIUM", is_recidivist=False, has_disclosure=False):
        offense = OFFENSE_MATRIX.get(offense_article, OFFENSE_MATRIX["Art. 54 §1"])

        # Classify: crime vs misdemeanor
        is_crime = amount_pln > CRIME_THRESHOLD or severity in ("HIGH", "CRITICAL")
        classification = "PRZESTĘPSTWO" if is_crime else "WYKROCZENIE"

        # Daily rate calculation
        daily_rate = max(DAILY_RATE_MIN, min(DAILY_RATE_MAX, amount_pln * 0.001))
        daily_rate = min(daily_rate, DAILY_RATE_MAX)

        # Number of daily rates
        if is_crime:
            rates_count = int(min(offense["max_rates"], max(10, amount_pln / 5000)))
        else:
            rates_count = int(min(180, max(10, amount_pln / 10000)))

        # Fine calculation
        fine = round(daily_rate * rates_count, 2)

        # PW risk
        if amount_pln > 5_000_000:
            pw_risk = "OBLIGATORYJNE"
            pw_years = offense["max_pw_years"]
        elif is_crime and offense["max_pw_years"] > 0:
            pw_risk = "WYSOKIE" if amount_pln > 1_000_000 else "ŚREDNIE"
            pw_years = min(offense["max_pw_years"], max(1, int(amount_pln / 500_000)))
        else:
            pw_risk = "NISKIE" if is_crime else "BRAK"
            pw_years = 0

        # Recidivism multiplier
        multiplier = 1.5 if is_recidivist else 1.0
        if is_recidivist:
            fine = round(fine * multiplier, 2)

        # Voluntary disclosure effect
        if has_disclosure:
            fine = 0
            pw_risk = "BRAK (CZYNNY ŻAL)"
            pw_years = 0

        return {
            "offense": offense["name"],
            "article": offense_article,
            "amount_pln": amount_pln,
            "classification": classification,
            "daily_rate_pln": round(daily_rate, 2),
            "daily_rates_count": rates_count,
            "fine_pln": fine,
            "pw_risk": pw_risk,
            "pw_years": pw_years,
            "recidivism_multiplier": multiplier,
            "voluntary_disclosure_applied": has_disclosure,
            "defense_note": "CZYNNY ŻAL = BEZKARNOŚĆ!" if amount_pln < 500_000 else "Skonsultuj z adwokatem — duża wartość" if amount_pln < 5_000_000 else "OBLIGATORYJNE PW — natychmiast adwokat!"
        }

    def generate_report(self):
        return {
            "tool": "KKS Penalty Simulator (INN01 P09)",
            "version": "1.0.0",
            "parameters_2026": {
                "min_wage": MIN_WAGE_2026,
                "daily_rate_min": DAILY_RATE_MIN,
                "daily_rate_max": DAILY_RATE_MAX,
                "crime_threshold_200x": CRIME_THRESHOLD,
            },
            "offense_matrix": {k: {"max_rates": v["max_rates"], "max_pw": v["max_pw_years"]} for k, v in OFFENSE_MATRIX.items()},
        }


def main():
    parser = argparse.ArgumentParser(description="KKS Penalty Simulator (INN01 P09)")
    parser.add_argument("--amount", type=float, default=100000, help="Tax shortfall amount PLN")
    parser.add_argument("--article", type=str, default="Art. 54 §1", help="KKS article")
    parser.add_argument("--severity", type=str, default="MEDIUM", choices=["LOW","MEDIUM","HIGH","CRITICAL"])
    parser.add_argument("--recidivist", action="store_true", help="Repeat offender")
    parser.add_argument("--disclosure", action="store_true", help="Voluntary disclosure applied")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    sim = KKSPenaltySimulator()
    result = sim.simulate(args.amount, args.article, args.severity, args.recidivist, args.disclosure)

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"\n  ⚖️  SYMULACJA KARY KKS:")
        print(f"     Czyn: {result['offense']} ({result['article']})")
        print(f"     Kwota: {result['amount_pln']:,.2f} PLN → {result['classification']}")
        print(f"     Stawka dzienna: {result['daily_rate_pln']:.2f} PLN × {result['daily_rates_count']} stawek")
        print(f"     Grzywna: {result['fine_pln']:,.2f} PLN")
        print(f"     Ryzyko PW: {result['pw_risk']}" + (f" (do {result['pw_years']} lat)" if result['pw_years'] > 0 else ""))
        print(f"     {result['defense_note']}")

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P09_INN01_KKS_PENALTY.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write(f"P09 INN01 — KKS Penalty Simulator\nCrime threshold: {CRIME_THRESHOLD:,.0f} PLN\n")
        print(f"  📄 {path}")


if __name__ == "__main__":
    main()
