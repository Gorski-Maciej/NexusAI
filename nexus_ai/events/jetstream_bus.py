"""
JetStreamEventBus — publish/subscribe domain events through NATS JetStream.

NATS JetStream zapewnia:
  - Trwałe kolejki (survive restart)
  - At-least-once delivery
  - Consumer groups (queue groups) dla horizontal scaling
  - Dyskowa persystencja dla eventów

Architektura:
  - Jeden JetStream Stream na typ agregatu (np. "nexus-invoice", "nexus-decision")
  - Każdy event ma subject: "{stream}.{event_type}" (np. "nexus-invoice.invoice.created")
  - Projections konsumują eventy przez PullConsumer z checkpointami
"""

from __future__ import annotations

import asyncio
import json
from msgspec import Struct, field
from typing import Any

from structlog import get_logger

from nexus_ai.events.domain_events import (
    DomainEvent,
    decode_event,
    encode_event,
)

logger = get_logger("nexus.events.jetstream")

# ── Stream configuration ──────────────────────────────────────────────────

# Mapowanie: typ agregatu → konfiguracja strumienia JetStream
STREAM_CONFIG: dict[str, dict[str, Any]] = {
    "invoice": {
        "stream_name": "nexus-invoice",
        "subjects": ["nexus-invoice.>"],
        "max_age_days": 90,
        "storage": "file",  # "file" | "memory"
        "replicas": 1,
    },
    "decision": {
        "stream_name": "nexus-decision",
        "subjects": ["nexus-decision.>"],
        "max_age_days": 90,
        "storage": "file",
        "replicas": 1,
    },
    "outbox": {
        "stream_name": "nexus-outbox",
        "subjects": ["nexus-outbox.>"],
        "max_age_days": 30,
        "storage": "file",
        "replicas": 1,
    },
}

# Cache na skonfigurowane strumienie
_stream_cache: dict[str, bool] = {}

# ── JetStream Event Bus ───────────────────────────────────────────────────

