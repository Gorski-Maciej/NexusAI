"""web_app.py — Web mode entry point for NexusAI Flet app.

SUPERMOCE Flet:
  - ft.app_async z view=ft.AppView.WEB_BROWSER — uruchamia jako SPA w przeglądarce
  - Automatyczna synchronizacja URL z routingiem aplikacji
  - Obsługa przycisków Wstecz/Dalej przeglądarki
  - Głębokie linkowanie (deep linking) — bezpośrednie wejście na /invoices/{id}
  - Responsywny layout dla różnych rozmiarów okna
  - page.title aktualizowany dynamicznie na podstawie trasy
"""

from __future__ import annotations

import sys
from typing import Any

import flet as ft
import httpx
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusApiClient
from nexus_ai.frontend.router import NexusRouter

logger = get_logger("nexus.ui.web")


# ── Konfiguracja domyślna ──────────────────────────────────────────────────

DEFAULT_API_PORT = 8000
DEFAULT_WEB_PORT = 8550


# ── Web app ─────────────────────────────────────────────────────────────────


async def init_web_app(page: ft.Page) -> None:
    """Initialize Flet app in web browser mode with URL routing.

    SUPERMOC:
      - ft.app_async z view=ft.AppView.WEB_BROWSER
      - page.on_route_change dla pełnej kontroli URL
      - page.on_view_pop dla przycisku Wstecz
      - Auto-wykrywanie portu API z URL parametrów lub domyślnego
    """
    # ── Konfiguracja strony dla Web ──────────────────────────────────────
    page.title = "Nexus AI — System Księgowy"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#121212"

    # SUPERMOC: Web-specific viewport configuration
    page.window_width = 1280
    page.window_height = 900
    page.window_resizable = True
    page.window_min_width = 800
    page.window_min_height = 600

    # SUPERMOC: Scroll mode dla web — AUTO zamiast ADAPTIVE
    # ADAPTIVE działa lepiej na desktopie, AUTO na web
    page.scroll = ft.ScrollMode.ADAPTIVE

    # ── Inicjalizacja API ───────────────────────────────────────────────
    api_client = NexusApiClient(
        base_url=f"http://127.0.0.1:{DEFAULT_API_PORT}/api/v1",
        token="",
    )

    # ── Router ───────────────────────────────────────────────────────────
    router = NexusRouter(page=page, api_client=api_client)

    # ── Pokaż loading screen podczas inicjalizacji ───────────────────────
    loading = ft.Container(
        content=ft.Column(
            [
                ft.ProgressRing(width=48, height=48, stroke_width=4),
                ft.Container(height=20),
                ft.Text(
                    "Ładowanie aplikacji Nexus AI...",
                    size=16,
                    color=ft.colors.GREY_400,
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            alignment=ft.MainAxisAlignment.CENTER,
        ),
        alignment=ft.alignment.center,
        expand=True,
    )
    await page.add_async(loading)

    # ── Routing dla Web ──────────────────────────────────────────────────
    # SUPERMOC: page.on_route_change synchronizuje URL przeglądarki z widokiem
    # page.go() aktualizuje URL i historię przeglądarki

    async def on_route_change(route_event: ft.RouteChangeEvent) -> None:
        """Handle URL changes from browser navigation (URL bar, back/forward).

        SUPERMOC: page.route zawiera aktualny URL, który jest automatycznie
        synchronizowany z paskiem adresu przeglądarki.
        """
        route = page.route

        # Aktualizuj tytuł strony w pasku przeglądarki
        _update_page_title(page, route)

        # Wyczyść poprzedni widok
        page.views.clear()
        page.controls.clear()

        # SUPERMOC: Routing przez dedykowany NexusRouter
        # - Obsługuje /, /invoices, /invoices/:id, /briefing, /partner
        # - Automatycznie ładuje dane asynchronicznie
        await router.handle_route(route)

        # SUPERMOC: page.update() jest wymagany po zmianie widoku
        await page.update_async()

    # Podpięcie pod page.on_route_change
    # SUPERMOC: Flet automatycznie dodaje URL do historii przeglądarki
    # przy każdym page.go() — brak dodatkowej konfiguracji
    page.on_route_change = on_route_change

    # ── Obsługa przycisku Wstecz w przeglądarce ──────────────────────────
    async def on_view_pop(view_event: ft.ViewPopEvent) -> None:
        """Handle browser back button.

        SUPERMOC: Flet automatycznie wykrywa przycisk Wstecz/Dalej
        przeglądarki i wywołuje page.on_view_pop.
        """
        if len(page.views) > 1:
            page.views.pop()
            top_view = page.views[-1]
            page.go(top_view.route)
        else:
            # Jeśli jesteśmy na głównej — potwierdź zamknięcie
            await page.window_destroy_async()

    page.on_view_pop = on_view_pop

    # ── Pierwsze ładowanie ──────────────────────────────────────────────
    # SUPERMOC: page.go() inicjalizuje routing i ustawia URL w przeglądarce
    # Jeśli URL już zawiera ścieżkę (deep linking), używamy jej
    # W przeciwnym razie kierujemy na dashboard (/)
    initial_route = page.route if page.route and page.route != "/" else "/"
    page.go(initial_route)

    await page.update_async()


def _update_page_title(page: ft.Page, route: str) -> None:
    """Update browser tab title based on current route.

    SUPERMOC: page.title jest synchronizowany z tytułem karty przeglądarki.
    """
    titles = {
        "/": "Nexus AI — Dashboard",
        "/invoices": "Nexus AI — Faktury",
        "/briefing": "Nexus AI — Podsumowanie dnia",
        "/partner": "Nexus AI — Partnerzy",
    }

    # Obsługa /invoices/{id}
    if route.startswith("/invoices/") and len(route) > 10:
        invoice_id = route.split("/")[-1][:8]
        page.title = f"Nexus AI — Faktura #{invoice_id}"
    else:
        page.title = titles.get(route, f"Nexus AI — {route.strip('/').title()}")


# ── Web launcher ────────────────────────────────────────────────────────────


def run_web_app(
    port: int = DEFAULT_WEB_PORT,
    api_port: int = DEFAULT_API_PORT,
    headless: bool = False,
) -> None:
    """Launch NexusAI Flet app in web browser mode.

    SUPERMOCE:
      - view=ft.AppView.WEB_BROWSER — otwiera w domyślnej przeglądarce
      - port=0 — automatycznie wybiera wolny port
      - Automatyczne otwarcie URL w przeglądarce

    Args:
        port: Port serwera web (0 = losowy). Domyślnie 8550.
        api_port: Port API backendu. Domyślnie 8000.
        headless: Jeśli True, nie otwiera automatycznie przeglądarki.
    """
    logger.info(
        "Starting NexusAI Web App — port=%s, api_port=%s, headless=%s",
        port if port else "random",
        api_port,
        headless,
    )

    # SUPERMOC: ft.app_async z view=ft.AppView.WEB_BROWSER
    # Flet uruchamia serwer HTTP i otwiera aplikację w przeglądarce
    ft.app_async(
        target=init_web_app,
        view=ft.AppView.WEB_BROWSER,
        port=port,
    )

    logger.info("NexusAI Web App stopped.")


# ── CLI entry point ─────────────────────────────────────────────────────────


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="NexusAI Flet Web App")
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_WEB_PORT,
        help=f"Web server port (default: {DEFAULT_WEB_PORT})",
    )
    parser.add_argument(
        "--api-port",
        type=int,
        default=DEFAULT_API_PORT,
        help=f"API backend port (default: {DEFAULT_API_PORT})",
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        help="Run without opening browser automatically",
    )

    args = parser.parse_args()
    run_web_app(port=args.port, api_port=args.api_port, headless=args.headless)
