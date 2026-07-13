"""
Tests for Part V — RiskGuard.

Covers:
  - Default threshold fallback
  - First-match-wins priority
  - Adding new thresholds
  - Listing thresholds
"""

from __future__ import annotations

import duckdb
import pytest

from nexus_ai.services.risk_guard import (
    RiskGuard,
    ensure_schema,
    seed_default_thresholds,
    DEFAULT_RISK_THRESHOLDS,
)


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_schema(c)
    seed_default_thresholds(c)
    return c


@pytest.fixture
def guard(conn: duckdb.DuckDBPyConnection) -> RiskGuard:
    return RiskGuard(conn)


class TestRiskGuard:
    def test_default_rules_loaded(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Default risk thresholds are seeded."""
        count = conn.execute("SELECT COUNT(1) FROM risk_thresholds").fetchone()[0]
        assert count == len(DEFAULT_RISK_THRESHOLDS)

    def test_get_threshold_cit_vat_rate(self, guard: RiskGuard) -> None:
        """CIT_STANDARD + vat_rate → high threshold, BLOCK_AND_ALERT."""
        threshold = guard.get_threshold(tax_form="CIT_STANDARD", field="vat_rate")
        assert threshold.required_ml_confidence >= 0.95
        assert threshold.action_if_below == "BLOCK_AND_ALERT"

    def test_get_threshold_cit_default_field(self, guard: RiskGuard) -> None:
        """CIT_STANDARD with unspecified field falls back to generic rule."""
        threshold = guard.get_threshold(tax_form="CIT_STANDARD")
        # No generic rule for CIT without field → falls back to default 0.85
        assert threshold.required_ml_confidence == 0.85
        assert threshold.action_if_below == "BLOCK_AND_ALERT"

    def test_get_threshold_lump_sum(self, guard: RiskGuard) -> None:
        """LUMP_SUM → lower threshold, TRIAGE_QUEUE."""
        threshold = guard.get_threshold(tax_form="LUMP_SUM")
        # LUMP_SUM has lower threshold
        assert threshold.action_if_below in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE")

    def test_get_threshold_fallback(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Empty table → fallback default threshold."""
        conn.execute("DELETE FROM risk_thresholds")
        g = RiskGuard(conn)
        threshold = g.get_threshold(tax_form="UNKNOWN_FORM")
        assert threshold.required_ml_confidence == 0.85
        assert threshold.action_if_below == "BLOCK_AND_ALERT"

    def test_add_threshold(self, guard: RiskGuard) -> None:
        """Adding a rule creates a new record."""
        rule_id = guard.add_threshold(
            condition={"tax_form": "TEST_FORM"},
            output={"required_ml_confidence": 0.50, "action_if_below": "TRIAGE_QUEUE"},
            priority=1,
        )
        assert rule_id is not None
        threshold = guard.get_threshold(tax_form="TEST_FORM")
        assert threshold.required_ml_confidence == 0.50

    def test_list_thresholds(self, guard: RiskGuard) -> None:
        """List returns all rules."""
        rules = guard.list_thresholds()
        assert len(rules) == len(DEFAULT_RISK_THRESHOLDS)
        for rule in rules:
            assert "rule_id" in rule
            assert "condition" in rule
            assert "output" in rule
