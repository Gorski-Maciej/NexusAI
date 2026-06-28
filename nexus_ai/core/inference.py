"""
InferenceService + ModelManager — generic GGUF inference with TTL-based auto-unload.

Zgodnie z aa3fvcx.txt:
- Używa llama-cpp-python (jedyna technologia AI/ML wymieniona w stacku)
- Nie definiuje konkretnych modeli — ładuje dowolny GGUF podany w konfiguracji
- ModelManager z TTL auto-unload (TOP5 OPTYMALIZACJA #2)
- Lazy loading: model ładowany dopiero przy pierwszym generate()/chat()
- Auto-unload po 5 minutach bezczynności

aa3fvcx.txt (Punkt 10, wzmianka o embedddingach):
  llama-cpp-python jest już w projekcie jako zależność
"""

from __future__ import annotations

import gc
import time
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
        ttl: Czas życia modelu w sekundach (0 = bez auto-unload).
    """

    def __init__(
        self,
        model_path: str | Path,
        n_ctx: int = 4096,
        n_threads: int = 4,
        n_gpu_layers: int = 0,
        verbose: bool = False,
        ttl: int = 300,  # TOP5: domyślny TTL 5 minut
    ) -> None:
        self._model_path = Path(model_path)
        self._n_ctx = n_ctx
        self._n_threads = n_threads
        self._n_gpu_layers = n_gpu_layers
        self._verbose = verbose
        self._model: Any = None
        self._loaded = False
        self._ttl = ttl
        self._loaded_at: float = 0.0

    def load(self) -> None:
        """Load the GGUF model into memory."""
        if self._loaded:
            # Odśwież timer przy każdym dostępie
            self._loaded_at = time.time()
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
            self._loaded_at = time.time()
            logger.info(
                "[InferenceService] Loaded model: %s (ctx=%d, threads=%d, gpu_layers=%d, ttl=%ds)",
                self._model_path.name,
                self._n_ctx,
                self._n_threads,
                self._n_gpu_layers,
                self._ttl,
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
            self._loaded_at = 0.0
            gc.collect()
            logger.info("[InferenceService] Unloaded model: %s", self._model_path.name)

    def check_ttl(self) -> None:
        """SUPERMOC: Auto-unload jeśli TTL wygasł (TOP5 OPTYMALIZACJA #2).

        Sprawdza czy minął czas TTL od ostatniego użycia modelu.
        Jeśli tak — zwalnia pamięć. Oszczędność: 0.8-3.0 GB RAM.
        """
        if self._loaded and self._ttl > 0:
            elapsed = time.time() - self._loaded_at
            if elapsed > self._ttl:
                logger.info(
                    "[InferenceService] TTL expired for %s (%.1fs > %ds) — unloading",
                    self._model_path.name,
                    elapsed,
                    self._ttl,
                )
                self.unload()

    def generate(
        self,
        prompt: str,
        max_tokens: int = 512,
        temperature: float = 0.1,
        stop: list[str] | None = None,
    ) -> str:
        """Generate text from prompt with TTL check.

        Args:
            prompt: Input prompt.
            max_tokens: Maximum tokens to generate.
            temperature: Sampling temperature.
            stop: Stop sequences.

        Returns:
            Generated text string.
        """
        # Sprawdź czy TTL nie wygasł przed załadowaniem
        self.check_ttl()
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
            self._loaded_at = time.time()
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
        """Chat completion using the model with TTL check.

        Args:
            messages: List of message dicts with 'role' and 'content'.
            max_tokens: Maximum tokens to generate.
            temperature: Sampling temperature.

        Returns:
            Generated response string.
        """
        self.check_ttl()
        self.load()
        if self._model is None:
            return ""

        try:
            response = self._model.create_chat_completion(
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
            )
            self._loaded_at = time.time()
            return response["choices"][0]["message"]["content"]
        except Exception as exc:
            logger.error("[InferenceService] Chat failed: %s", exc)
            return ""

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    @property
    def ttl_remaining(self) -> float:
        """Pozostały czas TTL w sekundach (0 jeśli niezaładowany lub TTL=0)."""
        if not self._loaded or self._ttl == 0:
            return 0.0
        return max(0.0, self._ttl - (time.time() - self._loaded_at))

    def __enter__(self) -> InferenceService:
        return self

    def __exit__(self, *args: Any) -> None:
        self.unload()


class ModelManager:
    """SUPERMOC: Manager modeli AI z TTL auto-unload (TOP5 OPTYMALIZACJA #2).

    Oszczędność RAM: 0.8-3.0 GB gdy modele nie są używane.
    Automatycznie zwalnia modele po okresie bezczynności (domyślnie 5 min).
    Można też ręcznie zwolnić modele po zakończeniu zadania.

    Usage:
        manager = ModelManager()
        result = await manager.infer("path/to/model.gguf", "Hello")
        # Po 5 minutach bezczynności model zostanie automatycznie zwolniony
    """

    def __init__(self, default_ttl: int = 300) -> None:
        self._models: dict[str, InferenceService] = {}
        self._default_ttl = default_ttl

    def get_or_create(
        self,
        model_path: str | Path,
        *,
        n_ctx: int = 4096,
        n_threads: int = 4,
        n_gpu_layers: int = 0,
        ttl: int | None = None,
    ) -> InferenceService:
        """Pobierz istniejący model lub utwórz nowy.

        Args:
            model_path: Ścieżka do pliku GGUF.
            n_ctx: Rozmiar kontekstu.
            n_threads: Liczba wątków CPU.
            n_gpu_layers: Liczba warstw na GPU.
            ttl: TTL w sekundach (None = domyślny 300).

        Returns:
            InferenceService dla danego modelu.
        """
        key = str(model_path)
        if key in self._models:
            svc = self._models[key]
            # Sprawdź czy TTL nie wygasł
            svc.check_ttl()
            # Jeśli model został zwolniony przez TTL, zostanie załadowany od nowa
            return svc

        svc = InferenceService(
            model_path=model_path,
            n_ctx=n_ctx,
            n_threads=n_threads,
            n_gpu_layers=n_gpu_layers,
            ttl=ttl if ttl is not None else self._default_ttl,
        )
        self._models[key] = svc
        return svc

    async def infer(
        self,
        model_path: str | Path,
        prompt: str,
        *,
        max_tokens: int = 512,
        temperature: float = 0.1,
        n_ctx: int = 4096,
        n_threads: int = 4,
        n_gpu_layers: int = 0,
    ) -> str:
        """SUPERMOC: Wykonaj inferencję na modelu z auto-loading.

        Args:
            model_path: Ścieżka do pliku GGUF.
            prompt: Prompt wejściowy.
            max_tokens: Maksymalna liczba tokenów.
            temperature: Temperatura sampling.
            n_ctx: Rozmiar kontekstu.
            n_threads: Liczba wątków CPU.
            n_gpu_layers: Liczba warstw GPU.

        Returns:
            Wygenerowany tekst.
        """
        svc = self.get_or_create(
            model_path,
            n_ctx=n_ctx,
            n_threads=n_threads,
            n_gpu_layers=n_gpu_layers,
        )
        return svc.generate(
            prompt,
            max_tokens=max_tokens,
            temperature=temperature,
        )

    async def chat(
        self,
        model_path: str | Path,
        messages: list[dict[str, str]],
        *,
        max_tokens: int = 512,
        temperature: float = 0.1,
        n_ctx: int = 4096,
        n_threads: int = 4,
        n_gpu_layers: int = 0,
    ) -> str:
        """SUPERMOC: Chat completion z auto-loading."""
        svc = self.get_or_create(
            model_path,
            n_ctx=n_ctx,
            n_threads=n_threads,
            n_gpu_layers=n_gpu_layers,
        )
        return svc.chat(
            messages,
            max_tokens=max_tokens,
            temperature=temperature,
        )

    def unload_all(self) -> None:
        """SUPERMOC: Zwolnij WSZYSTKIE modele.

        Użyj po zakończeniu batcha OCR/AI.
        """
        for key, svc in list(self._models.items()):
            svc.unload()
        self._models.clear()
        logger.info("[ModelManager] All models unloaded (%d total)", len(self._models))

    def unload(self, model_path: str | Path) -> bool:
        """Zwolnij konkretny model."""
        key = str(model_path)
        if key in self._models:
            self._models[key].unload()
            del self._models[key]
            return True
        return False

    @property
    def loaded_models(self) -> list[str]:
        """Lista załadowanych modeli."""
        return [k for k, v in self._models.items() if v.is_loaded]

    def cleanup_expired(self) -> int:
        """SUPERMOC: Zwolnij wszystkie modele z wygasłym TTL.

        Returns:
            Liczba zwolnionych modeli.
        """
        count = 0
        for key, svc in list(self._models.items()):
            if svc.is_loaded and svc.ttl_remaining == 0:
                svc.unload()
                count += 1
        return count


# Globalny singleton ModelManager dla całej aplikacji
# Dzięki temu modele są współdzielone między komponentami
_model_manager: ModelManager | None = None


def get_model_manager(default_ttl: int = 300) -> ModelManager:
    """Zwraca globalny singleton ModelManager."""
    global _model_manager
    if _model_manager is None:
        _model_manager = ModelManager(default_ttl=default_ttl)
    return _model_manager


def cleanup_models() -> int:
    """SUPERMOC: Zwolnij wszystkie modele z wygasłym TTL.

    Wywołuj okresowo (np. co minutę) z background taska.
    """
    global _model_manager
    if _model_manager is None:
        return 0
    return _model_manager.cleanup_expired()
