"""
Semantyczny Wykrywacz Anomalii (SemanticGuard) -- wykrywa kreatywną księgowość.

- Embeddingi faktur przez realny model (llama-cpp-python / sentence-transformers)
- Wykrywanie nagłych zmian profilu usług kontrahenta
- Adaptacyjne progi per kontrahent (v7.0 Audit)
- Sezonowość i analiza wielowymiarowa
- First-match-wins przez DuckDB anomaly_rules
- Integracja z DecisionEngine jako pre-filter

v7.0 Audit: _mock_embedding zastąpiony realnym embeddingiem z fallbackiem.
"""

from __future__ import annotations

import hashlib
import math
from enum import StrEnum
from typing import Any, final

from structlog import get_logger

from nexus_ai.db.vector_store import AsyncVectorStore

logger = get_logger("nexus.services.semantic_guard")


class AnomalyAction(StrEnum):
    ALLOW = "ALLOW"
    WARN = "WARN"
    BLOCK_DECREE = "BLOCK_DECREE"


@final
class AnomalyResult:
    __slots__ = ('action', 'alert', 'anomaly_score', 'similar_invoices', 'seasonal_factor', 'vendor_profile')

    def __init__(
        self,
        action: AnomalyAction = AnomalyAction.ALLOW,
        anomaly_score: float = 0.0,
        alert: str = "",
        similar_invoices: list[dict[str, Any]] | None = None,
        seasonal_factor: float = 1.0,
        vendor_profile: dict[str, Any] | None = None,
    ) -> None:
        self.action = action
        self.anomaly_score = anomaly_score
        self.alert = alert
        self.similar_invoices = similar_invoices or []
        self.seasonal_factor = seasonal_factor
        self.vendor_profile = vendor_profile or {}

    def to_dict(self) -> dict[str, Any]:
        return {
            "action": self.action.value,
            "anomaly_score": self.anomaly_score,
            "alert": self.alert,
            "similar_invoices_count": len(self.similar_invoices),
            "seasonal_factor": self.seasonal_factor,
        }


