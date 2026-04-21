"""Flet UI for Nexus Accounting OS desktop frontend."""
from __future__ import annotations
import argparse
import asyncio
from decimal import Decimal, InvalidOperation
from typing import Final
import flet as ft
import httpx
from frontend.api_client import ApiConfig, InvoiceDTO, NexusApiClient, create_http_client

HTTP_CLIENT: httpx.Client | None = None
APP_NAME: Final[str] = "Nexus Accounting OS"

class InvoiceRegistryView(ft.Column):
    """Virtualized invoice register with optimistic update support."""
    def __init__(self) -> None:
        super().__init__(expand=True, spacing=12)
        self.items = ft.ListView(expand=1, spacing=10, auto_scroll=True)
        self.controls = [self.items]

    def set_rows(self, rows: list[InvoiceDTO]) -> None:
        """Replace entire register rows."""
        self.items.controls.clear()
        for row in rows:
            self.items.controls.append(self._build_tile(row))

    def prepend_row(self, row: InvoiceDTO) -> None:
        """Add new row at the top for fast user feedback."""
        self.items.controls.insert(0, self._build_tile(row))

    def replace_pending_row(self, optimistic_id: str, persisted: InvoiceDTO) -> None:
        """Swap optimistic row with backend-confirmed payload."""
        for index, control in enumerate(self.items.controls):
            if isinstance(control, ft.Container) and control.data == optimistic_id:
                self.items.controls[index] = self._build_tile(persisted)
                break

    def _build_tile(self, invoice: InvoiceDTO) -> ft.Container:
        status_suffix = " (pending...)" if invoice.pending else ""
        return ft.Container(
            data=invoice.id,
            padding=12,
            border_radius=8,
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST if invoice.pending else ft.colors.SURFACE,
            content=ft.Row(
                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                controls=[
                    ft.Text(f"{invoice.number}{status_suffix}"),
                    ft.Text(f"{invoice.amount_gross} {invoice.currency}")
                ]
            )
        )

