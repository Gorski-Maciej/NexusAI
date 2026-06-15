"""Taskiq worker bootstrap and local connectivity smoke test."""

from __future__ import annotations

import gc
import logging
import os
import platform
import signal
import sys

import anyio
from pathlib import Path as _SyncPath

import pendulum
import psutil
from structlog import get_logger
from taskiq import TaskiqEvents

import nexus_ai.core.tasks  # noqa: F401  # required to register @broker.task handlers
from nexus_ai.core.broker import broker
from nexus_ai.core.cache.http_client import warm_http_cache
from nexus_ai.core.config import AppConfig
from nexus_ai.services.vision.agent import VisionAgent

if getattr(sys, "frozen", False):
    BASE_PATH = _SyncPath(sys._MEIPASS)
else:
    BASE_PATH = _SyncPath(__file__).resolve().parent

MODELS_CACHE_DIR = BASE_PATH / "models"
os.environ.setdefault("HF_HOME", str(MODELS_CACHE_DIR))
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")
os.environ.setdefault("TORCH_HOME", str(MODELS_CACHE_DIR / "torch"))
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")

# ── mimalloc konfiguracja dla workera (audyt Faza 3) ───────────────────────
# Worker długo żyje i intensywnie alokuje dla modeli AI.
# Optymalizacje:
#   - Huge OS pages — redukcja TLB misses dla LightOnOCR-1B (~800MB)
#   - Eager commit — niższe opóźnienia alokacji
#   - Page reset wyłączony — worker nie resetuje stron, żeby nie tracić czasu
os.environ.setdefault("MIMALLOC_LARGE_OS_PAGES", "1")
os.environ.setdefault("MIMALLOC_RESERVE_HUGE_OS_PAGES", "1")
os.environ.setdefault("MIMALLOC_EAGER_COMMIT_DELAY", "0")
os.environ.setdefault("MIMALLOC_PAGE_RESET", "0")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s (PID:%(process)d): %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = get_logger("nexus.worker")

shutdown_flag = anyio.Event()


