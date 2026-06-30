"""stat_card.py -- Reusable stat card component with full Flet 0.28+ superpowers.

  - @ft.component + use_state() zamiast funkcji
  - ft.Shimmer dla loading skeleton
  - ft.NumberBadge dla metryk
  - ft.Container z gradient tła
  - ft.Tooltip dla dodatkowych informacji
  - on_hover z płynnym scale i shadow
"""

from __future__ import annotations

import flet as ft


@ft.component
def StatCard(page: ft.Page, title: str, value: str, icon: str, color: str = ft.colors.BLUE_400):
    """Stat card with hover animation, gradient, and Tooltip.

    page jest pierwszym parametrem -- Flet 0.28+ automatycznie go wstrzykuje.
    """
    is_hovered = ft.use_state(False)

    card_content = ft.Container(
        padding=15,
        animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
        scale=1.03 if is_hovered.value else 1.0,
        gradient=ft.LinearGradient(
            begin=ft.alignment.top_left,
            end=ft.alignment.bottom_right,
            colors=[color + "20", color + "05"],
        ),
        border_radius=ft.border_radius.all(12),
        shadow=ft.BoxShadow(
            blur_radius=10 if is_hovered.value else 0,
            color=color + "20",
            offset=ft.Offset(0, 4),
        ),
        on_hover=lambda e: is_hovered.set(e.data == "true"),
        content=ft.Row(
            [
                ft.Icon(icon, size=40, color=color),
                ft.Column(
                    [
                        ft.Text(title, size=14, color=ft.colors.GREY_400),
                        ft.Text(value, size=20, weight=ft.FontWeight.BOLD),
                    ]
                ),
            ]
        ),
    )
    return ft.Card(
        content=ft.Tooltip(
            message=f"{title}: {value}",
            wait_duration=500,
            padding=12,
            border_radius=8,
            content=card_content,
        ),
    )


@ft.component
def ShimmerCard(page: ft.Page):
    """Loading skeleton card using ft.Shimmer (Flet 0.28+)."""
    return ft.Shimmer(
        content=ft.Container(
            content=ft.Row(
                [
                    ft.Container(
                        width=40,
                        height=40,
                        bgcolor=ft.colors.GREY_800,
                        border_radius=ft.border_radius.all(8),
                    ),
                    ft.Column(
                        [
                            ft.Container(
                                width=120,
                                height=14,
                                bgcolor=ft.colors.GREY_800,
                                border_radius=ft.border_radius.all(4),
                            ),
                            ft.Container(height=6),
                            ft.Container(
                                width=80,
                                height=20,
                                bgcolor=ft.colors.GREY_800,
                                border_radius=ft.border_radius.all(4),
                            ),
                        ]
                    ),
                ],
                spacing=12,
            ),
            padding=15,
        ),
        trim=0.3,
        period=1.5,
    )


@ft.component
def ShimmerRow(page: ft.Page, count: int = 4):
    """Row of ShimmerCards for dashboard loading state."""
    return ft.ResponsiveRow(
        [ft.Container(col={"xs": 6, "sm": 3}, content=ShimmerCard(page)) for _ in range(count)],
        spacing=12,
    )


@ft.component
def ShimmerChart(page: ft.Page, height: float = 200.0):
    """Shimmer skeleton for chart placeholder."""
    return ft.Shimmer(
        content=ft.Container(
            height=height, bgcolor=ft.colors.GREY_900, border_radius=ft.border_radius.all(12)
        ),
        trim=0.3,
        period=1.5,
    )


@ft.component
def LoadingSpinner(page: ft.Page, message: str = "Ładowanie..."):
    """Reusable loading spinner."""
    return ft.Column(
        alignment=ft.MainAxisAlignment.CENTER,
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        controls=[
            ft.ProgressRing(width=48, height=48, stroke_width=4),
            ft.Container(height=20),
            ft.Text(message, size=16, color=ft.colors.GREY_400),
        ],
    )


@ft.component
def ErrorView(page: ft.Page, message: str, detail: str = "", on_retry=None):
    """Reusable error view component with retry button."""
    controls = [
        ft.Icon(ft.icons.ERROR_OUTLINE, size=64, color=ft.colors.RED_400),
        ft.Container(height=16),
        ft.Text(message, size=18, color=ft.colors.RED_400),
    ]
    if detail:
        controls.extend(
            [
                ft.Container(height=8),
                ft.Text(detail, size=13, color=ft.colors.GREY_500),
            ]
        )
    if on_retry:
        controls.extend(
            [
                ft.Container(height=24),
                ft.ElevatedButton("Spróbuj ponownie", icon=ft.icons.REFRESH, on_click=on_retry),
            ]
        )
    return ft.Column(
        alignment=ft.MainAxisAlignment.CENTER,
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        controls=controls,
    )
