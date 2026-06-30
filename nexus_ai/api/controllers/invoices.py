import os
import uuid
from pathlib import Path

import fsspec
from anyio import to_thread
from litestar import Body, Controller, get, post
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from litestar.status_codes import HTTP_201_CREATED
from nexus_crypto import Sha256Hasher
from sqlmodel import Session, select

from nexus_ai.api.dto import (
    TAG_INVOICES,
    InvoiceCreateDTO,
    InvoiceListResponseDTO,
    InvoiceResponseDTO,
    InvoiceUploadResponseDTO,
)
from nexus_ai.api.schemas import (
    InvoiceCreate,
    InvoiceListResponse,
    InvoiceResponse,
    InvoiceUploadResponse,
    InvoiceUploadResponseLarge,
    validate_invoice_create,
)
from nexus_ai.api.services import ContentAddressableStorage
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import Invoice, InvoiceStatus, OutboxEvent, OutboxStatus


class InvoiceController(Controller):
    """REST API dla faktur -- CRUD + upload."""

    path = "/invoices"
    tags = [TAG_INVOICES]

    @get(
        summary="List invoices with cursor pagination",
        description=(
            "Returns a paginated list of invoices ordered by creation date (descending). "
            "Use ``nextCursor`` from the response to fetch the next page. "
            "Implements keyset pagination (Rozwiązanie 32) for O(1) page navigation "
            "even under concurrent inserts."
        ),
        operation_id="listInvoices",
        return_dto=InvoiceListResponseDTO,
    )
    def list_invoices(
        self,
        db_session: Session,
        limit: int = 50,
        cursor: str | None = None,
    ) -> InvoiceListResponse:
        """Pobiera listę faktur z paginacją kursorem (Rozwiązanie 32).

        Query params:
          - limit (int, default 50, max 200): max liczba faktur na stronę.
          - cursor (str, optional): token paginacji z poprzedniej odpowiedzi (next_cursor).
        """
        from api.services import CursorPagination

        safe_limit = max(1, min(int(limit), 200))
        query = (
            select(Invoice)
            .order_by(Invoice.created_at.desc(), Invoice.id.desc())
            .limit(safe_limit + 1)
        )

        if cursor:
            decoded = CursorPagination.decode_cursor(cursor)
            if decoded:
                cursor_date, cursor_id = decoded
                query = query.where(
                    (Invoice.created_at < cursor_date)
                    | ((Invoice.created_at == cursor_date) & (Invoice.id < cursor_id))
                )

        result = db_session.execute(query)
        invoices = result.scalars().all()

        has_more = len(invoices) > safe_limit
        if has_more:
            invoices = invoices[:safe_limit]

        items = [
            InvoiceResponse(
                id=inv.id,
                number=inv.number,
                amount_net=inv.amount_net,
                amount_gross=inv.amount_gross,
                currency=inv.currency,
                status=inv.status,
                created_at=inv.created_at,
            )
            for inv in invoices
        ]

        next_cursor = None
        if has_more:
            next_cursor = CursorPagination.build_next_cursor(items)

        return InvoiceListResponse(
            items=items,
            next_cursor=next_cursor,
            has_more=has_more,
            limit=safe_limit,
        )

    @post(
        status_code=HTTP_201_CREATED,
        summary="Create a new invoice",
        description=(
            "Creates a new invoice record and enqueues an OCR processing event "
            "via the Transactional Outbox pattern in the same DB transaction. "
            "Validates NIP checksum and field constraints."
        ),
        operation_id="createInvoice",
        dto=InvoiceCreateDTO,
        return_dto=InvoiceResponseDTO,
    )
    def create_invoice(self, data: InvoiceCreate, db_session: Session) -> InvoiceResponse:
        """Dodaje nową fakturę i zapisuje event OCR w Outbox w tej samej transakcji."""
        try:
            validate_invoice_create(data)
        except ValueError as exc:
            raise ClientException(status_code=400, detail=str(exc)) from exc
        invoice_id = uuid.uuid4().hex
        new_invoice = Invoice(
            id=invoice_id,
            number=data.number,
            contractor_nip=data.contractor_nip,
            file_path=data.file_path,
            amount_net=data.amount_net,
            amount_gross=data.amount_gross,
            currency=data.currency,
            issue_date=data.issue_date or None,
            status=InvoiceStatus.NEW,
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
                status=OutboxStatus.PENDING,
                processed=False,
            )
        )
        db_session.commit()

        return InvoiceResponse(
            id=new_invoice.id,
            number=new_invoice.number,
            contractor_nip=new_invoice.contractor_nip,
            file_path=new_invoice.file_path,
            issue_date=new_invoice.issue_date,
            amount_net=new_invoice.amount_net,
            amount_gross=new_invoice.amount_gross,
            currency=new_invoice.currency,
            status=new_invoice.status,
            retry_count=new_invoice.retry_count,
            processing_status=new_invoice.processing_status,
            created_at=new_invoice.created_at,
            updated_at=new_invoice.updated_at,
        )

    @post(
        "/upload",
        summary="Upload invoice file",
        description=(
            "Streaming upload with SHA-256 content-addressable storage. "
            "Validates MIME type and file size. Returns task ID "
            "for tracking OCR processing progress. "
            "Supports idempotency via ``Idempotency-Key`` header."
        ),
        operation_id="uploadInvoiceFile",
        return_dto=InvoiceUploadResponseDTO,
    )
    async def upload_invoice(
        self, data: UploadFile = Body(media_type=RequestEncodingType.MULTI_PART)
    ) -> InvoiceUploadResponse:
        """Strumieniowy zapis uploadu + CAS hash (SHA-256) bez blokowania event loop."""
        config = AppConfig.create()
        max_bytes = config.max_invoice_upload_bytes
        content_length = (
            getattr(data, "headers", {}).get("content-length")
            if getattr(data, "headers", None)
            else None
        )
        if content_length:
            try:
                if int(content_length) > max_bytes:
                    raise ClientException(status_code=413, detail="Request body too large")
            except ValueError:
                pass

        storage = ContentAddressableStorage(str(config.storage_dir_path))
        temp_path = storage.create_temp_upload_file()
        hasher = Sha256Hasher()
        chunk_size = 1024 * 1024
        total_size = 0

        try:
            async with await fsspec.open_async(temp_path, "ab") as temp_file:
                while True:
                    chunk = await data.read(chunk_size)
                    if not chunk:
                        break
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        raise ClientException(status_code=413, detail="Request body too large")
                    hasher.update(chunk)
                    await temp_file.write(chunk)

            if total_size == 0:
                raise ClientException(status_code=400, detail="Empty file")

            digest = hasher.hexdigest()
            saved = await storage.finalize_temp_upload(
                temp_path=temp_path, digest=digest, size_bytes=total_size, suffix=".pdf"
            )
            return InvoiceUploadResponse(
                filename=Path(saved.file_path).name,
                status="uploaded",
                size_bytes=saved.size_bytes,
                file_hash=saved.file_hash,
                file_path=saved.file_path,
            )
        except Exception:
            try:
                await to_thread.run_sync(os.unlink, temp_path)
            except FileNotFoundError:
                pass
            raise

    @post(
        "/upload-large",
        summary="Upload large attachment (dedicated path)",
        description=(
            "Isolated path for very large attachments (up to 500MB). "
            "Uses a separate event queue to avoid blocking the default OCR pipeline. "
            "Streaming SHA-256 validation with content-addressable storage."
        ),
        operation_id="uploadLargeAttachment",
        return_dto=InvoiceUploadResponseDTO,
    )
    async def upload_large_attachment(
        self, data: UploadFile = Body(media_type=RequestEncodingType.MULTI_PART)
    ) -> InvoiceUploadResponseLarge:
        """Dedicated path for very large attachments isolated from regular invoice uploads."""
        config = AppConfig.create()
        max_bytes = config.max_attachment_upload_bytes
        storage = ContentAddressableStorage(str(config.storage_dir_path))
        temp_path = storage.create_temp_upload_file()
        hasher = Sha256Hasher()
        chunk_size = 1024 * 1024
        total_size = 0

        try:
            async with await fsspec.open_async(temp_path, "ab") as temp_file:
                while True:
                    chunk = await data.read(chunk_size)
                    if not chunk:
                        break
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        raise ClientException(status_code=413, detail="Request body too large")
                    hasher.update(chunk)
                    await temp_file.write(chunk)

            if total_size == 0:
                raise ClientException(status_code=400, detail="Empty file")

            saved = await storage.finalize_temp_upload(
                temp_path=temp_path,
                digest=hasher.hexdigest(),
                size_bytes=total_size,
                suffix=".bin",
            )
            return InvoiceUploadResponseLarge(
                filename=Path(saved.file_path).name,
                status="uploaded",
                kind="large_attachment",
                size_bytes=saved.size_bytes,
                file_hash=saved.file_hash,
                file_path=saved.file_path,
            )
        except Exception:
            try:
                await to_thread.run_sync(os.unlink, temp_path)
            except FileNotFoundError:
                pass
            raise
