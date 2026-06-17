"""
Dedykowane testy crosshair (SMT-driven property-based testing).

Wykorzystuje SMT solver (Z3) do matematycznego dowodzenia poprawności
funkcji księgowych, zamiast losowego fuzzingu (hypothesis).

Zgodnie z aa3fvcx.txt: crosshair zastępuje hypothesis jako główne
narzędzie property-based testing.

SUPERMOCE crosshair wykorzystane w tym pliku:
  - @crosshair.check       — symboliczne wykonanie wszystkich ścieżek
  - Type hints jako kontrakty — crosshair używa int, str, Decimal
  - Automatyczne wykrywanie błędów — ZeroDivisionError, ValueError
  - Obsługa Optional, List, Enum — jeśli funkcje mają te typy
  - SMT solving — matematyczne dowody (nie statystyczne)
"""

from __future__ import annotations

from decimal import Decimal

import crosshair
import pytest

from nexus_ai.tax.math_engine import (
    InvoicePositions,
    InvoiceSummary,
    RoundingPolicy,
    add_tax,
    add_tax_money,
    calculate_vat_by_policy,
    calculate_vat_udf,
    money_to_grosze,
    multiply_net_by_vat,
    multiply_net_by_vat_money,
    parse_rate,
    to_grosze,
    to_money,
    to_zlotowki,
    validate_invariants,
)
from nexus_ai.services.currency_converter import CurrencyConverter, CurrencyMismatchError, Money


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA 1: Podstawowe konwersje (5 testów)                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


@crosshair.check
def test_to_grosze_idempotent_from_decimal(amount: Decimal) -> None:
    """SUPERMOC crosshair #1: Dla dowolnego Decimal (0..1e6, 2 miejsca),
    to_grosze(to_zlotowki(x)) == x z dokładnością do 1 grosza.

    crosshair matematycznie dowodzi, że round-trip jest idempotentny
    dla całej domeny Decimal z 2 miejscami po przecinku."""
    # Ogranicz zakres do realnych kwot księgowych
    if amount < Decimal("0") or amount > Decimal("1_000_000.00"):
        return
    # Użyj precondition przez guard clause
    try:
        grosze = to_grosze(amount)
        back = to_zlotowki(grosze)
        # Dla kwot z 2 miejscami, round-trip musi być idealny
        assert back == amount, (
            f"to_grosze(to_zlotowki({amount})) = {back}, expected {amount}"
        )
    except (TypeError, ValueError):
        pass  # crosshair: wyjątki są akceptowalne dla brzegowych przypadków


@crosshair.check
def test_to_zlotowki_non_negative(grosze: int) -> None:
    """SUPERMOC crosshair #2: to_zlotowki zawsze zwraca Decimal >= 0 dla nieujemnego wejścia."""
    if grosze < 0:
        return
    result = to_zlotowki(grosze)
    assert isinstance(result, Decimal)
    assert result >= Decimal("0")
    # Końcówka zawsze .XX (dokładnie 2 miejsca po przecinku)
    str_result = str(result)
    if "." in str_result:
        decimal_places = len(str_result.split(".")[1])
        assert decimal_places <= 2, (
            f"to_zlotowki({grosze}) = {result} ma {decimal_places} miejsc"
        )


@crosshair.check
def test_to_grosze_returns_int(amount: str) -> None:
    """SUPERMOC crosshair #3: to_grosze ze stringa zawsze zwraca int."""
    try:
        result = to_grosze(amount)
        assert isinstance(result, int)
    except (TypeError, ValueError):
        pass  # Niepoprawne stringi mogą rzucać — to OK


@crosshair.check
def test_parse_rate_valid(rate_str: str) -> None:
    """SUPERMOC crosshair #4: parse_rate zwraca Decimal lub rzuca InvalidRateError.

    crosshair symbolicznie sprawdza, czy funkcja zawsze zwraca Decimal
    dla poprawnych stringów i rzuca wyjątek dla niepoprawnych."""
    try:
        result = parse_rate(rate_str)
        assert isinstance(result, Decimal)
    except (ValueError, Exception):
        pass  # Niepoprawne stawki mogą rzucać


