"""
dashboard_widgets.py — Widgety dashboardu NexusAI w natywnym Flet API (v7.0.1).

Zwraca gotowe komponenty ft.Container, ft.Column do osadzenia w dashboard.
"""
from __future__ import annotations

from typing import Any

try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


def build_gamification_widget(gamification_data: dict[str, Any]) -> Any:
    """Zbuduj widget gamifikacji jako ft.Container."""
    if not HAS_FLET:
        return None

    progress = gamification_data.get("progress", 0.0)
    level_name = gamification_data.get("level_name", "Początkujący")
    level_icon = gamification_data.get("level_icon", "🏅")
    next_level = gamification_data.get("next_level_name", "MAX")
    next_icon = gamification_data.get("next_level_icon", "🏆")
    streak = gamification_data.get("login_streak", 0)
    challenge = gamification_data.get("weekly_challenge", "")
    achievements = gamification_data.get("recent_achievements", [])

    return ft.Container(
        content=ft.Column([
            ft.Row([
                ft.Text(f"{level_icon} {level_name}", size=16, weight=ft.FontWeight.BOLD),
                ft.Text(f"→ {next_icon} {next_level}", size=12, color=ft.colors.GREY_500),
            ]),
            ft.ProgressBar(value=progress, color=ft.colors.PURPLE_400, height=8),
            ft.Row([
                ft.Text(f"📄 {gamification_data.get('total_invoices', 0)}", size=12),
                ft.Text(f"🤖 {gamification_data.get('auto_post_count', 0)}", size=12),
                ft.Text(f"💰 {gamification_data.get('yearly_savings', 0):,.0f} PLN", size=12),
            ], spacing=16),
            ft.Row([
                ft.Text(f"🔥 {streak} dni z rzędu", size=12, color=ft.colors.ORANGE_400),
            ]) if streak > 0 else ft.Text(""),
            ft.Text(f"🎯 {challenge}", size=11, color=ft.colors.BLUE_400) if challenge else ft.Text(""),
            *([
                ft.Row([
                    ft.Chip(label=ft.Text(f"{a['icon']} {a['name']}", size=11)),
                ])
                for a in achievements[:3]
            ] if achievements else []),
        ], spacing=6),
        padding=12,
        border_radius=12,
        bgcolor=ft.colors.SURFACE_VARIANT,
    )


def build_financial_health_gauge(health_data: dict[str, Any] | None = None) -> Any:
    """Zbuduj wskaźnik kondycji finansowej (0-100) jako ft.Container."""
    if not HAS_FLET:
        return None

    if health_data is None:
        return ft.Container(
            content=ft.Text("📊 Brak danych o kondycji finansowej", color=ft.colors.GREY_500, size=12),
            padding=12,
            border_radius=12,
            bgcolor=ft.colors.SURFACE_VARIANT,
        )

    overall = health_data.get("overall", 0)
    if overall >= 80:
        color = ft.colors.GREEN_700
        grade = "A"
    elif overall >= 65:
        color = ft.colors.BLUE_700
        grade = "B"
    elif overall >= 50:
        color = ft.colors.ORANGE_700
        grade = "C"
    elif overall >= 35:
        color = ft.colors.RED_700
        grade = "D"
    else:
        color = ft.colors.RED_900
        grade = "F"

    return ft.Container(
        content=ft.Column([
            ft.Text("🏥 Kondycja finansowa", size=14, weight=ft.FontWeight.BOLD),
            ft.Row([
                ft.Text(f"{overall:.0f}/100", size=28, weight=ft.FontWeight.BOLD, color=color),
                ft.Text(f"Klasa {grade}", size=18, color=color),
            ]),
            ft.ProgressBar(value=overall / 100, color=color, height=10),
            ft.Row([
                ft.Text(
                    f"Płynność: {health_data.get('cash_flow_health', 0):.0f} | "
                    f"Podatki: {health_data.get('tax_efficiency', 0):.0f} | "
                    f"Rentowność: {health_data.get('profitability', 0):.0f}",
                    size=10,
                    color=ft.colors.GREY_600,
                ),
            ]),
        ], spacing=4),
        padding=12,
        border_radius=12,
        bgcolor=ft.colors.SURFACE_VARIANT,
    )


def build_tax_deadline_countdown(deadlines: list[dict[str, Any]] | None = None) -> Any:
    """Zbuduj widget odliczania do następnego terminu podatkowego."""
    if not HAS_FLET:
        return None

    if not deadlines:
        return ft.Container(
            content=ft.Text("📅 Brak nadchodzących terminów", color=ft.colors.GREY_500, size=12),
            padding=12,
            border_radius=12,
            bgcolor=ft.colors.SURFACE_VARIANT,
        )

    next_deadline = deadlines[0]
    days_left = next_deadline.get("days_left", 0)
    urgency = next_deadline.get("urgency", "normal")

    if urgency == "critical":
        bg = ft.colors.RED_50
        border = ft.border.all(1, ft.colors.RED_400)
    elif urgency == "high":
        bg = ft.colors.ORANGE_50
        border = ft.border.all(1, ft.colors.ORANGE_400)
    else:
        bg = ft.colors.SURFACE_VARIANT
        border = None

    return ft.Container(
        content=ft.Column([
            ft.Text("📅 Najbliższy termin", size=14, weight=ft.FontWeight.BOLD),
            ft.Text(next_deadline.get("name", "Brak"), size=16, weight=ft.FontWeight.BOLD),
            ft.Text(
                f"Za {days_left} dni" if days_left > 0 else "DZIŚ!",
                size=20,
                weight=ft.FontWeight.BOLD,
                color=ft.colors.RED_700 if days_left <= 3 else ft.colors.ORANGE_700,
            ),
            *([
                ft.Text(d["name"], size=10, color=ft.colors.GREY_600)
                for d in deadlines[1:4]
            ] if len(deadlines) > 1 else []),
        ], spacing=4),
        padding=12,
        border_radius=12,
        bgcolor=bg,
        border=border,
    )
