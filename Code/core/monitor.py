# core/monitor.py
import os

import psutil

from core.logger import logger


class SystemMonitor:
    """Monitoruje zużycie zasobów przez Nexus AI."""

    @staticmethod
    def get_memory_usage() -> float:
        """Zwraca zużycie RAM przez bieżący proces w MB."""
        process = psutil.Process(os.get_pid())
        return process.memory_info().rss / (1024 * 1024)

    @staticmethod
    def check_health(memory_threshold_mb: int = 4000) -> bool:
        """Sprawdza, czy system nie przekracza bezpiecznych limitów."""
        usage = SystemMonitor.get_memory_usage()
        if usage > memory_threshold_mb:
            logger.error(f"Krytyczne zużycie pamięci: {usage:.2f}MB / {memory_threshold_mb}MB")
            return False
        return True
