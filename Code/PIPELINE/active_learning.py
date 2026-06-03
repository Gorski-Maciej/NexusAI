"""
ActiveLearningEngine — consolidated Active Learning module.

Integruje trzy komponenty w jeden, spójny moduł:

  1. **LanceDB Vector Store**  — przechowuje embeddingi faktur i korekt OCR
  2. **Field Confidence**      — śledzi pewność odczytu per-field z OCR/AI
  3. **Anomaly Detection**     — semantyczne wykrywanie anomalii (dawny SemanticGuard)

Zgodność wsteczna:
  - ``get_suggested_correction()`` — nazwa używana przez pipeline/parser.py
  - ``get_history_for_nip()``      — nazwa używana przez pipeline/parser.py
  - ``register_correction()``      — nazwa używana przez services/active_learning.py
  - ``record_active_learning_example()`` — nazwa używana przez tax/pipeline.py

Usage:
    engine = ActiveLearningEngine(lancedb_path="nexus_lancedb")
    suggestion = await engine.get_suggested_correction(raw_text, "1234567890")
    await engine.save_correction(raw_text, "1234567890", corrections)
    anomaly = engine.evaluate_anomaly(invoice_text, "1234567890", 1234.00)
"""

from __future__ import annotations

import hashlib
import json
import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Callable

import numpy as np

logger = logging.getLogger("nexus.pipeline.active_learning")

# ── Lazy imports ────────────────────────────────────────────────────────────

try:
    import lancedb
except ImportError:
    lancedb = None  # type: ignore[assignment]

try:
    import pyarrow as pa
except ImportError:
    pa = None  # type: ignore[assignment]

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    SentenceTransformer = None  # type: ignore[assignment]

try:
    from cachetools import TTLCache
except ImportError:
    # Fallback: simple dict-based cache
    class TTLCache(dict):  # type: ignore[no-redef]
        def __init__(self, maxsize: int = 500, ttl: int = 3600) -> None:
            super().__init__()
            self._maxsize = maxsize
            self._ttl = ttl
            self._timestamps: dict[str, float] = {}

        def __getitem__(self, key: str) -> Any:
            ts = self._timestamps.get(key)
            if ts is not None and (datetime.now().timestamp() - ts) > self._ttl:
                del self._timestamps[key]
                super().__delitem__(key)
                raise KeyError(key)
            return super().__getitem__(key)

        def get(self, key: str, default: Any = None) -> Any:  # type: ignore[override]
            try:
                return self[key]
            except KeyError:
                return default

        def __setitem__(self, key: str, value: Any) -> None:
            self._timestamps[key] = datetime.now().timestamp()
            super().__setitem__(key, value)
            if len(self) > self._maxsize:
                # Remove oldest entry
                oldest = min(self._timestamps, key=lambda k: self._timestamps[k])
                del self._timestamps[oldest]
                super().__delitem__(oldest)


# ── Constants ───────────────────────────────────────────────────────────────

CORRECTIONS_TABLE = "ocr_corrections"
"""LanceDB table for OCR correction patterns."""

INVOICES_TABLE = "vendor_invoices"
"""LanceDB table for verified vendor invoices (anomaly detection)."""

DEFAULT_EMBEDDING_DIM = 384
"""Default embedding dimension (all-MiniLM-L6-v2)."""

HERBERT_EMBEDDING_DIM = 768
"""Embedding dimension for HerBERT (sdadas/herbert-base-embedding)."""

DEFAULT_BATCH_MAX_SIZE = 100
"""Max corrections in a single batch flush."""

DEFAULT_CACHE_MAXSIZE = 500
"""Max entries in LRU suggestion cache."""

DEFAULT_CACHE_TTL = 3600
"""TTL for cached suggestions (seconds)."""

ANOMALY_PROXIMITY_THRESHOLD = 0.10
"""Max cosine distance for a suggestion to be considered relevant."""