class WorkerGuard:
    """Watchdog dla procesu workera z dynamicznym limitowaniem współbieżności (Rozwiązanie 29)."""

    def __init__(self, ram_limit_gb: float = 6.0) -> None:
        self.process = psutil.Process(os.getpid())
        self.ram_limit = int(ram_limit_gb * 1024 * 1024 * 1024)
        self.start_time = pendulum.now("UTC")
        # Licznik aktywnych zadań (Rozwiązanie 29)
        self.active_tasks: int = 0
        self.max_concurrent: int = 5  # Domyślny limit (zgodny z max_ack_pending)
        self.cpu_percent_history: list[float] = []

    def adjust_concurrency_limit(self) -> int:
        """Dynamicznie dostosuj limit współbieżności na podstawie obciążenia (Rozwiązanie 29).
        Jeśli CPU > 80% lub RAM > 80%, zmniejsz limit.
        """
        cpu_percent = self.process.cpu_percent(interval=0.1)
        self.cpu_percent_history.append(cpu_percent)
        if len(self.cpu_percent_history) > 10:
            self.cpu_percent_history.pop(0)

        avg_cpu = sum(self.cpu_percent_history) / max(len(self.cpu_percent_history), 1)
        current_ram = self.process.memory_info().rss
        ram_usage_pct = (current_ram / self.ram_limit) * 100

        if avg_cpu > 80 or ram_usage_pct > 80:
            self.max_concurrent = max(1, self.max_concurrent - 1)
        elif avg_cpu < 50 and ram_usage_pct < 50:
            self.max_concurrent = min(5, self.max_concurrent + 1)

        return self.max_concurrent

    def get_status(self) -> dict:
        """Zwróć aktualny status workera (Rozwiązanie 29)."""
        current_mem = self.process.memory_info().rss
        uptime = pendulum.now("UTC") - self.start_time

        return {
            "uptime_seconds": int(uptime.total_seconds()),
            "ram_mb": round(current_mem / 1024**2, 1),
            "ram_limit_gb": round(self.ram_limit / (1024**3), 1),
            "ram_usage_pct": round((current_mem / self.ram_limit) * 100, 1),
            "active_tasks": self.active_tasks,
            "max_concurrent": self.max_concurrent,
            "cpu_percent": round(self.process.cpu_percent(interval=0.0), 1),
        }

    def check_resources(self) -> bool:
        current_mem = self.process.memory_info().rss
        if current_mem <= self.ram_limit:
            self.adjust_concurrency_limit()
            return False

        logger.warning("RAM alert: %.1f MB. Triggering cleanup...", current_mem / 1024**2)
        gc.collect()
        return True

    async def heartbeat(self) -> None:
        while True:
            uptime = pendulum.now("UTC") - self.start_time
            ram_mb = self.process.memory_info().rss / 1024**2
            self.adjust_concurrency_limit()
            logger.debug(
                "Heartbeat uptime=%s RAM=%.1fMB max_concurrent=%d tasks=%d",
                uptime,
                ram_mb,
                self.max_concurrent,
                self.active_tasks,
            )
            await anyio.sleep(60)


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def on_worker_startup(state) -> None:
    logger.info(">>> Worker startup: loading config and OCR resources...")
    state.config = AppConfig()
    state.guard = WorkerGuard(ram_limit_gb=8.0)
    state.vision_agent = VisionAgent()
    state.heartbeat_task = anyio.ensure_backend().create_task(state.guard.heartbeat())

    # SUPERMOC HISHEL: Warm HTTP cache przy starcie workera
    try:
        await warm_http_cache()
        logger.info("[HTTP-CACHE-WARM] Cache warmed at worker startup")
    except Exception as exc:
        logger.debug("[HTTP-CACHE-WARM] Cache warming skipped (non-fatal): %s", exc)

    # Freeze GC po załadowaniu modeli — Python 3.13t (free-threaded)
    # Zamraża obiekty nienaruszalne, redukując overhead GC o ~30%
    gc.freeze()
    logger.debug("[GC] gc.freeze() applied — %d frozen objects", gc.get_freeze_count())

    logger.info(
        ">>> Worker ready. OS=%s, vision_agent=%s",
        platform.system(),
        "ocr-fallback",
    )


# TASK_POST_EXECUTION was renamed/removed in taskiq >=0.12.
# We use TASK_POST_EXECUTE if available, otherwise run guard via existing hooks.
_TASKIQ_TASK_POST_EVENT = getattr(TaskiqEvents, "TASK_POST_EXECUTION", None)

if _TASKIQ_TASK_POST_EVENT is not None:

    @broker.on_event(_TASKIQ_TASK_POST_EVENT)
    async def on_task_post_execution(state, task_result) -> None:
        state.guard.check_resources()
        logger.debug("Task finished: %s", task_result.task_id)


# Also handle post-execute if it exists in newer taskiq versions
_TASKIQ_TASK_POST_EXECUTE = getattr(TaskiqEvents, "TASK_POST_EXECUTE", None)
if _TASKIQ_TASK_POST_EXECUTE is not None and _TASKIQ_TASK_POST_EXECUTE != _TASKIQ_TASK_POST_EVENT:

    @broker.on_event(_TASKIQ_TASK_POST_EXECUTE)
    async def on_task_post_execute(state, task_result) -> None:
        state.guard.check_resources()
        logger.debug("Task finished (post-execute): %s", task_result.task_id)


@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def on_worker_shutdown(state) -> None:
    logger.info(">>> Worker shutdown: releasing resources...")
    if hasattr(state, "heartbeat_task"):
        state.heartbeat_task.cancel()
    gc.collect()


def _signal_handler(sig, _frame) -> None:
    logger.info("Received shutdown signal (%s).", sig)
    shutdown_flag.set()


async def main() -> None:
    if platform.system() != "Windows":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _signal_handler)

    try:
        logger.info("Connecting to Taskiq broker...")
        await broker.startup()
        logger.info("Worker is active and listening for tasks.")
        await shutdown_flag.wait()
    except Exception as exc:
        logger.error("Critical worker error: %s", exc)
    finally:
        await broker.shutdown()
        logger.info("Worker stopped.")


if __name__ == "__main__":
    anyio.run(main)
