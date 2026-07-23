"""Theme Manager -- Dynamiczny dark/light mode z Material 3 i scrollbar theme.

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

      - Pełny ColorScheme Material 3
      - Scrollbar theme dla spójnego wyglądu
      - page.theme_animation_style dla płynnych przejść między motywami
      - Use Material 3 widgets
    """

    @staticmethod
    def load_theme(page: ft.Page) -> ft.ThemeMode:
        """Load saved theme preference from client_storage.

        v7.0 Rec #3: Prefers-color-scheme — systemowe wykrywanie.
        Jeśli nie zapisano preferencji, używa ft.ThemeMode.SYSTEM.
        """
        saved = page.client_storage.get("theme_mode")
        if saved == "light":
            return ft.ThemeMode.LIGHT
        if saved == "dark":
            return ft.ThemeMode.DARK
        # v7.0: Auto-detect system preference
        return ft.ThemeMode.SYSTEM

    @staticmethod
    def save_theme(page: ft.Page, mode: ft.ThemeMode):
        """Save theme preference to client_storage."""
        page.client_storage.set("theme_mode", "light" if mode == ft.ThemeMode.LIGHT else "dark")

    @staticmethod
    def get_dark_theme() -> ft.Theme:
        """Enterprise dark theme with Material 3 ColorScheme + Scrollbar.

          - scrollbar_theme -- stylowanie scrollbara
          - use_material3=True -- wymuszenie Material 3
          - ColorScheme seed dla dynamicznej palety
          - TextThemeStyle dla spójnej typografii
        """
        # v7.0: Dynamiczny ColorSchemeSeed z jednego koloru (Material 3 eksperymentalne)
        return ft.Theme(
            use_material3=True,
            color_scheme_seed=ft.colors.BLUE_ACCENT_400,
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
            scrollbar_theme=ft.ScrollbarTheme(
                thickness=6.0,
                thumb_color=ft.colors.with_opacity(0.3, ft.colors.WHITE),
                track_color=ft.colors.with_opacity(0.05, ft.colors.WHITE),
                radius=ft.corner_radius.all(3),
                track_visibility=True,
                track_border_color=ft.colors.with_opacity(0.1, ft.colors.WHITE),
            ),
            text_theme=ft.TextTheme(
                headline_large=ft.TextStyle(
                    size=32,
                    weight=ft.FontWeight.BOLD,
                    color="#FFFFFF",
                    letter_spacing=-0.5,
                ),
                headline_medium=ft.TextStyle(
                    size=28,
                    weight=ft.FontWeight.BOLD,
                    color="#FFFFFF",
                ),
                headline_small=ft.TextStyle(
                    size=22,
                    weight=ft.FontWeight.SEMI_BOLD,
                    color="#E0E0E0",
                ),
                title_large=ft.TextStyle(
                    size=18,
                    weight=ft.FontWeight.SEMI_BOLD,
                    color="#E0E0E0",
                ),
                title_medium=ft.TextStyle(
                    size=16,
                    weight=ft.FontWeight.MEDIUM,
                    color="#D0D0D0",
                ),
                body_large=ft.TextStyle(size=16, color="#C0C0C0"),
                body_medium=ft.TextStyle(size=14, color="#B0B0B0"),
                body_small=ft.TextStyle(size=12, color="#909090"),
                label_large=ft.TextStyle(
                    size=14,
                    weight=ft.FontWeight.MEDIUM,
                    color="#A0A0A0",
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
        # v7.0: Dynamiczny ColorSchemeSeed dla light theme
        return ft.Theme(
            use_material3=True,
            color_scheme_seed=ft.colors.BLUE_700,
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
                    size=32,
                    weight=ft.FontWeight.BOLD,
                    color="#1A1A1A",
                ),
                title_large=ft.TextStyle(
                    size=18,
                    weight=ft.FontWeight.SEMI_BOLD,
                    color="#333333",
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

          - page.theme_animation_style dla płynnej animacji
          - page.client_storage dla zapisu preferencji
        """
        current = ThemeManager.load_theme(page)
        is_dark = current == ft.ThemeMode.DARK

        modes = [ft.ThemeMode.DARK, ft.ThemeMode.LIGHT, ft.ThemeMode.SYSTEM]
        labels = ["Ciemny", "Jasny", "Auto"]
        icons_list = [ft.icons.DARK_MODE, ft.icons.LIGHT_MODE, ft.icons.BRIGHTNESS_AUTO]

        async def toggle_theme(e):
            nonlocal current_idx
            current_idx = (current_idx + 1) % 3
            new_mode = modes[current_idx]
            page.theme_mode = new_mode
            ThemeManager.save_theme(page, new_mode)
            e.control.icon = icons_list[current_idx]
            e.control.tooltip = f"Motyw: {labels[current_idx]} (kliknij by zmienić)"

            page.theme_animation_style = ft.ThemeAnimationStyle(
                duration=400,
                curve=ft.AnimationCurve.EASE_IN_OUT,
            )
            page.update()

        current_idx = 0 if current == ft.ThemeMode.DARK else (1 if current == ft.ThemeMode.LIGHT else 2)

        return ft.IconButton(
            icon=icons_list[current_idx],
            tooltip=f"Motyw: {labels[current_idx]} (kliknij by zmienić)",
            on_click=toggle_theme,
        )
