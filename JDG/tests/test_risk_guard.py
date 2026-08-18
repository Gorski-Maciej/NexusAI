"""
Tests for Part V — RiskGuard (v7.0 API).

Covers:
  - RiskAction 5-level escalation (ALLOW/MONITOR/TRIAGE_QUEUE/BLOCK_AND_ALERT/FREEZE)
  - RiskThreshold defaults and custom fields
  - Vendor trust calibration (set_vendor_trust / get_vendor_trust_level)
  - Adaptive threshold learning (learn_from_outcome / _adapt_threshold)
  - get_threshold fallback and rule matching (mocked store)
  - evaluate action escalation

The v7.0 RiskGuard no longer exposes a DuckDB CRUD surface
(ensure_schema / seed_default_thresholds / DEFAULT_RISK_THRESHOLDS were
removed); thresholds now live in the shared SQLite rules store behind
get_rules_connection()/query_risk_threshold(). These tests patch that store
so they run without a live database.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest

pytest.importorskip("nexus_ai", reason="legacy nexus_ai package nieobecny w repo (JDG = OPA/Rego)")

from nexus_ai.services.risk_guard import (
    RiskAction,
    RiskGuard,
    RiskThreshold,
)


class _FakeConn:
    """Minimal fake connection — stands in for get_rules_connection()."""

    def __init__(self) -> None:
        self.closed = False

    def close(self) -> None:
        self.closed = True


def _store_patches(rule: dict | None):
    """Return the two patches that make get_threshold() see ``rule``."""
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


class TestRiskAction:
    def test_five_escalation_levels(self) -> None:
        assert {a.value for a in RiskAction} == {
            "ALLOW",
            "MONITOR",
            "TRIAGE_QUEUE",
            "BLOCK_AND_ALERT",
            "FREEZE",
        }


class TestRiskThreshold:
    def test_defaults(self) -> None:
        t = RiskThreshold()
        assert t.required_ml_confidence == 0.85
        assert t.action_if_below == "TRIAGE_QUEUE"
        assert t.rule_id == "default"

    def test_custom_fields(self) -> None:
        t = RiskThreshold(
            required_ml_confidence=0.98,
            action_if_below="BLOCK_AND_ALERT",
            rule_id="r-cit",
            vendor_trust_modifier=0.05,
            historical_accuracy=0.92,
        )
        assert t.required_ml_confidence == 0.98
        assert t.action_if_below == "BLOCK_AND_ALERT"
        assert t.rule_id == "r-cit"
        assert t.vendor_trust_modifier == 0.05
        assert t.historical_accuracy == 0.92


class TestVendorTrust:
    def test_set_and_get_level(self) -> None:
        g = RiskGuard()
        g.set_vendor_trust("v-high", 90)
        assert g.get_vendor_trust_level("v-high") == "high"
        g.set_vendor_trust("v-med", 50)
        assert g.get_vendor_trust_level("v-med") == "medium"
        g.set_vendor_trust("v-low", 5)
        assert g.get_vendor_trust_level("v-low") == "unknown"

    def test_unknown_vendor_defaults_to_medium(self) -> None:
        g = RiskGuard()
        assert g.get_vendor_trust_level("missing") == "medium"


class TestAdaptiveLearning:
    def test_learn_and_accuracy(self) -> None:
        g = RiskGuard()
        g.learn_from_outcome("r1", True)
        g.learn_from_outcome("r1", False)
        assert g._get_rule_accuracy("r1") == 0.5

    def test_unknown_rule_defaults_to_085(self) -> None:
        g = RiskGuard()
        assert g._get_rule_accuracy("unknown") == 0.85

    def test_adapt_threshold(self) -> None:
        g = RiskGuard()
        assert g._adapt_threshold(0.85, 0.96) == 0.82  # very accurate -> loosen
        assert g._adapt_threshold(0.85, 0.85) == 0.85  # average -> unchanged
        assert g._adapt_threshold(0.85, 0.70) == pytest.approx(0.92)  # weak -> tighten


class TestGetThreshold:
    def test_fallback_when_no_rule(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches(None)
        with conn_patch, rule_patch:
            t = g.get_threshold(tax_form="UNKNOWN_FORM")
        assert t.rule_id == "fallback"
        assert t.required_ml_confidence == 0.85
        assert t.action_if_below == "TRIAGE_QUEUE"

    def test_match_uses_rule_output(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches({
            "rule_id": "r-cit",
            "output": {
                "required_ml_confidence": 0.98,
                "action_if_below": "BLOCK_AND_ALERT",
            },
        })
        with conn_patch, rule_patch:
            t = g.get_threshold(tax_form="CIT_STANDARD", expense_type="vat_rate")
        assert t.rule_id == "r-cit"
        assert t.action_if_below == "BLOCK_AND_ALERT"
        assert t.required_ml_confidence == 0.98

    def test_vendor_trust_modifier_applied(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches(None)
        with conn_patch, rule_patch:
            # unknown vendor -> +0.10 modifier
            t = g.get_threshold(tax_form="X", vendor_trust="unknown")
        assert t.vendor_trust_modifier == 0.10
        assert t.required_ml_confidence == pytest.approx(0.95)  # 0.85 + 0.10


class TestEvaluate:
    def test_high_confidence_allows(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches({
            "rule_id": "r",
            "output": {
                "required_ml_confidence": 0.85,
                "action_if_below": "BLOCK_AND_ALERT",
            },
        })
        with conn_patch, rule_patch:
            verdict = g.evaluate(
                tax_form="CIT_STANDARD", expense_type="inne", ai_confidence=0.99
            )
        assert verdict["action"] == "ALLOW"
        assert verdict["rule_id"] == "r"

    def test_low_confidence_blocks(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches({
            "rule_id": "r",
            "output": {
                "required_ml_confidence": 0.95,
                "action_if_below": "BLOCK_AND_ALERT",
            },
        })
        with conn_patch, rule_patch:
            verdict = g.evaluate(
                tax_form="CIT_STANDARD", expense_type="inne", ai_confidence=0.30
            )
        # 0.30 falls below every escalation level -> escalated action
        assert verdict["action"] == "BLOCK_AND_ALERT"

    def test_returns_expected_keys(self) -> None:
        g = RiskGuard()
        conn_patch, rule_patch = _store_patches({"rule_id": "r", "output": {}})
        with conn_patch, rule_patch:
            verdict = g.evaluate(
                tax_form="CIT_STANDARD", expense_type="inne", ai_confidence=0.99
            )
        for key in (
            "action",
            "required_confidence",
            "ai_confidence",
            "rule_id",
            "vendor_trust",
            "vendor_modifier",
            "historical_accuracy",
            "reason",
        ):
            assert key in verdict, f"missing key {key}"
        assert verdict["action"] in {a.value for a in RiskAction}
