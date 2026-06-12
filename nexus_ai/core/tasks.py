"""Asynchronous workflow tasks powered by Taskiq + NATS JetStream."""
from __future__ import annotations

import os
import uuid

import anyio
from msgspec import Struct
from pathlib import Path
from typing import Any

import msgspec
import pendulum
import psutil
from sqlalchemy import select
from sqlalchemy.orm import Session
from taskiq import TaskiqEvents
from taskiq_nats import PullBasedJetStreamBroker

from nexus_ai.core.backup import BackupManager
from nexus_ai.core.cache import get_cache
from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger

class TimedModelCache:
    """Cache instancji modeli ML z TTL, wsparty przez NexusCache.

    Model objects (DocumentProcessor, VisionAgent) nie są msgspec-serializowalne,
    więc przechowujemy je w osobnym słowniku RAM. NexusCache zarządza TTL:
    przechowuje timestamp ostatniego odświeżenia dla każdego klucza i odpowiada
    za politykę wygaśnięcia — gdy nexus_cache.clear() zostanie wywołany,
    modele również zostaną unieważnione pośrednio przez brak wpisów TTL.

    Gdy w przyszłości modele staną się msgspec-serializowalne, L2 (SQLite)
    włączy się automatycznie bez zmian w tym kodzie.
    """
    def __init__(self, ttl_seconds: int = 600):
        self._nexus = get_cache(default_ttl=ttl_seconds)
        self._models: dict[str, object] = {}
        self._ttl = ttl_seconds

    async def get(self, key: str, loader):
        import time
        now = time.monotonic()
        ttl_key = f"_model_cache_ttl:{key}"

        # Sprawdź NexusCache — czy TTL jeszcze ważny?
        ttl_entry = self._nexus.get_sync(ttl_key)
        if ttl_entry is not None and key in self._models:
            stored_at: float = ttl_entry
            if now - stored_at < self._ttl:
                # Odśwież timestamp w NexusCache
                self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
                return self._models[key]
            # Wygasło — usuń model
            self._models.pop(key, None)

        # Miss lub wygasło — załaduj świeży model
        model = await loader()
        self._models[key] = model
        self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
        return model

    def evict_expired(self) -> None:
        """Usuń wszystkie modele — przy następnym get() zostaną odświeżone przez brak TTL."""
        self._models.clear()

    def release(self, key: str) -> None:
        """Usuń konkretny model i jego wpis TTL z cache'u."""
        self._models.pop(key, None)
        self._nexus._ram_cache.pop(f"_model_cache_ttl:{key}", None)
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import SessionLocal, create_oltp_engine, create_session_factory
from nexus_ai.db.models import ActiveLearningPattern, Invoice, OutboxEvent, OutboxStatus
from nexus_ai.pipeline.ocr import DocumentProcessor, ReviewStatus
from nexus_ai.services.dunning_engine import DunningEngine
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
from nexus_ai.services.vision.agent import VisionAgent
from nexus_ai.services.fixed_assets import FixedAssetsService


# ── SQLCipher engine helper ────────────────────────────────────────────────
def _make_engine(config: AppConfig | None = None) -> Any:
    """Utwórz SQLAlchemy engine z jawnym kluczem SQLCipher."""
    if config is None:
        config = AppConfig()
    sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
    return create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)


logger = get_logger()
OCR_INFERENCE_SEMAPHORE = anyio.Semaphore(int(os.getenv("NEXUS_MAX_PARALLEL_OCR", "1")))
OCR_TASK_TIMEOUT_SEC = int(os.getenv("NEXUS_OCR_TIMEOUT_SEC", "300"))

NATS_URL = os.getenv("NEXUS_NATS_URL", "nats://127.0.0.1:4222")
broker = PullBasedJetStreamBroker(servers=NATS_URL, queue="nexus-ai-workers")

_MODEL_CACHE = TimedModelCache(ttl_seconds=int(os.getenv("NEXUS_MODEL_CACHE_TTL_SEC", "600")))

async def _load_document_processor() -> DocumentProcessor:
    return await anyio.to_thread.run_sync(DocumentProcessor)

async def _load_vision_agent() -> VisionAgent:
    return await anyio.to_thread.run_sync(VisionAgent)

class InvoiceEventPayload(Struct):
    """Canonical payload embedded in Outbox events."""
    invoice_id: str
    image_path: str
    contractor_id: str

class InvoiceProcessingMachine:
    """Invoice lifecycle state machine (no statemachine dependency)."""
    STATES = {
        "new": "NEW",
        "processing": "PROCESSING",
        "approved": "APPROVED",
        "manual_review": "MANUAL_REVIEW",
        "failed": "FAILED",
    }

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
    """Lightweight proxy to mimic statemachine.State.id interface."""
    def __init__(self, state_id: str):
        self.id = state_id

    def __repr__(self):
        return f"State(id='{self.id}')"

