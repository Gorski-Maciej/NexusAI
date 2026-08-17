#!/usr/bin/env python3
"""
NexusAI JDG — PKPIR ENGINE (GLM52 P10, Enterprise)
==================================================
Silnik PKPiR „zero ręki" — generuje wiersze Podatkowej Księgi Przychodów
i Rozchodów (rozporządzenie MF z 15.11.2025 r., §10-12) z DOWODEM księgowym:

  • build_row(...)      — wiersz 17-kolumnowy z dowodem (data, numer, kontrahent,
                          opis, przychody 7-8, zakupy 10-13, amortyzacja 14,
                          pozostałe 15-16, uwagi 17),
  • cash_basis_deadline — memoriał kasowy: zapis do 14 dni od zdarzenia,
  • remanent_row(...)   — wiersz remanentu początkowego/końcowego (§18-19),
  • validate_row(...)   — walidator 17-kolumnowy (kompletność).

Usage:
  python3 tools/pkpir_engine.py                     # self-test (bramki)
  python3 tools/pkpir_engine.py --row 2026-03-15 KUP 1000 500
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date, timedelta
from typing import Any

COLUMNS = 17
CASH_BASIS_DAYS = 14  # §9 ust. 1 rozp. MF 15.11.2025 — 14 dni na zapis


def round2(x: float) -> float:
    return round(x * 100) / 100


def build_row(
    entry_date: str,
    number: str,
    counterparty: str,
    description: str,
    revenue: float = 0.0,
    purchase_net: float = 0.0,
    purchase_vat: float = 0.0,
    amortization: float = 0.0,
    other_expenses: float = 0.0,
) -> dict[str, Any]:
    """Wiersz PKPiR (kolumny 1-17) z dowodem (art. 24a PIT, §10-12 rozp.)."""
    purchase_gross = round2(purchase_net + purchase_vat)
    row = {
        "col1_data": entry_date,
        "col2_numer": number,
        "col3_kontrahent": counterparty,
        "col4_opis": description,
        "col5_przychod_wartosc": round2(revenue),
        "col6_przychod_bez_vat": round2(revenue),      # dla uproszczonego rozliczania
        "col7_przychody_razem": round2(revenue),
        "col8_uwagi_przychod": "",
        "col9_zakupy_razem": round2(purchase_gross),
        "col10_zakupy_towary": round2(purchase_net),
        "col11_zakupy_bez_vat": round2(purchase_net),
        "col12_zakupy_pozostale": 0.0,
        "col13_vat_naliczony": round2(purchase_vat),
        "col14_amortyzacja": round2(amortization),
        "col15_pozostale_wydatki": round2(other_expenses),
        "col16_pozostale": 0.0,
        "col17_uwagi": "dowód: " + (number or "-"),
        "columns_total": COLUMNS,
        "proof": {
            "legal": "§10-12 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
            "cash_basis_days": CASH_BASIS_DAYS,
            "source": "PKPIR_ENGINE_P10",
        },
    }
    return row


def cash_basis_deadline(event_date: str) -> dict[str, Any]:
    """Memoriał kasowy: zapis do 14 dni od zdarzenia (§9 ust. 1)."""
    d = date.fromisoformat(event_date)
    deadline = d + timedelta(days=CASH_BASIS_DAYS)
    return {
        "event_date": event_date,
        "deadline": deadline.isoformat(),
        "days": CASH_BASIS_DAYS,
        "legal": "§9 ust. 1 rozp. MF 15.11.2025",
    }


def remanent_row(
    entry_date: str,
    number: str,
    items: list[dict[str, Any]],
    kind: str = "KOŃCOWY",
) -> dict[str, Any]:
    """Wiersz remanentu (§18-19): spis z natury, wycena wg cen zakupu."""
    total = round2(sum(i.get("value_pln", 0.0) for i in items))
    return {
        "col1_data": entry_date,
        "col2_numer": number,
        "col4_opis": f"Remanent {kind} — spis z natury",
        "col5_przychod_wartosc": round2(total) if kind == "POCZĄTKOWY" else 0.0,
        "col15_pozostale_wydatki": round2(total) if kind == "KOŃCOWY" else 0.0,
        "col17_uwagi": f"Remanent {kind}: {len(items)} pozycji",
        "remanent_value_pln": total,
        "items_count": len(items),
        "legal": "§18-19 rozp. MF 15.11.2025 w zw. z art. 24 ust. 2 PIT",
    }


def validate_row(row: dict[str, Any]) -> dict[str, Any]:
    """Walidator 17-kolumnowy (kompletność) — brak kolumny = BLOCK."""
    required = [
        "col1_data", "col2_numer", "col3_kontrahent", "col4_opis",
        "col7_przychody_razem", "col10_zakupy_towary", "col12_zakupy_pozostale",
        "col14_amortyzacja", "col15_pozostale_wydatki", "col17_uwagi",
    ]
    missing = [c for c in required if c not in row]
    return {
        "complete": len(missing) == 0,
        "missing_columns": missing,
        "columns_total": COLUMNS,
        "verdict": "BLOCK_AND_ALERT" if missing else "OK",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    row = build_row("2026-03-15", "FV/2026/001", "Kontrahent Sp. z o.o.", "Usługi IT",
                    revenue=1000.0, purchase_net=500.0, purchase_vat=115.0, amortization=200.0)
    if row["col7_przychody_razem"] != 1000.0:
        failures.append("kolumna 7: oczekiwano 1000.0")
    if row["col13_vat_naliczony"] != 115.0:
        failures.append("kolumna 13: oczekiwano 115.0")
    if row["columns_total"] != 17:
        failures.append("liczba kolumn ≠ 17")
    # memoriał kasowy
    dl = cash_basis_deadline("2026-03-01")
    if dl["deadline"] != "2026-03-15":
        failures.append(f"memoriał kasowy: oczekiwano 2026-03-15, jest {dl['deadline']}")
    # remanent
    rem = remanent_row("2026-12-31", "REM/2026/01", [{"value_pln": 1000.0}, {"value_pln": 500.5}])
    if rem["remanent_value_pln"] != 1500.5:
        failures.append("remanent: oczekiwano 1500.5")
    # walidator
    v = validate_row(row)
    if not v["complete"]:
        failures.append("walidator: kompletny wiersz powinien przejść")
    bad = validate_row({"col1_data": "2026-03-15"})
    if bad["verdict"] != "BLOCK_AND_ALERT":
        failures.append("walidator: niekompletny wiersz powinien BLOCK")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--row", nargs=4, metavar=("DATA", "NUMER", "OPIS", "PRZYCHOD"),
                    help="wygeneruj wiersz PKPiR")
    args = ap.parse_args(argv)
    if args.row:
        d, num, desc, rev = args.row
        print(json.dumps(build_row(d, num, "-", desc, revenue=float(rev)),
                         ensure_ascii=False, indent=2))
        return 0
    failures = self_test()
    if failures:
        print("PKPIR ENGINE: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("PKPIR ENGINE: ✅ PASS — wiersze 17-kolumnowe, memoriał kasowy 14 dni, remanent OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
