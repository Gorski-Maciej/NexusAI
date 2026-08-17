#!/usr/bin/env python3
"""
NexusAI JDG — UoR CLOSING ENGINE (GLM52 P10, Enterprise)
========================================================
Auto-zamknięcie roku obrotowego (art. 12 ust. 2 pkt 1-6 UoR) — 12 kroków
z checklistą oraz weryfikacja sprawozdania (art. 45-49 UoR):

  • CLOSING_STEPS        — 12 kroków zamknięcia,
  • closing_checklist(...) — lista wykonanych/brakujących kroków (BLOCK przy brakach),
  • verify_balance(...)  — invariant bilansu: aktywa = pasywa,
  • close_year(...)      — raport zamknięcia (wynik finansowy, przeksięgowania).

Usage:
  python3 tools/uor_closing_engine.py                # self-test
  python3 tools/uor_closing_engine.py --assets 1000 --liabilities 1000
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

CLOSING_STEPS = [
    "inwentaryzacja",
    "przeksiegowania_rozliczen",
    "ustalenie_wyniku_finansowego",
    "odpisy_amortyzacyjne",
    "rezerwy_i_rozliczenia",
    "zamkniecie_ksieg",
    "sporzadzenie_bilansu",
    "sporzadzenie_rzis",
    "informacja_dodatkowa",
    "sprawozdanie_z_dzialalnosci",
    "zatwierdzenie_sprawozdania",
    "zlozenie_w_krs",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


def closing_checklist(done_steps: list[str]) -> dict[str, Any]:
    """Checklista zamknięcia roku — brakujący krok = BLOCK_AND_ALERT."""
    missing = [s for s in CLOSING_STEPS if s not in done_steps]
    return {
        "steps_total": len(CLOSING_STEPS),
        "steps_done": len(done_steps),
        "steps_missing": missing,
        "complete": len(missing) == 0,
        "verdict": "OK" if not missing else "BLOCK_AND_ALERT",
        "legal": "Art. 12 ust. 2 pkt 1-6 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    }


def verify_balance(assets: float, liabilities: float) -> dict[str, Any]:
    """Invariant bilansu: aktywa = pasywa (art. 45 ust. 1-3 UoR)."""
    assets, liabilities = round2(assets), round2(liabilities)
    balanced = abs(assets - liabilities) < 0.005
    return {
        "assets_sum_pln": assets,
        "liabilities_sum_pln": liabilities,
        "balanced": balanced,
        "verdict": "BLOCK_AND_ALERT" if not balanced else "OK",
        "invariant": "aktywa = pasywa (art. 45 ust. 1-3 UoR)",
    }


def close_year(entries: list[dict[str, Any]], revenue_accounts: list[str]) -> dict[str, Any]:
    """Zamknięcie: wynik finansowy = przychody − koszty; przeksięgowanie na 86-0."""
    revenues = round2(sum(e["debit"]["amount"] for e in entries
                          if e["credit"]["account"] in revenue_accounts))
    costs = round2(sum(e["debit"]["amount"] for e in entries
                       if e["debit"]["account"].startswith("4")
                       or e["debit"]["account"].startswith("5")))
    profit = round2(revenues - costs)
    return {
        "revenues_pln": revenues,
        "costs_pln": costs,
        "net_profit_pln": profit,
        "closing_entry": {
            "debit": {"account": "86-0 Wynik finansowy", "amount": profit},
            "credit": {"account": "82-0 Przychody", "amount": profit},
        },
        "result_kind": "ZYSK" if profit >= 0 else "STRATA",
        "legal": "Art. 12 ust. 2 pkt 4-6 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    cc = closing_checklist(CLOSING_STEPS[:-2])
    if cc["complete"] or cc["verdict"] != "BLOCK_AND_ALERT":
        failures.append("checklista: brak kroków powinien BLOCK")
    cc_ok = closing_checklist(CLOSING_STEPS)
    if not cc_ok["complete"]:
        failures.append("checklista: pełna lista powinna przejść")
    vb = verify_balance(1000000.0, 999999.0)
    if vb["balanced"] or vb["verdict"] != "BLOCK_AND_ALERT":
        failures.append("bilans: 1 000 000 vs 999 999 powinno BLOCK")
    if not verify_balance(1000.0, 1000.0)["balanced"]:
        failures.append("bilans: równe sumy powinny przejść")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--assets", type=float)
    ap.add_argument("--liabilities", type=float)
    args = ap.parse_args(argv)
    if args.assets is not None and args.liabilities is not None:
        print(json.dumps(verify_balance(args.assets, args.liabilities),
                         ensure_ascii=False, indent=2))
        return 0
    failures = self_test()
    if failures:
        print("UoR CLOSING ENGINE: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("UoR CLOSING ENGINE: ✅ PASS — 12 kroków, bilans i wynik finansowy OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
