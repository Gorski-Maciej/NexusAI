"""
Tests for ContextInterpreter (Element 2 — Interpreter Kontekstu).

Covers:
  - interpret() returns flat dict with expected keys
  - ALLOWED_KEYS whitelist enforcement
  - transaction_date required → raises ContextInterpreterError
  - amount_net_grosze correct conversion
  - vendor_nip extraction and normalization
  - vendor_account_on_whitelist boolean→string
  - expense_type extraction
  - COUNTRY_NORMALIZATION mapping
  - validate() errors list
  - get_allowed_keys() returns sorted list
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal

import pytest

from CORE.context_interpreter import (
    ContextInterpreter,
    ContextInterpreterError,
    ALLOWED_KEYS,
)


class TestContextInterpreter:
    def test_interpret_basic(self) -> None:
        """Basic invoice data produces expected context keys."""
        data = {
            "category_code": "FUEL",
            "transaction_date": "2024-06-15",
            "vendor_country": "PL",
            "company_tax_form": "CIT_STANDARD",
            "amount_net": Decimal("1000.00"),
        }
        ctx = ContextInterpreter.interpret(data)
        assert ctx["category_code"] == "FUEL"
        assert ctx["transaction_date"] == "2024-06-15"
        assert ctx["vendor_country"] == "PL"
        assert ctx["amount_net"] == "1000.00"
        assert ctx["amount_net_grosze"] == "100000"  # 1000 * 100

    def test_interpret_missing_date_raises(self) -> None:
        """Missing transaction_date raises ContextInterpreterError."""
        with pytest.raises(ContextInterpreterError, match="transaction_date"):
            ContextInterpreter.interpret({"category_code": "FUEL"})

    def test_interpret_date_object(self) -> None:
        """date object is converted to ISO string."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": date(2024, 6, 15),
        })
        assert ctx["transaction_date"] == "2024-06-15"

    def test_interpret_vendor_country_normalization(self) -> None:
        """Country is normalized to uppercase ISO code."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor_country": "de",
        })
        assert ctx["vendor_country"] == "DE"

    def test_interpret_vendor_country_from_vendor_dict(self) -> None:
        """Country extracted from nested vendor dict."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor": {"country": "Germany"},
        })
        assert ctx["vendor_country"] == "DE"

    def test_interpret_nip_from_vendor_dict(self) -> None:
        """NIP extracted from nested vendor dict."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor": {"nip": "123-456-78-90"},
        })
        assert ctx["vendor_nip"] == "1234567890"  # Dashes removed

    def test_interpret_nip_from_flat_field(self) -> None:
        """NIP extracted from flat vendor_nip field."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor_nip": "1234567890",
        })
        assert ctx["vendor_nip"] == "1234567890"

    def test_interpret_nip_missing(self) -> None:
        """Missing NIP results in empty string."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
        })
        assert ctx["vendor_nip"] == ""

    def test_interpret_amount_net_grosze(self) -> None:
        """amount_net_grosze is netto * 100."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "amount_net": Decimal("123.45"),
        })
        assert ctx["amount_net_grosze"] == "12345"  # 123.45 * 100

    def test_interpret_amount_net_zero(self) -> None:
        """Zero amount_net produces 0 grosze."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
        })
        assert ctx["amount_net_grosze"] == "0"

    def test_interpret_amount_net_as_string(self) -> None:
        """String amount_net is parsed to Decimal."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "amount_net": "500.50",
        })
        assert ctx["amount_net"] == "500.50"
        assert ctx["amount_net_grosze"] == "50050"

    def test_interpret_vendor_account_on_whitelist_true(self) -> None:
        """Boolean True becomes 'true' string."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor_account_on_whitelist": True,
        })
        assert ctx["vendor_account_on_whitelist"] == "true"

    def test_interpret_vendor_account_on_whitelist_false(self) -> None:
        """Boolean False becomes 'false' string."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor_account_on_whitelist": False,
        })
        assert ctx["vendor_account_on_whitelist"] == "false"

    def test_interpret_vendor_account_on_whitelist_missing(self) -> None:
        """Missing whitelist becomes 'unknown'."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
        })
        assert ctx["vendor_account_on_whitelist"] == "unknown"

    def test_interpret_expense_type(self) -> None:
        """expense_type is extracted from invoice data."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "expense_type": "operational",
        })
        assert ctx["expense_type"] == "operational"

    def test_interpret_expense_type_fallback(self) -> None:
        """expense_type falls back to expense_category."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "expense_category": "representation",
        })
        assert ctx["expense_type"] == "representation"

    def test_interpret_confidence_vat_rate(self) -> None:
        """confidence_vat_rate is converted to float string."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "confidence_vat_rate": 0.95,
        })
        assert ctx["confidence_vat_rate"] == "0.95"

    def test_interpret_only_allowed_keys(self) -> None:
        """Unknown keys are filtered out by ALLOWED_KEYS guard."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "secret_field": "should_not_appear",
        })
        assert "secret_field" not in ctx

    def test_interpret_all_allowed_keys_present(self) -> None:
        """All ALLOWED_KEYS are present after interpret (with defaults).

        Includes ``field_confidence`` data to populate ``fc_*`` keys
        which are conditionally added only when confidence metadata
        is provided.
        """
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            # Provide field_confidence so all fc_* keys get populated
            "field_confidence": {
                "total_gross": {"value": 1000.00, "confidence": 0.95},
                "total_net": {"value": 813.00, "confidence": 0.95},
                "vat_rate": {"value": 0.23, "confidence": 0.99},
                "vat_amount": {"value": 187.00, "confidence": 0.90},
                "vendor_nip": {"value": "1234567890", "confidence": 0.95},
                "vendor_name": {"value": "ACME Sp. z o.o.", "confidence": 0.88},
                "invoice_number": {"value": "FV/2024/001", "confidence": 0.90},
                "issue_date": {"value": "2024-01-15", "confidence": 0.92},
                "iban": {"value": "PL60102010260000042270201111", "confidence": 0.85},
                "category_code": {"value": "IT_OFFICE", "confidence": 0.80},
            },
        })
        for key in ALLOWED_KEYS:
            assert key in ctx, f"Missing key: {key}"

    def test_interpret_vendor_pkd(self) -> None:
        """vendor_pkd is extracted."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor_pkd": "62.01.Z",
        })
        assert ctx["vendor_pkd"] == "62.01.Z"

    def test_interpret_vendor_pkd_from_vendor(self) -> None:
        """vendor_pkd from nested vendor dict."""
        ctx = ContextInterpreter.interpret({
            "transaction_date": "2024-01-01",
            "vendor": {"pkd": "62.01.Z"},
        })
        assert ctx["vendor_pkd"] == "62.01.Z"

    def test_validate_no_errors(self) -> None:
        """Valid context returns empty errors list."""
        ctx = {"transaction_date": "2024-01-01", "category_code": "FUEL"}
        errors = ContextInterpreter.validate(ctx)
        assert errors == []

    def test_validate_missing_required(self) -> None:
        """Context missing transaction_date has errors."""
        errors = ContextInterpreter.validate({"category_code": "FUEL"})
        assert len(errors) >= 1
        assert any("transaction_date" in e for e in errors)

    def test_get_allowed_keys(self) -> None:
        """get_allowed_keys returns sorted list."""
        keys = ContextInterpreter.get_allowed_keys()
        assert isinstance(keys, list)
        assert len(keys) > 0
        assert keys == sorted(keys)
        assert "transaction_date" in keys
        assert "amount_net_grosze" in keys
