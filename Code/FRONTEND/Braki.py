# Fragment main.py
from ui.theme import ThemeManager
from ui.shortcuts import init_keyboard_handler
from ui.components.status_bar import NexusStatusBar
import flet as ft

async def main(page: ft.Page):
    # 1. Ustaw motyw
    page.theme = ThemeManager.get_dark_theme()

    # 2. Skróty klawiszowe
    init_keyboard_handler(page)

    # 3. Dodaj pasek stanu do nakładki (overlay) lub na dół strony
    status_bar = NexusStatusBar()
    page.add(
        ft.Column([
            ft.Container(content=ft.Text("Główny Content"), expand=True),
            status_bar
        ], expand=True)
    )

    # 4. Test połączenia
    status_bar.update_status(db_ok=True, nats_ok=False, message="Czekam na NATS...")




# frontend/api_client.py (Dodatkowe metody masowe)
class NexusApiClientBulk:
    # ... istniejące metody w NexusApiClient (AsyncNexusApiClient/NexusAPIClientUI) ...

    async def approve_bulk(self, invoice_ids: list[str]) -> bool:
        """Wysyła żądanie masowego zatwierdzenia faktur."""
        response = await self._client.post(
            "/invoices/bulk-approve",
            json={"ids": invoice_ids}
        )
        return response.status_code == 200

    async def get_high_confidence_ids(self, threshold: float = 0.95) -> list[str]:
        """Pobiera ID faktur, które AI oceniło jako pewne."""
        response = await self._client.get(f"/invoices/high-confidence?min={threshold}")
        return response.json()
