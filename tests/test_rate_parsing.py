"""
Tests for parse_rate() and InvalidRateError — Rozdział Ról (Element 1).

Covers:
  - parse_rate accepts valid strings
  - InvalidRateError for invalid strings
  - InvalidRateError for non-strings
  - Integration with pipeline (Decimal + parse_rate)
  - TaxMathEngine.parse_rate static method
"""

from __future__ import annotations

from decimal import Decimal

import pytest

from tax.math_engine import parse_rate, InvalidRateError, TaxMathEngine
from tax import InvalidRateError as InvalidRateErrorExported


class TestParseRate:
    def test_parse_valid_rate(self) -> None:
        """Valid rate strings are parsed correctly."""
        assert parse_rate("0.23") == Decimal("0.23")
        assert parse_rate("0.00") == Decimal("0.00")
        assert parse_rate("1.00") == Decimal("1.00")
        assert parse_rate("0.05") == Decimal("0.05")
        assert parse_rate("0.08") == Decimal("0.08")

    def test_parse_invalid_string_raises(self) -> None:
        """Invalid rate strings raise InvalidRateError."""
        with pytest.raises(InvalidRateError, match="0\\.23\\.5"):
            parse_rate("0.23.5")
        with pytest.raises(InvalidRateError):
            parse_rate("not-a-number")
        with pytest.raises(InvalidRateError):
            parse_rate("")

    def test_parse_non_string_raises(self) -> None:
        """Non-string input raises InvalidRateError."""
        with pytest.raises(InvalidRateError):
            parse_rate(0.23)  # type: ignore
        with pytest.raises(InvalidRateError):
            parse_rate(None)  # type: ignore

    def test_parse_exception_has_rate_str(self) -> None:
        """InvalidRateError stores the original string."""
        try:
            parse_rate("bad-input")
        except InvalidRateError as exc:
            assert exc.rate_str == "bad-input"

    def test_parse_via_tax_math_engine(self) -> None:
        """TaxMathEngine.parse_rate static method works."""
        rate = TaxMathEngine.parse_rate("0.23")
        assert rate == Decimal("0.23")

    def test_parse_integration_with_decimal(self) -> None:
        """Parsed rate can be used in arithmetic immediately."""
        rate = parse_rate("0.23")
        result = Decimal("10000") * rate  # 10000 gr * 0.23
        assert result == Decimal("2300")

    def test_exception_exported_from_tax(self) -> None:
        """InvalidRateError is re-exported from tax package."""
        assert InvalidRateError is InvalidRateErrorExported

    def test_default_rules_all_use_strings(self) -> None:
        """All DEFAULT_TAX_RULES use string vat_rate values (not float)."""
        from tax.rules import DEFAULT_TAX_RULES
        for rule in DEFAULT_TAX_RULES:
            vat_rate = rule["action_json"]["vat_rate"]
            assert isinstance(vat_rate, str), (
                f"Rule {rule['condition_sql']}: vat_rate should be str, got {type(vat_rate).__name__}"
            )
