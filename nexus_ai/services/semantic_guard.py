"""
Semantyczny Wykrywacz Anomalii (SemanticGuard) -- wykrywa kreatywną księgowość.

- Embeddingi faktur przez sqlite-vec (cosine distance)
- Wykrywanie nagłych zmian profilu usług kontrahenta
- First-match-wins przez DuckDB anomaly_rules
- Integracja z DecisionEngine jako pre-filter

Zgodnie z docs/tfgxzd.txt -- Semantyczny Wykrywacz Kreatywnej Księgowości.
"""

from __future__ import annotations

import hashlib
import math
from enum import StrEnum
from typing import Any

from structlog import get_logger

from nexus_ai.db.vector_store import AsyncVectorStore

logger = get_logger("nexus.services.semantic_guard")


class AnomalyAction(StrEnum):
    ALLOW = "ALLOW"
    WARN = "WARN"
    BLOCK_DECREE = "BLOCK_DECREE"


class AnomalyResult:
    __slots__ = ('action', 'alert', 'anomaly_score', 'similar_invoices')

    def __init__(
        self,
        action: AnomalyAction = AnomalyAction.ALLOW,
        anomaly_score: float = 0.0,
        alert: str = "",
        similar_invoices: list[dict[str, Any]] | None = None,
    ) -> None:
        self.action = action
        self.anomaly_score = anomaly_score
        self.alert = alert
        self.similar_invoices = similar_invoices or []

    def to_dict(self) -> dict[str, Any]:
        return {
            "action": self.action.value,
            "anomaly_score": self.anomaly_score,
            "alert": self.alert,
            "similar_invoices_count": len(self.similar_invoices),
        }


class SemanticGuard:
    """Wykrywa anomalie semantyczne w fakturach.

    Dla kazdego nowego dokumentu:
    1. Wektoryzacja tresci przez embedding model
    2. Zapytanie do sqlite-vec (podobne faktury tego kontrahenta)
    3. Obliczenie anomaly_score (odleglosc kosinusowa)
    4. Decyzja: ALLOW / WARN / BLOCK_DECREE
    """
    __slots__ = ('_store',)

    def __init__(self, vector_store: AsyncVectorStore | None = None) -> None:
        self._store = vector_store or AsyncVectorStore()

    async def evaluate(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
        category_code: str = "",
    ) -> AnomalyResult:

        """Evaluate invoice for semantic anomalies.

        Args:
            invoice_text: Pełny tekst faktury z OCR.
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto.
            category_code: Kod kategorii.

        Returns:
            AnomalyResult z decyzją.
        """
        if not invoice_text or not vendor_nip:
            return AnomalyResult(action=AnomalyAction.ALLOW, anomaly_score=0.0)

        try:
            # 1. Wektoryzacja treści (symulowana -- w produkcji użylibyśmy modelu embedding)
            embedding = self._mock_embedding(invoice_text)

            # 2. Zapytanie do sqlite-vec -- podobne faktury tego kontrahenta
            similar = await self._store.search_similar(
                query_vector=embedding,
                limit=5,
                table_name="vendor_invoices",
                partition={"vendor_nip": vendor_nip},
            )

            # 3. Oblicz anomaly_score
            if similar:
                distances = [s.get("_distance", 1.0) for s in similar]
                avg_distance = sum(distances) / len(distances) if distances else 1.0
                anomaly_score = min(1.0, avg_distance)
            else:
                # Nowy kontrahent -- brak historii = niskie ryzyko
                anomaly_score = 0.0

            # 4. Decyzja na podstawie progu
            if anomaly_score > 0.80 and amount_net > 10000:
                return AnomalyResult(
                    action=AnomalyAction.BLOCK_DECREE,
                    anomaly_score=anomaly_score,
                    alert=(
                        f"Drastyczna zmiana profilu usług kontrahenta NIP={vendor_nip}. "
                        f"Anomalia semantyczna: {anomaly_score:.2f}, kwota: {amount_net:.2f} PLN. "
                        f"Wymagana weryfikacja ręczna i dowód wykonania usługi."
                    ),
                    similar_invoices=similar,
                )
            elif anomaly_score > 0.60:
                return AnomalyResult(
                    action=AnomalyAction.WARN,
                    anomaly_score=anomaly_score,
                    alert=(
                        f"Uwaga: zmiana profilu kontrahenta NIP={vendor_nip}. "
                        f"Anomalia: {anomaly_score:.2f}"
                    ),
                    similar_invoices=similar,
                )

            return AnomalyResult(
                action=AnomalyAction.ALLOW,
                anomaly_score=anomaly_score,
                similar_invoices=similar,
            )

        except Exception as exc:
            logger.warning("[SEMANTIC-GUARD] Evaluation failed: %s", exc)
            return AnomalyResult(
                action=AnomalyAction.ALLOW,
                anomaly_score=0.0,
                alert=f"Evaluation error (allowed by default): {exc}",
            )

    @staticmethod
    def _mock_embedding(text: str, dim: int = 768) -> list[float]:
        """Generate mock embedding for testing.

        W produkcji: llama-cpp-python embedding.
        """
        seed = int(hashlib.sha256(text.encode()).hexdigest()[:8], 16)
        # Deterministyczny wektor z seed-a
        vec = []
        for i in range(dim):
            # Prosta mieszająca funkcja hash
            h = seed ^ (i * 2654435761)
            h = (h ^ (h >> 16)) * 0x45D9F3B
            h = (h ^ (h >> 16)) & 0xFFFFFFFF
            val = (h % 1000) / 1000.0 * 0.2 - 0.1  # range ~[-0.1, 0.1]
            vec.append(val)
        # Normalizacja do jednostkowej długości
        norm = math.sqrt(sum(v * v for v in vec))
        return [v / norm for v in vec]
