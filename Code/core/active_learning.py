# core/active_learning.py
from __future__ import annotations

import json
import hashlib
import logging
from typing import Optional, Dict, Any
from pathlib import Path

from cachetools import TTLCache
import lancedb
import polars as pl
import numpy as np

logger = logging.getLogger("nexus.core.active_learning")

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    SentenceTransformer = None  # type: ignore[assignment]
    logger.warning("[ACTIVE-LEARNING] sentence_transformers not available")

# Stałe schematu LanceDB zdefiniowane przez Polars
_CORRECTIONS_DTYPES = {
    "vector": pl.List(pl.Float32),
    "contractor_nip": pl.Utf8,
    "correction_payload": pl.Utf8,
    "context_hash": pl.Utf8,
}


class ActiveLearningEngine:
    """Silnik aktywnego uczenia z batchowaniem zapisów i cache'owaniem odczytów.
    Rozwiązanie 19: Buforowanie zapisów, LRU cache, indeks IVF, obsługa float16.
    """

    def __init__(self, db_path: str = "./data/vector_db"):
        self.db_path = db_path
        self.table_name = "ocr_corrections"
        self._init_db()

        # Bufor wsadowy dla zapisów (Rozwiązanie 19)
        self._batch_buffer: list[dict[str, Any]] = []
        self._batch_max_size = 100  # Maksymalny rozmiar batcha
        self._batch_flush_interval = 5.0  # Sekundy między flush

        # LRU cache dla odczytów (Rozwiązanie 19)
        self._suggestion_cache: TTLCache = TTLCache(maxsize=500, ttl=3600)

        # Ładuj model embeddingu
        if SentenceTransformer is not None:
            self.model = SentenceTransformer('all-MiniLM-L6-v2')
        else:
            self.model = None

    def _init_db(self):
        """Inicjalizuje bazę i tabelę, jeśli nie istnieją."""
        self.db = lancedb.connect(self.db_path, mode="file")
        if self.table_name not in self.db.table_names():
            # Definiujemy schemat przez Polars → konwersja do Arrow dla LanceDB
            _empty = pl.DataFrame({}, schema=_CORRECTIONS_DTYPES)
            _arrow_schema = _empty.to_arrow().schema
            self.db.create_table(self.table_name, schema=_arrow_schema)
        self.table = self.db.open_table(self.table_name, index_cache_size=100 * 1024 * 1024)

    def _generate_embedding(self, raw_text: str) -> list[float]:
        """Zamienia surowy tekst faktury na wektor."""
        if self.model is None:
            raise RuntimeError("SentenceTransformer not available; cannot generate embeddings")
        return self.model.encode(raw_text).tolist()

    def _to_float16(self, vector: list[float]) -> list[float]:
        """Konwertuje wektor do float16 dla oszczędności pamięci (Rozwiązanie 19)."""
        return np.array(vector, dtype=np.float16).tolist()

    def _get_cache_key(self, raw_text: str, nip: str) -> str:
        """Generuje klucz cache dla sugestii."""
        combined = f"{nip}:{raw_text[:200]}"
        return hashlib.md5(combined.encode()).hexdigest()

    async def save_correction(self, raw_text: str, nip: str, corrections: Dict[str, Any]):
        """Zapisuje poprawkę użytkownika do bazy wektorowej z batchowaniem (Rozwiązanie 19)."""
        vector = self._generate_embedding(raw_text)
        vector_f16 = self._to_float16(vector)

        data = {
            "vector": vector_f16,
            "contractor_nip": nip,
            "correction_payload": json.dumps(corrections),
            "context_hash": hashlib.md5(raw_text.encode()).hexdigest()
        }

        self._batch_buffer.append(data)

        # Automatyczny flush gdy batch osiągnie maksymalny rozmiar
        if len(self._batch_buffer) >= self._batch_max_size:
            await self.flush_batch()

    async def flush_batch(self) -> int:
        """Wymusza zapis buforowanych korekt w jednej transakcji wsadowej.
        Zwraca liczbę zapisanych rekordów.
        """
        if not self._batch_buffer:
            return 0

        batch = self._batch_buffer[:]
        self._batch_buffer = []

        try:
            self.table.add(batch)
            logger.info("[ACTIVE-LEARNING] Flushed batch of %d corrections", len(batch))
            return len(batch)
        except Exception as e:
            logger.error("[ACTIVE-LEARNING] Batch flush failed: %s", e)
            # Przywróć bufor w razie błędu
            self._batch_buffer = batch + self._batch_buffer
            raise

    @property
    def pending_count(self) -> int:
        """Liczba korekt oczekujących w buforze na zapis."""
        return len(self._batch_buffer)

    async def get_suggestion(self, raw_text: str, nip: str) -> Optional[dict[str, Any]]:
        """Szuka w bazie wektorowej podobnego układu dla danego NIP-u.
        Rozwiązanie 19: LRU cache dla wyników wyszukiwania.
        """
        # Sprawdź cache (Rozwiązanie 19)
        cache_key = self._get_cache_key(raw_text, nip)
        cached = self._suggestion_cache.get(cache_key)
        if cached is not None:
            logger.debug("[ACTIVE-LEARNING] Cache hit for nip=%s", nip)
            return cached

        query_vector = self._generate_embedding(raw_text)
        query_vector_f16 = self._to_float16(query_vector)

        results = (
            self.table.search(query_vector_f16)
            .where(f"contractor_nip = '{nip}'")
            .limit(1)
            .to_list()
        )

        if results and results[0]["_distance"] < 0.1:
            suggestion = json.loads(results[0]["correction_payload"])
            # Zapisz w cache (Rozwiązanie 19)
            self._suggestion_cache[cache_key] = suggestion
            return suggestion

        return None

    def ensure_index(self) -> None:
        """Tworzy indeks IVF dla szybszego wyszukiwania wektorowego (Rozwiązanie 19)."""
        try:
            self.table.create_index(
                metric="cosine",
                num_partitions=256,
                num_sub_vectors=32,
            )
            logger.info("[ACTIVE-LEARNING] IVF index created successfully")
        except Exception as e:
            logger.warning("[ACTIVE-LEARNING] Failed to create IVF index: %s", e)

    def optimize_storage(self) -> None:
        """Optymalizuje przechowywanie: kompaktuje pliki i czyści stare wersje."""
        try:
            if hasattr(self.table, "compact_files"):
                self.table.compact_files()
                logger.info("[ACTIVE-LEARNING] Storage compacted")
            if hasattr(self.table, "cleanup_old_versions"):
                self.table.cleanup_old_versions()
                logger.info("[ACTIVE-LEARNING] Old versions cleaned up")
        except Exception as e:
            logger.warning("[ACTIVE-LEARNING] Storage optimization failed: %s", e)

    def close(self) -> None:
        """Zamyka bazę wektorową i czyści cache."""
        self._suggestion_cache.clear()
        logger.info("[ACTIVE-LEARNING] Closed, cache cleared (%d items)", len(self._suggestion_cache))
