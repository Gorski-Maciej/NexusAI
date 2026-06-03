"""
ActiveLearningService — usługa aktywnego uczenia na podstawie ręcznych poprawek księgowej.

Wykorzystuje LanceDB do przechowywania embeddingów układów faktur
oraz sentence-transformers (all-MiniLM-L6-v2) do wektoryzacji tekstu OCR.
Lazy importy — obie biblioteki opcjonalne, fallback do zerowego wektora.
"""

from __future__ import annotations

import json
import logging
import uuid
from typing import Any

from models.invoice import ActiveLearningPattern
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger("nexus.servicess.active_learning")

# ── LanceDB table constants ──────────────────────────────────────────────────

INVOICE_TEMPLATES_TABLE = "invoice_templates"
"""LanceDB table for invoice layout embeddings."""

EMBEDDING_DIM = 384
"""Default embedding dimension (all-MiniLM-L6-v2)."""

SIMILARITY_THRESHOLD = 0.4
"""Max cosine distance for a layout to be considered similar."""


class ActiveLearningService:
    """Usługa ucząca system na podstawie ręcznych poprawek księgowej.

    Args:
        lancedb_path: Ścieżka do lokalnej bazy LanceDB.
    """

    def __init__(self, lancedb_path: str = "nexus_lancedb") -> None:
        self._lancedb_path = lancedb_path
        self._db: Any = None
        self._model: Any = None
        self._embedding_dim: int = EMBEDDING_DIM

    # ── Private helpers ──────────────────────────────────────────────

    def _init_lancedb(self) -> Any:
        """Lazy init LanceDB connection."""
        if self._db is not None:
            return self._db
        try:
            import lancedb
            self._db = lancedb.connect(self._lancedb_path, mode="file")
            self._ensure_templates_table()
        except ImportError:
            logger.warning("[ACTIVE-LEARNING] lancedb not installed — vector features disabled")
            self._db = None  # type: ignore[assignment]
        return self._db

    def _ensure_templates_table(self) -> None:
        """Create invoice_templates table if not exists."""
        if self._db is None:
            return
        if INVOICE_TEMPLATES_TABLE not in self._db.table_names():
            try:
                import pyarrow as pa
                schema = pa.schema([
                    pa.field("vector", pa.list_(pa.float32(), self._embedding_dim)),
                    pa.field("contractor_nip", pa.string()),
                    pa.field("layout_features", pa.string()),
                    pa.field("template_id", pa.string()),
                    pa.field("created_at", pa.timestamp("us", tz="UTC")),
                ])
                self._db.create_table(INVOICE_TEMPLATES_TABLE, schema=schema)
                logger.info(
                    "[ACTIVE-LEARNING] Created %s table (dim=%d)",
                    INVOICE_TEMPLATES_TABLE, self._embedding_dim,
                )
            except ImportError:
                logger.warning("[ACTIVE-LEARNING] pyarrow not installed — cannot create table schema")

    def get_embedding(self, text: str) -> list[float]:
        """Generate embedding vector from OCR text using sentence-transformers.

        Args:
            text: OCR text to vectorize.

        Returns:
            List of floats (embedding vector). Falls back to zero vector
            if sentence-transformers is unavailable.
        """
        model = self._get_model()
        if model is not None:
            try:
                return model.encode(text[:10000]).tolist()
            except Exception as exc:
                logger.warning("[ACTIVE-LEARNING] Embedding failed: %s — fallback to zero vector", exc)
        return [0.0] * self._embedding_dim

    def _get_model(self) -> Any:
        """Lazy-load sentence-transformers model."""
        if self._model is not None:
            return self._model
        try:
            from sentence_transformers import SentenceTransformer
            try:
                self._model = SentenceTransformer("all-MiniLM-L6-v2")
                self._embedding_dim = 384
            except Exception:
                # Fallback: HerBERT (polski, 768-dim)
                logger.warning("[ACTIVE-LEARNING] all-MiniLM-L6-v2 unavailable, trying HerBERT")
                self._model = SentenceTransformer("sdadas/herbert-base-embedding")
                self._embedding_dim = 768
        except ImportError:
            logger.warning("[ACTIVE-LEARNING] sentence-transformers not installed")
            self._model = None
        return self._model

    # ── Public API ───────────────────────────────────────────────────

    @staticmethod
    async def register_correction(
        session: AsyncSession,
        nip: str,
        field_name: str,
        ai_guess: str,
        human_correction: str,
    ) -> None:
        """Zapisuje, że AI się pomyliło i użytkownik musiał ręcznie poprawić wartość."""
        if not nip:
            return

        correction_payload = {
            "field": field_name,
            "ai_guess": ai_guess,
            "human_correction": human_correction,
        }

        pattern = ActiveLearningPattern(
            contractor_nip=nip,
            correction_payload=json.dumps(correction_payload),
        )
        session.add(pattern)

    async def find_similar_layout(self, ocr_text: str) -> dict[str, Any] | None:
        """Szuka w bazie wektorowej podobnego układu faktury.

        Args:
            ocr_text: Tekst faktury po OCR.

        Returns:
            Dopasowany rekord (dict z vector, contractor_nip, layout_features)
            lub None, jeśli nic podobnego nie znaleziono.
        """
        db = self._init_lancedb()
        if db is None:
            return None

        if INVOICE_TEMPLATES_TABLE not in db.table_names():
            return None

        vector = self.get_embedding(ocr_text)
        table = db.open_table(INVOICE_TEMPLATES_TABLE)

        try:
            results = table.search(vector).limit(1).to_list()
            if results and results[0].get("_distance", 1.0) < SIMILARITY_THRESHOLD:
                return results[0]
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] find_similar_layout failed: %s", exc)

        return None

    def learn_new_template(self, nip: str, ocr_text: str) -> None:
        """Zapisuje nowy wzorzec do bazy wektorowej.

        Args:
            nip: NIP kontrahenta.
            ocr_text: Tekst faktury po OCR.
        """
        db = self._init_lancedb()
        if db is None:
            logger.warning("[ACTIVE-LEARNING] Cannot learn template — LanceDB unavailable")
            return

        vector = self.get_embedding(ocr_text)

        try:
            from datetime import datetime, timezone
            self._ensure_templates_table()
            table = db.open_table(INVOICE_TEMPLATES_TABLE)
            table.add([{
                "vector": vector,
                "contractor_nip": nip,
                "layout_features": ocr_text[:500],
                "template_id": str(uuid.uuid4()),
                "created_at": datetime.now(timezone.utc),
            }])
            logger.info("[ACTIVE-LEARNING] Learned new template for nip=%s", nip)
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] learn_new_template failed: %s", exc)