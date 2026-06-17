"""Worker status monitoring endpoint (Rozwiązanie 29)."""

from __future__ import annotations

from typing import Any

import pendulum
from litestar import Controller, get

from nexus_ai.api.dto import WorkerStatusDTO, TAG_SYSTEM


class WorkerStatusController(Controller):
    """Worker status monitoring — current load, concurrency, and resource usage.

    Provides:
      - GET /api/v1/system/workers/status: aktualne obciążenie workera
    """

    path = "/system/workers"
    tags = [TAG_SYSTEM]

    @get(
        "/status",
        return_dto=WorkerStatusDTO,
        summary="Get worker status",
        description="Returns current worker load, task count, concurrency limit, and resource usage (Rozwiązanie 29).",
        operation_id="getWorkerStatus",
    )
    async def get_worker_status(self) -> dict[str, Any]:
        """Zwraca aktualny status workera: obciążenie, liczbę zadań, limit współbieżności.

        SUPERMOCE psutil:
          - Process.oneshot() — batch syscalls (zamiast 3 osobnych)
          - memory_full_info() — USS/PSS (rzeczywista pamięć)
          - cpu_percent(interval=0.1) — CPU z krótkim pomiarem
          - num_threads() — liczba wątków
          - num_fds() — liczba deskryptorów
          - status() — stan procesu
          - memory_percent() — % całkowitego RAM

        Rozwiązanie 29: Monitorowanie stanu workera.
        """
        try:
            import os
            import psutil

            process = psutil.Process(os.getpid())
            uss_mb = None
            pss_mb = None
            vms_mb = None
            num_threads = None
            num_fds = None
            mem_percent = None
            proc_status = "running"
            proc_name = "unknown"

            # SUPERMOC: oneshot() — wszystkie atrybuty w 1 syscallu
            try:
                with process.oneshot():
                    mem_info = process.memory_info()
                    try:
                        mem_full = process.memory_full_info()
                        uss_mb = mem_full.uss / (1024**2) if mem_full.uss else None
                        pss_mb = mem_full.pss / (1024**2) if mem_full.pss else None
                    except (psutil.AccessDenied, Exception):
                        pass
                    rss_mb = mem_info.rss / (1024**2)
                    vms_mb = mem_info.vms / (1024**2)
                    cpu_pct = process.cpu_percent(interval=0.1)
                    ctime = process.create_time()
                    num_threads = process.num_threads()
                    try:
                        num_fds = process.num_fds()
                    except (psutil.AccessDenied, Exception):
                        num_fds = None
                    mem_percent = process.memory_percent()
                    proc_status = process.status()
                    proc_name = process.name()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                return {"status": "process_gone", "error": "Process no longer exists"}

            uptime_seconds = int(
                (pendulum.now("UTC") - pendulum.from_timestamp(ctime, tz="UTC")).total_seconds()
            )

            return {
                "status": proc_status,
                "name": proc_name,
                "uptime_seconds": uptime_seconds,
                "ram_mb": round(rss_mb, 1),
                "uss_mb": round(uss_mb, 1) if uss_mb is not None else None,
                "pss_mb": round(pss_mb, 1) if pss_mb is not None else None,
                "vms_mb": round(vms_mb, 1) if vms_mb is not None else None,
                "ram_percent": round(mem_percent, 2) if mem_percent is not None else None,
                "cpu_percent": round(cpu_pct, 1),
                "num_threads": num_threads,
                "num_fds": num_fds,
                "active_tasks": 0,  # Wypełniane przez WorkerGuard w środowisku workers
                "max_concurrent": 5,  # Wartość domyślna, zgodna z max_ack_pending=5
                "pid": os.getpid(),
                "python_version": __import__("sys").version,
            }
        except Exception as exc:
            return {
                "status": "error",
                "error": str(exc),
            }
