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

from Code.tax.math_engine import (
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
