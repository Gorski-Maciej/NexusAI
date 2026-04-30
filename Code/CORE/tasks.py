"""Asynchronous workflow tasks powered by Taskiq + NATS JetStream."""
from __future__ import annotations
import asyncio
import json
import os
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any
import lancedb
import msgspec
import psutil
import pyarrow as pa
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from statemachine import State, StateMachine
from taskiq import TaskiqEvents
from taskiq_nats import PullBasedJetStreamBroker
import nats

from core.config import AppConfig
from db.database import create_oltp_engine, create_session_factory, SessionLocal
from models.invoice import ActiveLearningPattern, Invoice
from models.outbox import OutboxEvent, OutboxStatus
from pipeline.ocr import DocumentProcessor, ReviewStatus
from core.logger import get_logger
from core.backup import BackupManager
from Roboton_Reflekton.vision_agent import VisionAgent
from services.fixed_assets import FixedAssetsService
from Roboton_Reflekton.ledger_client import TigerBeetleClient
from db.analytics import DuckDBManager

logger = get_logger()

NATS_URL = os.getenv("NEXUS_NATS_URL", "nats://127.0.0.1:4222")
broker = PullBasedJetStreamBroker(servers=NATS_URL, queue="nexus-ai-workers")

@dataclass(slots=True)
class InvoiceEventPayload:
    """Canonical payload embedded in Outbox events."""
    invoice_id: str
    image_path: str
    contractor_id: str

class InvoiceProcessingMachine(StateMachine):
    """Invoice lifecycle state machine."""
    new = State("NEW", initial=True)
    processing = State("PROCESSING")
    approved = State("APPROVED")
    manual_review = State("MANUAL_REVIEW")
    failed = State("FAILED")

    start = new.to(processing)
    approve = processing.to(approved)
    request_review = processing.to(manual_review)
    fail = processing.to(failed)


def pin_worker_cpu_affinity(reserve_core0: bool = True) -> None:
    """Pin worker process to non-UI CPU cores to protect Flet responsiveness."""
    process = psutil.Process()
    available = list(range(psutil.cpu_count(logical=False) or psutil.cpu_count() or 1))
    if reserve_core0 and len(available) > 1:
        target = [core for core in available if core != 0] or available
    else:
        target = available
    process.cpu_affinity(target)

def _get_lancedb_table() -> Any:
    """Open or create vector table in LanceDB backed by Arrow schema."""
    db = lancedb.connect("nexus_lancedb")
    schema = pa.schema([
        pa.field("id", pa.string()),
        pa.field("invoice_id", pa.string()),
        pa.field("contractor_id", pa.string()),
        pa.field("vector", pa.list_(pa.float32(), 4)),
        pa.field("checksum", pa.string()),
        pa.field("created_at", pa.timestamp("us", tz="UTC")),
        pa.field("is_preferred", pa.bool_()),
    ])
    if "invoice_vectors" in db.table_names():
        return db.open_table("invoice_vectors")
    return db.create_table("invoice_vectors", schema=schema)

def _simple_features(raw_text: str) -> list[float]:
    """Small dense vector placeholder; replace with embedding model output."""
    length = float(len(raw_text))
    digits = float(sum(ch.isdigit() for ch in raw_text))
    letters = float(sum(ch.isalpha() for ch in raw_text))
    lines = float(max(raw_text.count("\n"), 1))
    return [length, digits, letters, lines]

async def _pick_pending_outbox(session: AsyncSession) -> OutboxEvent | None:
    query = (
        select(OutboxEvent)
        .where(OutboxEvent.status == OutboxStatus.PENDING)
        .order_by(OutboxEvent.created_at.asc())
        .limit(1)
    )
    result = await session.execute(query)
    return result.scalar_one_or_none()

async def _update_invoice_status(session: AsyncSession, invoice_id: str, status: str) -> None:
    invoice = await session.get(Invoice, invoice_id)
    if invoice is None:
        return
    invoice.processing_status = status
    invoice.updated_at = datetime.now(timezone.utc)
    await session.flush()

@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def _startup(_state: Any) -> None:
    pin_worker_cpu_affinity(reserve_core0=True)

