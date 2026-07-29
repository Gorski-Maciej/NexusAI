#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — KKS Completeness Matrix + Penalty Gradation (INN08+INN09 — P09)
═══════════════════════════════════════════════════════════════════════════════

INN08: Macierz pokrycia 30 artykułów KKS
INN09: Wizualizacja gradacji kar KKS

Użycie:
    python JDG/tools/kks_completeness_matrix.py [--json] [--report]

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse, json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ── KKS Article Coverage Matrix (from P09 report Section 3.10) ──────────────
KKS_ARTICLES = [
    ("16", "Czynny żal", "10+", "BLOCK/W", "85%", "V.dobre"),
    ("17", "Czynny żal — rozszerz.", "3", "-", "40%", "Słabe"),
    ("19", "Recydywa", "9", "TRIAGE", "70%", "Dobre"),
    ("20", "Przedawnienie (5/3 lat)", "4", "-", "75%", "Dobre"),
    ("21", "Przerwanie przedawnienia", "1", "-", "50%", "Minimalne"),
    ("22", "Stawki dzienne", "8", "-", "70%", "Dobre"),
    ("23", "Wymiar grzywny", "7", "-", "75%", "Dobre"),
    ("44", "Przedawnienie kary", "11", "WARNING", "75%", "Dobre"),
    ("51", "Przedawnienie wykroczenia", "3", "-", "50%", "Minimalne"),
    ("53", "Przekroczenie uprawnień", "4", "-", "40%", "Słabe"),
    ("54", "Uchylanie od podatku", "15+", "BLOCK", "88%", "V.dobre"),
    ("56", "Nierzetelne PKPiR", "12", "BLOCK", "75%", "Dobre"),
    ("57", "Nierzetelna ewidencja VAT", "16", "BLOCK", "70%", "Dobre"),
    ("60", "Niszczenie dokumentów", "17", "BLOCK", "70%", "Dobre"),
    ("62", "Puste faktury", "20+", "BLOCK", "90%", "V.dobre"),
    ("64", "Niewłaściwa stawka VAT", "6", "BLOCK", "75%", "Dobre"),
    ("69", "Utrudnianie kontroli", "5", "BLOCK", "80%", "Dobre"),
    ("77", "Niezłożenie deklaracji", "13", "W/BLOCK", "78%", "Dobre"),
    ("79", "Niezapłacenie podatku", "5", "TRIAGE/W", "75%", "Dobre"),
    ("83", "Niewykonanie decyzji", "14", "-", "72%", "Dobre"),
    ("24", "Kara zastępcza", "6", "-", "65%", "Umiarkowane"),
    ("25", "Kara zastępcza PW", "3", "BLOCK", "60%", "Umiarkowane"),
    ("48", "Mandat karny", "3", "-", "50%", "Minimalne"),
    ("59", "Brak ksiąg", "7", "-", "55%", "Umiarkowane"),
    ("63", "Fałszowanie faktur", "10", "BLOCK", "75%", "Dobre"),
    ("65", "Wyłudzenie", "3", "-", "40%", "Słabe"),
    ("67", "Brak ewidencji", "3", "-", "40%", "Słabe"),
    ("68", "Naruszenie rachunkowości", "6", "BLOCK", "65%", "Umiarkowane"),
    ("76", "Nieuzasadniony zwrot", "8", "-", "65%", "Umiarkowane"),
    ("81", "Naruszenie przep. dewiz.", "11", "-", "60%", "Umiarkowane"),
]

MISSING_ARTICLES = [
    "Art. 55 KKS — Forma przestępstwa (umyślność/nieumyślność)",
    "Art. 58 KKS — Fałszowanie znaków urzędowych",
    "Art. 61 KKS — Brak dokumentów podrzędnych",
    "Art. 65-67 KKS — Formy wyłudzenia (minimalne)",
    "Art. 72 KKS — Naruszenie przepisów o grach",
    "Art. 78 KKS — Niezgłoszenie zmian",
    "Art. 84 KKS — Przepisy karne",
    "Art. 86a KKS — Dobrowolne poddanie się odpowiedzialności",
]

PENALTY_GRADATION = [
    ("WYKROCZENIE", "Do 180", "Do 30 dni", "Art. 48, 77 §1"),
    ("WYKROCZENIE uporczywe", "Do 360", "Do 3 lat PW", "Art. 77 §2"),
    ("PRZESTĘPSTWO standard", "Do 720", "Do 5 lat PW", "Art. 54 §1, 56 §3"),
    ("PRZESTĘPSTWO ciężkie", "Do 720", "Do 8 lat PW", "Art. 62 §2"),
    ("WIELKA WARTOŚĆ >5M", "Do 1080", "Do 10 lat PW", "Art. 54 §2"),
    ("KARUZELA VAT", "Do 1080", "Do 15 lat PW", "Art. 62 §2 kwal."),
    ("RECYDYWA (×1.5)", "×1.5", "×1.5", "Art. 19 §3 KKS"),
]


