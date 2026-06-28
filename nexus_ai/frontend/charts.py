"""charts.py — Financial chart widgets using native Flet Charts.

Zastępuje: matplotlib + flet.matplotlib_chart.MatplotlibChart
Nowy:     natywne komponenty Flet Charts (BarChart, LineChart, PieChart)

SUPERMOCE:
  - Ciemny motyw zgodny z NexusAI dark theme (Catppuccin Mocha)
  - Wykresy w pełni interaktywne (Flutter — zoom, pan, tooltipy natywnie)
  - Zero zależności od matplotlib — oszczędność ~15 MB w finalnym .exe
"""

from __future__ import annotations

from typing import Any

import flet as ft

# ── Kolorystyka Catppuccin Mocha (zgodna z NexusAI dark theme) ──────────────
_BG_COLOR = ft.colors.with_opacity(0.0, "#1e1e2e")  # przezroczyste tło
_TEXT_COLOR = "#cdd6f4"
_GREEN = "#a6e3a1"
_RED = "#f38ba8"
_BLUE = "#89b4fa"
_YELLOW = "#f9e2af"
_PURPLE = "#cba6f7"
_PINK = "#f5c2e7"
_PEACH = "#fab387"
_SURFACE = "#313244"

_COLORS_CYCLE = [_GREEN, _BLUE, _PURPLE, _YELLOW, _PEACH, _PINK, _RED]

_CHART_HEIGHT = 280
_CHART_WIDTH = 500


def _axis_text_style() -> ft.TextStyle:
    return ft.TextStyle(color=_TEXT_COLOR, size=10)


def _axis_title_style() -> ft.TextStyle:
    return ft.TextStyle(color=_TEXT_COLOR, size=11, weight=ft.FontWeight.BOLD)


# ── Chart widgets ───────────────────────────────────────────────────────────


def revenue_expense_chart(
    monthly_data: list[dict[str, Any]],
    title: str = "Przychody i Koszty (miesięcznie)",
) -> ft.Container:
    """Grouped bar chart: przychody vs koszty w podziale miesięcznym.

    Args:
        monthly_data: Lista słowników z kluczami ``month``, ``revenue``, ``expense``.
        title: Tytuł wykresu.

    Returns:
        ft.Container z wykresem słupkowym Flet.
    """
    if not monthly_data:
        return _empty_chart(title, "Brak danych")

    months = [row.get("month", f"M{i}") for i, row in enumerate(monthly_data)]
    has_revenue = "revenue" in monthly_data[0] if monthly_data else False
    has_expense = "expense" in monthly_data[0] if monthly_data else False

    bar_groups: list[ft.BarChartGroup] = []

    for i, row in enumerate(monthly_data):
        rods: list[ft.BarChartRod] = []

        if has_revenue and has_expense:
            rev = float(row.get("revenue", 0))
            exp = float(row.get("expense", 0))

            rods.append(
                ft.BarChartRod(
                    from_y=0,
                    to_y=rev,
                    color=ft.colors.with_opacity(0.85, _GREEN),
                    width=14,
                    tooltip=f"Przychody: {rev:,.0f} PLN",
                )
            )
            rods.append(
                ft.BarChartRod(
                    from_y=0,
                    to_y=exp,
                    color=ft.colors.with_opacity(0.85, _RED),
                    width=14,
                    tooltip=f"Koszty: {exp:,.0f} PLN",
                )
            )
        else:
            total = float(row.get("total_gross", row.get("total", 0)))
            color = _GREEN if total >= 0 else _RED
            rods.append(
                ft.BarChartRod(
                    from_y=0,
                    to_y=total,
                    color=ft.colors.with_opacity(0.85, color),
                    width=20,
                    tooltip=f"{total:,.0f} PLN",
                )
            )

        bar_groups.append(
            ft.BarChartGroup(
                x=i,
                bar_rods=rods,
            )
        )

    max_val = (
        max(
            (abs(float(r.get("revenue", 0))) for r in monthly_data),
            default=1,
        )
        * 1.2
    )

    chart = ft.BarChart(
        bar_groups=bar_groups,
        max_y=max_val,
        interactive=True,
        tooltip_bgcolor=_SURFACE,
        border=ft.Border(
            bottom=ft.BorderSide(color=_SURFACE, width=0.5),
        ),
        left_axis=ft.ChartAxis(
            labels=_generate_axis_labels(max_val),
            labels_style=_axis_text_style(),
        ),
        bottom_axis=ft.ChartAxis(
            labels=[
                ft.ChartAxisLabel(value=i, label=ft.Text(m, style=_axis_text_style()))
                for i, m in enumerate(months)
            ],
            labels_style=_axis_text_style(),
        ),
    )

    return _wrap_chart(chart, title)


