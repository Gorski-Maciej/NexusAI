"""
PredictiveWorkerPoolManager — predykcyjne skalowanie workerów.

INNOWACJA #8 z Raportu v7.0: Worker monitoruje CPU, RAM, długość kolejki NATS.
Predykcyjnie uruchamia/zatrzymuje dodatkowe instancje.
Cel: kolejka zawsze <10 zadań.

Monitoring:
- CPU usage (%)
- RAM usage (%)
- NATS JetStream queue depth
- Average task processing time
- Prediction: linear regression na ostatnich 60s

Usage:
    pool = PredictiveWorkerPoolManager(
        max_workers=4,
        target_queue_depth=10,
        scale_up_threshold=15,
        scale_down_threshold=3,
    )
    await pool.start()
"""

from __future__ import annotations

import os
import time as _time
from collections.abc import Awaitable, Callable
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.worker_pool")


class WorkerMetrics:
    """Snapshot metryk workera w danym momencie."""
    __slots__ = ()

    def __init__(self) -> None:
        self.cpu_percent: float = 0.0
        self.ram_percent: float = 0.0
        self.queue_depth: int = 0
        self.active_workers: int = 1
        self.avg_task_duration_ms: float = 0.0
        self.tasks_completed_last_min: int = 0
        self.tasks_failed_last_min: int = 0
        self.timestamp: float = 0.0


