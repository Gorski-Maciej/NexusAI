from __future__ import annotations

import os

from nexus_crypto import Sha256Hasher
import uuid
from pathlib import Path

import pendulum
from litestar import Controller, post
from litestar.background_tasks import BackgroundTask
from litestar.response import Response as LitestarResponse
from structlog import get_logger
from litestar.connection import Request
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from sqlmodel import text
from sqlmodel import Session

from nexus_ai.api.background_tasks import emit_invoice_created_bg
from nexus_ai.api.cache import clear_cache_async
from nexus_ai.api.i18n import resolve_language, t
from nexus_ai.api.rbac import owner_or_worker_guard
from nexus_ai.api.dto import (
    InvoiceUploadResponseDTO,
    TAG_INVOICES,
    TaskResponseDTO,
)
from nexus_ai.api.schemas import TaskResponse
from nexus_ai.api.services import ContentAddressableStorage, FileValidator, IdempotencyStore
from nexus_ai.core.config import AppConfig
import fsspec

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import OutboxStatus


logger = get_logger("nexus.api.invoices")

UPLOAD_CHUNK_SIZE = 1024 * 1024
MAX_INVOICE_UPLOAD_BYTES = 50 * 1024 * 1024
MAX_ATTACHMENT_UPLOAD_BYTES = 500 * 1024 * 1024
EVENT_INVOICE_UPLOADED = "invoice_uploaded"
EVENT_ATTACHMENT_LARGE_UPLOADED = "attachment_large_uploaded"



def _validate_content_length(headers: dict[str, str], max_bytes: int) -> None:
    value = headers.get("content-length")
    if not value:
        return
    try:
        size = int(value)
    except ValueError:
        return
    if size > max_bytes:
        raise ClientException(
            detail=f"Request body too large ({size} > {max_bytes})", status_code=413
        )


