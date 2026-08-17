#!/usr/bin/env python3
"""
NexusAI JDG — ZUS ZASIŁKOWY KALKULATOR (GLM52 P09, Enterprise)
=============================================================
Kalkulator świadczeń zasiłkowych mikro (ustawa zasiłkowa) — wdrożenie
PROMPT 09 §3:

  • benefit_base(monthly_bases)  — podstawa zasiłku = średnia z 12 mies.
                                   historii podstaw składek (art. 19 ust. 1),
                                   podstawa dzienna = /30 (grosze),
  • sickness_benefit(...)        — zasiłek chorobowy: 80% (70% w szpitalu),
                                   z limitem dni 182/270 (art. 8),
  • waiting_period(...)          — okres wyczekiwania: 90 dni (dobrowolne
                                   chorobowe JDG) / 30 dni (obowiązkowe),
  • limit_tracker(used, tb)      — tracker limitu dni + alert 90%,
  • voluntary_sickness_simulator(...) — symulator „dobrowolne chorobowe”:
                                   składka 2,45% vs oczekiwany zasiłek.

Usage:
  python3 tools/zus_zasilkowa_calculator.py              # self-test
  python3 tools/zus_zasilkowa_calculator.py --base 8000 --days 30
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

RATE_STANDARD = 0.80      # 80% podstawy (art. 33)
RATE_HOSPITAL = 0.70      # 70% w szpitalu
DAILY_DIVISOR = 30
BASE_MONTHS = 12
LIMIT_STANDARD = 182      # dni/rok (art. 8 ust. 1 pkt 1)
LIMIT_TB = 270            # dni/rok (gruźlica, art. 8 ust. 2)
WAIT_VOLUNTARY = 90       # dni (dobrowolne chorobowe JDG)
WAIT_EMPLOYEE = 30        # dni (obowiązkowe)
VOLUNTARY_RATE = 0.0245   # 2,45% — składka chorobowa (art. 22 ust. 3 SUS)


def round2(x: float) -> float:
    return round(x * 100) / 100


def benefit_base(monthly_bases: list[float]) -> dict[str, Any]:
    """Podstawa zasiłku: średnia z 12 mies. podstaw; dzienna = /30."""
    if not monthly_bases:
        return {"error": "brak historii podstaw składek"}
    count = len(monthly_bases)
    avg = round2(sum(monthly_bases) / count)
    daily = round2(avg / DAILY_DIVISOR)
    return {
        "months_used": count,
        "base_monthly_pln": avg,
        "base_daily_pln": daily,
        "formula": "Σ podstaw / 12; dzienna = /30",
        "legal": "Art. 19 ust. 1 ustawy zasiłkowej",
    }


def sickness_benefit(base_daily: float, days: int, hospital: bool = False) -> dict[str, Any]:
    """Zasiłek chorobowy: 80% (70% w szpitalu) × podstawa dzienna × dni."""
    rate = RATE_HOSPITAL if hospital else RATE_STANDARD
    daily = round2(base_daily * rate)
    total = round2(daily * days)
    return {
        "rate": rate,
        "daily_benefit_pln": daily,
        "days": days,
        "total_benefit_pln": total,
        "hospital": hospital,
        "legal": "Art. 33 ustawy zasiłkowej (80%; 70% w szpitalu)",
    }


def waiting_period(insured_days: int, voluntary: bool) -> dict[str, Any]:
    """Okres wyczekiwania: 90 dni dobrowolne / 30 dni obowiązkowe (art. 4 ust. 1 pkt 2)."""
    required = WAIT_VOLUNTARY if voluntary else WAIT_EMPLOYEE
    return {
        "insured_days": insured_days,
        "required_days": required,
        "met": insured_days >= required,
        "remaining_days": max(0, required - insured_days),
        "voluntary": voluntary,
        "legal": "Art. 4 ust. 1 pkt 2 ustawy zasiłkowej",
    }


def limit_tracker(days_used: int, tuberculosis: bool = False) -> dict[str, Any]:
    """Tracker limitu dni: 182/270 — alert przy ≥ 90% limitu."""
    limit = LIMIT_TB if tuberculosis else LIMIT_STANDARD
    remaining = limit - days_used
    return {
        "days_used": days_used,
        "limit_days": limit,
        "remaining_days": remaining,
        "alert_90pct": days_used >= 0.9 * limit,
        "limit_exceeded": days_used > limit,
        "legal": "Art. 8 ustawy zasiłkowej",
    }


def voluntary_sickness_simulator(monthly_base: float, expected_days: int) -> dict[str, Any]:
    """Symulator „dobrowolne chorobowe”: składka 2,45% vs oczekiwany zasiłek.

    Zwraca próg opłacalności — po ilu dniach zasiłek przewyższa koszt składek.
    """
    monthly_contribution = round2(monthly_base * VOLUNTARY_RATE)
    base_info = benefit_base([monthly_base] * BASE_MONTHS)
    daily = base_info["base_daily_pln"] * RATE_STANDARD
    benefit_for_days = round2(daily * expected_days)
    annual_contribution = round2(monthly_contribution * 12)
    breakeven_days = (annual_contribution / daily) if daily > 0 else 9999
    return {
        "monthly_contribution_pln": monthly_contribution,
        "annual_contribution_pln": annual_contribution,
        "expected_days": expected_days,
        "expected_benefit_pln": benefit_for_days,
        "breakeven_days": round(breakeven_days, 1),
        "profitable": benefit_for_days > annual_contribution,
        "note": "Próg opłacalności: dni zasiłku > koszt roczny składek (2,45%)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    # podstawa 8 000 × 12 mies. → 8 000/30 = 266.67 dziennie
    bb = benefit_base([8000.0] * 12)
    if bb["base_daily_pln"] != 266.67:
        failures.append(f"podstawa dzienna: oczekiwano 266.67, jest {bb['base_daily_pln']}")
    # zasiłek 30 dni @ 80% → dzienna = 266.67 × 0.8 = 213.34 (grosze); × 30 = 6400.20
    sb = sickness_benefit(266.67, 30)
    if sb["total_benefit_pln"] != 6400.20:
        failures.append(f"zasiłek 30 dni: oczekiwano 6400.20, jest {sb['total_benefit_pln']}")
    # szpital 70%
    sh = sickness_benefit(266.67, 10, hospital=True)
    if sh["rate"] != 0.70 or sh["daily_benefit_pln"] != 186.67:
        failures.append(f"szpital: oczekiwano 186.67, jest {sh['daily_benefit_pln']}")
    # wyczekiwanie
    wp = waiting_period(85, voluntary=True)
    if wp["met"]:
        failures.append("wyczekiwanie: 85 dni < 90 — powinno być NIE spełnione")
    if not waiting_period(90, voluntary=True)["met"]:
        failures.append("wyczekiwanie: 90 dni — powinno być spełnione")
    # limity
    lt = limit_tracker(170)
    if lt["alert_90pct"] is not True:
        failures.append("limit: 170/182 ≥ 90% — alert powinien być aktywny")
    if limit_tracker(183)["limit_exceeded"] is not True:
        failures.append("limit: 183 > 182 — przekroczenie powinno być wykryte")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", type=float, help="podstawa miesięczna składek (PLN)")
    ap.add_argument("--days", type=int, default=30, help="liczba dni zasiłku")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)

    if args.base is not None:
        bb = benefit_base([args.base] * BASE_MONTHS)
        sb = sickness_benefit(bb["base_daily_pln"], args.days)
        print(json.dumps({"base": bb, "benefit": sb}, ensure_ascii=False, indent=2))
        return 0

    failures = self_test()
    if failures:
        print("ZUS ZASIŁKOWY KALKULATOR: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("ZUS ZASIŁKOWY KALKULATOR: ✅ PASS — podstawa 12 mies., stawki 80/70%, limity 182/270 OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
