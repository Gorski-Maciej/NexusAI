"""Worker status monitoring endpoint (Rozwiązanie 29)."""
from __future__ import annotations

from datetime import UTC
from typing import Any

from litestar import Controller, get


class WorkerStatusController(Controller):
    """Worker status monitoring — current load, concurrency, and resource usage.

    Provides:
      - GET /api/v1/system/workers/status: aktualne obciążenie workera
    """

    path = "/api/v1/system/workers"

    @get("/status")
    async def get_worker_status(self) -> dict[str, Any]:
        """Zwraca aktualny status workera: obciążenie, liczbę zadań, limit współbieżności.

        Rozwiązanie 29: Monitorowanie stanu workera.
        """
        try:
            import os
            from datetime import datetime

            import psutil

            process = psutil.Process(os.getpid())
            current_mem = process.memory_info().rss
            uptime_seconds = int((datetime.now(UTC) - datetime.fromtimestamp(
                process.create_time(), tz=UTC
            )).total_seconds())
            cpu_percent = process.cpu_percent(interval=0.1)

            return {
                "status": "running",
                "uptime_seconds": uptime_seconds,
                "ram_mb": round(current_mem / 1024**2, 1),
                "cpu_percent": round(cpu_percent, 1),
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