DEFAULT_ANOMALY_RULES: list[dict[str, Any]] = [
    {
        "min_anomaly_score": 0.80,
        "min_amount_net": 10000,
        "action": "BLOCK_DECREE",
        "alert": "Drastyczna zmiana profilu usług. Wymagany dowód wykonania usługi i ręczna weryfikacja.",
    },
    {
        "min_anomaly_score": 0.60,
        "min_amount_net": 10000,
        "action": "WARN",
        "alert": "Znacząca zmiana profilu usług. Zalecana weryfikacja.",
    },
    {
        "min_anomaly_score": 0.40,
        "min_amount_net": 50000,
        "action": "WARN",
        "alert": "Nietypowa wartość faktury względem historii. Wymagany nadzór.",
    },
    {
        "min_anomaly_score": 0.0,
        "min_amount_net": 0,
        "action": "ALLOW",
        "alert": None,
    },
]


# ── Data structures ─────────────────────────────────────────────────────────


@dataclass(frozen=True)
class FieldConfidence:
    """Pewność odczytu pojedynczego pola faktury.

    Attributes:
        value: Wartość pola (str, Decimal, float, int, bool).
        confidence: Poziom pewności od 0.0 do 1.0.
        source: Źródło odczytu (np. "surya_ocr", "paddle_ocr", "llm", "regex").
    """

    value: Any
    confidence: float
    source: str = "unknown"

    def __post_init__(self) -> None:
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(
                f"Confidence must be in [0.0, 1.0], got {self.confidence}"
            )

    def is_reliable(self, threshold: float = 0.85) -> bool:
        """Czy pole można uznać za wiarygodne powyżej zadanego progu."""
        return self.confidence >= threshold

    def to_dict(self) -> dict[str, Any]:
        """Serialize to dict for JSON storage."""
        from decimal import Decimal
        value = str(self.value) if isinstance(self.value, Decimal) else self.value
        return {"value": value, "confidence": self.confidence, "source": self.source}


FieldConfidenceDict = dict[str, FieldConfidence]
"""Słownik mapujący nazwę pola na FieldConfidence."""


@dataclass
class AnomalyResult:
    """Wynik oceny semantycznej faktury.

    Attributes:
        action: ALLOW | WARN | BLOCK_DECREE
        anomaly_score: float (0.0 = normal, 1.0 = highly anomalous)
        alert: str | None
    """

    action: str = "ALLOW"
    anomaly_score: float = 0.0
    alert: str | None = None


# ── Field Confidence helpers ────────────────────────────────────────────────


def field_confidence_from_dict(data: dict[str, dict[str, Any]]) -> FieldConfidenceDict:
    """Utwórz FieldConfidenceDict z surowego słownika."""
    result: FieldConfidenceDict = {}
    for field_name, item in data.items():
        if not isinstance(item, dict):
            raise ValueError(
                f"Invalid field_confidence entry for {field_name!r}: "
                f"expected dict, got {type(item).__name__}"
            )
        if "value" not in item:
            raise ValueError(f"Missing 'value' in field_confidence entry for {field_name!r}")
        if "confidence" not in item:
            raise ValueError(f"Missing 'confidence' in field_confidence entry for {field_name!r}")
        result[field_name] = FieldConfidence(
            value=item["value"],
            confidence=float(item["confidence"]),
            source=str(item.get("source", "unknown")),
        )
    return result


def fields_below_threshold(
    fc: FieldConfidenceDict,
    threshold: float = 0.85,
) -> list[tuple[str, float]]:
    """Zwróć listę pól, których confidence jest poniżej progu.

    Returns:
        Lista (nazwa_pola, confidence) dla pól poniżej progu.
    """
    return [(name, conf.confidence) for name, conf in fc.items() if conf.confidence < threshold]


def minimum_confidence(fc: FieldConfidenceDict) -> float:
    """Zwróć najniższy confidence spośród wszystkich pól (1.0 jeśli słownik pusty)."""
    if not fc:
        return 1.0
    return min(conf.confidence for conf in fc.values())


# ── ActiveLearningEngine ────────────────────────────────────────────────────


