# core/memory_manager.py
"""Memory management for AI models.

Zgodnie z aa3fvcx.txt: PyTorch → GGUF (llama-cpp-python).
MemoryManager obsługuje teraz modele GGUF zamiast PyTorch.
cachetools.TTLCache zastąpiony prostym dict + time.
"""

from __future__ import annotations

import gc
import time
from typing import Any


class MemoryManager:
    """Zarządza zwalnianiem pamięci po modelach GGUF.

    Modele GGUF (llama-cpp-python) nie wymagają specjalnej hibernacji
    do VRAM — działają w RAM. Wystarczy usunąć referencje i wywołać GC.
    """

    @staticmethod
    def hibernate_models(processors: list) -> None:
        """Zwalnia referencje do modeli — GC zwolni pamięć.

        Args:
            processors: Lista obiektów z atrybutem ``model`` (do zwolnienia).
        """
        for proc in processors:
            if hasattr(proc, "model") and proc.model is not None:
                proc.model = None

        gc.collect()

    @staticmethod
    def wakeup_models(processors: list) -> None:
        """Modele GGUF nie wymagają przywracania do GPU — nic nie robi.

        Args:
            processors: Lista obiektów (ignorowana).
        """
        pass


class TimedModelCache:
    """Cache modeli z TTL i automatycznym zwalnianiem zasobów.

    Używa prostego dict + timestamp zamiast cachetools.TTLCache.
    """

    def __init__(self, ttl_seconds: int = 600, maxsize: int = 64) -> None:
        self._cache: dict[str, object] = {}
        self._timestamps: dict[str, float] = {}
        self._ttl = ttl_seconds
        self._maxsize = maxsize

    async def get(self, key: str, loader) -> Any:
        now = time.monotonic()
        try:
            model = self._cache[key]
            ts = self._timestamps.get(key, 0.0)
            if now - ts < self._ttl:
                self._timestamps[key] = now
                return model
            # Expired — remove and reload
            del self._cache[key]
            del self._timestamps[key]
        except KeyError:
            pass

        model = await loader()
        self._cache[key] = model
        self._timestamps[key] = now

        # Evict oldest if over maxsize
        if len(self._cache) > self._maxsize:
            oldest = min(self._timestamps, key=lambda k: self._timestamps[k])
            del self._cache[oldest]
            del self._timestamps[oldest]

        return model

    def evict_expired(self, now: float | None = None) -> None:
        """Force cleanup of expired entries."""
        if now is None:
            now = time.monotonic()
        expired = [k for k, ts in self._timestamps.items() if now - ts >= self._ttl]
        for k in expired:
            self._cache.pop(k, None)
            self._timestamps.pop(k, None)

    def release(self, key: str) -> None:
        """Remove a single key from cache."""
        self._cache.pop(key, None)
        self._timestamps.pop(key, None)
        del key  # Help GC
        gc.collect()
