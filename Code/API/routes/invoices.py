from __future__ import annotations

import uuid
import json
from datetime import datetime, timezone

from litestar import Controller, post
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from litestar.connection import Request
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import AppConfig
from api.schemas import TaskResponse
from api.services import ContentAddressableStorage, IdempotencyStore


class InvoiceController(Controller):
    """Invoice APIs (v1)."""

    path = "/api/v1/invoices"

    @post("/upload", media_type=RequestEncodingType.MULTI_PART)
    async def upload_invoice(
        self,
        data: dict[str, UploadFile],
        request: Request,
        config: AppConfig,
        db_session: AsyncSession,
    ) -> TaskResponse:
        file_obj = data.get("file")
        if not file_obj:
            raise ClientException(detail="Brak pola 'file'", status_code=400)

        payload = await file_obj.read()
        if not payload:
            raise ClientException(detail="Pusty plik", status_code=400)

        idempotency_key = request.headers.get("idempotency-key")
        idempotency_store = IdempotencyStore(config.idempotency_db_path)
        payload_hash = idempotency_store.hash_payload(payload)

        if idempotency_key:
            cached = idempotency_store.get(idempotency_key, payload_hash)
            if cached:
                return TaskResponse(**cached)

        storage = ContentAddressableStorage(config.storage_dir)
        saved = storage.put(payload=payload, suffix=".pdf")

        task_id = str(uuid.uuid4())
        invoice_id = str(uuid.uuid4())
        event_payload = {
            "invoice_id": invoice_id,
            "task_id": task_id,
            "file_hash": saved.file_hash,
            "file_path": str(saved.path),
            "received_at": datetime.now(timezone.utc).isoformat(),
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
                "event_type": "INVOICE_UPLOADED",
                "aggregate_id": invoice_id,
                "payload": json.dumps(event_payload),
                "status": "PENDING",
                "processed": False,
            },
        )
        await db_session.commit()

        response = TaskResponse(
            task_id=task_id,
            status="QUEUED",
            message=(
                f"Invoice accepted: hash={saved.file_hash}, size={saved.size_bytes}, "
                f"workflow=UPLOADED->OUTBOX_PENDING ({datetime.now(timezone.utc).isoformat()})"
            ),
        )

        if idempotency_key:
            idempotency_store.save(idempotency_key, payload_hash, {
                "task_id": response.task_id,
                "status": response.status,
                "message": response.message,
            })

        return response
