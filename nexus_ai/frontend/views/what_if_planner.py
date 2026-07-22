"""
what_if_planner.py — F3.1 v7.0 Audit: What-If Scenario Planner UI + Financial Health Score.

Raport v7.0 Pomysl #8: "Co by bylo gdybym..."
  - "Zmienil forme opodatkowania na ryczalt?"
  - "Zatrudnil pracownika?"
  - "Kupil samochod na firme?"

DuckDB Shadow Ledger symuluje wszystkie scenariusze.
Przedsiebiorca widzi REALNE kwoty w kazdym scenariuszu.
Financial Health Score: A-F z kolorowym wskaznikiem.
"""

from __future__ import annotations

from typing import Any
from dataclasses import dataclass, field

try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


# ═══════════════════════════════════════════════════════════════════════════════
# Financial Health Score Colors
# ═══════════════════════════════════════════════════════════════════════════════

HEALTH_GRADE_COLORS = {
    "A": "#238636",  # Green
    "B": "#3FB950",
    "C": "#D29922",  # Yellow
    "D": "#F0883E",  # Orange
    "F": "#DA3633",  # Red
}

HEALTH_ICONS = {
    "A": "🌟",
    "B": "✅",
    "C": "⚠️",
    "D": "🔶",
    "F": "🔴",
}


# ═══════════════════════════════════════════════════════════════════════════════
# What-If Planner View
# ═══════════════════════════════════════════════════════════════════════════════


