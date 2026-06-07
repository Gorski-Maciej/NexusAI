# core/hardware.py
"""Hardware probing for AI model optimization.

Zgodnie z aa3fvcx.txt: PyTorch → GGUF (llama-cpp-python).
GPU detekcja przez nvidia-smi zamiast torch.cuda.
"""

from __future__ import annotations

import subprocess

import psutil

from nexus_ai.core.logger import logger


def _cuda_available() -> bool:
    """Check CUDA GPU availability via nvidia-smi."""
    try:
        res = subprocess.check_output(["nvidia-smi", "-L"], timeout=10).decode()
        return "GPU" in res
    except Exception:
        return False


class HardwareProbe:
    """Sprawdza zasoby sprzętowe w celu optymalizacji modeli AI."""

    @staticmethod
    def get_gpu_config() -> dict:
        """Zwraca optymalne parametry n_gpu_layers dla modelu Llama.

        Używa nvidia-smi zamiast torch.cuda.
        """
        if _cuda_available():
            logger.info("Wykryto akcelerację NVIDIA CUDA. Aktywacja warstw GPU.")
            return {
                "n_gpu_layers": -1,  # Wszystkie warstwy na GPU
                "use_mmap": True,
                "device": "cuda",
            }

        logger.warning("Nie wykryto GPU. Przełączanie w tryb CPU (Wolniejszy).")
        return {
            "n_gpu_layers": 0,
            "use_mmap": True,
            "device": "cpu",
        }

    @staticmethod
    def get_strategy() -> dict:
        """Decyduje o strategii: GPU dla modeli GGUF lub CPU.

        W nowej architekturze wszystkie modele to GGUF (llama-cpp-python),
        więc GPU jest opcjonalne — zależy od wersji llama-cpp-python z CUDA.
        """
        has_gpu = _cuda_available()
        _total_ram_gb = psutil.virtual_memory().total / (1024**3)

        if has_gpu:
            return {
                "mode": "GPU",
                "device": "cuda",
                "model_format": "gguf",
                "n_gpu_layers": -1,
            }

        logger.warning("Nie wykryto GPU. Przejście w tryb CPU.")
        return {
            "mode": "CPU",
            "device": "cpu",
            "model_format": "gguf",
            "n_gpu_layers": 0,
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
