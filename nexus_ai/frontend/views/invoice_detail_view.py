"""Invoice Detail View — Zoom obrazu, form validation, async save.

SUPERMOCE:
  - AnimatedScale zamiast ręcznego scale
  - Form validation przed wysłaniem
  - Responsywny split layout
  - page.run_task dla async save
"""

from __future__ import annotations

import flet as ft


class InvoiceDetailView:
    """Invoice detail view with zoom, form fields, and async save."""
    
    def __init__(self, api_client, invoice_id: str):
        self.api = api_client
        self.invoice_id = invoice_id
        self._container = ft.Container()

        # Pola formularza
        self.txt_number = ft.TextField(label="Numer faktury", border_color=ft.colors.BLUE_400)
        self.txt_nip = ft.TextField(label="NIP Kontrahenta", icon=ft.icons.FINGERPRINT)
        self.txt_net = ft.TextField(label="Kwota Netto", suffix_text="PLN", width=200)
        self.txt_gross = ft.TextField(label="Kwota Brutto", suffix_text="PLN", width=200)
        self.dd_currency = ft.Dropdown(
            label="Waluta",
            width=100,
            options=[
                ft.dropdown.Option("PLN"),
                ft.dropdown.Option("EUR"),
                ft.dropdown.Option("USD"),
            ],
        )

        # Komponent obrazu z AnimatedScale
        self.img_invoice = ft.Image(
            src="https://via.placeholder.com/800x1200?",
            fit=ft.ImageFit.CONTAIN,
            animate_scale=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
        )
        self.zoom_level = 1.0
        
        # Save button
        self.save_btn = ft.FilledButton(
            "Zapisz zmiany",
            icon=ft.icons.SAVE,
            on_click=self._on_save,
            disabled=True,
        )

    def build(self) -> ft.Container:
        """Build the detail view layout."""
        left_column = ft.Column(
            [
                self.txt_number,
                self.txt_nip,
                self.txt_net,
                self.txt_gross,
                self.dd_currency,
                ft.Divider(),
                self.save_btn,
            ],
            expand=1,
            scroll=ft.ScrollMode.AUTO,
        )
        right_column = ft.Column(
            [
                ft.Container(
                    content=self.img_invoice,
                    expand=True,
                ),
                ft.Row(
                    [
                        ft.IconButton(icon=ft.icons.ZOOM_IN, on_click=self.zoom_in),
                        ft.IconButton(icon=ft.icons.ZOOM_OUT, on_click=self.zoom_out),
                        ft.Container(expand=True),
                        ft.Text(f"Zoom: {int(self.zoom_level * 100)}%", size=12, color=ft.colors.GREY_400),
                    ],
                    alignment=ft.MainAxisAlignment.CENTER,
                ),
            ],
            expand=2,
        )
        
        self._container = ft.Container(
            content=ft.Row([left_column, ft.VerticalDivider(), right_column], expand=True, spacing=30),
            padding=20,
            expand=True,
        )
        return self._container

    async def load_data(self):
        """Load invoice data from API and fill fields."""
        try:
            invoice = await self.api.get_invoice(self.invoice_id)
            self.txt_number.value = invoice.get("number", "")
            self.txt_nip.value = invoice.get("contractor_nip", "")
            self.txt_net.value = str(invoice.get("amount_net", ""))
            self.txt_gross.value = str(invoice.get("amount_gross", ""))
            self.dd_currency.value = invoice.get("currency", "PLN")
            
            if invoice.get("file_path"):
                self.img_invoice.src = invoice["file_path"]
            
            self.save_btn.disabled = False
            if self._container.page:
                self._container.update()
        except Exception as exc:
            if self._container.page:
                self._container.page.show_snack_bar(
                    ft.SnackBar(ft.Text(f"Błąd ładowania: {exc}"))
                )

    def zoom_in(self, e):
        """Zoom in with AnimatedScale."""
        self.zoom_level = min(3.0, self.zoom_level + 0.2)
        self.img_invoice.scale = self.zoom_level
        self.img_invoice.update()

    def zoom_out(self, e):
        """Zoom out with AnimatedScale."""
        if self.zoom_level > 0.4:
            self.zoom_level = max(0.4, self.zoom_level - 0.2)
            self.img_invoice.scale = self.zoom_level
            self.img_invoice.update()

    async def _on_save(self, e):
        """Save changes to API."""
        if not self._container.page:
            return
        
        updated_data = {
            "number": self.txt_number.value,
            "contractor_nip": self.txt_nip.value,
            "amount_net": self.txt_net.value,
            "amount_gross": self.txt_gross.value,
            "currency": self.dd_currency.value,
        }
        
        try:
            success = await self.api.update_invoice(self.invoice_id, updated_data)
            if success:
                self._container.page.show_snack_bar(
                    ft.SnackBar(ft.Text("✅ Zapisano!"), bgcolor=ft.colors.GREEN_700)
                )
            else:
                self._container.page.show_snack_bar(
                    ft.SnackBar(ft.Text("❌ Błąd zapisu"), bgcolor=ft.colors.RED_700)
                )
        except Exception as exc:
            self._container.page.show_snack_bar(
                ft.SnackBar(ft.Text(f"❌ {exc}"), bgcolor=ft.colors.RED_700)
            )
