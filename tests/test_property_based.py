"""
Property-Based Testing z Hypothesis — zaawansowane testowanie matematycznych
właściwości systemu podatkowego.

Pięć właściwości (properties) zgodnie z dokumentem:

  Property 1 — Idempotentność konwersji grosze ↔ złotówki
  Property 2 — Netto + VAT = Brutto (dla pojedynczej pozycji, ROUND_HALF_UP)
  Property 3 — Suma pozycji = suma faktury (dla metody position)
  Property 4 — Determinizm pipeline
  Property 5 — Odporność na złośliwe dane

Używa hypothesis z dekoratorem @given do generowania losowych danych.
"""

from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
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

# Liczba pozycji na fakturze
position_counts = st.integers(min_value=1, max_value=20)

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
        """VAT error never exceeds 0.5 grosza before rounding (HALF_UP).

        This proves that the multiplication is accurate to within
        half a grosz before rounding.
        """
        # Compute exact VAT as Decimal (no rounding)
        exact_vat = Decimal(str(net_grosze)) * rate
        # Compute rounded VAT
        rounded_vat = multiply_net_by_vat(net_grosze, rate)

        # The difference between exact and rounded must be <= 0.5 grosza
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

        # Oblicz podsumowanie
        total_net = sum(p.net_grosze for p in positions)
        total_vat = sum(p.vat_grosze for p in positions)
        total_brutto = total_net + total_vat

        summary = InvoiceSummary(
            netto_grosze=total_net,
            vat_grosze=total_vat,
            brutto_grosze=total_brutto,
        )

        # Sprawdź niezmienniki
        result = validate_invariants(positions, summary)
        assert result.is_valid, (
            f"Invariants failed for {len(positions)} positions: {result.error_message}"
        )

    @given(positions_strategy)
    @settings(max_examples=100)
    def test_position_vs_total_difference_reasonable(self, positions_data: list[tuple[int, Decimal]]) -> None:
        """The difference between position and total rounding is bounded.

        For position rounding, each line's VAT is rounded individually.
        For total rounding, the sum of nets is rounded once.
        The difference should never exceed the number of positions (in grosze).
        """
        positions = [
            InvoicePositions(net_grosze=net, vat_rate=rate)
            for net, rate in positions_data
        ]

        pos_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "position")
        total_vat = calculate_vat_by_policy(positions, Decimal("0.23"), "total")

        diff = abs(pos_vat - total_vat)
        # Maximum difference is bounded by number of positions
        # (each position's rounding error ≤ 0.5 gr, so total error ≤ n * 0.5)
        max_diff = (len(positions) + 1) // 2  # ceiling of n/2
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
    zerowych, ogromnych, nieprawidłowych) system nie rzuca wyjątku,
    tylko zwraca poprawny wynik lub błąd walidacji.
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
# Property 6 — Money round-trip (Fowler's Money)
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty6MoneyRoundTrip:
    """Property 6: Fowler's Money round-trip — konwersja grosze ↔ Money i z powrotem
    jest idempotentna dla dowolnych kwot i walut.

    ``money_to_grosze(to_money(x, c)) == x`` dla każdego int x i waluty c.
    ``to_money(money_to_grosze(m), m.currency) == m`` dla każdego Money m.
    """

    # Obsługiwane waluty (znane CurrencyConverter.KNOWN_CURRENCIES + PLN)
    currencies = st.sampled_from(["PLN", "EUR", "USD", "GBP", "CHF", "CZK", "NOK", "SEK", "DKK", "HUF"])

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_grosze_to_money_round_trip(self, grosze: int, currency: str) -> None:
        """money_to_grosze(to_money(x, c)) == x dla każdego int x i waluty c."""
        money = to_money(grosze, currency)
        back = money_to_grosze(money)
        assert back == grosze, (
            f"Round-trip failed: {grosze} gr → {money} → {back} gr (currency={currency})"
        )

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_money_currency_preserved(self, grosze: int, currency: str) -> None:
        """to_money zachowuje walutę — currency_code zgadza się z argumentem."""
        money = to_money(grosze, currency)
        assert money.currency_code == currency, (
            f"Currency mismatch: expected {currency}, got {money.currency_code}"
        )

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_money_amount_precision(self, grosze: int, currency: str) -> None:
        """Money.amount ma maksymalnie 2 miejsca po przecinku (zaokrąglone do groszy)."""
        money = to_money(grosze, currency)
        amount_str = str(money.amount)
        if "." in amount_str:
            decimals = amount_str.split(".")[1]
            assert len(decimals) <= 2, (
                f"Money amount {amount_str} has {len(decimals)} decimal places (max 2)"
            )

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=200)
    def test_money_type_error_on_non_money(self, grosze: int, currency: str) -> None:
        """money_to_grosze rzuca TypeError dla non-Money arg."""
        # Non-Money input should raise TypeError
        with pytest.raises(TypeError, match="Expected Money"):
            money_to_grosze(grosze)  # passing int instead of Money

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=500)
    def test_to_money_amount_value(self, grosze: int, currency: str) -> None:
        """to_money(x) tworzy Money o wartości x/100 w jednostkach waluty.

        Czyli to_money(12345, "PLN").amount == Decimal("123.45").
        """
        from decimal import Decimal
        money = to_money(grosze, currency)
        expected = Decimal(grosze) / Decimal(100)
        assert money.amount == expected, (
            f"to_money({grosze}, {currency}) = {money.amount}, expected {expected}"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 7 — Money VAT arithmetic
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty7MoneyVatArithmetic:
    """Property 7: Money-aware VAT operations zachowują walutę i poprawność.

    - ``multiply_net_by_vat_money`` zwraca Money w tej samej walucie
    - ``add_tax_money`` zwraca Money w tej samej walucie
    - ``net + vat = gross`` (w Money)
    - Wyniki Money mają maksymalnie 2 miejsca po przecinku
    """

    currencies = st.sampled_from(["PLN", "EUR", "USD", "GBP"])

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_multiply_vat_preserves_currency(self, grosze: int, currency: str, rate: Decimal) -> None:
        """multiply_net_by_vat_money zwraca Money w tej samej walucie."""
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        assert isinstance(vat, Money), f"Expected Money, got {type(vat)}"
        assert vat.currency_code == currency, (
            f"VAT currency {vat.currency_code} != net currency {currency}"
        )

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_add_tax_preserves_currency(self, grosze: int, currency: str, rate: Decimal) -> None:
        """add_tax_money zwraca Money w tej samej walucie, net + vat = gross."""
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        gross = add_tax_money(net, vat)

        assert isinstance(gross, Money), f"Expected Money, got {type(gross)}"
        assert gross.currency_code == currency, (
            f"Gross currency {gross.currency_code} != net currency {currency}"
        )

        # net + vat = gross in grosze
        expected_gross_grosze = money_to_grosze(net) + money_to_grosze(vat)
        actual_gross_grosze = money_to_grosze(gross)
        assert actual_gross_grosze == expected_gross_grosze, (
            f"net({money_to_grosze(net)}) + vat({money_to_grosze(vat)}) = "
            f"{expected_gross_grosze}, got {actual_gross_grosze} gr"
        )

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_vat_money_never_negative(self, grosze: int, currency: str, rate: Decimal) -> None:
        """VAT w Money jest zawsze >= 0 dla nieujemnych stawek."""
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        assert money_to_grosze(vat) >= 0, (
            f"Negative VAT for net={grosze} {currency}, rate={rate}"
        )

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=500)
    def test_gross_geq_net_in_grosze(self, grosze: int, currency: str, rate: Decimal) -> None:
        """Brutto w groszach >= netto w groszach."""
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        gross = add_tax_money(net, vat)

        net_gr = money_to_grosze(net)
        gross_gr = money_to_grosze(gross)
        assert gross_gr >= net_gr, (
            f"Gross {gross_gr} gr < net {net_gr} gr (rate={rate})"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 8 — Money determinism
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty8MoneyDeterminism:
    """Property 8: Wszystkie Money-aware operacje są deterministyczne —
    te same dane wejściowe → identyczne wyniki.
    """

    currencies = st.sampled_from(["PLN", "EUR"])

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=200)
    def test_multiply_vat_deterministic(self, grosze: int, currency: str, rate: Decimal) -> None:
        """multiply_net_by_vat_money jest deterministyczne."""
        net = to_money(grosze, currency)
        r1 = multiply_net_by_vat_money(net, rate)
        r2 = multiply_net_by_vat_money(net, rate)
        r3 = multiply_net_by_vat_money(net, rate)
        assert r1 == r2 == r3, "Non-deterministic multiply_net_by_vat_money"

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=200)
    def test_add_tax_deterministic(self, grosze: int, currency: str, rate: Decimal) -> None:
        """add_tax_money jest deterministyczne."""
        net = to_money(grosze, currency)
        vat = multiply_net_by_vat_money(net, rate)
        r1 = add_tax_money(net, vat)
        r2 = add_tax_money(net, vat)
        r3 = add_tax_money(net, vat)
        assert r1 == r2 == r3, "Non-deterministic add_tax_money"

    @given(st.integers(min_value=0, max_value=10_000_000), currencies)
    @settings(max_examples=200)
    def test_money_to_grosze_deterministic(self, grosze: int, currency: str) -> None:
        """money_to_grosze jest deterministyczne."""
        money = to_money(grosze, currency)
        r1 = money_to_grosze(money)
        r2 = money_to_grosze(money)
        r3 = money_to_grosze(money)
        assert r1 == r2 == r3, "Non-deterministic money_to_grosze"

    @given(st.integers(min_value=0, max_value=100_000_000), currencies)
    @settings(max_examples=200)
    def test_to_money_deterministic(self, grosze: int, currency: str) -> None:
        """to_money jest deterministyczne."""
        m1 = to_money(grosze, currency)
        m2 = to_money(grosze, currency)
        m3 = to_money(grosze, currency)
        assert m1 == m2 == m3, "Non-deterministic to_money"


