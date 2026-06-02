"""
Tests for PriorityEngine (Element 1).

Covers:
  - resolve() returns first matching rule
  - Higher priority (lower number) wins
  - No match → matched=False
  - sort_rules determinism
  - validate_priorities conflict detection
"""

from __future__ import annotations

import json
import uuid

import pytest

from services.priority_engine import PriorityEngine, PrioritizedRule, MatchResult


class TestPriorityEngine:
    def test_resolve_first_match_wins(self) -> None:
        """First matching rule in priority order is returned."""
        rules = [
            PrioritizedRule("rule-c", "1=0", json.dumps({"rate": "0.10"}), 10),
            PrioritizedRule("rule-b", "1=1", json.dumps({"rate": "0.20"}), 20),
            PrioritizedRule("rule-a", "1=1", json.dumps({"rate": "0.30"}), 30),
        ]
        def _eval(sql: str) -> bool:
            # Simple SQL expression evaluator for tests
            if sql == "1=1":
                return True
            if sql == "1=0":
                return False
            raise ValueError(f"Unknown SQL: {sql}")
        result = PriorityEngine.resolve(rules, _eval)
        assert result.matched
        assert result.rule_id == "rule-b"
        assert result.verdict["rate"] == "0.20"

    def test_resolve_higher_priority_wins(self) -> None:
        """Higher priority (lower number) wins over lower priority."""
        rules = [
            PrioritizedRule("high", "1=1", json.dumps({"rate": "0.50"}), 5),
            PrioritizedRule("low", "1=1", json.dumps({"rate": "0.10"}), 100),
        ]
        result = PriorityEngine.resolve(rules, lambda sql: True)
        assert result.matched
        assert result.rule_id == "high"
        assert result.verdict["rate"] == "0.50"

    def test_resolve_no_match(self) -> None:
        """No matching rule → matched=False."""
        rules = [
            PrioritizedRule("r1", "1=0", json.dumps({"rate": "0.10"}), 10),
            PrioritizedRule("r2", "1=0", json.dumps({"rate": "0.20"}), 20),
        ]
        result = PriorityEngine.resolve(rules, lambda sql: False)
        assert not result.matched
        assert result.verdict == {}

    def test_resolve_empty_rules(self) -> None:
        """No rules → matched=False."""
        result = PriorityEngine.resolve([], lambda sql: True)
        assert not result.matched

    def test_resolve_skips_malformed_conditions(self) -> None:
        """Malformed conditions are skipped gracefully."""
        rules = [
            PrioritizedRule("bad", "THIS IS NOT SQL", json.dumps({"rate": "0.10"}), 10),
            PrioritizedRule("good", "1=1", json.dumps({"rate": "0.20"}), 20),
        ]
        def _eval(sql: str) -> bool:
            if sql == "THIS IS NOT SQL":
                raise Exception("Bad SQL")
            return True

        result = PriorityEngine.resolve(rules, _eval)
        assert result.matched
        assert result.rule_id == "good"

    def test_sort_rules(self) -> None:
        """sort_rules orders by priority ASC, then rule_id ASC."""
        rules = [
            PrioritizedRule("z", "1=1", "{}", 100),
            PrioritizedRule("a", "1=1", "{}", 10),
            PrioritizedRule("m", "1=1", "{}", 10),
        ]
        sorted_rules = PriorityEngine.sort_rules(rules)
        assert sorted_rules[0].rule_id == "a"
        assert sorted_rules[1].rule_id == "m"
        assert sorted_rules[2].rule_id == "z"

    def test_sort_rules_deterministic(self) -> None:
        """Sorting is deterministic for same priorities."""
        rules = [
            PrioritizedRule("b", "1=1", "{}", 10),
            PrioritizedRule("a", "1=1", "{}", 10),
        ]
        r1 = PriorityEngine.sort_rules(rules)
        r2 = PriorityEngine.sort_rules(rules)
        assert [r.rule_id for r in r1] == [r.rule_id for r in r2]

    def test_validate_priorities_no_conflict(self) -> None:
        rules = [
            PrioritizedRule("a", "cat='X'", "{}", 10),
            PrioritizedRule("b", "cat='Y'", "{}", 20),
        ]
        warnings = PriorityEngine.validate_priorities(rules)
        assert warnings == []

    def test_validate_priorities_conflict_detected(self) -> None:
        rules = [
            PrioritizedRule("a", "cat='X'", "{}", 10),
            PrioritizedRule("b", "cat='X'", "{}", 10),
        ]
        warnings = PriorityEngine.validate_priorities(rules)
        assert len(warnings) >= 1
        assert "cat='X'" in warnings[0]["condition_sql"]

    def test_validate_priorities_same_condition_different_priority(self) -> None:
        rules = [
            PrioritizedRule("a", "cat='X'", "{}", 10),
            PrioritizedRule("b", "cat='X'", "{}", 20),
        ]
        warnings = PriorityEngine.validate_priorities(rules)
        assert warnings == []

    def test_verdict_contains_metadata(self) -> None:
        """Verdict includes _rule_id and _priority."""
        rules = [
            PrioritizedRule("my-rule", "1=1", json.dumps({"rate": "0.23"}), 42),
        ]
        result = PriorityEngine.resolve(rules, lambda sql: True)
        assert result.verdict["_rule_id"] == "my-rule"
        assert result.verdict["_priority"] == 42

    def test_resolve_with_tracker_records_evaluated(self) -> None:
        """_tracker collects evaluated rules with results."""
        rules = [
            PrioritizedRule("r1", "1=0", json.dumps({"rate": "0.10"}), 10),
            PrioritizedRule("r2", "1=1", json.dumps({"rate": "0.20"}), 20),
            PrioritizedRule("r3", "1=1", json.dumps({"rate": "0.30"}), 30),
        ]
        def _eval(sql: str) -> bool:
            if sql == "1=1":
                return True
            if sql == "1=0":
                return False
            raise ValueError(f"Unknown SQL: {sql}")

        tracker: list[dict] = []
        result = PriorityEngine.resolve(rules, _eval, _tracker=tracker)

        assert result.matched
        assert result.rule_id == "r2"
        # Only r1 and r2 are evaluated — r3 is never reached (first-match-wins)
        assert len(tracker) == 2
        # r1: skipped (1=0 → False)
        assert tracker[0]["rule_id"] == "r1"
        assert tracker[0]["result"] is False
        assert tracker[0]["selected"] is False
        # r2: matched (1=1 → True)
        assert tracker[1]["rule_id"] == "r2"
        assert tracker[1]["result"] is True
        assert tracker[1]["selected"] is True

    def test_resolve_with_tracker_malformed(self) -> None:
        """Tracker records malformed conditions with error field."""
        rules = [
            PrioritizedRule("bad", "INVALID SQL", json.dumps({"rate": "0.10"}), 10),
            PrioritizedRule("good", "1=1", json.dumps({"rate": "0.20"}), 20),
        ]
        def _eval(sql: str) -> bool:
            if sql == "INVALID SQL":
                raise Exception("Bad SQL")
            return True

        tracker: list[dict] = []
        result = PriorityEngine.resolve(rules, _eval, _tracker=tracker)
        assert result.matched
        assert result.rule_id == "good"
        assert len(tracker) == 2
        # Bad rule: recorded with error
        assert tracker[0]["rule_id"] == "bad"
        assert tracker[0]["result"] is False
        assert "error" in tracker[0]
        # Good rule: matched
        assert tracker[1]["rule_id"] == "good"
        assert tracker[1]["result"] is True
