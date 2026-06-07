"""
Tests for RuleStore (Element 1 — Magazyn Reguł).

Covers:
  - ensure_schema creates tables and indexes
  - add_rule creates rules with UUID
  - close_rule closes a rule with valid_to
  - get_active_rules temporal filtering
  - list_rules with filters
  - get_rule by ID
  - count_rules
  - get_change_log audit trail
  - seed_default_rules idempotency
"""

from __future__ import annotations

from datetime import date

import duckdb
import pytest

from nexus_ai.services.rule_store import RuleStore


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    return c


@pytest.fixture
def store(conn: duckdb.DuckDBPyConnection) -> RuleStore:
    s = RuleStore(conn)
    s.ensure_schema()
    return s


class TestRuleStore:
    def test_ensure_schema_creates_tables(self, store: RuleStore) -> None:
        """Tables are created after ensure_schema."""
        rows = store._conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('tax_rules', 'rule_change_log')"
        ).fetchall()
        table_names = {str(r[0]) for r in rows}
        assert "tax_rules" in table_names
        assert "rule_change_log" in table_names

    def test_add_rule_returns_uuid(self, store: RuleStore) -> None:
        """add_rule returns a valid UUID string."""
        rule_id = store.add_rule(
            condition_sql="category_code = 'FUEL'",
            action={"vat_rate": "0.23"},
        )
        assert rule_id is not None
        assert len(rule_id) == 36  # UUID v4

    def test_add_rule_persists(self, store: RuleStore) -> None:
        """Rule is actually stored in the database."""
        rule_id = store.add_rule(
            condition_sql="category_code = 'FUEL'",
            action={"vat_rate": "0.23"},
            valid_from="2024-01-01",
            priority=10,
            created_by="test",
        )
        rule = store.get_rule(rule_id)
        assert rule is not None
        assert rule["condition_sql"] == "category_code = 'FUEL'"
        assert rule["priority"] == 10
        assert rule["created_by"] == "test"
        assert rule["valid_to"] is None  # Open rule

    def test_close_rule_sets_valid_to(self, store: RuleStore) -> None:
        """close_rule sets valid_to on the rule."""
        rule_id = store.add_rule(
            condition_sql="1=1",
            action={"vat_rate": "0.10"},
        )
        ok = store.close_rule(rule_id, valid_to="2024-06-30")
        assert ok

        rule = store.get_rule(rule_id)
        assert rule is not None
        assert rule["valid_to"] is not None

    def test_close_rule_nonexistent(self, store: RuleStore) -> None:
        """Closing a nonexistent rule returns False."""
        ok = store.close_rule("nonexistent")
        assert not ok

    def test_close_rule_already_closed(self, store: RuleStore) -> None:
        """Closing an already-closed rule returns False."""
        rule_id = store.add_rule(condition_sql="1=1", action={"vat_rate": "0.10"})
        store.close_rule(rule_id, valid_to="2024-01-01")
        ok = store.close_rule(rule_id, valid_to="2024-06-30")
        assert not ok  # Already closed

    def test_get_active_rules_temporal_filtering(self, store: RuleStore) -> None:
        """get_active_rules only returns rules active on the given date."""
        r1 = store.add_rule(condition_sql="cat='X'", action={"rate": "0.10"},
                            valid_from="2024-01-01", valid_to="2024-06-30")
        r2 = store.add_rule(condition_sql="cat='X'", action={"rate": "0.20"},
                            valid_from="2024-07-01")

        # Date in first window
        rules = store.get_active_rules("2024-03-15")
        rule_ids = [r["rule_id"] for r in rules]
        assert r1 in rule_ids
        assert r2 not in rule_ids  # Not yet active

        # Date in second window
        rules = store.get_active_rules("2024-09-15")
        rule_ids = [r["rule_id"] for r in rules]
        assert r1 not in rule_ids  # Expired
        assert r2 in rule_ids

    def test_get_active_rules_empty(self, store: RuleStore) -> None:
        """No rules → empty list."""
        rules = store.get_active_rules("2024-01-01")
        assert rules == []

    def test_list_rules_active_only(self, store: RuleStore) -> None:
        """list_rules with active_only filters closed rules."""
        r1 = store.add_rule(condition_sql="1=1", action={"rate": "0.10"})
        r2 = store.add_rule(condition_sql="1=1", action={"rate": "0.20"})
        store.close_rule(r1)

        rules = store.list_rules(active_only=True)
        rule_ids = [r["rule_id"] for r in rules]
        assert r1 not in rule_ids
        assert r2 in rule_ids

        rules = store.list_rules(active_only=False)
        rule_ids = [r["rule_id"] for r in rules]
        assert r1 in rule_ids
        assert r2 in rule_ids

    def test_list_rules_pagination(self, store: RuleStore) -> None:
        """list_rules supports limit and offset."""
        for i in range(5):
            store.add_rule(condition_sql=f"cat='{i}'", action={"rate": f"0.1{i}"})

        rules = store.list_rules(limit=2, offset=0)
        assert len(rules) == 2

        rules = store.list_rules(limit=2, offset=2)
        assert len(rules) == 2

    def test_count_rules(self, store: RuleStore) -> None:
        """count_rules returns correct counts."""
        assert store.count_rules() == 0
        r1 = store.add_rule(condition_sql="1=1", action={})
        store.add_rule(condition_sql="1=1", action={})
        store.close_rule(r1)

        assert store.count_rules() == 2
        assert store.count_rules(active_only=True) == 1

    def test_get_change_log(self, store: RuleStore) -> None:
        """get_change_log returns audit trail of rule changes."""
        rule_id = store.add_rule(condition_sql="1=1", action={"rate": "0.10"},
                                 created_by="admin")
        store.close_rule(rule_id, closed_by="admin")

        log = store.get_change_log(rule_id=rule_id)
        assert len(log) >= 2
        assert log[0]["change_type"] == "closed"
        assert log[1]["change_type"] == "created"

    def test_get_change_log_all(self, store: RuleStore) -> None:
        """get_change_log without rule_id returns all changes."""
        store.add_rule(condition_sql="1=1", action={})
        store.add_rule(condition_sql="2=2", action={})

        log = store.get_change_log()
        assert len(log) == 2  # 2 created events

    def test_seed_default_rules_idempotent(self, store: RuleStore) -> None:
        """seed_default_rules is idempotent (no duplicate rules)."""
        store.seed_default_rules()
        count1 = store.count_rules()
        assert count1 > 0

        store.seed_default_rules()
        count2 = store.count_rules()
        assert count1 == count2  # Idempotent

    def test_add_rule_with_description_template(self, store: RuleStore) -> None:
        """Rule can be created with a description template."""
        rule_id = store.add_rule(
            condition_sql="1=1",
            action={"vat_rate": "0.23"},
            description_template="Reguła {rule_id}: stawka {vat_rate_percent}%",
        )
        rule = store.get_rule(rule_id)
        assert rule is not None
        assert rule["description_template"] is not None
        assert "Reguła" in rule["description_template"]

    def test_get_rule_nonexistent(self, store: RuleStore) -> None:
        """get_rule returns None for nonexistent rule."""
        rule = store.get_rule("nonexistent")
        assert rule is None
