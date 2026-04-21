# core/memory_manager.py
import torch
import gc
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
