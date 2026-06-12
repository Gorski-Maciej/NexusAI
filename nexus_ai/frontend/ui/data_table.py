# ui/components/data_table.py
import flet as ft
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusAPIClientUI

logger = get_logger("nexus.ui.components")


class AsyncInvoiceTable(ft.Column):
    """Asynchroniczna tabela obsługująca tysiące rekordów przez API."""

    def __init__(self, api_client: NexusAPIClientUI):
        super().__init__()
        self.api = api_client
        self.cursor: str | None = None
        self.is_loading = False

        self.table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("Numer")),
                ft.DataColumn(ft.Text("NIP")),
                ft.DataColumn(ft.Text("Kwota Brutto"), numeric=True),
                ft.DataColumn(ft.Text("Status")),
                ft.DataColumn(ft.Text("Akcje")),
            ],
            rows=[],
        )

        self.loading_ring = ft.ProgressRing(visible=False)
        self.load_more_btn = ft.ElevatedButton(
            "Załaduj więcej", icon=ft.icons.DOWNLOAD, on_click=self._load_next_page
        )
        self.controls = [self.table, self.loading_ring, self.load_more_btn]

    async def _load_next_page(self, e=None):
        self._toggle_loading(True)
        try:
            # Zakładamy API z obsługą kursora
            response = await self.api.get("/invoices", params={"cursor": self.cursor})
            invoices = response if isinstance(response, list) else response.get("items", [])

            for invoice in invoices:
                status_color = (
                    ft.colors.GREEN if invoice.get("status") == "APPROVED" else ft.colors.ORANGE
                )
                row = ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Text(invoice.get("number") or "Brak")),
                        ft.DataCell(ft.Text(invoice.get("contractor_nip") or "---")),
                        ft.DataCell(
                            ft.Text(
                                f"{invoice.get('amount_gross', 0.0):.2f} {invoice.get('currency', 'PLN')}"
                            )
                        ),
                        ft.DataCell(
                            ft.Text(
                                invoice.get("status", "NEW"),
                                color=status_color,
                                weight=ft.FontWeight.BOLD,
                            )
                        ),
                        ft.DataCell(
                            ft.IconButton(
                                icon=ft.icons.VISIBILITY,
                                tooltip="Zobacz PDF",
                                on_click=lambda e, id=invoice.get("id"): self.page.go(
                                    f"/invoices/{id}"
                                ),
                            )
                        ),
                    ]
                )
                self.table.rows.append(row)
        except Exception as ex:
            logger.error(f"Błąd ładowania danych: {ex}")
        finally:
            self._toggle_loading(False)

    def _toggle_loading(self, show: bool):
        self.loading_ring.visible = show
        self.load_more_btn.visible = not show
        self.update()
