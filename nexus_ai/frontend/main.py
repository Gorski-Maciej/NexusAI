"""frontend/main.py -- Flet UI entry point (Desktop + Web).

  - ft.app_async zamiast ft.app -- spójność z resztą projektu
  - page.window_center() -- wycentrowanie okna po starcie
  - page.client_storage -- zapamiętanie ostatniej ścieżki między sesjami
  - page.pubsub -- event-driven state management
  - page.run_task -- async listenery bez blokowania UI
  - page.on_route_change z TemplateRoute -- natywny URL routing
  - ft.SafeArea -- mobile-safe layout
  - page.theme_animation_style -- płynne przejścia między widokami
  - Obsługa trybu Web (WEB_BROWSER) przez --web flag
  - Głębokie linkowanie przez TemplateRoute
"""

from __future__ import annotations

import argparse

import flet as ft
from structlog import get_logger

from nexus_ai.frontend.web_app import run_web_app

logger = get_logger("nexus.ui.main")


async def main(page: ft.Page):
    """Desktop mode -- standardowy tryb okienkowy Flet.

      - page.window_center() -- okno pojawia się na środku ekranu
      - page.client_storage -- ostatnia ścieżka zapamiętana między uruchomieniami
      - page.session -- stan między widokami
      - page.theme_animation_style -- płynne przejścia
      - ft.SafeArea -- bezpieczny padding dla wszystkich platform
    """
    page.title = "Nexus AI -- System Księgowy"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#121212"
    page.window_width = 1280
    page.window_height = 900
    page.window_resizable = True
    page.window_min_width = 800
    page.window_min_height = 600

    page.window_center()

    page.add(ft.SafeArea(content=ft.Container(expand=True)))

    from nexus_ai.frontend.api_client import NexusApiClient
    from nexus_ai.frontend.router import NexusRouter

    api_client = NexusApiClient(
        base_url="http://127.0.0.1:8000/api/v1",
        token="",
    )

    router = NexusRouter(page=page, api_client=api_client)

    async def on_route_change(route_event: ft.RouteChangeEvent) -> None:
        await router.handle_route(page.route)

    page.on_route_change = on_route_change

    def on_view_pop(view_event: ft.ViewPopEvent) -> None:
        if len(page.views) > 1:
            page.views.pop()
            top_view = page.views[-1]
            page.go(top_view.route)

    page.on_view_pop = on_view_pop

    last_route = page.client_storage.get("nexus_last_route")
    initial_route = last_route if last_route else "/"
    page.go(initial_route)

    await page.update_async()


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
        run_web_app(port=args.port, api_port=args.api_port)
    else:
        run_desktop_app()