@broker.task(task_name="process_invoice_task")
async def process_invoice_task() -> dict[str, str]:
    """Consume pending outbox event and process invoice OCR + workflow update."""
    config = AppConfig(base_dir=Path.cwd())
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    processor = DocumentProcessor()
    vision_agent = VisionAgent()

    async with session_factory() as session:
        event = await _pick_pending_outbox(session)
        if event is None:
            return {"result": "NO_EVENTS"}

        machine = InvoiceProcessingMachine()
        machine.start()
        event.status = OutboxStatus.PROCESSED
        payload = msgspec.json.decode(event.payload.encode("utf-8"), type=InvoiceEventPayload)
        await _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        try:
            processed = await asyncio.to_thread(processor.process, Path(payload.image_path))
            vision = await vision_agent.analyze(Path(payload.image_path), processed.primary.raw_text)
            vision_payload = {
                "vendor_nip": vision.vendor_nip,
                "total_gross": vision.total_gross,
                "vat_rate": vision.vat_rate,
                "payment_status": vision.payment_status,
                "visual_anomalies_detected": vision.visual_anomalies_detected,
                "handwritten_notes_summary": vision.handwritten_notes_summary,
                "source": vision.source,
            }
            enriched_text = f"{processed.primary.raw_text}\n[vision]{json.dumps(vision_payload, ensure_ascii=False)}"
            vector = _simple_features(enriched_text)
            table = _get_lancedb_table()
            table.add([{
                "id": str(uuid.uuid4()),
                "invoice_id": payload.invoice_id,
                "contractor_id": payload.contractor_id,
                "vector": vector,
                "checksum": processed.primary.checksum,
                "created_at": datetime.now(timezone.utc),
                "is_preferred": False,
            }])
            logger.info(
                "VisionAgent(%s) processed invoice_id=%s anomalies=%s",
                vision.source,
                payload.invoice_id,
                vision.visual_anomalies_detected,
            )

            if processed.status == ReviewStatus.MANUAL_REVIEW:
                machine.request_review()
            else:
                machine.approve()
            await _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        except Exception as exc:
            machine.fail()
            event.status = OutboxStatus.FAILED
            event.payload = json.dumps({"error": str(exc), "original_payload": event.payload})
            await _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        await session.commit()
        await engine.dispose()
        return {"result": "OK"}

@broker.task(task_name="store_active_learning_feedback")
async def store_active_learning_feedback(contractor_id: str, corrected_payload: dict[str, Any]) -> dict[str, str]:
    """Persist user corrections for active learning and preferred retrieval."""
    config = AppConfig(base_dir=Path.cwd())
    engine = create_oltp_engine(config)
    session_factory = create_session_factory(engine)
    table = _get_lancedb_table()
    serialized = json.dumps(corrected_payload, ensure_ascii=False)
    vector = _simple_features(serialized)
    pattern_id = str(uuid.uuid4())

    async with session_factory() as session:
        session.add(
            ActiveLearningPattern(
                id=pattern_id,
                contractor_id=contractor_id,
                correction_payload=serialized,
            )
        )
        await session.commit()

    table.add([{
        "id": pattern_id,
        "invoice_id": "",
        "contractor_id": contractor_id,
        "vector": vector,
        "checksum": "",
        "created_at": datetime.now(timezone.utc),
        "is_preferred": True,
    }])

    await engine.dispose()
    return {"result": "LEARNING_SAVED"}

@broker.task(schedule=[{"cron": "0 16 * * *"}])
async def scheduled_backup_task():
    """Codziennie o 16:00"""
    config = AppConfig()
    manager = BackupManager(config)
    path = manager.create_encrypted_zip(config.encryption_key)
    logger.info(f"Backup wykonany pomyślnie: {path}")

@broker.task(schedule=[{"cron": "*/5 * * * *"}])
async def invoice_reconciliation_loop():
    """Wyszukuje porzucone faktury i podejmuje akcje naprawcze."""
    logger.info("[Watchdog] Uruchamianie skanowania spójności...")
    timeout_threshold = datetime.utcnow() - timedelta(minutes=10)

    async with SessionLocal() as session:
        stmt = select(Invoice).where(
            Invoice.status == "PROCESSING",
            Invoice.updated_at <= timeout_threshold
        )
        result = await session.execute(stmt)
        stuck_invoices = result.scalars().all()

        if not stuck_invoices:
            logger.debug("[Watchdog] System w pełni spójny. Brak porzuconych zadań.")
            return

        nc = await nats.connect("nats://localhost:4222")
        for invoice in stuck_invoices:
            if invoice.retry_count < 3:
                logger.warning(
                    f"[Watchdog] Faktura ID: {invoice.id} utknęła. "
                    f"Próba {invoice.retry_count + 1}/3. Re-kolejkowanie..."
                )
                invoice.retry_count += 1
                invoice.updated_at = datetime.utcnow()
                payload = json.dumps({
                    "invoice_id": invoice.id,
                    "file_path": invoice.file_path,
                    "is_retry": True
                })
                await nc.publish("invoices.new", payload.encode())
            else:
                logger.error(
                    f"[Watchdog] Faktura ID: {invoice.id} trwale uszkadza Workera. "
                    f"Zatrzymano próby. Status -> ERROR: TIMEOUT"
                )
                invoice.status = "ERROR: TIMEOUT"
                invoice.updated_at = datetime.utcnow()
                error_payload = json.dumps({
                    "status": "FAILED",
                    "message": "Przekroczono limit czasu (Krytyczny błąd przetwarzania)."
                })
                await nc.publish(f"invoices.status.{invoice.id}", error_payload.encode())

        await session.commit()
        await nc.close()


@broker.task(task_name="execute_monthly_depreciation", schedule=[{"cron": "0 0 1 * *"}])
async def execute_monthly_depreciation_task() -> dict[str, int]:
    """Posts due depreciation entries to TigerBeetle on the 1st day of each month."""
    duckdb = DuckDBManager(Path("app_data/nexus_olap.duckdb"))
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=TigerBeetleClient())
    posted = await service.execute_monthly_depreciation()
    logger.info("[FixedAssets] Posted %s depreciation entries", posted)
    return {"posted": posted}
