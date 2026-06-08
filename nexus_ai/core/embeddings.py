"""
EmbeddingService — centralized text embedding engine using llama-cpp-python.

Zgodnie z aa3fvcx.txt:
- Zastępuje: sentence-transformers (biblioteka spoza stacku)
- Nowy:     llama-cpp-python z embedding=True (technologia z stacku)
- Integracja z dyscache i msgspec (Punkty 4 i 13)

llama-cpp-python jest już w projekcie jako zależność (używana przez Council of Agents).
Używa tego samego silnika GGUF do generowania embeddingów, co eliminuje
osobną zależność sentence-transformers (ok. 500 MB).

Użycie:
    from nexus_ai.core.embeddings import EmbeddingService

    service = EmbeddingService(model_path="models/Qwen3-0.6B-Q4_K_M.gguf")
    vector = await service.embed("tekst faktury")
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.embeddings")

# ── Default embedding model path ────────────────────────────────────────────
# Używa najmniejszego modelu GGUF z Council of Agents (0.6B) w trybie embedding.
# Można zmienić na dedykowany model embeddingowy (np. all-MiniLM-L6-v2 GGUF).
DEFAULT_EMBEDDING_MODEL = "models/Qwen3-0.6B-Q4_K_M.gguf"
EMBEDDING_DIM = 768  # Domyślny wymiar (dla Qwen3-0.6B w trybie embedding)


class EmbeddingService:
    """Generuje embeddingi tekstu przez llama-cpp-python.

    Używa istniejących modeli GGUF z projektu (Council of Agents) w trybie
    embedding, co eliminuje potrzebę osobnej instalacji sentence-transformers.

    Args:
        model_path: Ścieżka do pliku GGUF. Domyślnie Qwen3-0.6B.
        embedding_dim: Wymiar embeddingu. Wykrywany dynamicznie z modelu.
        max_length: Maksymalna długość tekstu do embeddowania.
    """

    def __init__(
        self,
        model_path: str | Path | None = None,
        embedding_dim: int = EMBEDDING_DIM,
        max_length: int = 10000,
    ) -> None:
        self._model_path = Path(model_path or DEFAULT_EMBEDDING_MODEL)
        self._embedding_dim = embedding_dim
        self._max_length = max_length
        self._model: Any = None
        self._initialized = False

    def _ensure_model(self) -> None:
        """Lazy-init model through llama-cpp-python."""
        if self._initialized:
            return

        model_path = self._model_path
        if not model_path.exists():
            logger.warning(
                "[EmbeddingService] Model %s not found at %s. "
                "Using fallback hash-based embeddings. "
                "Download models with: python -m nexus_ai.scripts.download_models",
                model_path.name, model_path,
            )
            self._initialized = True
            return

        try:
            from llama_cpp import Llama

            self._model = Llama(
                model_path=str(model_path),
                embedding=True,       # Tryb embedding — kluczowe!
                n_ctx=2048,           # Mniejszy kontekst (embedding nie potrzebuje dużo)
                n_gpu_layers=-1,      # Wykorzystaj GPU jeśli dostępne
                verbose=False,
            )
            # Wykryj wymiar embeddingu
            try:
                test = self._model.create_embedding("test")
                vec = test["data"][0]["embedding"]
                self._embedding_dim = len(vec)
                logger.info(
                    "[EmbeddingService] Initialized: %s (dim=%d)",
                    model_path.name, self._embedding_dim,
                )
            except Exception:
                logger.info(
                    "[EmbeddingService] Initialized: %s (dim=%d, estimated)",
                    model_path.name, self._embedding_dim,
                )
            self._initialized = True

        except ImportError:
            logger.warning(
                "[EmbeddingService] llama-cpp-python not installed. "
                "Using fallback hash-based embeddings. "
                "Install with: pip install llama-cpp-python"
            )
            self._initialized = True

        except Exception as exc:
            logger.warning(
                "[EmbeddingService] Failed to load model %s: %s. "
                "Using fallback hash-based embeddings.",
                model_path.name, exc,
            )
            self._initialized = True

    def embed(self, text: str) -> list[float]:
        """Generate embedding vector from text using llama-cpp-python.

        Args:
            text: Tekst do zamiany na wektor.

        Returns:
            Lista floatów — wektor embeddingu.
        """
        self._ensure_model()

        if self._model is None:
            return self._fallback_embedding(text)

        try:
            truncated = text[:self._max_length]
            response = self._model.create_embedding(truncated)
            return response["data"][0]["embedding"]
        except Exception as exc:
            logger.warning(
                "[EmbeddingService] Embedding failed: %s — fallback to hash vector", exc,
            )
            return self._fallback_embedding(text)

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Generate embeddings for multiple texts in batch.

        Args:
            texts: Lista tekstów do embeddowania.

        Returns:
            Lista wektorów embeddingu.
        """
        self._ensure_model()

        if self._model is None:
            return [self._fallback_embedding(t) for t in texts]

        try:
            truncated = [t[:self._max_length] for t in texts]
            response = self._model.create_embedding(truncated)
            # Sort results by index to preserve input order
            sorted_data = sorted(response["data"], key=lambda x: x["index"])
            return [item["embedding"] for item in sorted_data]
        except Exception as exc:
            logger.warning(
                "[EmbeddingService] Batch embedding failed: %s — fallback", exc,
            )
            return [self._fallback_embedding(t) for t in texts]

    @property
    def embedding_dim(self) -> int:
        """Wymiar wektora embeddingu."""
        return self._embedding_dim

    # ── Fallback ──────────────────────────────────────────────────────────

    @staticmethod
    def _fallback_embedding(text: str) -> list[float]:
        """Fallback: generuje deterministyczny wektor z hash-a tekstu.

        Używane gdy model embeddingu nie jest dostępny.
        Zapewnia, że system nie przestaje działać — embeddingi będą
        niskiej jakości, ale stabilne.
        """
        import hashlib
        dim = EMBEDDING_DIM
        # Generuj stabilny hash z tekstu
        hash_bytes = hashlib.sha256(text.encode()).digest()
        # Rozciągnij 32 bajty SHA-256 na 'dim' wymiarów
        result = []
        for i in range(dim):
            val = (hash_bytes[i % 32] + (i * 7)) % 256
            result.append(val / 255.0)
        return result


# ── Global singleton ──────────────────────────────────────────────────────

_default_service: EmbeddingService | None = None


def get_embedding_service(
    model_path: str | Path | None = None,
) -> EmbeddingService:
    """Zwraca globalną instancję EmbeddingService (singleton).

    Args:
        model_path: Opcjonalna ścieżka do modelu (pierwsze wywołanie).

    Returns:
        Globalna instancja EmbeddingService.
    """
    global _default_service
    if _default_service is None:
        _default_service = EmbeddingService(model_path=model_path)
    return _default_service
