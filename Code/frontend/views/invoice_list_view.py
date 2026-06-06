# frontend/views/invoice_list_view.py
import flet as ft


class InvoiceListView:
    def __init__(self, api_client):
        self.api = api_client

    def build(self):
        # Tutaj budujemy tabelę
        self.table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("Numer")),
                ft.DataColumn(ft.Text("NIP")),
                ft.DataColumn(ft.Text("Kwota")),
                ft.DataColumn(ft.Text("Status")),
            ],
            rows=[]
        )

        return ft.Column([
            ft.Text("Lista Faktur", style=ft.TextThemeStyle.HEADLINE_MEDIUM),
            ft.ElevatedButton("Odśwież", on_click=self.load_data),
            self.table
        ], scroll=ft.ScrollMode.ALWAYS)

    async def load_data(self, e=None):
        invoices = await self.api.list_invoices() # Wywołanie Twojego API
        self.table.rows = [
            ft.DataRow(cells=[
                ft.DataCell(ft.Text(inv.number)),
                ft.DataCell(ft.Text(inv.customer_id)),
                ft.DataCell(ft.Text(str(inv.amount_gross))),
                ft.DataCell(ft.Text("APPROVED"))
            ]) for inv in invoices
        ]
        self.table.update()
