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
# Stawki ryczałtu per kategoria (art. 12 ustawy o ryczałcie, spójne z
# jdg.pit.forms.lump_sum_rate_by_pkwiu / thresholds.rates.lump_*)
LUMP_RATES = {"trade": 0.02, "gastronomy": 0.03, "construction": 0.055,
              "services": 0.085, "it": 0.085, "it_high": 0.12,
              "management": 0.15, "transport": 0.17, "professional": 0.17}
CARD_MONTHLY_MAX = 3000  # karta podatkowa — limit orientacyjny miesięcznie

# Składka zdrowotna (2026): skala 9% dochodu, liniowy 4,9% dochodu,
# ryczałt — progi przychodu 60k/300k (art. 23 ust. 1 u.z.d.n.);
# kwoty miesięczne ryczałtu wg przeciętnego wynagrodzenia (2026)
HEALTH_SCALE_RATE = 0.09
HEALTH_LINEAR_RATE = 0.049
LUMP_HEALTH_TIER_1_LIMIT = 60000
LUMP_HEALTH_TIER_2_LIMIT = 300000
LUMP_HEALTH_TIER_1_MONTHLY = 491.40   # 60% × 9 100 × 9%
LUMP_HEALTH_TIER_2_MONTHLY = 819.00   # 100% × 9 100 × 9%
LUMP_HEALTH_TIER_3_MONTHLY = 1474.20  # 180% × 9 100 × 9%


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
    lump_rate = LUMP_RATES.get(lump_category, 0.085)
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


def health_impact(form: str, income: float, revenue: float = 0.0) -> dict:
    """Roczny koszt składki zdrowotnej per forma (2026) — wpływ na wybór formy.
    Skala: 9% dochodu (NIE jest KUP). Liniowy: 4,9% dochodu (odliczenie od
    dochodu do 14 100 zł). Ryczałt: ryczałtowe kwoty wg progu przychodu."""
    income = max(0.0, _num(income))
    revenue = max(0.0, _num(revenue))
    if form == "LINEAR":
        annual = round(income * HEALTH_LINEAR_RATE, 2)
        return {"form": "LINEAR", "rate": "4.9% dochodu", "annual": annual,
                "note": "Odliczenie od dochodu do 14 100 zł/rok (art. 30c ust. 2 pkt 2 PIT)"}
    if form in {"LUMP_SUM", "LUMP"}:
        if revenue <= LUMP_HEALTH_TIER_1_LIMIT:
            monthly, tier = LUMP_HEALTH_TIER_1_MONTHLY, "TIER_1 (≤ 60k przychodu)"
        elif revenue <= LUMP_HEALTH_TIER_2_LIMIT:
            monthly, tier = LUMP_HEALTH_TIER_2_MONTHLY, "TIER_2 (60k–300k przychodu)"
        else:
            monthly, tier = LUMP_HEALTH_TIER_3_MONTHLY, "TIER_3 (> 300k przychodu)"
        return {"form": "LUMP_SUM", "rate": "ryczałtowe progi", "tier": tier,
                "monthly": monthly, "annual": round(monthly * 12, 2)}
    annual = round(income * HEALTH_SCALE_RATE, 2)
    return {"form": "PIT_SCALE", "rate": "9% dochodu", "annual": annual,
            "note": "Skala: składka zdrowotna NIE jest KUP i NIE odlicza się (2022+)"}


def simulate_3y(revenue: float, kup: float, zus_social: float, zus_health: float = 0.0,
                growth: float = 0.05, lump_category: str = "services",
                years: int = 3) -> dict:
    """Prognoza 3-letnia „co by było gdyby” (INN-01, art. 9a): symulacja
    4-ścieżkowa per rok przy wzroście przychodu growth^rok + rekomendacja
    długoterminowa (suma podatków w horyzoncie)."""
    growth = float(growth)
    paths_total = {"PIT_SCALE (12/32%)": 0.0, "LINEAR (19%)": 0.0,
                   "LUMP_SUM (ryczałt)": 0.0, "CARD (karta)": 0.0}
    yearly = []
    for y in range(1, years + 1):
        r = simulate(_num(revenue) * (1 + growth) ** (y - 1), kup, zus_social,
                     zus_health, lump_category)
        yearly.append({"year": y, "revenue": round(_num(revenue) * (1 + growth) ** (y - 1), 2),
                       "paths": r["paths"]})
        for k in paths_total:
            paths_total[k] += r["paths"][k]
    best = min(paths_total, key=paths_total.get)
    return {
        "horizon_years": years,
        "growth": growth,
        "yearly": yearly,
        "total_by_form": {k: round(v, 2) for k, v in paths_total.items()},
        "recommendation_long_term": best,
        "savings_long_term_vs_scale": round(max(paths_total.values()) - min(paths_total.values()), 2),
        "note": "Zmiana formy tylko od 1 stycznia (art. 9a PIT) — prognoza z form_simulator.simulate_3y",
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

    p_3 = sub.add_parser("simulate-3y")
    p_3.add_argument("--revenue", type=float, required=True)
    p_3.add_argument("--kup", type=float, default=0.0)
    p_3.add_argument("--zus_social", type=float, default=0.0)
    p_3.add_argument("--zus_health", type=float, default=0.0)
    p_3.add_argument("--growth", type=float, default=0.05)
    p_3.add_argument("--lump_category", default="services")
    p_3.add_argument("--years", type=int, default=3)

    p_h = sub.add_parser("health")
    p_h.add_argument("--form", required=True)
    p_h.add_argument("--income", type=float, required=True)
    p_h.add_argument("--revenue", type=float, default=0.0)

    args = ap.parse_args(argv)

    if args.cmd == "simulate":
        print(json.dumps(simulate(args.revenue, args.kup, args.zus_social, args.zus_health,
                                  args.lump_category), ensure_ascii=False, indent=2))
    elif args.cmd == "compare":
        print(json.dumps(compare(args.revenue, args.kup, args.zus_social), ensure_ascii=False, indent=2))
    elif args.cmd == "simulate-3y":
        print(json.dumps(simulate_3y(args.revenue, args.kup, args.zus_social, args.zus_health,
                                     args.growth, args.lump_category, args.years),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "health":
        print(json.dumps(health_impact(args.form, args.income, args.revenue),
                         ensure_ascii=False, indent=2))
    else:
        print(json.dumps(risk(args.revenue, args.current_form), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