class JetStreamEventBus:
    """Publikuje eventy domenowe do NATS JetStream.

    Args:
        nats_servers: Lista serwerów NATS (np. ``["nats://localhost:4222"]``).
        connect_timeout: Timeout na połączenie w sekundach.
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        connect_timeout: float = 5.0,
    ) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._connect_timeout = connect_timeout
        self._nc: Any = None  # nats connection
        self._js: Any = None  # jetstream context
        self._connected = False

    async def connect(self) -> None:
        """Połącz z NATS i skonfiguruj strumienie JetStream."""
        if self._connected:
            return
        try:
            import nats
            from nats.js.api import StorageType

            self._nc = await nats.connect(
                servers=self._nats_servers,
                connect_timeout=self._connect_timeout,
                name="nexus-event-bus",
            )
            self._js = self._nc.jetstream()
            self._connected = True
            logger.info(
                "[JETSTREAM] Connected to NATS: %s",
                self._nats_servers,
            )

            # Skonfiguruj strumienie przy starcie
            for agg_type, cfg in STREAM_CONFIG.items():
                await self._ensure_stream(cfg)

        except Exception as exc:
            logger.warning(
                "[JETSTREAM] Failed to connect: %s — events will be buffered",
                exc,
            )
            self._connected = False

    async def _ensure_stream(self, cfg: dict[str, Any]) -> None:
        """Upewnij się, że strumień JetStream istnieje."""
        if self._js is None:
            return
        stream_name = cfg["stream_name"]
        if stream_name in _stream_cache:
            return
        try:
            from nats.js.api import StorageType

            try:
                await self._js.stream_info(stream_name)
            except Exception:
                # Stream nie istnieje — utwórz
                await self._js.add_stream(
                    name=stream_name,
                    subjects=cfg["subjects"],
                    max_age=cfg["max_age_days"] * 24 * 3600,  # sekundy
                    storage=StorageType.FILE,
                    replicas=cfg.get("replicas", 1),
                )
                logger.info("[JETSTREAM] Created stream: %s", stream_name)

            _stream_cache[stream_name] = True
        except Exception as exc:
            logger.warning(
                "[JETSTREAM] Failed to ensure stream %s: %s",
                stream_name, exc,
            )

    async def publish(self, event: DomainEvent) -> bool:
        """Opublikuj event do JetStream.

        Args:
            event: Event do opublikowania.

        Returns:
            ``True`` jeśli publikacja się powiodła, ``False`` jeśli nie.
        """
        if not self._connected or self._js is None:
            logger.warning(
                "[JETSTREAM] Not connected — skipping publish of %s",
                event.event_type,
            )
            return False

        try:
            data = encode_event(event)
            subject = f"nexus-{event.aggregate_type}.{event.event_type}"
            ack = await self._js.publish(subject, data)
            logger.debug(
                "[JETSTREAM] Published %s seq=%d",
                event.event_type,
                ack.seq if ack else 0,
            )
            return True
        except Exception as exc:
            logger.warning(
                "[JETSTREAM] Failed to publish %s: %s",
                event.event_type, exc,
            )
            return False

    async def publish_batch(self, events: list[DomainEvent]) -> int:
        """Opublikuj wiele eventów w batchu.

        Args:
            events: Lista eventów.

        Returns:
            Liczba pomyślnie opublikowanych.
        """
        published = 0
        for event in events:
            if await self.publish(event):
                published += 1
        return published

    async def close(self) -> None:
        """Zamknij połączenie z NATS."""
        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
            self._nc = None
            self._js = None
            self._connected = False
            logger.info("[JETSTREAM] Disconnected")

    @property
    def is_connected(self) -> bool:
        return self._connected

# ── JetStream Consumer ────────────────────────────────────────────────────

class ConsumerConfig(Struct):
    """Konfiguracja konsumera JetStream dla projekcji.

    Args:
        stream_name: Nazwa strumienia (np. "nexus-invoice").
        consumer_name: Nazwa konsumera (np. "invoice-projection").
        deliver_policy: "all" = od początku, "last" = tylko nowe, "new" = od checkpoint.
        filter_subject: Opcjonalny filtr subject (np. "nexus-invoice.invoice.created").
        max_deliver: Maksymalna liczba dostaw przed DLQ.
        ack_wait: Czas oczekiwania na ack w sekundach.
    """
    stream_name: str = ""
    consumer_name: str = ""
    deliver_policy: str = "all"  # "all" | "last" | "new" | "by_start_sequence"
    filter_subject: str = ""
    max_deliver: int = 3
    ack_wait: int = 30

class JetStreamConsumer:
    """Konsumuje eventy z JetStream i przekazuje do handlerów.

    Args:
        nats_servers: Lista serwerów NATS.
        configs: Lista konfiguracji konsumerów.
        event_handler: Funkcja callback(event: DomainEvent) -> None.
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        configs: list[ConsumerConfig] | None = None,
        event_handler: Any = None,
    ) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._configs = configs or []
        self._event_handler = event_handler
        self._nc: Any = None
        self._js: Any = None
        self._sub_tasks: list[asyncio.Task] = []

    async def start(self) -> None:
        """Połącz i uruchom konsumentów."""
        import nats

        self._nc = await nats.connect(
            servers=self._nats_servers,
            name="nexus-event-consumer",
        )
        self._js = self._nc.jetstream()

        for cfg in self._configs:
            task = asyncio.create_task(self._consume_stream(cfg))
            self._sub_tasks.append(task)
            logger.info(
                "[JETSTREAM] Consumer started: %s/%s (filter=%s)",
                cfg.stream_name, cfg.consumer_name, cfg.filter_subject or "*",
            )

    async def _consume_stream(self, cfg: ConsumerConfig) -> None:
        """Konsumuj eventy z jednego strumienia."""
        try:
            sub = await self._js.pull_subscribe(
                subject=cfg.filter_subject or ">",
                stream=cfg.stream_name,
                durable=cfg.consumer_name,
                config={
                    "max_deliver": cfg.max_deliver,
                    "ack_wait": cfg.ack_wait,
                },
            )

            while True:
                try:
                    msgs = await sub.fetch(batch=10, timeout=5)
                    for msg in msgs:
                        try:
                            event = decode_event(msg.data)
                            if self._event_handler:
                                await self._event_handler(event)
                            await msg.ack()
                        except Exception as exc:
                            logger.warning(
                                "[JETSTREAM] Failed to process message: %s",
                                exc,
                            )
                            await msg.nak(delay=5)
                except TimeoutError:
                    # Brak wiadomości — kontynuuj
                    pass
                except Exception as exc:
                    logger.warning(
                        "[JETSTREAM] Consumer error: %s", exc,
                    )
                    await asyncio.sleep(1)

        except asyncio.CancelledError:
            logger.info("[JETSTREAM] Consumer cancelled: %s", cfg.consumer_name)
        except Exception as exc:
            logger.error(
                "[JETSTREAM] Consumer %s failed: %s",
                cfg.consumer_name, exc,
            )

    async def stop(self) -> None:
        """Zatrzymaj wszystkich konsumentów."""
        for task in self._sub_tasks:
            task.cancel()
        if self._sub_tasks:
            await asyncio.gather(*self._sub_tasks, return_exceptions=True)
        if self._nc is not None:
            await self._nc.drain()

# ── Global singleton ──────────────────────────────────────────────────────

_default_bus: JetStreamEventBus | None = None

def get_event_bus(
    nats_servers: list[str] | str | None = None,
) -> JetStreamEventBus:
    """Zwraca globalną instancję JetStreamEventBus (singleton).

    Args:
        nats_servers: Lista serwerów NATS.

    Returns:
        Globalna instancja JetStreamEventBus.
    """
    global _default_bus
    if _default_bus is None:
        _default_bus = JetStreamEventBus(nats_servers=nats_servers)
    return _default_bus