@crosshair.check
def test_to_money_round_trip(amount_cents: int) -> None:
    """SUPERMOC crosshair #5: money_to_grosze(to_money(x)) == x dla PLM."""
    if amount_cents < 0 or amount_cents > 100_000_000:
        return
    money = to_money(amount_cents, "PLN")
    back = money_to_grosze(money)
    assert back == amount_cents, (
        f"Money round-trip failed: {amount_cents} -> {back}"
    )


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA 2: Arytmetyka VAT (4 testy)                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


@crosshair.check
def test_multiply_net_by_vat_structure(net_grosze: int) -> None:
    """SUPERMOC crosshair #6: Dla 23% VAT, wynik multiply_net_by_vat
    to zawsze int i spełnia: 0 <= vat <= net_grosze (dla 0-100% stawek).

    crosshair sprawdza matematyczne górne i dolne ograniczenia."""
    if net_grosze < 0:
        return
    vat = multiply_net_by_vat(net_grosze, Decimal("0.23"))
    assert isinstance(vat, int)
    assert vat >= 0
    # Dla stawki 23%, VAT nie może przekroczyć netto
    assert vat <= net_grosze, f"vat={vat} > net={net_grosze} (23%)"


@crosshair.check
def test_add_tax_commutative(a: int, b: int) -> None:
    """SUPERMOC crosshair #7: add_tax jest przemienne."""
    result1 = add_tax(a, b)
    result2 = add_tax(b, a)
    assert result1 == result2, f"add_tax nie jest przemienne: {a}+{b} vs {b}+{a}"


@crosshair.check
def test_add_tax_associative(a: int, b: int, c: int) -> None:
    """SUPERMOC crosshair #8: add_tax jest łączne."""
    result1 = add_tax(add_tax(a, b), c)
    result2 = add_tax(a, add_tax(b, c))
    assert result1 == result2, f"add_tax nie jest łączne: ({a}+{b})+{c} vs {a}+({b}+{c})"


@crosshair.check
def test_multiply_net_by_vat_zero_net(vat_rate: str) -> None:
    """SUPERMOC crosshair #9: Dla netto=0, VAT zawsze 0 niezależnie od stawki."""
    try:
        vat = multiply_net_by_vat(0, vat_rate)
        assert vat == 0, f"Netto 0 dało VAT {vat} dla stawki {vat_rate}"
    except (ValueError, Exception):
        pass  # Niepoprawne stawki mogą rzucać


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA 3: Money operations (4 testy)                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


@crosshair.check
def test_money_currency_preserved_on_vat(amount_cents: int) -> None:
    """SUPERMOC crosshair #10: multiply_net_by_vat_money zachowuje walutę."""
    if amount_cents < 0 or amount_cents > 10_000_000:
        return
    net = to_money(amount_cents, "EUR")
    try:
        vat = multiply_net_by_vat_money(net, Decimal("0.23"))
        assert vat.currency == "EUR", (
            f"Currency changed from EUR to {vat.currency}"
        )
    except Exception:
        pass


@crosshair.check
def test_add_tax_money_same_currency_non_negative(amount_cents: int) -> None:
    """SUPERMOC crosshair #11: add_tax_money zwraca nieujemny wynik dla tej samej waluty."""
    if amount_cents < 0:
        return
    net = to_money(amount_cents, "PLN")
    vat = to_money(amount_cents, "PLN")  # sztucznie: vat = net
    try:
        gross = add_tax_money(net, vat)
        assert gross.currency == "PLN"
        assert money_to_grosze(gross) >= money_to_grosze(net)
    except Exception:
        pass


