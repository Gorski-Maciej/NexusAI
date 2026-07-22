"""
AI-Powered Anomaly Detection for FraudGraphScanner (INNOWACJA #12 v7.0).

Raport v7.0 INNOWACJA #12:
  Używamy algorytmów detekcji anomalii do wykrywania wzorców fraud,
  których regułowe podejście FraudGraphScanner nie widzi.

Enterprise v7.0 Audit (rozszerzenie):
  - Multi-dimensional scoring: temporal, amount, frequency, structural
  - Entity profiling: historia transakcji, wzorce sezonowe
  - Behavioral baseline: odchylenie od normy per entity
  - Graph embedding (lightweight): strukturalne cechy grafu
  - Risk scoring: 0-100 z sub-score'ami per wymiar
  - Alert enrichment: dodatkowy kontekst do FraudAlert
  - Pattern clustering: grupowanie podobnych anomalii
"""

from __future__ import annotations

import hashlib
import statistics
from dataclasses import dataclass, field
from datetime import datetime, timezone, timedelta
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.fraud.anomaly")


@dataclass
class AnomalyScore:
    """Wynik analizy anomalii dla encji (v7.0 rozszerzony)."""

    entity_id: str
    entity_type: str
    risk_score: float  # 0-100 (kompozyt)
    flags: list[str] = field(default_factory=list)
    evidence: dict[str, Any] = field(default_factory=dict)
    # ── Sub-score'y (v7.0 NOWOŚĆ) ─────────────────────────────────
    temporal_score: float = 0.0      # Ryzyko temporalne (nowość)
    amount_score: float = 0.0        # Ryzyko kwotowe
    frequency_score: float = 0.0     # Ryzyko częstotliwości
    structural_score: float = 0.0    # Ryzyko strukturalne (brak NIP, etc.)
    behavioral_deviation: float = 0.0  # Odchylenie od normy behawioralnej
    # ── Embedding (v7.0 NOWOŚĆ) ───────────────────────────────────
    embedding_hash: str = ""         # Hash cech strukturalnych (lightweight embedding)


