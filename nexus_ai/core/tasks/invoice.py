"""Invoice processing tasks — OCR pipeline + state machine."""

from __future__ import annotations

import os
import uuid
from pathlib import Path
from typing import Any, ClassVar

import anyio
import msgspec
import pendulum
from msgspec import Struct
from sqlmodel import Session, select
from taskiq import TaskiqDepends

from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.di import get_config, get_db_session
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import Invoice, InvoiceStatus, OutboxEvent, OutboxStatus, ActiveLearningPattern
from nexus_ai.pipeline.ocr import DocumentProcessor, ReviewStatus
from nexus_ai.core.tasks.ml import (
    _MODEL_CACHE,
    OCR_INFERENCE_LIMITER,
    _get_vector_store,
    _simple_features,
)

logger = get_logger()

OCR_TASK_TIMEOUT_SEC = int(os.getenv("NEXUS_OCR_TIMEOUT_SEC", "300"))


async def _load_document_processor():
    return await anyio.to_thread.run_sync(DocumentProcessor)


class InvoiceEventPayload(Struct):
    invoice_id: str
    image_path: str
    contractor_id: str


class InvoiceProcessingMachine:
    """Invoice lifecycle state machine."""

    STATES: ClassVar[dict[str, InvoiceStatus]] = {
        "new": InvoiceStatus.NEW,
        "processing": InvoiceStatus.PROCESSING,
        "approved": InvoiceStatus.APPROVED,
        "manual_review": InvoiceStatus.MANUAL_REVIEW,
        "failed": InvoiceStatus.FAILED,
    }

    __slots__ = ("_state",)

    def __init__(self):
        self._state = "new"

    def start(self):
        self._state = "processing"

    def approve(self):
        if self._state == "processing":
            self._state = "approved"

    def request_review(self):
        if self._state == "processing":
            self._state = "manual_review"

    def fail(self):
        if self._state == "processing":
            self._state = "failed"

    @property
    def current_state(self):
        return _StateProxy(self.STATES[self._state])


class _StateProxy:
    __slots__ = ("id",)

    def __init__(self, state_id: str):
        self.id = state_id

    def __repr__(self):
        return f"State(id='{self.id}')"


def _pick_pending_outbox(session: Session) -> OutboxEvent | None:
    query = (
        select(OutboxEvent)
        .where(OutboxEvent.status == OutboxStatus.PENDING)
        .order_by(OutboxEvent.created_at.asc())
        .limit(1)
    )
    return session.execute(query).scalar_one_or_none()


def _update_invoice_status(session: Session, invoice_id: str, status: str) -> None:
    invoice = session.get(Invoice, invoice_id)
    if invoice is None:
        return
    invoice.processing_status = status
    invoice.updated_at = pendulum.now("UTC")
    session.flush()


@broker.task(
    task_name="process_invoice_task",
    labels={"service": "core", "operation": "invoice", "criticality": "high"},
    timeout=300.0,
)
async def process_invoice_task(
    config: AppConfig = TaskiqDepends(get_config),  # noqa: B008
    db: Session = TaskiqDepends(get_db_session),  # noqa: B008
) -> dict[str, str]:
    event = _pick_pending_outbox(db)
    if event is None:
        return {"result": "NO_EVENTS"}

    machine = InvoiceProcessingMachine()
    machine.start()
    event.status = OutboxStatus.PROCESSED
    payload = msgspec.json.decode(event.payload.encode("utf-8"), type=InvoiceEventPayload)
    _update_invoice_status(db, payload.invoice_id, machine.current_state.id)

    try:
        async with OCR_INFERENCE_LIMITER:
            processor = await _MODEL_CACHE.get("document_processor", _load_document_processor)
            processed = await anyio.to_thread.run_sync(processor.process, Path(payload.image_path))
        enriched_text = processed.primary.raw_text
        vector = _simple_features(enriched_text)
        store = _get_vector_store()
        conn = store._get_conn()
        conn.execute(
            """INSERT INTO invoice_vectors
               (id, invoice_id, contractor_id, vector, checksum, created_at, is_preferred)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                uuid.uuid4().hex,
                payload.invoice_id,
                payload.contractor_id,
                store._vector_to_blob(vector),
                processed.primary.checksum,
                pendulum.now("UTC").isoformat(),
                0,
            ),
        )
        conn.commit()
        if processed.status == ReviewStatus.MANUAL_REVIEW:
            machine.request_review()
        else:
            machine.approve()
        _update_invoice_status(db, payload.invoice_id, machine.current_state.id)
    except TimeoutError as exc:
        machine.fail()
        event.status = OutboxStatus.FAILED
        event.payload = msgspec_dumps(
            {"error": f"OCR_TIMEOUT:{exc}", "original_payload": event.payload}
        )
        _update_invoice_status(db, payload.invoice_id, machine.current_state.id)
    except Exception as exc:
        machine.fail()
        event.status = OutboxStatus.FAILED
        event.payload = msgspec_dumps({"error": str(exc), "original_payload": event.payload})
        _update_invoice_status(db, payload.invoice_id, machine.current_state.id)
    return {"result": "OK"}


@broker.task(
    task_name="store_active_learning_feedback",
    labels={"service": "core", "operation": "learning", "criticality": "low"},
    timeout=30.0,
)
async def store_active_learning_feedback(
    contractor_id: str,
    corrected_payload: dict[str, Any],
    db: Session = TaskiqDepends(get_db_session),  # noqa: B008
) -> dict[str, str]:
    serialized = msgspec_dumps(corrected_payload, ensure_ascii=False)
    vector = _simple_features(serialized)
    pattern_id = uuid.uuid4().hex
    db.add(
        ActiveLearningPattern(
            id=pattern_id,
            contractor_id=contractor_id,
            correction_payload=serialized,
        )
    )
    store = _get_vector_store()
    conn = store._get_conn()
    conn.execute(
        """INSERT INTO invoice_vectors
           (id, invoice_id, contractor_id, vector, checksum, created_at, is_preferred)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (
            pattern_id,
            "",
            contractor_id,
            store._vector_to_blob(vector),
            "",
            pendulum.now("UTC").isoformat(),
            1,
        ),
    )
    conn.commit()
    return {"result": "LEARNING_SAVED"}
