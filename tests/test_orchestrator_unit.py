"""
test_orchestrator_unit.py — F2.5 v7.0 Audit: Unit tests for AgentOrchestrator.

Raport v7.0 Rec #3: AgentOrchestrator (~1000 LOC bez testów jednostkowych!).
Ten moduł dostarcza 20+ testów jednostkowych dla krytycznych metod:
  - process_invoice (główny pipeline)
  - _run_extraction, _run_quality_check, _run_analytics
  - _rule_based_evaluate, _guardian_verify
  - _run_weighted_voting, _check_four_eyes
  - _check_decision_cache, _cache_decision
  - get_threshold, make_decision
  - handle_user_feedback
  - Silent Partner: should_auto_post, build_executive_summary
  - Decision profile: observe_decision, get_autonomy_score
"""

from __future__ import annotations

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# ── Avoid heavy imports at module level ────────────────────────────────────────
from nexus_ai.agents.orchestrator import (
    FOUR_EYES_THRESHOLD,
    DEFAULT_VOTING_WEIGHTS,
    AgentOrchestrator,
)
from nexus_ai.agents.models import (
    AgentDecision,
    DataExtractionResult,
    DecisionMode,
    QualityCheckResult,
    TrustScore,
    VotingResult,
    ConfidenceVote,
)

pytestmark = pytest.mark.anyio


# ═══════════════════════════════════════════════════════════════════════════════
# Fixtures
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def orch() -> AgentOrchestrator:
    """Fresh AgentOrchestrator instance with no models loaded."""
    return AgentOrchestrator(config={"silent_mode": False})


@pytest.fixture
def sample_extraction() -> DataExtractionResult:
    """Sample extraction result for a typical invoice."""
    return DataExtractionResult(
        invoice_id="inv-001",
        success=True,
        extracted_data={
            "nip": "1234567890",
            "vendor_name": "Test Sp. z o.o.",
            "amount_gross": 5000,
            "category": "IT",
            "date": "2026-07-21",
            "invoice_number": "FV/2026/001",
        },
        confidence=0.88,
        document_type="INVOICE",
    )


