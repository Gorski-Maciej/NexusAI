#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GLM52 — brd_project_tracker.py
# Tracker projektów B+R: karty projektu (koszty kwalifikowane, limity, status),
# ewidencja czasu pracy (art. 26e ust. 2 pkt 1 — min. 50% czasu na B+R),
# auto-kalkulacja 100%/200% (centrum B+R), ryzyko odliczenia.
# ═══════════════════════════════════════════════════════════════════════════════
"""Tracker projektów B+R (art. 26e PIT, art. 5a pkt 38-40 PIT).

Każdy projekt to karta z kosztami wg kategorii art. 26e ust. 2:
  pkt 1  — wynagrodzenia personelu B+R (+ składki ZUS)
  pkt 1a — umowy cywilnoprawne
  pkt 2  — materiały i surowce
  pkt 3  — ekspertyzy, opinie, doradztwo
  pkt 4  — odpisy amortyzacyjne
  pkt 5  — koszty uzyskania patentu (art. 26e ust. 2 pkt 5)

Limity: odliczenie ≤ dochód z działalności B+R (art. 26e ust. 6);
200% dla centrum B+R (art. 26e ust. 7).
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# kategorie kosztów kwalifikowanych: klucz → (nazwa, punkt art. 26e)
COST_CATEGORIES: dict[str, tuple[str, str]] = {
    "staff": ("Wynagrodzenia personelu B+R", "art. 26e ust. 2 pkt 1"),
    "zus": ("Składki ZUS od wynagrodzeń B+R", "art. 26e ust. 2 pkt 1"),
    "contracts": ("Umowy cywilnoprawne B+R", "art. 26e ust. 2 pkt 1a"),
    "materials": ("Materiały i surowce", "art. 26e ust. 2 pkt 2"),
    "expertise": ("Ekspertyzy, opinie, doradztwo", "art. 26e ust. 2 pkt 3"),
    "depreciation": ("Odpisy amortyzacyjne", "art. 26e ust. 2 pkt 4"),
    "patent": ("Koszty uzyskania patentu", "art. 26e ust. 2 pkt 5"),
}


@dataclass
class ProjectCard:
    """Karta projektu B+R."""
    project_id: str
    name: str
    year: int
    is_rd_center: bool = False
    costs: dict[str, float] = field(default_factory=dict)
    staff_brd_percent: float = 0.0  # % czasu personelu na B+R (wymóg min. 50)
    active: bool = True

    @property
    def total_qualifying(self) -> float:
        return round(sum(max([0.0, v]) for v in self.costs.values()), 2)

    def deduction(self) -> float:
        rate = 2.0 if self.is_rd_center else 1.0
        return round(self.total_qualifying * rate, 2)

    def risks(self) -> list[str]:
        r: list[str] = []
        if self.staff_brd_percent < 50 and self.costs.get("staff", 0) > 0:
            r.append(f"Personel B+R: tylko {self.staff_brd_percent:.0f}% czasu na B+R "
                     "(wymóg min. 50% — art. 26e ust. 2 pkt 1)")
        if self.costs.get("staff", 0) > 0 and "zus" not in self.costs:
            r.append("Brak składek ZUS przy wynagrodzeniach — pamiętaj o składkach od personelu B+R")
        return r

    def to_dict(self) -> dict[str, Any]:
        return {
            "project_id": self.project_id,
            "name": self.name,
            "year": self.year,
            "is_rd_center": self.is_rd_center,
            "costs": {k: round(v, 2) for k, v in self.costs.items()},
            "costs_detail": {k: {"label": COST_CATEGORIES[k][0], "legal": COST_CATEGORIES[k][1],
                                 "amount": round(v, 2)} for k, v in self.costs.items() if v > 0},
            "total_qualifying": self.total_qualifying,
            "deduction_rate": 2.0 if self.is_rd_center else 1.0,
            "deduction": self.deduction(),
            "staff_brd_percent": self.staff_brd_percent,
            "risks": self.risks(),
            "active": self.active,
        }


def compute_tracker(projects: list[dict[str, Any]], rd_income: float) -> dict[str, Any]:
    """Oblicza tracker projektów + limit odliczenia (art. 26e ust. 6)."""
    cards: list[ProjectCard] = []
    for p in projects:
        card = ProjectCard(
            project_id=str(p.get("project_id", "")),
            name=str(p.get("name", "")),
            year=int(p.get("year", 0)),
            is_rd_center=bool(p.get("is_rd_center", False)),
            costs={k: float(v) for k, v in p.get("costs", {}).items()},
            staff_brd_percent=float(p.get("staff_brd_percent", 0) or 0),
            active=bool(p.get("active", True)),
        )
        cards.append(card)

    total_deduction = round(sum(c.deduction() for c in cards), 2)
    limit = max([0.0, rd_income])
    excess = max([total_deduction - limit, 0.0])

    result = {
        "tool": "brd_project_tracker",
        "campaign": "P07_GLM52_ULGI_OPTYMALIZACJA",
        "projects": [c.to_dict() for c in cards],
        "summary": {
            "project_count": len(cards),
            "total_qualifying_costs": round(sum(c.total_qualifying for c in cards), 2),
            "total_deduction": total_deduction,
            "rd_income_limit": limit,
            "excess_over_limit": round(excess, 2),
            "limit_note": "Odliczenie ≤ dochód z działalności B+R (art. 26e ust. 6 PIT)",
        },
        "risks": [r for c in cards for r in c.risks()],
    }
    return result


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — Tracker projektów B+R (art. 26e)")
    p.add_argument("--projects", required=True, help="ścieżka do JSON z listą projektów")
    p.add_argument("--rd-income", type=float, default=0, help="dochód z działalności B+R (limit art. 26e ust. 6)")
    p.add_argument("--out", help="zapis wyniku do pliku JSON")
    args = p.parse_args(argv)

    raw = json.loads(Path(args.projects).read_text(encoding="utf-8"))
    # akceptuj pojedynczy projekt lub listę projektów
    projects = raw if isinstance(raw, list) else [raw]
    result = compute_tracker(projects, args.rd_income)
    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano tracker {result['summary']['project_count']} projektów do {args.out}")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
