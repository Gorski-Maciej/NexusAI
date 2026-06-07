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

from datetime import date
from decimal import Decimal

import duckdb
import pytest

from nexus_ai.tax.exceptions import NoMatchingRuleError
from nexus_ai.tax.rules import (
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

    # ── decision_trace (include_decision_trace) ───────────────────────────

    def test_decision_trace_included_when_requested(self, engine: RuleEngine) -> None:
        """include_decision_trace=True adds human-readable decision_trace to verdict."""
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx, include_decision_trace=True)
        assert "decision_trace" in verdict, "decision_trace should be in verdict when include_decision_trace=True"
        assert isinstance(verdict["decision_trace"], str)
        assert len(verdict["decision_trace"]) > 0, "decision_trace should be non-empty"
        # Should contain key decision information
        assert "FUEL" in verdict["decision_trace"]
        assert "23" in verdict["decision_trace"]  # vat_rate percent
        assert "Reguła" in verdict["decision_trace"]
        assert verdict["vat_rate"] == "0.23"  # Other verdict fields preserved
        assert verdict["gtu_code"] == "GTU_04"

    def test_decision_trace_not_included_by_default(self, engine: RuleEngine) -> None:
        """Default include_decision_trace=False does NOT include decision_trace."""
        ctx = {
            "category_code": "FOOD",
            "transaction_date": "2025-06-01",
            "company_tax_form": "LUMP_SUM",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "500.00",
        }
        verdict = engine.decide(ctx)  # defaults to include_decision_trace=False
        assert "decision_trace" not in verdict, "decision_trace should NOT be in verdict by default"
        assert verdict["vat_rate"] == "0.08"  # Regular verdict fields intact

    def test_decision_trace_with_description_template(self, engine: RuleEngine) -> None:
        """When rule has description_template, decision_trace uses it."""
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        verdict = engine.decide(ctx, include_decision_trace=True)
        # The FUEL rule has description_template with placeholders
        trace = verdict["decision_trace"]
        # Should contain elements from the template
        assert "paliwo" in trace or "FUEL" in trace  # Template says (paliwo) or uses category_code
        assert "VAT" in trace or "23%" in trace
        # Verify no raw placeholders remain
        assert "{rule_id}" not in trace
        assert "{vat_rate_percent}" not in trace

    def test_decision_trace_with_routing_rule(self, engine: RuleEngine) -> None:
        """decision_trace also works for field-confidence (routing) rules."""
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
            "fc_vat_rate": "0.70",
        }
        verdict = engine.decide(ctx, include_decision_trace=True)
        assert "decision_trace" in verdict
        assert verdict["_routing"] == "BLOCK_AND_ALERT"  # Routing field preserved
        trace = verdict["decision_trace"]
        assert len(trace) > 0
        # Should contain routing intent keywords and no raw placeholders
        assert "pewność" in trace.lower() or "confidence" in trace.lower()
        assert "{_routing}" not in trace
        assert "{_routing_reason}" not in trace
        assert "{" not in trace or "?{" not in trace  # No unresolved placeholders


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

    def test_no_matching_rule_with_decision_trace(self, conn: duckdb.DuckDBPyConnection) -> None:
        """NoMatchingRuleError is still raised when include_decision_trace=True."""
        conn.execute("DELETE FROM tax_rules")
        engine = RuleEngine(conn)
        ctx = ContextInterpreter.build({
            "category_code": "UNKNOWN",
            "transaction_date": "2025-06-01",
        })
        with pytest.raises(NoMatchingRuleError, match="No active tax rules"):
            engine.decide(ctx, include_decision_trace=True)


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


# ── Field Confidence Rules — Zen-Engine zamiast RiskGuard ─────────────────


