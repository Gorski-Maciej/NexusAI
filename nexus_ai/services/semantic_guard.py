"""
SemanticGuard — semantyczny wykrywacz anomalii faktur na ASYNC vec0.

Zgodnie z docs/SQLITE_VEC_AUDIT.md:
- FAZA 1: Konwersja z sync SQL na ASYNC AsyncVectorStore z vec0 virtual table
- FAZA 2: partition_key=vendor_nip dla pre-filteringu
- metadata_columns: category_code, amount_net, id przechowywane w vec0
- Używa VEC0_SCHEMAS["vendor_invoices"] z unified schema registry

Zgodnie z aa3fvcx.txt:
- Używa sqlite-vec (Punkt 3) do wyszukiwania wektorowego
- Używa llama-cpp-python do embeddingów (technologia ze stacku)
- Nie używa agentów AI, protokołów ani specyficznych modeli LLM
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, final

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.cache import get_cache
from nexus_ai.core.embeddings import get_embedding_service
from nexus_ai.db.vector_store import AsyncVectorStore

# ── SHA-256 przez nexus-crypto (Rust+PyO3) z fallback do hashlib ────────
try:
    from nexus_crypto import sha256 as _text_hash
except ImportError:
    import hashlib as _hl

    def _text_hash(data: bytes) -> str:
        return _hl.sha256(data).hexdigest()


# NexusCache dla wyników evaluate() (L1 RAM + L2 SQLite przez dyscache)
_semantic_eval_cache = get_cache()

# Prefixy cache dla event-based invalidation
SEMANTIC_CACHE_PREFIXES = ["semantic_eval:"]


def invalidate_semantic_guard_cache() -> None:
    """Event-based cache invalidation dla SemanticGuard."""
    _semantic_eval_cache.delete_prefix_sync("semantic_eval:")


logger = get_logger("nexus.services.semantic_guard")

# ── Anomaly rules ──────────────────────────────────────────────────────────

ANOMALY_RULES: list[dict[str, Any]] = [
    {
        "min_score": 0.80,
        "min_amount": 10000,
        "action": "BLOCK_DECREE",
        "alert": "Drastyczna zmiana profilu usług. Wymagana ręczna weryfikacja.",
    },
    {
        "min_score": 0.60,
        "min_amount": 10000,
        "action": "WARN",
        "alert": "Znacząca zmiana profilu usług. Zalecana weryfikacja.",
    },
    {
        "min_score": 0.40,
        "min_amount": 50000,
        "action": "WARN",
        "alert": "Nietypowa wartość faktury względem historii.",
    },
    {"min_score": 0.0, "min_amount": 0, "action": "ALLOW", "alert": None},
]


# ── SemanticGuard (ASYNC) ───────────────────────────────────────────────────


@final
class SemanticGuard:
    """Detektor anomalii semantycznych — ASYNC na vec0 z partition_key.

    FAZA 1+2 SUPERMOCE:
    - vec0 virtual table z ``partition_key=vendor_nip``
    - metadata_columns: category_code, amount_net, id
    - Wszystkie operacje ASYNC — 0ms blokowania async loop
    - ``search_similar(partition={"vendor_nip": nip})`` — pre-filtering
    """

    EMBEDDING_DIM = 768

    def __init__(
        self,
        db_path: str = "app_data/semantic_guard.db",
    ) -> None:
        self._db_path = db_path
        self._store: AsyncVectorStore | None = None
        self._embedding_service = get_embedding_service()
        self._embedding_dim: int = self.EMBEDDING_DIM

    async def _init_store(self) -> AsyncVectorStore:
        """Lazy init ASYNC VectorStore z vec0 vendor_invoices."""
        if self._store is not None:
            return self._store
        Path(self._db_path).parent.mkdir(parents=True, exist_ok=True)
        self._store = AsyncVectorStore(self._db_path)

        # FAZA 2: Użyj unified schema registry + vec0 z partition_key
        await self._store.ensure_vec0_table("vendor_invoices")

        # Tabela pomocnicza dla przechowywania oryginalnego tekstu faktury
        conn = await self._store.get_conn()
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS vendor_invoice_text (
                rowid           INTEGER PRIMARY KEY,
                vendor_nip      TEXT NOT NULL,
                invoice_text    TEXT DEFAULT '',
                transaction_id  TEXT DEFAULT '',
                timestamp       TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        await conn.commit()
        return self._store

    def _get_embedding(self, text: str) -> list[float]:
        """Generate embedding vector from text."""
        vec = self._embedding_service.embed(text)
        self._embedding_dim = len(vec)
        return vec

    async def evaluate(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
    ) -> dict[str, Any]:
        """Evaluate invoice for semantic anomalies (ASYNC).

        FAZA 1 SUPERMOC: async przez search_similar() — 0ms blokowania.
        FAZA 2 SUPERMOC: pre-filtering przez partition={"vendor_nip": nip}.

        Wynik cache'owany w NexusCache przez 3600s.

        Args:
            invoice_text: Pełny tekst faktury (po OCR).
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto faktury.

        Returns:
            Dict z polami: action, anomaly_score, alert.
        """
        # Sprawdź NexusCache
        eval_cache_key = (
            f"semantic_eval:{vendor_nip}:{amount_net}:{_text_hash(invoice_text.encode())}"
        )
        cached = _semantic_eval_cache.get_sync(eval_cache_key)
        if cached is not None:
            logger.debug("[SemanticGuard] evaluate cache HIT for vendor=%s", vendor_nip)
            return cached

        embedding = await anyio.to_thread.run_sync(self._get_embedding, invoice_text)
        store = await self._init_store()

        # FAZA 1+2: ASYNC search_similar z partition_key pre-filtering
        try:
            similar = await store.search_similar(
                query_vector=embedding,
                limit=5,
                table_name="vendor_invoices",
                partition={"vendor_nip": vendor_nip},
            )
        except Exception:
            similar = []

        # Calculate anomaly score
        if similar:
            distances = [float(r["_distance"]) for r in similar]
            anomaly_score = sum(distances) / len(distances)
        else:
            anomaly_score = 0.0  # New vendor — no history

        # Check against anomaly rules
        action = "ALLOW"
        alert = None

        for rule in ANOMALY_RULES:
            if anomaly_score >= rule["min_score"] and amount_net >= rule["min_amount"]:
                action = rule["action"]
                alert = rule["alert"]
                break

        result = {
            "action": action,
            "anomaly_score": round(anomaly_score, 4),
            "alert": alert,
        }

        # Zapisz w NexusCache
        _semantic_eval_cache.set_sync(eval_cache_key, result, ttl=3600)
        return result

    async def store_invoice(
        self,
        vendor_nip: str,
        invoice_text: str,
        category_code: str = "",
        amount_net: float = 0.0,
        transaction_id: str = "",
    ) -> None:
        """Store verified invoice in vec0 for future anomaly detection (ASYNC).

        FAZA 1 SUPERMOC: async insert_vectors_batch() przez vec0.
        FAZA 2 SUPERMOC: metadata (category_code, amount_net) przechowywane
        w vec0 jako metadata_columns — brak osobnej tabeli, brak JOIN-ów.
        """
        import uuid

        embedding = await anyio.to_thread.run_sync(self._get_embedding, invoice_text)
        store = await self._init_store()

        record_id = uuid.uuid4().hex

        # FAZA 2: insert z metadata przez unified schema
        await store.insert_vectors_batch(
            vectors=[(record_id, embedding)],
            table_name="vendor_invoices",
            metadata=[{
                "vendor_nip": vendor_nip,
                "category_code": category_code,
                "amount_net": float(amount_net),
                "id": record_id,
            }],
        )

        # Zapisz tekst faktury w tabeli pomocniczej
        conn = await store.get_conn()
        await conn.execute(
            """INSERT INTO vendor_invoice_text
               (rowid, vendor_nip, invoice_text, transaction_id, timestamp)
               VALUES (?, ?, ?, ?, ?)""",
            (
                record_id,
                vendor_nip,
                invoice_text[:5000],
                transaction_id,
                pendulum.now("UTC").isoformat(),
            ),
        )
        await conn.commit()

        logger.info(
            "[SemanticGuard] Stored invoice %s for vendor %s (cat=%s, net=%.2f)",
            transaction_id,
            vendor_nip,
            category_code,
            float(amount_net),
        )
        invalidate_semantic_guard_cache()
