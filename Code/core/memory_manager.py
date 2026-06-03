# core/memory_manager.py
import torch
import gc
import time
from core.logger import logger

class MemoryManager:
    """Zarządza zrzucaniem modeli z VRAM do RAM."""

    @staticmethod
    def hibernate_models(processors: list):
        """Przenosi modele na CPU i czyści VRAM."""
        logger.info("Aplikacja zminimalizowana - hibernacja modeli AI...")
        for proc in processors:
            if hasattr(proc, 'model') and proc.model is not None:
                # Przeniesienie modelu PyTorch na CPU (zwalnia VRAM, zostaje w RAM)
                proc.model.to("cpu")

        # Wymuszenie czyszczenia
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()

    @staticmethod
    def wakeup_models(processors: list):
        """Przywraca modele do GPU dla maksymalnej wydajności."""
        if torch.cuda.is_available():
            logger.info("Aplikacja aktywna - przywracanie modeli do GPU...")
            for proc in processors:
                if hasattr(proc, 'model') and proc.model is not None:
                    proc.model.to("cuda")


from cachetools import TTLCache


class TimedModelCache:
    """Cache modeli z TTL i automatycznym zwalnianiem zasobów.

    Wrapper wokół ``cachetools.TTLCache`` — wewnętrznie używa LRU + TTL.
    Dodaje specjalne czyszczenie dla modeli PyTorch (``model.to("cpu")``).
    """

    def __init__(self, ttl_seconds: int = 600, maxsize: int = 64) -> None:
        self.cache: TTLCache[str, object] = TTLCache(maxsize=maxsize, ttl=ttl_seconds)
        self.last_used: dict[str, float] = {}
        self.ttl = ttl_seconds

    async def get(self, key: str, loader):
        now = time.monotonic()
        try:
            model = self.cache[key]
            self.last_used[key] = now
            return model
        except KeyError:
            pass

        model = await loader()
        self.cache[key] = model
        self.last_used[key] = now
        return model

    def evict_expired(self, now: float | None = None) -> None:
        """Force cleanup of expired entries. TTLCache handles this automatically,
        but calling with explicit now triggers immediate expiration."""
        if now is not None:
            # Trigger TTLCache cleanup by accessing the internal timer
            self.cache.expire(time=now)
        else:
            self.cache.expire()

    def release(self, key: str) -> None:
        try:
            model = self.cache.pop(key, None)
        except KeyError:
            model = None
        self.last_used.pop(key, None)
        if model is None:
            return
        if hasattr(model, "to"):
            try:
                model.to("cpu")
            except Exception:
                pass
        del model
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()
