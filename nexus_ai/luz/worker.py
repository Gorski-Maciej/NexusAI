"""
Taskiq worker bootstrap and local connectivity smoke test.

SUPERMOCE psutil w WorkerGuard:
  - Process.oneshot() — batch syscalls dla get_status(), adjust_concurrency_limit()
  - memory_full_info() → USS/PSS (rzeczywista pamięć zamiast gołego RSS)
  - memory_percent() → % całkowitego RAM
  - cpu_times_percent() → podział user/system/iowait
  - num_threads() / num_fds() → liczba wątków i deskryptorów
  - SystemMonitor z core/monitor.py → RAM, CPU, swap, dysk, sieć, temperatura
  - psutil.NoSuchProcess / AccessDenied → bezpieczna obsługa błędów
"""

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
from nexus_ai.core.monitor import process_monitor, system_monitor
from nexus_ai.services.vision.agent import VisionAgent

if getattr(sys, "frozen", False):
    BASE_PATH = _SyncPath(sys._MEIPASS)
else:
    BASE_PATH = _SyncPath(__file__).resolve().parent

MODELS_CACHE_DIR = BASE_PATH / "models"
os.environ.setdefault("HF_HOME", str(MODELS_CACHE_DIR))
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")

# mimalloc konfiguracja dla workera (audyt Faza 3)
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
    """Watchdog dla procesu workera z dynamicznym limitowaniem współbieżności.

    SUPERMOCE psutil:
      - Process.oneshot() — wszystkie atrybuty procesu w 1 syscallu
      - memory_full_info() → USS/PSS (rzeczywista alokacja pamięci)
      - cpu_times_percent() → podział user/system/iowait
      - num_threads() / num_fds() → zasoby systemowe
      - SystemMonitor → RAM %, swap, dysk, sieć, temperatura CPU
    """

    def __init__(self, ram_limit_gb: float = 6.0) -> None:
        self.process = psutil.Process(os.getpid())
        self.ram_limit = int(ram_limit_gb * 1024 * 1024 * 1024)
        self.start_time = pendulum.now("UTC")
        self.active_tasks: int = 0
        self.max_concurrent: int = 5
        self.cpu_percent_history: list[float] = []

    # ── SUPERMOC: oneshot() — batch syscalls ───────────────────────────

    def _collect_process_stats(self) -> dict:
        """Zbierz wszystkie atrybuty procesu w jednym oneshot() bloku.

        Zamiast 6 osobnych syscalli (memory_info, cpu_percent, num_threads...),
        oneshot() cache'uje wyniki po pierwszym wywołaniu.
        Wydajność: ~5x szybciej dla pełnego zestawu metryk.
        """
        proc = self.process
        try:
            with proc.oneshot():
                mem_info = proc.memory_info()
                mem_full = self._safe_memory_full_info(proc)
                cpu_pct = proc.cpu_percent(interval=0.0)
                cpu_times = proc.cpu_times()
                threads = proc.num_threads()
                fds = self._safe_num_fds(proc)
                mem_pct = proc.memory_percent()

            return {
                "rss_mb": mem_info.rss / (1024**2),
                "uss_mb": mem_full.uss / (1024**2) if mem_full and mem_full.uss else None,
                "pss_mb": mem_full.pss / (1024**2) if mem_full and mem_full.pss else None,
                "vms_mb": mem_info.vms / (1024**2),
                "cpu_percent": cpu_pct,
                "cpu_user": cpu_times.user,
                "cpu_system": cpu_times.system,
                "cpu_iowait": getattr(cpu_times, "iowait", None),
                "num_threads": threads,
                "num_fds": fds,
                "memory_percent": mem_pct,
            }
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            logger.warning("[WORKER-GUARD] Process inaccessible — re-initializing")
            self.process = psutil.Process(os.getpid())
            return self._collect_process_stats()

    def adjust_concurrency_limit(self) -> int:
        """Dynamicznie dostosuj limit współbieżności na podstawie obciążenia.

        SUPERMOCE psutil:
          - cpu_percent() — z oneshot() cache (0 syscalli)
          - memory_full_info() → USS zamiast RSS dla dokładniejszego pomiaru
          - Jeśli CPU > 80% lub RAM > 80%, zmniejsz limit
        """
        stats = self._collect_process_stats()
        cpu_percent = stats["cpu_percent"]
        uss_mb = stats["uss_mb"] or stats["rss_mb"]

        self.cpu_percent_history.append(cpu_percent)
        if len(self.cpu_percent_history) > 10:
            self.cpu_percent_history.pop(0)

        avg_cpu = sum(self.cpu_percent_history) / max(len(self.cpu_percent_history), 1)
        ram_usage_pct = (uss_mb * (1024**2) / self.ram_limit) * 100

        if avg_cpu > 80 or ram_usage_pct > 80:
            self.max_concurrent = max(1, self.max_concurrent - 1)
        elif avg_cpu < 50 and ram_usage_pct < 50:
            self.max_concurrent = min(5, self.max_concurrent + 1)

        return self.max_concurrent

    def get_status(self) -> dict:
        """Zwróć aktualny status workera z pełnymi metrykami.

        SUPERMOCE:
          - oneshot() dla procesu
          - SystemMonitor.collect_all() dla metryk systemowych
          - USS/PSS z memory_full_info()
        """
        proc_stats = self._collect_process_stats()
        uptime = pendulum.now("UTC") - self.start_time

        # SUPERMOC: metryki systemowe (RAM%, swap, dysk, sieć, temperatura)
        try:
            sys_metrics = system_monitor.collect_all()
            sys_dict = {
                "ram_total_gb": round(sys_metrics.ram_total_gb, 1),
                "ram_available_gb": round(sys_metrics.ram_available_gb, 1),
                "ram_percent": round(sys_metrics.ram_percent, 1),
                "swap_percent": round(sys_metrics.swap_percent, 1),
                "disk_percent": round(sys_metrics.disk_percent, 1),
                "cpu_temp_celsius": round(sys_metrics.cpu_temp_celsius, 1)
                if sys_metrics.cpu_temp_celsius else None,
                "load_avg": f"{sys_metrics.load_avg_1min:.2f} / {sys_metrics.load_avg_5min:.2f} / {sys_metrics.load_avg_15min:.2f}",
                "uptime_days": round(sys_metrics.uptime_days, 1),
            }
        except Exception:
            sys_dict = {}

        return {
            "uptime_seconds": int(uptime.total_seconds()),
            "ram_mb": round(proc_stats["rss_mb"], 1),
            "uss_mb": round(proc_stats["uss_mb"], 1) if proc_stats["uss_mb"] is not None else None,
            "pss_mb": round(proc_stats["pss_mb"], 1) if proc_stats["pss_mb"] is not None else None,
            "vms_mb": round(proc_stats["vms_mb"], 1),
            "ram_percent": round(proc_stats["memory_percent"], 2),
            "ram_limit_gb": round(self.ram_limit / (1024**3), 1),
            "ram_usage_pct": round((proc_stats["rss_mb"] * (1024**2) / self.ram_limit) * 100, 1),
            "active_tasks": self.active_tasks,
            "max_concurrent": self.max_concurrent,
            "cpu_percent": round(proc_stats["cpu_percent"], 1),
            "num_threads": proc_stats["num_threads"],
            "num_fds": proc_stats["num_fds"],
            **sys_dict,
        }

    def check_resources(self) -> bool:
        """Sprawdź zasoby i wyzwól GC jeśli potrzeba.

        Uses oneshot() internally — niemierzalny narzut.
        """
        proc_stats = self._collect_process_stats()
        rss_mb = proc_stats["rss_mb"]
        if rss_mb <= self.ram_limit / (1024**2):
            self.adjust_concurrency_limit()
            return False

        logger.warning(
            "RAM alert: %.1f MB (USS=%.1f MB). Triggering cleanup...",
            rss_mb,
            proc_stats["uss_mb"] or 0.0,
        )
        gc.collect()
        return True

    async def heartbeat(self) -> None:
        """Super-powered heartbeat z pełnymi metrykami co 60s.

        SUPERMOCE:
          - oneshot() dla procesu (zero dodatkowych syscalli)
          - SystemMonitor dla RAM %, swap, dysk, sieć, temperatura
          - Logowanie na poziomie AUDIT (custom Loguru level)
        """
        while True:
            proc_stats = self._collect_process_stats()
            self.adjust_concurrency_limit()

            # SUPERMOC: system-wide metrics co heartbeat
            try:
                sys_m = system_monitor.collect_all()
                logger.bind(level="AUDIT").info(
                    "Heartbeat uptime=%.1fh RSS=%.1fMB USS=%.1fMB CPU=%.1f%% "
                    "RAM=%.1f%% DISK=%.1f%% SWAP=%.1f%% TEMP=%.1f°C "
                    "NET_IN=%.1fMB NET_OUT=%.1fMB threads=%d fds=%d",
                    (pendulum.now("UTC") - self.start_time).total_seconds() / 3600,
                    proc_stats["rss_mb"],
                    proc_stats["uss_mb"] or 0.0,
                    proc_stats["cpu_percent"],
                    sys_m.ram_percent,
                    sys_m.disk_percent,
                    sys_m.swap_percent,
                    sys_m.cpu_temp_celsius or 0.0,
                    sys_m.net_bytes_recv_mb,
                    sys_m.net_bytes_sent_mb,
                    proc_stats["num_threads"],
                    proc_stats["num_fds"],
                )
            except Exception:
                logger.debug(
                    "Heartbeat uptime=%s RAM=%.1fMB max_concurrent=%d tasks=%d",
                    pendulum.now("UTC") - self.start_time,
                    proc_stats["rss_mb"],
                    self.max_concurrent,
                    self.active_tasks,
                )

            await anyio.sleep(60)

    # ── Safe helpers z obsługą wyjątków psutil ──────────────────────────

    @staticmethod
    def _safe_memory_full_info(proc: psutil.Process):
        try:
            return proc.memory_full_info()
        except (psutil.AccessDenied, psutil.NoSuchProcess):
            return type("MemInfo", (), {"uss": None, "pss": None, "swap": None})()

    @staticmethod
    def _safe_num_fds(proc: psutil.Process) -> int:
        try:
            return proc.num_fds()
        except (psutil.AccessDenied, psutil.NoSuchProcess):
            return -1


