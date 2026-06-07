"""
Tests for Part II — Tax Math Engine.

Covers:
  - to_grosze / to_zlotowki round-trip
  - multiply_net_by_vat precision
  - RoundingPolicy (position vs total)
  - TaxInvariantGuard (all 3 invariants)
  - Edge cases (0 amounts, single positions, large amounts)
"""

from __future__ import annotations

from decimal import Decimal

import pytest

from nexus_ai.tax.math_engine import (
    TaxMathEngine,
    InvoicePositions,
    InvoiceSummary,
    ValidationResult,
    to_grosze,
    to_zlotowki,
    multiply_net_by_vat,
    add_tax,
    calculate_vat_by_policy,
    validate_invariants,
)


# ── to_grosze / to_zlotowki round-trip ────────────────────────────────────────


class TestGroszeConversion:
    def test_decimal_round_trip(self) -> None:
        """to_grosze(to_zlotowki(x)) == x for clean amounts."""
        for grosze in [0, 1, 100, 12345, 999999]:
            zloty = to_zlotowki(grosze)
            back = to_grosze(zloty)
            assert back == grosze, f"Round-trip failed for {grosze} gr"

    def test_to_grosze_from_decimal(self) -> None:
        assert to_grosze(Decimal("123.45")) == 12345
        assert to_grosze(Decimal("0.01")) == 1
        assert to_grosze(Decimal("0")) == 0

    def test_to_grosze_from_float(self) -> None:
        assert to_grosze(123.45) == 12345
        assert to_grosze(0.01) == 1

    def test_to_grosze_from_int(self) -> None:
        assert to_grosze(100) == 10000

    def test_to_grosze_from_string(self) -> None:
        assert to_grosze("123.45") == 12345
        assert to_grosze("0.01") == 1

    def test_to_grosze_half_up_rounding(self) -> None:
        # 0.005 * 100 = 0.5 → ROUND_HALF_UP → 1
        assert to_grosze(Decimal("0.005")) == 1
        # 0.0049 * 100 = 0.49 → ROUND_HALF_UP → 0
        assert to_grosze(Decimal("0.0049")) == 0
        # 1.235 → 124 (since 1.235 * 100 = 123.5 → HALF_UP → 124)
        assert to_grosze(Decimal("1.235")) == 124
        # 1.234 → 123
        assert to_grosze(Decimal("1.234")) == 123

    def test_to_zlotowki_precision(self) -> None:
        assert to_zlotowki(12345) == Decimal("123.45")
        assert to_zlotowki(1) == Decimal("0.01")
        assert to_zlotowki(0) == Decimal("0.00")

    def test_to_grosze_invalid_type(self) -> None:
        with pytest.raises(TypeError):
            to_grosze([1, 2, 3])  # type: ignore[arg-type]


# ── multiply_net_by_vat ──────────────────────────────────────────────────────


class TestMultiplyNetByVat:
    def test_standard_rate_23(self) -> None:
        # 10000 gr * 0.23 = 2300 gr
        assert multiply_net_by_vat(10000, Decimal("0.23")) == 2300

    def test_reduced_rate_8(self) -> None:
        assert multiply_net_by_vat(10000, Decimal("0.08")) == 800

    def test_reduced_rate_5(self) -> None:
        assert multiply_net_by_vat(10000, Decimal("0.05")) == 500

    def test_zero_rate(self) -> None:
        assert multiply_net_by_vat(10000, Decimal("0.00")) == 0

    def test_rounding(self) -> None:
        # 1 gr * 0.23 = 0.23 → 0 gr (rounds down)
        assert multiply_net_by_vat(1, Decimal("0.23")) == 0
        # 3 gr * 0.23 = 0.69 → 1 gr (rounds up, HALF_UP)
        assert multiply_net_by_vat(3, Decimal("0.23")) == 1
        # 4 gr * 0.23 = 0.92 → 1 gr
        assert multiply_net_by_vat(4, Decimal("0.23")) == 1
        # 5 gr * 0.23 = 1.15 → 1 gr
        assert multiply_net_by_vat(5, Decimal("0.23")) == 1

    def test_large_amount(self) -> None:
        # 1_000_000 gr (10 000 PLN) * 0.23 = 230 000 gr (2 300 PLN)
        assert multiply_net_by_vat(1_000_000, Decimal("0.23")) == 230_000