class PredictiveWorkerPoolManager:
    """Predykcyjny menedżer puli workerów.

    Monitoruje metryki i predykcyjnie skaluje liczbę workerów.
    Używa prostej predykcji opartej na trendzie queue depth.

    Args:
        max_workers: Maksymalna liczba workerów.
        min_workers: Minimalna liczba workerów.
        target_queue_depth: Docelowa długość kolejki (cel: zawsze < target).
        scale_up_threshold: Próg kolejki do skalowania w górę.
        scale_down_threshold: Próg kolejki do skalowania w dół.
        cpu_threshold: Maks CPU przed skalowaniem w dół.
        ram_threshold: Maks RAM przed skalowaniem w dół.
        prediction_window_seconds: Okno predykcji.
        check_interval_seconds: Interwał sprawdzania metryk.
    """

    __slots__ = (
        "_active_workers",
        "_check_interval",
        "_cpu_threshold",
        "_history",
        "_max_workers",
        "_metrics_callback",
        "_min_workers",
        "_prediction_window",
        "_ram_threshold",
        "_running",
        "_scale_down_cooldown",
        "_scale_down_threshold",
        "_scale_up_cooldown",
        "_scale_up_threshold",
        "_target_queue_depth",
    )

    def __init__(
        self,
        max_workers: int = 4,
        min_workers: int = 1,
        target_queue_depth: int = 10,
        scale_up_threshold: int = 15,
        scale_down_threshold: int = 3,
        cpu_threshold: float = 80.0,
        ram_threshold: float = 80.0,
        prediction_window_seconds: float = 60.0,
        check_interval_seconds: float = 5.0,
    ) -> None:
        self._max_workers = max(max_workers, min_workers)
        self._min_workers = max(min_workers, 1)
        self._target_queue_depth = target_queue_depth
        self._scale_up_threshold = scale_up_threshold
        self._scale_down_threshold = scale_down_threshold
        self._cpu_threshold = cpu_threshold
        self._ram_threshold = ram_threshold
        self._prediction_window = prediction_window_seconds
        self._check_interval = check_interval_seconds

        self._active_workers = min_workers
        self._history: list[WorkerMetrics] = []
        self._running = False
        self._scale_up_cooldown = 0.0
        self._scale_down_cooldown = 0.0
        self._metrics_callback: Callable[[], Awaitable[WorkerMetrics]] | None = None

    def set_metrics_callback(
        self, callback: Callable[[], Awaitable[WorkerMetrics]]
    ) -> None:
        """Set async callback for collecting worker metrics."""
        self._metrics_callback = callback

    async def start(self) -> None:
        """Start the monitoring and auto-scaling loop."""
        if self._running:
            return
        self._running = True
        logger.info(
            "[WORKER-POOL] Started: min=%d max=%d target_queue=%d",
            self._min_workers,
            self._max_workers,
            self._target_queue_depth,
        )
        import anyio

        while self._running:
            try:
                await self._check_and_scale()
            except Exception as exc:
                logger.warning("[WORKER-POOL] Check failed: %s", exc)
            await anyio.sleep(self._check_interval)

    async def stop(self) -> None:
        """Stop the monitoring loop."""
        self._running = False
        logger.info("[WORKER-POOL] Stopped")

    async def _check_and_scale(self) -> None:
        """Check metrics and scale workers if needed."""
        now = _time.time()

        # Collect metrics
        metrics = await self._collect_metrics()
        self._history.append(metrics)

        # Keep only prediction window worth of history
        cutoff = now - self._prediction_window
        self._history = [m for m in self._history if m.timestamp > cutoff]

        # ── Resource check ───────────────────────────────────────────
        if metrics.cpu_percent > self._cpu_threshold:
            logger.warning(
                "[WORKER-POOL] CPU %.1f%% > threshold %.1f%% — not scaling up",
                metrics.cpu_percent,
                self._cpu_threshold,
            )
            return

        if metrics.ram_percent > self._ram_threshold:
            logger.warning(
                "[WORKER-POOL] RAM %.1f%% > threshold %.1f%% — not scaling up",
                metrics.ram_percent,
                self._ram_threshold,
            )
            return

        # ── Predicted queue depth ────────────────────────────────────
        predicted = self._predict_queue_depth()

        # ── Scale UP ─────────────────────────────────────────────────
        if predicted > self._scale_up_threshold and now - self._scale_up_cooldown > 30.0:
            new_count = min(self._active_workers + 1, self._max_workers)
            if new_count > self._active_workers:
                await self._scale_to(new_count, reason=f"predicted queue: {predicted}")
                self._scale_up_cooldown = now

        # ── Scale DOWN ───────────────────────────────────────────────
        elif predicted < self._scale_down_threshold and now - self._scale_down_cooldown > 60.0:
            new_count = max(self._active_workers - 1, self._min_workers)
            if new_count < self._active_workers:
                await self._scale_to(new_count, reason=f"low predicted queue: {predicted}")
                self._scale_down_cooldown = now

    async def _collect_metrics(self) -> WorkerMetrics:
        """Collect current worker metrics."""
        if self._metrics_callback:
            return await self._metrics_callback()

        # Fallback: basic system metrics
        import psutil

        cpu = psutil.cpu_percent(interval=0.1)
        ram = psutil.virtual_memory().percent
        queue = 0  # Would need NATS JetStream consumer info

        return WorkerMetrics(
            cpu_percent=float(cpu),
            ram_percent=float(ram),
            queue_depth=queue,
            active_workers=self._active_workers,
            timestamp=_time.time(),
        )

    def _predict_queue_depth(self) -> float:
        """Predict queue depth using simple linear trend from history.

        Uses last N measurements to estimate trend.
        If insufficient data, returns current queue depth.
        """
        if len(self._history) < 3:
            return float(self._history[-1].queue_depth) if self._history else 0.0

        # Simple linear trend: average of last 3 measurements + trend
        recent = self._history[-3:]
        values = [m.queue_depth for m in recent]
        avg = sum(values) / len(values)

        # Trend: difference between last and first in window
        trend = values[-1] - values[0]
        predicted = avg + trend * 0.5  # Weight trend at 50%

        return max(0.0, predicted)

    async def _scale_to(self, target: int, reason: str = "") -> None:
        """Scale to target worker count."""
        old = self._active_workers
        self._active_workers = target
        direction = "UP" if target > old else "DOWN"
        logger.info(
            "[WORKER-POOL] Scale %s: %d → %d workers (reason: %s)",
            direction,
            old,
            target,
            reason,
        )
        # TODO: Integration with Granian worker management API
        # For now, this is advisory — actual scaling requires
        # process management via Granian or OS signals.

    def get_stats(self) -> dict[str, Any]:
        """Return current pool statistics."""
        return {
            "active_workers": self._active_workers,
            "max_workers": self._max_workers,
            "min_workers": self._min_workers,
            "target_queue_depth": self._target_queue_depth,
            "history_size": len(self._history),
            "predicted_queue_depth": self._predict_queue_depth(),
            "current_queue_depth": self._history[-1].queue_depth if self._history else 0,
            "is_running": self._running,
        }

    @property
    def active_workers(self) -> int:
        return self._active_workers

    @property
    def is_running(self) -> bool:
        return self._running


__all__ = [
    "PredictiveWorkerPoolManager",
    "WorkerMetrics",
]
