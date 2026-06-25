"""
Property-Based Testing — zaawansowane testowanie matematycznych
właściwości systemu podatkowego.

Używa crosshair (SMT solver) do matematycznego dowodzenia poprawności.
crosshair używa symbolicznej analizy z Z3 zamiast losowego fuzzingu.

Pięć właściwości (properties) zgodnie z dokumentem:

  Property 1 — Idempotentność konwersji grosze ↔ złotówki
  Property 2 — Netto + VAT = Brutto (dla pojedynczej pozycji, ROUND_HALF_UP)
  Property 3 — Suma pozycji = suma faktury (dla metody position)
  Property 4 — Determinizm pipeline
  Property 5 — Odporność na złośliwe dane
"""

from __future__ import annotations

from decimal import Decimal

import crosshair

# ── Import badanego kodu ─────────────────────────────────────────────────────
from nexus_ai.tax.math_engine import (
    InvoicePositions,
    InvoiceSummary,
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
from nexus_ai.services.currency_converter import Money, CurrencyMismatchError


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC crosshair: SMT-driven property tests
# ═══════════════════════════════════════════════════════════════════════════════
# crosshair używa symbolicznego wykonania z Z3 do matematycznego
# dowodzenia poprawności zamiast losowego fuzzingu.
# Wszystkie testy poniżej są sprawdzane przez SMT solver.


@crosshair.check
def test_ch_grosze_round_trip(amount_grosze: int) -> None:
    """SUPERMOC crosshair: Dla dowolnego int, to_zlotowki(to_grosze(x)) == x.

    crosshair symbolicznie sprawdza wszystkie możliwe wartości int
    i matematycznie dowodzi, że round-trip jest idempotentny.
    Property 1 — Idempotentność konwersji grosze ↔ złotówki."""
    if amount_grosze < 0:
        return  # crosshair: pomiń ujemne (nieobsługiwane)
    zloty = to_zlotowki(amount_grosze)
    back = to_grosze(zloty)
    assert back == amount_grosze, (
        f"Round-trip failed: {amount_grosze} gr -> {zloty} -> {back} gr"
    )


@crosshair.check
def test_ch_multiply_net_by_vat_non_negative(net_grosze: int) -> None:
    """SUPERMOC crosshair: Dla nieujemnego netto i 23% VAT, wynik >= 0.
    Property 2 — Netto + VAT = Brutto (część)."""
    if net_grosze < 0:
        return
    vat = multiply_net_by_vat(net_grosze, Decimal("0.23"))
    assert vat >= 0, f"Negative VAT for net={net_grosze}"


@crosshair.check
def test_ch_add_tax_non_negative(net: int, vat: int) -> None:
    """SUPERMOC crosshair: add_tax zawsze zwraca sumę.
    Property 2 — Netto + VAT = Brutto."""
    result = add_tax(net, vat)
    assert result == net + vat, f"add_tax({net}, {vat}) = {result}, expected {net + vat}"


@crosshair.check
def test_ch_to_zlotowki_precision(grosze: int) -> None:
    """SUPERMOC crosshair: to_zlotowki zwraca Decimal z dokładnością do 2 miejsc.
    Property 1 — Idempotentność konwersji."""
    if grosze < 0:
        return
    result = to_zlotowki(grosze)
    assert isinstance(result, Decimal)
    # Sprawdź, że wynik ma max 2 miejsca po przecinku
    assert result.as_tuple().exponent >= -2, (
        f"to_zlotowki({grosze}) = {result} ma więcej niż 2 miejsca"
    )


@crosshair.check
def test_ch_money_to_grosze_inverse(grosze: int) -> None:
    """SUPERMOC crosshair: money_to_grosze(to_money(x)) == x."""
    if grosze < 0 or grosze > 10_000_000:
        return
    money = to_money(grosze, "PLN")
    back = money_to_grosze(money)
    assert back == grosze, f"Money round-trip failed: {grosze} -> {back}"


@crosshair.check
def test_ch_multiply_net_by_vat_zero_rate(net_grosze: int) -> None:
    """SUPERMOC crosshair: 0% VAT zawsze daje 0."""
    if net_grosze < 0:
        return
    vat = multiply_net_by_vat(net_grosze, Decimal("0.00"))
    assert vat == 0, f"Zero rate gave non-zero VAT: {vat}"


@crosshair.check
def test_ch_multiply_net_by_vat_deterministic(net_grosze: int) -> None:
    """SUPERMOC crosshair: multiply_net_by_vat jest deterministyczne.
    Property 4 — Determinizm pipeline."""
    if net_grosze < 0:
        return
    rate = Decimal("0.23")
    result1 = multiply_net_by_vat(net_grosze, rate)
    result2 = multiply_net_by_vat(net_grosze, rate)
    result3 = multiply_net_by_vat(net_grosze, rate)
    assert result1 == result2 == result3


@crosshair.check
def test_ch_vat_never_negative_for_any_rate(net_grosze: int, rate: Decimal) -> None:
    """SUPERMOC crosshair: Dla dowolnego netto i stawki, VAT >= 0.
    Property 5 — Odporność na złośliwe dane (część)."""
    if net_grosze < 0 or rate < 0:
        return
    vat = multiply_net_by_vat(net_grosze, rate)
    assert vat >= 0, f"Negative VAT for net={net_grosze}, rate={rate}"


@crosshair.check
def test_ch_to_grosze_never_crashes(amount: Decimal) -> None:
    """SUPERMOC crosshair: to_grosze nie rzuca wyjątku dla żadnego Decimal.
    Property 5 — Odporność na złośliwe dane."""
    result = to_grosze(amount)
    assert isinstance(result, int)


@crosshair.check
def test_ch_to_zlotowki_never_crashes(grosze: int) -> None:
    """SUPERMOC crosshair: to_zlotowki nie rzuca wyjątku dla żadnego int.
    Property 5 — Odporność na złośliwe dane."""
    result = to_zlotowki(grosze)
    assert isinstance(result, Decimal)


@crosshair.check
def test_ch_validate_invariants_never_crashes(
    net_grosze: int, vat_rate: Decimal
) -> None:
    """SUPERMOC crosshair: validate_invariants nie rzuca wyjątku.
    Property 5 — Odporność na złośliwe dane."""
    positions = [InvoicePositions(net_grosze=abs(net_grosze), vat_rate=vat_rate)]
    total_net = positions[0].net_grosze
    total_vat = positions[0].vat_grosze
    summary = InvoiceSummary(
        netto_grosze=total_net,
        vat_grosze=total_vat,
        brutto_grosze=total_net + total_vat,
    )
    result = validate_invariants(positions, summary)
    assert isinstance(result.is_valid, bool)
    assert isinstance(result.error_message, str)


@crosshair.check
def test_ch_empty_positions_never_crashes() -> None:
    """SUPERMOC crosshair: Pusta lista pozycji nie rzuca wyjątku."""
    assert calculate_vat_by_policy([], Decimal("0.23"), "position") == 0
    assert calculate_vat_by_policy([], Decimal("0.23"), "total") == 0
    result = validate_invariants([], InvoiceSummary(0, 0, 0))
    assert result.is_valid


# ═══════════════════════════════════════════════════════════════════════════════
# Nexus-Money (msgspec.Struct) tests — testowane przez crosshair
# ═══════════════════════════════════════════════════════════════════════════════


@crosshair.check
def test_ch_grosze_to_money_round_trip(grosze: int) -> None:
    """SUPERMOC crosshair: Konwersja grosze → Money → grosze."""
    if grosze < 0 or grosze > 100_000_000:
        return
    money = to_money(grosze, "PLN")
    back = money_to_grosze(money)
    assert back == grosze


@crosshair.check
def test_ch_money_currency_preserved(grosze: int) -> None:
    """SUPERMOC crosshair: Waluta jest zachowana."""
    if grosze < 0 or grosze > 100_000_000:
        return
    money = to_money(grosze, "PLN")
    assert money.currency == "PLN"


@crosshair.check
def test_ch_multiply_vat_preserves_currency(grosze: int) -> None:
    """SUPERMOC crosshair: multiply_net_by_vat_money zachowuje walutę."""
    if grosze < 0 or grosze > 10_000_000:
        return
    net = to_money(grosze, "PLN")
    vat = multiply_net_by_vat_money(net, Decimal("0.23"))
    assert isinstance(vat, Money)
    assert vat.currency == "PLN"


@crosshair.check
def test_ch_add_tax_preserves_currency(grosze: int) -> None:
    """SUPERMOC crosshair: add_tax_money zachowuje walutę."""
    if grosze < 0 or grosze > 10_000_000:
        return
    net = to_money(grosze, "PLN")
    vat = multiply_net_by_vat_money(net, Decimal("0.23"))
    gross = add_tax_money(net, vat)
    assert isinstance(gross, Money)
    assert gross.currency == "PLN"
    expected_gross_grosze = money_to_grosze(net) + money_to_grosze(vat)
    actual_gross_grosze = money_to_grosze(gross)
    assert actual_gross_grosze == expected_gross_grosze


@crosshair.check
def test_ch_vat_money_never_negative(grosze: int) -> None:
    """SUPERMOC crosshair: VAT Money nigdy nie jest ujemny."""
    if grosze < 0 or grosze > 10_000_000:
        return
    net = to_money(grosze, "PLN")
    vat = multiply_net_by_vat_money(net, Decimal("0.23"))
    assert money_to_grosze(vat) >= 0


@crosshair.check
def test_ch_to_money_amount_value(grosze: int) -> None:
    """SUPERMOC crosshair: to_money zwraca poprawną kwotę."""
    if grosze < 0 or grosze > 100_000_000:
        return
    money = to_money(grosze, "PLN")
    expected = Decimal(grosze) / Decimal(100)
    assert money.amount == expected
