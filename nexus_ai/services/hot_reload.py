"""
Hot-Reload Listener — odbiera zdarzenia NATS o zmianach reguł i czyści cache.

Tematy:
  - ``billing.rules.updated``   — po utworzeniu/deprecate reguły billingowej
  - ``risk.thresholds.updated`` — po utworzeniu/deprecate progu ryzyka

Usage:
    listener = HotReloadListener(nats_url="nats://localhost:4222")
    await listener.start()
    ...
    await listener.stop()
"""

from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.hot_reload")

SUBJECTS = ("billing.rules.updated", "risk.thresholds.updated", "tax.rules.updated", "ledger.rules.updated")


class HotReloadListener:
    """NATS subscriber for rule/threshold change events.

    On receiving a message:
      1. Logs the change with full payload for observability.
      2. Clears matching API response caches.

    Usage:
        listener = HotReloadListener(nats_url="nats://localhost:4222")
        await listener.start()   # runs in background task
        ...
        await listener.stop()    # graceful shutdown
    """

    def __init__(self, nats_url: str = "nats://localhost:4222") -> None:
        self._nats_url = nats_url
        self._nc: Any = None
        self._subs: list[Any] = []
        self._task: asyncio.Task[None] | None = None
        self._stop_event = asyncio.Event()
        self._started_at: datetime | None = None
        self._event_counts: dict[str, int] = {s: 0 for s in SUBJECTS}
        self._last_event_at: dict[str, str] = {}

    def health(self) -> dict[str, Any]:
        """Return current listener health status.

        Returns:
            dict with:
              - status: "connected" | "disconnected"
              - nats_url: configured NATS URL
              - subscriptions: list of subscribed topics
              - events_total: total events received across all subjects
              - events_per_subject: per-subject event counts
              - last_event_at: per-subject last event timestamp (ISO)
              - uptime_seconds: seconds since listener started (or 0)
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
        }

    async def start(self) -> None:
        """Connect to NATS, subscribe to rule topics, and start listening."""
        import nats

        try:
            self._nc = await nats.connect(self._nats_url)
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Cannot connect to NATS at %s: %s", self._nats_url, exc)
            return

        for subject in SUBJECTS:
            sub = await self._nc.subscribe(subject, queue="nexus-hot-reload")
            self._subs.append(sub)
            logger.info("[HOT-RELOAD] Subscribed to %s (queue=nexus-hot-reload)", subject)

        self._task = asyncio.create_task(self._run())
        self._started_at = pendulum.now("UTC")
        logger.info("[HOT-RELOAD] Listener started")

    async def stop(self) -> None:
        """Gracefully stop the listener and close NATS connection."""
        self._stop_event.set()
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None

        for sub in self._subs:
            try:
                await sub.unsubscribe()
            except Exception:
                pass
        self._subs.clear()

        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
            self._nc = None

        logger.info("[HOT-RELOAD] Listener stopped")

    async def _run(self) -> None:
        """Continuously fetch messages from NATS subscriptions."""
        while not self._stop_event.is_set():
            # Snapshot subs to avoid iteration-while-mutated race with stop()
            subs = list(self._subs)
            for sub in subs:
                if self._stop_event.is_set():
                    return
                try:
                    msg = await asyncio.wait_for(sub.fetch(1, timeout=1.0), timeout=2.0)
                except TimeoutError:
                    continue
                except Exception as exc:
                    logger.warning("[HOT-RELOAD] Fetch error: %s", exc)
                    continue

                await self._on_message(msg)

    async def _on_message(self, msg: Any) -> None:
        """Handle a single NATS message."""
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
            subject, rule_id, action, payload,
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

            if subject == "billing.rules.updated":
                await clear_cache_async(prefix="api.routes.billing")
                logger.info("[HOT-RELOAD] Cleared billing route cache")
            elif subject == "risk.thresholds.updated":
                await clear_cache_async(prefix="api.routes.admin")
                logger.info("[HOT-RELOAD] Cleared admin route cache")
            elif subject == "tax.rules.updated":
                await clear_cache_async(prefix="api.routes.tax")
                logger.info("[HOT-RELOAD] Cleared tax route cache")
            elif subject == "ledger.rules.updated":
                await clear_cache_async(prefix="api.routes.ledger")
                logger.info("[HOT-RELOAD] Cleared ledger route cache")
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Cache clear failed: %s", exc)
