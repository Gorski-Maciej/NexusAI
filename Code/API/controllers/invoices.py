import uuid
import shutil
import json
from pathlib import Path
from litestar import Controller, get, post, Body
from litestar.status_codes import HTTP_201_CREATED
from litestar.enums import RequestEncodingType
from litestar.datastructures import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from api.schemas import InvoiceCreate, InvoiceResponse
from models.invoice import Invoice
from models.outbox import OutboxEvent

class InvoiceController(Controller):
    path = "/invoices"

    @get()
    async def list_invoices(self, db_session: AsyncSession) -> list[InvoiceResponse]:
        """Pobiera listę wszystkich faktur z SQLite."""
        result = await db_session.execute(select(Invoice).order_by(Invoice.created_at.desc()))
        invoices = result.scalars().all()
        return [
            InvoiceResponse(
                id=inv.id, number=inv.number, amount_net=inv.amount_net,
                amount_gross=inv.amount_gross, currency=inv.currency,
                status=inv.status, created_at=inv.created_at
            ) for inv in invoices
        ]

    @post(status_code=HTTP_201_CREATED)
    async def create_invoice(self, data: InvoiceCreate, db_session: AsyncSession) -> InvoiceResponse:
        """Dodaje nową fakturę i zapisuje event OCR w Outbox w tej samej transakcji."""
        invoice_id = str(uuid.uuid4())
        new_invoice = Invoice(
            id=invoice_id,
            number=data.number,
            contractor_nip=data.contractor_nip,
            file_path=data.file_path,
            amount_net=data.amount_net,
            amount_gross=data.amount_gross,
            status="NEW"
        )
        db_session.add(new_invoice)
        db_session.add(
            OutboxEvent(
                event_type="process_invoice_ocr",
                aggregate_id=invoice_id,
                payload=json.dumps(
                    {
                        "invoice_id": invoice_id,
                        "image_path": f"storage/scans/{invoice_id}.pdf",
                    },
                    ensure_ascii=False,
                ),
                status="PENDING",
                processed=False,
            )
        )
        await db_session.commit()

        return InvoiceResponse(
            id=new_invoice.id, number=new_invoice.number,
            amount_net=new_invoice.amount_net, amount_gross=new_invoice.amount_gross,
            currency=new_invoice.currency, status=new_invoice.status,
            created_at=new_invoice.created_at
        )

    @post("/upload")
    async def upload_invoice(
        self,
        data: UploadFile = Body(media_type=RequestEncodingType.MULTI_PART)
    ) -> dict:
        # 1. Definiujemy ścieżkę zapisu
        upload_dir = Path("data/uploads")
        upload_dir.mkdir(parents=True, exist_ok=True)
        file_path = upload_dir / data.filename

        # 2. Zapisujemy plik fizycznie na dysku
        with open(file_path, "wb") as f:
            shutil.copyfileobj(data.file, f)

        # 3. Zapisujemy rekord w bazie danych (SQLAlchemy)
        # Przykład logicznego dodania
        return {"filename": data.filename, "status": "uploaded"}
