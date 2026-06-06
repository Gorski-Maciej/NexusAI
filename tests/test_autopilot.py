"""
Testy dla Autopilot — TrustScoreCalculator i CouncilOrchestrator.

Sprawdza:
  - TrustScoreCalculator.calculate z różnymi danymi
  - TrustScoreCalculator._check_math i _check_nip
  - TrustScoreCalculator.get_adapted_thresholds
  - TrustScoreCalculator.update_weights_from_user_corrections
  - CouncilOrchestrator._resolve_decision z różnymi kombinacjami
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from services.autopilot import (
    TrustScoreCalculator,
    CouncilOrchestrator,
    FinalDecision,
    DEFAULT_WEIGHTS,
    DEFAULT_THRESHOLDS,
)
from services.council_agents import DecisionVerdict
from services.council_session import CouncilVerdict, DecisionLevel


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def calculator() -> TrustScoreCalculator:
    return TrustScoreCalculator()


@pytest.fixture
def perfect_invoice() -> dict:
    """Faktura z idealnymi danymi — wszystkie kontrole przechodzą."""
    return {
        "ocr_confidence": 0.98,
        "layout_confidence": 0.95,
        "amount_consensus": True,
        "llm_validation": 0.95,
        "vendor_profile": {
            "known": True,
            "invoice_count": 25,
            "trust_score": 0.95,
            "category_consistent": True,
            "auto_approve": True,
            "category_preference_match": True,
        },
        "contractor_nip": "1234567890",
        "amount_net": 1000.0,
        "vat": 230.0,
        "amount_gross": 1230.0,
        "bank_account_consistent": True,
        "amount_typical": True,
        "category": "czynsz",
    }


@pytest.fixture
def suspicious_invoice() -> dict:
    """Faktura z podejrzanymi danymi — wiele czerwonych flag."""
    return {
        "ocr_confidence": 0.3,
        "layout_confidence": 0.25,
        "amount_consensus": False,
        "llm_validation": 0.2,
        "vendor_profile": {
            "known": False,
            "invoice_count": 0,
            "trust_score": 0.0,
            "category_consistent": False,
            "auto_approve": False,
            "category_preference_match": False,
        },
        "contractor_nip": "12345",
        "amount_net": 10000.0,
        "vat": 2000.0,
        "amount_gross": 15000.0,  # netto + vat ≠ brutto!
        "bank_account_consistent": False,
        "amount_typical": False,
        "category": "doradztwo",
    }


# ===========================================================================
# Trust Score Calculator
# ===========================================================================

class TestTrustScoreCalculator:
    """Testy dla TrustScoreCalculator."""

    def test_perfect_trust_score(self, calculator: TrustScoreCalculator, perfect_invoice: dict) -> None:
        """Idealne dane → trust score powinien być bardzo wysoki."""
        alpha = DecisionVerdict("APPROVE", 0.95, "OK")
        beta = DecisionVerdict("APPROVE", 0.9, "OK")
        gamma = DecisionVerdict("APPROVE", 0.85, "OK")

        result = calculator.calculate(perfect_invoice, alpha, beta, gamma)
        assert result["trust_score"] >= 0.85
        assert all(v > 0 for v in result["components"].values())
        assert "raw" in result

    def test_suspicious_trust_score(self, calculator: TrustScoreCalculator, suspicious_invoice: dict) -> None:
        """Podejrzane dane → trust score powinien być niski."""
        alpha = DecisionVerdict("REJECT", 0.3, "Suspicious")
        beta = DecisionVerdict("REJECT", 0.2, "Math error")
        gamma = DecisionVerdict("REJECT", 0.25, "Anomaly")

        result = calculator.calculate(suspicious_invoice, alpha, beta, gamma)
        assert result["trust_score"] < 0.4

    def test_default_weights_are_correct(self) -> None:
        """Domyślne wagi powinny sumować się do 1.0."""
        total = sum(DEFAULT_WEIGHTS.values())
        assert abs(total - 1.0) < 0.01

    def test_trust_score_components_structure(self, calculator: TrustScoreCalculator, perfect_invoice: dict) -> None:
        """Struktura wyniku powinna zawierać wszystkie komponenty."""
        alpha = DecisionVerdict("APPROVE", 0.9, "OK")
        beta = DecisionVerdict("APPROVE", 0.9, "OK")
        gamma = DecisionVerdict("APPROVE", 0.9, "OK")

        result = calculator.calculate(perfect_invoice, alpha, beta, gamma)
        assert "trust_score" in result
        assert "components" in result
        assert "raw" in result

        components = result["components"]
        assert "ai_confidence" in components
        assert "vendor_reliability" in components
        assert "data_consistency" in components
        assert "context_trust" in components

    def test_trust_score_clamped(self, calculator: TrustScoreCalculator) -> None:
        """Trust score powinien być zawsze w zakresie [0.0, 1.0]."""
        invoice = {
            "ocr_confidence": 999.0,  # nielogicznie wysokie
            "layout_confidence": 999.0,
            "amount_consensus": True,
            "llm_validation": 999.0,
            "vendor_profile": {
                "known": True,
                "invoice_count": 999,
                "trust_score": 999.0,
                "category_consistent": True,
                "auto_approve": True,
                "category_preference_match": True,
            },
            "contractor_nip": "1234567890",
            "amount_net": 100.0,
            "vat": 23.0,
            "amount_gross": 123.0,
            "bank_account_consistent": True,
            "amount_typical": True,
        }
        alpha = DecisionVerdict("APPROVE", 0.99, "OK")
        beta = DecisionVerdict("APPROVE", 0.99, "OK")
        gamma = DecisionVerdict("APPROVE", 0.99, "OK")

        result = calculator.calculate(invoice, alpha, beta, gamma)
        assert result["trust_score"] <= 1.0
        assert result["trust_score"] >= 0.0


# ===========================================================================
# Math & NIP validation
# ===========================================================================

class TestValidation:
    """Testy dla _check_math i _check_nip."""

    def test_check_math_correct(self) -> None:
        """Netto + VAT = brutto → OK."""
        data = {"amount_net": 1000.0, "vat": 230.0, "amount_gross": 1230.0}
        assert TrustScoreCalculator._check_math(data)

    def test_check_math_incorrect(self) -> None:
        """Netto + VAT ≠ brutto → błąd."""
        data = {"amount_net": 1000.0, "vat": 200.0, "amount_gross": 1230.0}
        assert not TrustScoreCalculator._check_math(data)

    def test_check_math_zero_gross(self) -> None:
        """Gross = 0 → pomiń walidację."""
        data = {"amount_net": 0.0, "vat": 0.0, "amount_gross": 0.0}
        assert TrustScoreCalculator._check_math(data)

    def test_check_math_tolerance(self) -> None:
        """Różnica ≤ 0.01 → OK.

        Uwaga: 123.01 w float to 123.01000000000000511591, więc
        abs(123.0 - 123.01) = 0.010000000000005116 > 0.01.
        Używamy 123.005 gdzie różnica wynosi ~0.005, wyraźnie ≤ 0.01.
        """
        data = {"amount_net": 100.0, "vat": 23.0, "amount_gross": 123.005}
        assert TrustScoreCalculator._check_math(data)

    def test_check_nip_valid(self) -> None:
        """Prawidłowy NIP (10 cyfr, poprawna suma kontrolna).

        NIP: 5252463191 — wagi (6,5,7,2,3,4,5,6,7):
        5*6+2*5+5*7+2*2+4*3+6*4+3*5+1*6+9*7 = 199 → 199%11 = 1 → ostatnia cyfra = 1 ✓
        """
        assert TrustScoreCalculator._check_nip("5252463191")

    def test_check_nip_invalid(self) -> None:
        """Nieprawidłowy NIP."""
        assert not TrustScoreCalculator._check_nip("1234567890")

    def test_check_nip_too_short(self) -> None:
        """Za krótki NIP."""
        assert not TrustScoreCalculator._check_nip("12345")

    def test_check_nip_with_dashes(self) -> None:
        """NIP z myślnikami powinien być normalizowany."""
        assert TrustScoreCalculator._check_nip("525-246-31-91")


# ===========================================================================
# Adapted thresholds
# ===========================================================================

class TestAdaptedThresholds:
    """Testy adaptacji progów decyzyjnych."""

    @pytest.mark.asyncio
    async def test_default_thresholds(self, calculator: TrustScoreCalculator) -> None:
        thresholds = await calculator.get_adapted_thresholds({})
        assert thresholds["auto_post"] >= 0.0
        assert thresholds["suggest"] >= 0.0
        assert thresholds["ask_user"] >= 0.0

    @pytest.mark.asyncio
    async def test_recurring_category_lowers_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Kategorie cykliczne (czynsz) → niższy próg auto_post.

        Uwaga: get_adapted_thresholds stosuje kilka regulacji jednocześnie:
        kategoria + vendor + kwota. Aby przetestować TYLKO wpływ kategorii,
        podajemy dane które nie aktywują pozostałych regulacji.
        """
        thresholds = await calculator.get_adapted_thresholds({
            "category": "czynsz",
            "amount_gross": 1000.0,
            "vendor_profile": {"known": True, "invoice_count": 10},
        })
        assert thresholds["auto_post"] <= DEFAULT_THRESHOLDS["auto_post"]

    @pytest.mark.asyncio
    async def test_problematic_category_raises_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Kategorie problematyczne (doradztwo) → wyższy próg auto_post."""
        thresholds = await calculator.get_adapted_thresholds({
            "category": "doradztwo",
            "amount_gross": 1000.0,
            "vendor_profile": {"known": True, "invoice_count": 10},
        })
        assert thresholds["auto_post"] >= DEFAULT_THRESHOLDS["auto_post"]

    @pytest.mark.asyncio
    async def test_known_vendor_lowers_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Znany kontrahent z historią → niższy próg."""
        thresholds = await calculator.get_adapted_thresholds(
            {"category": "inne", "amount_gross": 1000.0, "vendor_profile": {"known": True, "invoice_count": 15}}
        )
        assert thresholds["auto_post"] <= DEFAULT_THRESHOLDS["auto_post"]

    @pytest.mark.asyncio
    async def test_new_vendor_raises_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Nowy kontrahent → wyższy próg."""
        thresholds = await calculator.get_adapted_thresholds(
            {"category": "inne", "amount_gross": 1000.0, "vendor_profile": {"known": False, "invoice_count": 0}}
        )
        assert thresholds["auto_post"] >= DEFAULT_THRESHOLDS["auto_post"]

    @pytest.mark.asyncio
    async def test_low_amount_lowers_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Niska kwota (≤ próg) → niższy próg."""
        thresholds = await calculator.get_adapted_thresholds(
            {"category": "inne", "amount_gross": 50.0, "vendor_profile": {"known": True, "invoice_count": 10}}
        )
        assert thresholds["auto_post"] <= DEFAULT_THRESHOLDS["auto_post"]

    @pytest.mark.asyncio
    async def test_high_amount_raises_threshold(self, calculator: TrustScoreCalculator) -> None:
        """Bardzo wysoka kwota (≥ 20× próg) → wyższy próg."""
        thresholds = await calculator.get_adapted_thresholds(
            {"category": "inne", "amount_gross": 500000.0, "vendor_profile": {"known": True, "invoice_count": 10}}
        )
        assert thresholds["auto_post"] >= DEFAULT_THRESHOLDS["auto_post"]

    def test_update_weights(self, calculator: TrustScoreCalculator) -> None:
        """Aktualizacja wag na podstawie korekt użytkownika."""
        stats = {
            "ai_confidence_correction_rate": 0.3,
            "vendor_reliability_correction_rate": 0.1,
            "data_consistency_correction_rate": 0.02,
            "context_trust_correction_rate": 0.0,
        }
        calculator.update_weights_from_user_corrections(stats)
        total = sum(calculator._weights.values())
        assert abs(total - 1.0) < 0.01
        # ai_confidence correction rate > 0.2 → waga powinna być niższa niż domyślna
        assert calculator._weights["ai_confidence"] <= DEFAULT_WEIGHTS["ai_confidence"]


