"""
Tests for Nexus-Money and CurrencyConverter.

Covers:
  - Money arithmetic (add, sub, mul, neg) and explicit unsupported division
  - Currency mismatch detection
  - CurrencyConverter conversion logic
  - Conversion trail for audit
  - Invoice currency validation
"""

from __future__ import annotations

from decimal import Decimal

import duckdb
import pytest

from services.currency_converter import (
    CurrencyConverter,
    CurrencyMismatchError,
    EXCHANGE_RATES_SCHEMA,
    Money,
)


# ── Money arithmetic ─────────────────────────────────────────────────────────


class TestMoneyArithmetic:
    def test_add_same_currency(self) -> None:
        a = Money.from_string("100.00", "PLN")
        b = Money.from_string("50.00", "PLN")
        result = a + b
        assert result.amount == Decimal("150.00")
        assert result.currency_code == "PLN"

    def test_add_different_currency_raises(self) -> None:
        a = Money.from_string("100.00", "PLN")
        b = Money.from_string("50.00", "EUR")
        with pytest.raises(CurrencyMismatchError, match="Currency mismatch"):
            _ = a + b

    def test_sub_same_currency(self) -> None:
        a = Money.from_string("100.00", "PLN")
        b = Money.from_string("30.00", "PLN")
        result = a - b
        assert result.amount == Decimal("70.00")

    def test_sub_different_currency_raises(self) -> None:
        a = Money.from_string("100.00", "PLN")
        b = Money.from_string("30.00", "USD")
        with pytest.raises(CurrencyMismatchError, match="Currency mismatch"):
            _ = a - b

    def test_mul_by_decimal(self) -> None:
        net = Money.from_string("100.00", "PLN")
        vat = net * Decimal("0.23")
        assert vat.amount == Decimal("23.00")
        assert vat.currency_code == "PLN"

    def test_mul_by_int(self) -> None:
        m = Money.from_string("10.00", "PLN")
        result = m * 3
        assert result.amount == Decimal("30.00")

    def test_rmul(self) -> None:
        m = Decimal("0.23") * Money.from_string("100.00", "PLN")
        assert m.amount == Decimal("23.00")

    def test_truediv_is_not_supported(self) -> None:
        """Money does not support implicit division; convert amounts explicitly."""
        with pytest.raises(TypeError):
            _ = Money.from_string("100.00", "PLN") / Decimal("4")

    def test_neg(self) -> None:
        m = -Money.from_string("50.00", "PLN")
        assert m.amount == Decimal("-50.00")

    def test_eq(self) -> None:
        assert Money.from_string("10.00", "PLN") == Money.from_string("10.00", "PLN")
        assert Money.from_string("10.00", "PLN") != Money.from_string("10.00", "EUR")
        assert Money.from_string("10.00", "PLN") != Money.from_string("20.00", "PLN")

    def test_zero(self) -> None:
        z = Money.zero("PLN")
        assert z.amount == Decimal("0.00")
        assert z.currency_code == "PLN"
        assert z + Money.from_string("5.00", "PLN") == Money.from_string("5.00", "PLN")

    def test_to_dict(self) -> None:
        m = Money.from_string("123.45", "EUR")
        d = m.to_dict()
        assert d["amount_cents"] == 12345
        assert d["currency"] == "EUR"

    def test_currency_code_property(self) -> None:
        """currency_code returns the currency as a string."""
        m = Money.from_string("10.00", "PLN")
        assert m.currency_code == "PLN"
        assert isinstance(m.currency_code, str)

    def test_repr(self) -> None:
        m = Money.from_string("10.00", "PLN")
        assert "PLN" in repr(m)
        assert "amount_cents=1000" in repr(m)

    def test_from_decimal(self) -> None:
        """Backward compatibility: creating Money from Decimal."""
        m = Money.from_decimal(Decimal("99.99"), "USD")
        assert m.amount == Decimal("99.99")
        assert m.currency_code == "USD"

    def test_from_float(self) -> None:
        """Creating Money from float goes through explicit from_decimal constructor."""
        m = Money.from_decimal(99.99, "EUR")
        assert m.amount == Decimal("99.99")


# ── Currency Converter ──────────────────────────────────────────────────────


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    c.execute(EXCHANGE_RATES_SCHEMA)
    return c


@pytest.fixture
def converter(conn: duckdb.DuckDBPyConnection) -> CurrencyConverter:
    return CurrencyConverter(conn)


class TestCurrencyConverter:
    def test_convert_same_currency_noop(self, converter: CurrencyConverter) -> None:
        """Converting PLN to PLN returns same amount."""
        result = converter.convert(Money.from_string("100.00", "PLN"), "PLN")
        assert result == Money.from_string("100.00", "PLN")

    def test_convert_uses_cache(self, conn: duckdb.DuckDBPyConnection, converter: CurrencyConverter) -> None:
        """After fetching, rate is cached in DuckDB."""
        from datetime import date

        # Insert a known rate
        conn.execute(
            "INSERT INTO exchange_rates (currency, rate_date, rate_pln) VALUES (?, ?, ?)",
            ("EUR", "2025-06-01", "4.50"),
        )

        result = converter.convert(
            Money.from_string("100.00", "EUR"),
            "PLN",
            rate_date=date(2025, 6, 1),
        )
        assert result.amount == Decimal("450.00")
        assert result.currency_code == "PLN"

    def test_convert_unknown_currency_raises(self, converter: CurrencyConverter) -> None:
        """Unknown currency raises CurrencyRateNotFoundError."""
        from datetime import date
        from services.currency_converter import CurrencyRateNotFoundError

        # AED is intentionally NOT in the supported NBP KNOWN_CURRENCIES set
        with pytest.raises(CurrencyRateNotFoundError):
            converter.convert(
                Money.from_string("100.00", "AED"),
                "PLN",
                rate_date=date(2025, 1, 1),
            )

    def test_validate_invoice_currencies_same(self) -> None:
        """All same currency passes."""
        items = [
            Money.from_string("100.00", "PLN"),
            Money.from_string("50.00", "PLN"),
            Money.from_string("25.00", "PLN"),
        ]
        CurrencyConverter.validate_invoice_currencies(items)  # should not raise

    def test_validate_invoice_currencies_mixed(self) -> None:
        """Mixed currencies raise."""
        items = [
            Money.from_string("100.00", "PLN"),
            Money.from_string("50.00", "EUR"),
        ]
        with pytest.raises(CurrencyMismatchError, match="Currency mismatch"):
            CurrencyConverter.validate_invoice_currencies(items)

    def test_validate_invoice_currencies_empty(self) -> None:
        """Empty list passes."""
        CurrencyConverter.validate_invoice_currencies([])  # should not raise

    def test_build_conversion_trail(self, converter: CurrencyConverter) -> None:
        """Conversion trail has all required fields."""
        from datetime import date

        original = Money.from_string("100.00", "EUR")
        converted = Money.from_string("450.00", "PLN")
        trail = converter.build_conversion_trail(
            original, converted, Decimal("4.50"), date(2025, 6, 1),
        )
        assert trail["original_currency"] == "EUR"
        assert trail["target_currency"] == "PLN"
        assert trail["rate"] == "4.50"
        assert trail["rate_date"] == "2025-06-01"
        assert trail["rate_source"] == "NBP"
