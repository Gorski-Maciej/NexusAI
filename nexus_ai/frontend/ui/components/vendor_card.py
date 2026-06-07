from __future__ import annotations

import flet as ft


def build_vendor_card(vendor: dict) -> ft.Card:
    rating = int(vendor.get("rating_stars", 0))
    stars = "★" * max(0, min(5, rating)) + "☆" * max(0, 5 - rating)

    trend = vendor.get("monthly_spending", [])
    points = [ft.LineChartDataPoint(i, float(value)) for i, value in enumerate(trend)]

    alerts = vendor.get("alerts", [])
    alert_column = ft.Column(
        controls=[ft.Text(f"• {alert}", size=12, color=ft.colors.ORANGE_300) for alert in alerts]
        or [ft.Text("• No active alerts", size=12, color=ft.colors.GREEN_300)],
        spacing=4,
    )

    return ft.Card(
        content=ft.Container(
            padding=16,
            content=ft.Column(
                spacing=10,
                controls=[
                    ft.Text(vendor.get("vendor_name", "Unknown vendor"), size=18, weight=ft.FontWeight.BOLD),
                    ft.Text(f"NIP: {vendor.get('nip', '---')}", size=12, color=ft.colors.GREY_400),
                    ft.Text(stars, size=20, color=ft.colors.AMBER_400),
                    ft.LineChart(
                        data_series=[ft.LineChartData(data_points=points, curved=True, stroke_width=2)],
                        min_y=0,
                        expand=True,
                        height=110,
                        horizontal_grid_lines=ft.ChartGridLines(interval=1000, color=ft.colors.GREY_800),
                        tooltip_bgcolor=ft.colors.with_opacity(0.85, ft.colors.BLACK),
                    ),
                    ft.Text("Smart Alerts", size=14, weight=ft.FontWeight.W_600),
                    alert_column,
                ],
            ),
        )
    )
