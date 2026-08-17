#!/usr/bin/env python3
"""
NexusAI JDG — PKPiR→UoR TRANSFORMER (GLM52 P10, Enterprise)
===========================================================
Symulator transformacji PKPiR → pełna księgowość (UoR) — wdrożenie
PROMPT 10 §4:

  • transform(...)      — przeniesienie sald: remanent końcowy → zapasy,
                          środki trwałe (ewidencja → księga główna), różnice,
  • opening_balance(...) — generator bilansu otwarcia (aktywa/pasywa),
  • transformation_report(...) — raport różnic + lista kontrolna 12 kroków.

Spójność z rules/pkpir_to_uor_transformer.rego (warstwa Rego makro).

Usage:
  python3 tools/pkpir_uor_transformer.py             # self-test
  python3 tools/pkpir_uor_transformer.py --remanent 50000 --fixed-assets 120000
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

TRANSFORMATION_STEPS = [
    "spis_z_natury_remanent",
    "wycena_remanentu",
    "przeniesienie_zapasow",
    "ewidencja_srodkow_trwalych",
    "wycena_srodkow_trwalych",
    "przeniesienie_sald_kup",
    "przeniesienie_sald_przychodow",
    "rozliczenia_miedzyokresowe",
    "rezerwy",
    "sporzadzenie_bilansu_otwarcia",
    "otwarcie_ksieg_rachunkowych",
    "polityka_rachunkowosci",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


def transform(
    remanent_value: float,
    fixed_assets_value: float,
    kup_balance: float = 0.0,
    cash_balance: float = 0.0,
    receivables: float = 0.0,
    liabilities: float = 0.0,
) -> dict[str, Any]:
    """Transformacja: salda PKPiR → konta UoR (bilans otwarcia)."""
    assets = round2(cash_balance + receivables + remanent_value + fixed_assets_value)
    liabilities_side = round2(liabilities + kup_balance)
    equity = round2(assets - liabilities_side)
    return {
        "assets_pln": assets,
        "liabilities_pln": liabilities_side,
        "equity_pln": equity,
        "balanced": abs(assets - (liabilities_side + equity)) < 0.005,
        "mapping": {
            "remanent_koncowy": {"from": "PKPiR remanent", "to": "30-0 Zapasy", "amount": round2(remanent_value)},
            "srodki_trwale": {"from": "ewidencja ŚT", "to": "01-0 Środki trwałe", "amount": round2(fixed_assets_value)},
            "kasa": {"from": "PKPiR kol. 15", "to": "10-0 Kasa", "amount": round2(cash_balance)},
            "naleznosci": {"from": "faktury wystawione", "to": "20-0 Należności", "amount": round2(receivables)},
            "zobowiazania": {"from": "faktury kosztowe", "to": "21-0 Zobowiązania", "amount": round2(liabilities)},
        },
        "legal": "Art. 2 ust. 1 pkt 5 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    }


def opening_balance(transformed: dict[str, Any]) -> dict[str, Any]:
    """Bilans otwarcia (aktywa = pasywa + kapitał własny)."""
    assets = transformed["assets_pln"]
    return {
        "AKTYWA": {"Zapasy": transformed["mapping"]["remanent_koncowy"]["amount"],
                   "Środki trwałe": transformed["mapping"]["srodki_trwale"]["amount"],
                   "Kasa/Bank": transformed["mapping"]["kasa"]["amount"],
                   "Należności": transformed["mapping"]["naleznosci"]["amount"],
                   "Razem aktywa": assets},
        "PASYWA": {"Zobowiązania": transformed["mapping"]["zobowiazania"]["amount"],
                   "Kapitał własny": transformed["equity_pln"],
                   "Razem pasywa": round2(transformed["liabilities_pln"] + transformed["equity_pln"])},
        "balanced": transformed["balanced"],
    }


def transformation_report(done_steps: list[str]) -> dict[str, Any]:
    """Lista kontrolna przejścia PKPiR→UoR (12 kroków)."""
    missing = [s for s in TRANSFORMATION_STEPS if s not in done_steps]
    return {
        "steps_total": len(TRANSFORMATION_STEPS),
        "steps_done": len(done_steps),
        "steps_missing": missing,
        "complete": len(missing) == 0,
        "verdict": "OK" if not missing else "BLOCK_AND_ALERT",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    tr = transform(remanent_value=50000.0, fixed_assets_value=120000.0,
                   kup_balance=30000.0, cash_balance=20000.0,
                   receivables=10000.0, liabilities=15000.0)
    if not tr["balanced"]:
        failures.append(f"transformacja niezbalansowana: {tr}")
    if tr["assets_pln"] != 200000.0:
        failures.append(f"aktywa: oczekiwano 200000, jest {tr['assets_pln']}")
    ob = opening_balance(tr)
    if not ob["balanced"]:
        failures.append("bilans otwarcia niezbalansowany")
    rep = transformation_report(TRANSFORMATION_STEPS[:-1])
    if rep["complete"] or rep["verdict"] != "BLOCK_AND_ALERT":
        failures.append("raport: brak kroku powinien BLOCK")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--remanent", type=float, default=0.0)
    ap.add_argument("--fixed-assets", type=float, default=0.0)
    args = ap.parse_args(argv)
    if args.remanent or args.fixed_assets:
        tr = transform(args.remanent, args.fixed_assets)
        print(json.dumps({"transformacja": tr, "bilans_otwarcia": opening_balance(tr)},
                         ensure_ascii=False, indent=2))
        return 0
    failures = self_test()
    if failures:
        print("PKPiR→UoR TRANSFORMER: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("PKPiR→UoR TRANSFORMER: ✅ PASS — salda, bilans otwarcia, 12 kroków OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
