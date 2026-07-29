#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — KKS Voluntary Disclosure Auto-Generator (INN02 — P09 Report)
═══════════════════════════════════════════════════════════════════════════════

Generuje automatyczny draft czynnego żalu (Art. 16 KKS).
Sprawdza warunki: przed wszczęciem postępowania, wpłata w 7 dni,
kompletność ujawnienia.

Użycie:
    python JDG/tools/kks_voluntary_disclosure.py --generate --amount 15000
    python JDG/tools/kks_voluntary_disclosure.py --check --date 2026-01-15

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse, json
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

VD_CHECKLIST = [
    ("1", "Zawiadomienie do Naczelnika US", "Pismo z opisem czynu i okoliczności", True),
    ("2", "Wskazanie wszystkich nieprawidłowości", "Pełne ujawnienie — każdy czyn osobno", True),
    ("3", "Wpłata zaległości + odsetki w 7 dni", "Przelew na konto US w ciągu 7 dni od złożenia", True),
    ("4", "Timing: PRZED wszczęciem postępowania", "Art. 16 § 5 KKS — po wszczęciu = nieskuteczny!", True),
    ("5", "Korekta deklaracji (jeśli dotyczy)", "Skorygowany JPK_V7/PIT + czynny żal", False),
    ("6", "Dokumentacja dowodowa", "Faktury, umowy, wyciągi bankowe", False),
    ("7", "Oświadczenie o pełnym ujawnieniu", "Podpisane własnoręcznie", True),
]

VD_EXCLUSIONS = [
    "Czyn został już wykryty przez organ (Art. 16 § 6)",
    "Sprawca zataił istotne informacje (Art. 16 § 7)",
    "Postępowanie już wszczęte (Art. 16 § 5)",
    "Czynny żal dotyczy przekupstwa (Art. 16a KKS — osobny tryb)",
]


class VoluntaryDisclosureGenerator:
    """INN02 P09: KKS Voluntary Disclosure Auto-Generator."""

    def check_eligibility(self, proceedings_started=False, amount_unpaid=0, is_bribe=False, discovered_by_authority=False):
        issues = []
        eligible = True

        if proceedings_started:
            eligible = False
            issues.append("❌ NIESKUTECZNY — postępowanie już wszczęte (Art. 16 § 5 KKS)")

        if discovered_by_authority:
            eligible = False
            issues.append("❌ NIESKUTECZNY — czyn wykryty przez organ (Art. 16 § 6 KKS)")

        if is_bribe:
            issues.append("⚠️  Przekupstwo — wymaga osobnego trybu (Art. 16a KKS)")

        if amount_unpaid <= 0:
            issues.append("ℹ️  Brak zaległości — czynny żal może być nadmiarowy")

        return {
            "eligible": eligible,
            "legal_basis": "Art. 16 § 1-8 KKS",
            "effect_if_successful": "ABSOLUTE_IMPUNITY — brak kary",
            "issues": issues,
            "checklist": VD_CHECKLIST,
            "exclusions": VD_EXCLUSIONS,
        }

    def generate_draft(self, amount_unpaid, offense_description, nip, company_name, tax_office):
        """Generate a draft voluntary disclosure document."""
        today = date.today()
        deadline = today + timedelta(days=7)
        interest_daily = round(amount_unpaid * 0.145 / 365, 2)

        draft = f"""
================================================================================
                        CZYNNY ŻAL — Art. 16 KKS
                  Zawiadomienie o popełnieniu czynu zabronionego
================================================================================

Miejscowość: _____________                    Data: {today.strftime('%d.%m.%Y')}

Do: Naczelnik {tax_office}

Od: {company_name}
    NIP: {nip}

═══════════════════════════════════════════════════════════════════════════════

Na podstawie art. 16 § 1 Kodeksu Karnego Skarbowego zawiadamiam o popełnieniu
czynu zabronionego:

OPIS CZYNU:
{offense_description}

KWOTA ZALEGŁOŚCI PODATKOWEJ: {amount_unpaid:,.2f} PLN
ODSETKI (14.5% rocznie): ~{interest_daily:.2f} PLN/dzień
TERMIN WPŁATY: {deadline.strftime('%d.%m.%Y')} (7 dni od złożenia)

OŚWIADCZENIE:
Oświadczam, że:
1. Zawiadomienie składam przed wykryciem czynu przez organ podatkowy.
2. Ujawniam wszystkie znane mi okoliczności popełnienia czynu.
3. Zobowiązuję się do wpłaty zaległości w terminie 7 dni.
4. Jestem świadomy/a, że nieujawnienie części okoliczności skutkuje
   odpowiedzialnością za nieujawnione czyny.

================================================================================
Podpis: _____________________
================================================================================
"""
        return {
            "draft": draft,
            "amount_unpaid": amount_unpaid,
            "deadline": deadline.isoformat(),
            "daily_interest": interest_daily,
            "total_with_interest_7d": round(amount_unpaid + interest_daily * 7, 2),
        }

    def generate_report(self):
        return {
            "tool": "KKS Voluntary Disclosure Auto-Generator (INN02 P09)",
            "version": "1.0.0",
            "legal_basis": "Art. 16 § 1-8 KKS",
            "checklist": [c[1] for c in VD_CHECKLIST],
            "exclusions": VD_EXCLUSIONS,
        }


def main():
    parser = argparse.ArgumentParser(description="KKS Voluntary Disclosure Generator (INN02 P09)")
    parser.add_argument("--check", action="store_true", help="Check eligibility")
    parser.add_argument("--generate", action="store_true", help="Generate draft document")
    parser.add_argument("--amount", type=float, default=0, help="Unpaid tax amount")
    parser.add_argument("--proceedings", action="store_true", help="Proceedings already started")
    parser.add_argument("--discovered", action="store_true", help="Already discovered by authority")
    parser.add_argument("--offense", type=str, default="Niezapłacony podatek VAT", help="Offense description")
    parser.add_argument("--nip", type=str, default="000-000-00-00", help="NIP")
    parser.add_argument("--company", type=str, default="JDG Sp. z o.o.", help="Company name")
    parser.add_argument("--office", type=str, default="Urzędu Skarbowego", help="Tax office")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    gen = VoluntaryDisclosureGenerator()

    if args.generate:
        draft = gen.generate_draft(args.amount, args.offense, args.nip, args.company, args.office)
        if args.json:
            print(json.dumps(draft, indent=2, ensure_ascii=False))
        else:
            print(draft["draft"])
            print(f"  ⚠️  TERMIN WPŁATY: {draft['deadline']} — {draft['total_with_interest_7d']:,.2f} PLN")
        return

    result = gen.check_eligibility(
        proceedings_started=args.proceedings,
        amount_unpaid=args.amount,
        discovered_by_authority=args.discovered,
    )

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"\n  📋 CZYNNY ŻAL — Art. 16 KKS")
        print(f"     Status: {'✅ MOŻLIWY' if result['eligible'] else '❌ NIEMOŻLIWY'}")
        print(f"     Skutek: {result['effect_if_successful']}")
        for issue in result["issues"]:
            print(f"     {issue}")
        print(f"\n  ✅ CHECKLIST:")
        for num, title, desc, req in VD_CHECKLIST:
            print(f"     [{num}] {'[OBOWIĄZKOWE]' if req else '[OPCJONALNE]'} {title}: {desc}")

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P09_INN02_VOLUNTARY_DISCLOSURE.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write(f"P09 INN02 — Voluntary Disclosure Auto-Generator\nArt. 16 KKS\n")
        print(f"  📄 {path}")


if __name__ == "__main__":
    main()
