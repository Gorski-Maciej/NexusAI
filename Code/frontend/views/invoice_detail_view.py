# frontend/views/invoice_detail_view.py

import flet as ft


class InvoiceDetailView:
    def __init__(self, api_client, invoice_id: str):
        self.api = api_client
        self.invoice_id = invoice_id

        # Pola formularza (referencje, by móc odczytać ich wartość)
        self.txt_number = ft.TextField(label="Numer faktury", border_color=ft.colors.BLUE_400)
        self.txt_nip = ft.TextField(label="NIP Kontrahenta", icon=ft.icons.FINGERPRINT)
        self.txt_net = ft.TextField(label="Kwota Netto", suffix_text="PLN", width=200)
        self.txt_gross = ft.TextField(label="Kwota Brutto", suffix_text="PLN", width=200)
        self.dd_currency = ft.Dropdown(
            label="Waluta",
            width=100,
            options=[ft.dropdown.Option("PLN"), ft.dropdown.Option("EUR"), ft.dropdown.Option("USD")]
        )

        # Komponent obrazu
        self.img_invoice = ft.Image(
            src="https://via.placeholder.com/800x1200?",
            fit=ft.ImageFit.CONTAIN
        )
        self.zoom_level = 1.0

    def build(self):
        left_column = ft.Column([
            self.txt_number, self.txt_nip, self.txt_net, self.txt_gross, self.dd_currency
        ], expand=1)
        right_column = ft.Column([
            self.img_invoice,
            ft.Row([
                ft.IconButton(icon=ft.icons.ZOOM_IN, on_click=self.zoom_in),
                ft.IconButton(icon=ft.icons.ZOOM_OUT, on_click=self.zoom_out)
            ])
        ], expand=2)
        return ft.Row([left_column, right_column], expand=True, spacing=30)

    async def load_data(self):
        """Pobiera dane faktury z API i wypełnia pola."""
        invoice = await self.api.get_invoice(self.invoice_id)
        self.txt_number.value = invoice.number
        self.txt_nip.value = invoice.contractor_nip
        self.txt_net.value = str(invoice.amount_net)
        self.txt_gross.value = str(invoice.amount_gross)
        self.dd_currency.value = invoice.currency

        # W desktopowej aplikacji src będzie ścieżką lokalną (file://...)
        if hasattr(invoice, 'file_path'):
            self.img_invoice.src = invoice.file_path
        self.img_invoice.update()
        self.txt_number.page.update()

    def zoom_in(self, e):
        self.zoom_level += 0.2
        self.img_invoice.scale = self.zoom_level
        self.img_invoice.update()

    def zoom_out(self, e):
        if self.zoom_level > 0.4:
            self.zoom_level -= 0.2
            self.img_invoice.scale = self.zoom_level
            self.img_invoice.update()
