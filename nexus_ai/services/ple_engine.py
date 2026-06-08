"""
Perpetual Learning Engine (PLE) — trójwarstwowy system pamięci dla Autopilota.

Architektura:
  - STM (Short-Term Memory)   → ostatnie 50 decyzji, TTL 24h
  - LTM (Long-Term Memory)    → kategoryzowane według kontrahenta/kategorii/kwoty/conf
  - FM  (Fusion Memory)       → Cognitive Artifacts: DecisionCache, PatternLibrary, AnomalyInsights

Każda warstwa ma automatyczny Data Decay:
  STM → czyszczenie po 24h
  LTM → retention z wagą (starsze wpisy mają niższy priorytet)
  FM  → kompresja wzorców (duplikaty scalane, rzadkie wzorce usuwane)
"""

from __future__ import annotations

import asyncio
import time
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from typing import Any

from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.services.ple")


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class DecisionRecord:
    """Pojedynczy rekord decyzji w pamięci PLE."""

    invoice_id: str
    decision: str  # AUTO_POST | SUGGEST | ASK_USER | BLOCK
    trust_score: float
    trust_components: dict[str, float]
    contractor_nip: str
    category: str
    amount_gross: float
    timestamp: float  # unix timestamp
    user_correction: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def age_hours(self) -> float:
        return (time.time() - self.timestamp) / 3600.0

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @staticmethod
    def from_dict(data: dict[str, Any]) -> DecisionRecord:
        return DecisionRecord(**data)


@dataclass(slots=True)
class CognitiveArtifact:
    """Cognitive Artifact — wzorzec wyodrębniony z decyzji."""

    artifact_type: str  # "decision_cache" | "pattern" | "anomaly_insight"
    key: str
    value: Any
    confidence: float  # 0.0–1.0
    frequency: int = 1  # ile razy potwierdzony
    last_seen: float = 0.0
    created_at: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @staticmethod
    def from_dict(data: dict[str, Any]) -> CognitiveArtifact:
        return CognitiveArtifact(**data)


# ---------------------------------------------------------------------------
# STM — Short-Term Memory
# ---------------------------------------------------------------------------