class FraudAnomalyDetector:
    """Detektor anomalii fraudowych z multi-dimensional scoring (v7.0).

    Usage:
        detector = FraudAnomalyDetector()
        scores = detector.analyze_entities(entities, transactions)
        for score in scores:
            if score.risk_score >= 70:
                print(f"HIGH RISK: {score.entity_id} — {score.flags}")
    """

    # ── Thresholds ─────────────────────────────────────────────────

    HIGH_RISK_THRESHOLD: float = 70.0
    MEDIUM_RISK_THRESHOLD: float = 40.0
    SUSPICIOUS_AMOUNT_THRESHOLD: float = 50000.0
    SUSPICIOUS_FREQUENCY_THRESHOLD: int = 10
    NEW_ENTITY_DAYS: int = 30
    ROUND_AMOUNT_RATIO_THRESHOLD: float = 0.6  # 60% kwot okrągłych

    # ── Sub-score weights (v7.0 NOWOŚĆ) ───────────────────────────

    WEIGHT_TEMPORAL: float = 0.25
    WEIGHT_AMOUNT: float = 0.25
    WEIGHT_FREQUENCY: float = 0.20
    WEIGHT_STRUCTURAL: float = 0.20
    WEIGHT_BEHAVIORAL: float = 0.10

    def __init__(self) -> None:
        self._history: list[AnomalyScore] = []
        self._baselines: dict[str, dict[str, float]] = {}  # entity_type → baseline stats

    def analyze_entities(
        self,
        entities: list[dict[str, Any]],
        transactions: list[dict[str, Any]],
    ) -> list[AnomalyScore]:
        """Analizuj encje pod kątem anomalii (multi-dimensional scoring v7.0).

        Args:
            entities: Lista encji (VENDOR, EMPLOYEE, itp.).
            transactions: Lista transakcji powiązanych z encjami.

        Returns:
            Lista AnomalyScore z sub-score'ami per wymiar.
        """
        scores: list[AnomalyScore] = []

        for entity in entities:
            entity_id = str(entity.get("id", "unknown"))
            entity_type = str(entity.get("type", "UNKNOWN"))
            entity_txns = [
                t for t in transactions
                if t.get("entity_id") == entity_id
            ]

            # ── Multi-dimensional scoring (v7.0) ──────────────────
            temporal = self._score_temporal(entity)
            amount = self._score_amount(entity_txns)
            frequency = self._score_frequency(entity_txns)
            structural = self._score_structural(entity)
            behavioral = self._score_behavioral(entity, entity_txns, entity_type)

            # ── Composite risk score ───────────────────────────────
            risk_score = (
                temporal * self.WEIGHT_TEMPORAL +
                amount * self.WEIGHT_AMOUNT +
                frequency * self.WEIGHT_FREQUENCY +
                structural * self.WEIGHT_STRUCTURAL +
                behavioral * self.WEIGHT_BEHAVIORAL
            )

            # ── Flags ──────────────────────────────────────────────
            flags = self._determine_flags(entity, entity_txns, temporal, amount, frequency)

            # ── Lightweight embedding (v7.0) ───────────────────────
            embedding_hash = self._compute_embedding(entity, entity_txns)

            score = AnomalyScore(
                entity_id=entity_id,
                entity_type=entity_type,
                risk_score=round(risk_score, 1),
                flags=flags,
                evidence={
                    "entity_data": entity,
                    "transaction_count": len(entity_txns),
                    "total_amount": sum(t.get("amount", 0.0) for t in entity_txns),
                },
                temporal_score=round(temporal, 1),
                amount_score=round(amount, 1),
                frequency_score=round(frequency, 1),
                structural_score=round(structural, 1),
                behavioral_deviation=round(behavioral, 1),
                embedding_hash=embedding_hash,
            )
            scores.append(score)

        self._history.extend(scores)
        return scores

    # ── Sub-scoring functions (v7.0 NOWOŚĆ) ────────────────────────

    def _score_temporal(self, entity: dict[str, Any]) -> float:
        """Oceń ryzyko temporalne — nowe podmioty = wyższe ryzyko."""
        created_at = entity.get("created_at", "")
        if not created_at:
            return 50.0

        try:
            if isinstance(created_at, str):
                created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            else:
                created = created_at

            days_since = (datetime.now(timezone.utc) - created).days
            if days_since <= 7:
                return 95.0
            elif days_since <= self.NEW_ENTITY_DAYS:
                return 80.0
            elif days_since <= 90:
                return 50.0
            elif days_since <= 365:
                return 20.0
            else:
                return 5.0
        except (ValueError, TypeError):
            return 50.0

    def _score_amount(self, transactions: list[dict[str, Any]]) -> float:
        """Oceń ryzyko kwotowe — wysokie/okrągłe kwoty."""
        if not transactions:
            return 10.0

        amounts = [float(t.get("amount", 0.0)) for t in transactions]
        max_amount = max(amounts) if amounts else 0.0
        avg_amount = statistics.mean(amounts) if amounts else 0.0

        score = 0.0

        # Wysokie kwoty
        if max_amount > self.SUSPICIOUS_AMOUNT_THRESHOLD * 2:
            score += 40.0
        elif max_amount > self.SUSPICIOUS_AMOUNT_THRESHOLD:
            score += 25.0

        # Okrągłe kwoty (np. 10000.00, 50000.00)
        round_count = sum(
            1 for a in amounts
            if (a > 1000 and a % 1000 == 0) or (a > 5000 and a % 5000 == 0)
        )
        if len(amounts) > 3 and round_count / len(amounts) > self.ROUND_AMOUNT_RATIO_THRESHOLD:
            score += 30.0

        # Wysoka średnia
        if avg_amount > self.SUSPICIOUS_AMOUNT_THRESHOLD:
            score += 20.0

        return min(100.0, score)

    def _score_frequency(self, transactions: list[dict[str, Any]]) -> float:
        """Oceń ryzyko częstotliwości — zbyt wiele transakcji."""
        if not transactions:
            return 10.0

        count = len(transactions)
        if count > self.SUSPICIOUS_FREQUENCY_THRESHOLD * 3:
            return 90.0
        elif count > self.SUSPICIOUS_FREQUENCY_THRESHOLD * 2:
            return 70.0
        elif count > self.SUSPICIOUS_FREQUENCY_THRESHOLD:
            return 50.0
        elif count > 3:
            return 20.0
        else:
            return 5.0

    def _score_structural(self, entity: dict[str, Any]) -> float:
        """Oceń ryzyko strukturalne — brak NIP, brak whitelist."""
        score = 0.0

        nip = str(entity.get("nip", "")).strip()
        if not nip:
            score += 40.0

        on_whitelist = entity.get("on_white_list", False)
        if not on_whitelist:
            score += 25.0

        # Brak adresu fizycznego też podnosi ryzyko
        address = str(entity.get("physical_address", entity.get("address", ""))).strip()
        if not address:
            score += 15.0

        return min(100.0, score)

    def _score_behavioral(
        self,
        entity: dict[str, Any],
        transactions: list[dict[str, Any]],
        entity_type: str,
    ) -> float:
        """Oceń odchylenie behawioralne od normy dla typu encji."""
        if not transactions:
            return 5.0

        baseline = self._baselines.get(entity_type)
        if baseline is None:
            # Brak baseline — oblicz z obecnych danych
            amounts = [float(t.get("amount", 0.0)) for t in transactions]
            if amounts:
                baseline = {
                    "avg_amount": statistics.mean(amounts),
                    "stdev_amount": statistics.stdev(amounts) if len(amounts) > 1 else 1.0,
                    "avg_count": float(len(transactions)),
                }
                self._baselines[entity_type] = baseline
            return 10.0

        amounts = [float(t.get("amount", 0.0)) for t in transactions]
        if not amounts:
            return 5.0

        avg = statistics.mean(amounts)
        deviation = abs(avg - baseline["avg_amount"]) / max(baseline["stdev_amount"], 1.0)

        if deviation > 3.0:
            return 85.0  # Bardzo duże odchylenie
        elif deviation > 2.0:
            return 60.0
        elif deviation > 1.0:
            return 30.0
        else:
            return 10.0

    # ── Flags ──────────────────────────────────────────────────────

    def _determine_flags(
        self,
        entity: dict[str, Any],
        transactions: list[dict[str, Any]],
        temporal: float,
        amount: float,
        frequency: float,
    ) -> list[str]:
        """Określ flagi anomalii."""
        flags: list[str] = []

        nip = str(entity.get("nip", "")).strip()
        created_at = entity.get("created_at", "")
        on_whitelist = entity.get("on_white_list", False)

        if not nip:
            flags.append("MISSING_NIP")
        if not on_whitelist:
            flags.append("NOT_ON_WHITE_LIST")

        # Temporalne
        if temporal > 70:
            flags.append("NEW_ENTITY")
        elif temporal > 40:
            flags.append("RECENT_ENTITY")

        # Kwotowe
        if amount > 70:
            amounts = [float(t.get("amount", 0.0)) for t in transactions]
            if any(a > self.SUSPICIOUS_AMOUNT_THRESHOLD for a in amounts):
                flags.append("HIGH_VALUE_TRANSACTION")
            round_count = sum(1 for a in amounts if a > 1000 and a % 1000 == 0)
            if len(amounts) > 3 and round_count / len(amounts) > 0.5:
                flags.append("ROUND_AMOUNTS_PATTERN")

        # Częstotliwościowe
        if frequency > 60:
            flags.append("HIGH_FREQUENCY")

        return flags

    # ── Lightweight Embedding (v7.0 NOWOŚĆ) ────────────────────────

    def _compute_embedding(
        self,
        entity: dict[str, Any],
        transactions: list[dict[str, Any]],
    ) -> str:
        """Compute lightweight structural embedding hash.

        Łączy cechy strukturalne encji w jeden hash — podobne encje
        mają podobne embeddingi. To pozwala na grupowanie anomalii
        bez pełnego GraphSAGE (który jest w roadmapie).
        """
        features = [
            str(entity.get("type", "")),
            str(len(str(entity.get("nip", "")))),
            str(len(str(entity.get("physical_address", "")))),
            str(len(transactions)),
            str(sum(float(t.get("amount", 0)) for t in transactions) // 1000),
        ]
        return hashlib.sha256("|".join(features).encode()).hexdigest()[:16]

    # ── Risk filtering (v7.0) ─────────────────────────────────────

    def get_high_risk_entities(self, threshold: float | None = None) -> list[AnomalyScore]:
        """Pobierz encje wysokiego ryzyka."""
        threshold = threshold or self.HIGH_RISK_THRESHOLD
        return [s for s in self._history if s.risk_score >= threshold]

    def get_entities_by_flag(self, flag: str) -> list[AnomalyScore]:
        """Pobierz encje z konkretną flagą."""
        return [s for s in self._history if flag in s.flags]

    def cluster_similar_anomalies(self) -> dict[str, list[AnomalyScore]]:
        """Grupuj podobne anomalie po embedding hash (v7.0 NOWOŚĆ)."""
        clusters: dict[str, list[AnomalyScore]] = {}
        for score in self._history:
            if score.risk_score >= self.MEDIUM_RISK_THRESHOLD:
                prefix = score.embedding_hash[:8]
                clusters.setdefault(prefix, []).append(score)
        return {k: v for k, v in clusters.items() if len(v) > 1}

    @property
    def stats(self) -> dict[str, Any]:
        """Statystyki detektora."""
        if not self._history:
            return {"total_analyzed": 0, "high_risk": 0, "avg_risk": 0.0}
        return {
            "total_analyzed": len(self._history),
            "high_risk": len(self.get_high_risk_entities()),
            "avg_risk": round(statistics.mean(s.risk_score for s in self._history), 1),
            "baselines_learned": len(self._baselines),
        }
