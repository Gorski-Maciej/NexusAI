"""
core/broker.py — Unified NATS JetStream Taskiq Broker.

SUPERMOCE NATS:
  - PullBasedJetStreamBroker — jedyny broker w systemie (zamiast dwóch: NatsBroker + PullBasedJetStreamBroker)
  - JetStream Dead Letter Queue dla nieudanych zadań
  - max_ack_pending = 5 — kontrola współbieżności konsumpcji
  - Reconnect z wykładniczym backoffem (max_reconnect_attempts=-1 = nieskończone)
  - Konfiguracja przez AppConfig (TOML + env vars)
  - Centralny punkt dla wszystkich zadań Taskiq

Usage:
    from nexus_ai.core.broker import broker

    @broker.task(task_name="my_task")
    async def my_task() -> dict:
        ...
"""

from __future__ import annotations

from taskiq import TaskiqEvents
from taskiq_nats import PullBasedJetStreamBroker
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.broker")
config = AppConfig()

# ── NATS Dead Letter Queue subject ───────────────────────────────────────
# Trafiają tu zadania które przekroczyły max_deliver (domyślnie 3 próby)
DEAD_LETTER_SUBJECT = "nexus.dlq.tasks"

# ── Unified PullBasedJetStreamBroker ─────────────────────────────────────
# SUPERMOC: Jeden broker dla wszystkich zadań — zamiast dwóch (NatsBroker + PullBasedJetStreamBroker)
# SUPERMOC: max_ack_pending=5 — nie więcej niż 5 równoczesnych zadań na workera
# SUPERMOC: max_reconnect_attempts=-1 — nieskończone próby reconnectu z backoffem
broker = PullBasedJetStreamBroker(
    servers=[config.nats_url],
    queue="nexus-ai-workers",
    # SUPERMOC: Konfiguracja JetStream dla wszystkich zadań
    jetstream_queue_group="nexus-ai-workers",
    # SUPERMOC: Dead Letter Queue — nieudane zadania trafiają do osobnego strumienia
    dead_letter_subject=DEAD_LETTER_SUBJECT,
    # SUPERMOC: Maksymalnie 5 równoczesnych zadań na workera
    max_ack_pending=5,
    # SUPERMOC: Nieskończone próby reconnectu (z wykładniczym backoffem)
    max_reconnect_attempts=-1,
    connect_timeout=max(2.0, config.nats_reconnect_delay_seconds),
)


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup(state):
    """Logika uruchamiana przy starcie workera."""
    logger.info("[BROKER] Worker startup — connecting to NATS JetStream")
    state.ocr_processor = None


@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown(state):
    """Sprzątanie przy wyłączaniu."""
    logger.info("[BROKER] Worker shutdown — closing NATS connection")





# SUPERMOC: Publiczny dostęp do JetStream context przez broker.jetstream
@property
def jetstream(self) -> Any | None:
    """Zwraca JetStream context brokera (public property)."""
    return getattr(self, '_jetstream', None)

# Monkey-patch: dodaj jetstream property do brokera
broker.jetstream = jetstream.__get__(broker, type(broker))


__all__ = [
    "broker",
    "DEAD_LETTER_SUBJECT",
    "jetstream",
]