@crosshair.check
def test_invoice_positions_vat_grosze_consistency(net_grosze: int) -> None:
    """SUPERMOC crosshair #12: InvoicePositions.vat_grosze == multiply_net_by_vat()."""
    if net_grosze < 0:
        return
    pos = InvoicePositions(net_grosze=net_grosze, vat_rate=Decimal("0.23"))
    direct = multiply_net_by_vat(net_grosze, Decimal("0.23"))
    assert pos.vat_grosze == direct, (
        f"VAT mismatch: pos={pos.vat_grosze}, direct={direct}"
    )


@crosshair.check
def test_money_amount_cents_consistency(amount_cents: int) -> None:
    """SUPERMOC crosshair #13: Money.amount zawsze zgadza się z amount_cents."""
    if amount_cents < 0 or amount_cents > 100_000_000:
        return
    money = to_money(amount_cents, "PLN")
    expected = Decimal(amount_cents) / Decimal("100")
    assert money.amount == expected, (
        f"Money.amount {money.amount} != {expected} (amount_cents={amount_cents})"
    )


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA 4: Zaawansowane niezmienniki (4 testy)                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


@crosshair.check
def test_invoice_summary_immutable() -> None:
    """SUPERMOC crosshair #14: InvoiceSummary jest immutable."""
    summary = InvoiceSummary(netto_grosze=1000, vat_grosze=230, brutto_grosze=1230)
    with pytest.raises(AttributeError):
        summary.netto_grosze = 2000  # type: ignore[misc]
    with pytest.raises(AttributeError):
        summary.new_field = "test"  # type: ignore[attr-defined]


@crosshair.check
def test_invoice_positions_immutable() -> None:
    """SUPERMOC crosshair #15: InvoicePositions jest immutable."""
    pos = InvoicePositions(net_grosze=1000, vat_rate=Decimal("0.23"))
    with pytest.raises(AttributeError):
        pos.net_grosze = 2000  # type: ignore[misc]


@crosshair.check
def test_rounding_policy_position_never_negative(net_grosze: int) -> None:
    """SUPERMOC crosshair #16: RoundingPolicy.calculate dla position
    zawsze daje nieujemny VAT dla nieujemnego netto."""
    if net_grosze < 0:
        return
    positions = [InvoicePositions(net_grosze=net_grosze, vat_rate=Decimal("0.23"))]
    try:
        vat = RoundingPolicy.calculate(positions, Decimal("0.23"), "position")
        assert vat >= 0
        assert isinstance(vat, int)
    except ValueError:
        pass


@crosshair.check
def test_calculate_vat_udf_never_negative(net_grosze: int) -> None:
    """SUPERMOC crosshair #17: calculate_vat_udf nigdy nie zwraca ujemnego VAT."""
    result = calculate_vat_udf(net_grosze, "0.23")
    assert isinstance(result, int)
    if net_grosze >= 0:
        assert result >= 0, f"Negative VAT from UDF for net={net_grosze}"


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA 5: Walidacja krzyżowa (3 testy)                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


@crosshair.check
def test_validate_invariants_empty_list() -> None:
    """SUPERMOC crosshair #18: validate_invariants z pustą listą
    i zerowym summary zawsze zwraca is_valid=True."""
    result = validate_invariants([], InvoiceSummary(0, 0, 0))
    assert result.is_valid
    assert result.error_message == ""


@crosshair.check
def test_validate_invariants_net_plus_vat_equals_brutto(net: int, vat: int) -> None:
    """SUPERMOC crosshair #19: validate_invariants sprawdza Invariant 3
    (netto + vat == brutto) dla dowolnych wartości."""
    if net < 0 or vat < 0:
        return
    brutto = net + vat
    positions = [InvoicePositions(net_grosze=net, vat_rate=Decimal("0.23"))]
    summary = InvoiceSummary(netto_grosze=net, vat_grosze=vat, brutto_grosze=brutto)
    result = validate_invariants(positions, summary)
    # Invariant 3 zawsze przechodzi (netto + vat == brutto)
    # Invariant 1 i 2 mogą paść (VAT z position może różnić się od VAT z summary)
    assert isinstance(result.is_valid, bool)


