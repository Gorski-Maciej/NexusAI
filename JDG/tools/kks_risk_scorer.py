#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — KKS Risk Scorer + Audit Defense Pack (INN07+INN10 — P09 Report)
═══════════════════════════════════════════════════════════════════════════════

INN07: Tax Evasion Risk Scorer — ocena ryzyka karnego-skarbowego JDG
INN10: KKS Audit Defense Pack — pakiet obrony przed kontrolą

Użycie:
    python JDG/tools/kks_risk_scorer.py --score --indicators empty_invoice,vat_gap,books_gap
    python JDG/tools/kks_risk_scorer.py --defense --audit-date 2026-08-15
    python JDG/tools/kks_risk_scorer.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse, json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

RISK_INDICATORS = {
    "empty_invoice": {"weight": 1.0, "name": "Puste faktury", "article": "Art. 62 §2 KKS", "severity": "CRITICAL"},
    "carousel_vat": {"weight": 1.0, "name": "Karuzela VAT", "article": "Art. 62 §2 KKS", "severity": "CRITICAL"},
    "tax_evasion": {"weight": 0.9, "name": "Uchylanie od podatku", "article": "Art. 54 KKS", "severity": "CRITICAL"},
    "concealed_business": {"weight": 0.9, "name": "Ukryta działalność", "article": "Art. 54 §3 KKS", "severity": "CRITICAL"},
    "fictitious_costs": {"weight": 0.85, "name": "Fikcyjne koszty", "article": "Art. 54 §1 KKS", "severity": "CRITICAL"},
    "books_gap": {"weight": 0.7, "name": "Nierzetelne księgi", "article": "Art. 56 KKS", "severity": "HIGH"},
    "vat_gap": {"weight": 0.7, "name": "Nierzetelna ewidencja VAT", "article": "Art. 57 KKS", "severity": "HIGH"},
    "declaration_missing": {"weight": 0.4, "name": "Brak deklaracji", "article": "Art. 77 KKS", "severity": "MEDIUM"},
    "tax_unpaid": {"weight": 0.5, "name": "Niezapłacony podatek", "article": "Art. 79 KKS", "severity": "HIGH"},
    "document_destruction": {"weight": 0.8, "name": "Zniszczenie dokumentów", "article": "Art. 60 KKS", "severity": "HIGH"},
    "audit_obstruction": {"weight": 0.75, "name": "Utrudnianie kontroli", "article": "Art. 69 KKS", "severity": "HIGH"},
    "repeat_offense": {"weight": 0.6, "name": "Recydywa", "article": "Art. 19 §3 KKS", "severity": "HIGH"},
    "organized_group": {"weight": 1.0, "name": "Grupa zorganizowana", "article": "Art. 19 §4 KKS", "severity": "CRITICAL"},
}

DEFENSE_ITEMS = [
    ("Pełny komplet faktur zakupowych i sprzedażowych", "5 lat wstecz"),
    ("Ewidencja PKPiR — kolumny 1-17", "Kompletność zapisów"),
    ("Deklaracje VAT-7/JPK_V7M + PIT", "Zgodność z ewidencją"),
    ("Dowody zapłaty ZUS (DRA/RCA)", "Potwierdzenia przelewów"),
    ("Umowy z kontrahentami + zamówienia", "Weryfikacja transakcji"),
    ("Wyciągi bankowe firmowe", "Pełna historia rachunku"),
    ("Ewidencja środków trwałych + amortyzacja", "Tabela + dowody zakupu"),
    ("Korespondencja z US/ZUS/KAS", "Chronologicznie"),
    ("Polisy ubezpieczeniowe", "OC działalności"),
    ("Regulaminy wewnętrzne + polityka rachunkowości", "Dokumentacja organizacyjna"),
]


