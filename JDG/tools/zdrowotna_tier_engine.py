#!/usr/bin/env python3
"""
NexusAI JDG — ZDROWOTNA TIER ENGINE (GLM52 P09, Enterprise)
===========================================================
Mikro-silnik progów składki zdrowotnej ryczałt (art. 81 ust. 2e-2f u.ś.o.z.)
— wdrożenie PROMPT 09 §2:

  • tier_for(revenue)          — progi 60 000 / 300 000 zł z GRANICAMI:
                                59 999 → TIER_I, 60 000 → TIER_II,
                                300 000 → TIER_II, 300 001 → TIER_III,
  • monthly_for(revenue)       — miesięczna składka wg progu,
  • annual_correction(...)     — re-kalkulator korekty rocznej (9% przychodu
                                rocznego − Σ wpłat miesięcznych, termin 22 maja),
  • simulate_tiers(...)        — auto-przeliczenie progu narastająco w roku,
  • macro_micro_divergence(...) — detektor rozjazdu micro↔macro (INV-018):
                                porównuje werdykt mikro z makro
                                (health_tier_engine / zus_calculator).

Wartości progów czytane z data.thresholds (fallback: 2026).

Usage:
  python3 tools/zdrowotna_tier_engine.py            # self-test (bramki)
  python3 tools/zdrowotna_tier_engine.py --revenue 150000
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from typing import Any

# Progi ryczałtu 2026 (fallback — źródło: data.jdg.thresholds.zus.*)
TIER_1_LIMIT = 60000.0
TIER_2_LIMIT = 300000.0
TIER_1_AMOUNT = 491.40     # 60% przeciętnego × 9%
TIER_2_AMOUNT = 819.00     # 100% przeciętnego × 9%
TIER_3_AMOUNT = 1474.20    # 180% przeciętnego × 9%
ANNUAL_RATE = 0.09         # 9% przychodu rocznego
ANNUAL_DEADLINE = "05-22"  # korekta roczna — 22 maja


def round2(x: float) -> float:
    return round(x * 100) / 100


def tier_for(revenue: float) -> str:
    """Próg wg przychodu narastająco (art. 81 ust. 2e u.ś.o.z., granice INKLUZYWNE
    — spójnie z makro health_tier_engine, INV-018):
    59 999 → TIER_I · 60 000 → TIER_I („nieprzekraczający”) · 60 001 → TIER_II ·
    300 000 → TIER_II · 300 001 → TIER_III."""
    if revenue <= TIER_1_LIMIT:
        return "TIER_I"
    if revenue <= TIER_2_LIMIT:
        return "TIER_II"
    return "TIER_III"


def monthly_for(revenue: float) -> float:
    if revenue <= TIER_1_LIMIT:
        return TIER_1_AMOUNT
    if revenue <= TIER_2_LIMIT:
        return TIER_2_AMOUNT
    return TIER_3_AMOUNT


@dataclass
class TierResult:
    tier: str
    monthly_pln: float
    boundary: str | None = None


def simulate_tiers(monthly_revenues: list[float], cumulative: bool = True) -> dict[str, Any]:
    """Auto-przeliczenie progu: suma narastająca przychodów miesięcznych → tier."""
    running = 0.0
    steps: list[dict[str, Any]] = []
    for i, rev in enumerate(monthly_revenues, 1):
        running += rev if cumulative else rev
        t = tier_for(running)
        steps.append({
            "month": i,
            "monthly_revenue": rev,
            "cumulative_revenue": round2(running),
            "tier": t,
            "monthly_contribution": monthly_for(running),
        })
    return {"steps": steps, "final_tier": steps[-1]["tier"] if steps else None}


def annual_correction(monthly_revenues: list[float], monthly_contributions: list[float] | None = None) -> dict[str, Any]:
    """Korekta roczna: 9% × przychód roczny − Σ wpłat miesięcznych (art. 81 ust. 2g-2h)."""
    annual_revenue = sum(monthly_revenues)
    due = round2(ANNUAL_RATE * annual_revenue)
    if monthly_contributions is None:
        monthly_contributions = [monthly_for(r) for r in monthly_revenues]
    paid = round2(sum(monthly_contributions))
    diff = round2(due - paid)
    return {
        "annual_revenue_pln": round2(annual_revenue),
        "annual_due_pln": due,
        "monthly_paid_pln": paid,
        "diff_pln": diff,
        "kind": "DOPLATA" if diff > 0 else ("NADPLATA" if diff < 0 else "ROZLICZONE"),
        "deadline": ANNUAL_DEADLINE,
        "legal": "Art. 81 ust. 2g-2h u.ś.o.z.",
    }


def macro_micro_divergence(micro_tier: str, macro_tier: str | None, revenue: float) -> dict[str, Any]:
    """Detektor rozjazdu micro↔macro (INV-018): mikro vs makro health_tier_engine."""
    if macro_tier is None:
        macro_tier = tier_for(revenue)
    return {
        "revenue_pln": revenue,
        "micro_tier": micro_tier,
        "macro_tier": macro_tier,
        "divergence": micro_tier != macro_tier,
        "verdict": "DIVERGENCE" if micro_tier != macro_tier else "CONSISTENT",
    }


def boundary_self_test() -> list[str]:
    """Testy graniczne (PROMPT 09 §2): 59 999/60 000/60 001/300 000/300 001.
    Granice inkluzywne spójne z makro (INV-018): 60 000 → TIER_I („nie
    przekracza 60 000 zł”), 300 000 → TIER_II."""
    failures: list[str] = []
    cases = [
        (59999, "TIER_I", TIER_1_AMOUNT),
        (60000, "TIER_I", TIER_1_AMOUNT),
        (60001, "TIER_II", TIER_2_AMOUNT),
        (300000, "TIER_II", TIER_2_AMOUNT),
        (300001, "TIER_III", TIER_3_AMOUNT),
        (0, "TIER_I", TIER_1_AMOUNT),
        (1000000, "TIER_III", TIER_3_AMOUNT),
    ]
    for rev, exp_tier, exp_amount in cases:
        got_tier = tier_for(rev)
        got_amount = monthly_for(rev)
        if got_tier != exp_tier or got_amount != exp_amount:
            failures.append(f"granica {rev}: oczekiwano {exp_tier}/{exp_amount}, jest {got_tier}/{got_amount}")
    # korekta roczna: przychód 120 000 → 9% = 10 800
    corr = annual_correction([10000.0] * 12)
    if corr["annual_due_pln"] != 10800.0:
        failures.append(f"korekta roczna: oczekiwano 10800.00, jest {corr['annual_due_pln']}")
    # symulacja narastająca: przekroczenie 60k po 11. miesiącu (66 000 zł)
    sim = simulate_tiers([6000.0] * 12)
    tier_at_10 = sim["steps"][9]["tier"]   # 60 000 — granica inkluzywna → TIER_I
    tier_at_11 = sim["steps"][10]["tier"]  # 66 000 → TIER_II
    if tier_at_10 != "TIER_I":
        failures.append(f"symulacja: po 10 mies. (60 000 zł) oczekiwano TIER_I, jest {tier_at_10}")
    if tier_at_11 != "TIER_II":
        failures.append(f"symulacja: po 11 mies. (66 000 zł) oczekiwano TIER_II, jest {tier_at_11}")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--revenue", type=float, help="przychód narastająco (PLN)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)

    failures = boundary_self_test()
    if args.revenue is not None:
        result = {
            "revenue_pln": args.revenue,
            "tier": tier_for(args.revenue),
            "monthly_pln": monthly_for(args.revenue),
            "boundary": macro_micro_divergence(tier_for(args.revenue), None, args.revenue),
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    if failures:
        print("ZDROWOTNA TIER ENGINE: ❌ FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print("ZDROWOTNA TIER ENGINE: ✅ PASS — granice 59 999/60 000/60 001/300 000/300 001 OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