def cashflow_line_chart(
    cashflow_data: list[dict[str, Any]],
    title: str = "Prognoza przepływów pieniężnych",
) -> ft.Container:
    """Combined bar + line chart: cashflow projection.

    Args:
        cashflow_data: Lista słowników z ``period``, ``total_gross``, ``cumulative_gross``.
        title: Tytuł wykresu.

    Returns:
        ft.Container z wykresem Flet.
    """
    if not cashflow_data:
        return _empty_chart(title, "Brak danych")

    periods = []
    totals = []
    cumulatives = []
    for row in cashflow_data:
        periods.append(row.get("period", ""))
        totals.append(float(row.get("total_gross", 0)))
        cumulatives.append(float(row.get("cumulative_gross", 0)))

    max_val = max(max(totals, default=1), max(cumulatives, default=1)) * 1.2
    min_val = min(0, min(totals, default=0)) * 1.2

    # Bar chart for periodic totals
    bar_groups = [
        ft.BarChartGroup(
            x=i,
            bar_rods=[
                ft.BarChartRod(
                    from_y=0,
                    to_y=totals[i],
                    color=ft.colors.with_opacity(0.4, _BLUE),
                    width=16,
                    tooltip=f"Okresowe: {totals[i]:,.0f} PLN",
                )
            ],
        )
        for i in range(len(periods))
    ]

    bar_chart = ft.BarChart(
        bar_groups=bar_groups,
        max_y=max_val,
        min_y=min_val,
        interactive=True,
        tooltip_bgcolor=_SURFACE,
        border=ft.Border(
            bottom=ft.BorderSide(color=_SURFACE, width=0.5),
        ),
        left_axis=ft.ChartAxis(
            labels=_generate_axis_labels(max_val),
            labels_style=_axis_text_style(),
        ),
        bottom_axis=ft.ChartAxis(
            labels=[
                ft.ChartAxisLabel(value=i, label=ft.Text(p, style=_axis_text_style()))
                for i, p in enumerate(periods)
            ],
            labels_style=_axis_text_style(),
        ),
    )

    # Line chart overlay for cumulative
    line_data = ft.LineChartData(
        data_points=[ft.LineChartDataPoint(x=i, y=cumulatives[i]) for i in range(len(cumulatives))],
        stroke_width=2.5,
        color=ft.colors.with_opacity(0.9, _GREEN),
        curved=True,
        stroke_cap_round=True,
        prevent_curve_edges=True,
    )

    line_chart = ft.LineChart(
        data_series=[line_data],
        max_y=max_val,
        min_y=min_val,
        interactive=True,
        tooltip_bgcolor=_SURFACE,
        border=ft.Border(
            bottom=ft.BorderSide(color=_SURFACE, width=0.5),
        ),
        left_axis=ft.ChartAxis(
            labels=_generate_axis_labels(max_val),
            labels_style=_axis_text_style(),
        ),
        bottom_axis=ft.ChartAxis(
            labels=[
                ft.ChartAxisLabel(value=i, label=ft.Text(p, style=_axis_text_style()))
                for i, p in enumerate(periods)
            ],
            labels_style=_axis_text_style(),
        ),
    )

    # Stack both charts in a Stack with transparency
    # Line chart goes on top (transparent bg), bar chart below
    stack = ft.Stack(
        [
            bar_chart,
            ft.Container(
                content=line_chart,
                bgcolor=ft.colors.TRANSPARENT,
            ),
        ],
        height=_CHART_HEIGHT,
        width=_CHART_WIDTH,
    )

    return _wrap_chart(stack, title)


