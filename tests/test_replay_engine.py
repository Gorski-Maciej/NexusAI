from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
"""
Tests for Replay Engine (Element 1).

Covers:
  - Replay with matching verdicts
  - Replay with no trace found
  - Replay with empty context
  - Verdict comparison logic
  - Batch replay (empty period)
"""

from __future__ import annotations

import json
from datetime import date

import duckdb
import pytest

from nexus_ai.services.replay_engine import ReplayEngine, _compare_verdicts
from nexus_ai.tax.audit import DecisionTraceLogger, ensure_schema as ensure_audit_schema
from nexus_ai.tax.rules import ensure_tax_schemas, seed_default_rules


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_tax_schemas(c)
    seed_default_rules(c)
    ensure_audit_schema(c)
    return c


@pytest.fixture
def engine(conn: duckdb.DuckDBPyConnection) -> ReplayEngine:
    return ReplayEngine(conn)


def _log_trace(conn: duckdb.DuckDBPyConnection, tx_id: str, context: dict, verdict: dict) -> str:
    """Helper to log a decision trace."""
    logger = DecisionTraceLogger(conn)
    return logger.log(
        transaction_id=tx_id,
        context=context,
        verdict=verdict,
    )


class TestReplayEngine:
    def test_replay_match(self, conn: duckdb.DuckDBPyConnection, engine: ReplayEngine) -> None:
        """Replay with no rule changes → MATCH."""
        context = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "vendor_country": "PL",
            "company_tax_form": "CIT_STANDARD",
        }
        verdict = {"vat_rate": "0.23", "rounding_level": "position", "income_tax_qualification": "deductible_full", "gtu_code": "GTU_04"}
        _log_trace(conn, "tx-match-001", context, verdict)

        result = engine.replay("tx-match-001")
        assert result.match
        assert result.error == ""

    def test_replay_no_trace(self, engine: ReplayEngine) -> None:
        """No trace → error."""
        result = engine.replay("nonexistent")
        assert not result.match
        assert "No decision trace found" in result.error

    def test_replay_empty_context(self, conn: duckdb.DuckDBPyConnection, engine: ReplayEngine) -> None:
        """Empty context → error."""
        _log_trace(conn, "tx-empty", {}, {"vat_rate": "0.23"})
        result = engine.replay("tx-empty")
        assert not result.match
        assert "Empty context" in result.error

    def test_replay_rule_change_no_effect(self, conn: duckdb.DuckDBPyConnection, engine: ReplayEngine) -> None:
        """Changing rules AFTER the transaction date doesn't affect replay."""
        from datetime import date, timedelta

        past_date = "2024-06-01"
        context = {
            "category_code": "FOOD",
            "transaction_date": past_date,
            "vendor_country": "PL",
            "company_tax_form": "LUMP_SUM",
        }
        verdict = {"vat_rate": "0.08", "rounding_level": "position", "income_tax_qualification": "deductible_full", "gtu_code": "GTU_07"}
        _log_trace(conn, "tx-past", context, verdict)

        # Add a NEW rule for FOOD with different rate, valid from future
        import uuid
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (str(uuid.uuid4()), "category_code = 'FOOD'",
             msgspec_dumps({"vat_rate": "0.05", "rounding_level": "position", "income_tax_qualification": "deductible_full"}),
             "2025-01-01", None, 10),
        )

        # Replay should still use the OLD rule (active at past_date)
        result = engine.replay("tx-past")
        assert result.match, "Replay should match despite new rule (past date)"

    def test_replay_mismatch_detected(self, conn: duckdb.DuckDBPyConnection, engine: ReplayEngine) -> None:
        """Changing rules BEFORE the transaction date changes the replay."""
        context = {
            "category_code": "FOOD",
            "transaction_date": "2025-06-15",
            "vendor_country": "PL",
            "company_tax_form": "LUMP_SUM",
        }
        original_verdict = {"vat_rate": "0.08", "rounding_level": "position", "income_tax_qualification": "deductible_full", "gtu_code": "GTU_07"}
        _log_trace(conn, "tx-change", context, original_verdict)

        # Now update the FOOD rule to have different rate — but since the replay
        # uses rules active on 2025-06-15, and the new rule was valid from 2025-01-01,
        # the replay WILL pick up the new rule. This simulates a rule change that
        # retroactively affects past decisions.
        import uuid, json
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (str(uuid.uuid4()), "category_code = 'FOOD' AND vendor_country = 'PL'",
             msgspec_dumps({"vat_rate": "0.05", "rounding_level": "position", "income_tax_qualification": "deductible_full"}),
             "2025-01-01", None, 5),  # Higher priority
        )

        result = engine.replay("tx-change")
        # The original used 0.08, but the new rule (valid from 2025-01-01) gives 0.05
        # Since transaction_date is 2025-06-15, the new rule is active
        assert not result.match, "Should detect mismatch after rule change"
        assert len(result.differences) >= 1

    def test_batch_replay_empty(self, engine: ReplayEngine) -> None:
        """Batch replay with no data → empty list."""
        results = engine.replay_batch(date(2024, 1, 1), date(2024, 1, 31))
        assert results == []


class TestVerdictComparison:
    def test_identical_verdicts(self) -> None:
        """Same verdicts → no differences."""
        a = {"vat_rate": "0.23", "rounding_level": "position", "income_tax_qualification": "deductible_full"}
        b = {"vat_rate": "0.23", "rounding_level": "position", "income_tax_qualification": "deductible_full", "_rule_id": "abc"}
        diffs = _compare_verdicts(a, b)
        assert diffs == []

    def test_different_vat_rate(self) -> None:
        """Different VAT rate → difference detected."""
        a = {"vat_rate": "0.23"}
        b = {"vat_rate": "0.08"}
        diffs = _compare_verdicts(a, b)
        assert len(diffs) == 1
        assert diffs[0]["field"] == "vat_rate"

    def test_missing_field(self) -> None:
        """Field only in original → difference detected."""
        a = {"vat_rate": "0.23", "procedure": "MPP"}
        b = {"vat_rate": "0.23"}
        diffs = _compare_verdicts(a, b)
        assert len(diffs) == 1
        assert diffs[0]["field"] == "procedure"

    def test_none_equal(self) -> None:
        """Both None → no difference."""
        a = {"gtu_code": None}
        b = {"gtu_code": None}
        diffs = _compare_verdicts(a, b)
        assert diffs == []

    def test_metadata_excluded(self) -> None:
        """Metadata fields like _rule_id are excluded."""
        a = {"vat_rate": "0.23"}
        b = {"vat_rate": "0.23", "_rule_id": "rule-001", "_priority": 10}
        diffs = _compare_verdicts(a, b)
        assert diffs == []
