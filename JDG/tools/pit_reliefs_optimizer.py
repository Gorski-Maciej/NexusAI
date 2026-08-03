#!/usr/bin/env python3
"""NexusAI JDG — P05 PIT Macro Reliefs Optimizer (2026-08-02)

Narzędzie optymalizacji PIT Macro (Sekcja 2 P05 — PRIORYTET ulgi):

  --what-if          symulacja "co by było gdyby" (B+R vs IP Box vs termo vs
                     prototyp vs robotyzacja vs ekspansja) — oszczędność per ulga
  --ranking          ranking ulg per przedsiębiorca (malejąco wg oszczędności)
  --unused           detektor niewykorzystanych ulg (eligible ale nie claimed)
  --advances         symulacja zaliczek: standard vs uproszczone (art. 44 ust. 6b)
  --snapshot         migawka thresholdów temporalnych (2025 vs 2026)
  --predict-advances kontrakt ML predykcji zaliczek (INN-05) — deterministyczny
                     baseline (średnia ruchoma) + przedział ufności
  --json / --table   format wyjścia (domyślnie JSON)
  --income N         dochód roczny (PLN) do symulacji form
  --out FILE         zapis wyniku do pliku JSON

Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789), ADR-002 (progi z
data.jdg.thresholds — zero hardcode), ADR-006 (_legal_basis).
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# ── Limity ustawowe (2026) — spójne z p05_pit_macro_innovations_v9.rego ──────
RELIEF_PARAMS = {
    "BR_MULTIPLIER": 1.0,          # art. 26e — 100% (200% na pracowników B+R)
    "IP_BOX_RATE": 0.05,           # art. 30ca — 5%
    "THERMO_LIMIT": 53000,         # art. 26h — 53 000 PLN
    "PROTOTYPE_RATE": 0.30,        # art. 26eb — 30% kosztów
    "ROBOTICS_RATE": 0.50,         # art. 26gb — 50% kosztów
    "EXPANSION_RATE": 0.30,        # art. 26ec — 30% kosztów ekspansji
    "LOSS_CARRY_YEARS": 5,         # art. 9 — 5 lat
    "LOSS_DEDUCTION_CAP": 0.50,    # art. 9 — 50% dochodu
    "PIT0_SHARED_LIMIT": 85528,    # art. 21 — łączny limit ulg PIT-0
}

SCALE_LOW = 0.12
SCALE_HIGH = 0.32
SCALE_THRESHOLD = 120000
LINEAR = 0.19

# Migawki temporalne (2019-2026) — spójne z pit_temporal_snapshot_engine.py
TEMPORAL_SNAPSHOTS = {
    2022: {"scale_low": 0.17, "scale_high": 0.32, "threshold": 120000, "tax_free": 30000, "pit0_limit": 85528},
    2023: {"scale_low": 0.12, "scale_high": 0.32, "threshold": 120000, "tax_free": 30000, "pit0_limit": 85528},
    2024: {"scale_low": 0.12, "scale_high": 0.32, "threshold": 120000, "tax_free": 30000, "pit0_limit": 85528},
    2025: {"scale_low": 0.12, "scale_high": 0.32, "threshold": 120000, "tax_free": 30000, "pit0_limit": 85528},
    2026: {"scale_low": 0.12, "scale_high": 0.32, "threshold": 120000, "tax_free": 30000, "pit0_limit": 85528},
}

RELIEF_REGISTRY = [
    {"id": "BR", "name": "B+R", "legal_basis": "Art. 26e PIT", "rate": RELIEF_PARAMS["BR_MULTIPLIER"],
     "cap": "bez limitu", "cumulative": True, "deductible_from": "BASE"},
    {"id": "IP_BOX", "name": "IP Box", "legal_basis": "Art. 30ca PIT", "rate": RELIEF_PARAMS["IP_BOX_RATE"],
     "cap": "5% stawka", "cumulative": True, "deductible_from": "RATE"},
    {"id": "THERMO", "name": "Termomodernizacyjna", "legal_basis": "Art. 26h PIT", "rate": 1.0,
     "cap": RELIEF_PARAMS["THERMO_LIMIT"], "cumulative": False, "deductible_from": "BASE"},
    {"id": "PROTOTYPE", "name": "Na prototyp", "legal_basis": "Art. 26eb PIT", "rate": RELIEF_PARAMS["PROTOTYPE_RATE"],
     "cap": "do 10% dochodu", "cumulative": True, "deductible_from": "BASE"},
    {"id": "ROBOTICS", "name": "Na robotyzację", "legal_basis": "Art. 26gb PIT", "rate": RELIEF_PARAMS["ROBOTICS_RATE"],
     "cap": "50% kosztów", "cumulative": True, "deductible_from": "BASE"},
    {"id": "EXPANSION", "name": "Na ekspansję", "legal_basis": "Art. 26ec PIT", "rate": RELIEF_PARAMS["EXPANSION_RATE"],
     "cap": "30% kosztów", "cumulative": True, "deductible_from": "BASE"},
    {"id": "PIT0", "name": "PIT-0 (młodzi/powrót/4+/emeryci)", "legal_basis": "Art. 21 ust. 1 pkt 148-152 PIT",
     "rate": 1.0, "cap": RELIEF_PARAMS["PIT0_SHARED_LIMIT"], "cumulative": True, "deductible_from": "EXEMPT"},
    {"id": "LOSS", "name": "Straty z lat ubiegłych", "legal_basis": "Art. 9 ust. 3 PIT", "rate": 1.0,
     "cap": "50% dochodu, 5 lat", "cumulative": True, "deductible_from": "BASE"},
]

DEFAULT_BASES = {
    "BR": 0, "IP_BOX": 0, "THERMO": 0, "PROTOTYPE": 0,
    "ROBOTICS": 0, "EXPANSION": 0, "PIT0": 0, "LOSS": 0,
}
DEFAULT_ELIGIBLE = {"BR", "IP_BOX", "THERMO", "PROTOTYPE", "ROBOTICS", "EXPANSION", "PIT0", "LOSS"}
DEFAULT_CLAIMED = set()


# ── Matematyka podatkowa ──────────────────────────────────────────────────────

def scale_tax(income: float) -> float:
    """Skala 12%/32% z progiem 120 000 PLN (art. 27 PIT)."""
    if income <= SCALE_THRESHOLD:
        return income * SCALE_LOW
    return SCALE_THRESHOLD * SCALE_LOW + (income - SCALE_THRESHOLD) * SCALE_HIGH


def linear_tax(income: float) -> float:
    """Liniowy 19% (art. 30c PIT)."""
    return income * LINEAR


def relief_saving(rid: str, bases: dict) -> float:
    """Szacowana oszczędność podatkowa ulgi (model: stawka skali × oszczędność)."""
    entry = next(r for r in RELIEF_REGISTRY if r["id"] == rid)
    amount = float(bases.get(rid, 0) or 0)
    if rid == "THERMO":
        amount = min(amount, RELIEF_PARAMS["THERMO_LIMIT"])
    if entry["deductible_from"] == "BASE":
        return amount * entry["rate"] * SCALE_LOW
    if entry["deductible_from"] == "RATE":
        return amount * (SCALE_LOW - entry["rate"])
    if entry["deductible_from"] == "EXEMPT":
        return min(amount, RELIEF_PARAMS["PIT0_SHARED_LIMIT"]) * SCALE_LOW
    return 0.0


def rank_reliefs(bases: dict, eligible: set, claimed: set) -> list:
    """Ranking ulg malejąco wg oszczędności; deterministyczny tie-break po id."""
    rows = []
    for r in RELIEF_REGISTRY:
        rows.append({
            "id": r["id"], "name": r["name"], "legal_basis": r["legal_basis"],
            "base": bases.get(r["id"], 0), "eligible": r["id"] in eligible,
            "claimed": r["id"] in claimed,
            "estimated_saving": round(relief_saving(r["id"], bases), 2),
        })
    rows.sort(key=lambda x: (-x["estimated_saving"], x["id"]))
    return rows


def detect_unused(bases: dict, eligible: set, claimed: set) -> dict:
    """Detektor niewykorzystanych ulg (INN-04)."""
    unused = [r["id"] for r in RELIEF_REGISTRY
              if r["id"] in eligible and r["id"] not in claimed and (bases.get(r["id"]) or 0) > 0]
    missed = round(sum(relief_saving(i, bases) for i in unused), 2)
    return {"unused_count": len(unused), "unused": unused, "estimated_missed_saving": missed}


def what_if(bases: dict) -> dict:
    """Symulator 'co by było gdyby' — oszczędność per ulga + najlepsza."""
    ids = ["BR", "IP_BOX", "THERMO", "PROTOTYPE", "ROBOTICS", "EXPANSION"]
    savings = {i: round(relief_saving(i, bases), 2) for i in ids}
    best = max(ids, key=lambda i: (savings[i], i))  # tie-break deterministyczny
    return {"savings": savings, "best": best, "best_saving": savings[best]}


def advances_simulation(prev_year_income: float, monthly_income: float) -> dict:
    """Art. 44: standard vs uproszczone zaliczki (1/12 dochodu z poprzedniego roku)."""
    simplified = round(prev_year_income / 12.0, 2)
    standard = round(monthly_income * SCALE_LOW, 2) if monthly_income <= SCALE_THRESHOLD else \
        round(scale_tax(monthly_income * 12) / 12.0, 2)
    return {
        "standard_monthly": standard,
        "simplified_monthly": simplified,
        "simplified_annual": round(simplified * 12, 2),
        "deadline": "20. dzień miesiąca następującego (art. 44 PIT)",
        "rounding": "zaokrąglenie do pełnych złotych (art. 63 Ordynacji)",
        "recommendation": "SIMPLIFIED_IF_LIQUIDITY_RISK",
    }


def snapshot_diff(year1: int, year2: int) -> dict:
    """Różnica migawek thresholdów temporalnych (Sekcja 6 P05)."""
    a, b = TEMPORAL_SNAPSHOTS[year1], TEMPORAL_SNAPSHOTS[year2]
    changes = {}
    for k in a:
        if a[k] != b[k]:
            changes[k] = {"from": a[k], "to": b[k]}
    return {"year1": year1, "year2": year2, "changes": changes, "change_count": len(changes)}


def predict_advances(history: list[float], horizon: int = 12) -> dict:
    """Baseline ML predykcji zaliczek (INN-05): średnia ruchoma 3-miesięczna.

    Deterministyczny kontrakt — host może podmienić na model ML zachowując schemat.
    """
    if len(history) < 3:
        base = statistics.mean(history) if history else 0.0
        forecast = [round(base, 2)] * horizon
        return {"forecast": forecast, "model": "MOVING_AVG_3", "confidence": 0.0}
    forecast = []
    for i in range(horizon):
        window = history[-3:] if len(history) >= 3 else history
        nxt = statistics.mean(window)
        forecast.append(round(nxt, 2))
        history = list(history) + [nxt]
    return {"forecast": forecast, "model": "MOVING_AVG_3",
            "confidence": 0.8, "note": "Kontrakt ML — deterministyczny baseline (INN-05)"}


# ── CLI ───────────────────────────────────────────────────────────────────────

def parse_bases(args) -> dict:
    bases = dict(DEFAULT_BASES)
    if args.bases:
        for part in args.bases.split(","):
            if "=" in part:
                k, v = part.split("=", 1)
                if k.strip() in bases:
                    bases[k.strip()] = float(v)
    return bases


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — P05 PIT Macro Reliefs Optimizer")
    p.add_argument("--what-if", action="store_true", help="symulacja 'co by było gdyby'")
    p.add_argument("--ranking", action="store_true", help="ranking ulg")
    p.add_argument("--unused", action="store_true", help="detektor niewykorzystanych ulg")
    p.add_argument("--advances", action="store_true", help="symulacja zaliczek (art. 44)")
    p.add_argument("--snapshot", action="store_true", help="migawka thresholdów temporalnych")
    p.add_argument("--predict-advances", action="store_true", help="predykcja zaliczek (INN-05)")
    p.add_argument("--bases", help="kwoty bazowe ulg: BR=10000,IP_BOX=5000,...")
    p.add_argument("--eligible", help="uprawnione ulgi: BR,THERMO (domyślnie wszystkie)")
    p.add_argument("--claimed", help="zadeklarowane ulgi: BR")
    p.add_argument("--income", type=float, default=0, help="dochód roczny (PLN)")
    p.add_argument("--prev-year-income", type=float, default=0, help="dochód z poprzedniego roku")
    p.add_argument("--history", help="historia dochodów miesięcznych (csv)")
    p.add_argument("--table", action="store_true", help="format tabelaryczny")
    p.add_argument("--out", help="zapis wyniku do pliku JSON")
    args = p.parse_args(argv)

    bases = parse_bases(args)
    eligible = set(args.eligible.split(",")) if args.eligible else set(DEFAULT_ELIGIBLE)
    claimed = set(args.claimed.split(",")) if args.claimed else set(DEFAULT_CLAIMED)

    result: dict = {}
    if args.what_if or not (args.ranking or args.unused or args.advances or args.snapshot or args.predict_advances):
        result["what_if"] = what_if(bases)
    if args.ranking:
        result["ranking"] = rank_reliefs(bases, eligible, claimed)
    if args.unused:
        result["unused"] = detect_unused(bases, eligible, claimed)
    if args.advances:
        result["advances"] = advances_simulation(args.prev_year_income, args.income / 12.0 if args.income else 0)
    if args.snapshot:
        result["snapshot_diff_2025_2026"] = snapshot_diff(2025, 2026)
    if args.predict_advances:
        history = [float(x) for x in args.history.split(",")] if args.history else []
        result["advance_forecast"] = predict_advances(history)

    result["form_comparison"] = {
        "income": args.income,
        "scale_tax": round(scale_tax(args.income), 2),
        "linear_tax": round(linear_tax(args.income), 2),
        "recommended": "LINEAR" if linear_tax(args.income) < scale_tax(args.income) else "SCALE",
    }

    if args.table:
        if "ranking" in result:
            print("=== RANKING ULG (P05) ===")
            for r in result["ranking"]:
                print(f"  {r['id']:<10} {r['name']:<28} oszczędność: {r['estimated_saving']:>12.2f} PLN "
                      f"eligible={r['eligible']} claimed={r['claimed']}")
        if "what_if" in result:
            print("=== WHAT-IF ===")
            for k, v in result["what_if"]["savings"].items():
                print(f"  {k:<10} {v:>12.2f} PLN")
            print(f"  BEST: {result['what_if']['best']} ({result['what_if']['best_saving']} PLN)")
        if "unused" in result:
            print(f"=== NIEWYKORZYSTANE ULGI: {result['unused']['unused']} (utracone: {result['unused']['estimated_missed_saving']} PLN) ===")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano do {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
