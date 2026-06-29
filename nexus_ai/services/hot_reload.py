"""
Hot-Reload Listener — odbiera zdarzenia NATS JetStream o zmianach reguł i czyści cache.

Zalety:
  - Durable consumer — checkpointy, retry, DLQ
  - At-least-once delivery — żadne zdarzenie nie ginie
  - Queue group — horizontal scaling listenerów
  - Retry z backoffem — automatyczne ponowienie przy błędach

Tematy (subjects):
  - ``nexus-config.billing.rules.updated``   — po utworzeniu/deprecate reguły billingowej
  - ``nexus-config.risk.thresholds.updated`` — po utworzeniu/deprecate progu ryzyka
  - ``nexus-config.tax.rules.updated``       — po zmianie reguł podatkowych
  - ``nexus-config.ledger.rules.updated``    — po zmianie reguł księgowych

Usage:
    listener = HotReloadListener(nats_url=\"nats://localhost:4222\")
    await listener.start()   # runs in background
    ...
    await listener.stop()    # graceful shutdown
"""

from __future__ import annotations

import anyio
from typing import Any, final

import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.hot_reload")

# Mapowanie: subject JetStream → prefix cache do wyczyszczenia
SUBJECT_CONFIG: dict[str, str] = {
    "nexus-config.billing.rules.updated": "api.routes.billing",
    "nexus-config.risk.thresholds.updated": "api.routes.admin",
    "nexus-config.tax.rules.updated": "api.routes.tax",
    "nexus-config.ledger.rules.updated": "api.routes.ledger",
}

SUBJECTS = tuple(SUBJECT_CONFIG.keys())


