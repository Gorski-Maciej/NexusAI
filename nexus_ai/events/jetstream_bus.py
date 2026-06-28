"""JetStreamEventBus — publish/subscribe domain events through NATS JetStream."""

from __future__ import annotations

import random
import threading
import time
from msgspec import Struct, field
from typing import Any

import anyio

from structlog import get_logger

from nexus_ai.core.nats_utils import NatsErrors, safe_close

from nexus_ai.events.domain_events import (
    DomainEvent,
    decode_event,
    encode_event,
)

logger = get_logger("nexus.events.jetstream")

# ── Stream configuration ──────────────────────────────────────────────

_BASE_STREAM = {"storage": "file", "replicas": 1, "retention": "limits"}

STREAM_CONFIG: dict[str, dict[str, Any]] = {
    "invoice": dict(**_BASE_STREAM, stream_name="nexus-invoice", subjects=["nexus-invoice.>"], max_age_days=90, max_msg_size=64*1024**2),
    "decision": dict(**_BASE_STREAM, stream_name="nexus-decision", subjects=["nexus-decision.>"], max_age_days=90, max_msg_size=1*1024**2),
    "outbox": dict(**_BASE_STREAM, stream_name="nexus-outbox", subjects=["nexus-outbox.>"], max_age_days=30, max_msg_size=1*1024**2),
    "files": dict(**_BASE_STREAM, stream_name="nexus-files", subjects=["nexus-files.>", "nexus-objects.>"], max_age_days=365, max_msg_size=256*1024**2),
    "config": dict(**_BASE_STREAM, stream_name="nexus-config", subjects=["nexus-config.>", "nexus-kv.>"], max_age_days=365, max_msg_size=1*1024**2),
    "invoice_mirror": dict(**_BASE_STREAM, stream_name="nexus-invoice-mirror", subjects=[], max_age_days=365, max_msg_size=64*1024**2, mirror={"name": "nexus-invoice"}),
    "audit": dict(**_BASE_STREAM, stream_name="nexus-audit", subjects=[], max_age_days=365*5, max_msg_size=64*1024**2,
                   sources=[{"name": "nexus-invoice"}, {"name": "nexus-decision"}, {"name": "nexus-outbox"}]),
}

_stream_cache: dict[str, bool] = {}
_stream_cache_lock = threading.Lock()

DEFAULT_RECONNECT_ATTEMPTS = 5
DEFAULT_RECONNECT_BASE_DELAY = 1.0
DEFAULT_RECONNECT_MAX_DELAY = 30.0
DEFAULT_CONNECT_TIMEOUT = 10.0

# ── JetStream Event Bus ───────────────────────────────────────────────────