# ── add_tax ──────────────────────────────────────────────────────────────────


class TestAddTax:
    def test_simple_sum(self) -> None:
        assert add_tax(10000, 2300) == 12300

    def test_zero_vat(self) -> None:
        assert add_tax(10000, 0) == 10000

    def test_zero_net(self) -> None:
        assert add_tax(0, 2300) == 2300


# ── RoundingPolicy (position vs total) ───────────────────────────────────────


class TestRoundingPolicy:
    def test_position_single_line(self) -> None:
        """Position rounding with one line = same as total."""
        positions = [InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))]
        result = calculate_vat_by_policy(positions, Decimal("0.23"), "position")
        assert result == 2300

    def test_position_multi_line(self) -> None:
        """Each line rounded separately, then summed."""
        positions = [
            InvoicePositions(net_grosze=100, vat_rate=Decimal("0.23")),   # 23 gr
            InvoicePositions(net_grosze=200, vat_rate=Decimal("0.23")),   # 46 gr
            InvoicePositions(net_grosze=150, vat_rate=Decimal("0.23")),   # 34.5 → 35 gr
        ]
        result = calculate_vat_by_policy(positions, Decimal("0.23"), "position")
        # 23 + 46 + 35 = 104
        assert result == 104

    def test_total_multi_line(self) -> None:
        """Sum net first, then round once."""
        positions = [
            InvoicePositions(net_grosze=100, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=200, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=150, vat_rate=Decimal("0.23")),
        ]
        result = calculate_vat_by_policy(positions, Decimal("0.23"), "total")
        # total net = 450 gr, 450 * 0.23 = 103.5 → 104 gr
        assert result == 104

    def test_position_vs_total_difference(self) -> None:
        """Demonstrate that position vs total can (rarely) differ."""
        # With 3 items of 1 gr each at 23%:
        # position: 0 + 0 + 0 = 0 gr (each 1*0.23=0.23 → 0)
        # total: (1+1+1) * 0.23 = 3 * 0.23 = 0.69 → 1 gr
        positions = [
            InvoicePositions(net_grosze=1, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=1, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=1, vat_rate=Decimal("0.23")),
        ]
        pos_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "position")
        total_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "total")
        assert pos_vat == 0
        assert total_vat == 1

    def test_invalid_rounding_level(self) -> None:
        positions = [InvoicePositions(net_grosze=100, vat_rate=Decimal("0.23"))]
        with pytest.raises(ValueError, match="Unknown rounding_level"):
            calculate_vat_by_policy(positions, Decimal("0.23"), "invalid")


# ── TaxInvariantGuard ────────────────────────────────────────────────────────


class TestTaxInvariantGuard:
    def test_all_invariants_pass(self) -> None:
        """Happy path — all three invariants hold."""
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=5000, vat_rate=Decimal("0.08")),
        ]
        # Calculate expected values
        vat1 = multiply_net_by_vat(10000, Decimal("0.23"))  # 2300
        vat2 = multiply_net_by_vat(5000, Decimal("0.08"))  # 400
        total_net = 15000
        total_vat = 2300 + 400  # 2700
        total_brutto = 15000 + 2700  # 17700

        summary = InvoiceSummary(
            netto_grosze=total_net,
            vat_grosze=total_vat,
            brutto_grosze=total_brutto,
        )
        result = validate_invariants(positions, summary)
        assert result.is_valid
        assert result.error_message == ""

    def test_invariant_1_fails(self) -> None:
        """Sum of position net ≠ summary net."""
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=9999,  # Wrong!
            vat_grosze=2300,
            brutto_grosze=12299,
        )
        result = validate_invariants(positions, summary)
        assert not result.is_valid
        assert "Invariant 1" in result.error_message

    def test_invariant_2_fails(self) -> None:
        """Sum of position VAT ≠ summary VAT."""
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=10000,
            vat_grosze=2299,  # Wrong! Should be 2300
            brutto_grosze=12299,
        )
        result = validate_invariants(positions, summary)
        assert not result.is_valid
        assert "Invariant 2" in result.error_message

    def test_invariant_3_fails(self) -> None:
        """Net + VAT ≠ brutto."""
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=10000,
            vat_grosze=2300,
            brutto_grosze=13000,  # Wrong! Should be 12300
        )
        result = validate_invariants(positions, summary)
        assert not result.is_valid
        assert "Invariant 3" in result.error_message

    def test_all_invariants_fail(self) -> None:
        """All three invariants fail simultaneously."""
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=5000,    # Wrong
            vat_grosze=1000,      # Wrong
            brutto_grosze=2000,   # Wrong
        )
        result = validate_invariants(positions, summary)
        assert not result.is_valid
        # Should contain all three error messages
        assert "Invariant 1" in result.error_message
        assert "Invariant 2" in result.error_message
        assert "Invariant 3" in result.error_message

    def test_empty_positions_zero_summary(self) -> None:
        """Empty invoice must have all zeros."""
        result = validate_invariants([], InvoiceSummary(0, 0, 0))
        assert result.is_valid

    def test_zero_amounts(self) -> None:
        """Zero amounts with zero VAT rate."""
        positions = [
            InvoicePositions(net_grosze=0, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(0, 0, 0)
        result = validate_invariants(positions, summary)
        assert result.is_valid


# ── TaxMathEngine (convenience wrapper) ──────────────────────────────────────


class TestTaxMathEngine:
    def test_calculate_positions_vat(self) -> None:
        total_vat, positions = TaxMathEngine.calculate_positions_vat(
            [10000, 5000], Decimal("0.23"), "position"
        )
        assert len(positions) == 2
        assert positions[0].net_grosze == 10000
        assert positions[1].net_grosze == 5000
        # 10000 * 0.23 = 2300, 5000 * 0.23 = 1150 → 3450
        assert total_vat == 3450

    def test_invoice_positions_vat_property(self) -> None:
        pos = InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))
        assert pos.vat_grosze == 2300


