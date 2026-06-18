"""frontend/main.py — Flet UI entry point (Desktop + Web).

SUPERMOCE:
  - ft.app_async zamiast ft.app — spójność z resztą projektu
  - Obsługa trybu Web (WEB_BROWSER) przez --web flag
  - page.pubsub zamiast ręcznego zarządzania stanem
  - page.run_task do async listenerów
"""

from __future__ import annotations

import argparse
import sys

import flet as ft
from structlog import get_logger

from nexus_ai.frontend.web_app import run_web_app

logger = get_logger("nexus.ui.main")


# ── Desktop mode ────────────────────────────────────────────────────────────


async def main(page: ft.Page):
    """Desktop mode — standardowy tryb okienkowy Flet."""
    # SUPERMOC: Konfiguracja strony dla Desktop
    page.title = "Nexus AI — System Księgowy"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#121212"
    page.window_width = 1280
    page.window_height = 900
    page.window_resizable = True
    page.window_min_width = 800
    page.window_min_height = 600

    # SUPERMOC: Routing przez NexusRouter
    from nexus_ai.frontend.api_client import NexusApiClient
    from nexus_ai.frontend.router import NexusRouter

    api_client = NexusApiClient(
        base_url="http://127.0.0.1:8000/api/v1",
        token="",
    )

    router = NexusRouter(page=page, api_client=api_client)

    # SUPERMOC: page.on_route_change z NexusRouter
    async def on_route_change(route_event: ft.RouteChangeEvent) -> None:
        await router.handle_route(page.route)

    page.on_route_change = on_route_change

    # SUPERMOC: page.on_view_pop dla stosu widoków (Desktop)
    def on_view_pop(view_event: ft.ViewPopEvent) -> None:
        if len(page.views) > 1:
            page.views.pop()
            top_view = page.views[-1]
            page.go(top_view.route)

    page.on_view_pop = on_view_pop

    # SUPERMOC: Start na dashboardzie
    page.go("/")
    await page.update_async()


# ── CLI ─────────────────────────────────────────────────────────────────────


def run_desktop_app() -> None:
    """Launch NexusAI in desktop window mode."""
    logger.info("Starting NexusAI Desktop App")
    ft.app_async(target=main)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NexusAI Flet App")
    parser.add_argument(
        "--web",
        action="store_true",
        help="Run as web application (browser mode)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8550,
        help="Web server port (default: 8550)",
    )
    parser.add_argument(
        "--api-port",
        type=int,
        default=8000,
        help="API backend port (default: 8000)",
    )

    args = parser.parse_args()

    if args.web:
        # SUPERMOC: Tryb Web — otwiera w przeglądarce z URL routingiem
        run_web_app(port=args.port, api_port=args.api_port)
    else:
        # Tryb Desktop — standardowe okno
        run_desktop_app()
