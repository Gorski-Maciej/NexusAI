"""Asynchronous workflow tasks powered by Taskiq + NATS JetStream.

  - TaskiqDepends dla DI: config, db_session, duckdb_manager
  - Labels na wszystkich zadaniach (service, operation, criticality)
  - Timeout na dekoratorze zamiast anyio.fail_after
  - Context.requeue() dla watchdog (zamiast ręcznego publish do JetStream)
  - with_task_id() dla deterministycznych ID zadań
"""

from __future__ import annotations

import os
import threading
import uuid
from pathlib import Path
from typing import Any

import anyio
import msgspec
import pendulum
import psutil
from msgspec import Struct
from sqlmodel import Session, select
from taskiq import Kicker, TaskiqDepends, TaskiqEvents

from nexus_ai.core.backup import BackupManager
from nexus_ai.core.cache import get_cache
from nexus_ai.core.config import AppConfig
from nexus_ai.core.di import get_config, get_db_session, get_duckdb_manager
from nexus_ai.core.logger import get_logger


class TimedModelCache:
    """Cache instancji modeli ML z TTL, thread-safe dla free-threaded Python."""

    def __init__(self, ttl_seconds: int = 600):
        self._nexus = get_cache(default_ttl=ttl_seconds)
        self._models: dict[str, object] = {}
        self._lock = threading.Lock()
        self._ttl = ttl_seconds

    async def get(self, key: str, loader):
        now = anyio.current_time()
        ttl_key = f"_model_cache_ttl:{key}"

        ttl_entry = self._nexus.get_sync(ttl_key)
        if ttl_entry is not None:
            with self._lock:
                if key in self._models:
                    stored_at: float = ttl_entry
                    if now - stored_at < self._ttl:
                        self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
                        return self._models[key]
                    self._models.pop(key, None)

        model = await loader()
        with self._lock:
            self._models[key] = model
        self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
        return model

    def evict_expired(self) -> None:
        with self._lock:
            self._models.clear()

    def release(self, key: str) -> None:
        with self._lock:
            self._models.pop(key, None)
        # - clear_l1_sync czyści klucz z L1 (RAM) bez naruszania enkapsulacji
        # - Działa z każdym CacheBackend (InMemoryBackend, SqliteBackend, RedisBackend)
        self._nexus.clear_l1_sync(f"_model_cache_ttl:{key}")


from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice, InvoiceStatus, OutboxEvent, OutboxStatus
from nexus_ai.pipeline.ocr import DocumentProcessor, ReviewStatus
from nexus_ai.services.dunning_engine import DunningEngine
from nexus_ai.services.fixed_assets import FixedAssetsService
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

logger = get_logger()
# Python 3.13t (free-threaded): zamiast 1 OCR na raz, wykorzystaj wszystkie wolne rdzenie.
# Domyślnie os.cpu_count_free() jeśli dostępne, fallback do os.cpu_count(), fallback 4.
_DEFAULT_OCR_CONCURRENCY = os.cpu_count() or 4
OCR_INFERENCE_LIMITER = anyio.CapacityLimiter(
    int(os.getenv("NEXUS_MAX_PARALLEL_OCR", str(_DEFAULT_OCR_CONCURRENCY)))
)
OCR_TASK_TIMEOUT_SEC = int(os.getenv("NEXUS_OCR_TIMEOUT_SEC", "300"))

# zamiast tworzyć osobnego PullBasedJetStreamBroker tutaj.
from nexus_ai.core.broker import broker as _broker

broker = _broker

_MODEL_CACHE = TimedModelCache(ttl_seconds=int(os.getenv("NEXUS_MODEL_CACHE_TTL_SEC", "600")))


async def _load_document_processor() -> DocumentProcessor:
    return await anyio.to_thread.run_sync(DocumentProcessor)


class InvoiceEventPayload(Struct):
    """Canonical payload embedded in Outbox events."""

    invoice_id: str
    image_path: str
    contractor_id: str


