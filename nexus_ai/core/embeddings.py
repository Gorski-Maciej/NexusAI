"""
EmbeddingService — centralized text embedding engine using llama-cpp-python.

Zgodnie z aa3fvcx.txt:
- Zastępuje: sentence-transformers (biblioteka spoza stacku)
- Nowy:     llama-cpp-python z embedding=True (technologia z stacku)
- Integracja z nexus_cache (wbudowany cache) i msgspec (Punkty 4 i 13)

llama-cpp-python jest już w projekcie jako zależność.
Używa tego samego silnika GGUF do generowania embeddingów, co eliminuje
osobną zależność sentence-transformers (ok. 500 MB).

Użycie:
    from nexus_ai.core.embeddings import EmbeddingService

    service = EmbeddingService(model_path="models/mymodel.gguf")
    vector = await service.embed("tekst faktury")
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

# ── SHA-256 przez nexus-crypto (Rust+PyO3) zgodnie z aa3fvcx.txt ─────────
try:
    from nexus_crypto import sha256 as _sha256

    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib

    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


from nexus_ai.core.cache import get_cache
from structlog import get_logger

logger = get_logger("nexus.core.embeddings")

# NexusCache dla embeddingów (diskcache-backed)
# Klucz: semantic_embed:{sha256(text)} → list[float]
# TTL: 3600s (1h) — embedding jest deterministyczny dla tego samego tekstu
# Oszczędza ~50-200ms przy wołaniu embed() dla tej samej faktury
# (np. evaluate() → store_invoice() w SemanticGuard)
_embedding_cache = get_cache()

# ── Default embedding dimension ─────────────────────────────────────────────
EMBEDDING_DIM = 768  # Domyślny wymiar (wykrywany dynamicznie z modelu)


class EmbeddingService:
    """Generuje embeddingi tekstu przez llama-cpp-python.

    Zgodnie z aa3fvcx.txt: używa llama-cpp-python z embedding=True.
    Nie definiuje konkretnego modelu — ścieżka jest parametrem.

    Args:
        model_path: Ścieżka do pliku GGUF. None = użyj fallback hash.
        embedding_dim: Wymiar embeddingu. Wykrywany dynamicznie z modelu.
        max_length: Maksymalna długość tekstu do embeddowania.
    """

    def __init__(
        self,
        model_path: str | Path | None = None,
        embedding_dim: int = EMBEDDING_DIM,
        max_length: int = 10000,
    ) -> None:
        self._model_path = Path(model_path) if model_path else None
        self._embedding_dim = embedding_dim
        self._max_length = max_length
        self._model: Any = None
        self._initialized = False

    def _ensure_model(self) -> None:
        """Lazy-init model through llama-cpp-python."""
        if self._initialized:
            return

        model_path = self._model_path
        if not model_path or not model_path.exists():
            logger.warning(
                "[EmbeddingService] Model %s not found at %s. "
                "Using fallback hash-based embeddings. "
                "Place a .gguf model in models/ directory.",
                model_path.name,
                model_path,
            )
            self._initialized = True
            return

        try:
            from llama_cpp import Llama

            self._model = Llama(
                model_path=str(model_path),
                embedding=True,  # Tryb embedding — kluczowe!
                n_ctx=2048,  # Mniejszy kontekst (embedding nie potrzebuje dużo)
                n_gpu_layers=-1,  # Wykorzystaj GPU jeśli dostępne
                verbose=False,
            )
            # Wykryj wymiar embeddingu
            try:
                test = self._model.create_embedding("test")
                vec = test["data"][0]["embedding"]
                self._embedding_dim = len(vec)
                logger.info(
                    "[EmbeddingService] Initialized: %s (dim=%d)",
                    model_path.name,
                    self._embedding_dim,
                )
            except Exception:
                logger.info(
                    "[EmbeddingService] Initialized: %s (dim=%d, estimated)",
                    model_path.name,
                    self._embedding_dim,
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
                model_path.name,
                exc,
            )
            self._initialized = True

    def embed(self, text: str) -> list[float]:
        """Generate embedding vector from text using llama-cpp-python.

        Wynik cache'owany w NexusCache (``semantic_embed:{sha256(text)}``) przez 3600s.
        Oszczędza generowanie embeddingu gdy ten sam tekst jest embeddowany
        wielokrotnie (np. evaluate() → store_invoice() w SemanticGuard).

        Args:
            text: Tekst do zamiany na wektor.

        Returns:
            Lista floatów — wektor embeddingu.
        """
        # Sprawdź NexusCache (L1 RAM) — szybki path, oszczędza ~50-200ms
        cache_key = f"semantic_embed:{_sha256(text.encode())}"
        cached = _embedding_cache.get_sync(cache_key)
        if cached is not None:
            return cached

        self._ensure_model()

        if self._model is None:
            vector = self._fallback_embedding(text)
            _embedding_cache.set_sync(cache_key, vector, ttl=3600)
            return vector

        try:
            truncated = text[: self._max_length]
            response = self._model.create_embedding(truncated)
            vector = response["data"][0]["embedding"]
            _embedding_cache.set_sync(cache_key, vector, ttl=3600)
            return vector
        except Exception as exc:
            logger.warning(
                "[EmbeddingService] Embedding failed: %s — fallback to hash vector",
                exc,
            )
            vector = self._fallback_embedding(text)
            _embedding_cache.set_sync(cache_key, vector, ttl=3600)
            return vector

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
            truncated = [t[: self._max_length] for t in texts]
            response = self._model.create_embedding(truncated)
            # Sort results by index to preserve input order
            sorted_data = sorted(response["data"], key=lambda x: x["index"])
            return [item["embedding"] for item in sorted_data]
        except Exception as exc:
            logger.warning(
                "[EmbeddingService] Batch embedding failed: %s — fallback",
                exc,
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
        dim = EMBEDDING_DIM
        # Generuj stabilny hash z tekstu (SHA-256 przez nexus-crypto)
        hash_bytes = bytes.fromhex(_sha256(text.encode()))
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
