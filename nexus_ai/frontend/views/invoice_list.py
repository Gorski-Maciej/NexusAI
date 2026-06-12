# frontend/views/invoice_list.py

import flet as ft


def on_export_click(e, table, db, insert_epp_exporter, page):
    # 1. Pobierz zaznaczone faktury
    selected_ids = [row.data for row in table.rows if row.selected]
    invoices = db.get_invoices_by_ids(selected_ids)

    # 2. Wygeneruj plik
    exporter = insert_epp_exporter(invoices)
    epp_data = exporter.generate()

    # 3. Zapisz plik na dysku użytkownika
    with open("eksport_do_inserta.epp", "w", encoding="cp1250") as f:
        f.write(epp_data)

    page.show_snack_bar(ft.SnackBar(ft.Text("Plik .EPP został wygenerowany!")))


class InfiniteInvoiceList(ft.UserControl):
    def __init__(self, api_client):
        super().__init__()
        self.api = api_client
        self.invoices = []
        self.cursor = None
        self.is_loading = False

        # ListView natywnie zarządza pamięcią (renderuje tylko widoczne na ekranie)
        self.list_view = ft.ListView(
            expand=True, spacing=10, padding=20, on_scroll=self.handle_scroll
        )

    async def load_more(self):
        if self.is_loading:
            return

        self.is_loading = True
        self.list_view.controls.append(ft.ProgressRing())  # Wskaźnik ładowania na dole
        self.update()

        # Pobieranie danych z użyciem kursora (Cursor Pagination)
        new_data, next_cursor = await self.api.get_invoices(cursor=self.cursor, limit=50)
        self.cursor = next_cursor

        # Usuwamy spinner
        self.list_view.controls.pop()

        for inv in new_data:
            self.list_view.controls.append(ft.Text(f"{inv['number']} - {inv['amount_gross']}"))

        self.is_loading = False
        self.update()

    def handle_scroll(self, e: ft.OnScrollEvent):
        # Prosta detekcja dojechania do końca listy
        pass

    def build(self):
        return self.list_view
