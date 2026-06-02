"""
Tests for TemporalManager (Element 2).

Covers:
  - get_active_rules returns only rules valid on the given date
  - Rules with valid_to in the past are excluded
  - Rules with valid_from in the future are excluded
  - is_rule_active_on check
  - get_validity_window
  - Temporal overlap detection
"""

from __future__ import annotations

import json
import uuid
from datetime import date

import duckdb
import pytest

from services.temporal_manager import TemporalManager, TemporalRule
from tax.rules import ensure_tax_schemas, seed_default_rules


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_tax_schemas(c)
    seed_default_rules(c)
    return c


@pytest.fixture
def manager(conn: duckdb.DuckDBPyConnection) -> TemporalManager:
    return TemporalManager(conn)


class TestTemporalManager:
    def test_get_active_rules_returns_current(self, manager: TemporalManager) -> None:
        """Default rules (valid from 2024) are active for a 2025 date."""
        rules = manager.get_active_rules(date(2025, 6, 1))
        assert len(rules) > 0
        for rule in rules:
            assert rule.valid_from <= date(2025, 6, 1)
            assert rule.valid_to is None or rule.valid_to >= date(2025, 6, 1)

    def test_get_active_rules_excludes_future(self, conn: duckdb.DuckDBPyConnection, manager: TemporalManager) -> None:
        """Rules starting in the future are excluded."""
        future_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (future_id, "1=1", json.dumps({"vat_rate": "0.99"}), "2099-01-01", None, 1),
        )
        rules = manager.get_active_rules(date(2025, 6, 1))
        rule_ids = [r.rule_id for r in rules]
        assert future_id not in rule_ids, "Future-dated rule should be excluded"

    def test_get_active_rules_excludes_closed(self, conn: duckdb.DuckDBPyConnection, manager: TemporalManager) -> None:
        """Rules closed (valid_to in past) are excluded."""
        rule_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (rule_id, "1=1", json.dumps({"vat_rate": "0.10"}), "2024-01-01", "2024-06-30", 10),
        )
        rules = manager.get_active_rules(date(2025, 6, 1))
        rule_ids = [r.rule_id for r in rules]
        assert rule_id not in rule_ids

    def test_get_active_rules_includes_past_valid(self, conn: duckdb.DuckDBPyConnection, manager: TemporalManager) -> None:
        """Rule closed in past IS included for a date within its window."""
        rule_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (rule_id, "1=1", json.dumps({"vat_rate": "0.10"}), "2024-01-01", "2024-12-31", 10),
        )
        # Date INSIDE the window
        rules = manager.get_active_rules(date(2024, 6, 15))
        rule_ids = [r.rule_id for r in rules]
        assert rule_id in rule_ids

    def test_is_rule_active_on(self, conn: duckdb.DuckDBPyConnection, manager: TemporalManager) -> None:
        """is_rule_active_on returns correct results."""
        rule_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (rule_id, "1=1", json.dumps({"vat_rate": "0.10"}), "2024-01-01", "2024-12-31", 10),
        )
        assert manager.is_rule_active_on(rule_id, date(2024, 6, 15))
        assert not manager.is_rule_active_on(rule_id, date(2025, 6, 15))

    def test_get_validity_window(self, conn: duckdb.DuckDBPyConnection, manager: TemporalManager) -> None:
        """get_validity_window returns correct dates."""
        rule_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (rule_id, "1=1", json.dumps({"vat_rate": "0.10"}), "2024-01-01", "2024-12-31", 10),
        )
        window = manager.get_validity_window(rule_id)
        assert window is not None
        vf, vt = window
        assert vf == date(2024, 1, 1)
        assert vt == date(2024, 12, 31)

    def test_get_validity_window_nonexistent(self, manager: TemporalManager) -> None:
        """Nonexistent rule returns None."""
        assert manager.get_validity_window("nonexistent") is None

    def test_validate_temporal_overlap_no_conflict(self) -> None:
        """Rules with non-overlapping windows → no conflicts."""
        rules = [
            TemporalRule("a", "cat='X'", "{}", 10, date(2024, 1, 1), date(2024, 6, 30)),
            TemporalRule("b", "cat='X'", "{}", 10, date(2024, 7, 1), None),
        ]
        conflicts = TemporalManager.validate_temporal_overlap(rules)
        assert conflicts == []

    def test_validate_temporal_overlap_detected(self) -> None:
        """Overlapping temporal windows → conflict detected."""
        rules = [
            TemporalRule("a", "cat='X'", "{}", 10, date(2024, 1, 1), date(2024, 12, 31)),
            TemporalRule("b", "cat='X'", "{}", 10, date(2024, 6, 1), None),
        ]
        conflicts = TemporalManager.validate_temporal_overlap(rules)
        assert len(conflicts) >= 1
        assert conflicts[0]["condition_sql"] == "cat='X'"

    def test_validate_temporal_overlap_empty(self) -> None:
        """Empty list → no conflicts."""
        assert TemporalManager.validate_temporal_overlap([]) == []

    def test_validate_temporal_overlap_different_conditions(self) -> None:
        """Different conditions → no conflict even if windows overlap."""
        rules = [
            TemporalRule("a", "cat='X'", "{}", 10, date(2024, 1, 1), None),
            TemporalRule("b", "cat='Y'", "{}", 10, date(2024, 1, 1), None),
        ]
        conflicts = TemporalManager.validate_temporal_overlap(rules)
        assert conflicts == []
