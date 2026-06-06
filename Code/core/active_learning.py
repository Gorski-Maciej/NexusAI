# core/active_learning.py
"""Active Learning Engine — uses sqlite-vec instead of LanceDB.

Zgodnie z aa3fvcx.txt: LanceDB → sqlite-vec.
Wektory przechowywane w SQLite z extension sqlite-vec.
sentence-transformers pozostaje opcjonalny (lazy import).
"""
from __future__ import annotations

import hashlib
import logging
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from core.msgspec_utils import msgspec_dumps, msgspec_loads
from db.vector_store import VectorStore

logger = logging.getLogger("nexus.core.active_learning")

# sentence-transformers is optional (lazy import)
try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    SentenceTransformer = None  # type: ignore[assignment]
    logger.warning("[ACTIVE-LEARNING] sentence_transformers not available — using dummy embeddings")


class ActiveLearningEngine:
    """Silnik aktywnego uczenia z sqlite-vec (zamiast LanceDB).

    Zapisuje embeddingi poprawek OCR w SQLite z extension sqlite-vec.
    """

    def __init__(self, db_path: str = "./data/active_learning.db"):
        self.db_path = db_path
        self._store: VectorStore | None = None
        self._model: Any = None

        # Ładuj model embeddingu (opcjonalny)
        if SentenceTransformer is not None:
            try:
                self._model = SentenceTransformer('all-MiniLM-L6-v2')
            except Exception:
                logger.warning("[ACTIVE-LEARNING] Failed to load SentenceTransformer; using dummy embeddings")

    def _get_store(self) -> VectorStore:
        """Lazy-init VectorStore (sqlite-vec)."""
        if self._store is None:
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
            self._store = VectorStore(self.db_path)
            self._ensure_tables()
        return self._store

    def _ensure_tables(self) -> None:
        """Ensure tables exist for active learning corrections."""
        conn = self._get_store()._get_conn()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS ocr_corrections (
                id               TEXT PRIMARY KEY,
                vector           BLOB NOT NULL,
                contractor_nip   TEXT NOT NULL,
                correction_payload TEXT NOT NULL,
                context_hash     TEXT DEFAULT '',
                tenant_id        TEXT DEFAULT 'default',
                created_at       TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.commit()

    def _generate_embedding(self, raw_text: str) -> list[float]:
        """Zamienia surowy tekst faktury na wektor."""
        if self._model is not None:
            try:
                return self._model.encode(raw_text[:10000]).tolist()
            except Exception:
                pass
        # Fallback: prosty wektor oparty na długości
        return [float(len(raw_text)) % 1000 / 1000.0] * 384

    async def save_correction(
        self,
        raw_text: str,
        nip: str,
        corrections: dict[str, Any],
        tenant_id: str = "default",
    ) -> None:
        """Zapisuje poprawkę użytkownika do bazy wektorowej."""
        vector = self._generate_embedding(raw_text)
        context_hash = hashlib.md5(raw_text.encode()).hexdigest()

        store = self._get_store()
        record_id = str(uuid.uuid4())

        # Zapisz do tabeli ocr_corrections przez raw SQL
        conn = store._get_conn()
        conn.execute(
            """INSERT INTO ocr_corrections
               (id, vector, contractor_nip, correction_payload, context_hash, tenant_id, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                record_id,
                store._vector_to_blob(vector),
                nip,
                msgspec_dumps(corrections, ensure_ascii=False),
                context_hash,
                tenant_id,
                datetime.now(UTC).isoformat(),
            ),
        )
        conn.commit()
        logger.info("[ACTIVE-LEARNING] Saved correction %s for nip=%s", record_id, nip)

    async def get_suggestion(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Szuka w bazie wektorowej podobnego układu dla danego NIP-u."""
        query_vector = self._generate_embedding(raw_text)

        store = self._get_store()
        conn = store._get_conn()
        query_blob = store._vector_to_blob(query_vector)

        rows = conn.execute(
            """SELECT correction_payload, vec_distance_cosine(vector, ?) AS _distance
               FROM ocr_corrections
               WHERE contractor_nip = ? AND tenant_id = ?
               ORDER BY _distance ASC
               LIMIT 1""",
            (query_blob, nip, tenant_id),
        ).fetchall()

        if rows and float(rows[0]["_distance"]) < 0.1:
            return msgspec_loads(rows[0]["correction_payload"])

        return None

    async def get_suggested_correction(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Alias dla get_suggestion — kompatybilność z pipeline/parser.py."""
        return await self.get_suggestion(raw_text, nip, tenant_id)

    def close(self) -> None:
        """Zamyka połączenie."""
        if self._store:
            self._store.close()
            self._store = None
