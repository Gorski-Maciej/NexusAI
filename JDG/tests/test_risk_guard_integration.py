"""
Integration tests for RiskGuard (v7.0) — pełny przepływ bez żywej bazy.

Symuluje ścieżkę produkcyjną:
  1. kalibracja kontrahenta (set_vendor_trust)
  2. dopasowanie progu z shared store (get_threshold, zamockowany store)
  3. ewaluacja ryzyka (evaluate)
  4. pętla zwrotna (learn_from_outcome) -> adaptacja progu

v7.0 usunął DuckDB CRUD (add_threshold / list_thresholds /
deprecate_threshold / RiskVerdict / DEFAULT_THRESHOLD); progi żyją teraz
w SQLite rules store za get_rules_connection()/query_risk_threshold(),
a evaluate() zwraca dict (nie RiskVerdict). Store jest patchowany, więc
testy nie wymagają bazy ani plików na dysku.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest

pytest.importorskip("nexus_ai", reason="legacy nexus_ai package nieobecny w repo (JDG = OPA/Rego)")

from nexus_ai.services.risk_guard import (
    RiskGuard,
)


class _FakeConn:
    def __init__(self) -> None:
        self.closed = False

    def close(self) -> None:
        self.closed = True


_CIT_RULE = {
    "rule_id": "r-cit-vat",
    "output": {
        "required_ml_confidence": 0.98,
        "action_if_below": "BLOCK_AND_ALERT",
    },
}


def _store_patches(rule: dict | None):
    return (
        patch(
            "nexus_ai.services.risk_guard.get_rules_connection",
            return_value=_FakeConn(),
        ),
        patch(
            "nexus_ai.services.risk_guard.query_risk_threshold",
            return_value=rule,
        ),
    )


class TestRiskGuardIntegration:
    def test_vendor_calibration_to_evaluate(self) -> None:
        """Kalibracja zaufania obniża próg (high -> -0.05)."""
        g = RiskGuard()
        g.set_vendor_trust("v-trusted", 90)
        assert g.get_vendor_trust_level("v-trusted") == "high"

        conn_patch, rule_patch = _store_patches(_CIT_RULE)
        with conn_patch, rule_patch:
            threshold = g.get_threshold(
                tax_form="CIT_STANDARD",
                expense_type="vat_rate",
                vendor_trust="high",
            )

        assert threshold.rule_id == "r-cit-vat"
        assert threshold.required_ml_confidence == pytest.approx(0.93)  # 0.98 - 0.05 (clamped)
        assert threshold.vendor_trust_modifier == -0.05

    def test_feedback_loop_adapts_threshold(self) -> None:
        """Pozytywne wyniki podnoszą skuteczność i luzują próg."""
        g = RiskGuard()
        for _ in range(20):
            g.learn_from_outcome("r-cit-vat", True)
        assert g._get_rule_accuracy("r-cit-vat") == 1.0

        conn_patch, rule_patch = _store_patches(_CIT_RULE)
        with conn_patch, rule_patch:
            threshold = g.get_threshold(
                tax_form="CIT_STANDARD", expense_type="vat_rate"
            )

        # accuracy 1.0 -> _adapt_threshold(0.98, 1.0) == 0.95
        assert threshold.required_ml_confidence == 0.95

    def test_evaluate_end_to_end(self) -> None:
        """Pełna ścieżka: próg -> ewaluacja -> werdykt (dict)."""
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches(_CIT_RULE)
        with conn_patch, rule_patch:
            verdict = g.evaluate(
                tax_form="CIT_STANDARD",
                expense_type="vat_rate",
                ai_confidence=0.99,
            )

        assert verdict["rule_id"] == "r-cit-vat"
        assert verdict["action"] == "ALLOW"
        assert verdict["ai_confidence"] == 0.99
        assert isinstance(verdict["reason"], str) and verdict["reason"]

    def test_low_confidence_triggers_block_and_alert(self) -> None:
        """Confidence poniżej progu -> eskalacja do akcji blokującej."""
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches(_CIT_RULE)
        with conn_patch, rule_patch:
            verdict = g.evaluate(
                tax_form="CIT_STANDARD",
                expense_type="vat_rate",
                ai_confidence=0.50,
            )

        assert verdict["action"] == "BLOCK_AND_ALERT"
        assert verdict["required_confidence"] == 0.98