class NexusApp:
    """Composable app controller separating UI from HTTP data layer."""
    def __init__(self, page: ft.Page, api: NexusApiClient) -> None:
        self.page = page
        self.api = api
        self.registry = InvoiceRegistryView()
        self.invoice_number = ft.TextField(label="Numer faktury", expand=True)
        self.invoice_gross = ft.TextField(label="Kwota brutto", width=180)
        self.feedback = ft.Text(value="", color=ft.colors.RED_400)

        # UI Components z drugiego bloku
        self.registry_table = ft.DataTable(
            expand=True,
            columns=[
                ft.DataColumn(ft.Text("Numer")),
                ft.DataColumn(ft.Text("NIP Kontrahenta")),
                ft.DataColumn(ft.Text("Kwota Brutto")),
                ft.DataColumn(ft.Text("Status")),
                ft.DataColumn(ft.Text("Data")),
            ],
            rows=[]
        )
        self.stats_row = ft.Row(spacing=20)
        self.loader = ft.ProgressBar(visible=False, color="blue")
        self.file_picker = ft.FilePicker(on_result=self._on_file_selected)
        self.page.overlay.append(self.file_picker)

    async def initialize(self) -> None:
        """Build layout and load initial register."""
        self.page.title = APP_NAME
        self.page.theme_mode = ft.ThemeMode.LIGHT
        self.page.horizontal_alignment = ft.CrossAxisAlignment.STRETCH
        self.page.padding = 30

        await self.refresh_data()
        self._build_main_layout()

    def _build_main_layout(self):
        """Buduje strukturę widoku."""
        layout = ft.Column(
            expand=True,
            controls=[
                ft.Row(
                    controls=[
                        ft.Text("NEXUS", size=32, weight="bold", color="blue800"),
                        ft.VerticalDivider(),
                        ft.Text("Panel Księgowy", size=20, color="grey700"),
                    ],
                    alignment=ft.MainAxisAlignment.START,
                ),
                ft.Divider(),
                ft.Text("Analityka (DuckDB)", weight="bold", size=16),
                self.stats_row,
                ft.Divider(),
                ft.Row(
                    controls=[
                        ft.ElevatedButton(
                            "Dodaj Fakturę (OCR)",
                            icon=ft.icons.UPLOAD_FILE,
                            on_click=lambda _: self.file_picker.pick_files()
                        ),
                        ft.IconButton(ft.icons.REFRESH, on_click=lambda _: self.refresh_data()),
                    ]
                ),
                self.loader,
                ft.Column([self.registry_table], scroll=ft.ScrollMode.ADAPTIVE, expand=True)
            ]
        )
        self.page.add(layout)

    async def refresh_data(self) -> None:
        """Pobiera dane z API (zarówno OLTP jak i OLAP)."""
        self.loader.visible = True
        self.page.update()
        try:
            invoices = await asyncio.to_thread(self.api.list_invoices)
            self._update_table(invoices)
            stats = await asyncio.to_thread(self.api.get_analytics_summary)
            self._update_stats(stats)
            self.feedback.value = ""
        except Exception as exc:
            self.page.show_snack_bar(ft.SnackBar(ft.Text(f"Błąd synchronizacji: {exc}")))
        self.loader.visible = False
        self.page.update()

    def _update_table(self, invoices: list[InvoiceDTO]):
        self.registry_table.rows.clear()
        for inv in invoices:
            status_color = {
                "APPROVED": ft.colors.GREEN,
                "PROCESSING": ft.colors.ORANGE,
                "MANUAL_REVIEW": ft.colors.BLUE,
                "FAILED": ft.colors.RED
            }.get(getattr(inv, "status", "NEW"), ft.colors.GREY)

            self.registry_table.rows.append(
                ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Text(inv.number or "W trakcie...")),
                        ft.DataCell(ft.Text(inv.customer_id or "-")),
                        ft.DataCell(ft.Text(f"{inv.amount_gross:.2f} {inv.currency}")),
                        ft.DataCell(ft.Chip(ft.Text(getattr(inv, "status", "NEW")), bgcolor=status_color)),
                        ft.DataCell(ft.Text(inv.created_at.strftime("%Y-%m-%d %H:%M"))),
                    ]
                )
            )

    def _update_stats(self, stats: dict):
        self.stats_row.controls = [
            self._build_stat_card("Suma Brutto", f"{stats.get('total_gross', 0):.2f} PLN", ft.icons.MONEY),
            self._build_stat_card("Liczba Faktur", str(stats.get('count', 0)), ft.icons.COPY),
            self._build_stat_card("Średnia Wartość", f"{stats.get('avg_amount', 0):.2f} PLN", ft.icons.ANALYTICS)
        ]

    def _build_stat_card(self, title: str, value: str, icon: str):
        return ft.Card(
            content=ft.Container(
                padding=15,
                content=ft.Row([
                    ft.Icon(icon, size=40, color="blue"),
                    ft.Column([
                        ft.Text(title, size=14, color="grey"),
                        ft.Text(value, size=20, weight="bold")
                    ])
                ])
            )
        )

    def _on_file_selected(self, e: ft.FilePickerResultEvent):
        # Placeholder dla wyboru pliku
        pass

def _read_bootstrap(page: ft.Page) -> ApiConfig:
    """Resolve dynamic backend port and bootstrap token from UI inputs."""
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--port", type=int)
    parser.add_argument("--token", type=str)
    args, unknown = parser.parse_known_args()

    qp_port = page.query_params.get("port")
    qp_token = page.query_params.get("token")

    port = args.port or (int(qp_port) if qp_port else None)
    token = args.token or qp_token

    if not port or not token:
        raise ValueError("Brak wymaganych parametrów startowych: port i token.")
    return ApiConfig(port=int(port), token=token)

async def main(page: ft.Page) -> None:
    """Flet app entrypoint."""
    try:
        config = _read_bootstrap(page)
        global HTTP_CLIENT
        HTTP_CLIENT = create_http_client(config)
        api = NexusApiClient(HTTP_CLIENT)
        app = NexusApp(page, api)
        await app.initialize()
    except Exception as exc:
        page.add(ft.Text(f"Błąd inicjalizacji UI: {exc}", color=ft.colors.RED_400))
        page.update()

if __name__ == "__main__":
    ft.app(target=main)