def vat_pie_chart(
    vat_data: list[dict[str, Any]],
    title: str = "Struktura VAT",
) -> ft.Container:
    """Donut chart: struktura VAT.

    Args:
        vat_data: Lista słowników z ``label``, ``value``, opcjonalnie ``color``.
        title: Tytuł wykresu.

    Returns:
        ft.Container z donut chart Flet.
    """
    if not vat_data:
        return _empty_chart(title, "Brak danych VAT")

    total = sum(float(row.get("value", 0)) for row in vat_data)
    if total == 0:
        return _empty_chart(title, "Brak wartości VAT")

    sections = []
    for i, row in enumerate(vat_data):
        value = float(row.get("value", 0))
        label = row.get("label", f"Kat {i}")
        color = row.get("color", _COLORS_CYCLE[i % len(_COLORS_CYCLE)])
        pct = (value / total) * 100

        sections.append(
            ft.PieChartSection(
                value=value,
                color=color,
                radius=100,
                title=f"{pct:.1f}%",
                title_style=ft.TextStyle(
                    color=_TEXT_COLOR,
                    size=10,
                    weight=ft.FontWeight.BOLD,
                ),
                badge=ft.Container(
                    content=ft.Text(label, size=8, color=_TEXT_COLOR),
                    bgcolor=ft.colors.with_opacity(0.7, _SURFACE),
                    border_radius=4,
                    padding=ft.padding.all(4),
                ),
            )
        )

    chart = ft.PieChart(
        sections=sections,
        center_space_radius=0.55,  # Donut hole
        sections_space=2,
        start_degree_offset=90,
        animate=True,
    )

    # Center text overlay
    center_text = ft.Container(
        content=ft.Column(
            [
                ft.Text(
                    f"{total:,.0f}",
                    color=_TEXT_COLOR,
                    size=16,
                    weight=ft.FontWeight.BOLD,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Text("Razem VAT", color=_TEXT_COLOR, size=10, text_align=ft.TextAlign.CENTER),
            ],
            spacing=0,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        alignment=ft.alignment.center,
    )

    stack = ft.Stack(
        [
            chart,
            center_text,
        ],
        width=_CHART_WIDTH,
        height=_CHART_HEIGHT,
    )

    return _wrap_chart(stack, title)


def monthly_trend_line_chart(
    trend_data: list[dict[str, Any]],
    title: str = "Trend miesięczny",
) -> ft.Container:
    """Line chart: trend miesięczny.

    Args:
        trend_data: Lista słowników z ``month``, ``total``.
        title: Tytuł wykresu.

    Returns:
        ft.Container z wykresem liniowym Flet.
    """
    if not trend_data:
        return _empty_chart(title, "Brak danych trendu")

    months = [row.get("month", "") for row in trend_data]
    totals = [float(row.get("total", 0)) for row in trend_data]

    max_val = max(totals, default=1) * 1.2
    min_val = min(0, min(totals, default=0)) * 1.2

    line_data = ft.LineChartData(
        data_points=[ft.LineChartDataPoint(x=i, y=totals[i]) for i in range(len(totals))],
        stroke_width=2.5,
        color=ft.colors.with_opacity(0.9, _BLUE),
        curved=True,
        stroke_cap_round=True,
        prevent_curve_edges=True,
    )

    chart = ft.LineChart(
        data_series=[line_data],
        max_y=max_val,
        min_y=min_val,
        interactive=True,
        tooltip_bgcolor=_SURFACE,
        border=ft.Border(
            bottom=ft.BorderSide(color=_SURFACE, width=0.5),
        ),
        left_axis=ft.ChartAxis(
            labels=_generate_axis_labels(max_val),
            labels_style=_axis_text_style(),
        ),
        bottom_axis=ft.ChartAxis(
            labels=[
                ft.ChartAxisLabel(value=i, label=ft.Text(m, style=_axis_text_style()))
                for i, m in enumerate(months)
            ],
            labels_style=_axis_text_style(),
        ),
    )

    return _wrap_chart(chart, title)


def top_suppliers_bar_chart(
    suppliers: list[dict[str, Any]],
    title: str = "Top dostawcy",
) -> ft.Container:
    """Horizontal bar chart: top suppliers by spending.

    Args:
        suppliers: Lista słowników z ``contractor_nip``, ``total_spent``.
        title: Tytuł wykresu.

    Returns:
        ft.Container z poziomym wykresem słupkowym Flet.
    """
    if not suppliers:
        return _empty_chart(title, "Brak danych")

    names = [row.get("contractor_nip", f"Dostawca {i}")[:12] for i, row in enumerate(suppliers)]
    totals = [float(row.get("total_spent", 0)) for row in suppliers]

    # Reverse for top-at-top display
    names = names[::-1]
    totals = totals[::-1]

    max_val = max(totals, default=1) * 1.3

    bar_groups = [
        ft.BarChartGroup(
            x=i,
            bar_rods=[
                ft.BarChartRod(
                    from_y=0,
                    to_y=totals[i],
                    color=ft.colors.with_opacity(0.85, _COLORS_CYCLE[i % len(_COLORS_CYCLE)]),
                    width=20,
                    tooltip=f"{names[i]}: {totals[i]:,.0f} PLN",
                )
            ],
        )
        for i in range(len(names))
    ]

    chart = ft.BarChart(
        bar_groups=bar_groups,
        max_y=max_val,
        interactive=True,
        tooltip_bgcolor=_SURFACE,
        border=ft.Border(
            bottom=ft.BorderSide(color=_SURFACE, width=0.5),
        ),
        left_axis=ft.ChartAxis(
            labels=[
                ft.ChartAxisLabel(value=i, label=ft.Text(n, style=_axis_text_style()))
                for i, n in enumerate(names)
            ],
            labels_style=_axis_text_style(),
        ),
        bottom_axis=ft.ChartAxis(
            labels=_generate_axis_labels(max_val),
            labels_style=_axis_text_style(),
        ),
    )

    return _wrap_chart(chart, title)


# ── Helper functions ────────────────────────────────────────────────────────


def _generate_axis_labels(max_val: float, steps: int = 5) -> list[ft.ChartAxisLabel]:
    """Generate evenly spaced axis labels from 0 to max_val.

    Args:
        max_val: Maksymalna wartość na osi.
        steps: Liczba kroków (etykiet).

    Returns:
        Lista obiektów ChartAxisLabel.
    """
    if max_val <= 0:
        return [ft.ChartAxisLabel(value=0, label=ft.Text("0", style=_axis_text_style()))]

    step = max_val / steps
    labels = []
    for i in range(steps + 1):
        val = round(i * step, 0)
        labels.append(
            ft.ChartAxisLabel(
                value=val,
                label=ft.Text(f"{val:,.0f}", style=_axis_text_style()),
            )
        )
    return labels


def _empty_chart(title: str, message: str) -> ft.Container:
    """Create an empty chart placeholder with a message.

    Args:
        title: Tytuł wyświetlany nad pustym wykresem.
        message: Komunikat o braku danych.

    Returns:
        ft.Container z pustym wykresem.
    """
    return ft.Container(
        content=ft.Column(
            [
                ft.Text(title, style=_axis_title_style(), text_align=ft.TextAlign.CENTER),
                ft.Container(height=20),
                ft.Text(message, color=_TEXT_COLOR, size=14, text_align=ft.TextAlign.CENTER),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        bgcolor=ft.colors.TRANSPARENT,
        padding=ft.padding.all(20),
        height=_CHART_HEIGHT,
    )


def _wrap_chart(chart: ft.Control, title: str) -> ft.Container:
    """Wrap a chart control in a styled container with title.

    Args:
        chart: Główny kontrolka wykresu (BarChart, LineChart, PieChart, Stack).
        title: Tytuł wyświetlany nad wykresem.

    Returns:
        ft.Container z tytułem i wykresem.
    """
    return ft.Container(
        content=ft.Column(
            [
                ft.Text(
                    title,
                    style=_axis_title_style(),
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(
                    content=chart,
                    expand=True,
                ),
            ],
            spacing=8,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        bgcolor=ft.colors.with_opacity(0.05, "#ffffff"),
        border_radius=12,
        padding=ft.padding.all(16),
        margin=ft.margin.all(8),
        expand=True,
    )
