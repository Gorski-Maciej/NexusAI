"""team/components/stat_card.py — Reusable stat card component with hover animation.

SUPERMOC Flet:
  - Animated Container z płynnym scale na hover
  - Typowane parametry (str, str, str)
  - Responsywny przez col={...} przy użyciu z ResponsiveRow
"""

from __future__ import annotations

import flet as ft


def stat_card(title: str, value: str, icon: str) -> ft.Card:
    """Stat card with hover animation and icon."""
    return ft.Card(
        content=ft.Container(
            padding=15,
            animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
            on_hover=lambda e: (
                setattr(e.control, "scale", 1.03 if e.data == "true" else 1.0)
                or e.control.update()
            ),
            content=ft.Row(
                [
                    ft.Icon(icon, size=40, color=ft.colors.BLUE_400),
                    ft.Column(
                        [
                            ft.Text(title, size=14, color=ft.colors.GREY_400),
                            ft.Text(value, size=20, weight=ft.FontWeight.BOLD),
                        ]
                    ),
                ]
            ),
        )
    )


def loading_spinner(message: str = "Ładowanie...") -> ft.Column:
    """Reusable loading spinner component."""
    return ft.Column(
        alignment=ft.MainAxisAlignment.CENTER,
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        controls=[
            ft.ProgressRing(width=48, height=48, stroke_width=4),
            ft.Container(height=20),
            ft.Text(message, size=16, color=ft.colors.GREY_400),
        ],
    )


def error_view(
    message: str,
    detail: str = "",
    on_retry=None,
) -> ft.Column:
    """Reusable error view component."""
    controls = [
        ft.Icon(ft.icons.ERROR_OUTLINE, size=64, color=ft.colors.RED_400),
        ft.Container(height=16),
        ft.Text(message, size=18, color=ft.colors.RED_400),
    ]
    if detail:
        controls.extend([
            ft.Container(height=8),
            ft.Text(detail, size=13, color=ft.colors.GREY_500),
        ])
    if on_retry:
        controls.extend([
            ft.Container(height=24),
            ft.ElevatedButton("Spróbuj ponownie", icon=ft.icons.REFRESH, on_click=on_retry),
        ])
    return ft.Column(
        alignment=ft.MainAxisAlignment.CENTER,
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        controls=controls,
    )
