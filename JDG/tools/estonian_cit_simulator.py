#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GLM52 — estonian_cit_simulator.py
# Symulator PIT vs estoński CIT dla JDG (art. 28c-28t ustawy o CIT):
# - warunki wyboru (mały podatnik, przychody ≤ 2 000 000 EUR, brak udziałowców
#   innych niż osoby fizyczne — art. 28j ust. 1 pkt 4-5 CIT),
# - prognoza 3-letnia (retencja zysku → korzyść odroczenia),
# - podatek od wypłat 10%/20% (art. 28t ust. 1-2 CIT),
# - tracker przejścia/rezygnacji (terminy).
# ═══════════════════════════════════════════════════════════════════════════════
"""Symulator formy opodatkowania: PIT (skala/liniowy) vs estoński CIT.

Estoński CIT dla JDG (sp. z o.o.):
  - opodatkowanie dopiero przy wypłacie (10% do 2M zł zysku, 20% nadwyżka)
  - 0% przy reinwestycji zysku
  - warunki: mały podatnik, przychody ≤ 2 000 000 EUR (art. 28j ust. 1 pkt 4),
    wyłącznie osoby fizyczne jako wspólnicy (pkt 5), sprawozdanie finansowe.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# limity estońskiego CIT (art. 28j ust. 1 pkt 4 CIT; art. 28t ust. 1-2 CIT)
REVENUE_LIMIT_EUR = 2_000_000.0
DISTRIBUTION_RATE_LOW = 0.10    # do 2 000 000 zł zysku rocznie
DISTRIBUTION_RATE_HIGH = 0.20   # nadwyżka ponad 2 000 000 zł


@dataclass
class YearForecast:
    year: int
    profit_before_tax: float
    pit_scale_tax: float
    pit_linear_tax: float
    estonian_retained: float      # 0% przy reinwestycji
    estonian_distributed: float   # przy pełnej wypłacie
    estonian_low_base: float
    estonian_high_base: float

    def to_dict(self) -> dict[str, Any]:
        return {
            "year": self.year,
            "profit_before_tax": round(self.profit_before_tax, 2),
            "pit_scale_tax": round(self.pit_scale_tax, 2),
            "pit_linear_tax": round(self.pit_linear_tax, 2),
            "estonian_retained_tax": round(self.estonian_retained, 2),
            "estonian_distributed_tax": round(self.estonian_distributed, 2),
            "savings_retained_vs_scale": round(self.pit_scale_tax - self.estonian_retained, 2),
        }


def pit_scale_tax(profit: float) -> float:
    """Skala PIT 2026: 12% do 120 000 zł, 32% nadwyżka (kwota zmniejszająca 3 600 zł pominięta dla porównania form)."""
    bracket = 120_000.0
    if profit <= bracket:
        return profit * 0.12
    return bracket * 0.12 + (profit - bracket) * 0.32


def pit_linear_tax(profit: float) -> float:
    return profit * 0.19


def estonian_tax(profit: float, distribute_pct: float) -> float:
    """Estoński CIT: 0% przy reinwestycji; przy wypłacie 10% do 2M zł, 20% nadwyżka."""
    if distribute_pct <= 0:
        return 0.0
    distributed = profit * distribute_pct
    low_base = min([distributed, 2_000_000.0])
    high_base = max([distributed - 2_000_000.0, 0.0])
    return low_base * DISTRIBUTION_RATE_LOW + high_base * DISTRIBUTION_RATE_HIGH


@dataclass
class SimulationResult:
    eligible: bool
    eligibility_notes: list[str]
    revenue_eur: float
    forecasts: list[YearForecast]
    verdict: str
    evidence: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "tool": "estonian_cit_simulator",
            "campaign": "P07_GLM52_ULGI_OPTYMALIZACJA",
            "eligible": self.eligible,
            "eligibility_notes": self.eligibility_notes,
            "revenue_eur": round(self.revenue_eur, 2),
            "revenue_limit_eur": REVENUE_LIMIT_EUR,
            "forecasts": [f.to_dict() for f in self.forecasts],
            "verdict": self.verdict,
            "evidence": self.evidence,
        }


def simulate(profits: list[float], revenue_eur: float, distribute_pct: float = 0.0,
             years: tuple[int, ...] | None = None) -> SimulationResult:
    """Symulacja 3-letnia: PIT (skala/liniowy) vs estoński CIT."""
    notes: list[str] = []
    eligible = revenue_eur <= REVENUE_LIMIT_EUR
    if not eligible:
        notes.append(f"PRZYKROCZONY LIMIT PRZYCHODÓW: {revenue_eur:,.0f} EUR > {REVENUE_LIMIT_EUR:,.0f} EUR "
                     f"(art. 28j ust. 1 pkt 4 CIT) — estoński CIT NIEDOSTĘPNY")
    notes.append("Wymagania: spółka z o.o., wspólnicy wyłącznie osoby fizyczne (art. 28j ust. 1 pkt 5), "
                 "sprawozdanie finansowe, mały podatnik")

    start_year = years[0] if years else 2026
    forecasts: list[YearForecast] = []
    for i, profit in enumerate(profits):
        y = start_year + i
        p_scale = pit_scale_tax(profit)
        p_linear = pit_linear_tax(profit)
        est_retained = estonian_tax(profit, 0.0)
        est_distributed = estonian_tax(profit, distribute_pct if distribute_pct > 0 else 1.0)
        low_base = min([profit * (distribute_pct if distribute_pct > 0 else 1.0), 2_000_000.0])
        high_base = max([profit * (distribute_pct if distribute_pct > 0 else 1.0) - 2_000_000.0, 0.0])
        forecasts.append(YearForecast(y, profit, p_scale, p_linear,
                                      est_retained, est_distributed, low_base, high_base))

    total_p_scale = sum(f.pit_scale_tax for f in forecasts)
    total_p_linear = sum(f.pit_linear_tax for f in forecasts)
    total_est = sum(f.estonian_retained for f in forecasts)

    # werdykt
    if not eligible:
        verdict = "POZOSTAŃ W PIT — estoński CIT niedostępny (limit przychodów)"
    elif distribute_pct <= 0 and total_est < total_p_linear:
        verdict = "ESTOŃSKI CIT (reinwestycja) — oszczędność przy pełnej reinwestycji zysku"
    elif total_est < total_p_scale and total_est < total_p_linear:
        verdict = "ESTOŃSKI CIT — najniższe obciążenie w horyzoncie 3 lat"
    elif total_p_linear <= total_p_scale:
        verdict = "PIT LINIOWY 19% — najniższe obciążenie (retencja nie przeważa kosztów sp. z o.o.)"
    else:
        verdict = "PIT SKALA — najniższe obciążenie przy danych dochodach"

    return SimulationResult(eligible, notes, revenue_eur, forecasts, verdict)


def render_report(r: SimulationResult) -> str:
    lines = [
        "╔══════════════════════════════════════════════════════════════════════╗",
        "║  PIT vs ESTOŃSKI CIT — SYMULATOR (art. 28c-28t ustawy o CIT)        ║",
        "╚══════════════════════════════════════════════════════════════════════╝",
        f"  Przychody: {r.revenue_eur:,.0f} EUR (limit: {REVENUE_LIMIT_EUR:,.0f} EUR) → "
        f"{'✅ Kwalifikacja' if r.eligible else '❌ POZA LIMITEM'}",
    ]
    for n in r.eligibility_notes:
        lines.append(f"  ⚠ {n}")
    lines.append("  " + "─" * 64)
    lines.append("  rok │ zysk przed opod. │ PIT skala │ PIT 19% │ estoński 0% │ estoński wypłata")
    lines.append("  " + "─" * 64)
    for f in r.forecasts:
        lines.append(f"  {f.year} │ {f.profit_before_tax:>14,.0f} │ {f.pit_scale_tax:>9,.0f} │ "
                     f"{f.pit_linear_tax:>7,.0f} │ {f.estonian_retained:>11,.0f} │ {f.estonian_distributed:>14,.0f}")
    lines.append("  " + "─" * 64)
    lines.append(f"  WERDYKT: {r.verdict}")
    lines.append("  UWAGA: koszty sp. z o.o. (księgowość, KRZ), ZUS członka zarządu, "
                 "ryzyko GAAR/MDR przy sztucznej strukturze")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — Symulator PIT vs estoński CIT")
    p.add_argument("--profits", type=float, nargs="+", required=True,
                   help="zysk przed opodatkowaniem na lata (np. 150000 180000 200000)")
    p.add_argument("--revenue-eur", type=float, required=True, help="przychody w EUR (limit 2 000 000)")
    p.add_argument("--distribute", type=float, default=0.0,
                   help="% wypłacanego zysku (0 = pełna reinwestycja)")
    p.add_argument("--start-year", type=int, default=2026)
    p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)

    years = tuple(range(args.start_year, args.start_year + len(args.profits)))
    res = simulate(args.profits, args.revenue_eur, args.distribute, years)
    if args.json:
        print(json.dumps(res.to_dict(), ensure_ascii=False, indent=2))
    else:
        print(render_report(res))
    return 0


if __name__ == "__main__":
    sys.exit(main())
