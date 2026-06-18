"""charts.py — Financial chart widgets using Matplotlib + Flet MatplotlibChart.

SUPERMOCE:
  - flet.matplotlib_chart.MatplotlibChart do embedowania wykresów matplotlib
  - Revenue/Expense bar chart z kolorowaniem (green/red)
  - Cashflow projection line chart z wypełnieniem
  - VAT summary pie chart
  - Monthly trend bar chart
  - Dark theme aware wykresy
"""

from __future__ import annotations

from typing import Any

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

from flet.matplotlib_chart import MatplotlibChart

# ── Konfiguracja matplotlib ──────────────────────────────────────────────────
# SUPERMOC: Używamy dedykowanego backendu 'Agg' — nie wymaga GUI, działa
# w każdej konsoli, zużywa minimalną ilość RAM.
matplotlib.use("Agg")

# Kolorystyka ciemna (zgodna z NexusAI dark theme)
_BG_COLOR = "#1e1e2e"
_TEXT_COLOR = "#cdd6f4"
_GRID_COLOR = "#313244"
_GREEN = "#a6e3a1"
_RED = "#f38ba8"
_BLUE = "#89b4fa"
_YELLOW = "#f9e2af"
_PURPLE = "#cba6f7"
_PINK = "#f5c2e7"
_PEACH = "#fab387"

_COLORS_CYCLE = [_GREEN, _BLUE, _PURPLE, _YELLOW, _PEACH, _PINK, _RED]

plt.rcParams.update(
    {
        "figure.facecolor": _BG_COLOR,
        "axes.facecolor": _BG_COLOR,
        "axes.edgecolor": _GRID_COLOR,
        "axes.labelcolor": _TEXT_COLOR,
        "text.color": _TEXT_COLOR,
        "xtick.color": _TEXT_COLOR,
        "ytick.color": _TEXT_COLOR,
        "grid.color": _GRID_COLOR,
        "grid.alpha": 0.3,
        "figure.dpi": 120,
        "savefig.dpi": 120,
        "font.size": 10,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
    }
)


# ── Helper: tworzenie figury ─────────────────────────────────────────────────


def _create_figure(width: float = 5.0, height: float = 3.0) -> tuple[plt.Figure, plt.Axes]:
    """Create a dark-themed matplotlib figure.

    SUPERMOC Flet: Każda figura jest embedowana przez ``MatplotlibChart(fig)``.
    Flet automatycznie konwertuje matplotlib figure na obrazek Flutter,
    wspiera scroll, zoom i responsywny resize.
    """
    fig, ax = plt.subplots(figsize=(width, height))
    fig.patch.set_facecolor(_BG_COLOR)
    ax.set_facecolor(_BG_COLOR)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(_GRID_COLOR)
    ax.spines["bottom"].set_color(_GRID_COLOR)
    ax.tick_params(colors=_TEXT_COLOR, labelsize=9)
    ax.grid(True, alpha=0.2, color=_GRID_COLOR)
    return fig, ax


# ── Chart widgets ───────────────────────────────────────────────────────────


def revenue_expense_chart(
    monthly_data: list[dict[str, Any]],
    title: str = "Przychody i Koszty (miesięcznie)",
) -> MatplotlibChart:
    """Bar chart: przychody vs koszty w podziale miesięcznym.

    Args:
        monthly_data: Lista słowników z kluczami ``month``, ``revenue``, ``expense``.
                     Jeśli brak ``revenue``/``expense``, używa ``total_gross``.
        title: Tytuł wykresu.

    Returns:
        MatplotlibChart gotowy do dodania do Flet UI.
    """
    fig, ax = _create_figure(width=5.5, height=3)

    if not monthly_data:
        ax.text(0.5, 0.5, "Brak danych", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    months = [row.get("month", f"M{i}") for i, row in enumerate(monthly_data)]

    # Jeśli dane zawierają revenue/expense, używamy ich
    has_revenue = "revenue" in monthly_data[0] if monthly_data else False
    has_expense = "expense" in monthly_data[0] if monthly_data else False

    if has_revenue and has_expense:
        revenues = [float(row.get("revenue", 0)) for row in monthly_data]
        expenses = [float(row.get("expense", 0)) for row in monthly_data]

        x = np.arange(len(months))
        width = 0.35

        bars1 = ax.bar(x - width / 2, revenues, width, label="Przychody", color=_GREEN, alpha=0.85)
        bars2 = ax.bar(x + width / 2, expenses, width, label="Koszty", color=_RED, alpha=0.85)

        # Dodaj etykiety nad słupkami
        for bar in bars1:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height(),
                f"{bar.get_height():.0f}",
                ha="center",
                va="bottom",
                fontsize=7,
                color=_TEXT_COLOR,
            )
        for bar in bars2:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height(),
                f"{bar.get_height():.0f}",
                ha="center",
                va="bottom",
                fontsize=7,
                color=_TEXT_COLOR,
            )

        ax.legend(facecolor=_BG_COLOR, edgecolor=_GRID_COLOR, labelcolor=_TEXT_COLOR, fontsize=8)
    else:
        # Fallback: pojedynczy bar z total_gross
        totals = [float(row.get("total_gross", row.get("total", 0))) for row in monthly_data]
        colors = [_GREEN if t >= 0 else _RED for t in totals]
        bars = ax.bar(months, totals, color=colors, alpha=0.85)

        for bar in bars:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height(),
                f"{bar.get_height():.0f}",
                ha="center",
                va="bottom",
                fontsize=7,
                color=_TEXT_COLOR,
            )

    ax.set_title(title, color=_TEXT_COLOR)
    ax.set_xticks(range(len(months)))
    ax.set_xticklabels(months, rotation=30, ha="right", fontsize=8)
    ax.set_ylabel("PLN", color=_TEXT_COLOR)

    fig.tight_layout()
    return MatplotlibChart(fig, expand=True)