class InvoiceProcessingMachine:
    """Invoice lifecycle state machine (no statemachine dependency).

    """

    STATES = {
        "new": InvoiceStatus.NEW,
        "processing": InvoiceStatus.PROCESSING,
        "approved": InvoiceStatus.APPROVED,
        "manual_review": InvoiceStatus.MANUAL_REVIEW,
        "failed": InvoiceStatus.FAILED,
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


def pin_worker_cpu_affinity(reserve_core0: bool = True) -> list[int]:
    """Pin worker process to non-UI CPU cores to protect Flet responsiveness.

    zamiast osobnych wywołań.

    Args:
        reserve_core0: Jeśli True, przypnij do wszystkich rdzeni oprócz 0
                       (chroni UI Flet na Android/Linux).

    Returns:
        Lista rdzeni CPU, do których przypięto proces.
    """
    process = psutil.Process()

    all_cores = list(range(psutil.cpu_count(logical=False) or psutil.cpu_count() or 1))
    if reserve_core0 and len(all_cores) > 1:
        target = [core for core in all_cores if core != 0] or all_cores
    else:
        target = all_cores

    try:
        with process.oneshot():
            current = process.cpu_affinity()
            process.cpu_affinity(target)
        logger.info(
            "[CPU-AFFINITY] Pinned from %s to %s (reserve_core0=%s)",
            current,
            target,
            reserve_core0,
        )
    except (psutil.AccessDenied, psutil.NoSuchProcess) as exc:
        logger.warning("[CPU-AFFINITY] Cannot set affinity: %s", exc)
    except Exception as exc:
        logger.error("[CPU-AFFINITY] Failed: %s", exc)

    return target


def _get_vector_store() -> Any:
    """Get or create vector store (sqlite-vec).

    Zastępuje: LanceDB + Polars -> sqlite-vec VectorStore.
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


@broker.task(
    task_name="process_invoice_task",
    labels={"service": "core", "operation": "invoice", "criticality": "high"},
    timeout=300.0,
)
async def process_invoice_task(
    config: AppConfig = TaskiqDepends(get_config),
    db: Session = TaskiqDepends(get_db_session),
) -> dict[str, str]:
    """Consume pending outbox event and process invoice OCR + workflow update.

    Engine jest cache'owany przez DI -- nie ma create/dispose per task.
    """
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
    db: Session = TaskiqDepends(get_db_session),
) -> dict[str, str]:
    """Persist user corrections for active learning and preferred retrieval.

    """
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


@broker.task(
    schedule=[{"cron": "0 16 * * *"}],
    labels={"service": "core", "operation": "backup", "criticality": "high", "schedule": "daily"},
    timeout=600.0,
)
async def scheduled_backup_task(
    config: AppConfig = TaskiqDepends(get_config),
):
    """Codziennie o 16:00"""
    manager = BackupManager(config)
    path = manager.create_encrypted_zip(config.encryption_key)
    logger.info(f"Backup wykonany pomyślnie: {path}")


@broker.task(
    schedule=[{"cron": "55 23 28-31 * *"}],
    task_name="cron_post_depreciation",
    labels={
        "service": "core",
        "operation": "depreciation",
        "criticality": "high",
        "schedule": "monthly",
    },
    timeout=120.0,
)
async def cron_post_depreciation(
    duckdb: DuckDBManager = TaskiqDepends(get_duckdb_manager),
) -> dict[str, int | str]:
    """Monthly fixed-assets depreciation posting. Runs on month-end window 23:55 UTC.

    """
    today = pendulum.now("UTC").date()
    if (today + pendulum.duration(days=1)).month == today.month:
        return {"result": "SKIPPED_NOT_MONTH_END", "posted": 0}
    tigerbeetle = TigerBeetleClient()
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=tigerbeetle)
    posted = await service.execute_monthly_depreciation(as_of=today)
    return {"result": "OK", "posted": posted}


@broker.task(
    schedule=[{"cron": "*/5 * * * *"}],
    labels={"service": "core", "operation": "watchdog", "criticality": "high", "schedule": "5min"},
    timeout=60.0,
)
async def invoice_reconciliation_loop(
    db: Session = TaskiqDepends(get_db_session),
):
    """Wyszukuje porzucone faktury i podejmuje akcje naprawcze.

    - TaskiqDepends wstrzykuje sesję DB -- zero boilerplate
    - Context.requeue() zamiast ręcznego publish do JetStream
    - Deterministic task_id przez Kicker.with_task_id()
    """
    logger.info("[Watchdog] Uruchamianie skanowania spójności...")
    timeout_threshold = pendulum.now("UTC") - pendulum.duration(minutes=10)

    stmt = select(Invoice).where(
        Invoice.status == InvoiceStatus.PROCESSING, Invoice.updated_at <= timeout_threshold
    )
    result = db.execute(stmt)
    stuck_invoices = result.scalars().all()

    if not stuck_invoices:
        logger.debug("[Watchdog] System w pełni spójny. Brak porzuconych zadań.")
        return

    for invoice in stuck_invoices:
        if invoice.retry_count < 3:
            logger.warning(
                f"[Watchdog] Faktura ID: {invoice.id} utknęła. "
                f"Próba {invoice.retry_count + 1}/3. Re-kolejkowanie..."
            )
            invoice.retry_count += 1
            invoice.updated_at = pendulum.now("UTC")

            # JetStream deduplikuje na podstawie Nats-Msg-Id = task_id
            task_id = f"watchdog_recover:{invoice.id}:{invoice.retry_count}"
            await (
                Kicker("process_invoice_task", broker=broker)
                .with_task_id(task_id)
                .with_labels({"is_retry": "true", "invoice_id": invoice.id})
                .kiq()
            )
        else:
            logger.error(
                f"[Watchdog] Faktura ID: {invoice.id} trwale uszkadza Workera. "
                f"Zatrzymano próby. Status -> ERROR: TIMEOUT"
            )
            invoice.status = InvoiceStatus.ERROR_TIMEOUT
            invoice.updated_at = pendulum.now("UTC")



class _DefaultDunningAIAgent:
    def generate_dunning_text(
        self, invoice_data: dict[str, Any], vendor_score: float, level: int
    ) -> str:
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


@broker.task(
    task_name="run_daily_dunning_check",
    schedule=[{"cron": "0 9 * * *"}],
    labels={
        "service": "core",
        "operation": "dunning",
        "criticality": "medium",
        "schedule": "daily",
    },
    timeout=300.0,
)
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


@broker.task(
    task_name="execute_monthly_depreciation",
    schedule=[{"cron": "0 0 1 * *"}],
    labels={
        "service": "core",
        "operation": "depreciation",
        "criticality": "high",
        "schedule": "monthly",
    },
    timeout=120.0,
)
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
