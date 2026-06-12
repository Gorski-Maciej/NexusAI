"""Central Background Task Manager for NexusAI API.

Zastępuje rozrzucone ``tg.start_soon()`` i ``anyio.ensure_backend().create_task()``
po kontrolerach — zapewnia centralną rejestrację, monitoring i anulowanie
wszystkich background tasków podczas shutdownu API.

Usage:
    # Startup — rejestracja taska
    app.state.bg_tasks = BackgroundTaskManager()
    app.state.bg_tasks.start_task(
        "metrics_updater",
        _update_system_metrics(),
        metadata={"description": "System metrics (30s interval)"},
    )

    # Shutdown — anulowanie wszystkich
    await app.state.bg_tasks.cancel_all()

    # Controller — fire-and-forget przez DI
    app.state.bg_tasks.start_task(
        f"notification_{invoice_id}",
        _send_notification_async(service, user, ...),
    )
"""

from __future__ import annotations

import threading
import time
from typing import Any

import anyio
from structlog import get_logger

logger = get_logger("nexus.core.background_tasks")


class BackgroundTaskManager:
    """Central manager for long-running background tasks on ``app.state``.

    Zapewnia:
      - Rejestrację tasków z unikalnymi nazwami i metadanymi
      - Automatyczne anulowanie poprzedniego taska przy rejestracji pod tą samą nazwą
      - ``cancel_all()`` na shutdown — anuluje wszystkie aktywne taski
      - ``get_status()`` dla monitorowania i health check
      - Thread-safety dla free-threaded Python 3.13t (``threading.Lock``)
    """

    def __init__(self) -> None:
        self._tasks: dict[str, Any] = {}
        self._metadata: dict[str, dict[str, Any]] = {}
        self._lock = threading.Lock()

    def start_task(
        self,
        name: str,
        coro: Any,
        metadata: dict[str, Any] | None = None,
    ) -> Any:
        """Register and start a background task.

        Args:
            name: Unikalna nazwa taska (nadpisuje istniejący o tej samej nazwie).
            coro: Coroutine do uruchomienia w tle (np. ``_my_loop()``).
            metadata: Opcjonalne metadane (description, interval, owner).

        Returns:
            Handle taska (np. ``asyncio.Task``) — do bezpośredniego użycia,
            ale normalnie zarządzanie odbywa się przez ``cancel_all()``.

        Thread-safe: używa ``threading.Lock()``.
        """
        task = anyio.ensure_backend().create_task(coro)
        started_at = time.monotonic()
        with self._lock:
            # Anuluj poprzedni task o tej samej nazwie jeśli jeszcze działa
            existing = self._tasks.get(name)
            if existing is not None and not existing.done():
                existing.cancel()
                logger.debug("[BG-TASK] Cancelled existing task '%s' (replaced)", name)
            self._tasks[name] = task
            self._metadata[name] = {
                "started_at": started_at,
                "running": True,
                **(metadata or {}),
            }
        logger.info(
            "[BG-TASK] Started '%s'%s",
            name,
            f" — {metadata['description']}" if metadata and "description" in metadata else "",
        )
        return task

    async def cancel_all(self) -> None:
        """Cancel ALL registered background tasks.

        Iteruje po wszystkich zarejestrowanych taskach, anuluje je,
        i czeka na ich zakończenie (z timeoutem 5s na task).

        Wywoływane podczas ``on_shutdown`` API.
        """
        with self._lock:
            tasks = list(self._tasks.items())
            self._tasks.clear()
            self._metadata.clear()

        if not tasks:
            logger.debug("[BG-TASK] No background tasks to cancel")
            return

        for name, task in tasks:
            if task.done():
                logger.debug("[BG-TASK] Task '%s' already completed", name)
                continue
            try:
                task.cancel()
                with anyio.fail_after(5):
                    await task
                logger.info("[BG-TASK] Cancelled '%s'", name)
            except TimeoutError:
                logger.warning("[BG-TASK] Timeout cancelling '%s' — forcing", name)
            except BaseException:
                # CancelledError dziedziczy po BaseException (Python >=3.9),
                # więc używamy BaseException zamiast Exception
                logger.debug("[BG-TASK] Task '%s' finished after cancel", name)

        logger.info("[BG-TASK] All background tasks cancelled")

    def get_status(self) -> dict[str, Any]:
        """Return status snapshot of all registered tasks.

        Returns:
            Dict mapping task name → status info.
            Nadaje się do health check endpointu.
        """
        with self._lock:
            now = time.monotonic()
            return {
                name: {
                    "running": not task.done(),
                    "cancelled": task.cancelled() if hasattr(task, "cancelled") else False,
                    "uptime_seconds": round(now - self._metadata.get(name, {}).get("started_at", now), 1),
                    "description": self._metadata.get(name, {}).get("description"),
                }
                for name, task in self._tasks.items()
            }

    def get_task_count(self) -> int:
        """Return number of currently registered tasks."""
        with self._lock:
            return len(self._tasks)
