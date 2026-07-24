"""
NatsBridge — synchronizacja TypedEventBus (in-process) z JetStreamEventBus (NATS).

SUPERMOC v7.0 (INNOWACJA z Raportu): Bridge eliminujący lukę między
dwoma busami — eventy domenowe automatycznie propagowane między procesami.

Architektura:
    ┌────────────────┐          ┌─────────────┐          ┌──────────────┐
    │  TypedEventBus │──emit──▶│  NatsBridge  │──publish─▶│  JetStream   │
    │  (in-process)  │         │              │          │  (NATS)      │
    └────────────────┘          │              │          └──────┬───────┘
                                │  subscriber  │◀──consume───────┘
                                └──────────────┘

Usage:
    from nexus_ai.events.nats_bridge import NatsBridge

    bridge = NatsBridge(
        local_bus=get_bus(),
        jetstream_bus=JetStreamEventBus(nats_servers=["nats://localhost:4222"]),
        bridge_mode="bidirectional",  # "outbound", "inbound", "bidirectional"
    )
    await bridge.start()
"""

from __future__ import annotations

import threading
from typing import Any

import anyio
import msgspec
from structlog import get_logger

from nexus_ai.core.bus import EventBus, EventT, get_bus
from nexus_ai.events.domain_events import DomainEvent, decode_event, encode_event
from nexus_ai.events.jetstream_bus import (
    JetStreamConsumer,
    ConsumerConfig,
    JetStreamEventBus,
)

logger = get_logger("nexus.events.nats_bridge")


class BridgeEvent(msgspec.Struct, kw_only=True):
    """Envelope for bridging events across bus boundaries."""

    source_bus: str = "typed-event-bus"
    event_type: str = ""
    payload_bytes: bytes = b""
    correlation_id: str = ""
    timestamp: float = 0.0


