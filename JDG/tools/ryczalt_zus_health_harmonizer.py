#!/usr/bin/env python3
"""P13 cross-domain burden calculator: lump sum tax, ZUS and health."""
from __future__ import annotations

import argparse
import json
from typing import Final

HEALTH_TIERS: Final = ((60_000.0, "TIER_1"), (300_000.0, "TIER_2"), (float("inf"), "TIER_3"))


def harmonize(
    annual_revenue: float,
    ryczalt_rate: float = 8.5,
    zus_relief_type: str = "FULL",
    zus_monthly_pln: float = 0.0,
    health_monthly_pln: float = 0.0,
    health_tier_base: float | None = None,
) -> dict:
    """Calculate total annual burden using supplied current contribution amounts.

    Contribution amounts are explicit inputs because ZUS and health values change
    independently from the tax rate registry. Missing amounts remain zero and are
    flagged in ``assumptions`` instead of being silently invented.
    """
    if annual_revenue < 0 or zus_monthly_pln < 0 or health_monthly_pln < 0:
        raise ValueError("revenue and contribution amounts must be non-negative")
    if not 0 <= ryczalt_rate <= 100:
        raise ValueError("ryczalt_rate must be between 0 and 100")
    relief = zus_relief_type.upper()
    if relief not in {"START", "PREFERENTIAL", "FULL", "CUSTOM"}:
        raise ValueError("zus_relief_type must be START, PREFERENTIAL, FULL or CUSTOM")

    tier_base = annual_revenue if health_tier_base is None else health_tier_base
    tier = next(name for threshold, name in HEALTH_TIERS if tier_base <= threshold)
    lump_sum = annual_revenue * ryczalt_rate / 100
    social = zus_monthly_pln * 12
    health = health_monthly_pln * 12
    total = lump_sum + social + health
    return {
        "annual_revenue": round(annual_revenue, 2),
        "ryczalt_rate_pct": ryczalt_rate,
        "ryczalt_tax_pln": round(lump_sum, 2),
        "zus_relief_type": relief,
        "zus_annual_pln": round(social, 2),
        "health_tier": tier,
        "health_annual_pln": round(health, 2),
        "total_burden_pln": round(total, 2),
        "effective_rate_pct": round(total / annual_revenue * 100, 4) if annual_revenue else 0.0,
        "thresholds": {"tier_1_max_pln": 60_000, "tier_2_max_pln": 300_000},
        "assumptions": [
            "kwoty miesięczne ZUS i zdrowotnej są wymaganymi danymi wejściowymi",
            "progi zdrowotnej: 60 000 PLN i 300 000 PLN",
        ],
        "legal_basis": "art. 12 ustawy o ryczałcie; art. 18-19 ustawy o SUS; art. 79-81 ustawy zdrowotnej",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revenue", type=float, default=300_000)
    parser.add_argument("--rate", type=float, default=8.5)
    parser.add_argument("--zus-type", default="FULL")
    parser.add_argument("--zus-monthly", type=float, default=0)
    parser.add_argument("--health-monthly", type=float, default=0)
    args = parser.parse_args()
    print(json.dumps(harmonize(args.revenue, args.rate, args.zus_type, args.zus_monthly, args.health_monthly), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