class ShortTermMemory:
    """Pamięć krótkoterminowa — przechowuje ostatnie 50 decyzji z TTL 24h.

    Wszystkie operacje są thread-safe przez asyncio.Lock.
    Automatyczny Data Decay przy każdej operacji zapisu.
    """

    MAX_SIZE = 50
    TTL_HOURS = 24

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._records: list[DecisionRecord] = []
        self._last_decay: float = time.time()

    async def push(self, record: DecisionRecord) -> None:
        """Dodaj nowy rekord do STM z automatycznym decay."""
        async with self._lock:
            await self._apply_decay()
            self._records.append(record)
            # Trim to MAX_SIZE
            if len(self._records) > self.MAX_SIZE:
                self._records = self._records[-self.MAX_SIZE:]
            logger.debug("[PLE:STM] pushed decision=%s trust=%.4f", record.decision, record.trust_score)

    async def query(
        self,
        contractor_nip: str | None = None,
        category: str | None = None,
        min_confidence: float = 0.0,
        limit: int = 10,
    ) -> list[DecisionRecord]:
        """Przeszukaj STM z opcjonalnymi filtrami."""
        async with self._lock:
            await self._apply_decay()
            results = list(self._records)
            # Filtruj
            if contractor_nip:
                results = [r for r in results if r.contractor_nip == contractor_nip]
            if category:
                results = [r for r in results if r.category == category]
            if min_confidence > 0:
                results = [r for r in results if r.trust_score >= min_confidence]
            # Sortuj od najnowszych
            results.sort(key=lambda r: r.timestamp, reverse=True)
            return results[:limit]

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki STM."""
        async with self._lock:
            await self._apply_decay()
            if not self._records:
                return {"size": 0, "avg_trust": 0.0, "decisions": {}}
            decisions: dict[str, int] = defaultdict(int)
            for r in self._records:
                decisions[r.decision] += 1
            return {
                "size": len(self._records),
                "avg_trust": round(sum(r.trust_score for r in self._records) / len(self._records), 4),
                "decisions": dict(decisions),
                "oldest_hours": max(r.age_hours for r in self._records) if self._records else 0.0,
            }

    async def _apply_decay(self) -> None:
        """Automatyczny Data Decay — usuń rekordy starsze niż TTL."""
        now = time.time()
        # Sprawdzaj tylko co 5 minut
        if now - self._last_decay < 300:
            return
        self._last_decay = now
        cutoff = now - self.TTL_HOURS * 3600
        before = len(self._records)
        self._records = [r for r in self._records if r.timestamp >= cutoff]
        removed = before - len(self._records)
        if removed > 0:
            logger.info("[PLE:STM] data decay removed %d old records", removed)

    async def clear(self) -> None:
        """Wyczyść STM."""
        async with self._lock:
            self._records.clear()
            logger.info("[PLE:STM] cleared")


# ---------------------------------------------------------------------------
# LTM — Long-Term Memory
# ---------------------------------------------------------------------------

class LongTermMemory:
    """Pamięć długoterminowa — kategoryzuje decyzje z retention wagą.

    Struktura indeksowana przez (contractor_nip, category).
    Retention weight: starsze wpisy mają niższy priorytet.
    Automatyczny decay przy każdej operacji zapisu.
    """

    MAX_PER_BUCKET = 100  # max wpisów na bucket (kontrahent, kategoria)
    RETENTION_DECAY = 0.95  # waga mnożona przez ten współczynnik co miesiąc

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        # Indeks: (contractor_nip, category) → list[DecisionRecord]
        self._buckets: dict[tuple[str, str], list[DecisionRecord]] = defaultdict(list)
        self._last_decay: float = time.time()

    async def store(self, record: DecisionRecord) -> None:
        """Przechowaj rekord w LTM z kategoryzacją."""
        async with self._lock:
            await self._apply_decay()
            key = (record.contractor_nip or "unknown", record.category or "unknown")
            bucket = self._buckets[key]
            bucket.append(record)
            # Trim
            if len(bucket) > self.MAX_PER_BUCKET:
                # Sortuj od najnowszych i przytnij
                bucket.sort(key=lambda r: r.timestamp, reverse=True)
                self._buckets[key] = bucket[:self.MAX_PER_BUCKET]
            logger.debug("[PLE:LTM] stored decision for key=%s", key)

    async def query(
        self,
        contractor_nip: str | None = None,
        category: str | None = None,
        limit: int = 20,
    ) -> list[DecisionRecord]:
        """Przeszukaj LTM z opcjonalnymi filtrami."""
        async with self._lock:
            await self._apply_decay()
            results: list[DecisionRecord] = []
            for (nip, cat), records in self._buckets.items():
                if contractor_nip and nip != contractor_nip:
                    continue
                if category and cat != category:
                    continue
                results.extend(records)
            # Sortuj od najnowszych
            results.sort(key=lambda r: r.timestamp, reverse=True)
            # Weight by recency
            for r in results:
                r.metadata["retention_weight"] = self._calculate_weight(r)
            return results[:limit]

    async def get_vendor_profile(self, contractor_nip: str) -> dict[str, Any]:
        """Zwróć profil kontrahenta na podstawie LTM."""
        async with self._lock:
            records = await self.query(contractor_nip=contractor_nip, limit=50)
            if not records:
                return {"known": False, "invoice_count": 0, "trust_trend": "unknown"}

            decisions = [r.decision for r in records]
            trust_scores = [r.trust_score for r in records]
            categories = [r.category for r in records if r.category]

            auto_post_count = decisions.count("AUTO_POST")
            block_count = decisions.count("BLOCK")
            ask_user_count = decisions.count("ASK_USER")

            return {
                "known": True,
                "invoice_count": len(records),
                "avg_trust_score": round(sum(trust_scores) / len(trust_scores), 4) if trust_scores else 0.0,
                "auto_post_rate": round(auto_post_count / max(len(decisions), 1), 4),
                "block_rate": round(block_count / max(len(decisions), 1), 4),
                "ask_user_rate": round(ask_user_count / max(len(decisions), 1), 4),
                "categories": list(set(categories)),
                "last_decision": records[0].decision if records else "unknown",
                "trust_trend": self._compute_trend(trust_scores),
            }

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki LTM."""
        async with self._lock:
            total = sum(len(v) for v in self._buckets.values())
            if total == 0:
                return {"total_records": 0, "unique_vendors": 0, "unique_categories": 0}
            unique_vendors = len(set(k[0] for k in self._buckets))
            unique_categories = len(set(k[1] for k in self._buckets))
            return {
                "total_records": total,
                "unique_vendors": unique_vendors,
                "unique_categories": unique_categories,
                "buckets": len(self._buckets),
            }

    async def _apply_decay(self) -> None:
        """Retention decay — starsze wpisy tracą wagę."""
        now = time.time()
        if now - self._last_decay < 3600:  # raz na godzinę
            return
        self._last_decay = now
        # Usuń wpisy z wagą poniżej progu
        for key in list(self._buckets.keys()):
            bucket = self._buckets[key]
            bucket = [r for r in bucket if self._calculate_weight(r) > 0.1]
            if bucket:
                self._buckets[key] = bucket
            else:
                del self._buckets[key]

    def _calculate_weight(self, record: DecisionRecord) -> float:
        """Oblicz wagę retention na podstawie wieku."""
        age_months = record.age_hours / (24 * 30)
        weight = self.RETENTION_DECAY ** age_months
        return max(weight, 0.0)

    @staticmethod
    def _compute_trend(scores: list[float]) -> str:
        """Określ trend trust score: up/down/stable."""
        if len(scores) < 3:
            return "stable"
        recent = sum(scores[:3]) / 3
        older = sum(scores[-3:]) / 3 if len(scores) >= 6 else sum(scores) / len(scores)
        diff = recent - older
        if diff > 0.05:
            return "up"
        if diff < -0.05:
            return "down"
        return "stable"

    async def clear(self) -> None:
        """Wyczyść LTM."""
        async with self._lock:
            self._buckets.clear()
            logger.info("[PLE:LTM] cleared")


# ---------------------------------------------------------------------------
# FM — Fusion Memory (Cognitive Artifacts)
# ---------------------------------------------------------------------------

class FusionMemory:
    """Pamięć fuzyjna — Cognitive Artifacts wyodrębnione z decyzji.

    Trzy typy artifactów:
      1. DecisionCache — zapamiętane decyzje dla szybkiego dostępu
      2. PatternLibrary — wzorce decyzyjne (np. "czynsz zawsze auto_post")
      3. AnomalyInsights — wyjątki i anomalie
    """

    MAX_ARTIFACTS = 200
    MIN_FREQUENCY = 2  # minimalna częstotliwość dla patternów

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._artifacts: dict[str, CognitiveArtifact] = {}  # key → artifact
        self._last_compaction: float = time.time()

    async def add_decision_cache(
        self,
        contractor_nip: str,
        category: str,
        decision: str,
        trust_score: float,
    ) -> None:
        """Dodaj Decision Cache artifact."""
        key = f"dc:{contractor_nip}:{category}"
        async with self._lock:
            existing = self._artifacts.get(key)
            if existing:
                existing.frequency += 1
                existing.last_seen = time.time()
                existing.confidence = max(existing.confidence, trust_score)
            else:
                self._artifacts[key] = CognitiveArtifact(
                    artifact_type="decision_cache",
                    key=key,
                    value={"contractor_nip": contractor_nip, "category": category, "typical_decision": decision},
                    confidence=trust_score,
                    frequency=1,
                    last_seen=time.time(),
                    created_at=time.time(),
                )
            await self._compact_if_needed()

    async def add_pattern(
        self,
        pattern_key: str,
        description: str,
        confidence: float,
    ) -> None:
        """Dodaj Pattern Library artifact."""
        key = f"pat:{pattern_key}"
        async with self._lock:
            existing = self._artifacts.get(key)
            if existing:
                existing.frequency += 1
                existing.last_seen = time.time()
            else:
                self._artifacts[key] = CognitiveArtifact(
                    artifact_type="pattern",
                    key=key,
                    value={"pattern": pattern_key, "description": description},
                    confidence=confidence,
                    frequency=1,
                    last_seen=time.time(),
                    created_at=time.time(),
                )
            await self._compact_if_needed()

    async def add_anomaly_insight(
        self,
        insight_key: str,
        description: str,
        severity: str,
    ) -> None:
        """Dodaj Anomaly Insight artifact."""
        key = f"ani:{insight_key}"
        async with self._lock:
            existing = self._artifacts.get(key)
            if existing:
                existing.frequency += 1
                existing.last_seen = time.time()
            else:
                confidence = {"high": 0.9, "medium": 0.6, "low": 0.3}.get(severity, 0.5)
                self._artifacts[key] = CognitiveArtifact(
                    artifact_type="anomaly_insight",
                    key=key,
                    value={"insight": insight_key, "description": description, "severity": severity},
                    confidence=confidence,
                    frequency=1,
                    last_seen=time.time(),
                    created_at=time.time(),
                )
            await self._compact_if_needed()

    async def query(
        self,
        artifact_type: str | None = None,
        min_confidence: float = 0.0,
        limit: int = 20,
    ) -> list[CognitiveArtifact]:
        """Przeszukaj Cognitive Artifacts."""
        async with self._lock:
            results = list(self._artifacts.values())
            if artifact_type:
                results = [a for a in results if a.artifact_type == artifact_type]
            if min_confidence > 0:
                results = [a for a in results if a.confidence >= min_confidence]
            # Sortuj: najpierw najczęstsze, potem najnowsze
            results.sort(key=lambda a: (a.frequency, a.last_seen), reverse=True)
            return results[:limit]

    async def get_decision_pattern(self, contractor_nip: str, category: str) -> dict[str, Any] | None:
        """Sprawdź czy istnieje znany wzorzec decyzyjny dla kontrahenta+kategorii."""
        key = f"dc:{contractor_nip}:{category}"
        async with self._lock:
            artifact = self._artifacts.get(key)
            if artifact and artifact.frequency >= self.MIN_FREQUENCY:
                return {
                    "typical_decision": artifact.value.get("typical_decision", "unknown"),
                    "confidence": artifact.confidence,
                    "frequency": artifact.frequency,
                }
            return None

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki FM."""
        async with self._lock:
            types: dict[str, int] = defaultdict(int)
            for a in self._artifacts.values():
                types[a.artifact_type] += 1
            return {
                "total_artifacts": len(self._artifacts),
                "by_type": dict(types),
                "avg_confidence": round(
                    sum(a.confidence for a in self._artifacts.values()) / max(len(self._artifacts), 1), 4
                ),
            }

    async def _compact_if_needed(self) -> None:
        """Automatyczna kompresja — scalić duplikaty, usunąć rzadkie wzorce."""
        if len(self._artifacts) < self.MAX_ARTIFACTS:
            return
        now = time.time()
        if now - self._last_compaction < 3600:  # max raz na godzinę
            return
        self._last_compaction = now
        # Usuń artifacty o niskiej częstotliwości
        to_remove = [
            k for k, a in self._artifacts.items()
            if a.frequency < self.MIN_FREQUENCY and now - a.created_at > 86400 * 7  # starsze niż tydzień
        ]
        for k in to_remove:
            del self._artifacts[k]
        logger.info("[PLE:FM] compaction removed %d low-frequency artifacts", len(to_remove))

    async def clear(self) -> None:
        """Wyczyść FM."""
        async with self._lock:
            self._artifacts.clear()
            logger.info("[PLE:FM] cleared")


# ---------------------------------------------------------------------------
# PLE Engine — główny orchestrator
# ---------------------------------------------------------------------------

class PLEEngine:
    """Perpetual Learning Engine — główny orchestrator trójwarstwowej pamięci.

    Automatycznie:
      1. Zapisuje każdą decyzję do STM
      2. Promuje do LTM przy 3+ wpisach na kontrahenta
      3. Tworzy Cognitive Artifacts w FM przy powtarzalnych wzorcach
      4. Wykorzystuje LTM do adaptacji progów Trust Score
      5. Wykorzystuje FM do predykcji typowej decyzji
    """

    def __init__(self, config: AppConfig | None = None) -> None:
        self._config = config or AppConfig()
        self._stm = ShortTermMemory()
        self._ltm = LongTermMemory()
        self._fm = FusionMemory()
        self._stats_lock = asyncio.Lock()
        self._stats: dict[str, Any] = {
            "total_decisions_processed": 0,
            "stm_promotions_to_ltm": 0,
            "fm_artifacts_created": 0,
            "fm_patterns_matched": 0,
        }

    async def record_decision(
        self,
        invoice_id: str,
        decision: str,
        trust_score: float,
        trust_components: dict[str, float],
        contractor_nip: str,
        category: str,
        amount_gross: float,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        """Zarejestruj decyzję we wszystkich warstwach PLE.

        Automatyczna promocja: STM → LTM → FM (Cognitive Artifacts).
        """
        record = DecisionRecord(
            invoice_id=invoice_id,
            decision=decision,
            trust_score=trust_score,
            trust_components=trust_components,
            contractor_nip=contractor_nip or "unknown",
            category=category or "unknown",
            amount_gross=float(amount_gross),
            timestamp=time.time(),
            metadata=metadata or {},
        )

        # 1. STM
        await self._stm.push(record)

        # 2. LTM — zapisz zawsze (LTM ma własny mechanizm retention)
        await self._ltm.store(record)

        # 3. FM — Cognitive Artifacts dla powtarzalnych wzorców
        await self._build_cognitive_artifacts(record)

        # 4. Statystyki
        async with self._stats_lock:
            self._stats["total_decisions_processed"] += 1

        logger.debug(
            "[PLE] recorded decision=%s trust=%.4f nip=%s cat=%s amount=%.2f",
            decision, trust_score, contractor_nip, category, amount_gross,
        )

    async def record_user_correction(
        self,
        invoice_id: str,
        correction: str,
        contractor_nip: str,
        category: str,
    ) -> None:
        """Zarejestruj korektę użytkownika dla wcześniejszej decyzji."""
        # Znajdź rekord w STM
        stm_records = await self._stm.query(limit=50)
        for r in stm_records:
            if r.invoice_id == invoice_id:
                r.user_correction = correction
                # Jeśli użytkownik skorygował, oznacza to że wzorzec jest inny
                await self._fm.add_anomaly_insight(
                    insight_key=f"correction:{contractor_nip}:{category}",
                    description=f"User corrected decision from {r.decision} to {correction}",
                    severity="medium" if r.decision == "AUTO_POST" else "low",
                )
                break

    async def get_decision_pattern(
        self,
        contractor_nip: str,
        category: str,
    ) -> dict[str, Any] | None:
        """Sprawdź czy istnieje znany wzorzec decyzyjny.

        Najpierw sprawdza FM (Cognitive Artifacts), potem LTM.
        Jeśli wzorzec znaleziony i ma wysokie confidence → zwróć go.
        """
        async with self._stats_lock:
            self._stats["fm_patterns_matched"] += 1

        # 1. FM — szybkie cache wzorców
        fm_pattern = await self._fm.get_decision_pattern(contractor_nip, category)
        if fm_pattern and fm_pattern["confidence"] >= 0.85:
            return {
                "source": "fm",
                "typical_decision": fm_pattern["typical_decision"],
                "confidence": fm_pattern["confidence"],
                "frequency": fm_pattern["frequency"],
            }

        # 2. LTM — analiza historii kontrahenta
        ltm_records = await self._ltm.query(
            contractor_nip=contractor_nip,
            category=category,
            limit=20,
        )
        if len(ltm_records) >= 3:
            decisions = [r.decision for r in ltm_records]
            auto_post_count = decisions.count("AUTO_POST")
            auto_post_rate = auto_post_count / len(decisions)

            if auto_post_rate >= 0.85:
                # Promuj do FM
                await self._fm.add_decision_cache(
                    contractor_nip=contractor_nip,
                    category=category,
                    decision="AUTO_POST",
                    trust_score=sum(r.trust_score for r in ltm_records) / len(ltm_records),
                )
                return {
                    "source": "ltm",
                    "typical_decision": "AUTO_POST",
                    "confidence": round(auto_post_rate, 4),
                    "frequency": len(decisions),
                }

        return None

    async def get_vendor_profile(self, contractor_nip: str) -> dict[str, Any]:
        """Zwróć profil kontrahenta z LTM."""
        return await self._ltm.get_vendor_profile(contractor_nip)

    async def get_adapted_thresholds(
        self,
        base_thresholds: dict[str, float],
        contractor_nip: str | None = None,
        category: str | None = None,
    ) -> dict[str, float]:
        """Adaptuj progi decyzyjne na podstawie PLE.

        Jeśli FM ma wzorzec dla kontrahenta → obniż próg auto_post.
        Jeśli LTM pokazuje wysoką blokadę → podnieś próg ask_user.
        """
        adapted = dict(base_thresholds)

        # 1. FM — znany wzorzec → bardziej agresywny auto_post
        if contractor_nip and category:
            pattern = await self._fm.get_decision_pattern(contractor_nip, category)
            if pattern and pattern["confidence"] >= 0.85:
                adapted["auto_post"] = max(adapted["auto_post"] - 0.05, 0.70)
                logger.debug(
                    "[PLE] FM pattern matched for nip=%s cat=%s → auto_post threshold adjusted to %.4f",
                    contractor_nip, category, adapted["auto_post"],
                )

        return adapted

    async def get_briefing_data(self) -> dict[str, Any]:
        """Generuj dane do Daily Briefing na podstawie PLE."""
        stm_stats = await self._stm.get_stats()
        ltm_stats = await self._ltm.get_stats()
        fm_stats = await self._fm.get_stats()

        async with self._stats_lock:
            total = self._stats["total_decisions_processed"]

        return {
            "stm": stm_stats,
            "ltm": ltm_stats,
            "fm": fm_stats,
            "total_decisions_processed": total,
            "patterns_available": fm_stats.get("total_artifacts", 0) > 0,
        }

    async def _build_cognitive_artifacts(self, record: DecisionRecord) -> None:
        """Buduj Cognitive Artifacts na podstawie nowego rekordu."""
        # 1. Decision Cache — jeśli kontrahent ma kategorię
        if record.contractor_nip and record.category:
            await self._fm.add_decision_cache(
                contractor_nip=record.contractor_nip,
                category=record.category,
                decision=record.decision,
                trust_score=record.trust_score,
            )

        # 2. Pattern Library — dla powtarzalnych decyzji
        ltm_records = await self._ltm.query(
            contractor_nip=record.contractor_nip,
            category=record.category,
            limit=10,
        )
        if len(ltm_records) >= 3:
            decisions = [r.decision for r in ltm_records]
            # Jeśli wszystkie decyzje są AUTO_POST → wzorzec
            if all(d == "AUTO_POST" for d in decisions):
                await self._fm.add_pattern(
                    pattern_key=f"auto_post:{record.contractor_nip}:{record.category}",
                    description=f"All {len(decisions)} decisions for this vendor+category are AUTO_POST",
                    confidence=0.9,
                )

        # 3. Anomaly Insights — dla BLOCK/ASK_USER z niskim trust score
        if record.decision in ("BLOCK", "ASK_USER") and record.trust_score < 0.5:
            severity = "high" if record.decision == "BLOCK" and record.trust_score < 0.3 else "medium"
            await self._fm.add_anomaly_insight(
                insight_key=f"low_trust:{record.contractor_nip}:{record.category}",
                description=f"Decision={record.decision} with trust={record.trust_score:.4f} for nip={record.contractor_nip}",
                severity=severity,
            )

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć pełne statystyki PLE."""
        async with self._stats_lock:
            return dict(self._stats)
