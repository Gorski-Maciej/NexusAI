from __future__ import annotations

import hashlib
import os
import uuid
from pathlib import Path

import pendulum
from anyio import to_thread
from litestar import Controller, post
from litestar.connection import Request
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from nexus_ai.api.cache import clear_cache_async
from nexus_ai.api.i18n import resolve_language, t
from nexus_ai.api.rbac import owner_or_worker_guard
from nexus_ai.api.schemas import TaskResponse
from nexus_ai.api.services import ContentAddressableStorage, FileValidator, IdempotencyStore
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.audit_logger import AuditLogger

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
        raise ClientException(detail=f"Request body too large ({size} > {max_bytes})", status_code=413)


async def _write_chunk(temp_file, chunk: bytes) -> None:
    await to_thread.run_sync(temp_file.write, chunk)


class InvoiceController(Controller):
    """Invoice APIs (v1)."""

    path = "/api/v1/invoices"
    guards = [owner_or_worker_guard]

    @post("/upload", media_type=RequestEncodingType.MULTI_PART)
    async def upload_invoice(
        self,
        data: dict[str, UploadFile],
        request: Request,
        config: AppConfig,
        db_session: AsyncSession,
    ) -> TaskResponse:
        file_obj = data.get("file")
        language = resolve_language(request.headers.get("accept-language"))
        _validate_content_length(request.headers, MAX_INVOICE_UPLOAD_BYTES)
        if not file_obj:
            raise ClientException(detail=t("upload.missing_file", language=language), status_code=400)

        hasher = hashlib.sha256()
        total_size = 0
        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        first_chunk = b""
        try:
            with Path(temp_path).open("ab") as temp_file:
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
                    await _write_chunk(temp_file, chunk)
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
        idempotency_store = IdempotencyStore(config.idempotency_db_path)

        if idempotency_key:
            cached = idempotency_store.get(idempotency_key, payload_hash)
            if cached:
                return TaskResponse(**cached)

        saved = storage.finalize_temp_upload(temp_path=temp_path, digest=payload_hash, size_bytes=total_size, suffix=".pdf")

        task_id = str(uuid.uuid4())
        invoice_id = str(uuid.uuid4())
        event_payload = {
            "invoice_id": invoice_id,
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "file_path": str(saved.file_path),
            "received_at": pendulum.now("UTC").to_iso8601_string(),
        }

        await db_session.execute(
            text(
                """
                INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed)
                VALUES (:id, :event_type, :aggregate_id, :payload, :status, :processed)
                """
            ),
            {
                "id": str(uuid.uuid4()),
                "event_type": EVENT_INVOICE_UPLOADED,
                "aggregate_id": invoice_id,
                "payload": msgspec_dumps(event_payload),
                "status": "PENDING",
                "processed": False,
            },
        )
        await db_session.commit()
        await clear_cache_async(prefix="api.routes.analytics")

        # Immutable audit trail (hash-chained) for compliance-grade evidencing.
        audit_manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path, read_only=False)
        try:
            AuditLogger(audit_manager).append_event(
                "invoice.uploaded",
                {
                    "invoice_id": invoice_id,
                    "task_id": task_id,
                    "file_hash": saved.file_hash,
                    "file_path": saved.file_path,
                    "size_bytes": saved.size_bytes,
                    "received_at": event_payload["received_at"],
                },
            )
        finally:
            audit_manager.close()

        response = TaskResponse(
            task_id=task_id,
            status="QUEUED",
            message=(
                f"Invoice accepted: hash={saved.file_hash}, size={saved.size_bytes}, "
                f"workflow=UPLOADED->OUTBOX_PENDING ({pendulum.now('UTC').to_iso8601_string()})"
            ),
        )

        if idempotency_key:
            idempotency_store.save(idempotency_key, payload_hash, {
                "task_id": response.task_id,
                "status": response.status,
                "message": response.message,
            })

        return response

    @post("/upload-large", media_type=RequestEncodingType.MULTI_PART)
    async def upload_large_attachment(
        self,
        data: dict[str, UploadFile],
        request: Request,
        config: AppConfig,
        db_session: AsyncSession,
    ) -> TaskResponse:
        """Dedicated path for large attachments to avoid blocking the default OCR queue."""
        file_obj = data.get("file")
        language = resolve_language(request.headers.get("accept-language"))
        _validate_content_length(request.headers, MAX_ATTACHMENT_UPLOAD_BYTES)
        if not file_obj:
            raise ClientException(detail=t("upload.missing_file", language=language), status_code=400)
        idempotency_key = request.headers.get("idempotency-key")
        idempotency_store = IdempotencyStore(config.idempotency_db_path)

        hasher = hashlib.sha256()
        total_size = 0
        storage = ContentAddressableStorage(config.storage_dir)
        temp_path = storage.create_temp_upload_file()
        first_chunk = b""
        try:
            with Path(temp_path).open("ab") as temp_file:
                while True:
                    chunk = await file_obj.read(UPLOAD_CHUNK_SIZE)
                    if not chunk:
                        break
                    if not first_chunk:
                        first_chunk = chunk[:512]
                    total_size += len(chunk)
                    if total_size > min(config.max_attachment_upload_bytes, MAX_ATTACHMENT_UPLOAD_BYTES):
                        raise ClientException(
                            detail=t(
                                "upload.file_too_large",
                                language=language,
                                limit_mb=config.max_attachment_upload_mb,
                            ),
                            status_code=413,
                        )
                    hasher.update(chunk)
                    await _write_chunk(temp_file, chunk)
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
            normalized_content, detected_mime = FileValidator.validate_file(first_chunk, file_obj.filename or "")
            if normalized_content != first_chunk:
                with Path(temp_path).open("wb") as f:
                    f.write(normalized_content)
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
        saved = storage.finalize_temp_upload(temp_path=temp_path, digest=payload_hash, size_bytes=total_size, suffix=".bin")
        task_id = str(uuid.uuid4())
        attachment_id = str(uuid.uuid4())
        event_payload = {
            "attachment_id": attachment_id,
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "file_path": str(saved.file_path),
            "size_bytes": saved.size_bytes,
            "received_at": pendulum.now("UTC").to_iso8601_string(),
        }
        await db_session.execute(
            text(
                """
                INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed)
                VALUES (:id, :event_type, :aggregate_id, :payload, :status, :processed)
                """
            ),
            {
                "id": str(uuid.uuid4()),
                "event_type": EVENT_ATTACHMENT_LARGE_UPLOADED,
                "aggregate_id": attachment_id,
                "payload": msgspec_dumps(event_payload),
                "status": "PENDING",
                "processed": False,
            },
        )
        await db_session.commit()
        response = TaskResponse(task_id=task_id, status="QUEUED", message="Large attachment accepted for dedicated processing queue")
        if idempotency_key:
            idempotency_store.save(
                idempotency_key,
                payload_hash,
                {"task_id": response.task_id, "status": response.status, "message": response.message},
            )
        return response


class InvoiceControllerV2(InvoiceController):
    """Invoice APIs (v2)."""

    path = "/api/v2/invoices"
