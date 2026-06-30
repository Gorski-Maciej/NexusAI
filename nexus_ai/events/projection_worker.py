"""ProjectionWorker -- standalone process consuming domain events from NATS JetStream.

Merged into projections.py for module consolidation.
This is a backward-compatible re-export shim.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import anyio
from structlog import get_logger

from nexus_ai.events.domain_events import decode_event
from nexus_ai.events.event_store import EventStore
from nexus_ai.events.jetstream_bus import STREAM_CONFIG
from nexus_ai.events.projections import DecisionProjection, InvoiceProjection, Projection

logger = get_logger("nexus.events.projection_worker")


class ProjectionWorker:
    """Konsumuje eventy z JetStream i aktualizuje projekcje CQRS."""

    def __init__(self, event_store: EventStore | None = None, nats_servers: list[str] | str | None = None,
                 poll_interval_seconds: float = 1.0, batch_size: int = 10,
                 enable_fallback_poll: bool = True, fallback_poll_seconds: float = 30.0) -> None:
        self._event_store = event_store
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._poll_interval = poll_interval_seconds
        self._batch_size = batch_size
        self._enable_fallback = enable_fallback_poll
        self._fallback_poll_seconds = fallback_poll_seconds
        self._projections: list[tuple[Projection, str, str]] = []
        self._nc: Any = None
        self._js: Any = None
        self._connected = False
        self._consumer_tasks: list[Any] = []
        self._fallback_task: Any | None = None
        self._shutdown_event = anyio.Event()

    def add_projection(self, projection: Projection, stream_name: str | None = None, filter_subject: str = "") -> None:
        if stream_name is None:
            stream_name = "nexus-invoice" if isinstance(projection, InvoiceProjection) else "nexus-decision"
        self._projections.append((projection, stream_name, filter_subject))
        logger.info("[PROJECTION-WORKER] Registered %s -> %s", projection.name, stream_name)

    async def start(self) -> None:
        logger.info("[PROJECTION-WORKER] Starting with %d projections", len(self._projections))
        try:
            await self._connect_nats()
        except Exception as exc:
            logger.warning("[PROJECTION-WORKER] NATS failed: %s", exc)
        if self._connected:
            for projection, stream_name, filter_subject in self._projections:
                task = anyio.create_task(self._consume_stream(projection, stream_name, filter_subject))
                self._consumer_tasks.append(task)
        if self._enable_fallback:
            self._fallback_task = anyio.create_task(self._fallback_poll_loop())
        try:
            await self._shutdown_event.wait()
        except anyio.CancelledError:
            pass

    async def stop(self) -> None:
        logger.info("[PROJECTION-WORKER] Stopping...")
        for task in self._consumer_tasks:
            task.cancel()
        if self._consumer_tasks:
            await anyio.gather(*self._consumer_tasks, return_exceptions=True)
        self._consumer_tasks.clear()
        if self._fallback_task is not None:
            self._fallback_task.cancel()
            try:
                await self._fallback_task
            except (anyio.CancelledError, Exception):
                pass
        if self._nc is not None:
            from nexus_ai.core.nats_utils import safe_close
            await safe_close(self._nc)
            self._nc = None
            self._js = None
            self._connected = False
        logger.info("[PROJECTION-WORKER] Stopped")

    def handle_signal(self, sig: int, _frame: Any = None) -> None:
        self._shutdown_event.set()

    async def _connect_nats(self) -> None:
        from nexus_ai.core.nats_utils import NatsErrors, get_connection
        NatsErrors.init()
        self._nc = await get_connection(nats_url=self._nats_servers, name="nexus-projection-worker", connect_timeout=10.0)
        self._js = self._nc.jetstream()
        self._connected = True
        logger.info("[PROJECTION-WORKER] Connected to NATS")
        for projection, stream_name, _ in self._projections:
            try:
                try:
                    await self._js.stream_info(stream_name)
                except Exception:
                    from nats.js.api import StorageType
                    agg_type = "invoice" if isinstance(projection, InvoiceProjection) else "decision"
                    cfg = STREAM_CONFIG.get(agg_type, {})
                    await self._js.add_stream(name=stream_name, subjects=cfg.get("subjects", [f"{stream_name}.>"]),
                                              max_age=cfg.get("max_age_days", 90) * 24 * 3600,
                                              storage=StorageType.FILE, replicas=cfg.get("replicas", 1))
                    logger.info("[PROJECTION-WORKER] Created stream: %s", stream_name)
            except Exception as exc:
                logger.warning("[PROJECTION-WORKER] Failed to ensure stream %s: %s", stream_name, exc)

    async def _consume_stream(self, projection: Projection, stream_name: str, filter_subject: str) -> None:
        if not self._connected or self._js is None:
            return
        try:
            sub = await self._js.pull_subscribe(subject=filter_subject or ">", stream=stream_name,
                 durable=f"{projection.name}-worker",
                 config=dict(max_deliver=3, ack_wait=30, max_ack_pending=100, idle_heartbeat=10, flow_control=True, ordered=True))
            while not self._shutdown_event.is_set():
                try:
                    for msg in await sub.fetch(batch=self._batch_size, timeout=self._poll_interval):
                        await self._process_message(projection, msg)
                except TimeoutError:
                    continue
                except Exception as exc:
                    if not self._shutdown_event.is_set():
                        logger.warning("[PROJECTION-WORKER] Fetch error: %s", exc)
                        await anyio.sleep(1)
        except anyio.CancelledError:
            pass
        except Exception as exc:
            logger.error("[PROJECTION-WORKER] Consumer %s failed: %s", projection.name, exc)

    async def _process_message(self, projection: Projection, msg: Any) -> None:
        try:
            event = decode_event(msg.data)
            await projection._handle_event(event)
            await msg.ack()
            if self._event_store is not None:
                try:
                    await self._event_store.update_checkpoint(projection.name, event.event_id, event.version)
                except Exception:
                    pass
        except Exception as exc:
            logger.warning("[PROJECTION-WORKER] Failed: %s", exc)
            try:
                await msg.nak(delay=5)
            except Exception:
                pass

    async def _fallback_poll_loop(self) -> None:
        while not self._shutdown_event.is_set():
            try:
                await anyio.sleep(self._fallback_poll_seconds)
                for projection, _, _ in self._projections:
                    try:
                        if (processed := await projection.process()) > 0:
                            logger.info("[FALLBACK] %s processed %d events", projection.name, processed)
                    except Exception as exc:
                        logger.warning("[FALLBACK] %s failed: %s", projection.name, exc)
            except anyio.CancelledError:
                break
            except Exception as exc:
                logger.error("[FALLBACK] Error: %s", exc)

    @property
    def is_connected(self) -> bool:
        return self._connected

    def get_status(self) -> dict[str, Any]:
        return dict(nats_connected=self._connected, nats_servers=self._nats_servers,
                    projections=[dict(name=p.name, stream=s, filter=f or "*") for p, s, f in self._projections],
                    consumer_tasks=len(self._consumer_tasks), fallback_enabled=self._enable_fallback)


async def create_default_worker(base_dir: str | Path | None = None, nats_servers: list[str] | str | None = None,
                                enable_fallback: bool = True, poll_interval: float = 1.0,
                                batch_size: int = 10, fallback_poll_seconds: float = 30.0) -> ProjectionWorker:
    from nexus_ai.core.config import AppConfig
    from nexus_ai.events import EventStore
    base_dir = Path(base_dir or AppConfig.from_toml().base_dir)
    event_store = EventStore(db_path=str(base_dir / "app_data" / "events.db"))
    inv_proj = InvoiceProjection(event_store=event_store, db_path=str(base_dir / "app_data" / "projections" / "invoices.db"))
    dec_proj = DecisionProjection(event_store=event_store, db_path=str(base_dir / "app_data" / "projections" / "decisions.db"))
    worker = ProjectionWorker(event_store=event_store, nats_servers=nats_servers, enable_fallback_poll=enable_fallback,
                              poll_interval_seconds=poll_interval, batch_size=batch_size, fallback_poll_seconds=fallback_poll_seconds)
    worker.add_projection(inv_proj)
    worker.add_projection(dec_proj)
    return worker
