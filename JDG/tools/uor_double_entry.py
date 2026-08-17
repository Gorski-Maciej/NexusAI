#!/usr/bin/env python3
"""
NexusAI JDG — UoR DOUBLE ENTRY (GLM52 P10, Enterprise)
======================================================
Silnik podwójnego zapisu (art. 15 ust. 1 UoR) — każda operacja gospodarcza
debetuje i kredytuje konta, invariant: Σ debetów = Σ kredytów (zasada
podwójnego zapisu, memoriał, współmierność — art. 4 ust. 1 UoR).

  • make_entry(...)      — zapis (2 strony: debet/kredyt) z dowodem księgowym,
  • balance(entries)     — invariant ΣD = ΣC (BLOCK przy naruszeniu),
  • trial_balance(...)   — zestawienie obrotów i sald,
  • ledger_entry(...)    — zapis w dzienniku (art. 14) + księdze głównej (art. 15).

Usage:
  python3 tools/uor_double_entry.py                  # self-test
  python3 tools/uor_double_entry.py --debit 100 --credit 100
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Any


def round2(x: float) -> float:
    return round(x * 100) / 100


@dataclass
class Entry:
    date: str
    description: str
    debit_account: str
    credit_account: str
    amount: float
    document: str = ""
    debit_amount: float = field(default=0.0)
    credit_amount: float = field(default=0.0)

    def __post_init__(self):
        if self.debit_amount == 0.0 and self.credit_amount == 0.0:
            self.debit_amount = round2(self.amount)
            self.credit_amount = round2(self.amount)


def make_entry(date: str, description: str, debit_account: str,
               credit_account: str, amount: float, document: str = "") -> dict[str, Any]:
    amount = round2(amount)
    return {
        "date": date,
        "description": description,
        "debit": {"account": debit_account, "amount": amount},
        "credit": {"account": credit_account, "amount": amount},
        "document": document or f"PK/{date}",
        "balanced": True,
        "legal": "Art. 15 ust. 1 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    }


def balance(entries: list[dict[str, Any]]) -> dict[str, Any]:
    """Invariant podwójnego zapisu: Σ debety = Σ kredyty."""
    debits = round2(sum(e["debit"]["amount"] for e in entries))
    credits = round2(sum(e["credit"]["amount"] for e in entries))
    balanced = abs(debits - credits) < 0.005
    return {
        "debits_sum_pln": debits,
        "credits_sum_pln": credits,
        "balanced": balanced,
        "verdict": "BLOCK_AND_ALERT" if not balanced else "OK",
        "invariant": "Σ debety = Σ kredyty (art. 15 ust. 1 UoR)",
    }


def trial_balance(entries: list[dict[str, Any]]) -> dict[str, Any]:
    """Zestawienie obrotów i sald (per konto)."""
    accounts: dict[str, dict[str, float]] = {}
    for e in entries:
        d, c = e["debit"], e["credit"]
        accounts.setdefault(d["account"], {"debit": 0.0, "credit": 0.0})
        accounts.setdefault(c["account"], {"debit": 0.0, "credit": 0.0})
        accounts[d["account"]]["debit"] = round2(accounts[d["account"]]["debit"] + d["amount"])
        accounts[c["account"]]["credit"] = round2(accounts[c["account"]]["credit"] + c["amount"])
    rows = [
        {"account": acc, "debit_pln": v["debit"], "credit_pln": v["credit"],
         "balance_pln": round2(v["debit"] - v["credit"])}
        for acc, v in sorted(accounts.items())
    ]
    return {"accounts": rows, "total_debit": round2(sum(r["debit_pln"] for r in rows)),
            "total_credit": round2(sum(r["credit_pln"] for r in rows))}


def ledger_entry(e: dict[str, Any]) -> dict[str, Any]:
    """Zapis w dzienniku (art. 14) i księdze głównej (art. 15)."""
    return {
        "journal": {"date": e["date"], "entry": e["description"], "document": e["document"]},
        "ledger": {"debit": e["debit"], "credit": e["credit"]},
        "chronological": True,
        "legal": "Art. 14-15 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    e1 = make_entry("2026-03-15", "Zakup towaru (gotówka)", "30-0 Towary", "10-0 Kasa", 1000.0)
    e2 = make_entry("2026-03-15", "Sprzedaż usługi (przelew)", "13-0 Rachunek bankowy", "70-0 Przychody", 1230.0)
    b = balance([e1, e2])
    if not b["balanced"] or b["debits_sum_pln"] != 2230.0:
        failures.append(f"balance: oczekiwano 2230.0 zbalansowane, jest {b}")
    # naruszenie invariantu — zapis jednostronny
    bad = {"date": "2026-03-15", "description": "zapis jednostronny",
           "debit": {"account": "10-0 Kasa", "amount": 100.0},
           "credit": {"account": "70-0 Przychody", "amount": 90.0},
           "document": "PK/BAD", "balanced": False}
    b2 = balance([bad])
    if b2["balanced"] or b2["verdict"] != "BLOCK_AND_ALERT":
        failures.append("balance: jednostronny zapis powinien BLOCK")
    tb = trial_balance([e1, e2])
    if tb["total_debit"] != tb["total_credit"]:
        failures.append("trial balance: obroty nierówne")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--debit", type=float)
    ap.add_argument("--credit", type=float)
    args = ap.parse_args(argv)
    if args.debit is not None and args.credit is not None:
        print(json.dumps({
            "debits_sum_pln": args.debit, "credits_sum_pln": args.credit,
            "balanced": abs(args.debit - args.credit) < 0.005,
        }, ensure_ascii=False, indent=2))
        return 0
    failures = self_test()
    if failures:
        print("UoR DOUBLE ENTRY: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("UoR DOUBLE ENTRY: ✅ PASS — invariant ΣD = ΣC, trial balance OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
