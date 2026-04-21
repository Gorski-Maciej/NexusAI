# ui/root.py
import flet as ft
import asyncio
from frontend.api_client import NexusAPIClientUI
from ui.ws_client import ProgressWebSocketClient
from ui.state import app_state

class NexusRootUI:
    """Główna klasa orkiestrująca interfejsem graficznym."""

    def __init__(self, page: ft.Page, process_manager):
        self.page = page
        self.process_manager = process_manager # Z main.py

        port = page.session.get("api_port")
        token = page.session.get("api_token")
        base_url = f"http://127.0.0.1:{port}/api/v1" if port else "http://127.0.0.1:8000/api/v1"
        self.api = NexusAPIClientUI(base_url=base_url, token=token)

        self.ws_client = ProgressWebSocketClient()

        # Elementy nawigacji
        self.main_content = ft.Container(expand=True, padding=20)
        self.snackbar = ft.SnackBar(content=ft.Text(""), action="OK")
        self.page.overlay.append(self.snackbar)

    async def build(self):
        """Zarządza globalnym układem (Layout) i rutowaniem."""
        self.page.title = "Nexus AI Workspace"
        self.page.padding = 0
        self.page.bgcolor = "#121212" # Ciemny motyw Enterprise

        # Załadowanie domyślnego widoku
        await self._load_dashboard()

        self.page.add(self.main_content)
        self.ws_client.start()

    async def _load_dashboard(self):
        try:
            summary = await self.api.get("/analytics/summary")

            self.main_content.content = ft.Column([
                ft.Text("Pulpit Finansowy", size=28, weight=ft.FontWeight.BOLD),
                ft.Row([
                    self._create_stat_card("Suma Netto", f"{summary.get('total_net', 0)} PLN"),
                    self._create_stat_card("Suma Brutto", f"{summary.get('total_gross', 0)} PLN"),
                    self._create_stat_card("Przeanalizowane", str(summary.get('count', 0))),
                ])
            ])
            self.page.update()
        except Exception as e:
            self.main_content.content = ft.Text(f"Błąd ładowania dashboardu: {e}", color="red")
            self.page.update()

    def _create_stat_card(self, title, value):
        return ft.Card(
            content=ft.Container(
                padding=20,
                content=ft.Column([
                    ft.Text(title, size=14, color="grey"),
                    ft.Text(value, size=24, weight="bold")
                ])
            )
        )
