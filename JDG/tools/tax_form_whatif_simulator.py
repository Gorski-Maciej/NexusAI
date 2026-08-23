#!/usr/bin/env python3
"""P13 what-if calculator for the three main PIT forms."""
from __future__ import annotations

import argparse
import json
from decimal import Decimal, ROUND_HALF_UP


def _money(value: float | int | Decimal) -> float:
    return float(Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def _nonnegative(name: str, value: float) -> float:
    if value < 0:
        raise ValueError(f"{name} must be non-negative")
    return float(value)


def compare_forms(
    annual_revenue: float,
    business_costs: float,
    zus_base: float = 0.0,
    ryczalt_rate: float = 8.5,
) -> dict:
    """Compare annual PIT tax; inputs are PLN, rate is a percentage."""
    revenue = _nonnegative("annual_revenue", annual_revenue)
    costs = _nonnegative("business_costs", business_costs)
    zus = _nonnegative("zus_base", zus_base)
    rate = float(ryczalt_rate)
    if not 0 <= rate <= 100:
        raise ValueError("ryczalt_rate must be between 0 and 100")

    profit = max(revenue - costs - zus, 0.0)
    lump_sum = revenue * rate / 100
    scale_base = max(profit - 30_000, 0.0)
    scale_tax = min(scale_base, 120_000) * 0.12 + max(scale_base - 120_000, 0.0) * 0.32
    linear_tax = profit * 0.19
    taxes = {
        "ryczalt": _money(lump_sum),
        "skala": _money(scale_tax),
        "liniowy": _money(linear_tax),
    }
    best_form, best_tax = min(taxes.items(), key=lambda item: item[1])
    return {
        "annual_revenue": _money(revenue),
        "business_costs": _money(costs),
        "zus_base": _money(zus),
        "taxable_profit": _money(profit),
        "ryczalt_rate_pct": rate,
        "taxes": taxes,
        "best_form": best_form,
        "best_tax": best_tax,
        "savings_vs_worst": _money(max(taxes.values()) - best_tax),
        "assumptions": [
            "skala: kwota wolna 30 000 PLN, progi 12%/32%",
            "liniowy: 19% dochodu po kosztach i składkach społecznych",
            "ryczałt: stawka od przychodu, bez kosztów uzyskania",
            "składka zdrowotna i ulgi są poza porównaniem PIT",
        ],
        "legal_basis": "art. 9a i 27 ustawy o PIT; art. 12 ustawy o ryczałcie",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revenue", type=float, default=300_000)
    parser.add_argument("--costs", type=float, default=60_000)
    parser.add_argument("--zus", type=float, default=0)
    parser.add_argument("--rate", type=float, default=8.5)
    args = parser.parse_args()
    print(json.dumps(compare_forms(args.revenue, args.costs, args.zus, args.rate), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
