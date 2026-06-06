"""
Property-Based Testing — zaawansowane testowanie matematycznych
właściwości systemu podatkowego.

Używa hypothesis z dekoratorem @given do generowania losowych danych.
Crosshair (statyczna analiza SMT) jest dostępny dla prostszych, typowanych testów
— dla złożonych generatorów hypothesis pozostaje najlepszym narzędziem.

Pięć właściwości (properties) zgodnie z dokumentem:

  Property 1 — Idempotentność konwersji grosze ↔ złotówki
  Property 2 — Netto + VAT = Brutto (dla pojedynczej pozycji, ROUND_HALF_UP)
  Property 3 — Suma pozycji = suma faktury (dla metody position)
  Property 4 — Determinizm pipeline
  Property 5 — Odporność na złośliwe dane
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# ── Import badanego kodu ─────────────────────────────────────────────────────
from Code.tax.math_engine import (
    InvoicePositions,
    InvoiceSummary,
    TaxMathEngine,
    add_tax,
    add_tax_money,
    calculate_vat_by_policy,
    money_to_grosze,
    multiply_net_by_vat,
    multiply_net_by_vat_money,
    to_grosze,
    to_money,
    to_zlotowki,
    validate_invariants,
)
from services.currency_converter import Money, CurrencyMismatchError


# ── Hypothesis strategies ────────────────────────────────────────────────────

# Kwoty w złotówkach (Decimal) z 2 miejscami po przecinku, zakres 0.01 – 1_000_000.00
pln_amounts = st.decimals(
    min_value=Decimal("0.01"),
    max_value=Decimal("1_000_000.00"),
    places=2,
)

# Kwoty w groszach (int) — zakres 1 – 100_000_000
grosze_amounts = st.integers(min_value=0, max_value=100_000_000)

# Stawki VAT zgodne z polskim prawem
vat_rates = st.sampled_from([
    Decimal("0.00"),
    Decimal("0.05"),
    Decimal("0.08"),
    Decimal("0.23"),
])

# Pojedyncza pozycja faktury jako (net_grosze, vat_rate)
position_strategy = st.tuples(grosze_amounts, vat_rates)

# Lista pozycji
positions_strategy = st.lists(
    position_strategy,
    min_size=1,
    max_size=20,
)

# Złośliwe dane — kwoty ujemne, zera, ogromne, nieprawidłowe stawki
malicious_amounts = st.decimals(
    min_value=Decimal("-1_000_000.00"),
    max_value=Decimal("10_000_000.00"),
    places=2,
)
malicious_grosze = st.integers(min_value=-100_000_000, max_value=100_000_000)
malicious_rates = st.decimals(
    min_value=Decimal("-1.00"),
    max_value=Decimal("2.00"),
    places=2,
)


# ═══════════════════════════════════════════════════════════════════════════════
# Property 1 — Idempotentność konwersji grosze ↔ złotówki
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty1RoundTrip:
    """Property 1: Dla dowolnej kwoty w złotówkach (Decimal, 2 miejsca),
    konwersja na grosze (int) i z powrotem na złotówki daje tę samą kwotę.
    """

    @given(pln_amounts)
    @settings(max_examples=200)
    def test_grosze_round_trip(self, amount_pln: Decimal) -> None:
        """to_grosze(to_zlotowki(x)) == x dla dowolnego x."""
        grosze = to_grosze(amount_pln)
        back = to_zlotowki(grosze)
        assert back == amount_pln, (
            f"Round-trip failed: {amount_pln} → {grosze} gr → {back}"
        )

    @given(grosze_amounts)
    @settings(max_examples=200)
    def test_zlotowki_round_trip(self, grosze: int) -> None:
        """to_zlotowki(to_grosze(x)) == x dla dowolnego x."""
        zloty = to_zlotowki(grosze)
        back = to_grosze(zloty)
        assert back == grosze, (
            f"Round-trip failed: {grosze} gr → {zloty} → {back} gr"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 2 — Netto + VAT = Brutto (dla pojedynczej pozycji, ROUND_HALF_UP)
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty2NetPlusVatEqualsGross:
    """Property 2: Dla dowolnego netto i dowolnej stawki VAT,
    netto + VAT = brutto (zgodnie z ROUND_HALF_UP).
    """

    @given(grosze_amounts, vat_rates)
    @settings(max_examples=500)
    def test_net_plus_vat_equals_gross(self, net_grosze: int, rate: Decimal) -> None:
        """net + vat == brutto (wszystkie wartości w groszach)."""
        vat = multiply_net_by_vat(net_grosze, rate)
        brutto = add_tax(net_grosze, vat)
        assert brutto == net_grosze + vat, (
            f"net={net_grosze} gr, rate={rate}, vat={vat} gr, brutto={brutto} gr"
        )
        # Brutto zawsze >= netto (dla nieujemnych stawek)
        assert brutto >= net_grosze

    @given(grosze_amounts, vat_rates)
    @settings(max_examples=500)
    def test_vat_never_negative(self, net_grosze: int, rate: Decimal) -> None:
        """VAT never negative for non-negative rates."""
        vat = multiply_net_by_vat(net_grosze, rate)
        assert vat >= 0, f"Negative VAT for net={net_grosze}, rate={rate}"

    @given(grosze_amounts, vat_rates)
    @settings(max_examples=200)
    def test_vat_precision_max_1_grosz_error(self, net_grosze: int, rate: Decimal) -> None:
        """VAT error never exceeds 0.5 grosza before rounding (HALF_UP)."""
        exact_vat = Decimal(str(net_grosze)) * rate
        rounded_vat = multiply_net_by_vat(net_grosze, rate)
        diff = abs(exact_vat - Decimal(str(rounded_vat)))
        assert diff <= Decimal("0.5"), (
            f"VAT rounding error too large: exact={exact_vat}, "
            f"rounded={rounded_vat}, diff={diff}"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 3 — Suma pozycji = suma faktury (dla metody position)
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty3PositionSum:
    """Property 3: Dla dowolnej listy pozycji, obliczonych metodą position:
    - Suma netto pozycji == netto faktury
    - Suma VAT pozycji == VAT faktury
    - Netto + VAT == Brutto
    """

    @given(positions_strategy)
    @settings(max_examples=200)
    def test_position_sum_invariants(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """All three invariants hold for position-level rounding."""
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]
        total_net = sum(p.net_grosze for p in positions)
        total_vat = sum(p.vat_grosze for p in positions)
        total_brutto = total_net + total_vat
        summary = InvoiceSummary(
            netto_grosze=total_net,
            vat_grosze=total_vat,
            brutto_grosze=total_brutto,
        )
        result = validate_invariants(positions, summary)
        assert result.is_valid, (
            f"Invariants failed for {len(positions)} positions: {result.error_message}"
        )

    @given(positions_strategy)
    @settings(max_examples=100)
    def test_position_vs_total_difference_reasonable(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """The difference between position and total rounding is bounded."""
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]
        pos_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "position")
        total_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "total")
        diff = abs(pos_vat - total_vat)
        max_diff = (len(positions) + 1) // 2
        assert diff <= max_diff, (
            f"Position vs total VAT diff too large: pos={pos_vat}, "
            f"total={total_vat}, diff={diff}, max={max_diff}"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 4 — Determinizm pipeline
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty4Determinism:
    """Property 4: Dla identycznych danych wejściowych, wielokrotne
    uruchomienie daje identyczne wyniki.
    """

    @given(grosze_amounts, vat_rates)
    @settings(max_examples=100)
    def test_multiply_net_by_vat_deterministic(self, net_grosze: int, rate: Decimal) -> None:
        """multiply_net_by_vat is deterministic."""
        result1 = multiply_net_by_vat(net_grosze, rate)
        result2 = multiply_net_by_vat(net_grosze, rate)
        result3 = multiply_net_by_vat(net_grosze, rate)
        assert result1 == result2 == result3

    @given(positions_strategy)
    @settings(max_examples=50)
    def test_calculate_vat_deterministic(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """calculate_vat_by_policy is deterministic for both methods."""
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]
        for method in ("position", "total"):
            r1 = calculate_vat_by_policy(positions, Decimal("0.23"), method)
            r2 = calculate_vat_by_policy(positions, Decimal("0.23"), method)
            r3 = calculate_vat_by_policy(positions, Decimal("0.23"), method)
            assert r1 == r2 == r3, f"Non-deterministic for method={method}"


# ═══════════════════════════════════════════════════════════════════════════════
# Property 5 — Odporność na złośliwe dane
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty5MaliciousInput:
    """Property 5: Dla dowolnych danych wejściowych (w tym ujemnych,
    zerowych, ogromnych, nieprawidłowych) system nie rzuca wyjątku.
    """

    @given(malicious_grosze, malicious_rates)
    @settings(max_examples=500)
    def test_multiply_never_crashes(self, net_grosze: int, rate: Decimal) -> None:
        """multiply_net_by_vat never crashes for any inputs."""
        vat = multiply_net_by_vat(net_grosze, rate)
        assert isinstance(vat, int)
        if rate == Decimal("0.00"):
            assert vat == 0

    @given(malicious_amounts)
    @settings(max_examples=200)
    def test_to_grosze_never_crashes(self, amount: Decimal) -> None:
        """to_grosze never crashes for any Decimal input."""
        result = to_grosze(amount)
        assert isinstance(result, int)

    @given(malicious_grosze)
    @settings(max_examples=200)
    def test_to_zlotowki_never_crashes(self, grosze: int) -> None:
        """to_zlotowki never crashes for any int input."""
        result = to_zlotowki(grosze)
        assert isinstance(result, Decimal)

    @given(st.lists(
        st.tuples(malicious_grosze, malicious_rates),
        min_size=0,
        max_size=50,
    ))
    @settings(max_examples=200)
    def test_validate_invariants_never_crashes(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """validate_invariants never crashes for any data."""
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]
        total_net = sum(p.net_grosze for p in positions)
        total_vat = sum(p.vat_grosze for p in positions)
        summary = InvoiceSummary(
            netto_grosze=total_net,
            vat_grosze=total_vat,
            brutto_grosze=total_net + total_vat,
        )
        result = validate_invariants(positions, summary)
        assert isinstance(result.is_valid, bool)
        assert isinstance(result.error_message, str)

    @given(st.lists(
        st.tuples(malicious_grosze, malicious_rates),
        min_size=1,
        max_size=20,
    ))
    @settings(max_examples=100)
    def test_calculate_vat_by_policy_never_crashes(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """calculate_vat_by_policy never crashes for any data."""
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]
        for method in ("position", "total"):
            result = calculate_vat_by_policy(positions, Decimal("0.23"), method)
            assert isinstance(result, int)

    def test_empty_positions_never_crashes(self) -> None:
        """Empty positions list doesn't crash any function."""
        assert calculate_vat_by_policy([], Decimal("0.23"), "position") == 0
        assert calculate_vat_by_policy([], Decimal("0.23"), "total") == 0
        result = validate_invariants([], InvoiceSummary(0, 0, 0))
        assert result.is_valid


