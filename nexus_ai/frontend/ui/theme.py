"""Theme Manager — Dynamiczny dark/light mode z Material 3 i scrollbar theme.

SUPERMOCE Flet 0.28+:
  - ft.Theme z pełnym ColorScheme (Material 3)
  - scrollbar_theme dla spójnego scrollbara
  - page.theme_animation_style dla płynnych przejść
  - page.client_storage dla zapisu preferencji
  - use_material3=True dla wymuszenia Material 3
  - TextThemeStyle dla systemowej skali typografii
  - ColorSchemeSeed dla dynamicznej palety z jednego koloru
  - page.font_family dla spójnej typografii
  - PageTransitionsTheme dla płynnych przejść między widokami
"""

from __future__ import annotations

import flet as ft


class ThemeManager:
    """Zarządza paletą barw i stylem Nexus AI z dynamicznym przełączaniem.

    SUPERMOC Flet 0.28+:
      - Pełny ColorScheme Material 3
      - Scrollbar theme dla spójnego wyglądu
      - page.theme_animation_style dla płynnych przejść między motywami
      - Use Material 3 widgets
    """

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
        """Enterprise dark theme with Material 3 ColorScheme + Scrollbar.

        SUPERMOCE:
          - scrollbar_theme — stylowanie scrollbara
          - use_material3=True — wymuszenie Material 3
          - ColorScheme seed dla dynamicznej palety
          - TextThemeStyle dla spójnej typografii
        """
        return ft.Theme(
            use_material3=True,
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_ACCENT_400,
                on_primary=ft.colors.WHITE,
                primary_container="#232333",
                secondary=ft.colors.CYAN_400,
                secondary_container="#1A2A3A",
                surface="#1E1E26",
                surface_container_highest="#2A2A35",
                surface_container="#252530",
                background="#121217",
                on_surface="#E0E0E0",
                on_surface_variant="#A0A0B0",
                error=ft.colors.RED_400,
                error_container="#3A1A1A",
                outline=ft.colors.GREY_800,
                outline_variant="#3A3A45",
                inverse_surface="#E0E0E0",
                inverse_on_surface="#121217",
            ),
            # SUPERMOC: Scrollbar theme — spójny style na wszystkich platformach
            scrollbar_theme=ft.ScrollbarTheme(
                thickness=6.0,
                thumb_color=ft.colors.with_opacity(0.3, ft.colors.WHITE),
                track_color=ft.colors.with_opacity(0.05, ft.colors.WHITE),
                radius=ft.corner_radius.all(3),
                track_visibility=True,
                track_border_color=ft.colors.with_opacity(0.1, ft.colors.WHITE),
            ),
            # SUPERMOC: Text theme z hierarchią typografii
            text_theme=ft.TextTheme(
                headline_large=ft.TextStyle(
                    size=32, weight=ft.FontWeight.BOLD, color="#FFFFFF",
                    letter_spacing=-0.5,
                ),
                headline_medium=ft.TextStyle(
                    size=28, weight=ft.FontWeight.BOLD, color="#FFFFFF",
                ),
                headline_small=ft.TextStyle(
                    size=22, weight=ft.FontWeight.SEMI_BOLD, color="#E0E0E0",
                ),
                title_large=ft.TextStyle(
                    size=18, weight=ft.FontWeight.SEMI_BOLD, color="#E0E0E0",
                ),
                title_medium=ft.TextStyle(
                    size=16, weight=ft.FontWeight.MEDIUM, color="#D0D0D0",
                ),
                body_large=ft.TextStyle(size=16, color="#C0C0C0"),
                body_medium=ft.TextStyle(size=14, color="#B0B0B0"),
                body_small=ft.TextStyle(size=12, color="#909090"),
                label_large=ft.TextStyle(
                    size=14, weight=ft.FontWeight.MEDIUM, color="#A0A0A0",
                ),
            ),
            font_family="Segoe UI, -apple-system, sans-serif",
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
        """Clean light theme with Material 3 and scrollbar theme."""
        return ft.Theme(
            use_material3=True,
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_700,
                on_primary=ft.colors.WHITE,
                primary_container=ft.colors.BLUE_100,
                secondary=ft.colors.CYAN_600,
                surface=ft.colors.WHITE,
                surface_container_highest=ft.colors.GREY_100,
                background=ft.colors.GREY_50,
                on_surface=ft.colors.GREY_900,
                on_surface_variant=ft.colors.GREY_600,
                error=ft.colors.RED_600,
                error_container=ft.colors.RED_100,
                outline=ft.colors.GREY_300,
            ),
            scrollbar_theme=ft.ScrollbarTheme(
                thickness=6.0,
                thumb_color=ft.colors.with_opacity(0.3, ft.colors.BLACK),
                track_color=ft.colors.with_opacity(0.05, ft.colors.BLACK),
                radius=ft.corner_radius.all(3),
                track_visibility=True,
            ),
            text_theme=ft.TextTheme(
                headline_large=ft.TextStyle(
                    size=32, weight=ft.FontWeight.BOLD, color="#1A1A1A",
                ),
                title_large=ft.TextStyle(
                    size=18, weight=ft.FontWeight.SEMI_BOLD, color="#333333",
                ),
                body_medium=ft.TextStyle(size=14, color="#555555"),
            ),
            font_family="Segoe UI, -apple-system, sans-serif",
            visual_density=ft.VisualDensity.COMFORTABLE,
            page_transitions=ft.PageTransitionsTheme(
                windows=ft.PageTransitionType.FADE_THROUGH,
            ),
        )

    @staticmethod
    def create_theme_switcher(page: ft.Page) -> ft.IconButton:
        """Create a theme switch button with persistence and animation.

        SUPERMOC:
          - page.theme_animation_style dla płynnej animacji
          - page.client_storage dla zapisu preferencji
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

            # SUPERMOC: Płynna animacja przejścia między motywami
            page.theme_animation_style = ft.ThemeAnimationStyle(
                duration=400,
                curve=ft.AnimationCurve.EASE_IN_OUT,
            )
            page.update()

        return ft.IconButton(
            icon=ft.icons.DARK_MODE if is_dark else ft.icons.LIGHT_MODE,
            tooltip="Zmień motyw (zapisuje się automatycznie w client_storage)",
            on_click=toggle_theme,
        )