class ActiveLearningEngine:
    """Consolidated Active Learning Engine.

    Integruje LanceDB, field_confidence i SemanticGuard w jednym module.

    Args:
        lancedb_path: Ścieżka do lokalnej bazy LanceDB.
        embedding_model: Nazwa modelu sentence-transformers.
        batch_max_size: Maksymalny rozmiar batcha przed flush.
        cache_maxsize: Maksymalna liczba wpisów w LRU cache.
        cache_ttl: TTL dla cache'owanych sugestii (sekundy).
        on_error: Opcjonalny callback wywoływany przy błędach LanceDB.
        duckdb_conn: Opcjonalne połączenie DuckDB dla statystyk i anomaly_rules.
    """

    def __init__(
        self,
        lancedb_path: str = "nexus_lancedb",
        embedding_model: str = "all-MiniLM-L6-v2",
        *,
        batch_max_size: int = DEFAULT_BATCH_MAX_SIZE,
        cache_maxsize: int = DEFAULT_CACHE_MAXSIZE,
        cache_ttl: int = DEFAULT_CACHE_TTL,
        on_error: Callable[[str, Exception], Any] | None = None,
        duckdb_conn: Any = None,
    ) -> None:
        self._lancedb_path = lancedb_path
        self._embedding_model_name = embedding_model
        self._batch_max_size = batch_max_size
        self._on_error = on_error
        self._duckdb_conn = duckdb_conn

        # Lazy-init at first use
        self._db: Any = None
        self._model: Any = None
        self._embedding_dim: int = DEFAULT_EMBEDDING_DIM
        self._batch_buffer: list[dict[str, Any]] = []
        self._suggestion_cache: TTLCache = TTLCache(maxsize=cache_maxsize, ttl=cache_ttl)

    # ── Initialization ────────────────────────────────────────────────

    def _init_lancedb(self) -> Any:
        """Lazy init LanceDB connection."""
        if self._db is not None:
            return self._db
        if lancedb is None:
            raise RuntimeError("lancedb is not installed. Run: pip install lancedb")
        self._db = lancedb.connect(self._lancedb_path, mode="file")
        return self._db

    def _ensure_corrections_table(self) -> None:
        """Create ocr_corrections table if not exists."""
        if pa is None:
            raise RuntimeError("pyarrow is not installed. Run: pip install pyarrow")

        db = self._init_lancedb()
        if CORRECTIONS_TABLE not in db.table_names():
            schema = pa.schema([
                pa.field("vector", pa.list_(pa.float16(), self._embedding_dim)),
                pa.field("contractor_nip", pa.string()),
                pa.field("correction_payload", pa.string()),
                pa.field("context_hash", pa.string()),
                pa.field("tenant_id", pa.string()),
                pa.field("created_at", pa.timestamp("us", tz="UTC")),
            ])
            db.create_table(CORRECTIONS_TABLE, schema=schema)
            logger.info(
                "[ACTIVE-LEARNING] Created %s table (dim=%d)",
                CORRECTIONS_TABLE, self._embedding_dim,
            )

    def _ensure_invoices_table(self) -> None:
        """Create vendor_invoices table if not exists (for anomaly detection)."""
        if pa is None:
            raise RuntimeError("pyarrow is not installed")

        db = self._init_lancedb()
        if INVOICES_TABLE not in db.table_names():
            schema = pa.schema([
                pa.field("vendor_nip", pa.string()),
                pa.field("embedding", pa.list_(pa.float32(), self._embedding_dim)),
                pa.field("category_code", pa.string()),
                pa.field("amount_net", pa.float64()),
                pa.field("invoice_text", pa.string()),
                pa.field("transaction_id", pa.string()),
                pa.field("timestamp", pa.timestamp("us", tz="UTC")),
            ])
            db.create_table(INVOICES_TABLE, schema=schema)
            logger.info(
                "[ACTIVE-LEARNING] Created %s table (dim=%d)",
                INVOICES_TABLE, self._embedding_dim,
            )

    def _get_model(self) -> Any:
        """Lazy-load sentence-transformers model."""
        if self._model is not None:
            return self._model

        if SentenceTransformer is not None:
            try:
                self._model = SentenceTransformer(self._embedding_model_name)
            except Exception:
                try:
                    # Fallback: HerBERT (polski embedding)
                    logger.warning(
                        "[ACTIVE-LEARNING] %s unavailable, trying HerBERT",
                        self._embedding_model_name,
                    )
                    self._model = SentenceTransformer("sdadas/herbert-base-embedding")
                    self._embedding_dim = HERBERT_EMBEDDING_DIM
                except Exception as exc:
                    logger.warning(
                        "[ACTIVE-LEARNING] sentence-transformers unavailable: %s", exc,
                    )
                    self._model = None
        else:
            logger.warning("[ACTIVE-LEARNING] sentence-transformers not installed")
            self._model = None

        return self._model

    # ── Embedding ────────────────────────────────────────────────────

    def _generate_embedding(self, text: str) -> list[float]:
        """Generate embedding vector from text."""
        model = self._get_model()
        if model is not None:
            try:
                return model.encode(text[:10000]).tolist()
            except Exception as exc:
                logger.warning("[ACTIVE-LEARNING] Embedding failed: %s", exc)
        # Fallback: zero vector
        return [0.0] * self._embedding_dim

    @staticmethod
    def _to_float16(vector: list[float]) -> list[float]:
        """Convert vector to float16 for memory efficiency."""
        return np.array(vector, dtype=np.float16).tolist()

    @staticmethod
    def _sanitize_lancedb(value: str) -> str:
        """Sanitize string for LanceDB WHERE clause (SQL injection prevention)."""
        return value.replace("'", "''").replace(";", "")

    @staticmethod
    def _get_cache_key(raw_text: str, nip: str, tenant_id: str = "") -> str:
        """Generate cache key for suggestions."""
        combined = f"{nip}:{tenant_id}:{raw_text[:200]}"
        return hashlib.md5(combined.encode()).hexdigest()

    @staticmethod
    def _get_context_hash(raw_text: str) -> str:
        """Generate context hash for deduplication."""
        return hashlib.md5(raw_text.encode()).hexdigest()

    # ── Corrections API ──────────────────────────────────────────────

    async def save_correction(
        self,
        raw_text: str,
        nip: str,
        corrections: dict[str, Any],
        tenant_id: str = "default",
    ) -> None:
        """Zapisz poprawkę użytkownika do bazy wektorowej z batchowaniem.

        Args:
            raw_text: Surowy tekst faktury.
            nip: NIP kontrahenta.
            corrections: Słownik poprawek (field → corrected_value).
            tenant_id: Identyfikator tenanta (dla izolacji danych).
        """
        vector = self._generate_embedding(raw_text)
        vector_f16 = self._to_float16(vector)

        data = {
            "vector": vector_f16,
            "contractor_nip": nip,
            "correction_payload": json.dumps(corrections, ensure_ascii=False),
            "context_hash": self._get_context_hash(raw_text),
            "tenant_id": tenant_id,
            "created_at": datetime.now(timezone.utc),
        }

        self._batch_buffer.append(data)

        # Auto-flush gdy batch osiągnie maksymalny rozmiar
        if len(self._batch_buffer) >= self._batch_max_size:
            await self.flush_batch()

    async def flush_batch(self) -> int:
        """Wymuś zapis buforowanych korekt w jednej transakcji wsadowej.

        Returns:
            Liczba zapisanych rekordów.
        """
        if not self._batch_buffer:
            return 0

        batch = self._batch_buffer[:]
        self._batch_buffer = []

        try:
            db = self._init_lancedb()
            self._ensure_corrections_table()
            table = db.open_table(CORRECTIONS_TABLE)
            table.add(batch)
            logger.info("[ACTIVE-LEARNING] Flushed batch of %d corrections", len(batch))
            return len(batch)
        except Exception as exc:
            logger.error("[ACTIVE-LEARNING] Batch flush failed: %s", exc)
            # Przywróć bufor w razie błędu
            self._batch_buffer = batch + self._batch_buffer
            if self._on_error is not None:
                self._on_error("flush_batch", exc)
            raise

    @property
    def pending_count(self) -> int:
        """Liczba korekt oczekujących w buforze na zapis."""
        return len(self._batch_buffer)

    async def get_suggestion(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Szukaj w bazie wektorowej podobnego układu dla danego NIP-u i tenanta.

        Args:
            raw_text: Surowy tekst faktury.
            nip: NIP kontrahenta.
            tenant_id: Identyfikator tenanta.

        Returns:
            Słownik z poprawkami (correction_payload) lub None.
        """
        # Sprawdź cache
        cache_key = self._get_cache_key(raw_text, nip, tenant_id)
        cached = self._suggestion_cache.get(cache_key)
        if cached is not None:
            logger.debug("[ACTIVE-LEARNING] Cache hit for nip=%s tenant=%s", nip, tenant_id)
            return cached

        query_vector = self._generate_embedding(raw_text)
        query_vector_f16 = self._to_float16(query_vector)

        try:
            db = self._init_lancedb()
            self._ensure_corrections_table()

            safe_nip = self._sanitize_lancedb(nip)
            safe_tenant = self._sanitize_lancedb(tenant_id)

            table = db.open_table(CORRECTIONS_TABLE)
            results = (
                table.search(query_vector_f16)
                .where(f"contractor_nip = '{safe_nip}' AND tenant_id = '{safe_tenant}'")
                .limit(1)
                .to_list()
            )

            if results and results[0].get("_distance", 1.0) < ANOMALY_PROXIMITY_THRESHOLD:
                suggestion = json.loads(results[0]["correction_payload"])
                # Zapisz w cache
                self._suggestion_cache[cache_key] = suggestion
                return suggestion
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] get_suggestion failed: %s", exc)
            if self._on_error is not None:
                self._on_error("get_suggestion", exc)

        return None

    async def get_suggested_correction(
        self,
        raw_text: str,
        nip: str,
        tenant_id: str = "default",
    ) -> dict[str, Any] | None:
        """Alias dla ``get_suggestion`` — kompatybilność z pipeline/parser.py."""
        return await self.get_suggestion(raw_text, nip, tenant_id)

    async def get_history_for_nip(
        self,
        nip: str,
        limit: int = 10,
        tenant_id: str = "default",
    ) -> list[dict[str, Any]]:
        """Pobierz historię faktur dla danego NIP-u z LanceDB.

        Args:
            nip: NIP kontrahenta.
            limit: Maksymalna liczba wyników.
            tenant_id: Identyfikator tenanta.

        Returns:
            Lista słowników z danymi historycznymi (amount_net, category_code, ...).
        """
        try:
            db = self._init_lancedb()
            safe_nip = self._sanitize_lancedb(nip)

            if INVOICES_TABLE not in db.table_names():
                return []

            table = db.open_table(INVOICES_TABLE)
            results = (
                table.search()
                .where(f"vendor_nip = '{safe_nip}'")
                .limit(limit)
                .to_list()
            )
            # Normalizuj : dict z polami amount_net, category_code, timestamp, transaction_id
            history: list[dict[str, Any]] = []
            for r in results:
                entry = {
                    "vendor_nip": r.get("vendor_nip", nip),
                    "amount_net": r.get("amount_net", 0.0),
                    "category_code": r.get("category_code", ""),
                    "transaction_id": r.get("transaction_id", ""),
                    "timestamp": str(r.get("timestamp", "")),
                    "invoice_text": r.get("invoice_text", ""),
                }
                history.append(entry)
            return history
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] get_history_for_nip failed: %s", exc)
            if self._on_error is not None:
                self._on_error("get_history_for_nip", exc)
            return []

    # ── Anomaly Detection ────────────────────────────────────────────

    def evaluate_anomaly(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
    ) -> AnomalyResult:
        """Oceń fakturę pod kątem anomalii semantycznych.

        Args:
            invoice_text: Pełny tekst faktury (po OCR).
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto faktury.

        Returns:
            AnomalyResult z akcją, score i alertem.
        """
        if not invoice_text and not vendor_nip:
            return AnomalyResult()

        embedding = self._generate_embedding(invoice_text)

        try:
            db = self._init_lancedb()
            if INVOICES_TABLE not in db.table_names():
                return AnomalyResult()

            table = db.open_table(INVOICES_TABLE)
            try:
                results = (
                    table.search(embedding)
                    .where(f"vendor_nip = '{vendor_nip}'")
                    .limit(5)
                    .to_list()
                )
            except Exception:
                results = []

            # Calculate anomaly score
            if results:
                distances = [r.get("_distance", 1.0) for r in results]
                anomaly_score = sum(distances) / len(distances)
            else:
                anomaly_score = 0.0  # New vendor — no history

            # Apply default anomaly rules
            action = "ALLOW"
            alert: str | None = None

            for rule in DEFAULT_ANOMALY_RULES:
                min_score = float(rule.get("min_anomaly_score", 1.0))
                min_amount = float(rule.get("min_amount_net", 0))
                if anomaly_score >= min_score and amount_net >= min_amount:
                    action = rule.get("action", "ALLOW")
                    alert = rule.get("alert")
                    break

            return AnomalyResult(
                action=action,
                anomaly_score=round(anomaly_score, 4),
                alert=alert,
            )

        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] evaluate_anomaly failed: %s", exc)
            if self._on_error is not None:
                self._on_error("evaluate_anomaly", exc)
            return AnomalyResult()

    # ── Store Invoice (Active Learning feedback) ─────────────────────

    def store_invoice(
        self,
        vendor_nip: str,
        invoice_text: str,
        category_code: str = "",
        amount_net: float = 0.0,
        transaction_id: str = "",
    ) -> None:
        """Zapisz zweryfikowaną fakturę w LanceDB dla przyszłej detekcji anomalii.

        Args:
            vendor_nip: NIP kontrahenta.
            invoice_text: Pełny tekst faktury (po OCR).
            category_code: Kod kategorii wydatku.
            amount_net: Kwota netto w złotych.
            transaction_id: UUID faktury (do powiązania z bazą SQL).
        """
        try:
            embedding = self._generate_embedding(invoice_text)
            db = self._init_lancedb()
            self._ensure_invoices_table()
            table = db.open_table(INVOICES_TABLE)

            record = {
                "vendor_nip": vendor_nip,
                "embedding": embedding,
                "category_code": category_code,
                "amount_net": float(amount_net),
                "invoice_text": invoice_text[:5000],
                "transaction_id": transaction_id,
                "timestamp": datetime.now(timezone.utc),
            }
            table.add([record])
            logger.info(
                "[ACTIVE-LEARNING] Stored invoice %s for vendor %s (cat=%s, net=%.2f)",
                transaction_id, vendor_nip, category_code, float(amount_net),
            )
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] store_invoice failed: %s", exc)
            if self._on_error is not None:
                self._on_error("store_invoice", exc)

    # ── Record Example (DuckDB-based) ────────────────────────────────

    async def record_active_learning_example(
        self,
        transaction_id: str,
        original_data: dict[str, Any],
        corrected_data: dict[str, Any],
        verified_by: str = "system",
    ) -> None:
        """Zapisz przykład ręcznej korekty dla active learning.

        Zapisuje do tabeli ``active_learning_examples`` w DuckDB.

        Args:
            transaction_id: UUID transakcji.
            original_data: Surowe dane przed korektą (AI guess).
            corrected_data: Dane poprawione przez księgowego.
            verified_by: Login księgowego.
        """
        if self._duckdb_conn is None:
            logger.warning(
                "[ACTIVE-LEARNING] No DuckDB connection — cannot record example tid=%s",
                transaction_id,
            )
            return

        example_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        try:
            self._duckdb_conn.execute(
                """CREATE TABLE IF NOT EXISTS active_learning_examples (
                    example_id      VARCHAR PRIMARY KEY,
                    transaction_id  VARCHAR NOT NULL,
                    original_data   VARCHAR NOT NULL,
                    corrected_data  VARCHAR NOT NULL,
                    verified_by     VARCHAR NOT NULL,
                    verified_at     TIMESTAMP NOT NULL,
                    used_for_training BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                )"""
            )

            self._duckdb_conn.execute(
                """INSERT INTO active_learning_examples
                   (example_id, transaction_id, original_data, corrected_data,
                    verified_by, verified_at)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (
                    example_id,
                    transaction_id,
                    json.dumps(original_data, ensure_ascii=False, default=str),
                    json.dumps(corrected_data, ensure_ascii=False, default=str),
                    verified_by,
                    now,
                ),
            )
            logger.info(
                "[ACTIVE-LEARNING] Recorded correction tid=%s example_id=%s by=%s",
                transaction_id, example_id, verified_by,
            )
        except Exception as exc:
            logger.error(
                "[ACTIVE-LEARNING] Failed to record example tid=%s: %s",
                transaction_id, exc,
            )
            if self._on_error is not None:
                self._on_error("record_active_learning_example", exc)

    async def get_active_learning_stats(self) -> dict[str, Any]:
        """Statystyki active learning dla dashboardu.

        Returns:
            Dict z total_examples, unused_for_training.
        """
        if self._duckdb_conn is None:
            return {"total_examples": 0, "unused_for_training": 0}

        try:
            self._duckdb_conn.execute(
                """CREATE TABLE IF NOT EXISTS active_learning_examples (
                    example_id      VARCHAR PRIMARY KEY,
                    transaction_id  VARCHAR NOT NULL,
                    original_data   VARCHAR NOT NULL,
                    corrected_data  VARCHAR NOT NULL,
                    verified_by     VARCHAR NOT NULL,
                    verified_at     TIMESTAMP NOT NULL,
                    used_for_training BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                )"""
            )

            total = self._duckdb_conn.execute(
                "SELECT COUNT(*) FROM active_learning_examples"
            ).fetchone()
            unused = self._duckdb_conn.execute(
                "SELECT COUNT(*) FROM active_learning_examples WHERE used_for_training = FALSE"
            ).fetchone()

            return {
                "total_examples": int(total[0]) if total else 0,
                "unused_for_training": int(unused[0]) if unused else 0,
            }
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] get_stats failed: %s", exc)
            return {"total_examples": 0, "unused_for_training": 0}

    # ── Index & Maintenance ──────────────────────────────────────────

    def ensure_index(self) -> None:
        """Twórz indeks IVF dla szybszego wyszukiwania wektorowego."""
        try:
            db = self._init_lancedb()
            if CORRECTIONS_TABLE in db.table_names():
                table = db.open_table(CORRECTIONS_TABLE)
                table.create_index(
                    metric="cosine",
                    num_partitions=256,
                    num_sub_vectors=32,
                )
                logger.info("[ACTIVE-LEARNING] IVF index created for %s", CORRECTIONS_TABLE)

            if INVOICES_TABLE in db.table_names():
                table = db.open_table(INVOICES_TABLE)
                table.create_index(
                    metric="cosine",
                    num_partitions=256,
                    num_sub_vectors=32,
                )
                logger.info("[ACTIVE-LEARNING] IVF index created for %s", INVOICES_TABLE)
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] Failed to create IVF index: %s", exc)

    def optimize_storage(self) -> None:
        """Optymalizuj przechowywanie: kompaktuj pliki i czyść stare wersje."""
        try:
            db = self._init_lancedb()
            for table_name in (CORRECTIONS_TABLE, INVOICES_TABLE):
                if table_name in db.table_names():
                    table = db.open_table(table_name)
                    if hasattr(table, "compact_files"):
                        table.compact_files()
                    if hasattr(table, "cleanup_old_versions"):
                        table.cleanup_old_versions()
                    logger.info("[ACTIVE-LEARNING] Storage optimized for %s", table_name)
        except Exception as exc:
            logger.warning("[ACTIVE-LEARNING] Storage optimization failed: %s", exc)

    def close(self) -> None:
        """Zamknij bazę wektorową i wyczyść cache."""
        self._suggestion_cache.clear()
        self._batch_buffer.clear()
        logger.info(
            "[ACTIVE-LEARNING] Closed, cache cleared, buffer empty",
        )