def pin_worker_cpu_affinity(reserve_core0: bool = True) -> None:
    """Pin worker process to non-UI CPU cores to protect Flet responsiveness."""
    process = psutil.Process()
    available = list(range(psutil.cpu_count(logical=False) or psutil.cpu_count() or 1))
    if reserve_core0 and len(available) > 1:
        target = [core for core in available if core != 0] or available
    else:
        target = available
    process.cpu_affinity(target)

def _get_vector_store() -> Any:
    """Get or create vector store (sqlite-vec).

    Zastępuje: LanceDB + Polars → sqlite-vec VectorStore.
    """
    from db.vector_store import VectorStore
    store = VectorStore("app_data/vectors.db")
    # Ensure invoice_vectors-like table exists
    conn = store._get_conn()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS invoice_vectors (
            id              TEXT PRIMARY KEY,
            invoice_id      TEXT NOT NULL,
            contractor_id   TEXT NOT NULL,
            vector          BLOB NOT NULL,
            checksum        TEXT DEFAULT '',
            created_at      TEXT NOT NULL DEFAULT (datetime('now')),
            is_preferred    INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    return store

def _simple_features(raw_text: str) -> list[float]:
    """Small dense vector placeholder; replace with embedding model output."""
    length = float(len(raw_text))
    digits = float(sum(ch.isdigit() for ch in raw_text))
    letters = float(sum(ch.isalpha() for ch in raw_text))
    lines = float(max(raw_text.count("\n"), 1))
    return [length, digits, letters, lines]

def _pick_pending_outbox(session: Session) -> OutboxEvent | None:
    query = (
        select(OutboxEvent)
        .where(OutboxEvent.status == OutboxStatus.PENDING)
        .order_by(OutboxEvent.created_at.asc())
        .limit(1)
    )
    result = session.execute(query)
    return result.scalar_one_or_none()

def _update_invoice_status(session: Session, invoice_id: str, status: str) -> None:
    invoice = session.get(Invoice, invoice_id)
    if invoice is None:
        return
    invoice.processing_status = status
    invoice.updated_at = pendulum.now("UTC")
    session.flush()

@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def _startup(_state: Any) -> None:
    pin_worker_cpu_affinity(reserve_core0=True)

@broker.task(task_name="process_invoice_task")
async def process_invoice_task() -> dict[str, str]:
    """Consume pending outbox event and process invoice OCR + workflow update."""
    config = AppConfig(base_dir=Path.cwd())
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)

    with session_factory() as session:
        event = _pick_pending_outbox(session)
        if event is None:
            return {"result": "NO_EVENTS"}

        machine = InvoiceProcessingMachine()
        machine.start()
        event.status = OutboxStatus.PROCESSED
        payload = msgspec.json.decode(event.payload.encode("utf-8"), type=InvoiceEventPayload)
        _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        try:
            async with OCR_INFERENCE_SEMAPHORE:
                processor = await _MODEL_CACHE.get("document_processor", _load_document_processor)
                vision_agent = await _MODEL_CACHE.get("vision_agent", _load_vision_agent)
                with anyio.fail_after(OCR_TASK_TIMEOUT_SEC):
                    processed = await anyio.to_thread.run_sync(processor.process, Path(payload.image_path))
                with anyio.fail_after(OCR_TASK_TIMEOUT_SEC):
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
            enriched_text = f"{processed.primary.raw_text}\n[vision]{msgspec_dumps(vision_payload, ensure_ascii=False)}"
            vector = _simple_features(enriched_text)
            store = _get_vector_store()
            conn = store._get_conn()
            conn.execute(
                """INSERT INTO invoice_vectors
                   (id, invoice_id, contractor_id, vector, checksum, created_at, is_preferred)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (
                    str(uuid.uuid4()),
                    payload.invoice_id,
                    payload.contractor_id,
                    store._vector_to_blob(vector),
                    processed.primary.checksum,
                    pendulum.now("UTC").isoformat(),
                    0,
                ),
            )
            conn.commit()
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
            _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        except TimeoutError as exc:
            machine.fail()
            event.status = OutboxStatus.FAILED
            event.payload = msgspec_dumps({"error": f"OCR_TIMEOUT:{exc}", "original_payload": event.payload})
            _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        except Exception as exc:
            machine.fail()
            event.status = OutboxStatus.FAILED
            event.payload = msgspec_dumps({"error": str(exc), "original_payload": event.payload})
            _update_invoice_status(session, payload.invoice_id, machine.current_state.id)

        session.commit()
        engine.dispose()
        return {"result": "OK"}

@broker.task(task_name="store_active_learning_feedback")
async def store_active_learning_feedback(contractor_id: str, corrected_payload: dict[str, Any]) -> dict[str, str]:
    """Persist user corrections for active learning and preferred retrieval."""
    config = AppConfig(base_dir=Path.cwd())
    engine = _make_engine(config)
    session_factory = create_session_factory(engine)
    serialized = msgspec_dumps(corrected_payload, ensure_ascii=False)
    vector = _simple_features(serialized)
    pattern_id = str(uuid.uuid4())

    with session_factory() as session:
        session.add(
            ActiveLearningPattern(
                id=pattern_id,
                contractor_id=contractor_id,
                correction_payload=serialized,
            )
        )
        session.commit()

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

    engine.dispose()
    return {"result": "LEARNING_SAVED"}

@broker.task(schedule=[{"cron": "0 16 * * *"}])
async def scheduled_backup_task():
    """Codziennie o 16:00"""
    config = AppConfig()
    manager = BackupManager(config)
    path = manager.create_encrypted_zip(config.encryption_key)
    logger.info(f"Backup wykonany pomyślnie: {path}")

@broker.task(schedule=[{"cron": "55 23 28-31 * *"}], task_name="cron_post_depreciation")
async def cron_post_depreciation() -> dict[str, int | str]:
    """Monthly fixed-assets depreciation posting. Runs on month-end window 23:55 UTC."""
    today = pendulum.now("UTC").date()
    if (today + pendulum.duration(days=1)).month == today.month:
        return {"result": "SKIPPED_NOT_MONTH_END", "posted": 0}
    duckdb = DuckDBManager(Path("app_data/nexus_olap.duckdb"))
    tigerbeetle = TigerBeetleClient()
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=tigerbeetle)
    posted = await service.execute_monthly_depreciation(as_of=today)
    return {"result": "OK", "posted": posted}

@broker.task(schedule=[{"cron": "*/5 * * * *"}])
async def invoice_reconciliation_loop():
    """Wyszukuje porzucone faktury i podejmuje akcje naprawcze."""
    logger.info("[Watchdog] Uruchamianie skanowania spójności...")
    timeout_threshold = pendulum.now("UTC") - pendulum.duration(minutes=10)

    with SessionLocal() as session:
        stmt = select(Invoice).where(
            Invoice.status == "PROCESSING",
            Invoice.updated_at <= timeout_threshold
        )
        result = session.execute(stmt)
        stuck_invoices = result.scalars().all()

        if not stuck_invoices:
            logger.debug("[Watchdog] System w pełni spójny. Brak porzuconych zadań.")
            return

        import nats
        nc = await nats.connect("nats://localhost:4222")
        for invoice in stuck_invoices:
            if invoice.retry_count < 3:
                logger.warning(
                    f"[Watchdog] Faktura ID: {invoice.id} utknęła. "
                    f"Próba {invoice.retry_count + 1}/3. Re-kolejkowanie..."
                )
                invoice.retry_count += 1
                invoice.updated_at = pendulum.now("UTC")
                payload = msgspec_dumps({
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
                invoice.updated_at = pendulum.now("UTC")
                error_payload = msgspec_dumps({
                    "status": "FAILED",
                    "message": "Przekroczono limit czasu (Krytyczny błąd przetwarzania)."
                })
                await nc.publish(f"invoices.status.{invoice.id}", error_payload.encode())

        session.commit()
        await nc.close()

class _DefaultDunningAIAgent:
    def generate_dunning_text(self, invoice_data: dict[str, Any], vendor_score: float, level: int) -> str:
        tone = "uprzejmy" if vendor_score >= 0.8 else "stanowczy"
        return (
            f"To automatyczne przypomnienie ({tone}, poziom {level}) dla faktury {invoice_data['invoice_number']} "
            f"na kwotę {invoice_data['balance_due']:.2f} PLN. "
            f"Zaległość: {invoice_data['days_overdue']} dni."
        )

class _DefaultEmailProvider:
    def send(self, *, to_email: str, subject: str, body: str) -> bool:
        if not to_email:
            return False
        logger.info("[Dunning] Wysyłka email to=%s subject=%s", to_email, subject)
        return True

@broker.task(task_name="run_daily_dunning_check", schedule=[{"cron": "0 9 * * *"}])
async def run_daily_dunning_check() -> dict[str, int]:
    """Codzienna kontrola należności i wysyłka przypomnień (09:00)."""
    config = AppConfig(base_dir=Path.cwd())
    duckdb = DuckDBManager(config.duckdb_path)
    engine = DunningEngine(
        duckdb_manager=duckdb,
        ai_agent=_DefaultDunningAIAgent(),
        email_provider=_DefaultEmailProvider(),
    )
    return await engine.run_daily_dunning_check()

@broker.task(task_name="execute_monthly_depreciation", schedule=[{"cron": "0 0 1 * *"}])
async def execute_monthly_depreciation_task() -> dict[str, int]:
    """Posts due depreciation entries to TigerBeetle on the 1st day of each month."""
    duckdb = DuckDBManager(Path("app_data/nexus_olap.duckdb"))
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=TigerBeetleClient())
    posted = await service.execute_monthly_depreciation()
    logger.info("[FixedAssets] Posted %s depreciation entries", posted)
    return {"posted": posted}

@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def _shutdown(_state: Any) -> None:
    _MODEL_CACHE.evict_expired()
    _MODEL_CACHE.release("document_processor")
    _MODEL_CACHE.release("vision_agent")