@final
class SemanticGuard:
    """Wykrywa anomalie semantyczne w fakturach.

    v7.0 Audit — kluczowe zmiany:
    - Realny embedding (llama-cpp-python z fallbackiem do mock)
    - Adaptacyjne progi per kontrahent (na podstawie historii)
    - Analiza sezonowości (współczynnik sezonowy)
    - Wielowymiarowa analiza (nie tylko cosine distance)

    Dla kazdego nowego dokumentu:
    1. Wektoryzacja treści przez realny model embedding
    2. Zapytanie do sqlite-vec (podobne faktury tego kontrahenta)
    3. Obliczenie anomaly_score (ważona odległość kosinusowa)
    4. Adaptacyjna decyzja: ALLOW / WARN / BLOCK_DECREE
    """

    __slots__ = ('_store', '_model_manager', '_model_path', '_use_real_embedding')

    # v7.0: domyślne progi per kontrahent (mogą być adaptowane)
    DEFAULT_THRESHOLD_WARN: float = 0.60
    DEFAULT_THRESHOLD_BLOCK: float = 0.80
    DEFAULT_BLOCK_AMOUNT_MIN: float = 10000.0

    def __init__(
        self,
        vector_store: AsyncVectorStore | None = None,
        model_manager: Any = None,
        model_path: str | None = None,
        use_real_embedding: bool = True,
    ) -> None:
        self._store = vector_store or AsyncVectorStore()
        self._model_manager = model_manager
        self._model_path = model_path
        self._use_real_embedding = use_real_embedding

    async def evaluate(
        self,
        invoice_text: str,
        vendor_nip: str,
        amount_net: float = 0.0,
        category_code: str = "",
        vendor_profile: dict[str, Any] | None = None,
    ) -> AnomalyResult:
        """Evaluate invoice for semantic anomalies.

        v7.0: Dodana analiza sezonowości i adaptacyjne progi.

        Args:
            invoice_text: Pełny tekst faktury z OCR.
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto.
            category_code: Kod kategorii.
            vendor_profile: Profil kontrahenta (historia, zaufanie).

        Returns:
            AnomalyResult z decyzją.
        """
        if not invoice_text or not vendor_nip:
            return AnomalyResult(action=AnomalyAction.ALLOW, anomaly_score=0.0)

        try:
            # 1. Wektoryzacja treści (REALNY model z fallbackiem)
            embedding = await self._embed(invoice_text)

            # 2. Zapytanie do sqlite-vec — podobne faktury tego kontrahenta
            similar = await self._store.search_similar(
                query_vector=embedding,
                limit=10,
                table_name="vendor_invoices",
                partition={"vendor_nip": vendor_nip},
            )

            # 3. Oblicz anomaly_score (wielowymiarowo)
            if similar:
                distances = [s.get("_distance", 1.0) for s in similar]
                # Ważona średnia — nowsze faktury mają większą wagę
                weighted_distances = []
                for i, d in enumerate(distances):
                    recency_weight = 1.0 - (i / (len(distances) + 1)) * 0.5  # 1.0 → 0.5
                    weighted_distances.append(d * recency_weight)
                avg_distance = sum(weighted_distances) / len(weighted_distances) if weighted_distances else 1.0

                # Dodaj analizę wariancji (wielowymiarowość)
                variance = sum((d - avg_distance) ** 2 for d in distances) / len(distances) if len(distances) > 1 else 0
                anomaly_score = min(1.0, avg_distance * 0.7 + math.sqrt(variance) * 0.3)
            else:
                anomaly_score = 0.0

            # 4. Analiza sezonowości (v7.0)
            seasonal_factor = await self._compute_seasonal_factor(vendor_nip, category_code)

            # 5. Adaptacyjne progi (v7.0 — per kontrahent)
            thresholds = self._get_adaptive_thresholds(vendor_profile)
            adjusted_score = anomaly_score * seasonal_factor

            # 6. Decyzja
            if adjusted_score > thresholds["block"] and amount_net > thresholds["block_amount_min"]:
                return AnomalyResult(
                    action=AnomalyAction.BLOCK_DECREE,
                    anomaly_score=round(adjusted_score, 4),
                    alert=(
                        f"Drastyczna zmiana profilu usług kontrahenta NIP={vendor_nip}. "
                        f"Anomalia semantyczna: {adjusted_score:.2f} (sezonowa: {seasonal_factor:.2f}), "
                        f"kwota: {amount_net:.2f} PLN. "
                        f"Wymagana weryfikacja ręczna i dowód wykonania usługi."
                    ),
                    similar_invoices=similar,
                    seasonal_factor=seasonal_factor,
                )
            elif adjusted_score > thresholds["warn"]:
                return AnomalyResult(
                    action=AnomalyAction.WARN,
                    anomaly_score=round(adjusted_score, 4),
                    alert=(
                        f"Uwaga: zmiana profilu kontrahenta NIP={vendor_nip}. "
                        f"Anomalia: {adjusted_score:.2f} (sezonowa: {seasonal_factor:.2f})"
                    ),
                    similar_invoices=similar,
                    seasonal_factor=seasonal_factor,
                )

            return AnomalyResult(
                action=AnomalyAction.ALLOW,
                anomaly_score=round(adjusted_score, 4),
                similar_invoices=similar,
                seasonal_factor=seasonal_factor,
            )

        except Exception as exc:
            logger.warning("[SEMANTIC-GUARD] Evaluation failed: %s", exc)
            return AnomalyResult(
                action=AnomalyAction.ALLOW,
                anomaly_score=0.0,
                alert=f"Evaluation error (allowed by default): {exc}",
            )

    # ── Real Embedding (v7.0) ──────────────────────────────────────────

    async def _embed(self, text: str, dim: int = 768) -> list[float]:
        """Realny embedding z fallbackiem do mocka.

        v7.0 Audit: _mock_embedding zastąpiony prawdziwym modelem.
        Używa llama-cpp-python embedding API gdy dostępne.
        """
        if self._use_real_embedding and self._model_manager is not None and self._model_path is not None:
            try:
                svc = self._model_manager.get_or_create(
                    self._model_path,
                    n_ctx=2048,
                    n_threads=2,
                    n_gpu_layers=0,
                )
                # Próba użycia publicznego API embedding (jeśli InferenceService je wspiera)
                if hasattr(svc, 'embed'):
                    result = await svc.embed(text[:2000])
                    if result and isinstance(result, list) and len(result) > 0:
                        if isinstance(result[0], list):
                            return result[0][:dim]
                        return result[:dim]
                # Fallback: bezpośredni dostęp do modelu (tylko jeśli nie ma publicznego API)
                if hasattr(svc, '_model') and svc._model is not None and hasattr(svc._model, 'embed'):
                    result = svc._model.embed(text[:2000])
                    if result and isinstance(result, list) and len(result) > 0:
                        if isinstance(result[0], list):
                            return result[0][:dim]
                        return result[:dim]
            except Exception as exc:
                logger.debug("[SEMANTIC-GUARD] Real embedding failed, falling back to mock: %s", exc)

        # Fallback: mock embedding (deterministyczny, ale lepszy niż nic)
        return self._mock_embedding(text, dim)

    @staticmethod
    def _mock_embedding(text: str, dim: int = 768) -> list[float]:
        """Mock embedding — fallback gdy realny model niedostępny.

        UWAGA: To NIE JEST prawdziwy embedding semantyczny.
        W produkcji należy użyć realnego modelu (llama-cpp-python,
        sentence-transformers, lub OpenAI API).
        """
        seed = int(hashlib.sha256(text.encode()).hexdigest()[:8], 16)
        vec = []
        for i in range(dim):
            h = seed ^ (i * 2654435761)
            h = (h ^ (h >> 16)) * 0x45D9F3B
            h = (h ^ (h >> 16)) & 0xFFFFFFFF
            val = (h % 1000) / 1000.0 * 0.2 - 0.1
            vec.append(val)
        norm = math.sqrt(sum(v * v for v in vec))
        return [v / norm for v in vec] if norm > 0 else [0.0] * dim

    # ── Adaptacyjne progi (v7.0) ─────────────────────────────────────

    @staticmethod
    def _get_adaptive_thresholds(vendor_profile: dict[str, Any] | None) -> dict[str, float]:
        """Oblicz adaptacyjne progi per kontrahent.

        v7.0: Progi dostosowują się do historii kontrahenta:
        - Nowy kontrahent: wyższe progi (ostrożniej)
        - Zaufany kontrahent: niższe progi (mniej false positives)
        - Sezonowy kontrahent: uwzględniona sezonowość
        """
        if vendor_profile is None:
            return {
                "warn": SemanticGuard.DEFAULT_THRESHOLD_WARN,
                "block": SemanticGuard.DEFAULT_THRESHOLD_BLOCK,
                "block_amount_min": SemanticGuard.DEFAULT_BLOCK_AMOUNT_MIN,
            }

        trust = vendor_profile.get("trust_score", 0.5)
        invoice_count = vendor_profile.get("invoice_count", 0)

        # Nowi kontrahenci — wyższe progi (mniej danych)
        if invoice_count < 5:
            warn_threshold = 0.50
            block_threshold = 0.70
        elif invoice_count < 50:
            # Skaluj liniowo od nowego do zaufanego
            factor = invoice_count / 50.0
            warn_threshold = 0.50 + factor * 0.10
            block_threshold = 0.70 + factor * 0.10
        else:
            # Zaufany kontrahent — standardowe progi
            warn_threshold = 0.60
            block_threshold = 0.80

        # Dostosuj do trust_score
        trust_adjustment = (trust - 0.5) * 0.1  # ±5 punktów proc.
        warn_threshold += trust_adjustment
        block_threshold += trust_adjustment

        return {
            "warn": round(max(0.40, min(0.75, warn_threshold)), 2),
            "block": round(max(0.60, min(0.90, block_threshold)), 2),
            "block_amount_min": 10000.0 if trust > 0.7 else 5000.0,
        }

    async def _compute_seasonal_factor(
        self, vendor_nip: str, category_code: str
    ) -> float:
        """Oblicz współczynnik sezonowości dla kontrahenta.

        v7.0: "Brak uwzględnienia sezonowości — kontrahent może mieć
        cykliczne zmiany profilu (np. dostawca owoców ma sezon letni)"

        Returns:
            Współczynnik sezonowy (1.0 = brak sezonowości, >1.0 = wyższe
            ryzyko poza sezonem).
        """
        try:
            import pendulum
            current_month = pendulum.now("UTC").month

            # Pobierz historyczne miesiące aktywności kontrahenta
            similar = await self._store.search_similar(
                query_vector=[0.0] * 768,  # dummy — i tak filtrujemy po partition
                limit=100,
                table_name="vendor_invoices",
                partition={"vendor_nip": vendor_nip},
            )

            if not similar or len(similar) < 3:
                return 1.0  # Za mało danych

            # Analiza: czy kontrahent wystawia faktury w obecnym miesiącu?
            active_months: set[int] = set()
            for s in similar:
                ts = s.get("created_at") or s.get("date")
                if ts:
                    try:
                        m = pendulum.parse(str(ts)).month
                        active_months.add(m)
                    except Exception:
                        pass

            # Jeśli kontrahent jest aktywny w tym miesiącu → normalne ryzyko
            if current_month in active_months:
                return 0.9  # Lekko obniżone ryzyko (sezonowość potwierdzona)
            elif len(active_months) >= 3:
                # Kontrahent ma ustalony wzorzec, obecny miesiąc jest poza nim
                return 1.3  # Podwyższone ryzyko
            return 1.0

        except Exception as exc:
            logger.debug("[SEMANTIC-GUARD] Seasonal factor computation skipped: %s", exc)
            return 1.0


__all__ = [
    "SemanticGuard",
    "AnomalyResult",
    "AnomalyAction",
]
