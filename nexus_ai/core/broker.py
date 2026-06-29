"""
core/broker.py — Unified NATS JetStream Taskiq Broker (v2.0).

  - PullBasedJetStreamBroker — jedyny broker w systemie
  - JetStream Dead Letter Queue dla nieudanych zadań
  - max_ack_pending = 5 — kontrola współbieżności konsumpcji
  - Reconnect z wykładniczym backoffem (max_reconnect_attempts=-1)
  - Konfiguracja przez AppConfig (TOML + env vars)
  - Centralny punkt dla wszystkich zadań Taskiq
  - Middleware: metryki, PII scan, tracing
  - Result Backend: SQLite dla audytu wyników zadań
  - Labels na wszystkich zadaniach
  - TaskiqDepends dla DI
  - Dynamiczna konfiguracja przez config.nats_url / config.max_task_retries

Usage:
    from nexus_ai.core.broker import broker

    @broker.task(task_name="my_task", labels={"service": "core"})
    async def my_task() -> dict:
        ...
"""

from __future__ import annotations

import hashlib
import os
from typing import Any

from structlog import get_logger
from taskiq import TaskiqEvents
from taskiq_nats import PullBasedJetStreamBroker

from nexus_ai.core.config import AppConfig
from nexus_ai.core.taskiq import (
    DynamicConcurrencyMiddleware,
    HybridResultBackend,
    PiiScanMiddleware,
    SqliteResultBackend,
    TaskMetricsMiddleware,
    TaskTracingMiddleware,
)

logger = get_logger("nexus.broker")
config = AppConfig()

# ── NATS Dead Letter Queue subject ───────────────────────────────────────
DEAD_LETTER_SUBJECT = "nexus.dlq.tasks"

# ── Result Backend (SQLite albo Hybrid) ──────────────────────────────────
# Włącz przez ustawienie NEXUS_NATS_URL lub NEXUS_USE_NATS_RESULT_BACKEND=true
# Domyślnie: SqliteResultBackend (kompatybilność wsteczna)
_sqlite_path = str(config.base_dir / "app_data" / "task_results.db")
_nats_url = os.getenv("NEXUS_NATS_URL", "") or os.getenv("NATS_URL", "")
_use_nats = os.getenv("NEXUS_USE_NATS_RESULT_BACKEND", "false").lower() in ("true", "1", "yes")

if _use_nats and _nats_url:
    _result_backend = HybridResultBackend(
        sqlite_path=_sqlite_path,
        nats_servers=[_nats_url],
    )
    logger.info(
        "[BROKER] HybridResultBackend active — wbudowany w NATS Object Store + SQLite fallback"
    )
else:
    _result_backend = SqliteResultBackend(db_path=_sqlite_path)
    if os.getenv("NEXUS_USE_NATS_RESULT_BACKEND", "") and not _nats_url:
        logger.warning(
            "[BROKER] NEXUS_USE_NATS_RESULT_BACKEND=true but no NEXUS_NATS_URL set — "
            "falling back to SQLite"
        )


# ── Unified PullBasedJetStreamBroker z supermocami ───────────────────────
# Każde zadanie ma task_id oparty WYŁĄCZNIE na hash(kwargs), co pozwala NATS JetStream
# na automatyczne odrzucanie duplikatów przez Nats-Msg-Id (duplicate_window=2min).
# Dwa zadania z identycznymi argumentami OTRZYMUJĄ to samo task_id → JetStream odrzuca duplikat.
def _task_id_generator(task_name: str, args: tuple, kwargs: dict) -> str:
    """Generuj deterministyczne task_id dla deduplikacji JetStream.

      - WYŁĄCZNIE na podstawie hash(task_name + sorted(kwargs))
      - Bez random suffixu — ten sam input = to samo task_id
      - JetStream automatycznie odrzuca duplikaty w oknie 2min (duplicate_window)
      - Zastępuje ręczną tabelę processed_events dla idempotentności
    """
    content = f"{task_name}:{sorted(kwargs.items())}:{repr(args)}"
    return hashlib.sha256(content.encode()).hexdigest()[:32]


broker = PullBasedJetStreamBroker(
    servers=[config.nats_url],
    queue="nexus-ai-workers",
    jetstream_queue_group="nexus-ai-workers",
    dead_letter_subject=DEAD_LETTER_SUBJECT,
    max_ack_pending=int(os.getenv("NEXUS_MAX_ACK_PENDING", "5")),
    max_reconnect_attempts=-1,
    connect_timeout=max(2.0, config.nats_reconnect_delay_seconds),
    result_backend=_result_backend,
    task_id_generator=_task_id_generator,
    #   pull_consume_batch=1 — jeden task na raz (kontrola obciążenia)
    #   pull_consume_timeout=5.0 — timeout na fetch z JetStream
    pull_consume_batch=int(os.getenv("NEXUS_PULL_CONSUME_BATCH", "1")),
    pull_consume_timeout=float(os.getenv("NEXUS_PULL_CONSUME_TIMEOUT", "5.0")),
)

# ── Rejestracja middleware ───────────────────────────────────────────────
#   1. TaskMetricsMiddleware — zapisuje metryki OTel dla każdego zadania
#   2. PiiScanMiddleware — skanuje payload w poszukiwaniu PII
#   3. TaskTracingMiddleware — dodaje tracing (trace_id) do labels
#   4. DynamicConcurrencyMiddleware — dynamiczne limitowanie współbieżności
broker.add_middleware(TaskMetricsMiddleware())
broker.add_middleware(PiiScanMiddleware())
broker.add_middleware(TaskTracingMiddleware())
broker.add_middleware(
    DynamicConcurrencyMiddleware(
        max_concurrent=int(os.getenv("NEXUS_MAX_CONCURRENT", "10")),
        cpu_threshold=80.0,
        ram_threshold=80.0,
    )
)


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup(state):
    """Logika uruchamiana przy starcie workera."""
    logger.info("[BROKER] Worker startup — connecting to NATS JetStream")
    state.ocr_processor = None
    logger.info(
        "[BROKER] Middleware active: metrics, pi-scan, tracing | "
        "Result backend: SQLite | DLQ: %s | max_ack_pending: %d",
        DEAD_LETTER_SUBJECT,
        broker.max_ack_pending if hasattr(broker, "max_ack_pending") else "default",
    )


@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown(state):
    """Sprzątanie przy wyłączaniu."""
    logger.info("[BROKER] Worker shutdown — closing NATS connection")
    # Zamknij result backend
    if _result_backend:
        await _result_backend.close()


# ── Publiczny dostęp do result backend ────────────────────────────────────
@property
def result_backend(self) -> SqliteResultBackend | None:
    """Zwraca result backend brokera (public property)."""
    return _result_backend


broker.result_backend = result_backend.__get__(broker, type(broker))


@property
def jetstream_prop(self) -> Any | None:
    """Zwraca JetStream context brokera (public property)."""
    return getattr(self, "_jetstream", None)


broker.jetstream = jetstream_prop.__get__(broker, type(broker))


__all__ = [
    "broker",
    "DEAD_LETTER_SUBJECT",
    "_result_backend",
    "result_backend",
]
