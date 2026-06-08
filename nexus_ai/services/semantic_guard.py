"""
SemanticGuard — semantyczny wykrywacz anomalii faktur.

Zgodnie z aa3fvcx.txt:
- LanceDB → sqlite-vec (wektory w SQLite)
- sentence-transformers → llama-cpp-python embedding (technologia ze stacku)
- EmbeddingService używa istniejących modeli GGUF (np. Qwen3-0.6B)
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.core.embeddings import get_embedding_service
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_dumps, msgspec_loads
from nexus_ai.db.vector_store import VectorStore

logger = get_logger("nexus.services.semantic_guard")

# ── Anomaly rules schema ────────────────────────────────────────────────────

ANOMALY_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS anomaly_rules (
    rule_id       VARCHAR PRIMARY KEY,
    condition_json VARCHAR NOT NULL,
    action_json   VARCHAR NOT NULL,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    priority      INTEGER NOT NULL DEFAULT 100,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_anomaly_rules_valid
    ON anomaly_rules(valid_from, valid_to, priority);
"""

DEFAULT_ANOMALY_RULES: list[dict[str, Any]] = [
    {
        "condition_json": msgspec_dumps({"min_anomaly_score": 0.80, "min_amount_net": 10000}),
        "action_json": msgspec_dumps({
            "action": "BLOCK_DECREE",
            "alert": "Drastyczna zmiana profilu usług. Wymagany dowód wykonania usługi i ręczna weryfikacja.",
            "routing": "HUMAN_VERIFICATION",
        }),
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": msgspec_dumps({"min_anomaly_score": 0.60, "min_amount_net": 10000}),
        "action_json": msgspec_dumps({
            "action": "WARN",
            "alert": "Znacząca zmiana profilu usług. Zalecana weryfikacja.",
        }),
        "valid_from": "2024-01-01",
        "priority": 20,
    },
    {
        "condition_json": msgspec_dumps({"min_anomaly_score": 0.40, "min_amount_net": 50000}),
        "action_json": msgspec_dumps({
            "action": "WARN",
            "alert": "Nietypowa wartość faktury względem historii. Wymagany nadzór.",
        }),
        "valid_from": "2024-01-01",
        "priority": 30,
    },
    {
        "condition_json": msgspec_dumps({"min_anomaly_score": 0.0, "min_amount_net": 0}),
        "action_json": msgspec_dumps({
            "action": "ALLOW",
            "alert": None,
        }),
        "valid_from": "2024-01-01",
        "priority": 999,
    },
]


# ── SemanticGuard ────────────────────────────────────────────────────────────


class SemanticGuard:
    """Detektor anomalii semantycznych oparty o embeddingi faktur.

    Używa sqlite-vec (zamiast LanceDB) i llama-cpp-python embedding
    (zamiast sentence-transformers) zgodnie z aa3fvcx.txt.
    """

    EMBEDDING_DIM = 768  # Domyślny wymiar; wykrywany dynamicznie z modelu

    def __init__(
        self,
        db_path: str = "app_data/semantic_guard.db",
        conn: Any = None,
    ) -> None:
        self._db_path = db_path
        self._conn = conn
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
        """Generate embedding vector from text using llama-cpp-python.

        Zgodnie z aa3fvcx.txt: sentence-transformers → llama-cpp-python embedding.
        Używa istniejącego modelu GGUF (Qwen3-0.6B) z flagą embedding=True.
        """
        vec = self._embedding_service.embed(text)
        # Dynamicznie dopasuj wymiar
        self._embedding_dim = len(vec)
        return vec

    def evaluate(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
    ) -> dict[str, Any]:
        """Evaluate invoice for semantic anomalies.

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

        if self._conn is not None:
            db_rows = self._conn.execute(
                """SELECT condition_json, action_json, priority
                   FROM anomaly_rules
                   WHERE valid_from <= CURRENT_DATE
                     AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
                   ORDER BY priority ASC""",
            ).fetchall()

            for cond_json, act_json, priority in db_rows:
                try:
                    cond = msgspec_loads(cond_json) if isinstance(cond_json, str) else cond_json
                    act = msgspec_loads(act_json) if isinstance(act_json, str) else act_json

                    min_score = float(cond.get("min_anomaly_score", 1.0))
                    min_amount = float(cond.get("min_amount_net", 0))

                    if anomaly_score >= min_score and amount_net >= min_amount:
                        action = act.get("action", "ALLOW")
                        alert = act.get("alert")
                        break
                except (DecodeError, ValueError, TypeError):
                    continue

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
        """Store verified invoice in sqlite-vec for future anomaly detection.

        Args:
            vendor_nip: NIP kontrahenta.
            invoice_text: Pełny tekst faktury (po OCR).
            category_code: Kod kategorii wydatku.
            amount_net: Kwota netto w złotych.
            transaction_id: UUID faktury (do powiązania z bazą SQL).
        """
        import uuid
        embedding = self._get_embedding(invoice_text)
        store = self._init_store()
        conn = store._get_conn()

        conn.execute(
            """INSERT INTO vendor_invoices
               (id, vendor_nip, embedding, category_code, amount_net, invoice_text, transaction_id, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                str(uuid.uuid4()),
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
            transaction_id, vendor_nip, category_code, float(amount_net),
        )