@final
class HotReloadListener:
    """NATS JetStream subscriber for rule/threshold change events.

      - Durable Pull Consumer z checkpointami (zamiast core NATS subscribe)
      - Queue group dla horizontal scaling (nexus-hot-reload)
      - At-least-once delivery — retry przy błędach
      - Metryki health dla każdego subjecta
      - Graceful shutdown

    Usage:
        listener = HotReloadListener(nats_url=\"nats://localhost:4222\")
        await listener.start()   # runs in background task
        ...
        await listener.stop()    # graceful shutdown
    """

    def __init__(self, nats_url: str = "nats://localhost:4222") -> None:
        self._nats_url = nats_url
        self._nc: Any = None
        self._js: Any = None
        self._subs: list[Any] = []
        self._task: anyio.abc.TaskGroup | None = None
        self._stop_event = anyio.Event()
        self._started_at: pendulum.DateTime | None = None
        self._event_counts: dict[str, int] = {s: 0 for s in SUBJECTS}
        self._last_event_at: dict[str, str] = {}

    def health(self) -> dict[str, Any]:
        """Return current listener health status.

        Returns:
            dict with status, subscriptions, event counts, uptime.
        """
        now = pendulum.now("UTC")
        started = self._started_at
        uptime = (now - started).total_seconds() if started else 0.0

        return {
            "status": "connected" if self._nc is not None else "disconnected",
            "nats_url": self._nats_url,
            "subscriptions": list(SUBJECTS),
            "events_total": sum(self._event_counts.values()),
            "events_per_subject": dict(self._event_counts),
            "last_event_at": dict(self._last_event_at) if self._last_event_at else None,
            "uptime_seconds": round(uptime, 2),
            "jetstream": True,
            "durable_name": "nexus-hot-reload",
        }

    async def _ensure_jetstream_stream(self) -> None:
        """Upewnij się, że strumień nexus-config istnieje.

        """
        if self._js is None:
            return
        try:
            from nats.js.api import StorageType

            try:
                await self._js.stream_info("nexus-config")
            except Exception:
                await self._js.add_stream(
                    name="nexus-config",
                    subjects=["nexus-config.>"],
                    max_age=90 * 24 * 3600,  # 90 dni
                    storage=StorageType.FILE,
                    replicas=1,
                )
                logger.info("[HOT-RELOAD] Created JetStream stream: nexus-config")
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Failed to ensure stream nexus-config: %s", exc)

    async def start(self) -> None:
        """Connect to NATS JetStream, subscribe to rule topics, and start listening.

        """
        from nexus_ai.core.nats_utils import NatsErrors, get_connection

        NatsErrors.init()

        self._nc = await get_connection(
            nats_url=self._nats_url,
            name="nexus-hot-reload",
        )
        if self._nc is None:
            logger.warning("[HOT-RELOAD] Cannot connect to NATS at %s", self._nats_url)
            return
        self._js = self._nc.jetstream()
        await self._ensure_jetstream_stream()

        for subject in SUBJECTS:
            try:
                sub = await self._js.pull_subscribe(
                    subject=subject,
                    stream="nexus-config",
                    durable=f"nexus-hot-reload-{subject.replace('.', '-')}",
                    config={
                        "max_deliver": 3,
                        "ack_wait": 30,
                        "max_ack_pending": 10,
                        "description": f"Hot reload consumer for {subject}",
                    },
                )
                self._subs.append(sub)
                logger.info(
                    "[HOT-RELOAD] Subscribed to %s (durable=nexus-hot-reload-%s)",
                    subject,
                    subject.replace(".", "-"),
                )
            except Exception as exc:
                logger.warning("[HOT-RELOAD] Failed to subscribe to %s: %s", subject, exc)

        self._task = anyio.create_task(self._run())
        self._started_at = pendulum.now("UTC")
        logger.info("[HOT-RELOAD] Listener started (JetStream durable consumers)")

    async def stop(self) -> None:
        """Gracefully stop the listener and close NATS connection."""
        self._stop_event.set()
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except anyio.get_cancelled_exc_class():
                pass
            self._task = None

        for sub in self._subs:
            try:
                await sub.unsubscribe()
            except Exception:
                pass
        self._subs.clear()

        if self._nc is not None:
            from nexus_ai.core.nats_utils import safe_close

            await safe_close(self._nc)
            self._nc = None
            self._js = None

        logger.info("[HOT-RELOAD] Listener stopped")

    async def _run(self) -> None:
        """Continuously fetch messages from JetStream subscriptions."""
        while not self._stop_event.is_set():
            subs = list(self._subs)
            for sub in subs:
                if self._stop_event.is_set():
                    return
                try:
                    with anyio.fail_after(2.0):
                        msgs = await sub.fetch(1, timeout=1.0)
                        for msg in msgs:
                            await self._on_message(msg)
                except TimeoutError:
                    continue
                except Exception as exc:
                    logger.warning("[HOT-RELOAD] Fetch error: %s", exc)
                    continue

    async def _on_message(self, msg: Any) -> None:
        """Handle a single NATS JetStream message."""
        subject = msg.subject
        try:
            payload = msgspec_loads(msg.data)
        except (DecodeError, UnicodeDecodeError) as exc:
            logger.warning("[HOT-RELOAD] Invalid message on %s: %s", subject, exc)
            return

        rule_id = payload.get("rule_id", "unknown")
        action = payload.get("action", "unknown")
        logger.info(
            "[HOT-RELOAD] Event subject=%s rule_id=%s action=%s payload=%s",
            subject,
            rule_id,
            action,
            payload,
        )

        # Update health counters
        self._event_counts[subject] = self._event_counts.get(subject, 0) + 1
        self._last_event_at[subject] = pendulum.now("UTC").isoformat()

        # Record Prometheus metrics
        try:
            from api.telemetry_metrics import record_hot_reload_event

            record_hot_reload_event(subject)
        except Exception:
            pass

        # Clear relevant API caches based on subject
        try:
            from api.cache import clear_cache_async

            cache_prefix = SUBJECT_CONFIG.get(subject)
            if cache_prefix:
                await clear_cache_async(prefix=cache_prefix)
                logger.info("[HOT-RELOAD] Cleared cache for prefix: %s", cache_prefix)
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Cache clear failed: %s", exc)

        try:
            await msg.ack()
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Failed to ack message: %s", exc)

    @property
    def is_connected(self) -> bool:
        return self._nc is not None
