"""Vendor Card — Karta dostawcy z wykresem trendów, animacjami i hover.

SUPERMOCE:
  - AnimatedContainer zamiast statycznego Card
  - Trend chart z formatowaniem kwot
  - Kolorowane alerty według severity
  - Interaktywny click do szczegółów
"""

from __future__ import annotations

import flet as ft


def build_vendor_card(vendor: dict) -> ft.Container:
    """Build an interactive vendor card with trend chart and alerts."""
    rating = int(vendor.get("rating_stars", 0))
    stars = "★" * max(0, min(5, rating)) + "☆" * max(0, 5 - rating)

    trend = vendor.get("monthly_spending", [])
    points = [ft.LineChartDataPoint(i, float(value)) for i, value in enumerate(trend)]

    alerts = vendor.get("alerts", [])

    # Kolorowane alerty według severity
    def _alert_row(alert: str) -> ft.Row:
        severity = vendor.get("alert_severity", "info")
        alert_colors = {
            "critical": ft.colors.RED_300,
            "warning": ft.colors.ORANGE_300,
            "info": ft.colors.BLUE_300,
        }
        color = alert_colors.get(severity, ft.colors.ORANGE_300)
        return ft.Row(
            [
                ft.Icon(ft.icons.WARNING_AMBER_ROUNDED, size=14, color=color),
                ft.Container(width=4),
                ft.Text(f"• {alert}", size=12, color=color),
            ]
        )

    alert_column = ft.Column(
        controls=[_alert_row(a) for a in alerts]
        if alerts
        else [ft.Text("• No active alerts", size=12, color=ft.colors.GREEN_300)],
        spacing=4,
    )

    return ft.Container(
        animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
        on_hover=lambda e: (
            setattr(e.control, "scale", 1.02 if e.data == "true" else 1.0) or e.control.update()
        ),
        content=ft.Card(
            content=ft.Container(
                padding=16,
                content=ft.Column(
                    spacing=10,
                    controls=[
                        ft.Text(
                            vendor.get("vendor_name", "Unknown vendor"),
                            size=18,
                            weight=ft.FontWeight.BOLD,
                        ),
                        ft.Text(
                            f"NIP: {vendor.get('nip', '---')}", size=12, color=ft.colors.GREY_400
                        ),
                        ft.Text(stars, size=20, color=ft.colors.AMBER_400),
                        ft.LineChart(
                            data_series=[
                                ft.LineChartData(data_points=points, curved=True, stroke_width=2)
                            ],
                            min_y=0,
                            expand=True,
                            height=110,
                            horizontal_grid_lines=ft.ChartGridLines(
                                interval=1000, color=ft.colors.GREY_800
                            ),
                            tooltip_bgcolor=ft.colors.with_opacity(0.85, ft.colors.BLACK),
                        ),
                        ft.Text("Smart Alerts", size=14, weight=ft.FontWeight.W_600),
                        alert_column,
                    ],
                ),
            )
        ),
    )