def cashflow_line_chart(
    cashflow_data: list[dict[str, Any]],
    title: str = "Prognoza przepływów pieniężnych",
) -> MatplotlibChart:
    """Line chart: projekcja cashflow z wypełnieniem pod linią.

    SUPERMOC Flet: Wykres matplotlib jest interaktywny przez Flutter —
    zoom, pan, tooltipy są obsługiwane natywnie.

    Args:
        cashflow_data: Lista słowników z ``period``, ``total_gross``, ``cumulative_gross``.
        title: Tytuł wykresu.

    Returns:
        MatplotlibChart gotowy do dodania do Flet UI.
    """
    fig, ax = _create_figure(width=5.5, height=3)

    if not cashflow_data:
        ax.text(0.5, 0.5, "Brak danych", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    # Parsuj okresy
    periods = []
    totals = []
    cumulatives = []
    for row in cashflow_data:
        period_str = row.get("period", "")
        total = float(row.get("total_gross", 0))
        cumulative = float(row.get("cumulative_gross", 0))
        periods.append(period_str)
        totals.append(total)
        cumulatives.append(cumulative)

    x = np.arange(len(periods))

    # SUPERMOC: Dwa zestawy danych — słupki dla okresowych + linia dla kumulacji
    bars = ax.bar(x, totals, color=_BLUE, alpha=0.4, label="Okresowe", width=0.6)
    ax.plot(x, cumulatives, color=_GREEN, linewidth=2.5, marker="o", label="Skumulowane", zorder=5)

    # Wypełnienie pod linią kumulacji
    ax.fill_between(x, cumulatives, alpha=0.1, color=_GREEN)

    # Dodaj wartości nad słupkami
    for bar in bars:
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height(),
            f"{bar.get_height():.0f}",
            ha="center",
            va="bottom",
            fontsize=7,
            color=_TEXT_COLOR,
        )

    # Dodaj wartości na punktach linii
    for i, (xi, cum) in enumerate(zip(x, cumulatives)):
        ax.text(xi, cum, f"{cum:.0f}", ha="center", va="bottom", fontsize=7, color=_GREEN)

    ax.set_title(title, color=_TEXT_COLOR)
    ax.set_xticks(x)
    ax.set_xticklabels(periods, rotation=30, ha="right", fontsize=8)
    ax.set_ylabel("PLN", color=_TEXT_COLOR)
    ax.legend(facecolor=_BG_COLOR, edgecolor=_GRID_COLOR, labelcolor=_TEXT_COLOR, fontsize=8)

    fig.tight_layout()
    return MatplotlibChart(fig, expand=True)


