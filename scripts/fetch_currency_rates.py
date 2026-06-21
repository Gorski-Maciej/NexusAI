#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "httpx>=0.27.0",
#   "msgspec>=0.18.0",
# ]
# ///
"""
Pobierz aktualne kursy walut z NBP API.

Single-file script zgodny z PEP 723 — samowystarczalny, nie wymaga
instalacji zależności. Uruchom przez:

    pixi run rates
    # lub:
    pixi exec -- python scripts/fetch_currency_rates.py
    # lub bezpośrednio (w środowisku pixi):
    python scripts/fetch_currency_rates.py

Przykłady:
    pixi run rates                                        # Wszystkie kursy
    pixi run rates -- EUR USD GBP                       # Wybrane waluty
    pixi run rates-json                                 # Format JSON
"""

from __future__ import annotations

import sys
from typing import Any

import httpx
from msgspec import Struct, json as msgspec_json


class Rate(Struct, frozen=True):
    """Pojedyncza waluta z tabeli NBP."""

    currency: str
    code: str
    mid: float | None = None
    bid: float | None = None
    ask: float | None = None


class NBPTable(Struct, frozen=True):
    """Tabela kursów NBP."""

    table: str
    no: str
    effectiveDate: str
    rates: list[Rate]


def fetch_rates(table_type: str = "A") -> list[NBPTable]:
    """Pobierz tabelę kursów NBP."""
    with httpx.Client() as client:
        resp = client.get(
            f"https://api.nbp.pl/api/exchangerates/tables/{table_type}",
            params={"format": "json"},
        )
        resp.raise_for_status()
        return msgspec_json.decode(resp.content, type=list[NBPTable])


def main() -> None:
    tables = fetch_rates("A")

    if not tables:
        print("❌ Nie udało się pobrać kursów NBP")
        sys.exit(1)

    table = tables[0]
    selected = sys.argv[1:]

    if "--json" in selected:
        selected.remove("--json")
        print(msgspec_json.encode(table.rates).decode())
        return

    print(f"\n📊 Tabela {table.table} nr {table.no} z dnia {table.effectiveDate}")
    print("=" * 50)

    for rate in table.rates:
        if selected and rate.code.upper() not in {c.upper() for c in selected}:
            continue
        if rate.mid is not None:
            print(f"  {rate.currency:25s} ({rate.code})  →  {rate.mid:.4f} PLN")
        elif rate.bid is not None and rate.ask is not None:
            print(
                f"  {rate.currency:25s} ({rate.code})  "
                f"→  kupno: {rate.bid:.4f}  sprzedaż: {rate.ask:.4f} PLN"
            )

    print()


if __name__ == "__main__":
    main()
