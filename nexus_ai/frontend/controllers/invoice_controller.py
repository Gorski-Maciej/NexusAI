# frontend/controllers/invoice_controller.py

import flet as ft


class OptimisticField(ft.UserControl):
    def __init__(self, api_client, invoice_id: str, field_name: str, initial_value: str):
        super().__init__()
        self.api = api_client
        self.invoice_id = invoice_id
        self.field_name = field_name
        self.original_value = initial_value

        self.text_field = ft.TextField(
            value=initial_value,
            on_submit=self.handle_update
        )

    async def handle_update(self, e):
        new_value = self.text_field.value
        if new_value == self.original_value:
            return

        # 1. Optimistic Update (zakładamy sukces, UI reaguje natychmiast)
        self.text_field.border_color = ft.colors.GREEN_400
        self.original_value = new_value
        self.update()

        # 2. Strzał do API w tle
        try:
            success = await self.api.update_invoice(
                self.invoice_id,
                {self.field_name: new_value}
            )
            if not success:
                self.text_field.border_color = ft.colors.RED_400
                self.update()
        except Exception:
            self.text_field.border_color = ft.colors.RED_400
            self.update()

    def build(self):
        return self.text_field
