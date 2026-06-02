"""
Tests for Part I — Tax Rule Engine.

Covers:
  - ContextInterpreter building from various invoice shapes
  - RuleEngine with DuckDB in-memory
  - First-match-wins priority
  - Temporal rule validity (valid_from / valid_to)
  - NoMatchingRuleError
  - Immutable rule lifecycle (add_rule, close_rule)
"""

from __future__ import annotations

import json
from datetime import date
from decimal import Decimal

import duckdb
import pytest

from Code.tax.exceptions import NoMatchingRuleError
from Code.tax.rules import (
    ContextInterpreter,
    RuleEngine,
    ensure_tax_schemas,
    seed_default_rules,
    DEFAULT_TAX_RULES,
)


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    """In-memory DuckDB connection for testing."""
    c = duckdb.connect(":memory:")
    ensure_tax_schemas(c)
    seed_default_rules(c)
    return c


@pytest.fixture
def engine(conn: duckdb.DuckDBPyConnection) -> RuleEngine:
    return RuleEngine(conn)


# ── Context Interpreter ──────────────────────────────────────────────────────


class TestContextInterpreter:
    def test_build_minimal(self) -> None:
        """Minimal invoice data produces sensible defaults."""
        invoice = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
        }
        ctx = ContextInterpreter.build(invoice)
        assert ctx["category_code"] == "FUEL"
        assert ctx["transaction_date"] == "2025-06-01"
        assert ctx["company_tax_form"] == "CIT_STANDARD"
        assert ctx["vendor_country"] == "PL"
        assert ctx["vendor_vat_status"] == "unknown"
        assert ctx["vendor_pkd"] == ""
        assert ctx["amount_net"] == "0"

    def test_build_full(self) -> None:
        """Full invoice data preserved correctly."""
        invoice = {
            "category_code": "IT_OFFICE",
            "transaction_date": date(2025, 6, 15),
            "company_tax_form": "LUMP_SUM",
            "vendor_country": "EU",
            "vendor_vat_status": "active",
            "vendor_pkd": "6201Z",
            "amount_net": Decimal("1234.56"),
        }
        ctx = ContextInterpreter.build(invoice)
        assert ctx["category_code"] == "IT_OFFICE"
        assert ctx["transaction_date"] == "2025-06-15"
        assert ctx["company_tax_form"] == "LUMP_SUM"
        assert ctx["vendor_country"] == "EU"
        assert ctx["vendor_vat_status"] == "active"
        assert ctx["vendor_pkd"] == "6201Z"
        assert ctx["amount_net"] == "1234.56"

    def test_build_with_empty_data(self) -> None:
        """Empty dict produces default values."""
        ctx = ContextInterpreter.build({})
        assert ctx["category_code"] == "UNKNOWN"
        assert ctx["vendor_country"] == "PL"
        assert ctx["company_tax_form"] == "CIT_STANDARD"
        assert ctx["vendor_vat_status"] == "unknown"

    def test_build_preserves_decimal_precision(self) -> None:
        """amount_net with many decimal places stays as string representation."""
        ctx = ContextInterpreter.build({"amount_net": Decimal("0.005")})
        assert ctx["amount_net"] == "0.005"  # not rounded yet — that's for math engine


# ── RuleEngine — matching ────────────────────────────────────────────────────