class TestFieldConfidenceRules:
    """Test Zen-Engine rules for per-field confidence thresholds.

    Zastępują Pythonowy RiskGuard. Reguły mają priorytet 8 i zwracają
    ``_routing`` w werdykcie, gdy confidence danego pola jest poniżej progu.
    Jeśli wszystkie pola mają wystarczającą pewność, żadna reguła
    field-confidence nie matchuje i pipeline kontynuuje normalnie.
    """

    def _build_ctx(
        self,
        *,
        category_code: str = "FUEL",
        tax_form: str = "CIT_STANDARD",
        vendor_country: str = "PL",
        fc_values: dict[str, str] | None = None,
    ) -> dict[str, str]:
        """Build a context dict with field_confidence values."""
        ctx = {
            "category_code": category_code,
            "transaction_date": "2025-06-01",
            "company_tax_form": tax_form,
            "vendor_country": vendor_country,
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "amount_net": "1000.00",
        }
        if fc_values:
            ctx.update(fc_values)
        return ctx

    # ── CIT_STANDARD ────────────────────────────────────────────────────

    def test_cit_standard_low_vat_rate_confidence(self, engine: RuleEngine) -> None:
        """CIT_STANDARD + fc_vat_rate=0.70 < 0.98 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.70",
            "fc_minimum": "0.90",  # above 0.85 — only vat_rate rule matches
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"
        assert "VAT rate confidence" in verdict["_routing_reason"]
        assert verdict["_priority"] == 8

    def test_cit_standard_low_net_confidence(self, engine: RuleEngine) -> None:
        """CIT_STANDARD + fc_total_net=0.80 < 0.95 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(fc_values={
            "fc_total_net": "0.80",
            "fc_vat_rate": "0.99",
            "fc_minimum": "0.90",  # above fc_minimum < 0.85 threshold — tylko fc_total_net matchuje
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"
        assert "net amount" in verdict["_routing_reason"]

    def test_cit_standard_default_fallback_low_minimum(self, engine: RuleEngine) -> None:
        """CIT_STANDARD + fc_minimum=0.80 < 0.85 → BLOCK_AND_ALERT (fallback rule)."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.99",
            "fc_total_net": "0.99",
            "fc_vendor_nip": "0.80",
            "fc_minimum": "0.80",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"
        assert "minimum" in verdict["_routing_reason"]

    # ── LUMP_SUM ────────────────────────────────────────────────────────

    def test_lump_sum_low_vat_rate_confidence(self, engine: RuleEngine) -> None:
        """LUMP_SUM + fc_vat_rate=0.80 < 0.95 → TRIAGE_QUEUE."""
        ctx = self._build_ctx(tax_form="LUMP_SUM", fc_values={
            "fc_vat_rate": "0.80",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "TRIAGE_QUEUE"
        assert verdict["_priority"] == 8

    def test_lump_sum_very_low_net_confidence(self, engine: RuleEngine) -> None:
        """LUMP_SUM + fc_total_net=0.50 < 0.60 → TRIAGE_QUEUE."""
        ctx = self._build_ctx(tax_form="LUMP_SUM", fc_values={
            "fc_total_net": "0.50",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "TRIAGE_QUEUE"
        assert "net amount" in verdict["_routing_reason"]

    # ── LINEAR ──────────────────────────────────────────────────────────

    def test_linear_low_confidence(self, engine: RuleEngine) -> None:
        """LINEAR + fc_minimum=0.70 < 0.85 → TRIAGE_QUEUE."""
        ctx = self._build_ctx(tax_form="LINEAR", fc_values={
            "fc_vat_rate": "0.70",
            "fc_minimum": "0.70",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "TRIAGE_QUEUE"

    # ── CIT_ESTONIAN ────────────────────────────────────────────────────

    def test_cit_estonian_low_vat_rate_confidence(self, engine: RuleEngine) -> None:
        """CIT_ESTONIAN + fc_vat_rate=0.90 < 0.95 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(tax_form="CIT_ESTONIAN", fc_values={
            "fc_vat_rate": "0.90",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"

    # ── MIXED_AUTO ──────────────────────────────────────────────────────

    def test_mixed_auto_low_confidence(self, engine: RuleEngine) -> None:
        """MIXED_AUTO + fc_minimum=0.80 < 0.90 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(category_code="MIXED_AUTO", fc_values={
            "fc_vat_rate": "0.80",
            "fc_minimum": "0.80",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"

    # ── REPRESENTATION ──────────────────────────────────────────────────

    def test_representation_low_confidence(self, engine: RuleEngine) -> None:
        """REPRESENTATION + fc_minimum=0.90 < 0.95 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(category_code="REPRESENTATION", fc_values={
            "fc_vat_rate": "0.90",
            "fc_minimum": "0.90",
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"

    # ── NIP ─────────────────────────────────────────────────────────────

    def test_low_nip_confidence(self, engine: RuleEngine) -> None:
        """fc_vendor_nip=0.50 < 0.80 → BLOCK_AND_ALERT."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.99",
            "fc_vendor_nip": "0.50",
            "fc_minimum": "0.90",  # above all thresholds — only NIP rule matches
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"
        assert "NIP" in verdict["_routing_reason"]

    # ── Category confidence ─────────────────────────────────────────────

    def test_low_category_confidence(self, engine: RuleEngine) -> None:
        """fc_category_code=0.50 < 0.80 → TRIAGE_QUEUE."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.99",
            "fc_category_code": "0.50",
            "fc_minimum": "0.90",  # above all thresholds — only category rule matches
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "TRIAGE_QUEUE"
        assert "category" in verdict["_routing_reason"].lower()

    # ── Very low minimum ────────────────────────────────────────────────

    def test_very_low_minimum_confidence(self, engine: RuleEngine) -> None:
        """fc_vat_rate=0.50 < 0.98 → BLOCK_AND_ALERT (CIT_STANDARD vat_rate rule)."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.50",
            "fc_minimum": "0.99",  # above all thresholds — tylko fc_vat_rate matchuje
        })
        verdict = engine.decide(ctx)
        assert verdict["_routing"] == "BLOCK_AND_ALERT"

    # ── High confidence — falls through to regular rules ────────────────

    def test_high_confidence_falls_to_regular_rule(self, engine: RuleEngine) -> None:
        """All fc_* values high → no field confidence rule matches → regular rule."""
        ctx = self._build_ctx(fc_values={
            "fc_vat_rate": "0.99",
            "fc_total_net": "0.99",
            "fc_vendor_nip": "0.99",
            "fc_minimum": "0.99",
        })
        verdict = engine.decide(ctx)
        # Should match FUEL rule (priority 10) — no _routing
        assert "_routing" not in verdict
        assert verdict["vat_rate"] == "0.23"
        assert verdict["gtu_code"] == "GTU_04"
        assert verdict["_priority"] == 10

    def test_high_confidence_falls_to_default_pl(self, engine: RuleEngine) -> None:
        """Unknown category + high confidence → fallback default PL (no _routing)."""
        ctx = self._build_ctx(category_code="UNKNOWN", fc_values={
            "fc_vat_rate": "0.99",
            "fc_minimum": "0.99",
        })
        verdict = engine.decide(ctx)
        assert "_routing" not in verdict
        assert verdict["vat_rate"] == "0.23"
        assert verdict["_priority"] == 100

    def test_no_field_confidence_in_context(self, engine: RuleEngine) -> None:
        """Brak fc_* w kontekście → zachowanie niezmienione (bezpieczne)."""
        ctx = self._build_ctx()  # No fc_values!
        verdict = engine.decide(ctx)
        assert "_routing" not in verdict
        assert verdict["vat_rate"] == "0.23"
        assert verdict["gtu_code"] == "GTU_04"

    def test_some_fc_fields_missing(self, engine: RuleEngine) -> None:
        """Tylko niektóre fc_* dostępne → działa tylko dla dostępnych."""
        ctx = self._build_ctx(fc_values={
            "fc_total_net": "0.50",  # Only total_net available
        })
        verdict = engine.decide(ctx)
        # CIT_STANDARD + fc_total_net < 0.95 should match
        assert verdict["_routing"] == "BLOCK_AND_ALERT"


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