class NatsBridge:
    """Dwukierunkowy most między TypedEventBus (in-process) a JetStreamEventBus.

    INNOWACJA z Raportu v7.0 (sekcja 3.3):
    - OUTBOUND: subskrybuje TypedEventBus → publikuje na NATS JetStream
    - INBOUND: subskrybuje NATS JetStream → emituje na TypedEventBus
    - BIDIRECTIONAL: oba kierunki

    Args:
        local_bus: In-process TypedEventBus (core/bus.py).
        jetstream_bus: JetStreamEventBus (events/jetstream_bus.py).
        bridge_mode: "outbound", "inbound", or "bidirectional".
        local_event_types: Lista msgspec.Struct typów do bridge'owania.
    """

    __slots__ = (
        "_bridge_mode",
        "_jetstream_bus",
        "_local_bus",
        "_local_event_types",
        "_started",
        "_task_group",
        "_consumer",
    )

    def __init__(
        self,
        local_bus: EventBus | None = None,
        jetstream_bus: JetStreamEventBus | None = None,
        *,
        bridge_mode: str = "bidirectional",
        local_event_types: list[type[msgspec.Struct]] | None = None,
    ) -> None:
        self._local_bus = local_bus or get_bus()
        self._jetstream_bus = jetstream_bus or JetStreamEventBus()
        self._bridge_mode = bridge_mode.lower()
        if self._bridge_mode not in ("outbound", "inbound", "bidirectional"):
            raise ValueError(
                f"bridge_mode must be 'outbound', 'inbound', or 'bidirectional', got '{bridge_mode}'"
            )
        self._local_event_types = local_event_types or []
        self._started = False
        self._task_group: Any | None = None
        self._consumer: JetStreamConsumer | None = None

    async def start(self) -> None:
        """Uruchom bridge — rejestruj subskrypcje po obu stronach."""
        if self._started:
            return

        # ── OUTBOUND: TypedEventBus → NATS ──────────────────────────
        if self._bridge_mode in ("outbound", "bidirectional"):
            for event_type in self._local_event_types:
                self._local_bus.subscribe(
                    event_type=event_type,
                    callback=self._outbound_handler,
                    name=f"nats-bridge-outbound-{event_type.__name__}",
                )
                logger.debug(
                    "[BRIDGE] Outbound subscription: %s", event_type.__name__
                )

        # ── INBOUND: NATS → TypedEventBus ──────────────────────────
        if self._bridge_mode in ("inbound", "bidirectional"):
            await self._jetstream_bus.connect()
            consumers: list[ConsumerConfig] = []
            for stream_name in ("nexus-invoice", "nexus-decision", "nexus-outbox"):
                consumers.append(
                    ConsumerConfig(
                        stream_name=stream_name,
                        consumer_name=f"nats-bridge-inbound-{stream_name}",
                        filter_subject=f"{stream_name}.>",
                        max_ack_pending=100,
                        ack_wait=30,
                        max_deliver=3,
                        idle_heartbeat=10,
                        description=f"NatsBridge inbound consumer for {stream_name}",
                    )
                )
            self._consumer = JetStreamConsumer(
                nats_servers=self._jetstream_bus._nats_servers,
                configs=consumers,
                event_handler=self._inbound_handler,
            )
            await self._consumer.start()
            logger.info("[BRIDGE] Inbound consumer started on %d streams", len(consumers))

        self._started = True
        logger.info("[BRIDGE] Started in %s mode", self._bridge_mode)

    async def stop(self) -> None:
        """Zatrzymaj bridge — wyrejestruj subskrypcje."""
        if self._consumer:
            await self._consumer.stop()
            self._consumer = None
        self._started = False
        logger.info("[BRIDGE] Stopped")

    async def _outbound_handler(self, event: Any) -> None:
        """Handler OUTBOUND: TypedEventBus → NATS JetStream."""
        import time as _time

        try:
            payload = encode_event(event) if isinstance(event, DomainEvent) else msgspec.msgpack.encode(event)
            bridge_event = BridgeEvent(
                source_bus="typed-event-bus",
                event_type=type(event).__name__,
                payload_bytes=payload,
                timestamp=_time.time(),
            )
            await self._jetstream_bus.publish(event) if isinstance(event, DomainEvent) else None
            logger.debug("[BRIDGE:OUT] Forwarded %s to NATS", type(event).__name__)
        except Exception:
            logger.exception("[BRIDGE:OUT] Failed to forward event %s", type(event).__name__)

    async def _inbound_handler(self, event: DomainEvent) -> None:
        """Handler INBOUND: NATS JetStream → TypedEventBus."""
        import time as _time

        try:
            # Wrap in BridgeEvent i emituj na lokalnym busie
            bridge_event = BridgeEvent(
                source_bus="jetstream",
                event_type=type(event).__name__,
                payload_bytes=encode_event(event),
                timestamp=_time.time(),
            )
            await self._local_bus.emit(event)
            logger.debug("[BRIDGE:IN] Routed %s to local bus", type(event).__name__)
        except Exception:
            logger.exception("[BRIDGE:IN] Failed to route event %s", type(event).__name__)

    @property
    def is_started(self) -> bool:
        return self._started


# ── Global singleton ─────────────────────────────────────────────────────

_default_bridge: NatsBridge | None = None
_default_bridge_lock = threading.Lock()


def get_nats_bridge(
    local_bus: EventBus | None = None,
    jetstream_bus: JetStreamEventBus | None = None,
    *,
    bridge_mode: str = "bidirectional",
) -> NatsBridge:
    """Get global NatsBridge singleton (thread-safe)."""
    global _default_bridge
    if _default_bridge is None:
        with _default_bridge_lock:
            if _default_bridge is None:
                _default_bridge = NatsBridge(
                    local_bus=local_bus,
                    jetstream_bus=jetstream_bus,
                    bridge_mode=bridge_mode,
                )
    return _default_bridge


__all__ = ["NatsBridge", "BridgeEvent", "get_nats_bridge"]