class KKSCompletenessGradation:
    """INN08 + INN09 P09: KKS Completeness Matrix + Penalty Gradation."""

    def analyze_coverage(self):
        total = len(KKS_ARTICLES)
        def parse_cov(cov_str):
            """Parse coverage string like '85%', '10+', '15+' to integer."""
            digits = ''.join(c for c in cov_str if c.isdigit())
            return int(digits) if digits else 0

        covered_70plus = sum(1 for a in KKS_ARTICLES if parse_cov(a[4]) >= 70)
        covered_50minus = sum(1 for a in KKS_ARTICLES if parse_cov(a[4]) < 50)

        return {
            "total_articles": total,
            "covered_70pct_plus": covered_70plus,
            "covered_below_50pct": covered_50minus,
            "average_coverage_pct": round(sum(parse_cov(a[4]) for a in KKS_ARTICLES) / total, 1),
            "articles": [{"art": a[0], "name": a[1], "rules": a[2], "routing": a[3], "coverage": a[4], "grade": a[5]} for a in KKS_ARTICLES],
            "missing_articles": MISSING_ARTICLES,
        }

    def gradation_report(self):
        return {
            "gradation_levels": [
                {"level": g[0], "max_rates": g[1], "max_pw": g[2], "legal_basis": g[3]}
                for g in PENALTY_GRADATION
            ],
            "daily_rate_range": "56 PLN (1/30 min.) — 56 000 PLN (400× min.)",
            "crime_threshold_2026": "200× minimalne wynagrodzenie ≈ 933 200 PLN",
        }

    def generate_report(self):
        return {
            "tool": "KKS Completeness Matrix + Penalty Gradation (INN08+INN09 P09)",
            "version": "1.0.0",
            "coverage": self.analyze_coverage(),
            "gradation": self.gradation_report(),
        }


def main():
    parser = argparse.ArgumentParser(description="KKS Completeness + Gradation (INN08+INN09 P09)")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tools = KKSCompletenessGradation()
    cov = tools.analyze_coverage()
    grad = tools.gradation_report()

    if args.json:
        print(json.dumps({"coverage": cov, "gradation": grad}, indent=2, ensure_ascii=False))
    else:
        print(f"\n  ═════════════════════════════════════════════════════════════════")
        print(f"  KKS Article Completeness Matrix (INN08 P09)")
        print(f"  Artykuły: {cov['total_articles']} | Średnie pokrycie: {cov['average_coverage_pct']}%")
        print(f"  ≥70%: {cov['covered_70pct_plus']} | <50%: {cov['covered_below_50pct']}")
        print(f"  ═════════════════════════════════════════════════════════════════")
        print(f"\n  📊 MACIERZ POKRYCIA:")
        print(f"  {'Art.':>5s} | {'Opis':<30s} | {'Reguły':>6s} | {'Routing':>9s} | {'Pokrycie':>8s}")
        print(f"  {'-'*5}-+-{'-'*30}-+-{'-'*6}-+-{'-'*9}-+-{'-'*8}")
        for a in KKS_ARTICLES:
            print(f"  {a[0]:>5s} | {a[1]:<30s} | {a[2]:>6s} | {a[3]:>9s} | {a[4]:>8s}")

        print(f"\n  🔴 BRAKI ({len(MISSING_ARTICLES)}):")
        for m in MISSING_ARTICLES:
            print(f"     ❌ {m}")

        print(f"\n  ═════════════════════════════════════════════════════════════════")
        print(f"  KKS Penalty Gradation Visualizer (INN09 P09)")
        print(f"  Zakres stawek: {grad['daily_rate_range']}")
        print(f"  Próg przestępstwa: {grad['crime_threshold_2026']}")
        print(f"  ═════════════════════════════════════════════════════════════════")
        print(f"\n  ⚖️  GRADACJA KAR:")
        print(f"  {'Poziom':<25s} | {'Stawki':>10s} | {'PW':>15s} | {'Podstawa'}")
        print(f"  {'-'*25}-+-{'-'*10}-+-{'-'*15}-+-{'-'*20}")
        for g in PENALTY_GRADATION:
            print(f"  {g[0]:<25s} | {g[1]:>10s} | {g[2]:>15s} | {g[3]}")

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P09_INN08_INN09_KKS_MATRIX.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write(f"P09 INN08+INN09 — KKS Completeness + Gradation\n")
            f.write(f"Coverage: {cov['average_coverage_pct']}%\n")
        print(f"  📄 {path}")


if __name__ == "__main__":
    main()
