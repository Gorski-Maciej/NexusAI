"""
[DEPRECATED] BackgroundTaskManager — zastąpiony przez Taskiq.

UWAGA: Ten moduł jest LEGACY i zostanie usunięty w wersji 3.0.0.

WSZYSTKIE background taski powinny być zadaniami Taskiq:
  - Long-running: @broker.task, fire-and-forget przez broker.kick()
  - Periodic: @broker.task(schedule=[{"cron": "..."}])
  - Lifecycle: @broker.on_event(TaskiqEvents.WORKER_STARTUP)

Zalety przejścia na Taskiq:
  - Persistentność: zadania nie giną przy restarcie API
  - Monitorowanie: metryki przez middleware
  - Skalowanie: wiele workerów
  - Mniej kodu: ~300 LOC mniej

Usage (NOWY SPOSÓB — Taskiq):
    # Periodic task (zamiast BackgroundTaskManager)
    @broker.task(
        schedule=[{"cron": "*/30 * * * * *"}],
        task_name="metrics_updater",
        labels={"service": "core", "operation": "metrics"},
    )
    async def update_system_metrics():
        ...

    # Fire-and-forget (zamiast start_task)
    await broker.kick("send_notification", notification_id="...")
"""

from __future__ import annotations

import threading
from typing import Any, Callable, Coroutine

import anyio
import msgspec
from structlog import get_logger

logger = get_logger("nexus.core.background_tasks")


# ── Typed task metadata ────────────────────────────────────────────────────


class TaskMetadata(msgspec.Struct, kw_only=True):
    """Typed metadata for a registered background task.

    Attributes:
        description: Human-readable description of the task.
        started_at: Monotonic timestamp when the task was started.
        owner: Optional owner identifier (e.g., "controller:invoices").
        interval_seconds: Optional expected interval for periodic tasks.
    """
    description: str = ""
    started_at: float = 0.0
    owner: str = ""
    interval_seconds: float = 0.0


class TaskInfo(msgspec.Struct, kw_only=True):
    """Runtime status of a registered background task.

    Attributes:
        name: Unique task name.
        running: Whether the task is currently executing.
        uptime_seconds: Seconds since the task started.
        description: Human-readable description.
        owner: Task owner identifier.
    """
    name: str = ""
    running: bool = False
    uptime_seconds: float = 0.0
    description: str = ""
    owner: str = ""


