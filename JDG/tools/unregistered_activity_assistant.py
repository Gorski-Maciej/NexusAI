#!/usr/bin/env python3
"""P13 assistant for unregistered activity threshold monitoring."""
from __future__ import annotations

import argparse
import json
from datetime import date, timedelta


def assess(
    monthly_revenue: float,
    min_wage: float,
    as_of: date | None = None,
    threshold_pct: float = 50.0,
) -> dict:
    """Assess the monthly revenue against the statutory percentage limit."""
    if monthly_revenue < 0 or min_wage <= 0:
        raise ValueError("monthly_revenue must be non-negative and min_wage must be positive")
    if not 0 < threshold_pct <= 100:
        raise ValueError("threshold_pct must be between 0 and 100")
    limit = min_wage * threshold_pct / 100
    exceeded = monthly_revenue > limit
    evaluation_date = as_of or date.today()
    return {
        "monthly_revenue_pln": round(monthly_revenue, 2),
        "min_wage_pln": round(min_wage, 2),
        "threshold_pct": threshold_pct,
        "limit_pln": round(limit, 2),
        "within_limit": not exceeded,
        "status": "REGISTRATION_REQUIRED" if exceeded else "ALLOWED",
        "registration_deadline": (evaluation_date + timedelta(days=7)).isoformat() if exceeded else None,
        "routing": "TRIAGE_QUEUE" if exceeded else "",
        "legal_basis": "art. 5-6 ustawy — Prawo przedsiębiorców",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revenue", type=float, default=2_000)
    parser.add_argument("--min-wage", type=float, default=4_800)
    args = parser.parse_args()
    print(json.dumps(assess(args.revenue, args.min_wage), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
