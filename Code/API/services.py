import json
from nats.js.errors import HeaderError
from models.invoice import Invoice # Zakładane importy

async def publish_to_worker(nc, payload):
    # Pobieramy ID z bieżącego kontekstu (założenie)
    cid = correlation_id_ctx.get()

    # Tworzymy nagłówki NATS
    headers = {"X-Correlation-ID": cid}

    await nc.publish(
        "invoices.new",
        json.dumps(payload).encode(),
        headers=headers
    )

async def save_invoice_workflow(session, invoice_data: dict, replication_bridge):
    # KROK 1: Atomowy zapis do głównej bazy (OLTP)
    async with session.begin():
        new_invoice = Invoice(**invoice_data)
        session.add(new_invoice)

        # Flush pozwala nam uzyskać wygenerowane ID bez zamykania transakcji
        await session.flush()

        # Przygotowanie danych do repliki
        replica_data = {
            "id": new_invoice.id,
            "contractor_nip": new_invoice.contractor_nip,
            "amount_gross": new_invoice.amount_gross,
            "issue_date": new_invoice.issue_date
        }
