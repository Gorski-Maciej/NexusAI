"""
SemanticGuard — semantyczny wykrywacz anomalii faktur z DuckDB VSS.

SUPERMOCE DuckDB version:
- DuckDB VSS (Vector Similarity Search) zamiast osobnej bazy sqlite-vec.
- Wszystkie embeddingi w tej samej bazie DuckDB — jedno połączenie,
  jedna transakcja, backup.
- ``array_cosine_similarity()`` — natywna funkcja DuckDB z indeksem HNSW.
- ``GENERATE_SERIES`` dla batch insert wektorów.

Zgodnie z aa3fvcx.txt:
- DuckDB (Punkt 3) dla analityki OLAP + teraz również VSS
- Używa llama-cpp-python do embeddingów
"""

from __future__ import annotations

from decimal import Decimal
from pathlib import Path
from typing import Any, final

import anyio
import pendulum
import duckdb
from structlog import get_logger

from nexus_ai.core.cache import get_cache
from nexus_ai.core.embeddings import get_embedding_service

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


# ── DuckDB VSS Schema ───────────────────────────────────────────────────────

VENDOR_EMBEDDINGS_SCHEMA = """
-- SUPERMOC: DuckDB VSS z indeksem HNSW
-- Zastępuje osobną bazę sqlite-vec + osobny VectorStore
-- Wszystkie embeddingi w tej samej bazie DuckDB
CREATE TABLE IF NOT EXISTS vendor_embeddings (
    id              VARCHAR PRIMARY KEY,
    vendor_nip      VARCHAR NOT NULL,
    embedding       FLOAT[768],
    category_code   VARCHAR DEFAULT '',
    amount_net      DOUBLE DEFAULT 0.0,
    invoice_text    VARCHAR DEFAULT '',
    transaction_id  VARCHAR DEFAULT '',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Partition key dla pre-filteringu
    partition_key   VARCHAR GENERATED ALWAYS AS (vendor_nip) STORED
);

-- SUPERMOC: Indeks HNSW dla VSS (cosine similarity)
-- M=16, ef_construction=200 — optymalne dla 768-dim wektorów
CREATE INDEX IF NOT EXISTS idx_vendor_embeddings_hnsw
    ON vendor_embeddings
    USING HNSW (embedding cosine)
    WITH (dim=768, M=16, ef_construction=200);

-- Indeks dla pre-filteringu po vendor_nip
CREATE INDEX IF NOT EXISTS idx_vendor_embeddings_nip
    ON vendor_embeddings(vendor_nip);
"""


# ── SemanticGuard z DuckDB VSS ───────────────────────────────────────────────


@final
class SemanticGuard:
    """Detektor anomalii semantycznych — DuckDB VSS.

    SUPERMOCE DuckDB:
    - VSS (Vector Similarity Search) z indeksem HNSW — natywny w DuckDB
    - ``array_cosine_similarity()`` — funkcja skalarna DuckDB
    - JEDNA baza zamiast dwóch (sqlite-vec + DuckDB analityka)
    - Pre-filtering przez ``WHERE vendor_nip = ?`` przed VSS
    - Backup całej bazy przez ``EXPORT DATABASE`` — backup embeddingów
      razem z resztą danych analitycznych
    """

    EMBEDDING_DIM = 768

    def __init__(
        self,
        conn_or_path: duckdb.DuckDBPyConnection | str,
        embedding_dim: int = 768,
    ) -> None:
        """Inicjalizacja SemanticGuard z DuckDB VSS.

        SUPERMOC DuckDB:
        - VSS (Vector Similarity Search) z indeksem HNSW — natywny w DuckDB
        - ``array_cosine_similarity()`` — funkcja skalarna DuckDB
        - JEDNA baza zamiast dwóch (sqlite-vec + DuckDB analityka)

        Args:
            conn_or_path: Połączenie DuckDB (współdzielone z DuckDBManager)
                LUB ścieżka do pliku bazy (tworzy nowe połączenie).
            embedding_dim: Wymiar wektorów embeddingu (domyślnie 768).
        """
        # SUPERMOC: Akceptujemy zarówno conn jak i path dla kompatybilności
        if isinstance(conn_or_path, str):
            self._conn = duckdb.connect(conn_or_path)
        else:
            self._conn = conn_or_path
        self._embedding_service = get_embedding_service()
        self._embedding_dim = embedding_dim
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Utwórz schemat VSS — INSTALL vss + CREATE TABLE + indeks HNSW."""
        # SUPERMOC: Instalacja i załadowanie VSS extension
        try:
            self._conn.execute("INSTALL vss; LOAD vss;")
        except Exception:
            logger.warning(
                "[SemanticGuard] DuckDB VSS extension not available — "
                "vector search disabled. Install with: INSTALL vss; LOAD vss;"
            )

        # Utwórz tabelę embeddingów z indeksem HNSW
        self._conn.execute(VENDOR_EMBEDDINGS_SCHEMA)

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
        """Evaluate invoice for semantic anomalies — DuckDB VSS.

        SUPERMOC DuckDB:
        - ``array_cosine_similarity()`` — natywna funkcja VSS
        - ``WHERE vendor_nip = ?`` — pre-filtering przed VSS
        - ``ORDER BY score DESC LIMIT 5`` — najbliżsi sąsiedzi

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

        # ── SUPERMOC: DuckDB VSS wyszukiwanie wektorowe ────────────────
        # array_cosine_similarity() + indeks HNSW + pre-filtering
        rows = self._conn.execute(
            """
            SELECT id, vendor_nip, category_code, amount_net, invoice_text,
                   array_cosine_similarity(embedding, ?::FLOAT[768]) AS score
            FROM vendor_embeddings
            WHERE vendor_nip = ?
              AND embedding IS NOT NULL
            ORDER BY score DESC
            LIMIT 5
            """,
            (embedding, vendor_nip),
        ).fetchall()

        # Calculate anomaly score
        if rows:
            distances = [float(r[5]) for r in rows]  # score = cosine similarity
            # Normalize: 1 - avg_similarity → anomaly_score
            anomaly_score = 1.0 - (sum(distances) / len(distances))
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
        """Store verified invoice in DuckDB VSS for future anomaly detection.

        SUPERMOC DuckDB:
        - JEDEN INSERT zamiast dwóch (embedding + text) — wszystko w jednej tabeli
        - Indeks HNSW automatycznie indeksuje nowy wektor
        - Backup przez EXPORT DATABASE — embeddingi razem z resztą
        """
        import uuid

        embedding = await anyio.to_thread.run_sync(self._get_embedding, invoice_text)

        record_id = uuid.uuid4().hex

        # SUPERMOC: JEDEN INSERT do DuckDB z wektorem i metadanymi
        self._conn.execute(
            """INSERT INTO vendor_embeddings
               (id, vendor_nip, embedding, category_code, amount_net,
                invoice_text, transaction_id)
               VALUES (?, ?, ?::FLOAT[768], ?, ?, ?, ?)""",
            (
                record_id,
                vendor_nip,
                embedding,
                category_code,
                float(amount_net),
                invoice_text[:5000],
                transaction_id,
            ),
        )

        logger.info(
            "[SemanticGuard] Stored invoice %s for vendor %s (cat=%s, net=%.2f) [DuckDB VSS]",
            transaction_id,
            vendor_nip,
            category_code,
            float(amount_net),
        )
        invalidate_semantic_guard_cache()