class KKSIntegratedTools:
    """INN07 + INN10 P09: Risk Scorer + Audit Defense Pack."""

    def score_risk(self, indicators, tax_shortfall=0, prior_incidents=0):
        active = {k: v for k, v in RISK_INDICATORS.items() if k in indicators}
        raw_score = sum(v["weight"] for v in active.values())
        max_score = sum(v["weight"] for v in RISK_INDICATORS.values())
        normalized = (raw_score / max_score * 100) if max_score > 0 else 0

        # Adjust for amount and recidivism
        if tax_shortfall > 5_000_000:
            normalized = min(100, normalized + 20)
        elif tax_shortfall > 1_000_000:
            normalized = min(100, normalized + 10)
        elif tax_shortfall > 500_000:
            normalized = min(100, normalized + 5)

        if prior_incidents >= 3:
            normalized = min(100, normalized + 15)

        level = "LOW" if normalized <= 25 else "MEDIUM" if normalized <= 50 else "HIGH" if normalized <= 75 else "CRITICAL"

        return {
            "risk_score": round(normalized, 1),
            "risk_level": level,
            "active_indicators": [{"name": v["name"], "article": v["article"], "severity": v["severity"]} for v in active.values()],
            "count": len(active),
            "tax_shortfall": tax_shortfall,
            "prior_incidents": prior_incidents,
            "recommendation": "BEZPIECZNIE" if level == "LOW" else "MONITORUJ" if level == "MEDIUM" else "CZYNNY ŻAL + ADWOKAT" if level == "HIGH" else "NATYCHMIAST ADWOKAT!",
        }

    def generate_defense_pack(self, audit_date_str=None):
        audit_date = date.fromisoformat(audit_date_str) if audit_date_str else date.today()
        prep_deadline = audit_date - timedelta(days=7)

        return {
            "audit_date": audit_date.isoformat(),
            "preparation_deadline": prep_deadline.isoformat(),
            "days_to_prepare": (audit_date - date.today()).days,
            "checklist": DEFENSE_ITEMS,
            "legal_rights": [
                "Prawo do czynnego udziału pełnomocnika (adwokat/radca prawny)",
                "Prawo do odmowy zeznań gdy grozi odpowiedzialność karna (Art. 199 KPK w zw. z Art. 113 KKS)",
                "Prawo do składania wyjaśnień na piśmie",
                "Prawo do nagrywania kontroli (za zgodą kontrolującego)",
                "Prawo do złożenia zastrzeżeń do protokołu w ciągu 14 dni",
                "Prawo do korekty deklaracji przed zakończeniem kontroli",
            ],
            "strategy": [
                "1. Skompletuj WSZYSTKIE dokumenty przed kontrolą",
                "2. Zidentyfikuj potencjalne ryzyka (uruchom KKS Risk Scorer)",
                "3. Rozważ CZYNNY ŻAL przed kontrolą (Art. 16 KKS)",
                "4. Ustal z adwokatem strategię odpowiedzi",
                "5. Przygotuj pisemne wyjaśnienia do każdego ryzyka",
                "6. NIGDY nie niszcz dokumentów po wezwaniu",
                "7. Dokumentuj każdą czynność kontrolującego",
            ],
        }

    def generate_report(self):
        return {
            "tool": "KKS Risk Scorer + Audit Defense Pack (INN07+INN10 P09)",
            "version": "1.0.0",
            "indicators_count": len(RISK_INDICATORS),
            "defense_items_count": len(DEFENSE_ITEMS),
        }


def main():
    parser = argparse.ArgumentParser(description="KKS Risk Scorer + Audit Defense (INN07+INN10 P09)")
    parser.add_argument("--score", action="store_true", help="Score risk")
    parser.add_argument("--indicators", type=str, default="", help="Comma-separated risk indicators")
    parser.add_argument("--shortfall", type=float, default=0, help="Tax shortfall PLN")
    parser.add_argument("--prior", type=int, default=0, help="Prior KKS incidents")
    parser.add_argument("--defense", action="store_true", help="Generate defense pack")
    parser.add_argument("--audit-date", type=str, default=None, help="Audit date (YYYY-MM-DD)")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tools = KKSIntegratedTools()

    if args.defense:
        result = tools.generate_defense_pack(args.audit_date)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🛡️  PAKIET OBRONY PRZED KONTROLĄ KAS:")
            print(f"     Data kontroli: {result['audit_date']}")
            print(f"     Dni do przygotowania: {result['days_to_prepare']}")
            print(f"\n  📋 CHECKLIST DOKUMENTÓW:")
            for item, note in result["checklist"]:
                print(f"     ⬜ {item} — {note}")
            print(f"\n  ⚖️  PRAWA PODCZAS KONTROLI:")
            for right in result["legal_rights"]:
                print(f"     ✓ {right}")
            print(f"\n  🎯 STRATEGIA:")
            for step in result["strategy"]:
                print(f"     {step}")
        return

    if args.score:
        indicators = [i.strip() for i in args.indicators.split(",") if i.strip()] if args.indicators else []
        result = tools.score_risk(indicators, args.shortfall, args.prior)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🎯 KKS RISK SCORER:")
            print(f"     Ryzyko: {result['risk_score']}% — {result['risk_level']}")
            print(f"     Aktywne wskaźniki: {result['count']}")
            for ind in result["active_indicators"]:
                print(f"       [{ind['severity']}] {ind['name']} — {ind['article']}")
            print(f"     Rekomendacja: {result['recommendation']}")
        return

    print("\n  ═════════════════════════════════════════════════════════════════")
    print("  KKS Risk Scorer + Audit Defense Pack (INN07+INN10 P09)")
    print("  Użyj --score lub --defense")
    print("  ═════════════════════════════════════════════════════════════════")

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P09_INN07_INN10_KKS_RISK_DEFENSE.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write("P09 INN07+INN10 — KKS Risk Scorer + Audit Defense Pack\n")
        print(f"  📄 {path}")


if __name__ == "__main__":
    main()