class TestRuleEngineMatching:
    def test_match_fuel_pl(self, engine: RuleEngine) -> None:
        """FUEL in Poland matches the FUEL rule (priority 10)."""
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.23"
        assert verdict["rounding_level"] == "position"
        assert verdict["gtu_code"] == "GTU_04"
        assert "_rule_id" in verdict
        assert verdict["_priority"] == 10

    def test_match_education_pl(self, engine: RuleEngine) -> None:
        """EDUCATION in Poland matches the exempt rule."""
        ctx = {
            "category_code": "EDUCATION",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.00"
        assert verdict["rounding_level"] == "total"

    def test_match_healthcare_pl(self, engine: RuleEngine) -> None:
        """HEALTHCARE in Poland matches the exempt rule (same condition)."""
        ctx = {
            "category_code": "HEALTHCARE",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "500.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.00"

    def test_match_eu_reverse_charge(self, engine: RuleEngine) -> None:
        """EU vendor with active VAT status → reverse charge."""
        ctx = {
            "category_code": "IT_OFFICE",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "EU",
            "vendor_vat_status": "active",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.00"
        assert verdict.get("procedure") == "VAT_REVERSE_CHARGE"

    def test_match_non_eu_import(self, engine: RuleEngine) -> None:
        """Non-EU vendor → import procedure."""
        ctx = {
            "category_code": "IT_OFFICE",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "NON_EU",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.23"
        assert verdict.get("procedure") == "IMPORT"

    def test_match_fallback_domestic(self, engine: RuleEngine) -> None:
        """Unknown PL category falls back to default domestic rule."""
        ctx = {
            "category_code": "UNKNOWN",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        # Falls to default PL rule (priority 100)
        assert verdict["vat_rate"] == "0.23"
        assert verdict["_priority"] == 100


# ── RuleEngine — priority and temporal ───────────────────────────────────────


class TestRuleEnginePriorityAndTemporal:
    def test_higher_priority_wins(self, engine: RuleEngine) -> None:
        """A rule with lower priority number wins over higher number."""
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx)
        assert verdict["_priority"] == 10  # FUEL rule at priority 10 beats default 100

    def test_temporal_validity_future_rule(self, conn: duckdb.DuckDBPyConnection) -> None:
        """A rule starting in the future should not match today's invoices."""
        engine = RuleEngine(conn)
        # Add a rule that only applies from 2099
        engine.add_rule(
            condition_sql="category_code = 'FUEL' AND vendor_country = 'PL'",
            action={"vat_rate": "0.99", "rounding_level": "position"},
            valid_from="2099-01-01",
            priority=1,
        )
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        # Should still match the existing 2024 rule, not the 2099 one
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.23"

    def test_temporal_validity_closed_rule(self, conn: duckdb.DuckDBPyConnection) -> None:
        """A rule closed (valid_to set) should not match after its end date."""
        engine = RuleEngine(conn)
        # Close all existing fuel rules so we can test
        conn.execute("DELETE FROM tax_rules")  # Clean slate for this test

        rule_id = engine.add_rule(
            condition_sql="category_code = 'FUEL'",
            action={"vat_rate": "0.22", "rounding_level": "position"},
            valid_from="2024-01-01",
            valid_to="2024-12-31",
            priority=10,
        )
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        with pytest.raises(NoMatchingRuleError):
            engine.decide(ctx)

    def test_no_matching_rule_error(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Empty rule table raises NoMatchingRuleError."""
        conn.execute("DELETE FROM tax_rules")
        engine = RuleEngine(conn)
        ctx = ContextInterpreter.build({
            "category_code": "UNKNOWN",
            "transaction_date": "2025-06-01",
        })
        with pytest.raises(NoMatchingRuleError, match="No active tax rules"):
            engine.decide(ctx)


# ── RuleEngine — rule lifecycle ──────────────────────────────────────────────


class TestRuleLifecycle:
    def test_add_rule(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Adding a new rule creates a record and it becomes matchable."""
        engine = RuleEngine(conn)
        rule_id = engine.add_rule(
            condition_sql="category_code = 'TEST'",
            action={"vat_rate": "0.15", "rounding_level": "total"},
            valid_from="2025-01-01",
            priority=1,
            created_by="test_runner",
        )
        assert rule_id is not None
        assert len(rule_id) == 36  # UUID length

        ctx = ContextInterpreter.build({
            "category_code": "TEST",
            "transaction_date": "2025-06-01",
        })
        verdict = engine.decide(ctx)
        assert verdict["vat_rate"] == "0.15"

    def test_close_rule(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Closing a rule prevents it from matching after valid_to."""
        engine = RuleEngine(conn)
        # Clean slate
        conn.execute("DELETE FROM tax_rules")

        rule_id = engine.add_rule(
            condition_sql="category_code = 'SEASONAL'",
            action={"vat_rate": "0.10", "rounding_level": "total"},
            valid_from="2025-01-01",
            priority=10,
        )
        # Close it
        engine.close_rule(rule_id, "2025-06-01")

        # Should match before closure
        ctx_before = ContextInterpreter.build({
            "category_code": "SEASONAL",
            "transaction_date": "2025-03-01",
        })
        verdict = engine.decide(ctx_before)
        assert verdict["vat_rate"] == "0.10"

        # Should NOT match after closure
        ctx_after = ContextInterpreter.build({
            "category_code": "SEASONAL",
            "transaction_date": "2025-07-01",
        })
        with pytest.raises(NoMatchingRuleError):
            engine.decide(ctx_after)


# ── DEFAULT_TAX_RULES validation ─────────────────────────────────────────────


class TestDefaultRules:
    def test_all_default_rules_are_valid(self) -> None:
        """All default rules have required fields."""
        for rule in DEFAULT_TAX_RULES:
            assert "condition_sql" in rule, f"Missing condition_sql in {rule}"
            assert "action_json" in rule, f"Missing action_json in {rule}"
            assert "valid_from" in rule
            assert "priority" in rule
            action = rule["action_json"]
            assert "vat_rate" in action
            assert "rounding_level" in action

    def test_default_rules_cover_common_cases(self, conn: duckdb.DuckDBPyConnection) -> None:
        """All default rules can be evaluated without SQL errors."""
        engine = RuleEngine(conn)
        test_contexts = [
            {"category_code": "FUEL", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
            {"category_code": "FOOD", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
            {"category_code": "EDUCATION", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
        ]
        for ctx_data in test_contexts:
            ctx = ContextInterpreter.build(ctx_data)
            verdict = engine.decide(ctx)
            assert "vat_rate" in verdict
            assert "rounding_level" in verdict
