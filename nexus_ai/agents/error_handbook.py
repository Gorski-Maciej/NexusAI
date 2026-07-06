"""DynamicErrorHandbook — Dynamiczny Podręcznik Błędów (few-shot learning).

Technologie — wyłącznie z RAPORT_TECHNOLOGII_NEXUSAI.txt:
- DuckDB (baza analityczna)
- msgspec (struktury danych)
- sqlite-vec (embeddingi dla k-NN)
"""

from __future__ import annotations

from typing import Any

import pendulum
from msgspec import Struct, field
from structlog import get_logger

from nexus_ai.core.vectorize import execute_db, execute_db_fetchall, vectorize_text

logger = get_logger("nexus.agents.error_handbook")


# ═════════════════════════════════════════════════════════════════════════
# A. Struktury danych
# ═════════════════════════════════════════════════════════════════════════


class HandbookExample(Struct, kw_only=True):
    """Pojedynczy przykład w Podręczniku Błędów."""

    id: str
    invoice_id: str
    vendor_nip: str
    category: str = ""
    amount_gross: float = 0.0
    ai_decision: str = ""
    ai_trust_score: float = 0.0
    ai_reason: str = ""
    user_correction: str = ""
    correction_reason: str = ""
    timestamp: str = ""
    embedding: list[float] = field(default_factory=list)
    correction_count: int = 0


class HandbookQuery(Struct, kw_only=True):
    """Zapytanie do Podręcznika Błędów — przed inferencją."""

    vendor_nip: str = ""
    category: str = ""
    amount_gross: float = 0.0
    document_type: str = ""
    k: int = 3


# ═════════════════════════════════════════════════════════════════════════
# B. DynamicErrorHandbook
# ═════════════════════════════════════════════════════════════════════════