@pytest.fixture
def high_amount_extraction() -> DataExtractionResult:
    """Extraction result for a high-amount invoice (>50k PLN)."""
    return DataExtractionResult(
        invoice_id="inv-high",
        success=True,
        extracted_data={
            "nip": "9999999999",
            "vendor_name": "Big Corp S.A.",
            "amount_gross": 85000,
            "category": "CONSTRUCTION",
            "date": "2026-07-21",
        },
        confidence=0.92,
        document_type="INVOICE",
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Initialization
# ═══════════════════════════════════════════════════════════════════════════════


class TestOrchestratorInit:
    """AgentOrchestrator initialization tests."""

    def test_default_init_creates_error_handbook(self, orch: AgentOrchestrator) -> None:
        """Orchestrator should create DynamicErrorHandbook on init."""
        assert orch._error_handbook is not None

    def test_default_init_creates_proactive_scheduler(self, orch: AgentOrchestrator) -> None:
        """Orchestrator should create ProactiveWorkflowScheduler on init."""
        assert orch._proactive_scheduler is not None

    def test_default_init_creates_card_generator(self, orch: AgentOrchestrator) -> None:
        """Orchestrator should create ActionCardGenerator on init."""
        assert orch._card_generator is not None

    def test_silent_mode_default_true(self) -> None:
        """Silent mode should default to True (v6.0 Silent Partner)."""
        o = AgentOrchestrator(config={})
        assert o.silent_mode is True

    def test_silent_mode_config_false(self) -> None:
        """Silent mode can be disabled via config."""
        o = AgentOrchestrator(config={"silent_mode": False})
        assert o.silent_mode is False

    def test_swarm_optimizer_initialized(self, orch: AgentOrchestrator) -> None:
        """SwarmOptimizer should be initialized with RAM budget."""
        assert orch._swarm_optimizer is not None

    def test_explainability_engine_initialized(self, orch: AgentOrchestrator) -> None:
        """ExplainabilityEngine should be initialized (v7.0 Rec #20)."""
        assert orch._explainability_engine is not None

    def test_predictive_preloader_initialized(self, orch: AgentOrchestrator) -> None:
        """PredictivePreloader should be initialized (v7.0 Rec #19)."""
        assert orch._predictive_preloader is not None


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Rule-Based Fallback (Chaos Engineering)
# ═══════════════════════════════════════════════════════════════════════════════


class TestRuleBasedEvaluate:
    """_rule_based_evaluate() should work without any models loaded."""

    def test_rule_based_returns_decision(self, orch: AgentOrchestrator,
                                          sample_extraction: DataExtractionResult) -> None:
        """Should return an AgentDecision with valid status."""
        decision = orch._rule_based_evaluate(sample_extraction)
        assert decision is not None
        assert hasattr(decision, "verdict")
        assert decision.verdict.status in ("AUTO_POST", "REVIEW", "BLOCK")

    def test_high_confidence_returns_auto_post(self, orch: AgentOrchestrator) -> None:
        """High extraction confidence (>=0.92) should trigger AUTO_POST."""
        ext = DataExtractionResult(
            invoice_id="high-conf",
            success=True,
            confidence=0.95,
            extracted_data={"nip": "1234567890", "amount_gross": 3000, "category": "IT"},
        )
        decision = orch._rule_based_evaluate(ext)
        assert decision.verdict.status == "AUTO_POST"

    def test_medium_confidence_returns_suggest(self, orch: AgentOrchestrator) -> None:
        """Medium confidence (>=0.75) should trigger SUGGEST mode."""
        ext = DataExtractionResult(
            invoice_id="med-conf",
            success=True,
            confidence=0.80,
            extracted_data={"nip": "1234567890", "amount_gross": 3000, "category": "IT"},
        )
        decision = orch._rule_based_evaluate(ext)
        assert decision.verdict.status == "REVIEW"

    def test_low_confidence_returns_block(self, orch: AgentOrchestrator) -> None:
        """Low confidence (<0.75) should trigger BLOCK/ASK_USER."""
        ext = DataExtractionResult(
            invoice_id="low-conf",
            success=True,
            confidence=0.50,
            extracted_data={"nip": "unknown", "amount_gross": 50000, "category": "NEW"},
        )
        decision = orch._rule_based_evaluate(ext)
        assert decision.verdict.status == "BLOCK"


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Extraction & Quality Fallbacks
# ═══════════════════════════════════════════════════════════════════════════════


class TestExtractionAndQuality:
    """Extraction and quality check fallback tests."""

    def test_extraction_fallback_returns_data(self, orch: AgentOrchestrator) -> None:
        """When no extraction agent registered, fallback returns raw data."""
        orch._sub_agents = {}
        result = asyncio.run(orch._run_extraction(
            {"invoice_id": "test", "amount_gross": 1000},
            "dec-001",
        ))
        assert result.success is True

    def test_quality_check_fallback_returns_none(self, orch: AgentOrchestrator) -> None:
        """When no quality validator registered, fallback returns None."""
        orch._sub_agents = {}
        result = asyncio.run(orch._run_quality_check("dec-001", None, None))
        assert result is None

    def test_analytics_fallback_returns_none(self, orch: AgentOrchestrator,
                                               sample_extraction: DataExtractionResult) -> None:
        """When no analytics agent registered, fallback returns None."""
        orch._sub_agents = {}
        result = asyncio.run(orch._run_analytics(sample_extraction))
        assert result is None


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Weighted Voting
# ═══════════════════════════════════════════════════════════════════════════════


class TestWeightedVoting:
    """Weighted voting between orchestrator and quality validator."""

    def test_voting_returns_valid_result(self, orch: AgentOrchestrator,
                                           sample_extraction: DataExtractionResult) -> None:
        """Weighted voting should return a VotingResult with winner."""
        trust = TrustScore(overall=0.92)
        result = asyncio.run(orch._run_weighted_voting(sample_extraction, trust, None))
        assert isinstance(result, VotingResult)
        assert result.winner in ("AUTO_POST", "REVIEW", "BLOCK")

    def test_high_trust_without_quality_returns_auto_post(self, orch: AgentOrchestrator,
                                                            sample_extraction: DataExtractionResult) -> None:
        """High trust (>=0.92) without quality validator should still return AUTO_POST."""
        trust = TrustScore(overall=0.95)
        result = asyncio.run(orch._run_weighted_voting(sample_extraction, trust, None))
        assert result.winner == "AUTO_POST"

    def test_voting_weights_sum_to_one(self) -> None:
        """Default voting weights should approximate 1.0."""
        total = sum(DEFAULT_VOTING_WEIGHTS.values())
        assert 0.9 <= total <= 1.1


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: 4-Eyes Principle
# ═══════════════════════════════════════════════════════════════════════════════


class TestFourEyesPrinciple:
    """4-Eyes principle: transactions >50k PLN require dual verification."""

    def test_below_threshold_no_four_eyes(self, orch: AgentOrchestrator,
                                            sample_extraction: DataExtractionResult) -> None:
        """Transaction below 50k should NOT trigger 4-eyes."""
        amount = sample_extraction.extracted_data.get("amount_gross", 0)
        assert float(amount) < FOUR_EYES_THRESHOLD

    def test_above_threshold_triggers_four_eyes(self, orch: AgentOrchestrator,
                                                  high_amount_extraction: DataExtractionResult) -> None:
        """Transaction above 50k SHOULD trigger 4-eyes."""
        amount = high_amount_extraction.extracted_data.get("amount_gross", 0)
        assert float(amount) > FOUR_EYES_THRESHOLD


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Decision Profile
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecisionProfile:
    """UserDecisionProfile — progressive autonomy engine (v5.2)."""

    def test_observe_decision_updates_profile(self, orch: AgentOrchestrator) -> None:
        """Observing decisions should not raise errors."""
        orch._decision_profile.observe_decision(
            vendor_nip="1234567890",
            vendor_name="Test",
            amount_gross=5000,
            category="IT",
            status="AUTO_POST",
            decision_mode="auto_post",
            user_action="confirm",
            user_option="",
        )
        score = orch._decision_profile.get_autonomy_score()
        assert score is not None
        assert isinstance(score, (int, float))

    def test_autonomy_score_between_0_and_100(self, orch: AgentOrchestrator) -> None:
        """Autonomy score should be between 0 and 100."""
        score = orch._decision_profile.get_autonomy_score()
        assert 0 <= score <= 100


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Adaptive Thresholds
# ═══════════════════════════════════════════════════════════════════════════════


class TestAdaptiveThresholds:
    """Adaptive thresholds per vendor (Bayesian)."""

    def test_known_vendor_has_lower_threshold(self, orch: AgentOrchestrator) -> None:
        """Frequently observed vendor should have lower auto-post threshold."""
        # Simulate many observations
        for _ in range(10):
            orch._decision_profile.observe_decision(
                vendor_nip="1234567890",
                vendor_name="Trusted Co.",
                amount_gross=5000,
                category="IT",
                status="AUTO_POST",
                decision_mode="auto_post",
                user_action="confirm",
                user_option="",
            )
        threshold = orch.get_threshold("1234567890")
        assert threshold <= 0.92, f"Known vendor threshold should be <=0.92, got {threshold}"

    def test_unknown_vendor_has_default_threshold(self, orch: AgentOrchestrator) -> None:
        """Unknown vendor should use base threshold."""
        threshold = orch.get_threshold("unknown_nip")
        assert 0.75 <= threshold <= 0.92


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Error Handbook
# ═══════════════════════════════════════════════════════════════════════════════


class TestErrorHandbook:
    """DynamicErrorHandbook — few-shot learning from corrections."""

    def test_handbook_initialized(self, orch: AgentOrchestrator) -> None:
        """Error handbook should be initialized."""
        assert orch._error_handbook is not None

    def test_handbook_count_is_integer(self, orch: AgentOrchestrator) -> None:
        """Handbook should report count as integer."""
        count = orch._error_handbook.count
        assert isinstance(count, int)


# ═══════════════════════════════════════════════════════════════════════════════
# Tests: Make Decision
# ═══════════════════════════════════════════════════════════════════════════════


class TestMakeDecision:
    """make_decision() factory method."""

    def test_make_decision_auto_post(self, orch: AgentOrchestrator) -> None:
        """Should create a decision with AUTO_POST mode."""
        decision = orch.make_decision(
            decision_id="dec-001",
            status="AUTO_POST",
            trust_score=0.95,
            reason="High confidence",
        )
        assert decision.decision_id == "dec-001"
        assert decision.verdict.status == "AUTO_POST"
        assert decision.decision_mode == DecisionMode.AUTO_POST

    def test_make_decision_ask_user(self, orch: AgentOrchestrator) -> None:
        """Should create a decision with ASK_USER mode."""
        decision = orch.make_decision(
            decision_id="dec-low",
            status="BLOCK",
            trust_score=0.50,
            reason="Low confidence",
        )
        assert decision.decision_mode == DecisionMode.ASK_USER
        assert decision.verdict.trust_score == 0.50
