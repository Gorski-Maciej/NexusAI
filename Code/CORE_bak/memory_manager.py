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


class TimedModelCache:
    """Cache modeli z TTL i automatycznym zwalnianiem zasobów."""

    def __init__(self, ttl_seconds: int = 600) -> None:
        self.cache: dict[str, object] = {}
        self.last_used: dict[str, float] = {}
        self.ttl = ttl_seconds

    async def get(self, key: str, loader):
        now = time.monotonic()
        if key in self.cache and (now - self.last_used[key]) < self.ttl:
            self.last_used[key] = now
            return self.cache[key]

        self.evict_expired(now=now)
        model = await loader()
        self.cache[key] = model
        self.last_used[key] = now
        return model

    def evict_expired(self, now: float | None = None) -> None:
        now = now or time.monotonic()
        for key in list(self.cache.keys()):
            if now - self.last_used.get(key, now) > self.ttl:
                self.release(key)

    def release(self, key: str) -> None:
        model = self.cache.pop(key, None)
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
