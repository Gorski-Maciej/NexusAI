"""Theme Manager — Dynamiczny dark/light mode z zapisem w client_storage.

SUPERMOCE:
  - Dynamiczny przełącznik dark/light
  - Zapis preferencji w page.client_storage
  - page.theme_animation_style dla płynnych przejść
  - ColorScheme dla spójnego Material 3 designu
"""

from __future__ import annotations

import flet as ft


class ThemeManager:
    """Zarządza paletą barw i stylem Nexus AI z dynamicznym przełączaniem."""

    @staticmethod
    def load_theme(page: ft.Page) -> ft.ThemeMode:
        """Load saved theme preference from client_storage."""
        saved = page.client_storage.get("theme_mode")
        if saved == "light":
            return ft.ThemeMode.LIGHT
        return ft.ThemeMode.DARK

    @staticmethod
    def save_theme(page: ft.Page, mode: ft.ThemeMode):
        """Save theme preference to client_storage."""
        page.client_storage.set("theme_mode", "light" if mode == ft.ThemeMode.LIGHT else "dark")

    @staticmethod
    def get_dark_theme() -> ft.Theme:
        """Enterprise dark theme with custom ColorScheme."""
        return ft.Theme(
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_ACCENT_400,
                on_primary=ft.colors.WHITE,
                primary_container="#232333",
                secondary=ft.colors.CYAN_400,
                surface="#1E1E26",
                background="#121217",
                on_surface="#E0E0E0",
                error=ft.colors.RED_400,
                outline=ft.colors.GREY_800,
            ),
            font_family="Segoe UI",
            visual_density=ft.VisualDensity.COMFORTABLE,
            page_transitions=ft.PageTransitionsTheme(
                windows=ft.PageTransitionType.FADE_THROUGH,
                macos=ft.PageTransitionType.SLIDE_DOWNWARDS,
                linux=ft.PageTransitionType.FADE_THROUGH,
                android=ft.PageTransitionType.OPEN_UPWARDS,
                ios=ft.PageTransitionType.CUPERTINO,
            ),
        )

    @staticmethod
    def get_light_theme() -> ft.Theme:
        """Clean light theme for productivity."""
        return ft.Theme(
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_700,
                on_primary=ft.colors.WHITE,
                primary_container=ft.colors.BLUE_100,
                secondary=ft.colors.CYAN_600,
                surface=ft.colors.WHITE,
                background=ft.colors.GREY_50,
                on_surface=ft.colors.GREY_900,
                error=ft.colors.RED_600,
                outline=ft.colors.GREY_300,
            ),
            font_family="Segoe UI",
            visual_density=ft.VisualDensity.COMFORTABLE,
            page_transitions=ft.PageTransitionsTheme(
                windows=ft.PageTransitionType.FADE_THROUGH,
            ),
        )

    @staticmethod
    def create_theme_switcher(page: ft.Page) -> ft.IconButton:
        """Create a theme switch button with persistence.
        
        Usage:
            page.appbar = ft.AppBar(actions=[ThemeManager.create_theme_switcher(page)])
        """
        current = ThemeManager.load_theme(page)
        is_dark = current == ft.ThemeMode.DARK

        async def toggle_theme(e):
            nonlocal is_dark
            is_dark = not is_dark
            new_mode = ft.ThemeMode.DARK if is_dark else ft.ThemeMode.LIGHT
            page.theme_mode = new_mode
            ThemeManager.save_theme(page, new_mode)
            e.control.icon = ft.icons.DARK_MODE if is_dark else ft.icons.LIGHT_MODE
            # Płynna animacja przejścia między motywami
            page.theme_animation_style = ft.ThemeAnimationStyle(
                duration=300,
                curve=ft.AnimationCurve.EASE_IN_OUT,
            )
            page.update()

        return ft.IconButton(
            icon=ft.icons.DARK_MODE if is_dark else ft.icons.LIGHT_MODE,
            tooltip="Zmień motyw (zapisuje się automatycznie)",
            on_click=toggle_theme,
        )
