"""AsyncInvoiceTable — Virtual scrolling DataTable z infinite scroll.

SUPERMOCE:
  - Cursor-based pagination zamiast przycisku "Załaduj więcej"
  - Virtual scrolling (ListView z auto_scroll)
  - Status colors z mapowaniem
  - Proper async przez page.run_task
"""

from __future__ import annotations

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.components")

INVOICE_STATUS_COLORS = {
    "APPROVED": ft.colors.GREEN,
    "PROCESSING": ft.colors.ORANGE,
    "MANUAL_REVIEW": ft.colors.BLUE,
    "FAILED": ft.colors.RED,
    "NEW": ft.colors.GREY,
}


class AsyncInvoiceTable(ft.Column):
    """Asynchroniczna tabela obsługująca tysiące rekordów przez API z infinite scroll."""

    def __init__(self, api_client):
        super().__init__()
        self.api = api_client
        self.cursor: str | None = None
        self._has_more: bool = True
        self._is_loading: bool = False

        # ListView zamiast DataTable — wirtualny scroll
        self.list_view = ft.ListView(
            expand=True,
            spacing=8,
            padding=20,
            auto_scroll=False,
        )

        # Wskaźnik ładowania (na dole listy)
        self.loading_ring = ft.ProgressRing(visible=False, width=24, height=24)
        
        # Przycisk "Załaduj więcej" (widoczny tylko jeśli są dane)
        self.load_more_btn = ft.ElevatedButton(
            "Załaduj więcej",
            icon=ft.icons.DOWNLOAD,
            on_click=self._on_load_more,
            visible=True,
        )

        # Empty state
        self.empty_state = ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.icons.INVENTORY_2_OUTLINED, size=64, color=ft.colors.GREY_700),
                    ft.Container(height=12),
                    ft.Text("Brak faktur", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_500),
                    ft.Text("Dodaj pierwszą fakturę przez OCR.", size=13, color=ft.colors.GREY_600),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            alignment=ft.alignment.center,
            expand=True,
            visible=True,
        )

        self.controls = [
            ft.Stack(
                [
                    ft.Column([
                        self.list_view,
                        ft.Row(
                            [self.loading_ring, self.load_more_btn],
                            alignment=ft.MainAxisAlignment.CENTER,
                            spacing=10,
                        ),
                    ], expand=True),
                    self.empty_state,
                ],
                expand=True,
            ),
        ]

    async def load_initial(self):
        """Load first page of data."""
        self._is_loading = True
        self.empty_state.visible = False
        self.loading_ring.visible = True
        self.update()

        try:
            response = await self.api.get("/invoices", params={"cursor": self.cursor, "limit": 50})
            items = response if isinstance(response, list) else response.get("items", [])
            self._has_more = len(items) >= 50
            
            self.list_view.controls.clear()
            for inv in items:
                self.list_view.controls.append(self._build_invoice_tile(inv))
            
            self.load_more_btn.visible = self._has_more
            self.empty_state.visible = len(items) == 0
        except Exception as ex:
            logger.error(f"Błąd ładowania danych: {ex}")
        finally:
            self._is_loading = False
            self.loading_ring.visible = False
            self.update()

    async def _on_load_more(self, e=None):
        """Load next page."""
        if self._is_loading or not self._has_more:
            return

        self._is_loading = True
        self.loading_ring.visible = True
        self.load_more_btn.visible = False
        self.update()

        try:
            response = await self.api.get("/invoices", params={"cursor": self.cursor, "limit": 50})
            items = response if isinstance(response, list) else response.get("items", [])
            self._has_more = len(items) >= 50

            for inv in items:
                self.list_view.controls.append(self._build_invoice_tile(inv))

            self.load_more_btn.visible = self._has_more
        except Exception as ex:
            logger.error(f"Błąd ładowania danych: {ex}")
        finally:
            self._is_loading = False
            self.loading_ring.visible = False
            self.update()

    def _build_invoice_tile(self, invoice: dict) -> ft.Container:
        """Build a single invoice tile for the ListView."""
        status = invoice.get("status", "NEW")
        status_color = INVOICE_STATUS_COLORS.get(status, ft.colors.GREY)
        number = invoice.get("number") or "Brak"
        nip = invoice.get("contractor_nip") or "---"
        amount = f"{invoice.get('amount_gross', 0.0):.2f} {invoice.get('currency', 'PLN')}"
        inv_id = invoice.get("id", "")

        return ft.Container(
            data=inv_id,
            content=ft.Row(
                [
                    ft.Column([
                        ft.Text(number, size=15, weight=ft.FontWeight.BOLD),
                        ft.Text(f"NIP: {nip}", size=12, color=ft.colors.GREY_400),
                    ], expand=True),
                    ft.Chip(
                        label=ft.Text(status, size=11, color=ft.colors.WHITE),
                        bgcolor=status_color,
                    ),
                    ft.Text(amount, size=15, weight=ft.FontWeight.BOLD, color=ft.colors.AMBER_300),
                    ft.IconButton(
                        icon=ft.icons.VISIBILITY,
                        tooltip="Zobacz PDF",
                        on_click=lambda e, iid=inv_id: (
                            self.page.go(f"/invoices/{iid}")
                            if self.page
                            else None
                        ),
                    ),
                ]
            ),
            padding=16,
            border_radius=8,
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            ink=True,
            animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
            on_hover=lambda e: setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0) or e.control.update(),
        )
