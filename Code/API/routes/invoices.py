import uuid
from pathlib import Path
from litestar import Controller, get, post, put, Parameter
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from core.config import AppConfig
from db.pagination import CursorPagination
from models.invoice import Invoice
from api.schemas import InvoiceResponse, TaskResponse
from worker.broker import broker # Twój broker Taskiq (NATS)
from worker.tasks import process_invoice_task # Zadanie analizy AI

class InvoiceController(Controller):
    path = "/api/v1/invoices"

    @post("/upload", media_type=RequestEncodingType.MULTI_PART)
    async def upload_invoice(
        self,
        data: dict[str, UploadFile],
        config: AppConfig
    ) -> TaskResponse:
        """
        Odbiera plik PDF z Flet UI, zapisuje go na dysku
        i zleca asynchroniczną analizę OCR/AI przez NATS.
        """
        file_obj = data.get("file")
        # logika przetwarzania pliku...

    @get("/search")
    async def search_invoices(
        self,
        db_session: AsyncSession,
        nip: str | None = Parameter(query="nip", default=None),
        min_amount: float | None = Parameter(query="min_amount", default=None),
        status: str | None = Parameter(query="status", default=None),
    ) -> list[InvoiceResponse]:
        """Wyszukiwanie faktur z dynamicznymi filtrami."""
        query = select(Invoice)
        filters = []

        if nip:
            filters.append(Invoice.contractor_nip == nip)
        if min_amount:
            filters.append(Invoice.amount_gross >= min_amount)
        if status:
            filters.append(Invoice.status == status)

        if filters:
            query = query.where(and_(*filters))

        result = await db_session.execute(query.order_by(Invoice.created_at.desc()))
        return [InvoiceResponse.model_validate(r) for r in result.scalars().all()]
