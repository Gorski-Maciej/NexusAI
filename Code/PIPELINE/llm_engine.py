# pipeline/llm_engine.py
from typing import Optional
from core.hardware import HardwareProbe
from core.logger import logger

class HybridLLMEngine:
    """Silnik obsługujący modele PyTorch (GPU) oraz GGUF (CPU)."""

    def __init__(self, model_path: str):
        self.strategy = HardwareProbe.get_strategy()
        self.model = None
        self._load_model(model_path)

    def _load_model(self, model_path: str):
        if self.strategy.get("model_format") == "gguf":
            from llama_cpp import Llama

            logger.info(f"Ładowanie modelu GGUF na CPU ({self.strategy.get('threads', 4)} wątków)...")
            self.model = Llama(
                model_path=model_path,
                n_ctx=2048,
                n_threads=self.strategy.get("threads", 4),
                n_gpu_layers=0
            )
        else:
            # Standardowe ładowanie przez Transformers (AutoModelForCausalLM)
            import torch
            from transformers import AutoModelForCausalLM

            logger.info("Ładowanie modelu AutoModelForCausalLM...")
            # self.model = AutoModelForCausalLM.from_pretrained(model_path)
            pass
