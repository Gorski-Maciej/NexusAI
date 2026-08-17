#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GLM52 — ipbox_nexus_calculator.py
# Kalkulator wskaźnika Nexus dla IP Box (art. 30ca ust. 4-5 PIT) z pełnym
# dowodem obliczenia. Poziom ENTERPRISE: każdy wynik = certyfikat z podstawą.
# ═══════════════════════════════════════════════════════════════════════════════
"""Kalkulator Nexus IP Box (art. 30ca ust. 4-5 PIT).

Nexus = (a + b + c) × 1.3 / (a + b + c + d), gdzie:
  a = koszty działalności B+R bezpośrednio związane z IP (faktycznie poniesione)
  b = koszty nabycia wyników prac B+R od podmiotów niepowiązanych
  c = koszty nabycia IP od podmiotów niepowiązanych
  d = koszty nabycia IP od podmiotów powiązanych (niekwalifikowane)

Limity: wskaźnik ≤ 1.0; dochód kwalifikowany = dochód z IP × nexus.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

UPLIFT = 1.3  # art. 30ca ust. 4 pkt 2 PIT
RATE = 0.05   # art. 30ca ust. 1 PIT


@dataclass
class NexusResult:
    """Wynik kalkulacji nexus z dowodem."""
    a: float
    b: float
    c: float
    d: float
    nexus: float
    qualifying_income: float
    tax_5pct: float
    evidence: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "a_brd_direct": round(self.a, 2),
            "b_acquisition_unrelated": round(self.b, 2),
            "c_ip_acquisition_unrelated": round(self.c, 2),
            "d_ip_acquisition_related": round(self.d, 2),
            "nexus_ratio": round(self.nexus, 4),
            "nexus_ratio_pct": round(self.nexus * 100, 2),
            "qualifying_income": round(self.qualifying_income, 2),
            "tax_at_5pct": round(self.tax_5pct, 2),
            "evidence": self.evidence,
        }


def compute_nexus(a: float, b: float, c: float, d: float,
                  qualifying_income: float) -> NexusResult:
    """Oblicza wskaźnik Nexus i podatek 5% z pełnym dowodem."""
    evidence: list[str] = []
    a, b, c, d = (max([0.0, v]) for v in (a, b, c, d))
    qualifying_income = max([0.0, qualifying_income])

    numerator = (a + b + c) * UPLIFT
    denominator = a + b + c + d
    nexus = min([numerator / denominator, 1.0]) if denominator > 0 else 0.0

    evidence.append(f"Licznik = (a+b+c)×1.3 = ({a:.2f}+{b:.2f}+{c:.2f})×{UPLIFT} = {numerator:.2f}")
    evidence.append(f"Mianownik = a+b+c+d = {a:.2f}+{b:.2f}+{c:.2f}+{d:.2f} = {denominator:.2f}")
    evidence.append(f"Nexus = {numerator:.2f}/{denominator:.2f} = {nexus*100:.2f}% (max 100%)")
    if d > 0:
        evidence.append("UWAGA: koszty od podmiotów powiązanych (d) OBNIŻAJĄ wskaźnik — "
                        "nie są kwalifikowane (art. 30ca ust. 4 pkt 4 PIT)")
    if nexus >= 1.0:
        evidence.append("Wskaźnik osiągnął limit 100% — podstawa do zaokrąglenia w górę (art. 30ca ust. 5 PIT)")

    qi = qualifying_income * nexus
    tax = qi * RATE
    evidence.append(f"Dochód kwalifikowany = {qualifying_income:.2f} × {nexus*100:.2f}% = {qi:.2f}")
    evidence.append(f"Podatek = {qi:.2f} × {RATE*100:.0f}% = {tax:.2f} (art. 30ca ust. 1 PIT)")

    return NexusResult(a, b, c, d, nexus, qi, tax, evidence)


def render_report(r: NexusResult) -> str:
    lines = [
        "╔══════════════════════════════════════════════════════════════════════╗",
        "║  IP BOX — KALKULATOR NEXUS (art. 30ca ust. 4-5 PIT) — DOWÓD         ║",
        "╚══════════════════════════════════════════════════════════════════════╝",
        f"  a) koszty B+R bezpośrednio związane z IP : {r.a:>12.2f} zł",
        f"  b) nabycie wyników prac B+R (niepowiązani): {r.b:>12.2f} zł",
        f"  c) nabycie IP (niepowiązani)              : {r.c:>12.2f} zł",
        f"  d) nabycie IP (powiązani, NIE kwalifikow.) : {r.d:>12.2f} zł",
        "  ─────────────────────────────────────────────────────────────",
        f"  Wskaźnik Nexus                          : {r.nexus*100:>10.2f}%",
        f"  Dochód kwalifikowany                    : {r.qualifying_income:>12.2f} zł",
        f"  Podatek 5%                              : {r.tax_5pct:>12.2f} zł",
        "  ── DOWÓD ──",
    ]
    lines += [f"  · {e}" for e in r.evidence]
    lines.append("  ─────────────────────────────────────────────────────────────")
    lines.append("  Wymogi: odrębna ewidencja (art. 30cb ust. 1) + PIT-IP (30cb ust. 4)")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — IP Box Nexus Calculator (art. 30ca)")
    p.add_argument("--a", type=float, default=0, help="koszty B+R bezpośrednio związane z IP")
    p.add_argument("--b", type=float, default=0, help="nabycie wyników prac B+R od podmiotów niepowiązanych")
    p.add_argument("--c", type=float, default=0, help="nabycie IP od podmiotów niepowiązanych")
    p.add_argument("--d", type=float, default=0, help="nabycie IP od podmiotów powiązanych (niekwalifikowane)")
    p.add_argument("--income", type=float, required=True, help="dochód z kwalifikowanego IP")
    p.add_argument("--json", action="store_true", help="wyjście JSON")
    args = p.parse_args(argv)

    res = compute_nexus(args.a, args.b, args.c, args.d, args.income)
    if args.json:
        print(json.dumps(res.to_dict(), ensure_ascii=False, indent=2))
    else:
        print(render_report(res))
    return 0


if __name__ == "__main__":
    sys.exit(main())
