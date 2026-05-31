# core/hardware.py
import subprocess
import torch
import psutil
import platform
from core.logger import logger

class HardwareProbe:
    """Sprawdza zasoby sprzętowe w celu optymalizacji modeli AI."""

    @staticmethod
    def get_gpu_config() -> dict:
        """Zwraca optymalne parametry n_gpu_layers dla modelu Llama."""
        try:
            # Próba detekcji CUDA przez nvidia-smi
            res = subprocess.check_output(["nvidia-smi", "-L"]).decode()
            if "GPU" in res:
                logger.info("Wykryto akcelerację NVIDIA CUDA. Aktywacja warstw GPU.")
                return {
                    "n_gpu_layers": -1, # Wszystkie warstwy na GPU
                    "use_mmap": True,
                    "device": "cuda"
                }
        except Exception:
            pass

        logger.warning("Nie wykryto GPU. Przełączanie w tryb CPU (Wolniejszy).")
        return {
            "n_gpu_layers": 0,
            "use_mmap": True,
            "device": "cpu"
        }

    @staticmethod
    def get_strategy() -> dict:
        """Decyduje, czy użyć natywnego PyTorcha (GPU) czy GGUF (CPU)."""
        has_gpu = torch.cuda.is_available()
        total_ram = psutil.virtual_memory().total / (1024**3) # w GB
        cpu_info = platform.processor()

        if has_gpu and torch.cuda.get_device_properties(0).total_memory > 4 * 1024**3:
            return {
                "mode": "GPU",
                "device": "cuda",
                "model_format": "native", # PyTorch / Surya
                "n_gpu_layers": 35 # Wszystkie warstwy na GPU
            }

        logger.warning("Nie wykryto GPU lub za mało VRAM. Przejście w tryb CPU (GGUF).")
        return {
            "mode": "CPU",
            "device": "cpu",
            "model_format": "gguf", # llama-cpp-python
            "n_gpu_layers": 0
        }

    @staticmethod
    def hot_swap_model(current_model: str, gpu_temp_c: float | None = None, free_vram_gb: float | None = None) -> str:
        """Dynamically downgrade model when hardware pressure is detected."""
        temp = gpu_temp_c if gpu_temp_c is not None else 0.0
        vram = free_vram_gb if free_vram_gb is not None else 999.0

        if temp >= 84.0 or vram < 2.5:
            logger.warning(
                "Hot-swap activated: model=%s temp=%.1fC free_vram=%.2fGB -> Phi-3-mini",
                current_model,
                temp,
                vram,
            )
            return "Phi-3-mini"

        return current_model
