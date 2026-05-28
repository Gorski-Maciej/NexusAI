"""
Testy dla Council Session — matryca decyzyjna 8 kombinacji.

Sprawdza:
  - Każdą z 8 kombinacji (FULL_APPROVE → FULL_REJECT)
  - Nieznane kombinacje (fallback)
  - get_consensus_type dla każdego scenariusza
  - get_all_patterns
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from Code.SERVICES.council_session import (
    CouncilSession,
    CouncilVerdict,
    DecisionLevel,
    DECISION_MATRIX,
)
from Code.SERVICES.council_agents import DecisionVerdict


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def sample_invoice() -> dict:
    return {
        "invoice_id": "inv-001",
        "contractor_nip": "1234567890",
        "amount_net": 1000.0,
        "vat": 230.0,
        "amount_gross": 1230.0,
        "contractor": {"name": "Test sp. z o.o.", "known": True},
        "category": "usługi",
    }


def make_verdict(decision: str, confidence: float = 0.9) -> DecisionVerdict:
    return DecisionVerdict(
        decision=decision,
        confidence=confidence,
        reasoning=f"Test {decision}",
    )


# ---------------------------------------------------------------------------
# 8 kombinacji matrycy decyzyjnej
# ---------------------------------------------------------------------------

class TestDecisionMatrix:
    """Test każdy z 8 wpisów w DECISION_MATRIX."""

    def test_full_approve(self, sample_invoice: dict) -> None:
        """APP + APP + APP → FULL_APPROVE → AUTO_POST"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "FULL_APPROVE"
        assert verdict.level == DecisionLevel.LEVEL_1_AUTO
        assert verdict.recommended_action == "AUTO_POST"
        assert verdict.min_trust_for_auto == 0.85
        assert session.get_consensus_type() == "full_approve"

    def test_alpha_gamma_approve(self, sample_invoice: dict) -> None:
        """APP + REJ + APP → ALPHA_GAMMA_APPROVE → SUGGEST"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("REJECT"),
            make_verdict("APPROVE"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "ALPHA_GAMMA_APPROVE"
        assert verdict.level == DecisionLevel.LEVEL_2_REVIEW
        assert verdict.recommended_action == "SUGGEST"
        assert verdict.min_trust_for_auto == 0.92
        assert session.get_consensus_type() == "majority_approve"

    def test_alpha_beta_approve(self, sample_invoice: dict) -> None:
        """APP + APP + REJ → ALPHA_BETA_APPROVE → SUGGEST"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
            make_verdict("REJECT"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "ALPHA_BETA_APPROVE"
        assert verdict.level == DecisionLevel.LEVEL_2_REVIEW
        assert verdict.recommended_action == "SUGGEST"
        assert verdict.min_trust_for_auto == 0.90
        assert session.get_consensus_type() == "majority_approve"

    def test_alpha_only(self, sample_invoice: dict) -> None:
        """APP + REJ + REJ → ALPHA_ONLY → ASK_USER"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("REJECT"),
            make_verdict("REJECT"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "ALPHA_ONLY"
        assert verdict.level == DecisionLevel.LEVEL_3_ESCALATE
        assert verdict.recommended_action == "ASK_USER"
        assert verdict.min_trust_for_auto == 0.0
        assert session.get_consensus_type() == "majority_reject"

    def test_beta_gamma_approve(self, sample_invoice: dict) -> None:
        """REJ + APP + APP → BETA_GAMMA_APPROVE → ASK_USER"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("REJECT"),
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "BETA_GAMMA_APPROVE"
        assert verdict.level == DecisionLevel.LEVEL_3_ESCALATE
        assert verdict.recommended_action == "ASK_USER"
        assert verdict.min_trust_for_auto == 0.0
        assert session.get_consensus_type() == "majority_approve"

    def test_gamma_only(self, sample_invoice: dict) -> None:
        """REJ + REJ + APP → GAMMA_ONLY → ASK_USER"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("REJECT"),
            make_verdict("REJECT"),
            make_verdict("APPROVE"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "GAMMA_ONLY"
        assert verdict.level == DecisionLevel.LEVEL_3_ESCALATE
        assert verdict.recommended_action == "ASK_USER"
        assert verdict.min_trust_for_auto == 0.0
        assert session.get_consensus_type() == "majority_reject"

    def test_beta_only_precision(self, sample_invoice: dict) -> None:
        """REJ + APP + REJ → BETA_ONLY_PRECISION → BLOCK"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("REJECT"),
            make_verdict("APPROVE"),
            make_verdict("REJECT"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "BETA_ONLY_PRECISION"
        assert verdict.level == DecisionLevel.LEVEL_4_BLOCK
        assert verdict.recommended_action == "BLOCK"
        assert verdict.min_trust_for_auto == 0.0
        assert session.get_consensus_type() == "majority_reject"

    def test_full_reject(self, sample_invoice: dict) -> None:
        """REJ + REJ + REJ → FULL_REJECT → BLOCK"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("REJECT"),
            make_verdict("REJECT"),
            make_verdict("REJECT"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "FULL_REJECT"
        assert verdict.level == DecisionLevel.LEVEL_4_BLOCK
        assert verdict.recommended_action == "BLOCK"
        assert verdict.min_trust_for_auto == 0.0
        assert session.get_consensus_type() == "full_reject"


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

class TestEdgeCases:
    """Testy dla nieznanych kombinacji, błędów i brzegowych przypadków."""

    def test_unknown_pattern_fallback(self, sample_invoice: dict) -> None:
        """ERROR + ERROR + ERROR → fallback do ASK_USER"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("ERROR"),
            make_verdict("ERROR"),
            make_verdict("ERROR"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "UNKNOWN"
        assert verdict.level == DecisionLevel.LEVEL_3_ESCALATE
        assert verdict.recommended_action == "ASK_USER"

    def test_mixed_error_fallback(self, sample_invoice: dict) -> None:
        """APPROVE + APPROVE + ERROR → fallback (not in matrix)"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
            make_verdict("ERROR"),
        )
        verdict = session.deliberate()
        assert verdict.pattern == "UNKNOWN"
        assert verdict.recommended_action == "ASK_USER"

    def test_consensus_type_split(self, sample_invoice: dict) -> None:
        """APP + REJ + REJ → majority_reject (2 rejects, 1 approve)"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("REJECT"),
            make_verdict("REJECT"),
        )
        assert session.get_consensus_type() == "majority_reject"

    def test_consensus_type_full_approve(self, sample_invoice: dict) -> None:
        """APP + APP + APP → full_approve"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
        )
        assert session.get_consensus_type() == "full_approve"

    def test_consensus_type_full_reject(self, sample_invoice: dict) -> None:
        """REJ + REJ + REJ → full_reject"""
        session = CouncilSession(
            sample_invoice,
            make_verdict("REJECT"),
            make_verdict("REJECT"),
            make_verdict("REJECT"),
        )
        assert session.get_consensus_type() == "full_reject"

    def test_get_all_patterns_returns_eight(self) -> None:
        """get_all_patterns() zwraca dokładnie 8 kombinacji."""
        patterns = CouncilSession.get_all_patterns()
        assert len(patterns) == 8
        for p in patterns:
            assert "key" in p
            assert "pattern" in p
            assert "level" in p
            assert "action" in p
            assert "min_trust" in p

    def test_all_matrix_keys_have_required_fields(self) -> None:
        """Każdy wpis w DECISION_MATRIX ma wymagane pola."""
        for key, verdict in DECISION_MATRIX.items():
            assert len(key) == 3
            assert isinstance(verdict, CouncilVerdict)
            assert verdict.pattern
            assert verdict.level in DecisionLevel
            assert verdict.recommended_action in (
                "AUTO_POST", "SUGGEST", "ASK_USER", "BLOCK"
            )
            assert 0.0 <= verdict.min_trust_for_auto <= 1.0

    def test_verdict_to_dict(self, sample_invoice: dict) -> None:
        """CouncilVerdict.to_dict() zwraca poprawne dict."""
        session = CouncilSession(
            sample_invoice,
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
            make_verdict("APPROVE"),
        )
        verdict = session.deliberate()
        d = verdict.to_dict()
        assert d["pattern"] == "FULL_APPROVE"
        assert d["level"] == "LEVEL_1_AUTO"
        assert d["recommended_action"] == "AUTO_POST"
        assert d["min_trust_for_auto"] == 0.85
        assert "consensus_summary" in d
        assert "deliberation" in d
