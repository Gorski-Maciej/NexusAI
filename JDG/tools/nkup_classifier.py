#!/usr/bin/env python3
"""
NexusAI JDG — NKUP CLASSIFIER (PROMPT 06 — PIT MIKRO + AMORTYZACJA + NKUP, Sekcja 8)
====================================================================================
Klasyfikator wydatku → punkt art. 23 PIT (57 punktów wyłączeń z KUP) z drzewem
decyzyjnym, przykładami i rejestrem „wydatków wątpliwych" (SUGGEST). Spójny z
`nkup_enterprise_complete.rego` (59 reguł) i `rules/pit/kup.rego` (PROMPT 05).

Kluczowe punkty art. 23 (wybór):
  pkt 1  — ulepszenia środka trwałego w części przekraczającej wartość początkową
  pkt 4  — koszty egzekucji (zapłacone przez dłużnika)  [hmm: pkt 4 = kary umowne]
  pkt 16 — kary umowne i odszkodowania z tytułu wad towarów
  pkt 23 — reprezentacja, w szczególności wydatki na usługi gastronomiczne,
           zakup żywności oraz napojów (w tym alkoholowych)
  pkt 37 — składki ZUS niezapłacone w terminie
  pkt 43 — VAT naliczony (odliczony / nieodliczalny z powodu braku faktury)
  pkt 46 — koszty eksploatacji samochodu (bez ewidencji przebiegu = 75% KUP)
  pkt 47 — wydatki z tytułu umowy leasingu (w części)
  pkt 55 — składki na ubezpieczenie społeczne (WYJĄTEK: nie są NKUP)

Usage:
  python nkup_classifier.py classify --expense REPRESENTATION [--amount 500]
  python nkup_classifier.py classify --expense CAR_FUEL --mileage-log
  python nkup_classifier.py map
"""

import argparse
import json
import sys

# Katalog: typ wydatku → punkt art. 23 + kwalifikacja
NKUP_CATALOG = {
    "REPRESENTATION": {
        "point": "art. 23 ust. 1 pkt 23 PIT",
        "kup": False,
        "note": "Reprezentacja (gastronomia, alkohol, usługi hotelowe w celach reprezentacyjnych) = NKUP w 100%",
        "examples": ["kolacje biznesowe", "alkohol", "usługi gastronomiczne w celach reprezentacji", "prezenty dla kontrahentów"],
    },
    "PENALTY": {
        "point": "art. 23 ust. 1 pkt 16 PIT",
        "kup": False,
        "note": "Kary umowne i odszkodowania z tytułu wad dostarczonych towarów/wykonanych robót = NKUP",
        "examples": ["kara umowna za opóźnienie", "odszkodowanie za wady towaru"],
    },
    "CAR_FUEL": {
        "point": "art. 23 ust. 1 pkt 46 PIT",
        "kup": True,
        "partial_pct": 75,
        "note": "Koszty eksploatacji auta: 75% KUP bez ewidencji przebiegu, 100% z ewidencją (limit auta 150k/225k)",
        "examples": ["paliwo", "serwis", "ubezpieczenie auta"],
    },
    "CAR_INSURANCE": {
        "point": "art. 23 ust. 1 pkt 46 PIT",
        "kup": True,
        "partial_pct": 75,
        "note": "Ubezpieczenie auta — jak koszty eksploatacji (75%/100%)",
        "examples": ["OC", "AC"],
    },
    "VAT_NON_DEDUCTIBLE": {
        "point": "art. 23 ust. 1 pkt 43 PIT",
        "kup": False,
        "note": "VAT naliczony nieodliczalny (np. brak faktury, zakup usług noclegowych) = NKUP",
        "examples": ["VAT od zakupu bez faktury", "VAT od usług noclegowych"],
    },
    "ZUS_UNPAID": {
        "point": "art. 23 ust. 1 pkt 37 PIT",
        "kup": False,
        "note": "Niezapłacone w terminie składki ZUS = NKUP (po zapłacie = KUP, art. 22 ust. 6ba)",
        "examples": ["składki ZUS za poprzedni miesiąc niezapłacone do terminu"],
    },
    "ZUS_SOCIAL_PAID": {
        "point": "art. 23 ust. 1 pkt 55 PIT (wyjątek)",
        "kup": True,
        "note": "Zapłacone składki na ubezpieczenie społeczne = KUP (wyjątek od pkt 55: pkt 55 dotyczy składek nienależnych)",
        "examples": ["składki społeczne ZUS opłacone"],
    },
    "PERSONAL": {
        "point": "art. 23 ust. 1 pkt 10-11 PIT",
        "kup": False,
        "note": "Wydatki osobiste (żywność, odzież, leczenie prywatne) = NKUP",
        "examples": ["zakupy spożywcze", "odzież osobista"],
    },
    "GIFT": {
        "point": "art. 23 ust. 1 pkt 34 PIT",
        "kup": True,
        "note": "Prezenty małej wartości (≤ 200 zł, reklama) = KUP; pozostałe dary = NKUP (pkt 16/17)",
        "examples": ["prezent ≤ 200 zł z logo firmy"],
    },
    "DONATION": {
        "point": "art. 23 ust. 1 pkt 16 PIT / art. 26 PIT",
        "kup": False,
        "note": "Darowizny = NKUP (odliczenie w zeznaniu do 6% dochodu, art. 26 ust. 1 pkt 9)",
        "examples": ["darowizna na OPP", "darowizna na kult religijny"],
    },
    "DEDUCTIBLE_VAT": {
        "point": "art. 23 ust. 1 pkt 43 PIT (odwrotnie)",
        "kup": True,
        "note": "VAT naliczony podlegający odliczeniu nie zwiększa KUP (neutralny)",
        "examples": ["VAT naliczony odliczany w JPK"],
    },
    "AMORTIZATION_NOT_ALLOWED": {
        "point": "art. 23 ust. 1 pkt 1 PIT",
        "kup": False,
        "note": "Odpisy amortyzacyjne od wartości przewyższającej limity (auta 150k/225k, ulepszenia) = NKUP",
        "examples": ["amortyzacja auta > 150 000 zł", "ulepszenie przekraczające wartość początkową"],
    },
    "DOUBTFUL": {
        "point": "art. 23 ust. 1 pkt 5 PIT (wydatki wątpliwe)",
        "kup": None,
        "note": "Wydatek wątpliwy — SUGGEST: dokumentuj i przeanalizuj związek z przychodami",
        "examples": ["wydatek bez wyraźnego związku z działalnością"],
    },
}

