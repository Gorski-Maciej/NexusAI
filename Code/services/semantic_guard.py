"""
SemanticGuard — semantyczny wykrywacz anomalii faktur.

Część VI drugiej połowy szkieletu.

Wykorzystuje LanceDB do przechowywania embeddingów faktur
i HerBERT (via sentence-transformers) do wektoryzacji tekstu.

Wykrywa:
  - „Puste faktury” (treść nie odpowiada kwocie)
  - Drastyczne zmiany profilu usług kontrahenta
"""

from __future__ import annotations

import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger("nexus.services.semantic_guard")

# LanceDB & sentence-transformers są importowane leniwie (lazy).
# Testy używają mock/fake zamiast prawdziwych zależności.

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
        "condition_json": json.dumps({"min_anomaly_score": 0.80, "min_amount_net": 10000}),
        "action_json": json.dumps({
            "action": "BLOCK_DECREE",
            "alert": "Drastyczna zmiana profilu usług. Wymagany dowód wykonania usługi i ręczna weryfikacja.",
            "routing": "HUMAN_VERIFICATION",
        }),
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": json.dumps({"min_anomaly_score": 0.60, "min_amount_net": 10000}),
        "action_json": json.dumps({
            "action": "WARN",
            "alert": "Znacząca zmiana profilu usług. Zalecana weryfikacja.",
        }),
        "valid_from": "2024-01-01",
        "priority": 20,
    },
    {
        "condition_json": json.dumps({"min_anomaly_score": 0.40, "min_amount_net": 50000}),
        "action_json": json.dumps({
            "action": "WARN",
            "alert": "Nietypowa wartość faktury względem historii. Wymagany nadzór.",
        }),
        "valid_from": "2024-01-01",
        "priority": 30,
    },
    {
        "condition_json": json.dumps({"min_anomaly_score": 0.0, "min_amount_net": 0}),
        "action_json": json.dumps({
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

    Args:
        lancedb_path: Ścieżka do lokalnej bazy LanceDB.
        conn: DuckDB connection dla anomaly_rules.
    """

    EMBEDDING_DIM = 768  # Default for HerBERT; detected dynamically at model load

    def __init__(
        self,
        lancedb_path: str = "nexus_lancedb",
        conn: Any = None,
    ) -> None:
        self._lancedb_path = lancedb_path
        self._conn = conn
        self._db = None
        self._model = None
        self._embedding_dim: int = self.EMBEDDING_DIM

    def _init_lancedb(self) -> Any:
        """Lazy init LanceDB."""
        if self._db is None:
            import lancedb
            self._db = lancedb.connect(self._lancedb_path, mode="file")
            self._ensure_vendor_table()
        return self._db

    def _ensure_vendor_table(self) -> None:
        """Create vendor_invoices table if not exists.
        Uses self._embedding_dim for the vector dimension.
        """
        import pyarrow as pa
        table_name = "vendor_invoices"
        if table_name not in self._db.table_names():
            schema = pa.schema([
                pa.field("vendor_nip", pa.string()),
                pa.field("embedding", pa.list_(pa.float32(), self._embedding_dim)),
                pa.field("category_code", pa.string()),
                pa.field("amount_net", pa.float64()),
                pa.field("invoice_text", pa.string()),
                pa.field("transaction_id", pa.string()),
                pa.field("timestamp", pa.timestamp("us", tz="UTC")),
            ])
            self._db.create_table(table_name, schema=schema)
            logger.info(
                "[SemanticGuard] Created vendor_invoices table (dim=%d)",
                self._embedding_dim,
            )
        else:
            # Log warning if existing table dimension doesn't match current model
            existing_schema = self._db.open_table(table_name).schema
            try:
                existing_dim = existing_schema.field("embedding").type.value_type.size or 0
                if existing_dim != self._embedding_dim:
                    logger.warning(
                        "[SemanticGuard] Table dim mismatch: existing=%d, model=%d",
                        existing_dim,
                        self._embedding_dim,
                    )
            except Exception:
                pass

    def _get_embedding(self, text: str) -> list[float]:
        """Generate embedding vector from text using sentence-transformers."""
        if self._model is None:
            try:
                from sentence_transformers import SentenceTransformer
                try:
                    # Preferowany model: HerBERT (polski, 768-dim)
                    self._model = SentenceTransformer("sdadas/herbert-base-embedding")
                    self._embedding_dim = 768
                except Exception:
                    # Fallback: all-MiniLM-L6-v2 (angielski, 384-dim — gorszy dla PL)
                    logger.warning("[SemanticGuard] HerBERT unavailable, falling back to all-MiniLM-L6-v2")
                    self._model = SentenceTransformer("all-MiniLM-L6-v2")
                    self._embedding_dim = 384
            except Exception as exc:
                logger.warning("[SemanticGuard] sentence-transformers unavailable: %s", exc)
                # Fallback: deterministic pseudo-embedding (use detected dimension)
                return [0.0] * self._embedding_dim

        # Preferowany model: sdadas/herbert-base-embedding (768-dim, polski)
        # Fallback: all-MiniLM-L6-v2 (384-dim)
        try:
            return self._model.encode(text[:10000]).tolist()  # Truncate long texts
        except Exception as exc:
            logger.warning("[SemanticGuard] Embedding failed: %s — fallback to zero vector", exc)
            return [0.0] * 768

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
        # 1. Generate embedding
        embedding = self._get_embedding(invoice_text)

        # 2. Query historical vendor invoices
        db = self._init_lancedb()
        table_name = "vendor_invoices"

        if table_name not in db.table_names():
            return {"action": "ALLOW", "anomaly_score": 0.0, "alert": None}

        table = db.open_table(table_name)
        try:
            results = (
                table.search(embedding)
                .where(f"vendor_nip = '{vendor_nip}'")
                .limit(5)
                .to_list()
            )
        except Exception:
            results = []

        # 3. Calculate anomaly score
        if not results:
            anomaly_score = 0.0  # New vendor — no history
        else:
            distances = [r.get("_distance", 1.0) for r in results]
            anomaly_score = sum(distances) / len(distances)

        # 4. Check against anomaly rules
        action = "ALLOW"
        alert = None

        if self._conn is not None:
            import duckdb
            rows = self._conn.execute(
                """SELECT condition_json, action_json, priority
                   FROM anomaly_rules
                   WHERE valid_from <= CURRENT_DATE
                     AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
                   ORDER BY priority ASC""",
            ).fetchall()

            for cond_json, act_json, priority in rows:
                try:
                    cond = json.loads(cond_json) if isinstance(cond_json, str) else cond_json
                    act = json.loads(act_json) if isinstance(act_json, str) else act_json

                    min_score = float(cond.get("min_anomaly_score", 1.0))
                    min_amount = float(cond.get("min_amount_net", 0))

                    if anomaly_score >= min_score and amount_net >= min_amount:
                        action = act.get("action", "ALLOW")
                        alert = act.get("alert")
                        break
                except (json.JSONDecodeError, ValueError, TypeError):
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
        """Store verified invoice in LanceDB for future anomaly detection (Active Learning).

        Args:
            vendor_nip: NIP kontrahenta.
            invoice_text: Pełny tekst faktury (po OCR).
            category_code: Kod kategorii wydatku.
            amount_net: Kwota netto w złotych.
            transaction_id: UUID faktury (do powiązania z bazą SQL).
        """
        embedding = self._get_embedding(invoice_text)
        db = self._init_lancedb()
        table = db.open_table("vendor_invoices")

        record = {
            "vendor_nip": vendor_nip,
            "embedding": embedding,
            "category_code": category_code,
            "amount_net": float(amount_net),
            "invoice_text": invoice_text[:5000],  # Store summary
            "transaction_id": transaction_id,
            "timestamp": datetime.now(timezone.utc),
        }
        table.add([record])
        logger.info("[SemanticGuard] Stored invoice %s for vendor %s (cat=%s, net=%.2f)",
                     transaction_id, vendor_nip, category_code, float(amount_net))
