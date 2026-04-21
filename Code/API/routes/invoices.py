from __future__ import annotations

import uuid
from datetime import datetime, timezone

from litestar import Controller, post
from litestar.datastructures import UploadFile
from litestar.enums import RequestEncodingType
from litestar.exceptions import ClientException
from litestar.connection import Request

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
        response = TaskResponse(
            task_id=task_id,
            status="QUEUED",
            message=(
                f"Invoice accepted: hash={saved.file_hash}, size={saved.size_bytes}, "
                f"workflow=UPLOADED->QUEUED ({datetime.now(timezone.utc).isoformat()})"
            ),
        ).model_dump()

        if idempotency_key:
            idempotency_store.save(idempotency_key, payload_hash, response)

        return TaskResponse(**response)