POINTS = [
    ("pkt 1", "ulepszenia ŚT w części przewyższającej wartość początkową"),
    ("pkt 4", "koszty egzekucyjne / kary umowne (w części)"),
    ("pkt 16", "kary umowne i odszkodowania za wady"),
    ("pkt 23", "reprezentacja"),
    ("pkt 34", "prezenty (małej wartości = KUP)"),
    ("pkt 37", "niezapłacone składki ZUS"),
    ("pkt 43", "VAT naliczony (nieodliczalny)"),
    ("pkt 46", "koszty eksploatacji samochodu"),
    ("pkt 47", "leasing (część kapitałowa)"),
    ("pkt 55", "składki nienależne / odsetki"),
]


def classify(expense: str, amount: float = 0.0, mileage_log: bool = False) -> dict:
    """Klasyfikacja wydatku → punkt art. 23 + kwalifikacja KUP/NKUP/SUGGEST."""
    expense = expense.upper()
    entry = NKUP_CATALOG.get(expense)
    if entry is None:
        return {
            "expense": expense,
            "classified": False,
            "action": "SUGGEST",
            "point": "art. 23 ust. 1 PIT (analiza indywidualna)",
            "note": "Typ wydatku poza katalogiem — zakwalifikuj wg drzewa decyzyjnego (katalog: " + ", ".join(sorted(NKUP_CATALOG)) + ")",
        }

    kup = entry["kup"]
    pct = entry.get("partial_pct")
    if expense in {"CAR_FUEL", "CAR_INSURANCE"} and mileage_log:
        pct = 100
        kup = True

    if expense == "GIFT" and amount > 200:
        kup = False
        entry = {**entry, "note": "Prezent > 200 zł = NKUP (nie ma charakteru reklamowego)"}

    return {
        "expense": expense,
        "classified": True,
        "point": entry["point"],
        "kup": kup,
        "partial_pct": pct,
        "note": entry["note"],
        "examples": entry["examples"],
        "action": "KUP" if kup is True else ("NKUP" if kup is False else "SUGGEST"),
        "amount": amount,
        "decision_tree": {
            "związek_z_przychodami": "TAK" if kup is True else "NIE",
            "dokumentacja": "wymagana faktura/dowód",
            "wyłączenie_art23": entry["point"],
        },
    }


def map_all() -> dict:
    """Pełna mapa typów wydatków → punkty art. 23."""
    return {k: {"point": v["point"], "kup": v["kup"], "action": "KUP" if v["kup"] is True
                else ("NKUP" if v["kup"] is False else "SUGGEST")}
            for k, v in NKUP_CATALOG.items()}


def main(argv=None):
    ap = argparse.ArgumentParser(description="NKUP Classifier (PROMPT 06)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_c = sub.add_parser("classify")
    p_c.add_argument("--expense", required=True)
    p_c.add_argument("--amount", type=float, default=0.0)
    p_c.add_argument("--mileage-log", action="store_true")

    p_m = sub.add_parser("map")

    args = ap.parse_args(argv)

    if args.cmd == "classify":
        print(json.dumps(classify(args.expense, args.amount, args.mileage_log),
                         ensure_ascii=False, indent=2))
    else:
        print(json.dumps({"catalog": map_all(), "points_reference": [dict(point=p, desc=d) for p, d in POINTS]},
                         ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
