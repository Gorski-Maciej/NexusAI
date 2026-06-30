from __future__ import annotations

"""
Tests for TraceGenerator (Element 1 — Generator Ścieżki Decyzyjnej).

Covers:
  - generate() with default template
  - generate() with custom description_template from rule
  - generate_trace_json() structure
  - Edge cases: missing fields, None values, empty context
"""

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.services.trace_generator import TraceGenerator


class TestTraceGenerator:
    def test_generate_default_template(self) -> None:
        """Default template generates readable description."""
        rule = {"rule_id": "rule-001", "condition_sql": "category_code='FUEL'"}
        context = {
            "category_code": "FUEL",
            "transaction_date": "2024-06-15",
            "vendor_country": "PL",
        }
        verdict = {
            "vat_rate": "0.23",
            "income_tax_qualification": "deductible_full",
            "rounding_level": "position",
            "gtu_code": "GTU_04",
        }
        text = TraceGenerator.generate(rule=rule, context=context, verdict=verdict)
        assert "rule-001" in text
        assert "FUEL" in text
        assert "23%" in text
        assert "odliczenie pełne" in text
        assert "zaokrąglanie per pozycja" in text

    def test_generate_custom_template(self) -> None:
        """Custom description_template from rule is used."""
        rule = {
            "rule_id": "rule-fuel",
            "description_template": (
                "Reguła {rule_id}: {category_code} → VAT {vat_rate_percent}%"
            ),
        }
        context = {"category_code": "FUEL", "transaction_date": "2024-01-01"}
        verdict = {"vat_rate": "0.23", "income_tax_qualification": "deductible_full"}
        text = TraceGenerator.generate(rule=rule, context=context, verdict=verdict)
        assert "rule-fuel" in text
        assert "FUEL → VAT 23%" in text

    def test_generate_missing_fields(self) -> None:
        """Missing fields are replaced with '?' placeholders."""
        text = TraceGenerator.generate(rule={}, context={}, verdict={})
        # Should not crash — uses defaults
        assert isinstance(text, str)
        assert len(text) > 0

    def test_generate_none_values(self) -> None:
        """None values are handled gracefully."""
        rule = {"rule_id": "r1"}
        context = {"category_code": None, "transaction_date": "2024-01-01"}
        verdict = {"vat_rate": None}
        text = TraceGenerator.generate(rule=rule, context=context, verdict=verdict)
        assert "r1" in text
        assert "None" in text or "?" in text

    def test_generate_with_procedure(self) -> None:
        """Procedure field produces human-readable label."""
        rule = {"rule_id": "rule-cross"}
        context = {
            "category_code": "SERVICES",
            "transaction_date": "2024-06-01",
            "vendor_country": "EU",
        }
        verdict = {
            "vat_rate": "0.00",
            "income_tax_qualification": "deductible_full",
            "procedure": "VAT_REVERSE_CHARGE",
        }
        text = TraceGenerator.generate(rule=rule, context=context, verdict=verdict)
        assert "odwrotne obciążenie" in text

    def test_generate_trace_json_structure(self) -> None:
        """generate_trace_json returns valid JSON with expected keys."""
        evaluated = [
            {"rule_id": "r1", "condition_sql": "cat='X'", "result": False},
            {"rule_id": "r2", "condition_sql": "cat='Y'", "result": True, "selected": True},
        ]
        verdict = {"vat_rate": "0.23"}
        context = {"category_code": "FUEL", "transaction_date": "2024-06-15"}

        trace_json_str = TraceGenerator.generate_trace_json(
            evaluated_rules=evaluated,
            final_verdict=verdict,
            context=context,
        )
        trace = msgspec_loads(trace_json_str)
        assert "evaluated_rules" in trace
        assert "final_verdict" in trace
        assert "context_snapshot" in trace
        assert len(trace["evaluated_rules"]) == 2
        assert trace["final_verdict"]["vat_rate"] == "0.23"
        assert trace["context_snapshot"]["category_code"] == "FUEL"

    def test_generate_trace_json_empty(self) -> None:
        """Empty inputs produce minimal JSON."""
        trace_json_str = TraceGenerator.generate_trace_json()
        trace = msgspec_loads(trace_json_str)
        assert trace == {}

    def test_default_template_uses_rule_id(self) -> None:
        """Default template includes rule_id even without custom template."""
        rule = {"rule_id": "my-rule-42"}
        context = {"category_code": "BOOKS", "transaction_date": "2024-01-01"}
        verdict = {"vat_rate": "0.05", "income_tax_qualification": "deductible_full"}
        text = TraceGenerator.generate(rule=rule, context=context, verdict=verdict)
        assert "my-rule-42" in text
        assert "BOOKS" in text
        assert "5%" in text

    def test_unknown_field_in_template(self) -> None:
        """Template with unknown {key} produces ?{key} placeholder."""
        rule = {
            "rule_id": "r1",
            "description_template": "Custom {nonexistent_field}",
        }
        text = TraceGenerator.generate(rule=rule, context={}, verdict={})
        assert "?{nonexistent_field}" in text
