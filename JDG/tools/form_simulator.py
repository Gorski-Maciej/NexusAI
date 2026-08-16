#!/usr/bin/env python3
"""
NexusAI JDG — FORM SIMULATOR (PROMPT 05 — PIT MAKRO, Sekcja 1)
===============================================================
Symulator „co by było gdyby” — 4-ścieżkowa analiza form opodatkowania
(skala 12/32, liniowy 19, ryczałt 8.5/12.5/17, karta) na danych
historycznych z prognozą. Rekomendacja + ryzyko. Zgodność: art. 9a PIT
(wybór/zmiana formy), art. 27/30c PIT, ustawa o ryczałcie.

  • simulate  — pełna 4-ścieżkowa symulacja + rekomendacja
  • compare   — skala vs liniowy (break-even)
  • risk      — ryzyka zmiany formy (art. 9a: terminy, ograniczenia)

Usage:
  python form_simulator.py simulate --revenue 250000 --kup 80000 --zus_social 24000
  python form_simulator.py compare --revenue 250000 --kup 80000
"""

import argparse
import json
import sys

SCALE_LOW = 0.12
SCALE_HIGH = 0.32
SCALE_THRESHOLD = 120000
TAX_FREE = 30000
LINEAR_RATE = 0.19
LUMP_RATES = {"trade": 0.085, "services": 0.125, "it": 0.125, "transport": 0.17}
CARD_MONTHLY_MAX = 3000  # karta podatkowa — limit orientacyjny miesięcznie


def _num(v, default=0.0):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return default


def _scale_tax(income):
    if income <= SCALE_THRESHOLD:
        return round(income * SCALE_LOW, 2)
    return round(SCALE_THRESHOLD * SCALE_LOW + (income - SCALE_THRESHOLD) * SCALE_HIGH, 2)


def simulate(revenue: float, kup: float, zus_social: float, zus_health: float = 0.0,
             lump_category: str = "services") -> dict:
    """4-ścieżkowa symulacja: skala / liniowy / ryczałt / karta."""
    income = max(0.0, _num(revenue) - _num(kup) - _num(zus_social))

    # Skala
    scale = _scale_tax(income)

    # Liniowy
    linear = round(income * LINEAR_RATE, 2)

    # Ryczałt
    lump_rate = LUMP_RATES.get(lump_category, 0.125)
    lump_revenue = max(0.0, _num(revenue) - _num(kup))
    lump = round(lump_revenue * lump_rate, 2)

    # Karta (orientacyjnie: limit dla usług)
    card = min(round(_num(revenue) * 0.20, 2), CARD_MONTHLY_MAX * 12)

    paths = {
        "PIT_SCALE (12/32%)": scale,
        "LINEAR (19%)": linear,
        "LUMP_SUM (ryczałt)": lump,
        "CARD (karta)": card,
    }
    best = min(paths, key=paths.get)
    return {
        "income": income,
        "paths": paths,
        "recommendation": best,
        "savings_vs_scale": round(max(paths.values()) - min(paths.values()), 2),
    }


def compare(revenue: float, kup: float, zus_social: float) -> dict:
    """Skala vs liniowy — break-even i delta."""
    income = max(0.0, _num(revenue) - _num(kup) - _num(zus_social))
    scale = _scale_tax(income)
    linear = round(income * LINEAR_RATE, 2)
    return {
        "income": income,
        "scale": scale,
        "linear": linear,
        "delta_linear_vs_scale": round(linear - scale, 2),
        "break_even_income": round(SCALE_THRESHOLD, 2),
    }


def risk(revenue: float, current_form: str) -> dict:
    """Ryzyka zmiany formy (art. 9a PIT)."""
    risks = []
    if current_form == "LINEAR" and revenue > 0:
        risks.append("Liniowy: BRAK kwoty wolnej, BRAK wspólnego rozliczenia (art. 30c ust. 2)")
    if current_form == "LUMP_SUM" and revenue > 2000000:
        risks.append("Ryczałt: przekroczenie limitu 2 mln EUR przychodu")
    if current_form == "PIT_SCALE":
        risks.append("Skala: składka zdrowotna NIE jest KUP (od 2022)")
    return {
        "current_form": current_form,
        "change_deadline": "do 20. dnia miesiąca następującego po miesiącu rozpoczęcia działalności (art. 9a ust. 2)",
        "risks": risks,
        "recommendation": "Symulacja 4-ścieżkowa przed zmianą formy (form_simulator.simulate)",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Form Simulator")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_s = sub.add_parser("simulate")
    p_s.add_argument("--revenue", type=float, required=True)
    p_s.add_argument("--kup", type=float, default=0.0)
    p_s.add_argument("--zus_social", type=float, default=0.0)
    p_s.add_argument("--zus_health", type=float, default=0.0)
    p_s.add_argument("--lump_category", default="services")

    p_c = sub.add_parser("compare")
    p_c.add_argument("--revenue", type=float, required=True)
    p_c.add_argument("--kup", type=float, default=0.0)
    p_c.add_argument("--zus_social", type=float, default=0.0)

    p_r = sub.add_parser("risk")
    p_r.add_argument("--revenue", type=float, required=True)
    p_r.add_argument("--current_form", required=True)

    args = ap.parse_args(argv)

    if args.cmd == "simulate":
        print(json.dumps(simulate(args.revenue, args.kup, args.zus_social, args.zus_health,
                                  args.lump_category), ensure_ascii=False, indent=2))
    elif args.cmd == "compare":
        print(json.dumps(compare(args.revenue, args.kup, args.zus_social), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(risk(args.revenue, args.current_form), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