class BackgroundTaskManager:
    """Central manager for long-running background tasks — TaskGroup-based.

    Each task is started in its own anyio task group (nursery) for independent
    lifecycle management. On shutdown, all task groups are cancelled via
    CancelScope and the manager awaits their completion with a timeout.

    Thread-safety: uses threading.Lock() for free-threaded Python 3.13t.

    Compared to the legacy ``ensure_backend().create_task()`` approach:
      - Structured concurrency: child tasks are cancelled when the group exits
      - No orphaned tasks: cancel_all() properly awaits all subtasks
      - Type-safe metadata via msgspec.Struct
      - Proper exception handling per task group
      - TaskGroup.start() ensures task signals readiness before parent continues
    """

    def __init__(self) -> None:
        self._tasks: dict[str, anyio.CancelScope] = {}
        self._metadata: dict[str, TaskMetadata] = {}
        self._lock = threading.Lock()
        # Persistent nursery — lazy-created on first start_task() call
        self._nursery: anyio.abc.TaskGroup | None = None

    async def start_task(
        self,
        name: str,
        coro_fn: Callable[..., Coroutine[Any, Any, Any]],
        *args: Any,
        metadata: TaskMetadata | None = None,
        **kwargs: Any,
    ) -> None:
        """Register and start a background task using TaskGroup.start().

        Uses ``TaskGroup.start()`` internally which provides structured
        concurrency: the child task signals readiness via ``task_status.started()``,
        and the parent awaits that signal before continuing. This ensures proper
        lifecycle — the task is running and cancelable before ``start_task()`` returns.

        The task runs inside a persistent nursery (auto-created on first use),
        ensuring all tasks are properly cancelled when cancel_all() is called.

        Args:
            name: Unique task name (replaces existing task with the same name).
            coro_fn: Async callable to run in the background.
            *args: Positional arguments passed to the coroutine.
            metadata: Optional typed metadata (TaskMetadata struct).
            **kwargs: Keyword arguments passed to the coroutine.

        Thread-safe: uses threading.Lock().
        """
        meta = metadata or TaskMetadata()
        meta.started_at = anyio.current_time()

        # Cancel existing task with the same name
        with self._lock:
            existing_scope = self._tasks.get(name)
            if existing_scope is not None and not existing_scope.cancel_called:
                existing_scope.cancel()
                logger.debug("[BG-TASK] Cancelled existing task '%s' (replaced)", name)

        async def _run_wrapped(task_status: anyio.abc.TaskStatus) -> None:
            """Wrap the coroutine in a CancelScope for proper cancellation.

            Uses TaskGroup.start() protocol: calls ``task_status.started()``
            after setting up the CancelScope, so the parent knows the task is
            running before continuing.
            """
            cancel_scope = anyio.CancelScope()
            # Store scope so cancel_all() can find it
            with self._lock:
                self._tasks[name] = cancel_scope
                self._metadata[name] = meta

            # Signal that we're fully initialized and running
            task_status.started()

            try:
                with cancel_scope:
                    await coro_fn(*args, **kwargs)
            except anyio.get_cancelled_exc_class():
                logger.debug("[BG-TASK] Task '%s' cancelled", name)
            except Exception:
                logger.exception("[BG-TASK] Task '%s' failed", name)
            finally:
                with self._lock:
                    self._tasks.pop(name, None)
                    self._metadata.pop(name, None)

        # Lazy-init nursery on first use
        if self._nursery is None:
            self._nursery = await anyio.create_task_group().__aenter__()

        # Use TaskGroup.start() — waits for task_status.started()
        await self._nursery.start(_run_wrapped)

        logger.info(
            "[BG-TASK] Started '%s'%s",
            name,
            f" — {meta.description}" if meta.description else "",
        )

    async def cancel_all(self) -> None:
        """Cancel ALL registered background tasks.

        Cancels the persistent nursery's cancel scope, which cascades to all
        child tasks. Each task gets a 5-second timeout for graceful shutdown.
        """
        nursery = self._nursery
        if nursery is None:
            logger.debug("[BG-TASK] No background tasks to cancel")
            return

        with self._lock:
            names = list(self._tasks.keys())

        if names:
            logger.info("[BG-TASK] Cancelling %d background task(s)", len(names))

        # Cancel the nursery scope — this cancels all child tasks
        if not nursery.cancel_scope.cancel_called:
            nursery.cancel_scope.cancel()

        # Give tasks time to clean up (with timeout)
        with anyio.move_on_after(5):
            await anyio.sleep(0)  # Yield to allow pending cleanups

        # Exit and re-create nursery
        try:
            await nursery.__aexit__(None, None, None)
        except BaseExceptionGroup as eg:
            # TaskGroup may raise BaseExceptionGroup on cancellation — that's expected
            logger.debug("[BG-TASK] Nursery exit suppressed %d exception(s)", len(eg.exceptions))
        except Exception:
            logger.exception("[BG-TASK] Nursery exit error")

        self._nursery = None

        # Final cleanup: remove any stragglers
        with self._lock:
            remaining = len(self._tasks)
            if remaining:
                logger.warning("[BG-TASK] %d task(s) still registered after cancel_all", remaining)
                self._tasks.clear()
                self._metadata.clear()

        logger.info("[BG-TASK] All background tasks cancelled")

    def get_status(self) -> dict[str, TaskInfo]:
        """Return status snapshot of all registered tasks.

        Returns:
            Dict mapping task name -> TaskInfo struct.
            Suitable for health check endpoints.
        """
        with self._lock:
            now = anyio.current_time()
            return {
                name: TaskInfo(
                    name=name,
                    running=not scope.cancel_called,
                    uptime_seconds=round(
                        now - meta.started_at, 1
                    ) if meta.started_at else 0.0,
                    description=meta.description,
                    owner=meta.owner,
                )
                for name, scope in self._tasks.items()
                if (meta := self._metadata.get(name)) is not None
            }

    def get_task_count(self) -> int:
        """Return number of currently registered tasks."""
        with self._lock:
            return len(self._tasks)

    def get_task(self, name: str) -> TaskInfo | None:
        """Return status of a specific task.

        Args:
            name: Task name to look up.

        Returns:
            TaskInfo if found, None otherwise.
        """
        with self._lock:
            scope = self._tasks.get(name)
            meta = self._metadata.get(name)
            if scope is None or meta is None:
                return None
            now = anyio.current_time()
            return TaskInfo(
                name=name,
                running=not scope.cancel_called,
                uptime_seconds=round(now - meta.started_at, 1) if meta.started_at else 0.0,
                description=meta.description,
                owner=meta.owner,
            )
