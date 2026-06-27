"""Active Learning Engine — ASYNC sqlite-vec + vec0 with partition_key.

Zgodnie z docs/SQLITE_VEC_AUDIT.md:
- FAZA 1: Konwersja z sync SQL na ASYNC AsyncVectorStore z vec0 virtual table
- FAZA 2: partition_key=["tenant_id", "contractor_nip"] dla pre-filteringu
- metadata_columns: contractor_nip, tenant_id przechowywane w vec0
- Używa VEC0_SCHEMAS["ocr_corrections"] z unified schema registry

Zgodnie z aa3fvcx.txt:
- LanceDB → sqlite-vec (wektory w SQLite)
- EmbeddingService używa istniejących modeli GGUF przez llama-cpp-python
"""

from __future__ import annotations

import hashlib  # MD5 for quick context dedup (non-cryptographic)
import uuid
from pathlib import Path
from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.embeddings import get_embedding_service
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.db.vector_store import AsyncVectorStore

logger = get_logger("nexus.core.active_learning")


class ActiveLearningEngine:
    """Silnik aktywnego uczenia na ASYNC vec0 z partition_key.

    FAZA 1+2 SUPERMOCE:
    - vec0 virtual table z ``partition_key=["tenant_id", "contractor_nip"]``
    - Wszystkie operacje ASYNC — 0ms blokowania async loop
    - ``search_similar(partition={...})`` — pre-filtering przez tenant+kontrahent
    - correction_payload przechowywany w osobnej tabeli (payload jest duży)
    """

    def __init__(
        self,
        db_path: str = "./data/active_learning.db",
    ):
        self.db_path = db_path
        self._store: AsyncVectorStore | None = None
        self._embedding_service = get_embedding_service()

    async def _get_store(self) -> AsyncVectorStore:
        """Lazy-init ASYNC VectorStore z vec0 ocr_corrections."""
        if self._store is None:
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
            self._store = AsyncVectorStore(self.db_path)

            # FAZA 2: vec0 z partition_keys przez unified schema registry
            await self._store.ensure_vec0_table("ocr_corrections")

            # Tabela pomocnicza dla correction_payload (duże JSON-y)
            conn = await self._store.get_conn()
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS ocr_correction_payloads (
                    rowid           TEXT PRIMARY KEY,
                    correction_payload TEXT NOT NULL,
                    context_hash    TEXT DEFAULT '',
                    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            await conn.commit()
        return self._store

    def _generate_embedding(self, raw_text: str) -> list[float]:
        """Zamienia surowy tekst faktury na wektor przez llama-cpp-python."""
        return self._embedding_service.embed(raw_text)

    async def save_correction(
        self,
        raw_text: str,
        nip: str,
        corrections: dict[str, Any],
        tenant_id: str = "default",
    ) -> None:
        """Zapisuje poprawkę użytkownika do vec0 (ASYNC).

        FAZA 1 SUPERMOC: async insert_vectors_batch() przez vec0.
        FAZA 2 SUPERMOC: partition_key=[tenant_id, contractor_nip]
        metadata przechowywane w vec0 — pre-filtering przy wyszukiwaniu.
        """
        vector = await anyio.to_thread.run_sync(self._generate_embedding, raw_text)
        context_hash = hashlib.md5(raw_text.encode()).hexdigest()

        store = await self._get_store()
        record_id = uuid.uuid4().hex

        # FAZA 2: insert z metadata przez unified schema
        await store.insert_vectors_batch(
            vectors=[(record_id, vector)],
            table_name="ocr_corrections",
            metadata=[{
                "contractor_nip": nip,
                "tenant_id": tenant_id,
            }],
        )

        # Zapisz payload w tabeli pomocniczej
        conn = await store.get_conn()
        await conn.execute(
            """INSERT INTO ocr_correction_payloads
               (rowid, correction_payload, context_hash, created_at)
               VALUES (?, ?, ?, ?)""",
            (
                record_id,
                msgspec_dumps(corrections, ensure_ascii=False),
                context_hash,
                pendulum.now("UTC").isoformat(),
            ),
        )
        await conn.commit()
        logger.info("[ACTIVE-LEARNING] Saved correction %s for nip=%s", record_id, nip)

    async def get_suggestion(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Szuka w vec0 podobnego układu dla danego NIP-u (ASYNC).

        FAZA 1+2 SUPERMOC:
        - async search_similar() — 0ms blokowania
        - partition={"tenant_id": tenant_id, "contractor_nip": nip} — pre-filtering
        - vec0 z indeksem IVF — ~10× szybszy niż O(n) skan
        """
        query_vector = await anyio.to_thread.run_sync(self._generate_embedding, raw_text)
        store = await self._get_store()

        # FAZA 2: ASYNC search z partition_key pre-filtering
        similar = await store.search_similar(
            query_vector=query_vector,
            limit=1,
            table_name="ocr_corrections",
            partition={
                "tenant_id": tenant_id,
                "contractor_nip": nip,
            },
        )

        if similar and float(similar[0]["_distance"]) < 0.1:
            row_id = similar[0].get("rowid", "")
            if row_id:
                conn = await store.get_conn()
                cursor = await conn.execute(
                    "SELECT correction_payload FROM ocr_correction_payloads WHERE rowid = ?",
                    (row_id,),
                )
                row = await cursor.fetchone()
                if row:
                    return msgspec_loads(row[0])

        return None

    async def get_suggested_correction(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Alias dla get_suggestion — kompatybilność z pipeline/parser.py."""
        return await self.get_suggestion(raw_text, nip, tenant_id)

    async def close(self) -> None:
        """Zamyka połączenie (ASYNC)."""
        if self._store:
            await self._store.close()
            self._store = None