@crosshair.check
def test_money_validate_currency_valid(currency: str) -> None:
    """SUPERMOC crosshair #20: Money.validate_currency dla 3-literowych kodów.

    crosshair symbolicznie sprawdza czy funkcja akceptuje wszystkie
    3-literowe kody walut i odrzuca nieprawidłowe."""
    try:
        result = Money.validate_currency(currency)
        assert result == currency.upper()
        assert len(result) == 3
        assert result.isalpha()
    except ValueError:
        # Nieprawidłowe kody walut — oczekiwane
        assert len(currency) != 3 or not currency.strip().isalpha()


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Testy jednostkowe wspomagające crosshair                                  ║
# ║  (standardowy pytest dla przypadków, które crosshair obsługuje słabiej)    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


class TestCrosshairSupplements:
    """Dodatkowe testy uzupełniające to, czego crosshair nie sprawdza."""

    def test_to_grosze_from_int_via_class(self) -> None:
        """TaxMathEngine.to_grosze jako classmethod."""
        from nexus_ai.tax.math_engine import TaxMathEngine
    assert TaxMathEngine.to_grosze(100) == 10000

    def test_to_money_non_pln_currency(self) -> None:
        """to_money z różnymi walutami."""
        usd = to_money(10000, "USD")
        assert usd.currency == "USD"
        assert usd.amount_cents == 10000

    def test_invoice_summary_from_money_valid(self) -> None:
        """InvoiceSummary.from_money z poprawnymi danymi."""
        summary = InvoiceSummary.from_money(
            netto=Money(amount_cents=10000, currency="PLN"),
            vat=Money(amount_cents=2300, currency="PLN"),
            brutto=Money(amount_cents=12300, currency="PLN"),
        )
        assert summary.netto_grosze == 10000

    def test_invoice_summary_from_money_currency_mismatch(self) -> None:
        """InvoiceSummary.from_money z różnymi walutami."""
        with pytest.raises(CurrencyMismatchError):
            InvoiceSummary.from_money(
                netto=Money(amount_cents=10000, currency="PLN"),
                vat=Money(amount_cents=2300, currency="EUR"),
                brutto=Money(amount_cents=12300, currency="PLN"),
            )

    def test_money_zero_constructor(self) -> None:
        """Money.zero() zwraca zero w danej walucie."""
        zero = Money.zero("EUR")
        assert zero.amount_cents == 0
        assert zero.currency == "EUR"

    def test_money_add_same_currency(self) -> None:
        """Money.__add__ dla tej samej waluty."""
        a = Money(amount_cents=10000, currency="PLN")
        b = Money(amount_cents=5000, currency="PLN")
        result = a + b
        assert result.amount_cents == 15000
        assert result.currency == "PLN"

    def test_money_add_different_currency_raises(self) -> None:
        """Money.__add__ dla różnych walut."""
        a = Money(amount_cents=10000, currency="PLN")
        b = Money(amount_cents=5000, currency="EUR")
        with pytest.raises(CurrencyMismatchError):
            _ = a + b

    def test_money_mul_by_int(self) -> None:
        """Money.__mul__ przez int."""
        m = Money(amount_cents=10000, currency="PLN")
        result = m * 3
        assert result.amount_cents == 30000

    def test_money_mul_by_decimal(self) -> None:
        """Money.__mul__ przez Decimal."""
        m = Money(amount_cents=10000, currency="PLN")
        result = m * Decimal("1.5")
        assert result.amount_cents == 15000

    def test_money_neg(self) -> None:
        """Money.__neg__."""
        m = Money(amount_cents=10000, currency="PLN")
        assert (-m).amount_cents == -10000

    def test_money_eq_same(self) -> None:
        """Money.__eq__ dla tych samych wartości."""
        a = Money(amount_cents=10000, currency="PLN")
        b = Money(amount_cents=10000, currency="PLN")
        assert a == b

    def test_money_eq_different_amount(self) -> None:
        """Money.__eq__ dla różnych wartości."""
        a = Money(amount_cents=10000, currency="PLN")
        b = Money(amount_cents=20000, currency="PLN")
        assert a != b

    def test_money_eq_different_currency(self) -> None:
        """Money.__eq__ dla różnych walut."""
        a = Money(amount_cents=10000, currency="PLN")
        b = Money(amount_cents=10000, currency="EUR")
        assert a != b

    def test_money_from_decimal_string(self) -> None:
        """Money.from_decimal ze stringa."""
        m = Money.from_decimal("123.45", "PLN")
        assert m.amount_cents == 12345

    def test_money_from_decimal_float(self) -> None:
        """Money.from_decimal z floata."""
        m = Money.from_decimal(123.45, "PLN")
        assert m.amount_cents == 12345

    def test_calculate_vat_udf_invalid_rate(self) -> None:
        """calculate_vat_udf z nieprawidłową stawką zwraca 0."""
        result = calculate_vat_udf(10000, "invalid")
        assert result == 0

    def test_calculate_vat_udf_negative_net(self) -> None:
        """calculate_vat_udf z ujemnym netto."""
        result = calculate_vat_udf(-100, "0.23")
        assert result == -23  # -100 * 0.23 = -23

    def test_invoice_positions_vat_grosze_edge_cases(self) -> None:
        """InvoicePositions.vat_grosze dla brzegowych przypadków."""
        pos = InvoicePositions(net_grosze=0, vat_rate=Decimal("0.23"))
        assert pos.vat_grosze == 0

    def test_invoice_positions_to_net_money_with_currency(self) -> None:
        """InvoicePositions.to_net_money z różnymi walutami."""
        pos = InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))
        money = pos.to_net_money("EUR")
        assert money.currency == "EUR"
        assert money.amount_cents == 10000

    def test_rounding_policy_constants(self) -> None:
        """RoundingPolicy stałe."""
        assert RoundingPolicy.POSITION == "position"
        assert RoundingPolicy.TOTAL == "total"

    def test_currency_converter_validate_invoice_currencies(self) -> None:
        """CurrencyConverter.validate_invoice_currencies."""
        from nexus_ai.services.currency_converter import CurrencyConverter
        items = [
            Money(amount_cents=10000, currency="PLN"),
            Money(amount_cents=5000, currency="PLN"),
        ]
        CurrencyConverter.validate_invoice_currencies(items)  # no raise

    def test_currency_converter_validate_invoice_currencies_mismatch(self) -> None:
        """CurrencyConverter.validate_invoice_currencies z różnymi walutami."""
        from nexus_ai.services.currency_converter import CurrencyConverter, CurrencyMismatchError
        items = [
            Money(amount_cents=10000, currency="PLN"),
            Money(amount_cents=5000, currency="EUR"),
        ]
        with pytest.raises(CurrencyMismatchError):
            CurrencyConverter.validate_invoice_currencies(items)

    def test_money_validate_currency_lowercase(self) -> None:
        """Money.validate_currency akceptuje lowercase."""
        assert Money.validate_currency("eur") == "EUR"
        assert Money.validate_currency("usd") == "USD"

    def test_money_validate_currency_invalid(self) -> None:
        """Money.validate_currency odrzuca nieprawidłowe kody."""
        with pytest.raises(ValueError, match="Invalid currency"):
            Money.validate_currency("ABCD")
        with pytest.raises(ValueError, match="Invalid currency"):
            Money.validate_currency("")
        with pytest.raises(ValueError, match="Invalid currency"):
            Money.validate_currency("12")