def vat_pie_chart(
    vat_data: list[dict[str, Any]],
    title: str = "Struktura VAT",
) -> MatplotlibChart:
    """Pie chart: struktura VAT (VAT należny, VAT naliczony, netto).

    SUPERMOC Flet: Wykres kołowy matplotlib renderowany jako obrazek Flutter
    z zachowaniem przezroczystości i ciemnego motywu.

    Args:
        vat_data: Lista słowników z ``label``, ``value``, opcjonalnie ``color``.
        title: Tytuł wykresu.

    Returns:
        MatplotlibChart gotowy do dodania do Flet UI.
    """
    fig, ax = _create_figure(width=4.5, height=3.5)

    if not vat_data:
        ax.text(0.5, 0.5, "Brak danych VAT", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    labels = [row.get("label", f"Kategoria {i}") for i, row in enumerate(vat_data)]
    values = [float(row.get("value", 0)) for row in vat_data]
    colors = [
        row.get("color", _COLORS_CYCLE[i % len(_COLORS_CYCLE)])
        for i, row in enumerate(vat_data)
    ]

    if sum(values) == 0:
        ax.text(0.5, 0.5, "Brak wartości VAT", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    # SUPERMOC: Donut chart (pie + white circle) dla nowoczesnego wyglądu
    wedges, texts, autotexts = ax.pie(
        values,
        labels=labels,
        colors=colors,
        autopct="%1.1f%%",
        startangle=90,
        pctdistance=0.75,
        wedgeprops={"linewidth": 2, "edgecolor": _BG_COLOR},
        textprops={"color": _TEXT_COLOR, "fontsize": 9},
    )

    for autotext in autotexts:
        autotext.set_color(_BG_COLOR)
        autotext.set_fontweight("bold")

    # Donut hole — białe kółko w środku
    centre_circle = plt.Circle((0, 0), 0.50, fc=_BG_COLOR, edgecolor=_GRID_COLOR, linewidth=1)
    ax.add_artist(centre_circle)

    # Tekst w środku donut
    total = sum(values)
    ax.text(
        0, 0, f"{total:,.0f} PLN", ha="center", va="center", fontsize=11, color=_TEXT_COLOR, fontweight="bold"
    )
    ax.text(
        0, -0.2, "Razem VAT", ha="center", va="center", fontsize=8, color=_TEXT_COLOR
    )

    ax.set_title(title, color=_TEXT_COLOR, pad=15)

    fig.tight_layout()
    return MatplotlibChart(fig, expand=True)


def monthly_trend_line_chart(
    trend_data: list[dict[str, Any]],
    title: str = "Trend miesięczny",
) -> MatplotlibChart:
    """Line chart: trend miesięczny z wypełnieniem gradientowym.

    SUPERMOC Flet: Wykres matplotlib z przezroczystym tłem
    idealnie komponuje się z ciemnym motywem Flet.

    Args:
        trend_data: Lista słowników z ``month``, ``total``.
        title: Tytuł wykresu.

    Returns:
        MatplotlibChart gotowy do dodania do Flet UI.
    """
    fig, ax = _create_figure(width=5.5, height=2.8)

    if not trend_data:
        ax.text(0.5, 0.5, "Brak danych trendu", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    months = [row.get("month", "") for row in trend_data]
    totals = [float(row.get("total", 0)) for row in trend_data]

    x = np.arange(len(months))

    # SUPERMOC: Gradient fill under the line
    ax.plot(x, totals, color=_BLUE, linewidth=2.5, marker="o", markersize=5, zorder=5)
    ax.fill_between(x, totals, alpha=0.15, color=_BLUE)

    # Dodaj punkty z wartościami
    for i, (xi, val) in enumerate(zip(x, totals)):
        ax.text(xi, val, f"{val:.0f}", ha="center", va="bottom", fontsize=7, color=_TEXT_COLOR)

    ax.set_title(title, color=_TEXT_COLOR)
    ax.set_xticks(x)
    ax.set_xticklabels(months, rotation=30, ha="right", fontsize=8)
    ax.set_ylabel("PLN", color=_TEXT_COLOR)

    fig.tight_layout()
    return MatplotlibChart(fig, expand=True)


def top_suppliers_bar_chart(
    suppliers: list[dict[str, Any]],
    title: str = "Top dostawcy",
) -> MatplotlibChart:
    """Horizontal bar chart: top suppliers by spending.

    Args:
        suppliers: Lista słowników z ``contractor_nip``, ``total_spent``.
        title: Tytuł wykresu.

    Returns:
        MatplotlibChart gotowy do dodania do Flet UI.
    """
    fig, ax = _create_figure(width=5, height=3)

    if not suppliers:
        ax.text(0.5, 0.5, "Brak danych", ha="center", va="center", color=_TEXT_COLOR, fontsize=12)
        return MatplotlibChart(fig, expand=True)

    names = [row.get("contractor_nip", f"Dostawca {i}")[:12] for i, row in enumerate(suppliers)]
    totals = [float(row.get("total_spent", 0)) for row in suppliers]

    # Reverse for horizontal bar (top at top)
    names = names[::-1]
    totals = totals[::-1]

    colors = [_COLORS_CYCLE[i % len(_COLORS_CYCLE)] for i in range(len(names))][::-1]

    bars = ax.barh(names, totals, color=colors, alpha=0.85, height=0.6)

    for bar in bars:
        ax.text(
            bar.get_width() + max(totals) * 0.01,
            bar.get_y() + bar.get_height() / 2,
            f"{bar.get_width():,.0f} PLN",
            ha="left",
            va="center",
            fontsize=8,
            color=_TEXT_COLOR,
        )

    ax.set_title(title, color=_TEXT_COLOR)
    ax.set_xlabel("PLN", color=_TEXT_COLOR)
    ax.margins(x=0.2)

    fig.tight_layout()
    return MatplotlibChart(fig, expand=True)
