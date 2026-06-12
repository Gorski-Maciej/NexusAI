"""
SemanticGuard — semantyczny wykrywacz anomalii faktur.

Zgodnie z aa3fvcx.txt:
- Używa sqlite-vec (Punkt 3) do wyszukiwania wektorowego
- Używa llama-cpp-python do embeddingów (technologia ze stacku)
- Nie używa agentów AI, protokołów ani specyficznych modeli LLM
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.core.cache import get_cache
from nexus_ai.core.embeddings import get_embedding_service
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.vector_store import VectorStore

# ── SHA-256 przez nexus-crypto (Rust+PyO3) z fallback do hashlib ────────
try:
    from nexus_crypto import sha256 as _text_hash
except ImportError:
    import hashlib as _hl

    def _text_hash(data: bytes) -> str:
        return _hl.sha256(data).hexdigest()


# NexusCache dla wyników evaluate() (L1 RAM + L2 SQLite przez dyscache)
# Klucz: semantic_eval:{vendor_nip}:{amount_net}:{sha256(invoice_text)} → dict
# TTL: 3600s (1h) — wynik zależy od wszystkich trzech parametrów
# Oszczędza ~55-220ms przy retry/reprocess tej samej faktury
_semantic_eval_cache = get_cache()

# Prefixy cache dla event-based invalidation
# store_invoice() woła invalidate_semantic_guard_cache() po zapisie nowej faktury
# → następne evaluate() ładuje świeże dane z sqlite-vec
SEMANTIC_CACHE_PREFIXES = ["semantic_eval:"]


def invalidate_semantic_guard_cache() -> None:
    """Event-based cache invalidation dla SemanticGuard.

    Czyści wszystkie cache'owane wyniki ``evaluate()`` przez L1 RAM
    ``delete_prefix_sync("semantic_eval:")``.

    Wywoływane przez ``store_invoice()`` — po zapisie nowej faktury
    historia vector search się zmienia, więc cache'owane wyniki
    ``evaluate()`` stają się nieaktualne.

    Wzorzec identyczny z:
    - ``DecisionEngine.invalidate_rules_cache()``
    - ``RiskGuard.invalidate_risk_cache()``
    - ``ForexEngine.invalidate_forex_cache()``
    """
    _semantic_eval_cache.delete_prefix_sync("semantic_eval:")


logger = get_logger("nexus.services.semantic_guard")

# ── Anomaly rules (inline, bez DuckDB — zgodnie z aa3fvcx.txt minimalizm) ──

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


# ── SemanticGuard ────────────────────────────────────────────────────────────


class SemanticGuard:
    """Detektor anomalii semantycznych oparty o sqlite-vec i embeddingi.

    Zgodnie z aa3fvcx.txt:
    - sqlite-vec do przechowywania i wyszukiwania wektorów
    - llama-cpp-python do generowania embeddingów
    - Bez agentów AI, bez protokołów, bez specyficznych modeli
    """

    EMBEDDING_DIM = 768

    def __init__(
        self,
        db_path: str = "app_data/semantic_guard.db",
    ) -> None:
        self._db_path = db_path
        self._store: VectorStore | None = None
        self._embedding_service = get_embedding_service()
        self._embedding_dim: int = self.EMBEDDING_DIM

    def _init_store(self) -> VectorStore:
        """Lazy init sqlite-vec VectorStore."""
        if self._store is not None:
            return self._store
        Path(self._db_path).parent.mkdir(parents=True, exist_ok=True)
        self._store = VectorStore(self._db_path)
        self._ensure_vendor_table()
        return self._store

    def _ensure_vendor_table(self) -> None:
        """Create vendor_invoices table if not exists."""
        conn = self._init_store()._get_conn()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS vendor_invoices (
                id               TEXT PRIMARY KEY,
                vendor_nip       TEXT NOT NULL,
                embedding        BLOB NOT NULL,
                category_code    TEXT DEFAULT '',
                amount_net       REAL DEFAULT 0.0,
                invoice_text     TEXT DEFAULT '',
                transaction_id   TEXT DEFAULT '',
                timestamp        TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.commit()

    def _get_embedding(self, text: str) -> list[float]:
        """Generate embedding vector from text using llama-cpp-python."""
        vec = self._embedding_service.embed(text)
        self._embedding_dim = len(vec)
        return vec

    def evaluate(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
    ) -> dict[str, Any]:
        """Evaluate invoice for semantic anomalies.

        Wynik cache'owany w NexusCache (``semantic_eval:{vendor_nip}:{sha256(invoice_text)}``)
        przez 3600s. Oszczędza ~55-220ms przy retry/reprocess tej samej faktury.

        Args:
            invoice_text: Pełny tekst faktury (po OCR).
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto faktury.

        Returns:
            Dict z polami:
                - action: ALLOW | WARN | BLOCK_DECREE
                - anomaly_score: float (0.0 = normal, 1.0 = highly anomalous)
                - alert: str | None
        """
        # Sprawdź NexusCache (L1 RAM) — szybki path, oszczędza ~55-220ms
        eval_cache_key = (
            f"semantic_eval:{vendor_nip}:{amount_net}:{_text_hash(invoice_text.encode())}"
        )
        cached = _semantic_eval_cache.get_sync(eval_cache_key)
        if cached is not None:
            logger.debug("[SemanticGuard] evaluate cache HIT for vendor=%s", vendor_nip)
            return cached

        embedding = self._get_embedding(invoice_text)
        store = self._init_store()
        conn = store._get_conn()
        query_blob = store._vector_to_blob(embedding)

        # Query historical vendor invoices using sqlite-vec cosine distance
        try:
            rows = conn.execute(
                """SELECT *, vec_distance_cosine(embedding, ?) AS _distance
                   FROM vendor_invoices
                   WHERE vendor_nip = ?
                   ORDER BY _distance ASC
                   LIMIT 5""",
                (query_blob, vendor_nip),
            ).fetchall()
        except Exception:
            rows = []

        # Calculate anomaly score
        if rows:
            distances = [float(r["_distance"]) for r in rows]
            anomaly_score = sum(distances) / len(distances)
        else:
            anomaly_score = 0.0  # New vendor — no history

        # Check against anomaly rules
        action = "ALLOW"
        alert = None

        # Sprawdź reguły anomalii (inline, zgodnie z aa3fvcx.txt minimalizm)
        for rule in ANOMALY_RULES:
            if anomaly_score >= rule["min_score"] and amount_net >= rule["min_amount"]:
                action = rule["action"]
                alert = rule["alert"]
                break

        return {
            "action": action,
            "anomaly_score": round(anomaly_score, 4),
            "alert": alert,
        }

    def store_invoice(
        self,
        vendor_nip: str,
        invoice_text: str,
        category_code: str = "",
        amount_net: float = 0.0,
        transaction_id: str = "",
    ) -> None:
        """Store verified invoice in sqlite-vec for future anomaly detection."""
        import uuid

        embedding = self._get_embedding(invoice_text)
        store = self._init_store()
        conn = store._get_conn()

        conn.execute(
            """INSERT INTO vendor_invoices
               (id, vendor_nip, embedding, category_code, amount_net, invoice_text, transaction_id, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                uuid.uuid4().hex,
                vendor_nip,
                store._vector_to_blob(embedding),
                category_code,
                float(amount_net),
                invoice_text[:5000],
                transaction_id,
                pendulum.now("UTC").isoformat(),
            ),
        )
        conn.commit()
        logger.info(
            "[SemanticGuard] Stored invoice %s for vendor %s (cat=%s, net=%.2f)",
            transaction_id,
            vendor_nip,
            category_code,
            float(amount_net),
        )
        # Event-based cache invalidation — po zapisie nowej faktury
        # historia vector search się zmienia; następne evaluate()
        # dla tego vendora załaduje świeże dane z sqlite-vec.
        invalidate_semantic_guard_cache()