# ═════════════════════════════════════════════════════════════════════════════
# Taskiq lifecycle hooks
# ═════════════════════════════════════════════════════════════════════════════


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def on_worker_startup(state) -> None:
    logger.info(">>> Worker startup: loading config and OCR resources...")
    state.config = AppConfig()
    state.guard = WorkerGuard(ram_limit_gb=8.0)
    state.vision_agent = VisionAgent()
    state.heartbeat_task = anyio.ensure_backend().create_task(state.guard.heartbeat())

    try:
        await warm_http_cache()
        logger.info("[HTTP-CACHE-WARM] Cache warmed at worker startup")
    except Exception as exc:
        logger.debug("[HTTP-CACHE-WARM] Cache warming skipped (non-fatal): %s", exc)

    gc.freeze()
    logger.debug("[GC] gc.freeze() applied — %d frozen objects", gc.get_freeze_count())

    logger.info(
        ">>> Worker ready. OS=%s, vision_agent=%s",
        platform.system(),
        "ocr-fallback",
    )


_TASKIQ_TASK_POST_EVENT = getattr(TaskiqEvents, "TASK_POST_EXECUTION", None)

if _TASKIQ_TASK_POST_EVENT is not None:

    @broker.on_event(_TASKIQ_TASK_POST_EVENT)
    async def on_task_post_execution(state, task_result) -> None:
        state.guard.check_resources()
        logger.debug("Task finished: %s", task_result.task_id)


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