class DynamicErrorHandbook:
    """Dynamiczny Podręcznik Błędów — few-shot learning z DuckDB.

    Zapisuje każdą korektę użytkownika jako przykład few-shot.
    Przed inferencją wyszukuje najbardziej podobne przykłady.
    k-NN przez podobieństwo NIP + kategorii + przedziału kwotowego.
    """

    def __init__(self, db_path: str | None = None) -> None:
        self._db_path = db_path or "/tmp/nexus-error-handbook.db"
        self._conn: Any = None
        self._examples: dict[str, HandbookExample] = {}
        self._initialized = False

    async def initialize(self) -> None:
        """Inicjalizuj DuckDB i utwórz tabelę przykładów."""
        if self._initialized:
            return
        try:
            import duckdb
            self._conn = duckdb.connect(self._db_path)
            self._conn.execute("""CREATE TABLE IF NOT EXISTS error_handbook (
                id VARCHAR PRIMARY KEY, invoice_id VARCHAR, vendor_nip VARCHAR,
                category VARCHAR, amount_gross DOUBLE, ai_decision VARCHAR,
                ai_trust_score DOUBLE, ai_reason VARCHAR, user_correction VARCHAR,
                correction_reason VARCHAR, timestamp TIMESTAMP,
                embedding FLOAT[768], correction_count INTEGER DEFAULT 1)""")
            for idx_col in ["vendor_nip", "category", "timestamp"]:
                self._conn.execute(f"CREATE INDEX IF NOT EXISTS idx_handbook_{idx_col} ON error_handbook({idx_col})")
            self._initialized = True
            logger.info("[HANDBOOK] Initialized at %s | examples: %d", self._db_path, self.count)
        except Exception as exc:
            logger.warning("[HANDBOOK] Init failed (DuckDB not available?): %s", exc)
            self._initialized = True

    async def record_correction(
        self,
        invoice_id: str,
        vendor_nip: str,
        category: str,
        amount_gross: float,
        ai_decision: str,
        ai_trust_score: float,
        ai_reason: str,
        user_correction: str,
        correction_reason: str = "",
    ) -> HandbookExample | None:
        """Zapisz korektę jako przykład w Podręczniku Błędów."""
        import hashlib
        example_id = hashlib.sha256(f"{invoice_id}:{vendor_nip}:{user_correction}".encode()).hexdigest()[:16]

        existing = await self._find_existing(invoice_id, user_correction)
        if existing:
            await self._increment_count(existing.id)
            return existing

        embedding = vectorize_text(invoice_id, vendor_nip, category, f"{amount_gross:.2f}")
        example = HandbookExample(
            id=example_id, invoice_id=invoice_id, vendor_nip=vendor_nip,
            category=category, amount_gross=amount_gross,
            ai_decision=ai_decision, ai_trust_score=ai_trust_score, ai_reason=ai_reason,
            user_correction=user_correction, correction_reason=correction_reason,
            timestamp=pendulum.now("UTC").isoformat(),
            embedding=embedding, correction_count=1,
        )

        if self._conn:
            try:
                await execute_db(
                    self._conn,
                    "INSERT INTO error_handbook "
                    "(id, invoice_id, vendor_nip, category, amount_gross, "
                    "ai_decision, ai_trust_score, ai_reason, "
                    "user_correction, correction_reason, timestamp, "
                    "embedding, correction_count) "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (example.id, example.invoice_id, example.vendor_nip,
                     example.category, example.amount_gross, example.ai_decision,
                     example.ai_trust_score, example.ai_reason,
                     example.user_correction, example.correction_reason,
                     example.timestamp, example.embedding, example.correction_count),
                )
            except Exception as exc:
                logger.debug("[HANDBOOK] Insert failed: %s", exc)

        self._examples[example.id] = example
        logger.info("[HANDBOOK] Recorded #%d | NIP=%s | %s → %s", self.count, vendor_nip[:6], ai_decision, user_correction)
        return example

    async def query_relevant(self, query: HandbookQuery) -> list[HandbookExample]:
        """Znajdź najbardziej relewantne przykłady dla bieżącej faktury.

        Priorytetyzacja: (1) NIP+kategoria, (2) NIP, (3) kategoria+kwota, (4) ogólne.
        """
        results: list[HandbookExample] = []
        if query.vendor_nip and query.category and self._conn:
            results = await self._query_db("vendor_nip = ? AND category = ?", (query.vendor_nip, query.category), query.k)
        if len(results) < query.k and query.vendor_nip and self._conn:
            results = await self._query_db("vendor_nip = ?", (query.vendor_nip,), query.k)
        if len(results) < query.k and query.category and query.amount_gross > 0 and self._conn:
            lo, hi = query.amount_gross * 0.5, query.amount_gross * 1.5
            results = await self._query_db("category = ? AND amount_gross BETWEEN ? AND ?", (query.category, lo, hi), query.k)
        if len(results) < query.k:
            results = await self._query_db(None, None, query.k)
        results.sort(key=lambda x: x.correction_count, reverse=True)
        return results[:query.k]

    async def build_few_shot_prompt(self, query: HandbookQuery) -> str:
        """Zbuduj sekcję 'Podręcznik Błędów' do wstrzyknięcia w prompt."""
        if not self._initialized:
            await self.initialize()
        examples = await self.query_relevant(query)
        if not examples:
            return ""

        lines = [
            "\n--- PODRĘCZNIK BŁĘDÓW Z PRZESZŁOŚCI ---",
            "Ucz się na poniższych błędach i NIE popełniaj ich ponownie.\n",
        ]
        for i, ex in enumerate(examples, 1):
            nip_short = ex.vendor_nip[-4:] if len(ex.vendor_nip) >= 4 else ex.vendor_nip
            lines.extend([
                f"Przykład {i}: NIP=...{nip_short} Kategoria={ex.category} Kwota={ex.amount_gross:.2f} PLN",
                f"  ❌ BŁĘDNA decyzja AI: {ex.ai_decision} (trust: {ex.ai_trust_score:.2f})",
                f"  ✅ POPRAWNA decyzja: {ex.user_correction}",
            ])
            if ex.correction_reason:
                lines.append(f"  Powód: {ex.correction_reason}")
            lines.append(f"  (Korekta #{ex.correction_count})\n")
        lines.append("NIE POWTARZAJ tych błędów.\n")
        return "\n".join(lines)

    async def _query_db(self, where: str | None, params: tuple | None, limit: int) -> list[HandbookExample]:
        """Wykonaj kwerendę DuckDB i zwróć przykłady."""
        if not self._conn:
            return []
        try:
            sql = "SELECT id, invoice_id, vendor_nip, category, amount_gross, " \
                  "ai_decision, ai_trust_score, ai_reason, user_correction, " \
                  "correction_reason, timestamp, correction_count FROM error_handbook "
            if where:
                sql += f"WHERE {where} "
            sql += "ORDER BY timestamp DESC LIMIT ?"
            bind_params = [*(params or ()), limit]
            rows = await execute_db_fetchall(self._conn, sql, bind_params)
            return [
                HandbookExample(
                    id=str(r[0]), invoice_id=str(r[1]), vendor_nip=str(r[2]),
                    category=str(r[3]), amount_gross=float(r[4]) if r[4] else 0.0,
                    ai_decision=str(r[5]), ai_trust_score=float(r[6]) if r[6] else 0.0,
                    ai_reason=str(r[7]) if r[7] else "", user_correction=str(r[8]),
                    correction_reason=str(r[9]) if r[9] else "",
                    timestamp=str(r[10]) if r[10] else "",
                    correction_count=int(r[11]) if r[11] else 1,
                )
                for r in rows
            ]
        except Exception as exc:
            logger.debug("[HANDBOOK] Query failed: %s", exc)
            return []

    async def _find_existing(self, invoice_id: str, user_correction: str) -> HandbookExample | None:
        """Sprawdź czy korekta już istnieje."""
        if not self._conn:
            return None
        try:
            rows = await execute_db_fetchall(
                self._conn, "SELECT id FROM error_handbook WHERE invoice_id = ? AND user_correction = ?",
                (invoice_id, user_correction),
            )
            if rows:
                return self._examples.get(str(rows[0][0]))
        except Exception as exc:
            logger.debug("[HANDBOOK] Find existing failed: %s", exc)
        return None

    async def _increment_count(self, example_id: str) -> None:
        """Zwiększ licznik korekt dla istniejącego przykładu."""
        if not self._conn:
            return
        try:
            await execute_db(self._conn, "UPDATE error_handbook SET correction_count = correction_count + 1 WHERE id = ?", (example_id,))
            if example_id in self._examples:
                self._examples[example_id].correction_count += 1
        except Exception as exc:
            logger.debug("[HANDBOOK] Increment failed: %s", exc)

    async def find_similar_by_embedding(self, embedding: list[float], k: int = 5, threshold: float = 0.7) -> list[HandbookExample]:
        """Znajdź podobne przykłady przez k-NN (sqlite-vec). Fallback do cosine similarity na RAM."""
        if not self._initialized:
            await self.initialize()

        if self._conn:
            try:
                rows = await execute_db_fetchall(
                    self._conn,
                    "SELECT id, invoice_id, vendor_nip, category, amount_gross, "
                    "ai_decision, ai_trust_score, ai_reason, "
                    "user_correction, correction_reason, timestamp, correction_count "
                    "FROM error_handbook ORDER BY array_cosine_similarity(embedding, ?::FLOAT[768]) DESC LIMIT ?",
                    (embedding, k),
                )
                if rows:
                    return [
                        HandbookExample(
                            id=str(r[0]), invoice_id=str(r[1]), vendor_nip=str(r[2]),
                            category=str(r[3]), amount_gross=float(r[4]) if r[4] else 0.0,
                            ai_decision=str(r[5]), ai_trust_score=float(r[6]) if r[6] else 0.0,
                            ai_reason=str(r[7]) if r[7] else "", user_correction=str(r[8]),
                            correction_reason=str(r[9]) if r[9] else "",
                            timestamp=str(r[10]) if r[10] else "",
                            correction_count=int(r[11]) if r[11] else 1,
                        )
                        for r in rows
                    ]
            except Exception:
                pass

        scored = [(ex, sum(a * b for a, b in zip(embedding, ex.embedding, strict=True)) /
                   (sum(a * a for a in embedding) ** 0.5 * sum(b * b for b in ex.embedding) ** 0.5 + 1e-9))
                  for ex in self._examples.values() if ex.embedding and len(ex.embedding) == len(embedding)]
        scored.sort(key=lambda x: x[1], reverse=True)
        return [ex for ex, sim in scored if sim >= threshold][:k]

    @property
    def count(self) -> int:
        """Liczba przykładów w Podręczniku."""
        if self._conn:
            try:
                result = self._conn.execute("SELECT COUNT(*) FROM error_handbook").fetchone()
                return int(result[0]) if result else 0
            except Exception:
                return 0
        return len(self._examples)

    async def close(self) -> None:
        """Zamknij połączenie DuckDB."""
        if self._conn:
            try:
                self._conn.close()
            except Exception as exc:
                logger.debug("[HANDBOOK] Close failed: %s", exc)
            self._conn = None


__all__ = ["DynamicErrorHandbook", "HandbookExample", "HandbookQuery"]
