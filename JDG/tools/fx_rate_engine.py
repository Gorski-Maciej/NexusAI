#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — FX RATE ENGINE (GLM52 P12)
# Różnice kursowe (art. 14 ust. 2c PIT — metoda podatkowa): kurs NBP (tabela A)
# z dnia zdarzenia (time-travel) → różnica = kwota × (kurs wydatku − kurs
# przychodu)/kurs przychodu. Fallback: kurs referencyjny, alert 503 (data service).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
from datetime import date
from typing import Any

# Kursy NBP (tabela A) — dane przykładowe dla testów (time-travel)
NBP_RATES: dict[str, dict[str, float]] = {
    "2026-01-05": {"EUR": 4.29, "USD": 4.15, "GBP": 5.10, "CHF": 4.55},
    "2026-01-06": {"EUR": 4.31, "USD": 4.18, "GBP": 5.12, "CHF": 4.58},
    "2026-02-02": {"EUR": 4.35, "USD": 4.22, "GBP": 5.18, "CHF": 4.62},
    "2026-02-03": {"EUR": 4.37, "USD": 4.25, "GBP": 5.20, "CHF": 4.65},
    "2026-03-02": {"EUR": 4.40, "USD": 4.30, "GBP": 5.25, "CHF": 4.70},
}


def round2(x: float) -> float:
    return round(x * 100) / 100


def get_rate(currency: str, rate_date: str, fallback_rate: float = 4.50) -> dict[str, Any]:
    """Kurs NBP z dnia (time-travel); fallback z alertem (spójność PROMPT 01)."""
    day = NBP_RATES.get(rate_date)
    if day and currency in day:
        return {"rate": day[currency], "source": "NBP tabela A", "date": rate_date,
                "fallback": False, "alert": ""}
    # fallback 503 — data service niedostępny
    return {"rate": fallback_rate, "source": "FALLBACK", "date": rate_date,
            "fallback": True, "alert": "DATA_SERVICE_503: brak kursu NBP z dnia — użyto referencyjnego"}


def fx_difference(
    amount_pln: float,
    currency: str,
    income_date: str,
    expense_date: str,
) -> dict[str, Any]:
    """Różnica kursowa (art. 14 ust. 2c PIT): kurs NBP z dnia wpływu/wydatku."""
    r_income = get_rate(currency, income_date)
    r_expense = get_rate(currency, expense_date)
    rate_income = r_income["rate"]
    rate_expense = r_expense["rate"]
    diff = round2(amount_pln * (rate_expense - rate_income) / rate_income)
    return {
        "amount_pln": round2(amount_pln),
        "currency": currency,
        "rate_income": rate_income,
        "rate_expense": rate_expense,
        "income_rate_src": r_income["source"],
        "expense_rate_src": r_expense["source"],
        "difference_pln": diff,
        "alerts": [r_income["alert"], r_expense["alert"]],
        "legal": "Art. 14 ust. 2c ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def currency_conversion(amount: float, currency: str, rate_date: str) -> dict[str, Any]:
    """Przeliczenie waluty wg kursu NBP z dnia (WNT/WDT, art. 31a ust. 1 VAT)."""
    r = get_rate(currency, rate_date)
    return {
        "amount": round2(amount),
        "currency": currency,
        "rate": r["rate"],
        "amount_pln": round2(amount * r["rate"]),
        "source": r["source"],
        "alert": r["alert"],
        "legal": "Art. 31a ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    fx = fx_difference(10000, "EUR", "2026-01-05", "2026-02-03")
    # (4.37 - 4.29)/4.29 * 10000 ≈ 186.48
    expected = round2(10000 * (4.37 - 4.29) / 4.29)
    if fx["difference_pln"] != expected:
        failures.append(f"FX: oczekiwano {expected}, jest {fx['difference_pln']}")
    conv = currency_conversion(1000, "EUR", "2026-03-02")
    if conv["amount_pln"] != 4400:
        failures.append("przeliczenie 1000 EUR × 4.40 = 4400")
    fb = get_rate("JPY", "2026-03-02")
    if not fb["fallback"]:
        failures.append("JPY brak w tabeli → fallback 503")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="FX Rate Engine (GLM52 P12)")
    ap.add_argument("--amount", type=float, default=10000.0)
    ap.add_argument("--currency", default="EUR")
    ap.add_argument("--income-date", default="2026-01-05")
    ap.add_argument("--expense-date", default="2026-02-03")
    ap.add_argument("--convert", action="store_true", help="przeliczenie waluty (WNT/WDT)")
    ap.add_argument("--rate-date", default="2026-03-02")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        failures = self_test()
        if failures:
            print("SELF-TEST: FAIL")
            for f in failures:
                print(f"  ❌ {f}")
            return 1
        print("SELF-TEST: PASS")
        return 0

    if args.convert:
        print(json.dumps(currency_conversion(args.amount, args.currency, args.rate_date),
                         ensure_ascii=False, indent=2))
    else:
        print(json.dumps(fx_difference(args.amount, args.currency, args.income_date, args.expense_date),
                         ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
