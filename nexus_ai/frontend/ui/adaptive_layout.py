"""adaptive_layout.py -- Adaptive Layout Engine (v7.0 Rec #4: Innowacja 1).

  Responsywny frontend z breakpointami:
  - Mobile (<600px): single column, dolne NavigationBar
  - Tablet (600-1024px): dwie kolumny, NavigationRail
  - Desktop (>1024px): trzy kolumny, NavigationRail + Sidebar

  Używa ft.ResponsiveRow i page.on_resized do dynamicznego dostosowania.
"""

from __future__ import annotations

from enum import Enum, auto

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.adaptive")


class Breakpoint(Enum):
    MOBILE = auto()   # < 600px
    TABLET = auto()   # 600-1024px
    DESKTOP = auto()  # > 1024px


class AdaptiveLayout:
    """Silnik responsywnego layoutu — dostosowuje UI do rozmiaru okna.

    Użycie:
        layout = AdaptiveLayout(page)
        layout.on_resize(width)

        if layout.breakpoint == Breakpoint.MOBILE:
            ...  # single column
        elif layout.breakpoint == Breakpoint.TABLET:
            ...  # two columns
        else:
            ...  # three columns + sidebar
    """

    MOBILE_MAX = 600
    TABLET_MAX = 1024

    def __init__(self, page: ft.Page):
        self.page = page
        self._current = Breakpoint.DESKTOP
        self._width = 1280

        # Inicjalizuj na podstawie bieżących wymiarów
        if page.width:
            self.on_resize(page.width)

        # Nasłuchuj zmiany rozmiaru
        page.on_resized = self._handle_resize

    @property
    def breakpoint(self) -> Breakpoint:
        return self._current

    @property
    def is_mobile(self) -> bool:
        return self._current == Breakpoint.MOBILE

    @property
    def is_tablet(self) -> bool:
        return self._current == Breakpoint.TABLET

    @property
    def is_desktop(self) -> bool:
        return self._current == Breakpoint.DESKTOP

    @property
    def width(self) -> float:
        return self._width

    def on_resize(self, width: float):
        """Aktualizuj breakpoint na podstawie szerokości okna."""
        self._width = width
        old = self._current

        if width < self.MOBILE_MAX:
            self._current = Breakpoint.MOBILE
        elif width < self.TABLET_MAX:
            self._current = Breakpoint.TABLET
        else:
            self._current = Breakpoint.DESKTOP

        if old != self._current:
            logger.info(
                "[LAYOUT] Breakpoint changed: %s -> %s (width=%dpx)",
                old.name, self._current.name, int(width),
            )

    def _handle_resize(self, e: ft.WindowResizeEvent):
        self.on_resize(e.width)

    # ── Column helpers ──────────────────────────────────────────────────

    def responsive_col(self, desktop: int = 4, tablet: int = 6, mobile: int = 12) -> dict:
        """Zwróć dict col dla ft.ResponsiveRow / Container.col."""
        return {"xs": mobile, "sm": tablet, "md": desktop}

    @property
    def kpi_cards_per_row(self) -> int:
        if self.is_mobile:
            return 2
        if self.is_tablet:
            return 3
        return 4

    @property
    def sidebar_visible(self) -> bool:
        return self.is_desktop

    @property
    def navigation_type(self) -> str:
        """Zwróć typ nawigacji: 'rail' lub 'bar'."""
        if self.is_mobile:
            return "bar"
        return "rail"

    @property
    def content_padding(self) -> ft.Padding:
        if self.is_mobile:
            return ft.padding.all(12)
        if self.is_tablet:
            return ft.padding.all(16)
        return ft.padding.all(24)


# ── Factory functions ────────────────────────────────────────────────────────


def build_adaptive_nav(
    layout: AdaptiveLayout,
    destinations: list[ft.NavigationRailDestination | ft.NavigationBarDestination],
    on_change,
) -> ft.Control:
    """Zbuduj nawigację dostosowaną do breakpointu.

    Mobile: ft.NavigationBar (dolny pasek)
    Tablet/Desktop: ft.NavigationRail (boczny panel)
    """
    if layout.is_mobile:
        return ft.NavigationBar(
            destinations=[
                ft.NavigationBarDestination(
                    icon=d.icon,
                    selected_icon=d.selected_icon,
                    label=d.label if isinstance(d, ft.NavigationRailDestination) else "",
                )
                for d in destinations
            ],
            on_change=on_change,
            bgcolor=ft.colors.SURFACE_CONTAINER,
            indicator_color=ft.colors.BLUE_ACCENT_400,
        )
    else:
        return ft.NavigationRail(
            selected_index=0,
            extended=layout.is_desktop,
            label_type=(
                ft.NavigationRailLabelType.ALL
                if layout.is_desktop
                else ft.NavigationRailLabelType.SELECTED
            ),
            bgcolor=ft.colors.with_opacity(0.03, ft.colors.WHITE),
            destinations=[
                (
                    ft.NavigationRailDestination(
                        icon=d.icon if isinstance(d, ft.NavigationRailDestination) else d.icon,
                        selected_icon=(
                            d.selected_icon
                            if isinstance(d, ft.NavigationRailDestination)
                            else d.selected_icon
                        ),
                        label=(
                            d.label if isinstance(d, ft.NavigationRailDestination) else getattr(d, 'label', '')
                        ),
                    )
                    if isinstance(d, ft.NavigationRailDestination)
                    else ft.NavigationRailDestination(
                        icon=d.icon,
                        selected_icon=d.selected_icon,
                        label=getattr(d, 'label', ''),
                    )
                )
                for d in destinations
            ],
            on_change=on_change,
        )


def build_responsive_grid(
    layout: AdaptiveLayout,
    items: list[ft.Control],
    desktop_cols: int = 4,
    tablet_cols: int = 3,
    mobile_cols: int = 2,
) -> ft.ResponsiveRow:
    """Zbuduj responsywną siatkę kart KPI."""

    cols = mobile_cols
    if layout.is_tablet:
        cols = tablet_cols
    elif layout.is_desktop:
        cols = desktop_cols

    col_span = 12 // cols

    return ft.ResponsiveRow(
        controls=[
            ft.Container(
                col={"xs": 12, "sm": 12 // (cols // 2) if cols > 2 else 6, "md": col_span},
                content=item,
            )
            for item in items
        ],
        spacing=12,
    )