# ═══════════════════════════════════════════════════════════════════════════════
# Property 9 — InvoicePositions / InvoiceSummary Money API
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty9MoneyDataClasses:
    """Property 9: Money-aware konstruktory InvoicePositions i InvoiceSummary
    są spójne z ich int-based odpowiednikami.
    """

    currencies = st.sampled_from(["PLN", "EUR", "USD"])

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=300)
    def test_invoice_positions_from_money_consistency(
        self, grosze: int, currency: str, rate: Decimal
    ) -> None:
        """InvoicePositions.from_money → net_grosze zgadza się z int."""
        net = to_money(grosze, currency)
        pos = InvoicePositions.from_money(net, rate)
        assert pos.net_grosze == grosze, (
            f"from_money: expected net_grosze={grosze}, got {pos.net_grosze}"
        )
        assert pos.vat_rate == rate

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=300)
    def test_invoice_positions_to_money_round_trip(
        self, grosze: int, currency: str, rate: Decimal
    ) -> None:
        """InvoicePositions → to_net_money → money_to_grosze == net_grosze."""
        pos = InvoicePositions(net_grosze=grosze, vat_rate=rate)
        net_money = pos.to_net_money(currency)
        assert net_money.currency_code == currency
        back = money_to_grosze(net_money)
        assert back == grosze, (
            f"to_net_money round-trip: {grosze} → {net_money} → {back} gr"
        )

    @given(st.integers(min_value=0, max_value=10_000_000), currencies, vat_rates)
    @settings(max_examples=300)
    def test_invoice_positions_vat_money_consistency(
        self, grosze: int, currency: str, rate: Decimal
    ) -> None:
        """VAT z to_vat_money zgadza się z vat_grosze."""
        pos = InvoicePositions(net_grosze=grosze, vat_rate=rate)
        vat_money = pos.to_vat_money(currency)
        expected_vat = multiply_net_by_vat(grosze, rate)
        assert money_to_grosze(vat_money) == expected_vat, (
            f"VAT mismatch: pos.vat_grosze={pos.vat_grosze}, "
            f"to_vat_money={money_to_grosze(vat_money)}, expected={expected_vat}"
        )

    @given(
        st.integers(min_value=0, max_value=10_000_000),
        st.integers(min_value=0, max_value=10_000_000),
        currencies,
    )
    @settings(max_examples=300)
    def test_invoice_summary_from_money_consistency(
        self, netto_gr: int, vat_gr: int, currency: str
    ) -> None:
        """InvoiceSummary.from_money → grosze są zgodne z int."""
        brutto_gr = netto_gr + vat_gr
        summary = InvoiceSummary.from_money(
            netto=to_money(netto_gr, currency),
            vat=to_money(vat_gr, currency),
            brutto=to_money(brutto_gr, currency),
        )
        assert summary.netto_grosze == netto_gr
        assert summary.vat_grosze == vat_gr
        assert summary.brutto_grosze == brutto_gr

    @given(
        st.integers(min_value=0, max_value=10_000_000),
        st.integers(min_value=0, max_value=10_000_000),
        currencies,
    )
    @settings(max_examples=300)
    def test_invoice_summary_to_money_round_trip(
        self, netto_gr: int, vat_gr: int, currency: str
    ) -> None:
        """InvoiceSummary → to_*_money → money_to_grosze == oryginalne grosze."""
        brutto_gr = netto_gr + vat_gr
        summary = InvoiceSummary(netto_grosze=netto_gr, vat_grosze=vat_gr, brutto_grosze=brutto_gr)

        assert money_to_grosze(summary.to_netto_money(currency)) == netto_gr
        assert money_to_grosze(summary.to_vat_money(currency)) == vat_gr
        assert money_to_grosze(summary.to_brutto_money(currency)) == brutto_gr

    @given(
        st.lists(
            st.tuples(
                st.integers(min_value=0, max_value=10_000_000),
                currencies,
            ),
            min_size=1,
            max_size=10,
        ),
        vat_rates,
    )
    @settings(max_examples=100)
    def test_calculate_positions_vat_money_preserves_currency(
        self,
        positions_data: list[tuple[int, str]],
        vat_rate: Decimal,
    ) -> None:
        """calculate_positions_vat_money zwraca Money w walucie pierwszej pozycji."""
        positions_net = [to_money(gr, cur) for gr, cur in positions_data]
        # Skip if mixed currencies — that's tested separately
        first_currency = positions_net[0].currency_code
        if not all(m.currency_code == first_currency for m in positions_net):
            return  # mixed currencies → testowany oddzielnie

        total_vat_money, inv_positions = TaxMathEngine.calculate_positions_vat_money(
            positions_net, vat_rate, "position"
        )
        assert total_vat_money.currency_code == first_currency

        # Sprawdź, że InvoicePositions mają poprawne net_grosze
        for i, pos in enumerate(inv_positions):
            expected_grosze = money_to_grosze(positions_net[i])
            assert pos.net_grosze == expected_grosze, (
                f"Position {i}: net_grosze {pos.net_grosze} != expected {expected_grosze}"
            )
            assert pos.vat_rate == vat_rate

    @given(
        st.lists(
            st.tuples(
                st.integers(min_value=0, max_value=10_000_000),
                currencies,
            ),
            min_size=1,
            max_size=10,
        ),
    )
    @settings(max_examples=100)
    def test_sum_positions_net_money(
        self,
        positions_data: list[tuple[int, str]],
    ) -> None:
        """sum_positions_net_money zwraca sumę wszystkich pozycji (w tej samej walucie)."""
        positions_net = [to_money(gr, cur) for gr, cur in positions_data]
        first_currency = positions_net[0].currency_code
        if not all(m.currency_code == first_currency for m in positions_net):
            return

        total = TaxMathEngine.sum_positions_net_money(positions_net)
        assert total.currency_code == first_currency

        expected_grosze = sum(money_to_grosze(m) for m in positions_net)
        assert money_to_grosze(total) == expected_grosze, (
            f"sum_positions_net_money: expected {expected_grosze} gr, got {money_to_grosze(total)} gr"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Property 10 — Money CurrencyMismatchError
# ═══════════════════════════════════════════════════════════════════════════════


class TestProperty10CurrencyMismatch:
    """Property 10: Mieszanie walut w Money-aware operacjach rzuca
    CurrencyMismatchError, nigdy cichy błąd.
    """

    @given(
        st.integers(min_value=100, max_value=10_000_000),
        st.integers(min_value=100, max_value=10_000_000),
    )
    @settings(max_examples=200)
    def test_add_tax_money_different_currencies_raises(
        self, net_gr: int, vat_gr: int
    ) -> None:
        """add_tax_money z różnymi walutami → CurrencyMismatchError."""
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
        """calculate_positions_vat_money z mieszanymi walutami → CurrencyMismatchError.

        Używamy stałej kwoty (100 PLN) we wszystkich pozycjach, ale różnych walut
        — tylko waluta ma się różnić.
        """
        # Skip jeśli wszystkie waluty takie same — to nie jest mieszany test
        if len(set(currencies)) == 1:
            return

        positions_net = [to_money(10000, c) for c in currencies]  # 100.00 w każdej walucie

        with pytest.raises(CurrencyMismatchError):
            TaxMathEngine.calculate_positions_vat_money(
                positions_net, Decimal("0.23"), "position"
            )