class InvoiceController(Controller):
    """Invoice APIs (v1) — upload i zarządzanie fakturami.

    Endpoints:
      - POST /api/v1/invoices/upload — upload faktury z outbox eventem i audit trail
      - POST /api/v1/invoices/upload-large — upload dużego załącznika (do 500MB)
    """

    path = "/invoices"
    guards = [owner_or_worker_guard]
    tags = [TAG_INVOICES]

    @post(
        "/upload",
        media_type=RequestEncodingType.MULTI_PART,
        return_dto=TaskResponseDTO,
        summary="Upload invoice file (v1)",
        description=(
            "Uploads an invoice file with streaming SHA-256 content-addressable storage. "
            "Validates MIME type, file size, and idempotency. "
            "Creates an outbox event for OCR processing and logs to audit trail."
        ),
        operation_id="uploadInvoiceV1",
    )
    async def upload_invoice(
        self,
        data: dict[str, UploadFile],
        request: Request,
        config: AppConfig,
        db_session: Session,
    ) -> TaskResponse:
        file_obj = data.get("file")
        language = resolve_language(request.headers.get("accept-language"))
        _validate_content_length(request.headers, MAX_INVOICE_UPLOAD_BYTES)
        if not file_obj:
            raise ClientException(
                detail=t("upload.missing_file", language=language), status_code=400
            )

        hasher = Sha256Hasher()
        total_size = 0
        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        first_chunk = b""
        try:
            # SUPERMOC fsspec: uniwersalne otwieranie plików
            async with await fsspec.open_async(temp_path, "ab") as temp_file:
                while True:
                    chunk = await file_obj.read(UPLOAD_CHUNK_SIZE)
                    if not chunk:
                        break
                    if not first_chunk:
                        first_chunk = chunk[:512]  # Zachowaj pierwsze 512 bajtów do walidacji MIME
                    total_size += len(chunk)
                    if total_size > min(config.max_invoice_upload_bytes, MAX_INVOICE_UPLOAD_BYTES):
                        raise ClientException(
                            detail=t(
                                "upload.file_too_large",
                                language=language,
                                limit_mb=config.max_invoice_upload_mb,
                            ),
                            status_code=413,
                        )
                    hasher.update(chunk)
                    await temp_file.write(chunk)
        except Exception:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise

        if total_size == 0:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise ClientException(detail=t("upload.empty_file", language=language), status_code=400)

        # Rozwiązanie 31: Walidacja MIME i sygnatur plików (tylko pierwsze 512 bajtów)
        # Nie nadpisujemy pliku — normalize_image jest wywoływana tylko dla walidacji,
        # a pełna normalizacja nastąpi w dalszym potoku przetwarzania.
        try:
            _, detected_mime = FileValidator.validate_file(first_chunk, file_obj.filename or "")
        except ValueError as ve:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise ClientException(detail=str(ve), status_code=415) from ve

        payload_hash = hasher.hexdigest()

        idempotency_key = request.headers.get("idempotency-key")
        idempotency_store = IdempotencyStore(db_session.bind)

        if idempotency_key:
            cached = idempotency_store.get(idempotency_key, payload_hash)
            if cached:
                return TaskResponse(**cached)

        saved = storage.finalize_temp_upload(
            temp_path=temp_path, digest=payload_hash, size_bytes=total_size, suffix=".pdf"
        )

        task_id = uuid.uuid4().hex
        invoice_id = uuid.uuid4().hex
        event_payload = {
            "invoice_id": invoice_id,
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "file_path": str(saved.file_path),
            "received_at": pendulum.now("UTC").to_iso8601_string(),
        }

        db_session.execute(
            text(
                """
                INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed)
                VALUES (:id, :event_type, :aggregate_id, :payload, :status, :processed)
                """
            ),
            {
                "id": uuid.uuid4().hex,
                "event_type": EVENT_INVOICE_UPLOADED,
                "aggregate_id": invoice_id,
                "payload": msgspec_dumps(event_payload),
                "status": OutboxStatus.PENDING.value,
                "processed": False,
            },
        )
        db_session.commit()
        await clear_cache_async(prefix="api.routes.analytics")

        # ── Emit InvoiceCreated event (fire-and-forget via BackgroundTask) ─
        invoice_created_metadata = {
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "size_bytes": saved.size_bytes,
            "source": "upload",
        }

        # Audit trail przez DecisionTraceLogger (hash chain w DuckDB decision_traces)
        try:
            import duckdb
            from nexus_ai.tax import DecisionTraceLogger
            
            conn = duckdb.connect(str(config.duckdb_path))
            try:
                logger_audit = DecisionTraceLogger(conn)
                logger_audit.log(
                    transaction_id=invoice_id,
                    context={
                        "invoice_id": invoice_id,
                        "task_id": task_id,
                        "file_hash": saved.file_hash,
                        "file_path": str(saved.file_path),
                        "size_bytes": int(saved.size_bytes),
                        "received_at": event_payload["received_at"],
                    },
                    verdict={"action": "UPLOADED", "source": "invoice_upload"},
                )
            finally:
                conn.close()
        except Exception:
            pass

        response_data = TaskResponse(
            task_id=task_id,status="QUEUED"
,
            message=(
                f"Invoice accepted: hash={saved.file_hash}, size={saved.size_bytes}, "
                f"workflow=UPLOADED->OUTBOX_PENDING ({pendulum.now('UTC').to_iso8601_string()})"
            ),
        )

        if idempotency_key:
            idempotency_store.save(
                idempotency_key,
                payload_hash,
                {
                    "task_id": response_data.task_id,
                    "status": response_data.status,
                    "message": response_data.message,
                },
            )

        # Zwróć Response z BackgroundTask — InvoiceCreated event po wysłaniu odpowiedzi
        return LitestarResponse(
            content=response_data,
            background=BackgroundTask(
                emit_invoice_created_bg,
                invoice_id=invoice_id,
                filename=file_obj.filename or "",
                file_path=str(saved.file_path),
                metadata=invoice_created_metadata,
            ),
        )

    @post(
        "/upload-large",
        media_type=RequestEncodingType.MULTI_PART,
        return_dto=TaskResponseDTO,
        summary="Upload large attachment (v1)",
        description=(
            "Dedicated path for large attachments (up to 500MB). "
            "Uses a separate event queue to avoid blocking the default OCR pipeline. "
            "Streaming SHA-256 validation with idempotency support."
        ),
        operation_id="uploadLargeAttachmentV1",
    )
    async def upload_large_attachment(
        self,
        data: dict[str, UploadFile],
        request: Request,
        config: AppConfig,
        db_session: Session,
    ) -> TaskResponse:
        """Dedicated path for large attachments to avoid blocking the default OCR queue."""
        file_obj = data.get("file")
        language = resolve_language(request.headers.get("accept-language"))
        _validate_content_length(request.headers, MAX_ATTACHMENT_UPLOAD_BYTES)
        if not file_obj:
            raise ClientException(
                detail=t("upload.missing_file", language=language), status_code=400
            )
        idempotency_key = request.headers.get("idempotency-key")
        idempotency_store = IdempotencyStore(db_session.bind)

        hasher = Sha256Hasher()
        total_size = 0
        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        first_chunk = b""
        try:
            # SUPERMOC fsspec: uniwersalne otwieranie plików
            async with await fsspec.open_async(temp_path, "ab") as temp_file:
                while True:
                    chunk = await file_obj.read(UPLOAD_CHUNK_SIZE)
                    if not chunk:
                        break
                    if not first_chunk:
                        first_chunk = chunk[:512]
                    total_size += len(chunk)
                    if total_size > min(
                        config.max_attachment_upload_bytes, MAX_ATTACHMENT_UPLOAD_BYTES
                    ):
                        raise ClientException(
                            detail=t(
                                "upload.file_too_large",
                                language=language,
                                limit_mb=config.max_attachment_upload_mb,
                            ),
                            status_code=413,
                        )
                    hasher.update(chunk)
                    await temp_file.write(chunk)
        except Exception:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise

        if total_size == 0:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise ClientException(detail=t("upload.empty_file", language=language), status_code=400)

        # Rozwiązanie 31: Walidacja MIME i sygnatur plików
        try:
            normalized_content, detected_mime = FileValidator.validate_file(
                first_chunk, file_obj.filename or ""
            )
            if normalized_content != first_chunk:
                # SUPERMOC fsspec: uniwersalne otwieranie plików
                async with await fsspec.open_async(temp_path, "wb") as f:
                    await f.write(normalized_content)
        except ValueError as ve:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise ClientException(detail=str(ve), status_code=415) from ve

        payload_hash = hasher.hexdigest()
        if idempotency_key:
            cached = idempotency_store.get(idempotency_key, payload_hash)
            if cached:
                return TaskResponse(**cached)
        saved = storage.finalize_temp_upload(
            temp_path=temp_path, digest=payload_hash, size_bytes=total_size, suffix=".bin"
        )
        task_id = uuid.uuid4().hex
        attachment_id = uuid.uuid4().hex
        event_payload = {
            "attachment_id": attachment_id,
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "file_path": str(saved.file_path),
            "size_bytes": saved.size_bytes,
            "received_at": pendulum.now("UTC").to_iso8601_string(),
        }
        db_session.execute(
            text(
                """
                INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed)
                VALUES (:id, :event_type, :aggregate_id, :payload, :status, :processed)
                """
            ),
            {
                "id": uuid.uuid4().hex,
                "event_type": EVENT_ATTACHMENT_LARGE_UPLOADED,
                "aggregate_id": attachment_id,
                "payload": msgspec_dumps(event_payload),
                "status": OutboxStatus.PENDING.value,
                "processed": False,
            },
        )
        db_session.commit()
        response = TaskResponse(
            task_id=task_id,status="QUEUED"
,
            message="Large attachment accepted for dedicated processing queue",
        )
        if idempotency_key:
            idempotency_store.save(
                idempotency_key,
                payload_hash,
                {
                    "task_id": response.task_id,
                    "status": response.status,
                    "message": response.message,
                },
            )
        return response


class InvoiceControllerV2(InvoiceController):
    """Invoice APIs (v2) — upload i zarządzanie fakturami.

    Endpoints:
      - POST /api/v2/invoices/upload — upload faktury z outbox eventem i audit trail
      - POST /api/v2/invoices/upload-large — upload dużego załącznika (do 500MB)
    """

    path = "/invoices"
    tags = [TAG_INVOICES]