# ═══════════════════════════════════════════════════════════════════════════════
# Property 6-10 — Nexus-Money (msgspec.Struct) tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty6MoneyRoundTrip:
    """Property 6: Nexus-Money round-trip — konwersja grosze ↔ Money."""

    currencies = st.sampled_from(["PLN", "EUR", "USD", "GBP", "CHF"])

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_grosze_to_money_round_trip(self, grosze: int, currency: str) -> None:
        money = to_money(grosze, currency)
        back = money_to_grosze(money)
        assert back == grosze

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_money_currency_preserved(self, grosze: int, currency: str) -> None:
        money = to_money(grosze, currency)
        assert money.currency == currency

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=200)
    def test_money_type_error_on_non_money(self, grosze: int, currency: str) -> None:
        with pytest.raises(TypeError, match="Expected Money"):
            money_to_grosze(grosze)  # passing int instead of Money

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_to_money_amount_value(self, grosze: int, currency: str) -> None:
        money = to_money(grosze, currency)
        expected = Decimal(grosze) / Decimal(100)
        assert money.amount == expected


class TestProperty7MoneyVatArithmetic:
    """Property 7: Money-aware VAT operations."""

    currencies = st.sampled_from(["PLN", "EUR", "USD", "GBP"])

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_multiply_vat_preserves_currency(self, grosze: int, currency: str, rate: Decimal) -> None:
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        assert isinstance(vat, Money)
        assert vat.currency == currency

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_add_tax_preserves_currency(self, grosze: int, currency: str, rate: Decimal) -> None:
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        gross = add_tax_money(net, vat)
        assert isinstance(gross, Money)
        assert gross.currency == currency
        expected_gross_grosze = money_to_grosze(net) + money_to_grosze(vat)
        actual_gross_grosze = money_to_grosze(gross)
        assert actual_gross_grosze == expected_gross_grosze

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_vat_money_never_negative(self, grosze: int, currency: str, rate: Decimal) -> None:
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        assert money_to_grosze(vat) >= 0


class TestProperty10CurrencyMismatch:
    """Property 10: Mieszanie walut rzuca CurrencyMismatchError."""

    @given(
        st.integers(min_value=100, max_value=10_000_000),
        st.integers(min_value=100, max_value=10_000_000),
    )
    @settings(max_examples=200)
    def test_add_tax_money_different_currencies_raises(
        self, net_gr: int, vat_gr: int
    ) -> None:
        net = to_money(net_gr, "PLN")
        vat = to_money(vat_gr, "EUR")
        with pytest.raises(CurrencyMismatchError):
            add_tax_money(net, vat)

    @given(
        st.lists(
            st.sampled_from(["PLN", "EUR", "USD"]),
            min_size=2,
            max_size=5,
        )
    )
    @settings(max_examples=100)
    def test_calculate_positions_vat_money_mixed_currencies_raises(
        self, currencies: list[str]
    ) -> None:
        if len(set(currencies)) == 1:
            return
        positions_net = [to_money(10000, c) for c in currencies]
        with pytest.raises(CurrencyMismatchError):
            TaxMathEngine.calculate_positions_vat_money(
                positions_net, Decimal("0.23"), "position"
            )
