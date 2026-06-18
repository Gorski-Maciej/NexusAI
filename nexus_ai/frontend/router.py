"""NexusAI Declarative Router — SUPERMOC Flet 1.0 Router dla Web i Desktop.

SUPERMOCE:
  - page.on_route_change dla pełnej kontroli URL
  - Automatyczna synchronizacja z historią przeglądarki
  - Głębokie linkowanie (/invoices/:id)
  - Lazy loading widoków
  - Wsparcie dla Web (WEB_BROWSER) i Desktop (APP_WINDOW)
  - Obsługa 404
  - Dynamiczny page.title na podstawie trasy
"""

from __future__ import annotations

from typing import Any
from urllib.parse import urlparse, parse_qs

import flet as ft
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusApiClient

logger = get_logger("nexus.ui.router")


class NexusRouter:
    """Declarative router dla Web i Desktop.

    SUPERMOC Flet:
      - page.on_route_change — synchronizacja z URL przeglądarki
      - page.on_view_pop — obsługa przycisku Wstecz
      - page.go() — aktualizacja URL + historia + routing
      - Działa zarówno w WEB_BROWSER jak i APP_WINDOW

    Routing map:
      /                → Dashboard
      /invoices        → Lista faktur
      /invoices/:id    → Szczegóły faktury (deep link)
      /briefing        → Podsumowanie dnia
      /partner         → Partnerzy
      /tasks           → Monitor zadań
      *                → 404
    """

    def __init__(self, page: ft.Page, api_client: NexusApiClient):
        self.page = page
        self.api = api_client

        # Cache widoków dla szybkiego przełączania
        self._view_cache: dict[str, Any] = {}

        # SUPERMOC: Mapa ścieżek z lazy loadingiem
        # Każdy wpis: route → (builder_func, handler_instance)
        self._routes: dict[str, tuple] = {
            "/": (self._build_dashboard, None),
            "/invoices": (self._build_invoices, None),
            "/briefing": (self._build_briefing, None),
            "/partner": (self._build_partner, None),
            "/tasks": (self._build_tasks, None),
        }

    async def handle_route(self, route: str) -> None:
        """Handle route change and build the corresponding view.

        SUPERMOC:
          - Parsuje URL + query params
          - Obsługuje /invoices/:id jako deep link
          - Lazy ładuje widoki
          - Automatycznie triggeruje async data loading
        """
        # SUPERMOC: Parsuj URL (query params, fragment)
        parsed = urlparse(route)
        path = parsed.path or "/"
        query_params = parse_qs(parsed.query)

        logger.debug("Router handling path=%s params=%s", path, query_params)

        # SUPERMOC: Deep linking — /invoices/{id}
        if path.startswith("/invoices/") and len(path) > 10:
            invoice_id = path.split("/")[-1]
            await self._build_invoice_detail(invoice_id, query_params)
            return

        # SUPERMOC: Standardowe ścieżki
        builder, _ = self._routes.get(path, (self._build_not_found, None))
        view = builder()

        # SUPERMOC: Ustaw widok w page
        self.page.views.clear()
        self.page.controls.clear()
        self.page.add(view)
        await self.page.update_async()

    def _build_app_bar(self, title: str = "Nexus AI") -> ft.AppBar:
        """Build navigation app bar."""
        return ft.AppBar(
            title=ft.Text(title),
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            automatically_imply_leading=False,
            actions=[
                ft.IconButton(
                    icon=ft.icons.HOME_OUTLINED,
                    tooltip="Dashboard",
                    on_click=lambda _: self.page.go("/"),
                ),
                ft.IconButton(
                    icon=ft.icons.DOCUMENT_SCAN_OUTLINED,
                    tooltip="Faktury",
                    on_click=lambda _: self.page.go("/invoices"),
                ),
                ft.IconButton(
                    icon=ft.icons.TASK_ALT_OUTLINED,
                    tooltip="Zadania",
                    on_click=lambda _: self.page.go("/tasks"),
                ),
                ft.IconButton(
                    icon=ft.icons.GROUPS_OUTLINED,
                    tooltip="Partnerzy",
                    on_click=lambda _: self.page.go("/partner"),
                ),
                ft.IconButton(
                    icon=ft.icons.BRIGHTNESS_6,
                    tooltip="Zmień motyw",
                ),
            ],
        )

    def _build_dashboard(self) -> ft.View:
        """Build dashboard view."""
        from nexus_ai.frontend.views.dashboard import DashboardView

        dv = DashboardView(self.api)

        # SUPERMOC: Automatyczne ładowanie danych przy renderze dla Web
        # Dla WEB_BROWSER widok jest budowany za każdym razem
        self.page.run_task(dv.load_data)

        return ft.Column(
            [
                self._build_app_bar("Dashboard"),
                dv.build(),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

    def _build_invoices(self) -> ft.View:
        """Build invoice list view."""
        from nexus_ai.frontend.views.invoice_list_view import InvoiceListView

        iv = InvoiceListView(self.api)

        return ft.Column(
            [
                self._build_app_bar("Faktury"),
                ft.Container(
                    content=iv.build(),
                    expand=True,
                    padding=ft.padding.all(16),
                ),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

    async def _build_invoice_detail(
        self, invoice_id: str, query_params: dict[str, list[str]]
    ) -> None:
        """Build invoice detail view for deep linking.

        SUPERMOC: Głębokie linkowanie — /invoices/{id}
        URL jest automatycznie dodawany do historii przeglądarki.
        """
        from nexus_ai.frontend.views.invoice_detail_view import InvoiceDetailView

        dv = InvoiceDetailView(self.api, invoice_id)

        # SUPERMOC: page.go() aktualizuje URL w przeglądarce
        self.page.go(f"/invoices/{invoice_id}")

        # Supermoc: Aktualizuj tytuł strony
        self.page.title = f"Nexus AI — Faktura #{invoice_id[:8]}"

        view = ft.Column(
            [
                ft.AppBar(
                    title=ft.Text(f"Szczegóły faktury #{invoice_id[:8]}"),
                    bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                ),
                ft.Container(
                    content=dv.build(),
                    expand=True,
                    padding=ft.padding.all(16),
                ),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

        # Załaduj dane
        self.page.run_task(dv.load_data)

        self.page.views.clear()
        self.page.controls.clear()
        self.page.add(view)
        await self.page.update_async()

    def _build_briefing(self) -> ft.View:
        """Build daily briefing view."""
        from nexus_ai.frontend.views.daily_briefing import DailyBriefingView

        bv = DailyBriefingView(self.api)

        # SUPERMOC: Async data loading dla Web
        self.page.run_task(bv.load_data)

        return ft.Column(
            [
                self._build_app_bar("Podsumowanie dnia"),
                ft.Container(
                    content=bv.build(),
                    expand=True,
                    padding=ft.padding.all(16),
                ),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

    def _build_partner(self) -> ft.View:
        """Build partner hub view."""
        from nexus_ai.frontend.views.partner_hub import PartnerHubView

        pv = PartnerHubView(self.api)

        return ft.Column(
            [
                self._build_app_bar("Partnerzy"),
                ft.Container(
                    content=pv.build(),
                    expand=True,
                    padding=ft.padding.all(16),
                ),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

    def _build_tasks(self) -> ft.View:
        """Build task monitor view."""
        from nexus_ai.frontend.views.task_monitor import TaskMonitorPanel

        tm = TaskMonitorPanel(self.page, self.api)
        self.page.run_task(tm.refresh)

        return ft.Column(
            [
                self._build_app_bar("Monitor zadań"),
                ft.Container(
                    content=tm.build(),
                    expand=True,
                    padding=ft.padding.all(16),
                ),
            ],
            expand=True,
            scroll=ft.ScrollMode.AUTO,
            spacing=0,
        )

    def _build_not_found(self) -> ft.View:
        """Build 404 page."""
        return ft.Column(
            [
                self._build_app_bar("404"),
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(
                                ft.icons.SEARCH_OFF, size=80, color=ft.colors.GREY_600
                            ),
                            ft.Container(height=20),
                            ft.Text(
                                "404 — Strona nie znaleziona",
                                size=24,
                                weight=ft.FontWeight.BOLD,
                                color=ft.colors.GREY_400,
                            ),
                            ft.Container(height=8),
                            ft.Text(
                                f"Ścieżka: {self.page.route}",
                                size=14,
                                color=ft.colors.GREY_600,
                            ),
                            ft.Container(height=24),
                            ft.ElevatedButton(
                                "Powrót do Dashboardu",
                                icon=ft.icons.HOME,
                                on_click=lambda _: self.page.go("/"),
                            ),
                        ],
                        alignment=ft.MainAxisAlignment.CENTER,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    alignment=ft.alignment.center,
                    expand=True,
                ),
            ],
            expand=True,
            spacing=0,
        )
