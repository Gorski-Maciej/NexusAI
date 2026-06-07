# frontend/main_ui.py (fragment)
import flet as ft

from nexus_ai.frontend.api_client import NexusAPIClientUI  # Używamy wersji z obsługą UI


def main(page: ft.Page):
    port = page.session.get("api_port")
    token = page.session.get("api_token")

    # Przekazujemy dynamiczny port i bezpieczny token
    base_url = f"http://127.0.0.1:{port}/api/v1" if port else "http://127.0.0.1:8000/api/v1"
    NexusAPIClientUI(base_url=base_url, token=token)

    # ... reszta logiki interfejsu (router, widoki) …
