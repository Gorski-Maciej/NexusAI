import json
from db.models import Invoice, OutboxEvent

async def create_invoice_with_outbox(session, invoice_data: dict):
    """Zapisuje fakturę i zdarzenie outbox w jednej transakcji."""
    async with session.begin():
        # 1. Tworzymy fakturę
        new_invoice = Invoice(**invoice_data)
        session.add(new_invoice)

        # Wymuszamy flush, aby otrzymać ID faktury (jeśli potrzebne w zdarzeniu)
        await session.flush()

        # 2. Tworzymy zdarzenie outbox
        event = OutboxEvent(
            topic="invoices.new",
            payload=json.dumps({
                "invoice_id": new_invoice.id,
                "file_path": new_invoice.file_path,
                "correlation_id": "current_trace_id"
            })
        )
        session.add(event)

        # Po wyjściu z bloku 'begin' następuje COMMIT obu rekordów
        return new_invoice