class WhatIfPlannerView:
    """What-If Scenario Planner — symulacja alternatywnych scenariuszy biznesowych.

    Enterprise v7.0 Pomysl #8:
    Przedsiebiorca wybiera scenariusz → DuckDB symuluje skutki → widzi REALNE kwoty.
    """

    def __init__(self):
        self._scenarios: list[dict[str, Any]] = []
        self._baseline: dict[str, float] = {"revenue": 0, "costs": 0, "tax": 0, "net": 0}

    def set_baseline(self, revenue: float, costs: float, tax: float, net: float) -> None:
        """Ustaw scenariusz bazowy (obecna sytuacja)."""
        self._baseline = {"revenue": revenue, "costs": costs, "tax": tax, "net": net}

    def build(self) -> Any:
        """Zbuduj widok Flet What-If Planner."""
        if not HAS_FLET:
            return None

        # ── Scenario cards ─────────────────────────────────────────────
        scenario_cards = []
        for sc in self._scenarios:
            delta = sc.get("delta_vs_baseline", 0)
            is_positive = delta > 0
            arrow = "📈" if is_positive else "📉"
            color = "#238636" if is_positive else "#DA3633"

            scenario_cards.append(
                ft.Container(
                    content=ft.Column([
                        ft.Row([
                            ft.Text(arrow, size=24),
                            ft.Column([
                                ft.Text(sc.get("scenario", "Scenariusz"), size=15, weight=ft.FontWeight.BOLD, color="#E6EDF3"),
                                ft.Text(
                                    f"{'✅ Lepszy o' if is_positive else '❌ Gorszy o'} {abs(delta):,.0f} PLN vs obecny",
                                    size=13, color=color,
                                ),
                            ], spacing=2),
                        ], spacing=12),
                        ft.Container(height=8),
                        ft.Row([
                            _stat_chip("Przychód", f"{sc.get('revenue', 0):,.0f} PLN"),
                            _stat_chip("Koszty", f"{sc.get('costs', 0):,.0f} PLN"),
                            _stat_chip("Podatek", f"{sc.get('tax', 0):,.0f} PLN"),
                        ], spacing=8, wrap=True),
                        ft.Container(height=8),
                        ft.Text(
                            f"Netto: {sc.get('net', 0):,.0f} PLN",
                            size=18, weight=ft.FontWeight.BOLD, color="#E6EDF3",
                        ),
                    ]),
                    padding=ft.padding.all(16),
                    border_radius=ft.border_radius.all(12),
                    bgcolor="#161B22",
                    border=ft.border.all(1, "#30363D"),
                    margin=ft.margin.only(bottom=12),
                )
            )

        return ft.Container(
            content=ft.Column([
                ft.Row([
                    ft.Icon(ft.icons.SCIENCE, color="#D29922", size=24),
                    ft.Text("What-If Scenario Planner", size=20, weight=ft.FontWeight.BOLD, color="#E6EDF3"),
                ]),
                ft.Container(height=4),
                ft.Text(
                    "Symuluj alternatywne scenariusze biznesowe i zobacz realne skutki finansowe",
                    size=13, color="#8B949E",
                ),
                ft.Container(height=16),
                # Baseline card
                _baseline_card(self._baseline),
                ft.Container(height=16),
                # Scenario results
                *(scenario_cards if scenario_cards else [
                    ft.Container(
                        content=ft.Column([
                            ft.Icon(ft.icons.ADD_CIRCLE_OUTLINE, size=40, color="#30363D"),
                            ft.Text("Dodaj scenariusz aby zobaczyć porównanie", size=14, color="#8B949E"),
                        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                        padding=ft.padding.all(32),
                        border_radius=ft.border_radius.all(12),
                        bgcolor="#161B22",
                        border=ft.border.all(1, "#30363D"),
                    )
                ]),
            ], spacing=0),
            padding=ft.padding.all(24),
            expand=True,
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Financial Health Score Card
# ═══════════════════════════════════════════════════════════════════════════════


class FinancialHealthCard:
    """Karta Financial Health Score — scoring kondycji finansowej A-F.

    Enterprise v7.0 Pomysl #11:
    Kompleksowy scoring: cash flow, tax efficiency, profitability, risk.
    """

    def __init__(self, health_data: dict[str, float] | None = None):
        self._data = health_data or {
            "cash_flow_health": 75.0,
            "tax_efficiency": 82.0,
            "profitability": 68.0,
            "risk_exposure": 55.0,
            "overall": 72.0,
            "grade": "B — Dobra",
        }

    def update(self, data: dict[str, float]) -> None:
        """Aktualizuj dane scoringu."""
        self._data = data

    def build(self) -> Any:
        """Zbuduj karte Financial Health Score."""
        if not HAS_FLET:
            return None

        overall = self._data.get("overall", 0)
        grade = self._data.get("grade", "C")
        grade_letter = grade[0] if grade else "C"
        grade_color = HEALTH_GRADE_COLORS.get(grade_letter, "#D29922")
        icon = HEALTH_ICONS.get(grade_letter, "⚠️")

        metrics = [
            ("Płynność", self._data.get("cash_flow_health", 0), "#238636"),
            ("Efektywność podatkowa", self._data.get("tax_efficiency", 0), "#3FB950"),
            ("Rentowność", self._data.get("profitability", 0), "#D29922"),
            ("Ryzyko", 100 - self._data.get("risk_exposure", 0), "#DA3633"),
        ]

        metric_bars = []
        for label, value, color in metrics:
            metric_bars.append(
                ft.Column([
                    ft.Row([
                        ft.Text(label, size=12, color="#8B949E"),
                        ft.Container(expand=True),
                        ft.Text(f"{value:.0f}/100", size=12, weight=ft.FontWeight.BOLD, color=color),
                    ]),
                    ft.Container(height=2),
                    ft.ProgressBar(value=value / 100, color=color, bgcolor="#21262D", height=6, border_radius=3),
                    ft.Container(height=8),
                ], spacing=0)
            )

        return ft.Container(
            content=ft.Column([
                # Header with grade
                ft.Row([
                    ft.Text(icon, size=32),
                    ft.Column([
                        ft.Text("Financial Health Score", size=16, weight=ft.FontWeight.BOLD, color="#E6EDF3"),
                        ft.Text(grade, size=13, color=grade_color, weight=ft.FontWeight.BOLD),
                    ], spacing=2),
                    ft.Container(expand=True),
                    ft.Container(
                        content=ft.Text(f"{overall:.0f}", size=28, weight=ft.FontWeight.BOLD, color=grade_color),
                        padding=ft.padding.all(12),
                        border_radius=ft.border_radius.all(50),
                        bgcolor=f"{grade_color}20",
                    ),
                ]),
                ft.Container(height=16),
                *metric_bars,
            ]),
            padding=ft.padding.all(20),
            border_radius=ft.border_radius.all(14),
            bgcolor="#161B22",
            border=ft.border.all(1, "#30363D"),
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════════


def _baseline_card(baseline: dict[str, float]) -> Any:
    """Karta scenariusza bazowego."""
    return ft.Container(
        content=ft.Column([
            ft.Row([
                ft.Icon(ft.icons.HOME, color="#58A6FF", size=20),
                ft.Text("OBECNA SYTUACJA", size=13, weight=ft.FontWeight.BOLD, color="#58A6FF"),
            ]),
            ft.Container(height=8),
            ft.Row([
                _stat_chip("Przychód", f"{baseline.get('revenue', 0):,.0f} PLN"),
                _stat_chip("Koszty", f"{baseline.get('costs', 0):,.0f} PLN"),
                _stat_chip("Podatek", f"{baseline.get('tax', 0):,.0f} PLN"),
            ], spacing=8, wrap=True),
            ft.Container(height=8),
            ft.Text(
                f"Netto: {baseline.get('net', 0):,.0f} PLN",
                size=18, weight=ft.FontWeight.BOLD, color="#E6EDF3",
            ),
        ]),
        padding=ft.padding.all(16),
        border_radius=ft.border_radius.all(12),
        bgcolor="#0D419D",
        border=ft.border.all(1, "#58A6FF"),
    )


def _stat_chip(label: str, value: str) -> Any:
    """Chip ze statystyka."""
    return ft.Container(
        content=ft.Column([
            ft.Text(label, size=10, color="#8B949E"),
            ft.Text(value, size=12, weight=ft.FontWeight.BOLD, color="#E6EDF3"),
        ], spacing=1),
        padding=ft.padding.symmetric(horizontal=12, vertical=8),
        border_radius=ft.border_radius.all(8),
        bgcolor="#21262D",
    )
