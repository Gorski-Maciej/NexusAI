# ui/theme.py
import flet as ft


class ThemeManager:
    """Zarządza paletą barw i stylem Nexus AI (Enterprise Look & Feel)."""

    @staticmethod
    def get_dark_theme() -> ft.Theme:
        return ft.Theme(
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_ACCENT_400,
                on_primary=ft.colors.WHITE,
                primary_container="#232333",
                secondary=ft.colors.CYAN_400,
                surface="#1E1E26",  # Karty i panele
                background="#121217",  # Główne tło
                on_surface="#E0E0E0",
                error=ft.colors.RED_400,
                outline=ft.colors.GREY_800,
            ),
            font_family="Segoe UI",
            visual_density=ft.VisualDensity.COMFORTABLE,
            page_transitions=ft.PageTransitionsTheme(windows=ft.PageTransitionType.FADE_THROUGH),
        )

    @staticmethod
    def get_light_theme() -> ft.Theme:
        return ft.Theme(
            color_scheme=ft.ColorScheme(
                primary=ft.colors.BLUE_700,
                on_primary=ft.colors.WHITE,
                background=ft.colors.GREY_50,
                surface=ft.colors.WHITE,
            )
        )
