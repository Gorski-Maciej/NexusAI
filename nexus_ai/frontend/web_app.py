"""web_app.py -- Web mode entry point for NexusAI Flet Navigator 2.0.

  - ft.app_async z view=ft.AppView.WEB_BROWSER -- SPA w przeglądarce
  - TemplateRoute dla URL pattern matching
  - Navigator 2.0: page.views.append(ft.View(...)) zamiast page.add()
  - page.client_storage dla zapamiętania ostatniej ścieżki
  - ft.SafeArea dla mobile-safe layout
  - page.theme_animation_style dla płynnych przejść
  - page.window_prevent_close + on_window_event dla lifecycle
  - ft.Shimmer dla loading skeleton zamiast ProgressRing
  - page.go() dla inicjalizacji routingu (automatycznie triggeruje on_route_change)
"""

from __future__ import annotations

import flet as ft
from flet import TemplateRoute
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusApiClient
from nexus_ai.frontend.router import NexusRouter

logger = get_logger("nexus.ui.web")

DEFAULT_API_PORT = 8000
DEFAULT_WEB_PORT = 8550


async def init_web_app(page: ft.Page) -> None:
    """Initialize Flet app in web browser mode z Navigator 2.0.

      - page.on_route_change JEDEN raz -- deleguje do NexusRouter.handle_route()
      - page.on_view_pop dla przycisku Wstecz
      - page.window_prevent_close dla ochrony zamknięcia
      - page.theme_animation_style dla płynnych przejść
    """
    # ── Konfiguracja strony dla Web ──────────────────────────────────────
    page.title = "Nexus AI -- System Księgowy"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#121212"
    page.window_width = 1280
    page.window_height = 900
    page.window_resizable = True
    page.window_min_width = 800
    page.window_min_height = 600
    page.scroll = ft.ScrollMode.ADAPTIVE

    page.add(
        ft.SafeArea(
            content=ft.Container(expand=True),
            minimum=ft.Padding(left=8, top=8, right=8, bottom=8),
        )
    )

    # ── Inicjalizacja API ───────────────────────────────────────────────
    api_client = NexusApiClient(
        base_url=f"http://127.0.0.1:{DEFAULT_API_PORT}/api/v1",
        token="",
    )

    # ── Router -- JEDNO miejsce dla routingu ─────────────────────────────
    # page.window_prevent_close, page.on_window_event przez konstruktor
    router = NexusRouter(page=page, api_client=api_client)

    # ── Pokaż loading screen z Shimmer podczas inicjalizacji ─────────────
    loading = ft.Shimmer(
        content=ft.Container(
            content=ft.Column(
                [
                    ft.Container(height=40, bgcolor=ft.colors.GREY_800, border_radius=8),
                    ft.Container(height=16),
                    ft.Container(height=200, bgcolor=ft.colors.GREY_800, border_radius=12),
                    ft.Container(height=16),
                    ft.Row(
                        [
                            ft.Container(
                                height=100,
                                bgcolor=ft.colors.GREY_800,
                                border_radius=12,
                                expand=True,
                            ),
                            ft.Container(width=16),
                            ft.Container(
                                height=100,
                                bgcolor=ft.colors.GREY_800,
                                border_radius=12,
                                expand=True,
                            ),
                            ft.Container(width=16),
                            ft.Container(
                                height=100,
                                bgcolor=ft.colors.GREY_800,
                                border_radius=12,
                                expand=True,
                            ),
                        ]
                    ),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            alignment=ft.alignment.center,
            expand=True,
        ),
    )
    await page.add_async(loading)

    # ── Routing dla Web ─────────────────────────────────────────────────
    async def on_route_change(route_event: ft.RouteChangeEvent) -> None:
        """Handle URL changes -- deleguje do NexusRouter.handle_route()."""
        route = page.route

        _update_page_title(page, route)

        await router.handle_route(route)

    page.on_route_change = on_route_change

    async def on_view_pop(view_event: ft.ViewPopEvent) -> None:
        """Handle browser back button -- Navigator 2.0 pop."""
        if len(page.views) > 1:
            router.pop_view()
        else:
            await page.window_destroy_async()

    page.on_view_pop = on_view_pop

    last_route = page.client_storage.get("nexus_last_route")
    initial_route = page.route if page.route and page.route != "/" else (last_route or "/")
    page.go(initial_route)

    await page.update_async()


def _update_page_title(page: ft.Page, route: str) -> None:
    """Update browser tab title based on current route with TemplateRoute."""
    tr = TemplateRoute(route)
    # Match route patterns -- O(1) dispatch zamiast elif chain
    match route:
        case "/":
            page.title = "Nexus AI -- Dashboard"
        case r if tr.match("/invoices/:id"):
            invoice_id = tr.id[:8]
            page.title = f"Nexus AI -- Faktura #{invoice_id}"
        case r if tr.match("/invoices"):
            page.title = "Nexus AI -- Faktury"
        case r if tr.match("/briefing"):
            page.title = "Nexus AI -- Podsumowanie dnia"
        case r if tr.match("/partner"):
            page.title = "Nexus AI -- Partnerzy"
        case r if tr.match("/tasks"):
            page.title = "Nexus AI -- Monitor zadań"
        case _:
            page.title = f"Nexus AI -- {route.strip('/').title()}"


def run_web_app(
    port: int = DEFAULT_WEB_PORT,
    api_port: int = DEFAULT_API_PORT,
    headless: bool = False,
) -> None:
    """Launch NexusAI Flet app in web browser mode."""
    logger.info("Starting NexusAI Web App -- port=%s, api_port=%s", port or "random", api_port)
    ft.app_async(target=init_web_app, view=ft.AppView.WEB_BROWSER, port=port)
    logger.info("NexusAI Web App stopped.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="NexusAI Flet Web App")
    parser.add_argument("--port", type=int, default=DEFAULT_WEB_PORT)
    parser.add_argument("--api-port", type=int, default=DEFAULT_API_PORT)
    parser.add_argument("--headless", action="store_true")
    args = parser.parse_args()
    run_web_app(port=args.port, api_port=args.api_port, headless=args.headless)
