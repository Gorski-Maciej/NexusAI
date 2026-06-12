"""
InferenceService — generic GGUF inference engine using llama-cpp-python.

Zgodnie z aa3fvcx.txt:
- Używa llama-cpp-python (jedyna technologia AI/ML wymieniona w stacku)
- Nie definiuje konkretnych modeli — ładuje dowolny GGUF podany w konfiguracji
- Lekki, lazy-loading, bez skomplikowanego ModelManager

aa3fvcx.txt (Punkt 10, wzmianka o embedddingach):
  llama-cpp-python jest już w projekcie jako zależność
"""

from __future__ import annotations

import gc
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.inference")


class InferenceService:
    """Generic GGUF inference engine using llama-cpp-python.

    Ładuje dowolny model GGUF. Nie definiuje konkretnych modeli —
    ścieżka do modelu jest parametrem.

    Args:
        model_path: Ścieżka do pliku GGUF.
        n_ctx: Rozmiar kontekstu (domyślnie 4096).
        n_threads: Liczba wątków CPU.
        n_gpu_layers: Liczba warstw na GPU (-1 = wszystkie, 0 = CPU).
        verbose: Czy pokazywać logi llama_cpp.
    """

    def __init__(
        self,
        model_path: str | Path,
        n_ctx: int = 4096,
        n_threads: int = 4,
        n_gpu_layers: int = 0,
        verbose: bool = False,
    ) -> None:
        self._model_path = Path(model_path)
        self._n_ctx = n_ctx
        self._n_threads = n_threads
        self._n_gpu_layers = n_gpu_layers
        self._verbose = verbose
        self._model: Any = None
        self._loaded = False

    def load(self) -> None:
        """Load the GGUF model into memory."""
        if self._loaded:
            return

        if not self._model_path.exists():
            logger.warning(
                "[InferenceService] Model %s not found",
                self._model_path,
            )
            return

        try:
            from llama_cpp import Llama

            self._model = Llama(
                model_path=str(self._model_path),
                n_ctx=self._n_ctx,
                n_threads=self._n_threads,
                n_gpu_layers=self._n_gpu_layers,
                verbose=self._verbose,
            )
            self._loaded = True
            logger.info(
                "[InferenceService] Loaded model: %s (ctx=%d, threads=%d, gpu_layers=%d)",
                self._model_path.name,
                self._n_ctx,
                self._n_threads,
                self._n_gpu_layers,
            )
        except ImportError:
            logger.warning(
                "[InferenceService] llama-cpp-python not installed. "
                "Install with: pip install llama-cpp-python"
            )
        except Exception as exc:
            logger.error("[InferenceService] Failed to load model %s: %s", self._model_path, exc)

    def unload(self) -> None:
        """Unload the model and free memory."""
        if self._model is not None:
            del self._model
            self._model = None
            self._loaded = False
            gc.collect()
            logger.info("[InferenceService] Unloaded model: %s", self._model_path.name)

    def generate(
        self,
        prompt: str,
        max_tokens: int = 512,
        temperature: float = 0.1,
        stop: list[str] | None = None,
    ) -> str:
        """Generate text from prompt.

        Args:
            prompt: Input prompt.
            max_tokens: Maximum tokens to generate.
            temperature: Sampling temperature.
            stop: Stop sequences.

        Returns:
            Generated text string.
        """
        self.load()
        if self._model is None:
            return ""

        try:
            response = self._model(
                prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                stop=stop or [],
                echo=False,
            )
            return response["choices"][0]["text"]
        except Exception as exc:
            logger.error("[InferenceService] Generation failed: %s", exc)
            return ""

    def chat(
        self,
        messages: list[dict[str, str]],
        max_tokens: int = 512,
        temperature: float = 0.1,
    ) -> str:
        """Chat completion using the model.

        Args:
            messages: List of message dicts with 'role' and 'content'.
            max_tokens: Maximum tokens to generate.
            temperature: Sampling temperature.

        Returns:
            Generated response string.
        """
        self.load()
        if self._model is None:
            return ""

        try:
            response = self._model.create_chat_completion(
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
            )
            return response["choices"][0]["message"]["content"]
        except Exception as exc:
            logger.error("[InferenceService] Chat failed: %s", exc)
            return ""

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def __enter__(self) -> InferenceService:
        return self

    def __exit__(self, *args: Any) -> None:
        self.unload()
