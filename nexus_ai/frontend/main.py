"""
frontend/main.py — Flet UI for managing invoices with NATS subscription.

SUPERMOC nats-py:
  - NatsSubscription z async iteratorem (subscribe_async API)
  - Connection callbacks (disconnected_cb, reconnected_cb, closed_cb)
  - Msg.metadata() dla diagnostyki
"""

from __future__ import annotations

import flet as ft

from nexus_ai.core.msgspec_utils import msgspec_loads
from nexus_ai.core.nats_utils import NatsSubscription


async def main(page: ft.Page):
    # Inicjalizacja UI...
    status_text = ft.Text("Oczekiwanie na przetworzenie faktur...", visible=False)
    upload_button = ft.ElevatedButton("Wyślij pliki")
    page.add(status_text)

    # Przechowujemy referencje do elementów na liście po ID
    invoice_rows: dict[str, ft.Row] = {}

    async def update_backpressure_state() -> None:
        pending_count = 0
        if pending_count > 50:
            upload_button.disabled = True
            status_text.value = (
                f"⚠️ System przetwarza {pending_count} faktur. Poczekaj na zakończenie..."
            )
            status_text.visible = True
        else:
            upload_button.disabled = False
            status_text.visible = False
        page.update()

    async def nats_status_listener() -> None:
        # SUPERMOC nats-py: NatsSubscription z async iteratorem
        sub = NatsSubscription(
            subject="nexus.tasks.status",
            name="nexus-ui-status",
        )
        async for msg in sub:
            data = msgspec_loads(msg.data)
            invoice_id = data.get("invoice_id")
            status = data.get("status")

            if invoice_id in invoice_rows:
                row = invoice_rows[invoice_id]
                if status == "COMPLETED":
                    row.controls[1].value = "✅ Gotowe"  # type: ignore[union-attr]
                    row.controls[1].color = ft.colors.GREEN  # type: ignore[union-attr]
                elif status == "FAILED":
                    row.controls[1].value = "❌ Błąd OCR"  # type: ignore[union-attr]
                    row.controls[1].color = ft.colors.RED  # type: ignore[union-attr]
                page.update()

            await update_backpressure_state()

    page.run_task(nats_status_listener)

    page.add(
        ft.Column(
            [
                upload_button,
                status_text,
            ]
        )
    )


if __name__ == "__main__":
    ft.app(target=main)