class JetStreamEventBus:
    """Publikuje eventy domenowe do NATS JetStream.

    SUPERMOCE:
      - Automatyczny reconnect z wykładniczym backoffem (max 5 prób, 1s-30s)
      - Graceful degradation gdy NATS niedostępny
      - Batch publish dla wysokiej przepustowości
      - Stream auto-creation przy starcie

    Args:
        nats_servers: Lista serwerów NATS (np. ``["nats://localhost:4222"]``).
        connect_timeout: Timeout na połączenie w sekundach.
        reconnect_attempts: Maksymalna liczba prób reconnectu (0 = brak, -1 = nieskończone).
        reconnect_base_delay: Bazowe opóźnienie między reconnectami (sekundy).
        reconnect_max_delay: Maksymalne opóźnienie między reconnectami (sekundy).
        name: Nazwa połączenia NATS (dla diagnostyki).
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
        reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS,
        reconnect_base_delay: float = DEFAULT_RECONNECT_BASE_DELAY,
        reconnect_max_delay: float = DEFAULT_RECONNECT_MAX_DELAY,
        name: str = "nexus-event-bus",
    ) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._connect_timeout = connect_timeout
        self._reconnect_attempts = reconnect_attempts
        self._reconnect_base_delay = reconnect_base_delay
        self._reconnect_max_delay = reconnect_max_delay
        self._name = name
        self._nc: Any = None
        self._js: Any = None
        self._connected = False
        self._connect_lock = threading.Lock()
        self._kv_stores: dict[str, Any] = {}
        self._object_stores: dict[str, Any] = {}

    # ── Connection management ───────────────────────────────────────────

    async def _ensure_connected(self) -> bool:
        """Ensure NATS connection is active with exponential backoff reconnect."""
        if self._connected and self._nc is not None:
            try:
                await self._nc.ping()
                return True
            except Exception:
                logger.warning("[JETSTREAM] Connection lost — attempting reconnect")
                self._connected = False

        with self._connect_lock:
            if self._connected:
                return True
            attempt, last_error = 0, None
            max_attempts = self._reconnect_attempts

            while max_attempts < 0 or attempt < max_attempts:
                attempt += 1
                try:
                    async def _on_disconnect() -> None: logger.warning("[JETSTREAM] Connection lost")
                    async def _on_reconnect() -> None: logger.info("[JETSTREAM] Reconnected")
                    async def _on_close() -> None: logger.info("[JETSTREAM] Connection closed")
                    import nats
                    if self._nc is not None:
                        await safe_close(self._nc)
                    self._nc = await nats.connect(servers=self._nats_servers, connect_timeout=self._connect_timeout,
                                                   name=self._name, disconnected_cb=_on_disconnect,
                                                   reconnected_cb=_on_reconnect, closed_cb=_on_close,
                                                   reconnect_time_wait=self._reconnect_base_delay, max_reconnect_attempts=-1)
                    self._js = self._nc.jetstream()
                    self._connected = True
                    for cfg in STREAM_CONFIG.values():
                        await self._ensure_stream(cfg)
                    logger.info("[JETSTREAM] Connected (attempt %d)", attempt)
                    return True
                except Exception as exc:
                    last_error = exc
                    if max_attempts != -1 and attempt >= max_attempts:
                        break
                    delay = min(self._reconnect_base_delay * (2 ** (attempt - 1)), self._reconnect_max_delay) * (0.8 + random.random() * 0.4)
                    logger.warning("[JETSTREAM] Reconnect attempt %d/%s failed (retry in %.1fs)", attempt, "∞" if max_attempts < 0 else str(max_attempts), delay)
                    await anyio.sleep(delay)
            logger.error("[JETSTREAM] All reconnect attempts failed: %s", last_error)
            self._connected = False
            return False

    # ── Stream management ───────────────────────────────────────────────

    async def _ensure_stream(self, cfg: dict[str, Any]) -> None:
        """Ensure JetStream stream exists with mirror/sourcing support."""
        if self._js is None:
            return
        stream_name = cfg["stream_name"]
        with _stream_cache_lock:
            if stream_name in _stream_cache:
                return
        try:
            from nats.js.api import CompressionOption, DiscardPolicy, RetentionPolicy, StorageType
            _RETENTION_MAP = {"limits": RetentionPolicy.LIMITS, "interest": RetentionPolicy.INTEREST, "workqueue": RetentionPolicy.WORK_QUEUE}
            try:
                await self._js.stream_info(stream_name)
            except Exception:
                kw: dict[str, Any] = {"name": stream_name, "max_age": cfg["max_age_days"] * 86400, "storage": StorageType.FILE,
                                      "replicas": cfg.get("replicas", 1), "retention": _RETENTION_MAP.get(cfg.get("retention", "limits"), RetentionPolicy.LIMITS),
                                      "max_msg_size": cfg.get("max_msg_size", 64*1024**2), "max_msgs_per_subject": 10_000,
                                      "duplicate_window": 120_000_000_000, "discard": DiscardPolicy.OLD,
                                      "compression": CompressionOption.S2, "deny_delete": "audit" in stream_name}
                if "mirror" in cfg:
                    kw["mirror"] = cfg["mirror"]; kw.pop("subjects", None); kw.pop("max_msgs_per_subject", None)
                elif "sources" in cfg:
                    kw["sources"] = cfg["sources"]; kw.pop("subjects", None); kw.pop("max_msgs_per_subject", None)
                else:
                    kw["subjects"] = cfg["subjects"]
                await self._js.add_stream(**kw)
            with _stream_cache_lock:
                _stream_cache[stream_name] = True
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to ensure stream %s: %s", stream_name, exc)  #  # ── Store access (KV / Object) ─────────────────────────────────────

    async def _get_or_create_store(self, bucket: str, store_type: str) -> Any | None:
        """Get or create a JetStream store (KV or Object)."""
        stores = self._kv_stores if store_type == "kv" else self._object_stores
        create_fn = self._js.create_key_value if store_type == "kv" else self._js.create_object_store
        get_fn = self._js.key_value if store_type == "kv" else self._js.object_store
        if bucket in stores:
            return stores[bucket]
        for fn in [create_fn, get_fn]:
            try:
                result = await fn(bucket=bucket)
                stores[bucket] = result
                return result
            except Exception:
                continue
        logger.warning("[JETSTREAM:%s] Failed to get bucket %s", store_type.upper(), bucket)
        return None

    async def get_kv_store(self, bucket_name: str) -> Any | None:
        if not await self._ensure_connected():
            return None
        return await self._get_or_create_store(bucket_name, "kv")

    async def get_object_store(self, bucket_name: str) -> Any | None:
        if not await self._ensure_connected():
            return None
        return await self._get_or_create_store(bucket_name, "object")

    # ── Direct Get API ─────────────────────────────────────────────────

    async def get_message(self, stream_name: str, seq: int) -> Any | None:
        if not await self._ensure_connected() or self._js is None: return None
        try: return await self._js.get_msg(stream_name, seq)
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to get msg %s/%d: %s", stream_name, seq, exc); return None

    async def get_last_message(self, stream_name: str) -> Any | None:
        try:
            info = await self._js.stream_info(stream_name)
            return await self.get_message(stream_name, info.state.last_seq) if info.state.last_seq > 0 else None
        except Exception: return None

    async def purge_stream(self, stream_name: str) -> bool:
        if not await self._ensure_connected() or self._js is None: return False
        try: await self._js.purge_stream(stream_name); return True
        except Exception as exc: logger.warning("[JETSTREAM] Failed to purge %s: %s", stream_name, exc); return False

    async def delete_message(self, stream_name: str, seq: int) -> bool:
        if not await self._ensure_connected() or self._js is None: return False
        try: await self._js.delete_msg(stream_name, seq); return True
        except Exception as exc: logger.warning("[JETSTREAM] Failed to delete %s/%d: %s", stream_name, seq, exc); return False

    async def seal_stream(self, stream_name: str) -> bool:
        if not await self._ensure_connected() or self._js is None: return False
        try:
            info = await self._js.stream_info(stream_name)
            info.config.sealed = True; await self._js.update_stream(info.config); return True
        except Exception as exc: logger.warning("[JETSTREAM] Failed to seal %s: %s", stream_name, exc); return False

    # ── Publish ─────────────────────────────────────────────────────────

    async def connect(self) -> None:
        await self._ensure_connected()

    async def publish(self, event: DomainEvent) -> bool:
        if not await self._ensure_connected() or self._js is None:
            return False
        try:
            ack = await self._js.publish(f"nexus-{event.aggregate_type}.{event.event_type}", encode_event(event))
            return True
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to publish %s: %s", event.event_type, exc); return False

    async def publish_batch(self, events: list[DomainEvent]) -> int:
        if not await self._ensure_connected() or self._js is None: return 0
        published = 0
        for event in events:
            try: await self._js.publish(f"nexus-{event.aggregate_type}.{event.event_type}", encode_event(event)); published += 1
            except Exception: pass
        return published

    async def close(self) -> None:
        if self._nc is not None:
            await safe_close(self._nc)
            self._nc = self._js = None; self._connected = False
            self._kv_stores.clear(); self._object_stores.clear()

    @property
    def is_connected(self) -> bool: return self._connected
    @property
    def jetstream(self) -> Any | None: return self._js


# ── JetStream Consumer ────────────────────────────────────────────────────


class ConsumerConfig(Struct):
    """JetStream consumer configuration for projections."""
    stream_name: str
    consumer_name: str
    deliver_policy: str = "all"
    filter_subject: str = ""
    max_deliver: int = 3
    ack_wait: int = 30
    max_ack_pending: int = 100
    idle_heartbeat: int = 10
    backoff_delays: list[int] = field(default_factory=list)
    description: str = ""
    headers_only: bool = False
    flow_control: bool = False
    replay_policy: str = "instant"
    num_replicas: int = 0

    def __post_init__(self) -> None:
        if not (1 <= self.max_deliver <= 100): raise ValueError(f"max_deliver must be 1-100, got {self.max_deliver}")
        if not (1 <= self.ack_wait <= 300): raise ValueError(f"ack_wait must be 1-300, got {self.ack_wait}")
        if not (1 <= self.max_ack_pending <= 1000): raise ValueError(f"max_ack_pending must be 1-1000, got {self.max_ack_pending}")
        if not (0 <= self.idle_heartbeat <= 60): raise ValueError(f"idle_heartbeat must be 0-60, got {self.idle_heartbeat}")
        if not (0 <= self.num_replicas <= 3): raise ValueError(f"num_replicas must be 0-3, got {self.num_replicas}")


class JetStreamConsumer:
    """Consumes events from JetStream and dispatches to handlers."""

    def __init__(self, nats_servers: list[str] | str | None = None, configs: list[ConsumerConfig] | None = None,
                 event_handler: Any = None, connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
                 reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._configs = configs or []
        self._event_handler = event_handler
        self._connect_timeout = connect_timeout
        self._reconnect_attempts = reconnect_attempts
        self._nc = self._js = None
        self._consumer_tasks: list[Any] = []
        self._connected = False

    async def start(self) -> None:
        if not await self._connect_nats():
            return
        async def _run_consumers() -> None:
            async with anyio.create_task_group() as tg:
                for cfg in self._configs:
                    tg.start_soon(self._consume_stream, cfg)
        self._consumer_tasks.append(anyio.ensure_backend().create_task(_run_consumers()))

    async def _connect_nats(self) -> bool:
        import nats
        for attempt in range(1, max(self._reconnect_attempts, 1) + 1):
            try:
                self._nc = await nats.connect(servers=self._nats_servers, connect_timeout=self._connect_timeout, name="nexus-event-consumer")
                self._js = self._nc.jetstream()
                self._connected = True; return True
            except Exception as exc:
                if attempt >= self._reconnect_attempts: return False
                await anyio.sleep(min(2 ** (attempt - 1), 10))
        return False

    async def _consume_stream(self, cfg: ConsumerConfig) -> None:
        if not self._connected or self._js is None: return
        try:
            from nats.js.api import ReplayPolicy
            _RPM = {"instant": ReplayPolicy.Instant, "original": ReplayPolicy.Original}
        except ImportError:
            _RPM = {}
        ccfg: dict[str, Any] = {"max_deliver": cfg.max_deliver, "ack_wait": cfg.ack_wait, "max_ack_pending": cfg.max_ack_pending}
        if cfg.idle_heartbeat > 0: ccfg["idle_heartbeat"] = cfg.idle_heartbeat
        if cfg.headers_only: ccfg["headers_only"] = True
        if cfg.flow_control: ccfg["flow_control"] = ccfg["ordered"] = True
        if cfg.replay_policy != "instant" and _RPM: ccfg["replay_policy"] = _RPM.get(cfg.replay_policy, next(iter(_RPM.values())))
        if cfg.num_replicas > 1: ccfg["num_replicas"] = cfg.num_replicas
        if cfg.backoff_delays: ccfg["backoff"] = cfg.backoff_delays
        if cfg.description: ccfg["description"] = cfg.description
        try:
            sub = await self._js.pull_subscribe(subject=cfg.filter_subject or ">", stream=cfg.stream_name, durable=cfg.consumer_name, config=ccfg)
            while True:
                try:
                    msgs = await sub.fetch(batch=10, timeout=5)
                    for msg in msgs:
                        try:
                            event = decode_event(msg.data)
                            if self._event_handler: await self._event_handler(event)
                            await msg.ack()
                        except Exception as exc:
                            await msg.nak(delay=min(5, cfg.ack_wait // 2))
                except NatsErrors.TimeoutError: pass
                except NatsErrors.ConnectionClosedError: break
                except Exception: await anyio.sleep(1)
        except anyio.CancelledError: pass
        except Exception as exc: logger.error("[JETSTREAM:CONSUMER] %s failed: %s", cfg.consumer_name, exc)

    async def stop(self) -> None:
        for task in self._consumer_tasks: task.cancel()
        self._consumer_tasks.clear()
        if self._nc is not None:
            await safe_close(self._nc); self._nc = self._js = None; self._connected = False


# ── Global singleton ─────────────────────────────────────────────────────

_default_bus: JetStreamEventBus | None = None
_default_bus_lock = threading.Lock()


def get_event_bus(nats_servers: list[str] | str | None = None, connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
                  reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS) -> JetStreamEventBus:
    """Get global JetStreamEventBus singleton (thread-safe)."""
    global _default_bus
    if _default_bus is None:
        with _default_bus_lock:
            if _default_bus is None:
                _default_bus = JetStreamEventBus(nats_servers=nats_servers, connect_timeout=connect_timeout, reconnect_attempts=reconnect_attempts)
    return _default_bus
