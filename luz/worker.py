"""Taskiq worker bootstrap and local connectivity smoke test."""
from __future__ import annotations

import asyncio
import gc
import logging
import os
import platform
import signal
import sys
from datetime import datetime, timezone
from pathlib import Path

import psutil

try:
    import torch
except Exception:  # pragma: no cover - torch may be optional in some envs
    torch = None

from taskiq import TaskiqEvents

from Code.CORE.broker import broker
from Code.CORE.config import AppConfig
import Code.CORE.tasks  # noqa: F401  # required to register @broker.task handlers
from Roboton_Reflekton.vision_agent import VisionAgent


if getattr(sys, "frozen", False):
    BASE_PATH = Path(sys._MEIPASS)
else:
    BASE_PATH = Path(__file__).resolve().parent

MODELS_CACHE_DIR = BASE_PATH / "models"
os.environ.setdefault("HF_HOME", str(MODELS_CACHE_DIR))
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")
os.environ.setdefault("TORCH_HOME", str(MODELS_CACHE_DIR / "torch"))
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s (PID:%(process)d): %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("nexus.worker")

shutdown_flag = asyncio.Event()


class WorkerGuard:
    """Simple watchdog for worker process health and memory usage."""

    def __init__(self, ram_limit_gb: float = 6.0) -> None:
        self.process = psutil.Process(os.getpid())
        self.ram_limit = int(ram_limit_gb * 1024 * 1024 * 1024)
        self.start_time = datetime.now(timezone.utc)

    def check_resources(self) -> bool:
        current_mem = self.process.memory_info().rss
        if current_mem <= self.ram_limit:
            return False

        logger.warning("RAM alert: %.1f MB. Triggering cleanup...", current_mem / 1024**2)
        if torch is not None and torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()
        return True

    async def heartbeat(self) -> None:
        while True:
            uptime = datetime.now(timezone.utc) - self.start_time
            ram_mb = self.process.memory_info().rss / 1024**2
            logger.debug("Heartbeat uptime=%s RAM=%.1fMB", uptime, ram_mb)
            await asyncio.sleep(60)


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def on_worker_startup(state) -> None:
    logger.info(">>> Worker startup: loading config and OCR resources...")
    state.config = AppConfig()
    state.guard = WorkerGuard(ram_limit_gb=8.0)
    state.vision_agent = VisionAgent()
    state.heartbeat_task = asyncio.create_task(state.guard.heartbeat())

    gpu = bool(torch is not None and torch.cuda.is_available())
    logger.info(
        ">>> Worker ready. OS=%s, device=%s, vision_agent=%s",
        platform.system(),
        "CUDA/GPU" if gpu else "CPU",
        "qwen2.5-vl-2b-4bit" if getattr(state.vision_agent, "_enabled", False) else "ocr-fallback",
    )


@broker.on_event(TaskiqEvents.TASK_POST_EXECUTION)
async def on_task_post_execution(state, task_result) -> None:
    state.guard.check_resources()
    logger.debug("Task finished: %s", task_result.task_id)


@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def on_worker_shutdown(state) -> None:
    logger.info(">>> Worker shutdown: releasing resources...")
    if hasattr(state, "heartbeat_task"):
        state.heartbeat_task.cancel()
    if torch is not None and torch.cuda.is_available():
        torch.cuda.empty_cache()
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
    if platform.system() == "Windows":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
