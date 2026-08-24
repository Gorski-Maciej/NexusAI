#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 GLM52 — zus_calculator.py
# Kalkulator składek ZUS z dowodem groszowym (podstawa × stopa = kwota).
# Pokrycie: społeczne (art. 6, 18-19, 22, 36, 47 SUS) + zdrowotna (art. 79-81
# u.ś.o.z.) per forma PIT. Poziom ENTERPRISE: każda kwota = certyfikat dowodu.
# ═══════════════════════════════════════════════════════════════════════════════
"""Kalkulator składek ZUS dla JDG z pełnym dowodem obliczenia.

Społeczne (art. 22 SUS): emerytalna 19,52% + rentowa 8% + chorobowa 2,45%
(dobrowolna) + wypadkowa 1,67% → łącznie 31,64% (z chorobową).
Zdrowotna (art. 79-81 u.ś.o.z.): skala 9%, liniowy 4,9%, ryczałt wg progów.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Any
from pathlib import Path
import re

# stopy składek społecznych (art. 22 SUS, 2026)
RATES = {
    "pension": 0.1952,    # emerytalna
    "disability": 0.08,   # rentowa
    "sickness": 0.0245,   # chorobowa (dobrowolna)
    "accident": 0.0167,   # wypadkowa (1,67% standard)
}
SOCIAL_WITH_SICKNESS = sum(RATES.values())   # 0.3164
SOCIAL_WITHOUT_SICKNESS = SOCIAL_WITH_SICKNESS - RATES["sickness"]  # 0.2919

# zdrowotna
HEALTH_SCALE = 0.09       # skala PIT — 9% od dochodu
HEALTH_LINEAR = 0.049     # liniowy — 4,9% od dochodu (odliczalna od podatku)
HEALTH_LINEAR_DEDUCT_LIMIT = 14100.0  # fallback; preferuje data.jdg.thresholds.zus
HEALTH_LUMP_LIMITS = (60000.0, 300000.0)
HEALTH_LUMP_AMOUNTS = (491.40, 819.00, 1474.20)  # 60%/100%/180% przeciętnego

# ulgi składkowe
START_RELIEF_MONTHS = 6          # art. 18a SUS — ulga na start (bez społecznych)
PREFERENTIAL_PCT = 0.30          # art. 18c ust. 2 — 30% minimalnego wynagrodzenia
MALY_PLUS_PCT = 0.30             # art. 18c ust. 4 — 30% dochodu poprzedniego roku
MALY_PLUS_REVENUE_LIMIT = 120000.0  # art. 18c ust. 8 — limit przychodu


@dataclass
class ContributionProof:
    """Dowód pojedynczej składki: podstawa × stopa = kwota."""
    name: str
    base: float
    rate: float
    amount: float
    legal_basis: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "base": round(self.base, 2),
            "rate": self.rate,
            "amount": round(self.amount, 2),
            "legal_basis": self.legal_basis,
        }


def round2(x: float) -> float:
    return round(x + 1e-9, 2)


def social_contributions(base: float, sickness: bool = True,
                         accident_rate: float = 0.0167) -> list[ContributionProof]:
    """Składki społeczne od podstawy (art. 22 SUS) z dowodem groszowym."""
    proofs = [
        ContributionProof("Emerytalna", base, RATES["pension"],
                          round2(base * RATES["pension"]), "Art. 22 pkt 1 SUS (19,52%)"),
        ContributionProof("Rentowa", base, RATES["disability"],
                          round2(base * RATES["disability"]), "Art. 22 pkt 2 SUS (8%)"),
    ]
    if sickness:
        proofs.append(ContributionProof("Chorobowa (dobrowolna)", base, RATES["sickness"],
                                        round2(base * RATES["sickness"]), "Art. 22 pkt 3 SUS (2,45%)"))
    proofs.append(ContributionProof("Wypadkowa", base, accident_rate,
                                    round2(base * accident_rate), "Art. 22 pkt 4 SUS (1,67%)"))
    return proofs


def health_scale(income: float) -> ContributionProof:
    return ContributionProof("Zdrowotna — skala", income, HEALTH_SCALE,
                             round2(income * HEALTH_SCALE), "Art. 81 ust. 1 u.ś.o.z. (9%)")


def health_linear(income: float) -> ContributionProof:
    return ContributionProof("Zdrowotna — liniowy", income, HEALTH_LINEAR,
                             round2(income * HEALTH_LINEAR), "Art. 81 ust. 2c u.ś.o.z. (4,9%)")


def health_lump(revenue: float) -> ContributionProof:
    """Ryczałt: 3 progi kwotowe (art. 81 ust. 2e-2f u.ś.o.z.)."""
    if revenue <= HEALTH_LUMP_LIMITS[0]:
        tier, amount, pct = "I (≤60k)", HEALTH_LUMP_AMOUNTS[0], "60%"
    elif revenue <= HEALTH_LUMP_LIMITS[1]:
        tier, amount, pct = "II (60-300k)", HEALTH_LUMP_AMOUNTS[1], "100%"
    else:
        tier, amount, pct = "III (>300k)", HEALTH_LUMP_AMOUNTS[2], "180%"
    return ContributionProof(f"Zdrowotna — ryczałt {tier}", amount, 0.09,
                             round2(amount), f"Art. 81 ust. 2e u.ś.o.z. ({pct} przeciętnego)")


def relief_base(min_wage: float, avg_wage: float, relief: str,
                prev_year_income: float = 0.0) -> tuple[float, str]:
    """Podstawa składek społecznych wg ulgi (art. 18a/18c SUS)."""
    if relief == "start":
        return 0.0, "Ulga na start (art. 18a) — 6 mies. bez społecznych, tylko zdrowotna"
    if relief == "preferential":
        return round2(min_wage * PREFERENTIAL_PCT), \
            f"Preferencyjna (art. 18c ust. 2) — 30% minimalnej ({min_wage:.2f} PLN)"
    if relief == "maly_plus":
        raw = prev_year_income / 12.0 * MALY_PLUS_PCT
        lo = min_wage * PREFERENTIAL_PCT
        hi = avg_wage * 0.60
        return round2(max([lo, min([raw, hi])])), \
            f"Mały ZUS Plus (art. 18c ust. 4-5) — 30% dochodu poprz. roku, clamp [{lo:.2f}, {hi:.2f}]"
    return round2(max([min_wage * 0.60, 0.0])), \
        f"Standard — 60% przeciętnego ({avg_wage:.2f} PLN)"


def _thresholds() -> dict[str, Any]:
    """Odczytuje parametry zdrowotnej z kanonicznego thresholds_jdg.rego."""
    path = Path(__file__).resolve().parent / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    values: dict[str, Any] = {}
    for key in ("health_linear_deduction_limit", "health_lump_tier_1_limit", "health_lump_tier_2_limit"):
        match = re.search(rf'"{key}"\s*:\s*([0-9.]+)', text)
        if match:
            values[key] = float(match.group(1))
    return values


def calculate(base: float, tax_form: str, revenue: float = 0.0,
              sickness: bool = True) -> dict[str, Any]:
    """Pełna kalkulacja składek z dowodem."""
    thresholds = _thresholds()
    global HEALTH_LINEAR_DEDUCT_LIMIT
    HEALTH_LINEAR_DEDUCT_LIMIT = thresholds.get("health_linear_deduction_limit", HEALTH_LINEAR_DEDUCT_LIMIT)
    proofs = social_contributions(base, sickness)
    if tax_form == "PIT_SCALE":
        health = health_scale(max([revenue, base]))
    elif tax_form == "PIT_LINEAR":
        health = health_linear(max([revenue, base]))
    elif tax_form == "LUMP_SUM":
        health = health_lump(revenue)
    else:  # TAX_CARD
        health = ContributionProof("Zdrowotna — karta podatkowa", 0.0, HEALTH_SCALE,
                                   0.0, "Art. 81 ust. 2g u.ś.o.z. (9% od minimalnego)")

    total_social = round2(sum(p.amount for p in proofs))
    total = round2(total_social + health.amount)
    return {
        "tool": "zus_calculator",
        "campaign": "P08_GLM52_ZUS_MAKRO",
        "tax_form": tax_form,
        "base": round2(base),
        "social": [p.to_dict() for p in proofs],
        "health": health.to_dict(),
        "total_social": total_social,
        "total_health": health.amount,
        "total_monthly": total,
        "proof_grosz": round2(sum(p.amount for p in proofs) + health.amount) == total,
        "invariant_sum": round2(total_social + health.amount) == total,
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — Kalkulator składek ZUS z dowodem")
    p.add_argument("--base", type=float, required=True, help="podstawa składek społecznych (PLN)")
    p.add_argument("--form", choices=["PIT_SCALE", "PIT_LINEAR", "LUMP_SUM", "TAX_CARD"],
                   default="PIT_SCALE", help="forma opodatkowania")
    p.add_argument("--revenue", type=float, default=0, help="przychód (ryczałt — progi)")
    p.add_argument("--no-sickness", action="store_true", help="bez dobrowolnej chorobowej")
    p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)

    r = calculate(args.base, args.form, args.revenue, sickness=not args.no_sickness)
    if args.json:
        print(json.dumps(r, ensure_ascii=False, indent=2))
    else:
        lines = [f"Kalkulacja ZUS — forma: {args.form}, podstawa: {r['base']:.2f} PLN"]
        for s in r["social"]:
            lines.append(f"  · {s['name']:<24} {s['base']:>10.2f} × {s['rate']*100:>5.2f}% = {s['amount']:>10.2f}")
        h = r["health"]
        lines.append(f"  · {h['name']:<24} {h['base']:>10.2f} → {h['amount']:>10.2f}")
        lines.append(f"  RAZEM: społeczne {r['total_social']:.2f} + zdrowotna {r['total_health']:.2f} = {r['total_monthly']:.2f} PLN/mies")
        print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