# ===========================================================================
# Final Decision Resolution
# ===========================================================================

class TestResolveDecision:
    """Testy dla _resolve_decision."""

    def _make_orchestrator(self) -> CouncilOrchestrator:
        """Utwórz minimalny orchestrator z mockowanymi zależnościami."""
        from services.council_agents import ModelManager

        mm = ModelManager()
        alpha = None  # type: ignore
        beta = None
        gamma = None
        import asyncio
        return CouncilOrchestrator(mm, alpha, beta, gamma)  # type: ignore[arg-type]

    def test_level_1_auto_with_sufficient_trust(self) -> None:
        """LEVEL_1_AUTO + trust ≥ min → AUTO_POST."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="FULL_APPROVE",
            level=DecisionLevel.LEVEL_1_AUTO,
            recommended_action="AUTO_POST",
            min_trust_for_auto=0.85,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.90,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "AUTO_POST"

    def test_level_1_auto_with_insufficient_trust(self) -> None:
        """LEVEL_1_AUTO + trust < min → SUGGEST."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="FULL_APPROVE",
            level=DecisionLevel.LEVEL_1_AUTO,
            recommended_action="AUTO_POST",
            min_trust_for_auto=0.85,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.80,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "SUGGEST"

    def test_level_3_escalate_always_asks_user(self) -> None:
        """LEVEL_3_ESCALATE → zawsze ASK_USER niezależnie od trust score."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="ALPHA_ONLY",
            level=DecisionLevel.LEVEL_3_ESCALATE,
            recommended_action="ASK_USER",
            min_trust_for_auto=0.0,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.99,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "ASK_USER"

    def test_level_4_block_always_blocks(self) -> None:
        """LEVEL_4_BLOCK → zawsze BLOCK."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="FULL_REJECT",
            level=DecisionLevel.LEVEL_4_BLOCK,
            recommended_action="BLOCK",
            min_trust_for_auto=0.0,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.99,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "BLOCK"

    def test_level_2_review_with_high_trust(self) -> None:
        """LEVEL_2_REVIEW + trust ≥ min_trust_for_auto → AUTO_POST."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="ALPHA_GAMMA_APPROVE",
            level=DecisionLevel.LEVEL_2_REVIEW,
            recommended_action="SUGGEST",
            min_trust_for_auto=0.92,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.95,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "AUTO_POST"

    def test_level_2_review_with_medium_trust(self) -> None:
        """LEVEL_2_REVIEW + trust < min → SUGGEST."""
        orch = self._make_orchestrator()
        verdict = CouncilVerdict(
            pattern="ALPHA_GAMMA_APPROVE",
            level=DecisionLevel.LEVEL_2_REVIEW,
            recommended_action="SUGGEST",
            min_trust_for_auto=0.92,
            consensus_summary="",
            deliberation="",
        )
        decision = orch._resolve_decision(
            trust_score=0.85,
            thresholds=DEFAULT_THRESHOLDS,
            deliberation="test",
            council_verdict=verdict,
        )
        assert decision == "SUGGEST"

    def test_no_council_verdict_fallback_to_trust_score(self) -> None:
        """Bez CouncilVerdict → fallback do trust score thresholds."""
        orch = self._make_orchestrator()

        # Trust score ≥ auto_post → AUTO_POST
        assert orch._resolve_decision(0.95, {"auto_post": 0.92, "suggest": 0.75, "ask_user": 0.50}, "test") == "AUTO_POST"

        # Trust score między suggest a auto_post → SUGGEST
        assert orch._resolve_decision(0.80, {"auto_post": 0.92, "suggest": 0.75, "ask_user": 0.50}, "test") == "SUGGEST"

        # Trust score między ask_user a suggest → ASK_USER
        assert orch._resolve_decision(0.60, {"auto_post": 0.92, "suggest": 0.75, "ask_user": 0.50}, "test") == "ASK_USER"

        # Trust score < ask_user → BLOCK
        assert orch._resolve_decision(0.30, {"auto_post": 0.92, "suggest": 0.75, "ask_user": 0.50}, "test") == "BLOCK"


# ===========================================================================
# FinalDecision dataclass
# ===========================================================================

class TestFinalDecision:
    """Testy dla dataclass FinalDecision."""

    def test_create_final_decision(self) -> None:
        alpha = DecisionVerdict("APPROVE", 0.95, "OK")
        beta = DecisionVerdict("APPROVE", 0.9, "OK")
        gamma = DecisionVerdict("APPROVE", 0.85, "OK")

        decision = FinalDecision(
            decision="AUTO_POST",
            trust_score=0.92,
            trust_components={"ai_confidence": 0.9},
            adapted_thresholds={"auto_post": 0.85},
            alpha_verdict=alpha,
            beta_verdict=beta,
            gamma_verdict=gamma,
            context={"invoice_id": "inv-001"},
            deliberation="Full approve",
        )
        assert decision.decision == "AUTO_POST"
        assert decision.trust_score == 0.92
        assert decision.alpha_verdict.decision == "APPROVE"
        assert decision.beta_verdict.decision == "APPROVE"
        assert decision.gamma_verdict.decision == "APPROVE"
        assert decision.council_verdict is None

    def test_final_decision_with_council_verdict(self) -> None:
        alpha = DecisionVerdict("APPROVE", 0.9, "OK")
        beta = DecisionVerdict("APPROVE", 0.9, "OK")
        gamma = DecisionVerdict("APPROVE", 0.9, "OK")

        council_v = CouncilVerdict(
            pattern="FULL_APPROVE",
            level=DecisionLevel.LEVEL_1_AUTO,
            recommended_action="AUTO_POST",
            min_trust_for_auto=0.85,
            consensus_summary="Full consensus",
            deliberation="All approve",
        )

        decision = FinalDecision(
            decision="AUTO_POST",
            trust_score=0.95,
            trust_components={},
            adapted_thresholds={},
            alpha_verdict=alpha,
            beta_verdict=beta,
            gamma_verdict=gamma,
            council_verdict=council_v,
            ple_decision_pattern={"source": "fm", "typical_decision": "AUTO_POST", "confidence": 0.95},
        )
        assert decision.council_verdict is not None
        assert decision.council_verdict.pattern == "FULL_APPROVE"
        assert decision.ple_decision_pattern is not None
        assert decision.ple_decision_pattern["source"] == "fm"
