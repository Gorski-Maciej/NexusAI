#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 GLM52 — health_tier_engine.py
# Silnik progów składki zdrowotnej ryczałt (art. 81 ust. 2e-2f u.ś.o.z.):
# - automatyczne przełączanie TIER (miesięczna re-ewaluacja przychodu narastająco),
# - kalkulator korekty rocznej (rozliczenie do 22 maja),
# - monitor limitu 12 900 zł (liniowy — odliczenie od podatku),
# - predyktor składki na podstawie przychodów historycznych.
# ═══════════════════════════════════════════════════════════════════════════════
"""Silnik progów składki zdrowotnej — ryczałt + liniowy + korekta roczna."""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Any

# progi ryczałtu 2026 (art. 81 ust. 2e u.ś.o.z.)
TIER_LIMITS = (60000.0, 300000.0)          # przychód roczny
TIER_AMOUNTS = (491.40, 819.00, 1474.20)   # PLN/mies — 60%/100%/180% przeciętnego
TIER_PCTS = ("60%", "100%", "180%")
LINEAR_LIMIT = 14100.0                     # max odliczenie zdrowotnej liniowej/rok (2026 — P563)
LINEAR_RATE = 0.049
SCALE_RATE = 0.09
ANNUAL_SETTLEMENT_DEADLINE = "2027-05-22"  # rozliczenie roczne (następny rok)


@dataclass
class TierResult:
    month: int
    cumulative_revenue: float
    tier: str
    monthly_pln: float
    tier_changed: bool
    previous_tier: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "month": self.month,
            "cumulative_revenue": round(self.cumulative_revenue, 2),
            "tier": self.tier,
            "monthly_pln": self.monthly_pln,
            "tier_changed": self.tier_changed,
            "previous_tier": self.previous_tier,
        }


def tier_for(revenue: float) -> str:
    if revenue <= TIER_LIMITS[0]:
        return "TIER_I"
    if revenue <= TIER_LIMITS[1]:
        return "TIER_II"
    return "TIER_III"


def monthly_for(revenue: float) -> float:
    return TIER_AMOUNTS[["TIER_I", "TIER_II", "TIER_III"].index(tier_for(revenue))]


def simulate_tiers(monthly_revenues: list[float],
                   start_tier: str = "TIER_I") -> list[TierResult]:
    """Symulacja miesięcznej re-ewaluacji progu (przychód narastająco)."""
    results: list[TierResult] = []
    cumulative = 0.0
    prev = start_tier
    for i, rev in enumerate(monthly_revenues, 1):
        cumulative += max([0.0, rev])
        cur = tier_for(cumulative)
        results.append(TierResult(i, cumulative, cur, monthly_for(cumulative),
                                  cur != prev, prev))
        prev = cur
    return results


@dataclass
class AnnualCorrection:
    """Korekta roczna składki zdrowotnej ryczałt (do 22 maja)."""
    paid_total: float
    due_total: float
    difference: float
    is_overpayment: bool
    deadline: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "paid_total": round(self.paid_total, 2),
            "due_total": round(self.due_total, 2),
            "difference": round(self.difference, 2),
            "is_overpayment": self.is_overpayment,
            "deadline": self.deadline,
            "note": "Nadpłata → zwrot z ZUS" if self.is_overpayment
                    else "Dopłata do ZUS",
        }


def annual_correction(monthly_revenues: list[float],
                      paid_total: float) -> AnnualCorrection:
    """Korekta roczna: porównaj zapłacone vs należne wg faktycznego przychodu."""
    cumulative = sum(max([0.0, r]) for r in monthly_revenues)
    due = monthly_for(cumulative) * 12.0
    diff = round2(paid_total - due)
    return AnnualCorrection(paid_total, due, diff, diff > 0, ANNUAL_SETTLEMENT_DEADLINE)


def round2(x: float) -> float:
    return round(x + 1e-9, 2)


def linear_tracker(monthly_incomes: list[float]) -> dict[str, Any]:
    """Monitor 12 900 zł — odliczenie zdrowotnej liniowej od podatku (art. 81 ust. 2d)."""
    contributions = [round2(i * LINEAR_RATE) for i in monthly_incomes]
    annual = round2(sum(contributions))
    excess = round2(max([annual - LINEAR_LIMIT, 0.0]))
    return {
        "monthly_contributions": contributions,
        "annual_total": annual,
        "linear_limit": LINEAR_LIMIT,
        "excess_over_limit": excess,
        "deductible": round2(min([annual, LINEAR_LIMIT])),
        "note": "Zdrowotna liniowa ODLICZALNA od podatku do 12 900 zł/rok (art. 81 ust. 2d u.ś.o.z.)",
    }


def predict(history_revenues: list[float]) -> dict[str, Any]:
    """Predyktor składki na podstawie średniej z historii (prosta projekcja)."""
    if not history_revenues:
        return {"error": "brak danych historycznych"}
    avg_monthly = sum(history_revenues) / len(history_revenues)
    projected_annual = avg_monthly * 12.0
    tier = tier_for(projected_annual)
    return {
        "avg_monthly_revenue": round2(avg_monthly),
        "projected_annual_revenue": round2(projected_annual),
        "projected_tier": tier,
        "projected_monthly_health_pln": monthly_for(projected_annual),
        "method": "mean-extrapolation (baseline)",
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — Health Tier Engine (ryczałt)")
    p.add_argument("--revenues", type=float, nargs="+", required=True,
                   help="przychody miesięczne (12 wartości)")
    p.add_argument("--paid", type=float, default=0, help="zapłacona składka rocznie (korekta)")
    p.add_argument("--linear", action="store_true", help="monitor limitu 12 900 zł (liniowy)")
    p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)

    tiers = simulate_tiers(args.revenues)
    correction = annual_correction(args.revenues, args.paid) if args.paid else None
    result: dict[str, Any] = {
        "tool": "health_tier_engine",
        "campaign": "P08_GLM52_ZUS_MAKRO",
        "tier_simulation": [t.to_dict() for t in tiers],
        "annual_correction": correction.to_dict() if correction else None,
        "annual_settlement_deadline": ANNUAL_SETTLEMENT_DEADLINE,
    }
    if args.linear:
        result["linear_tracker"] = linear_tracker(args.revenues)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for t in tiers:
            flag = "  ◀ ZMIANA PROGU" if t.tier_changed else ""
            print(f"  mies. {t.month:>2}: {t.cumulative_revenue:>10,.2f} PLN → {t.tier} "
                  f"({t.monthly_pln:.2f} PLN){flag}")
        if correction:
            kind = "NADPŁATA (zwrot)" if correction.is_overpayment else "DOPŁATA"
            print(f"  Korekta roczna: zapłacono {correction.paid_total:.2f}, należne "
                  f"{correction.due_total:.2f} → {kind} {abs(correction.difference):.2f} "
                  f"(termin: {correction.deadline})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
