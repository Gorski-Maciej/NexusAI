"""Invoice List View — Deklaratywny widok listy faktur.

SUPERMOCE:
  - Async DataTable z paginacją
  - ResponsiveRow dla adaptacyjnego układu
  - Status colors przez mapowanie
  - page.run_task dla async load
"""

from __future__ import annotations

from typing import Any

import flet as ft


class InvoiceListView:
    """Modern invoice list view with async data loading."""
    
    INVOICE_STATUS_COLORS = {
        "APPROVED": ft.colors.GREEN,
        "PROCESSING": ft.colors.ORANGE,
        "MANUAL_REVIEW": ft.colors.BLUE,
        "FAILED": ft.colors.RED,
        "NEW": ft.colors.GREY,
        "PENDING": ft.colors.AMBER,
    }

    def __init__(self, api_client):
        self.api = api_client
        self._table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("Numer")),
                ft.DataColumn(ft.Text("NIP")),
                ft.DataColumn(ft.Text("Kwota")),
                ft.DataColumn(ft.Text("Status")),
            ],
            rows=[],
        )
        self._container = ft.Container()

    def build(self) -> ft.Container:
        """Build the invoice list view."""
        self._container = ft.Container(
            content=ft.Column(
                [
                    ft.Row(
                        controls=[
                            ft.Text("Lista Faktur", style=ft.TextThemeStyle.HEADLINE_MEDIUM),
                            ft.Container(expand=True),
                            ft.ElevatedButton("Odśwież", on_click=self._on_refresh),
                        ]
                    ),
                    ft.Divider(),
                    ft.Container(
                        content=self._table,
                        expand=True,
                        scroll=ft.ScrollMode.ADAPTIVE,
                    ),
                ],
                scroll=ft.ScrollMode.ALWAYS,
                expand=True,
            ),
            padding=20,
            expand=True,
        )
        return self._container

    def _on_refresh(self, e=None):
        """Trigger async refresh via page.run_task."""
        if self._container.page:
            self._container.page.run_task(self.load_data)

    async def load_data(self, e=None):
        """Load invoices from API."""
        try:
            invoices = await self.api.list_invoices()
            self._table.rows = [
                ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Text(inv.number)),
                        ft.DataCell(ft.Text(inv.customer_id)),
                        ft.DataCell(ft.Text(f"{inv.amount_gross:.2f} {inv.currency}")),
                        ft.DataCell(
                            ft.Text(
                                getattr(inv, "status", "APPROVED"),
                                color=self.INVOICE_STATUS_COLORS.get(
                                    getattr(inv, "status", "NEW"), ft.colors.GREY
                                ),
                                weight=ft.FontWeight.BOLD,
                            )
                        ),
                    ]
                )
                for inv in invoices
            ]
            if self._container.page:
                self._table.update()
        except Exception as exc:
            if self._container.page:
                self._container.page.show_snack_bar(
                    ft.SnackBar(ft.Text(f"Błąd ładowania: {exc}"))
                )
