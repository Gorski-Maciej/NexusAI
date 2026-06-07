import hashlib
import os
import uuid
from pathlib import Path

from anyio import to_thread
from litestar import Body, Controller, get, post
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from litestar.status_codes import HTTP_201_CREATED
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from nexus_ai.api.schemas import InvoiceCreate, InvoiceResponse, validate_invoice_create
from nexus_ai.api.services import ContentAddressableStorage
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps
from models.invoice import Invoice
from models.outbox import OutboxEvent


class InvoiceController(Controller):
    path = "/invoices"

    @get()
    async def list_invoices(
        self,
        db_session: AsyncSession,
        limit: int = 50,
        cursor: str | None = None,
    ) -> dict:
        """Pobiera listę faktur z paginacją kursorem (Rozwiązanie 32).

        Query params:
          - limit (int, default 50, max 200): max liczba faktur na stronę.
          - cursor (str, optional): token paginacji z poprzedniej odpowiedzi (next_cursor).

        Returns dict z items, next_cursor, has_more.
        """
        from api.services import CursorPagination

        safe_limit = max(1, min(int(limit), 200))
        query = select(Invoice).order_by(Invoice.created_at.desc(), Invoice.id.desc()).limit(safe_limit + 1)

        if cursor:
            decoded = CursorPagination.decode_cursor(cursor)
            if decoded:
                cursor_date, cursor_id = decoded
                query = query.where(
                    (Invoice.created_at < cursor_date) |
                    ((Invoice.created_at == cursor_date) & (Invoice.id < cursor_id))
                )

        result = await db_session.execute(query)
        invoices = result.scalars().all()

        has_more = len(invoices) > safe_limit
        if has_more:
            invoices = invoices[:safe_limit]

        items = [
            InvoiceResponse(
                id=inv.id, number=inv.number, amount_net=inv.amount_net,
                amount_gross=inv.amount_gross, currency=inv.currency,
                status=inv.status, created_at=inv.created_at
            ) for inv in invoices
        ]

        next_cursor = None
        if has_more:
            next_cursor = CursorPagination.build_next_cursor(items)

        return {
            "items": items,
            "next_cursor": next_cursor,
            "has_more": has_more,
            "limit": safe_limit,
        }

    @post(status_code=HTTP_201_CREATED)
    async def create_invoice(self, data: InvoiceCreate, db_session: AsyncSession) -> InvoiceResponse:
        """Dodaje nową fakturę i zapisuje event OCR w Outbox w tej samej transakcji."""
        try:
            validate_invoice_create(data)
        except ValueError as exc:
            raise ClientException(status_code=400, detail=str(exc)) from exc
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
                payload=msgspec_dumps(
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
        # Strumieniowy zapis uploadu + CAS hash (SHA-256) bez blokowania event loop.
        config = AppConfig()
        max_bytes = config.max_invoice_upload_bytes
        content_length = getattr(data, "headers", {}).get("content-length") if getattr(data, "headers", None) else None
        if content_length:
            try:
                if int(content_length) > max_bytes:
                    raise ClientException(status_code=413, detail="Request body too large")
            except ValueError:
                pass

        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        hasher = hashlib.sha256()
        chunk_size = 1024 * 1024
        total_size = 0

        try:
            with Path(temp_path).open("ab") as temp_file:
                while True:
                    chunk = await data.read(chunk_size)
                    if not chunk:
                        break
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        raise ClientException(status_code=413, detail="Request body too large")
                    hasher.update(chunk)
                    await to_thread.run_sync(temp_file.write, chunk)

            if total_size == 0:
                raise ClientException(status_code=400, detail="Empty file")

            digest = hasher.hexdigest()
            saved = storage.finalize_temp_upload(temp_path=temp_path, digest=digest, size_bytes=total_size, suffix=".pdf")
            return {
                "filename": Path(saved.file_path).name,
                "status": "uploaded",
                "size_bytes": saved.size_bytes,
                "file_hash": saved.file_hash,
                "file_path": saved.file_path,
            }
        except Exception:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise


    @post("/upload-large")
    async def upload_large_attachment(
        self,
        data: UploadFile = Body(media_type=RequestEncodingType.MULTI_PART)
    ) -> dict:
        """Dedicated path for very large attachments isolated from regular invoice uploads."""
        config = AppConfig()
        max_bytes = config.max_attachment_upload_bytes
        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        hasher = hashlib.sha256()
        chunk_size = 1024 * 1024
        total_size = 0

        try:
            with Path(temp_path).open("ab") as temp_file:
                while True:
                    chunk = await data.read(chunk_size)
                    if not chunk:
                        break
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        raise ClientException(status_code=413, detail="Request body too large")
                    hasher.update(chunk)
                    await to_thread.run_sync(temp_file.write, chunk)

            if total_size == 0:
                raise ClientException(status_code=400, detail="Empty file")

            saved = storage.finalize_temp_upload(
                temp_path=temp_path,
                digest=hasher.hexdigest(),
                size_bytes=total_size,
                suffix=".bin",
            )
            return {
                "filename": Path(saved.file_path).name,
                "status": "uploaded",
                "kind": "large_attachment",
                "size_bytes": saved.size_bytes,
                "file_hash": saved.file_hash,
                "file_path": saved.file_path,
            }
        except Exception:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise
