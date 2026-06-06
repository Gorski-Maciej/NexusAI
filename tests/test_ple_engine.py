"""
Testy dla Perpetual Learning Engine (PLE) — STM, LTM, FM, PLEEngine.

Sprawdza:
  - ShortTermMemory: push, query, data decay, stats, clear
  - LongTermMemory: store, query, vendor profile, weight calculation, stats, clear
  - FusionMemory: decision cache, pattern library, anomaly insights, query, compaction
  - PLEEngine: record_decision, user correction, decision pattern, adapted thresholds, briefing
"""

from __future__ import annotations

import sys
import time
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from services.ple_engine import (
    DecisionRecord,
    CognitiveArtifact,
    ShortTermMemory,
    LongTermMemory,
    FusionMemory,
    PLEEngine,
)
from core.config import AppConfig


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def sample_record() -> DecisionRecord:
    return DecisionRecord(
        invoice_id="inv-001",
        decision="AUTO_POST",
        trust_score=0.92,
        trust_components={"ai_confidence": 0.9, "vendor_reliability": 0.85},
        contractor_nip="1234567890",
        category="usługi",
        amount_gross=1230.0,
        timestamp=time.time(),
    )


@pytest.fixture
def low_trust_record() -> DecisionRecord:
    return DecisionRecord(
        invoice_id="inv-002",
        decision="BLOCK",
        trust_score=0.3,
        trust_components={"ai_confidence": 0.3, "vendor_reliability": 0.2},
        contractor_nip="1234567890",
        category="usługi",
        amount_gross=99999.0,
        timestamp=time.time(),
    )


# ===========================================================================
# SHORT-TERM MEMORY
# ===========================================================================

class TestShortTermMemory:
    """Testy dla STM — pamięć krótkoterminowa."""

    @pytest.mark.asyncio
    async def test_push_and_query(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        results = await stm.query(limit=10)
        assert len(results) == 1
        assert results[0].invoice_id == "inv-001"
        assert results[0].decision == "AUTO_POST"

    @pytest.mark.asyncio
    async def test_query_by_contractor(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        results = await stm.query(contractor_nip="1234567890", limit=10)
        assert len(results) == 1
        results = await stm.query(contractor_nip="9999999999", limit=10)
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_query_by_category(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        results = await stm.query(category="usługi", limit=10)
        assert len(results) == 1
        results = await stm.query(category="czynsz", limit=10)
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_query_by_min_confidence(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        results = await stm.query(min_confidence=0.9, limit=10)
        assert len(results) == 1
        results = await stm.query(min_confidence=0.95, limit=10)
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_max_size(self) -> None:
        """STM powinno przechowywać max 50 rekordów."""
        stm = ShortTermMemory()
        for i in range(60):
            await stm.push(DecisionRecord(
                invoice_id=f"inv-{i:03d}",
                decision="AUTO_POST",
                trust_score=0.9,
                trust_components={},
                contractor_nip="test",
                category="test",
                amount_gross=100.0,
                timestamp=time.time(),
            ))
        results = await stm.query(limit=100)
        assert len(results) == 50  # MAX_SIZE

    @pytest.mark.asyncio
    async def test_stats_empty(self) -> None:
        stm = ShortTermMemory()
        stats = await stm.get_stats()
        assert stats["size"] == 0
        assert stats["avg_trust"] == 0.0

    @pytest.mark.asyncio
    async def test_stats_with_data(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        stats = await stm.get_stats()
        assert stats["size"] == 1
        assert stats["avg_trust"] == 0.92
        assert stats["decisions"]["AUTO_POST"] == 1

    @pytest.mark.asyncio
    async def test_clear(self, sample_record: DecisionRecord) -> None:
        stm = ShortTermMemory()
        await stm.push(sample_record)
        await stm.clear()
        stats = await stm.get_stats()
        assert stats["size"] == 0

    @pytest.mark.asyncio
    async def test_age_property(self) -> None:
        record = DecisionRecord(
            invoice_id="inv-old",
            decision="BLOCK",
            trust_score=0.5,
            trust_components={},
            contractor_nip="test",
            category="test",
            amount_gross=100.0,
            timestamp=time.time() - 7200,  # 2h ago
        )
        assert record.age_hours > 1.9
        assert record.age_hours < 2.1

    @pytest.mark.asyncio
    async def test_to_dict(self, sample_record: DecisionRecord) -> None:
        d = sample_record.to_dict()
        assert d["invoice_id"] == "inv-001"
        assert d["decision"] == "AUTO_POST"
        assert d["trust_score"] == 0.92

    @pytest.mark.asyncio
    async def test_from_dict(self) -> None:
        data = {
            "invoice_id": "inv-001",
            "decision": "AUTO_POST",
            "trust_score": 0.92,
            "trust_components": {},
            "contractor_nip": "1234567890",
            "category": "usługi",
            "amount_gross": 1230.0,
            "timestamp": time.time(),
        }
        record = DecisionRecord.from_dict(data)
        assert record.invoice_id == "inv-001"
        assert record.decision == "AUTO_POST"


# ===========================================================================
# LONG-TERM MEMORY
# ===========================================================================

class TestLongTermMemory:
    """Testy dla LTM — pamięć długoterminowa."""

    @pytest.mark.asyncio
    async def test_store_and_query(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        await ltm.store(sample_record)
        results = await ltm.query(limit=10)
        assert len(results) >= 1

    @pytest.mark.asyncio
    async def test_query_by_contractor(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        await ltm.store(sample_record)
        results = await ltm.query(contractor_nip="1234567890", limit=10)
        assert len(results) >= 1
        results = await ltm.query(contractor_nip="nonexistent", limit=10)
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_vendor_profile_known(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        await ltm.store(sample_record)
        profile = await ltm.get_vendor_profile("1234567890")
        assert profile["known"] is True
        assert profile["invoice_count"] >= 1
        assert profile["auto_post_rate"] > 0
        assert "trust_trend" in profile

    @pytest.mark.asyncio
    async def test_vendor_profile_unknown(self) -> None:
        ltm = LongTermMemory()
        profile = await ltm.get_vendor_profile("0000000000")
        assert profile["known"] is False
        assert profile["invoice_count"] == 0

    @pytest.mark.asyncio
    async def test_stats_empty(self) -> None:
        ltm = LongTermMemory()
        stats = await ltm.get_stats()
        assert stats["total_records"] == 0

    @pytest.mark.asyncio
    async def test_stats_with_data(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        await ltm.store(sample_record)
        stats = await ltm.get_stats()
        assert stats["total_records"] >= 1
        assert stats["unique_vendors"] >= 1

    @pytest.mark.asyncio
    async def test_clear(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        await ltm.store(sample_record)
        await ltm.clear()
        stats = await ltm.get_stats()
        assert stats["total_records"] == 0

    def test_calculate_weight_fresh(self, sample_record: DecisionRecord) -> None:
        ltm = LongTermMemory()
        weight = ltm._calculate_weight(sample_record)
        assert weight > 0.9  # prawie 1.0 dla świeżego rekordu

    def test_calculate_weight_old(self) -> None:
        ltm = LongTermMemory()
        old_record = DecisionRecord(
            invoice_id="inv-old",
            decision="BLOCK",
            trust_score=0.5,
            trust_components={},
            contractor_nip="test",
            category="test",
            amount_gross=100.0,
            timestamp=time.time() - (365 * 24 * 3600),  # 1 year ago
        )
        weight = ltm._calculate_weight(old_record)
        assert weight < 0.5  # waga powinna być znacząco niższa

    def test_compute_trend_up(self) -> None:
        """
        scores are in DESC order (most recent first).
        _compute_trend: recent = scores[:3], older = scores[-3:].
        So recent=[0.9,0.85,0.8], older=[0.5,0.5,0.5] → diff=+0.35 → "up".
        """
        assert LongTermMemory._compute_trend([0.9, 0.85, 0.8, 0.5, 0.5, 0.5]) == "up"

    def test_compute_trend_down(self) -> None:
        """
        scores are in DESC order (most recent first).
        _compute_trend: recent = scores[:3], older = scores[-3:].
        So recent=[0.5,0.5,0.5], older=[0.8,0.85,0.9] → diff=-0.35 → "down".
        """
        assert LongTermMemory._compute_trend([0.5, 0.5, 0.5, 0.8, 0.85, 0.9]) == "down"

    def test_compute_trend_stable(self) -> None:
        assert LongTermMemory._compute_trend([0.7, 0.71, 0.69, 0.7]) == "stable"

    def test_compute_trend_insufficient(self) -> None:
        assert LongTermMemory._compute_trend([0.9]) == "stable"


# ===========================================================================
# FUSION MEMORY
# ===========================================================================

class TestFusionMemory:
    """Testy dla FM — pamięć fuzyjna (Cognitive Artifacts)."""

    @pytest.mark.asyncio
    async def test_add_decision_cache(self) -> None:
        fm = FusionMemory()
        await fm.add_decision_cache("1234567890", "usługi", "AUTO_POST", 0.92)
        pattern = await fm.get_decision_pattern("1234567890", "usługi")
        assert pattern is None  # frequency < MIN_FREQUENCY (2)

    @pytest.mark.asyncio
    async def test_add_decision_cache_repeated(self) -> None:
        fm = FusionMemory()
        for _ in range(3):
            await fm.add_decision_cache("1234567890", "usługi", "AUTO_POST", 0.92)
        pattern = await fm.get_decision_pattern("1234567890", "usługi")
        assert pattern is not None
        assert pattern["typical_decision"] == "AUTO_POST"
        assert pattern["frequency"] >= 2

    @pytest.mark.asyncio
    async def test_add_pattern(self) -> None:
        fm = FusionMemory()
        await fm.add_pattern("auto_post:vendorX:usługi", "High auto-post rate", 0.9)
        results = await fm.query(artifact_type="pattern")
        assert len(results) == 1
        assert results[0].artifact_type == "pattern"
        assert results[0].key == "pat:auto_post:vendorX:usługi"

    @pytest.mark.asyncio
    async def test_add_anomaly_insight(self) -> None:
        fm = FusionMemory()
        await fm.add_anomaly_insight(
            "low_trust:vendorX:usługi",
            "Low trust score detected",
            "high",
        )
        results = await fm.query(artifact_type="anomaly_insight")
        assert len(results) == 1
        assert results[0].artifact_type == "anomaly_insight"
        assert results[0].confidence == 0.9  # high → 0.9

    @pytest.mark.asyncio
    async def test_add_anomaly_insight_medium(self) -> None:
        fm = FusionMemory()
        await fm.add_anomaly_insight(
            "test_insight",
            "Medium anomaly",
            "medium",
        )
        results = await fm.query(artifact_type="anomaly_insight")
        assert results[0].confidence == 0.6

    @pytest.mark.asyncio
    async def test_add_anomaly_insight_low(self) -> None:
        fm = FusionMemory()
        await fm.add_anomaly_insight(
            "test_insight",
            "Low anomaly",
            "low",
        )
        results = await fm.query(artifact_type="anomaly_insight")
        assert results[0].confidence == 0.3

    @pytest.mark.asyncio
    async def test_query_by_type(self) -> None:
        fm = FusionMemory()
        await fm.add_decision_cache("nip1", "cat1", "AUTO_POST", 0.9)
        await fm.add_pattern("pat1", "desc", 0.8)
        await fm.add_anomaly_insight("ani1", "desc", "medium")

        assert len(await fm.query(artifact_type="decision_cache")) == 1
        assert len(await fm.query(artifact_type="pattern")) == 1
        assert len(await fm.query(artifact_type="anomaly_insight")) == 1

    @pytest.mark.asyncio
    async def test_query_by_min_confidence(self) -> None:
        fm = FusionMemory()
        await fm.add_decision_cache("nip1", "cat1", "AUTO_POST", 0.5)
        await fm.add_decision_cache("nip2", "cat2", "AUTO_POST", 0.9)

        results = await fm.query(min_confidence=0.8)
        assert len(results) == 1

    @pytest.mark.asyncio
    async def test_get_decision_pattern_unknown(self) -> None:
        fm = FusionMemory()
        pattern = await fm.get_decision_pattern("unknown", "unknown")
        assert pattern is None

    @pytest.mark.asyncio
    async def test_stats_empty(self) -> None:
        fm = FusionMemory()
        stats = await fm.get_stats()
        assert stats["total_artifacts"] == 0

    @pytest.mark.asyncio
    async def test_stats_with_data(self) -> None:
        fm = FusionMemory()
        await fm.add_decision_cache("nip1", "cat1", "AUTO_POST", 0.9)
        stats = await fm.get_stats()
        assert stats["total_artifacts"] == 1
        assert stats["by_type"]["decision_cache"] == 1

    @pytest.mark.asyncio
    async def test_clear(self) -> None:
        fm = FusionMemory()
        await fm.add_decision_cache("nip1", "cat1", "AUTO_POST", 0.9)
        await fm.clear()
        stats = await fm.get_stats()
        assert stats["total_artifacts"] == 0


# ===========================================================================
# PLE ENGINE
# ===========================================================================

class TestPLEEngine:
    """Testy dla PLEEngine — główny orchestrator."""

    @pytest.mark.asyncio
    async def test_record_decision(self) -> None:
        ple = PLEEngine()
        await ple.record_decision(
            invoice_id="inv-001",
            decision="AUTO_POST",
            trust_score=0.92,
            trust_components={"ai_confidence": 0.9},
            contractor_nip="1234567890",
            category="usługi",
            amount_gross=1230.0,
        )
        stats = await ple.get_stats()
        assert stats["total_decisions_processed"] == 1

    @pytest.mark.asyncio
    async def test_record_multiple_decisions(self) -> None:
        ple = PLEEngine()
        for i in range(5):
            await ple.record_decision(
                invoice_id=f"inv-{i:03d}",
                decision="AUTO_POST",
                trust_score=0.9,
                trust_components={},
                contractor_nip="1234567890",
                category="usługi",
                amount_gross=1000.0,
            )
        stats = await ple.get_stats()
        assert stats["total_decisions_processed"] == 5

    @pytest.mark.asyncio
    async def test_get_decision_pattern_none(self) -> None:
        ple = PLEEngine()
        pattern = await ple.get_decision_pattern("new_vendor", "unknown")
        assert pattern is None

    @pytest.mark.asyncio
    async def test_get_decision_pattern_from_fm(self) -> None:
        """Po wielokrotnych AUTO_POST powinien znaleźć wzorzec w FM."""
        ple = PLEEngine()
        for i in range(5):
            await ple.record_decision(
                invoice_id=f"inv-{i:03d}",
                decision="AUTO_POST",
                trust_score=0.95,
                trust_components={"ai_confidence": 0.95},
                contractor_nip="known_vendor",
                category="czynsz",
                amount_gross=5000.0,
            )

        pattern = await ple.get_decision_pattern("known_vendor", "czynsz")
        assert pattern is not None
        assert pattern["typical_decision"] == "AUTO_POST"
        assert pattern["confidence"] >= 0.85

    @pytest.mark.asyncio
    async def test_get_adapted_thresholds(self) -> None:
        ple = PLEEngine()
        base = {"auto_post": 0.92, "suggest": 0.75, "ask_user": 0.50}
        adapted = await ple.get_adapted_thresholds(base, "known_vendor", "czynsz")
        assert adapted["auto_post"] <= base["auto_post"]  # znany wzorzec → niższy próg

    @pytest.mark.asyncio
    async def test_get_vendor_profile_unknown(self) -> None:
        ple = PLEEngine()
        profile = await ple.get_vendor_profile("0000000000")
        assert profile["known"] is False

    @pytest.mark.asyncio
    async def test_get_briefing_data_empty(self) -> None:
        ple = PLEEngine()
        data = await ple.get_briefing_data()
        assert data["stm"]["size"] == 0
        assert data["ltm"]["total_records"] == 0
        assert data["fm"]["total_artifacts"] == 0
        assert data["total_decisions_processed"] == 0
        assert data["patterns_available"] is False

    @pytest.mark.asyncio
    async def test_get_briefing_data_with_decisions(self) -> None:
        ple = PLEEngine()
        for i in range(3):
            await ple.record_decision(
                invoice_id=f"inv-{i:03d}",
                decision="AUTO_POST",
                trust_score=0.9,
                trust_components={},
                contractor_nip="v1",
                category="cat1",
                amount_gross=1000.0,
            )
        data = await ple.get_briefing_data()
        assert data["stm"]["size"] > 0
        assert data["total_decisions_processed"] == 3

    @pytest.mark.asyncio
    async def test_record_user_correction(self) -> None:
        ple = PLEEngine()
        await ple.record_decision(
            invoice_id="inv-001",
            decision="AUTO_POST",
            trust_score=0.92,
            trust_components={"ai_confidence": 0.9},
            contractor_nip="1234567890",
            category="usługi",
            amount_gross=1230.0,
        )
        await ple.record_user_correction(
            invoice_id="inv-001",
            correction="BLOCK",
            contractor_nip="1234567890",
            category="usługi",
        )
        # Powinien utworzyć anomaly insight
        insights = await ple._fm.query(artifact_type="anomaly_insight")
        assert len(insights) >= 1

    @pytest.mark.asyncio
    async def test_build_cognitive_artifacts_for_block(self, low_trust_record: DecisionRecord) -> None:
        ple = PLEEngine()
        await ple._build_cognitive_artifacts(low_trust_record)
        insights = await ple._fm.query(artifact_type="anomaly_insight")
        assert len(insights) >= 1


# ===========================================================================
# Cognitive Artifact
# ===========================================================================

class TestCognitiveArtifact:
    """Testy dla CognitiveArtifact — serializacja i deserializacja."""

    def test_to_dict(self) -> None:
        artifact = CognitiveArtifact(
            artifact_type="decision_cache",
            key="dc:vendor:cat",
            value={"decision": "AUTO_POST"},
            confidence=0.92,
            frequency=5,
            last_seen=1000.0,
            created_at=500.0,
        )
        d = artifact.to_dict()
        assert d["artifact_type"] == "decision_cache"
        assert d["confidence"] == 0.92
        assert d["frequency"] == 5

    def test_from_dict(self) -> None:
        data = {
            "artifact_type": "pattern",
            "key": "pat:test",
            "value": {"pattern": "test_pattern"},
            "confidence": 0.85,
            "frequency": 3,
            "last_seen": 1000.0,
            "created_at": 500.0,
        }
        artifact = CognitiveArtifact.from_dict(data)
        assert artifact.artifact_type == "pattern"
        assert artifact.confidence == 0.85
        assert artifact.frequency == 3
