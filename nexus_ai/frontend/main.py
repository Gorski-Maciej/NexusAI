# frontend/main.py (Zarządzanie NATS z poziomu UI)
import flet as ft
import nats

from nexus_ai.core.msgspec_utils import msgspec_loads


async def main(page: ft.Page):
    # Inicjalizacja UI...
    status_text = ft.Text("Oczekiwanie na przetworzenie faktur...", visible=False)
    upload_button = ft.ElevatedButton("Wyślij pliki")
    page.add(status_text)

    # Przechowujemy referencje do elementów na liście po ID
    invoice_rows = {}

    async def update_backpressure_state():
        # Tu zakładamy istnienie api_client do pobrania ilości zadań
        # pending_count = await api_client.get_pending_count()
        pending_count = 0
        if pending_count > 50:
            upload_button.disabled = True
            status_text.value = f"⚠️ System przetwarza {pending_count} faktur. Poczekaj na zakończenie..."
            status_text.visible = True
        else:
            upload_button.disabled = False
            status_text.visible = False
        page.update()

    async def nats_status_listener():
        nc = await nats.connect("nats://localhost:4222")
        # Subskrypcja na kanał ze statusami z workera Taskiq
        sub = await nc.subscribe("nexus.tasks.status")

        async for msg in sub.messages:
            data = msgspec_loads(msg.data)
            invoice_id = data.get("invoice_id")
            status = data.get("status")

            # Bezpieczna aktualizacja UI z innego wątku (NATS)
            if invoice_id in invoice_rows:
                row = invoice_rows[invoice_id]
                if status == "COMPLETED":
                    row.controls[1].value = "✅ Gotowe"
                    row.controls[1].color = ft.colors.GREEN
                elif status == "FAILED":
                    row.controls[1].value = "❌ Błąd OCR"
                    row.controls[1].color = ft.colors.RED
                page.update()

            # Przy każdym zakończonym zadaniu aktualizujemy stan przycisku
            await update_backpressure_state()

    page.run_task(nats_status_listener)

    page.add(
        ft.Column([
            upload_button,
            status_text,
            # ... reszta listy faktur ...
        ])
    )

if __name__ == "__main__":
    ft.app(target=main)