# ── Money Integration Tests ─────────────────────────────────────────────────


class TestMoneyIntegration:
    """Tests for Fowler's Money (py-moneyed) integration with TaxMathEngine."""

    def test_money_to_grosze_basic(self) -> None:
        """Convert Money to grosze."""
        from services.currency_converter import Money
        result = money_to_grosze(Money("123.45", "PLN"))
        assert result == 12345
        assert isinstance(result, int)

    def test_money_to_grosze_zero(self) -> None:
        """Zero Money converts to 0 grosze."""
        from services.currency_converter import Money
        assert money_to_grosze(Money("0.00", "PLN")) == 0

    def test_money_to_grosze_eur(self) -> None:
        """Money in any currency converts to grosze (EUR test)."""
        from services.currency_converter import Money
        result = money_to_grosze(Money("50.00", "EUR"))
        assert result == 5000

    def test_money_to_grosze_rounding(self) -> None:
        """HALF_UP rounding for Money amounts."""
        from services.currency_converter import Money
        # 1.235 PLN → 124 gr (HALF_UP)
        assert money_to_grosze(Money("1.235", "PLN")) == 124
        # 1.234 PLN → 123 gr
        assert money_to_grosze(Money("1.234", "PLN")) == 123

    def test_to_money_basic(self) -> None:
        """Convert grosze to Money."""
        from services.currency_converter import Money
        result = to_money(12345, "PLN")
        assert isinstance(result, Money)
        assert result.currency_code == "PLN"
        assert str(result.amount) == "123.45"

    def test_to_money_default_currency(self) -> None:
        """Default currency is PLN."""
        from services.currency_converter import Money
        result = to_money(100)
        assert result.currency_code == "PLN"

    def test_money_round_trip(self) -> None:
        """money_to_grosze(to_money(x)) == x."""
        from services.currency_converter import Money
        for grosze in [0, 1, 100, 12345, 999999, 100000000]:
            money = to_money(grosze, "PLN")
            back = money_to_grosze(money)
            assert back == grosze, f"Round-trip failed for {grosze} gr"

    def test_multiply_net_by_vat_money(self) -> None:
        """Mulitply Money net by VAT rate."""
        from services.currency_converter import Money
        net = Money("100.00", "PLN")
        vat = multiply_net_by_vat_money(net, Decimal("0.23"))
        assert isinstance(vat, Money)
        assert str(vat.amount) == "23.00"
        assert vat.currency_code == "PLN"

    def test_multiply_net_by_vat_money_zero_rate(self) -> None:
        """Zero VAT rate returns zero Money."""
        from services.currency_converter import Money
        net = Money("100.00", "PLN")
        vat = multiply_net_by_vat_money(net, Decimal("0.00"))
        assert str(vat.amount) == "0.00"
        assert vat.currency_code == "PLN"

    def test_add_tax_money(self) -> None:
        """Add net and VAT as Money."""
        from services.currency_converter import Money
        net = Money("100.00", "PLN")
        vat = Money("23.00", "PLN")
        gross = add_tax_money(net, vat)
        assert isinstance(gross, Money)
        assert str(gross.amount) == "123.00"
        assert gross.currency_code == "PLN"

    def test_add_tax_money_same_currency(self) -> None:
        """Same currency works."""
        from services.currency_converter import Money
        net = Money("50.00", "EUR")
        vat = Money("11.50", "EUR")
        gross = add_tax_money(net, vat)
        assert str(gross.amount) == "61.50"
        assert gross.currency_code == "EUR"

    def test_add_tax_money_different_currency_raises(self) -> None:
        """Adding different currencies raises CurrencyMismatchError."""
        from services.currency_converter import Money, CurrencyMismatchError
        net = Money("100.00", "PLN")
        vat = Money("23.00", "EUR")
        with pytest.raises(CurrencyMismatchError, match="Currency mismatch"):
            add_tax_money(net, vat)

    def test_invoice_positions_from_money(self) -> None:
        """Create InvoicePositions from Money."""
        from services.currency_converter import Money
        net = Money("250.00", "PLN")
        pos = InvoicePositions.from_money(net, Decimal("0.23"))
        assert pos.net_grosze == 25000
        assert pos.vat_rate == Decimal("0.23")
        assert pos.vat_grosze == 5750  # 25000 * 0.23

    def test_invoice_positions_from_money_invalid_type(self) -> None:
        """Passing non-Money to from_money raises TypeError."""
        with pytest.raises(TypeError, match="Expected Money"):
            InvoicePositions.from_money(25000, Decimal("0.23"))  # type: ignore[arg-type]

    def test_invoice_positions_to_net_money(self) -> None:
        """Convert InvoicePositions back to Money."""
        from services.currency_converter import Money
        pos = InvoicePositions(net_grosze=12345, vat_rate=Decimal("0.23"))
        net_money = pos.to_net_money("PLN")
        assert isinstance(net_money, Money)
        assert str(net_money.amount) == "123.45"
        assert net_money.currency_code == "PLN"

    def test_invoice_positions_to_vat_money(self) -> None:
        """Get VAT as Money from InvoicePositions."""
        from services.currency_converter import Money
        pos = InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))
        vat_money = pos.to_vat_money("PLN")
        assert str(vat_money.amount) == "23.00"

    def test_invoice_summary_from_money(self) -> None:
        """Create InvoiceSummary from Money amounts."""
        from services.currency_converter import Money
        summary = InvoiceSummary.from_money(
            netto=Money("100.00", "PLN"),
            vat=Money("23.00", "PLN"),
            brutto=Money("123.00", "PLN"),
        )
        assert summary.netto_grosze == 10000
        assert summary.vat_grosze == 2300
        assert summary.brutto_grosze == 12300

    def test_invoice_summary_from_money_different_currency_raises(self) -> None:
        """Mismatched currencies raise CurrencyMismatchError."""
        from services.currency_converter import Money, CurrencyMismatchError
        with pytest.raises(CurrencyMismatchError):
            InvoiceSummary.from_money(
                netto=Money("100.00", "PLN"),
                vat=Money("23.00", "EUR"),
                brutto=Money("123.00", "PLN"),
            )

    def test_invoice_summary_to_money(self) -> None:
        """Convert InvoiceSummary fields back to Money."""
        from services.currency_converter import Money
        summary = InvoiceSummary(netto_grosze=10000, vat_grosze=2300, brutto_grosze=12300)
        assert summary.to_netto_money("PLN") == Money("100.00", "PLN")
        assert summary.to_vat_money("PLN") == Money("23.00", "PLN")
        assert summary.to_brutto_money("PLN") == Money("123.00", "PLN")

    def test_calculate_positions_vat_money(self) -> None:
        """Calculate VAT from Money positions, return Money."""
        from services.currency_converter import Money
        positions_net = [
            Money("100.00", "PLN"),
            Money("200.00", "PLN"),
            Money("150.00", "PLN"),
        ]
        total_vat_money, inv_positions = TaxMathEngine.calculate_positions_vat_money(
            positions_net, Decimal("0.23"), "position"
        )
        # 100*0.23=23, 200*0.23=46, 150*0.23=34.5→35 → 104 gr
        assert str(total_vat_money.amount) == "1.04"
        assert total_vat_money.currency_code == "PLN"
        assert len(inv_positions) == 3

    def test_calculate_positions_vat_money_different_currency_raises(self) -> None:
        """Mismatched currencies raise."""
        from services.currency_converter import Money, CurrencyMismatchError
        positions_net = [
            Money("100.00", "PLN"),
            Money("50.00", "EUR"),
        ]
        with pytest.raises(CurrencyMismatchError):
            TaxMathEngine.calculate_positions_vat_money(
                positions_net, Decimal("0.23"), "position"
            )

    def test_calculate_positions_vat_money_empty(self) -> None:
        """Empty position list returns zero Money."""
        from services.currency_converter import Money
        total_vat_money, inv_positions = TaxMathEngine.calculate_positions_vat_money(
            [], Decimal("0.23"), "position"
        )
        assert str(total_vat_money.amount) == "0.00"
        assert total_vat_money.currency_code == "PLN"
        assert inv_positions == []

    def test_sum_positions_net_money(self) -> None:
        """Sum of multiple Money amounts."""
        from services.currency_converter import Money
        nets = [Money("100.00", "PLN"), Money("50.00", "PLN"), Money("25.50", "PLN")]
        total = TaxMathEngine.sum_positions_net_money(nets)
        assert str(total.amount) == "175.50"
        assert total.currency_code == "PLN"

    def test_sum_positions_net_money_empty(self) -> None:
        """Empty list returns zero."""
        from services.currency_converter import Money
        total = TaxMathEngine.sum_positions_net_money([])
        assert str(total.amount) == "0.00"

    def test_sum_positions_net_money_different_currency_raises(self) -> None:
        """Different currencies raise."""
        from services.currency_converter import Money, CurrencyMismatchError
        with pytest.raises(CurrencyMismatchError):
            TaxMathEngine.sum_positions_net_money([
                Money("100.00", "PLN"),
                Money("50.00", "EUR"),
            ])

    def test_tax_math_engine_money_methods(self) -> None:
        """TaxMathEngine class exposes all Money methods."""
        assert hasattr(TaxMathEngine, "money_to_grosze")
        assert hasattr(TaxMathEngine, "to_money")
        assert hasattr(TaxMathEngine, "multiply_net_by_vat_money")
        assert hasattr(TaxMathEngine, "add_tax_money")
        assert hasattr(TaxMathEngine, "calculate_positions_vat_money")
        assert hasattr(TaxMathEngine, "sum_positions_net_money")

    def test_calculate_vat_by_policy_money(self) -> None:
        """RoundingPolicy.calculate_money returns Money."""
        from services.currency_converter import Money
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=5000, vat_rate=Decimal("0.23")),
        ]
        vat_money = RoundingPolicy.calculate_money(
            positions, Decimal("0.23"), "position", "PLN"
        )
        assert isinstance(vat_money, Money)
        assert str(vat_money.amount) == "34.50"
        assert vat_money.currency_code == "PLN"

# ── Hypothesis-style property tests (deterministic) ─────────────────────────


class TestPropertyBased:
    def test_round_trip_deterministic(self) -> None:
        """to_grosze(to_zlotowki(x)) == x for many values."""
        test_cases = [0, 1, 2, 99, 100, 101, 10000, 999999, 123456789]
        for grosze in test_cases:
            assert to_grosze(to_zlotowki(grosze)) == grosze

    def test_vat_never_negative(self) -> None:
        """VAT amount must never be negative for positive rates."""
        for net in [0, 1, 100, 10000, 999999]:
            for rate in [Decimal("0.23"), Decimal("0.08"), Decimal("0.05")]:
                vat = multiply_net_by_vat(net, rate)
                assert vat >= 0, f"Negative VAT for net={net}, rate={rate}"

    def test_gross_at_least_net(self) -> None:
        """Brutto must always be >= netto."""
        for net in [0, 1, 100, 10000]:
            for rate in [Decimal("0.23"), Decimal("0.08"), Decimal("0.05"), Decimal("0.00")]:
                vat = multiply_net_by_vat(net, rate)
                gross = add_tax(net, vat)
                assert gross >= net, f"Gross < net for net={net}, rate={rate}"
