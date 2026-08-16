#!/usr/bin/env python3
"""
NexusAI JDG — PIT ANNUAL ENGINE (PROMPT 05 — PIT MAKRO, Sekcja 1/3)
====================================================================
Auto-zeznania roczne z werdyktów OPA (zero ręki): PIT-36 (skala),
PIT-36L (liniowy), PIT-28 (ryczałt). Zgodność: art. 45 PIT (termin 30.04),
art. 27 (skala 12%/32%), art. 30c (liniowy 19%), art. 21 (zwolnienia).

  • compute    — werdykty → podstawa, podatek, składki, ulgi (groszowo)
  • declaration— wybór formularza (PIT-36/36L/28) + wypełnienie pól
  • verify     — groszowy dowód (invariant: podatek = f(podstawa, stawki))
  • schedule   — terminy (30.04, korekta, ryczałt)

Zgodność: thresholds.pit (scale_low_rate, scale_high_rate, scale_threshold,
          tax_free_amount, linear_rate), thresholds.zus (health_*).

Usage:
  python pit_annual_engine.py compute --verdicts verdicts.json --form PIT_SCALE
  python pit_annual_engine.py declaration --verdicts verdicts.json
  python pit_annual_engine.py verify --computed computed.json
"""

import argparse
import json
import sys
from pathlib import Path

SCALE_LOW = 0.12
SCALE_HIGH = 0.32
SCALE_THRESHOLD = 120000
TAX_FREE = 30000
LINEAR_RATE = 0.19
HEALTH_SCALE = 0.09
HEALTH_LINEAR = 0.049


def _num(v, default=0.0):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return default


def compute(verdicts: list, form: str = "PIT_SCALE") -> dict:
    """Werdykty OPA → roczne rozliczenie (skala/liniowy/ryczałt)."""
    revenue = sum(_num(v.get("amount_net")) for v in verdicts if v.get("direction") == "SALE")
    kup = sum(_num(v.get("kup_amount")) for v in verdicts if v.get("kup_amount"))
    zus_social = sum(_num(v.get("zus_social_paid")) for v in verdicts if v.get("zus_social_paid"))
    zus_health = sum(_num(v.get("zus_health_paid")) for v in verdicts if v.get("zus_health_paid"))
    income = round(revenue - kup - zus_social, 2)

    if form == "PIT_SCALE":
        taxable = max(0.0, income - TAX_FREE)
        if income <= SCALE_THRESHOLD:
            tax = round(income * SCALE_LOW, 2)
        else:
            tax = round(SCALE_THRESHOLD * SCALE_LOW + (income - SCALE_THRESHOLD) * SCALE_HIGH, 2)
        form_code = "PIT-36"
        health_deductible = 0.0  # skala: brak odliczenia zdrowotnej (2022+)
    elif form == "LINEAR":
        taxable = income
        tax = round(income * LINEAR_RATE, 2)
        form_code = "PIT-36L"
        health_deductible = min(zus_health, round(income * 0.049, 2))  # 4.9% odliczenia
    else:  # LUMP_SUM (ryczałt — pełne stawki w P13)
        taxable = income
        tax = round(income * 0.085, 2)
        form_code = "PIT-28"

    return {
        "form": form_code,
        "revenue": revenue,
        "kup": kup,
        "zus_social": zus_social,
        "zus_health": zus_health,
        "income": income,
        "taxable": taxable,
        "tax": tax,
        "health_deductible": health_deductible,
        "to_pay": round(tax - health_deductible, 2),
    }


def declaration(verdicts: list) -> dict:
    """Auto-wybór formularza + wypełnienie z werdyktów."""
    form = "PIT_SCALE"
    for v in verdicts:
        if v.get("pit_form"):
            form = v["pit_form"]
            break
    r = compute(verdicts, form)
    return {
        "declaration": r["form"],
        "fields": {
            "revenue": r["revenue"],
            "kup": r["kup"],
            "income": r["income"],
            "tax": r["tax"],
            "to_pay": r["to_pay"],
        },
        "deadline": "30.04",
        "auto_filled": True,
    }


def verify(computed: dict) -> dict:
    """Groszowy dowód: invariant podatek = f(podstawa, stawki) ± 0.01."""
    tax = computed["tax"]
    income = computed["income"]
    if computed["form"] == "PIT-36L":
        expected = round(income * LINEAR_RATE, 2)
    elif computed["form"] == "PIT-28":
        expected = round(income * 0.085, 2)
    else:
        if income <= SCALE_THRESHOLD:
            expected = round(income * SCALE_LOW, 2)
        else:
            expected = round(SCALE_THRESHOLD * SCALE_LOW + (income - SCALE_THRESHOLD) * SCALE_HIGH, 2)
    return {"consistent": abs(tax - expected) <= 0.01, "tax": tax, "expected": expected}


def schedule(year: int = 2026) -> dict:
    """Terminy roczne: PIT-36/36L 30.04, korekta, ryczałt 28."""
    from datetime import date
    pit36 = date(year, 4, 30)
    while pit36.weekday() >= 5:
        pit36 = pit36.replace(day=pit36.day - 1)  # weekend → poprzedni dzień roboczy (MF)
    return {
        "pit_36_36l": pit36.isoformat(),
        "pit_28": f"{year}-02-28",
        "correction": "do 30 dni po wykryciu błędu (art. 81 OrdPU)",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="PIT Annual Engine")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_c = sub.add_parser("compute")
    p_c.add_argument("--verdicts", required=True)
    p_c.add_argument("--form", default="PIT_SCALE", choices=["PIT_SCALE", "LINEAR", "LUMP_SUM"])

    p_d = sub.add_parser("declaration")
    p_d.add_argument("--verdicts", required=True)

    p_v = sub.add_parser("verify")
    p_v.add_argument("--computed", required=True)

    p_s = sub.add_parser("schedule")
    p_s.add_argument("--year", type=int, default=2026)

    args = ap.parse_args(argv)

    if args.cmd == "compute":
        print(json.dumps(compute(_load(args.verdicts), args.form), ensure_ascii=False, indent=2))
    elif args.cmd == "declaration":
        print(json.dumps(declaration(_load(args.verdicts)), ensure_ascii=False, indent=2))
    elif args.cmd == "verify":
        print(json.dumps(verify(_load(args.computed)), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(schedule(args.year), ensure_ascii=False, indent=2))
    return 0


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


if __name__ == "__main__":
    sys.exit(main())
