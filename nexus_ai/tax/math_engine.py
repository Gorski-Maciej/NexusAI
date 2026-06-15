"""
Tax Math Engine — Rust-powered integer-only arithmetic + Fowler's Money bridge.

Zintegrowany z DecisionEngine (DuckDB/SQL) — integer-only math,
zgodny z Nexus-Money (msgspec.Struct) i aa3fvcx.txt (Punkt 9).

Architektura:
  - Core math (to_grosze, multiply_net_by_vat, validate_invariants):
    Rust + PyO3 (rust_decimal) gdy native moduł dostępny,
    fallback do Python Decimal gdy nie.
  - Money-aware API (money_to_grosze, to_money, itp.):
    Python — pracuje z Pythonowym Money (msgspec.Struct z currency_converter).

Rust replacement: nexus_ai/rust/src/tax.rs (TaxMathEngine)
Kompatybilne API: wszystkie funkcje mają te same sygnatury co oryginał.

Zasady:  - Całkowity zakaz float — wszystkie kwoty w groszach (int).
  - Globalnie ROUND_HALF_UP, precyzja 28 miejsc.
  - Każde zaokrąglenie jawne — nigdy ukryte.
  - Trzy niezmienniki przed zapisem do księgi.
"""

from __future__ import annotations

import logging
from decimal import ROUND_HALF_UP, Decimal
from typing import TYPE_CHECKING, Any, final

from nexus_ai.services.currency_converter import (
    CurrencyMismatchError as _CurrencyMismatchError,
    Money as _Money,
)

logger = logging.getLogger("nexus.tax.math_engine")

# ── Global rounding context ─────────────────────────────────────────────────

_GROSZ = Decimal("0.01")

# ── Nuitka compilation guard ── ─────────────────────────────────────────────
# __compiled__ is set by Nuitka when this module is compiled to C.
# Use it to skip import-time checks and enable aggressive optimizations.
# Standard Nuitka idiom: try/except NameError instead of __builtins__ inspection.
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

# ── Fallback flag ───────────────────────────────────────────────────────────

_HAS_NATIVE_RUST = False

# ── Try to load the native Rust TaxMathEngine ──────────────────────────────
# When compiled by Nuitka, skip the import-time logging (logger might not be ready yet).

try:
    from nexus_crypto._core import (
        TaxMathEngine as _RustTaxMathEngine,
        InvoicePositions as _RustInvoicePositions,
        InvoiceSummary as _RustInvoiceSummary,
        ValidationResult as _RustValidationResult,
        to_grosze as _rust_to_grosze,
        to_zlotowki as _rust_to_zlotowki,
        multiply_net_by_vat as _rust_multiply_net_by_vat,
        add_tax as _rust_add_tax,
        calculate_vat_by_policy as _rust_calculate_vat_by_policy,
        validate_invariants as _rust_validate_invariants,
    )
    _HAS_NATIVE_RUST = True
    if not _NUITKA_COMPILED:
        logger.info(
            "TaxMathEngine: Rust native extension loaded — using rust_decimal for core math"
        )
except (ImportError, OSError):
    if not _NUITKA_COMPILED:
        logger.info(
            "TaxMathEngine: Rust native not available — using pure Python Decimal fallback"
        )


# ── Exceptions ──────────────────────────────────────────────────────────────


class InvalidRateError(ValueError):
    """Raised when a rate string cannot be parsed as a valid Decimal.

    This enforces the Rozdział Ról principle: all numeric values from
    the rule engine must be valid strings, never floats.
    """

    def __init__(self, rate_str: str) -> None:
        super().__init__(
            f"Invalid rate value: {rate_str!r}. Rates must be valid decimal strings (e.g. '0.23')."
        )
        self.rate_str = rate_str


# ── Helper: parse rate (common to both Rust and Python paths) ──────────────


def _parse_rate_or_raise(rate_str: str) -> Decimal:
    """Parse a rate string, raising InvalidRateError on failure."""
    try:
        return Decimal(rate_str)
    except Exception as exc:
        raise InvalidRateError(rate_str) from exc


# ── Data structures ─────────────────────────────────────────────────────────


@final
class InvoicePositions:
    """A single invoice line item in grosze.

    Attributes:
        net_grosze: Net amount in grosze (integer).
        vat_rate: VAT rate as string (e.g. "0.23").
    """

    __slots__ = ("net_grosze", "vat_rate")

    def __init__(self, net_grosze: int, vat_rate: str | Decimal) -> None:
        # Accept both str and Decimal for backward compatibility
        object.__setattr__(self, "net_grosze", net_grosze)
        object.__setattr__(self, "vat_rate", vat_rate)

    def __setattr__(self, name: str, value: Any) -> None:
        raise AttributeError(f"InvoicePositions is immutable: cannot set {name}")

    def __delattr__(self, name: str) -> None:
        raise AttributeError(f"InvoicePositions is immutable: cannot delete {name}")

    @property
    def vat_grosze(self) -> int:
        """VAT for this line, rounded to full grosze."""
        rate = self.vat_rate if isinstance(self.vat_rate, str) else str(self.vat_rate)
        return multiply_net_by_vat(self.net_grosze, rate)

    @classmethod
    def from_money(cls, net: _Money, vat_rate: str | Decimal) -> InvoicePositions:
        """Create an InvoicePositions from a Money amount.

        Args:
            net: Net amount as Money (e.g. Money(amount_cents=10000, currency="PLN")).
            vat_rate: VAT rate as string or Decimal (e.g. "0.23" or Decimal("0.23")).

        Returns:
            InvoicePositions with net_grosze extracted from Money.

        Raises:
            TypeError: If net is not a Money instance.
        """
        if not isinstance(net, _Money):
            raise TypeError(f"Expected Money, got {type(net).__name__}")
        return cls(net_grosze=net.amount_cents, vat_rate=vat_rate)

    def to_net_money(self, currency: str = "PLN") -> _Money:
        """Return the net amount as Money."""
        return _Money(amount_cents=self.net_grosze, currency=currency)

    def to_vat_money(self, currency: str = "PLN") -> _Money:
        """Return the VAT amount as Money."""
        return _Money(amount_cents=self.vat_grosze, currency=currency)

    def __repr__(self) -> str:
        return f"InvoicePositions(net_grosze={self.net_grosze}, vat_rate={self.vat_rate!r})"


@final
class InvoiceSummary:
    """Invoice totals in grosze.

    All three fields are integers (grosze) — never floats.
    """

    __slots__ = ("netto_grosze", "vat_grosze", "brutto_grosze")

    def __init__(self, netto_grosze: int, vat_grosze: int, brutto_grosze: int) -> None:
        object.__setattr__(self, "netto_grosze", netto_grosze)
        object.__setattr__(self, "vat_grosze", vat_grosze)
        object.__setattr__(self, "brutto_grosze", brutto_grosze)

    def __setattr__(self, name: str, value: Any) -> None:
        raise AttributeError(f"InvoiceSummary is immutable: cannot set {name}")

    def __delattr__(self, name: str) -> None:
        raise AttributeError(f"InvoiceSummary is immutable: cannot delete {name}")

    @classmethod
    def from_money(
        cls,
        netto: _Money,
        vat: _Money,
        brutto: _Money,
    ) -> InvoiceSummary:
        """Create an InvoiceSummary from Money amounts.

        Args:
            netto: Net amount as Money.
            vat: VAT amount as Money.
            brutto: Gross amount as Money.

        Raises:
            ValueError: If currencies differ between amounts.
        """
        if not all(isinstance(x, _Money) for x in (netto, vat, brutto)):
            raise TypeError("All amounts must be Money instances")
        _require_same_currency(netto, vat, "InvoiceSummary")
        _require_same_currency(netto, brutto, "InvoiceSummary")
        return cls(
            netto_grosze=netto.amount_cents,
            vat_grosze=vat.amount_cents,
            brutto_grosze=brutto.amount_cents,
        )

    def to_netto_money(self, currency: str = "PLN") -> _Money:
        """Return the netto as Money."""
        return _Money(amount_cents=self.netto_grosze, currency=currency)

    def to_vat_money(self, currency: str = "PLN") -> _Money:
        """Return the VAT as Money."""
        return _Money(amount_cents=self.vat_grosze, currency=currency)

    def to_brutto_money(self, currency: str = "PLN") -> _Money:
        """Return the brutto as Money."""
        return _Money(amount_cents=self.brutto_grosze, currency=currency)

    def __repr__(self) -> str:
        return (
            f"InvoiceSummary(netto_grosze={self.netto_grosze}, "
            f"vat_grosze={self.vat_grosze}, brutto_grosze={self.brutto_grosze})"
        )


@final
class ValidationResult:
    """Result of invariant validation.

    Attributes:
        is_valid: True if all invariants pass.
        error_message: Human-readable description on failure.
    """

    __slots__ = ("is_valid", "error_message")

    def __init__(self, is_valid: bool, error_message: str = "") -> None:
        self.is_valid = is_valid
        self.error_message = error_message

    def __repr__(self) -> str:
        if self.is_valid:
            return "ValidationResult(is_valid=True)"
        return f"ValidationResult(is_valid=False, error_message={self.error_message!r})"

    def __bool__(self) -> bool:
        return self.is_valid


# ── Rate parsing ────────────────────────────────────────────────────────────


def parse_rate(rate_str: str) -> Decimal:
    """Parse a rate string to Decimal with validation.

    This is the ONLY entry point for converting rule engine verdict
    values (strings) to Decimal for arithmetic.

    Args:
        rate_str: Rate as string (e.g. ``"0.23"``, ``"0.08"``).

    Returns:
        Decimal value for use in arithmetic.

    Raises:
        InvalidRateError: If the string is not a valid decimal number.
    """
    return _parse_rate_or_raise(rate_str)


# ── Core math functions ─────────────────────────────────────────────────────


def to_grosze(amount: Decimal | str | float | int) -> int:
    """Convert any numeric representation to grosze (int) with ROUND_HALF_UP."""
    if _HAS_NATIVE_RUST:
        if isinstance(amount, str):
            return _rust_to_grosze(amount)
        return _rust_to_grosze(str(amount))

    if isinstance(amount, Decimal):
        d = amount
    elif isinstance(amount, str):
        d = Decimal(amount)
    elif isinstance(amount, float):
        d = Decimal(str(amount))
    elif isinstance(amount, int):
        d = Decimal(str(amount))
    else:
        raise TypeError(
            f"Cannot convert {type(amount).__name__} to grosze; "
            f"expected Decimal, str, float, or int"
        )
    grosze = d * Decimal("100")
    return int(grosze.to_integral_value(rounding=ROUND_HALF_UP))


# ── SUPERMOC: DuckDB Python UDF dla kalkulacji VAT ──────────────────────────
# DuckDB pozwala na rejestrację funkcji Python jako UDF z typem "native".
# Dzięki temu kalkulacje VAT mogą być wykonywane bezpośrednio w SQL,
# bez przechodzenia przez FFI do Rusta.
#
# Zastosowanie:
#   conn.create_function("calculate_vat", calculate_vat_udf, ...)
#   conn.execute("SELECT calculate_vat(net_grosze, vat_rate) FROM ...")


def calculate_vat_udf(net_grosze: int, rate_str: str) -> int:
    """DuckDB Python UDF: Oblicz VAT w groszach.

    Ta funkcja może być zarejestrowana jako DuckDB UDF:
    ``conn.create_function("calculate_vat", calculate_vat_udf, ...)``

    Args:
        net_grosze: Kwota netto w groszach.
        rate_str: Stawka VAT jako string (np. "0.23").

    Returns:
        VAT w groszach (int).
    """
    try:
        rate = Decimal(rate_str)
        vat = Decimal(str(net_grosze)) * rate
        return int(vat.to_integral_value(rounding=ROUND_HALF_UP))
    except Exception:
        return 0


def register_vat_udfs(conn: Any) -> None:
    """Zarejestruj wszystkie Python UDF dla kalkulacji VAT w DuckDB.

    SUPERMOC DuckDB: ``create_function()`` rejestruje funkcję Python
    jako natywny UDF w DuckDB. Funkcja może być używana w SQL:
    ``SELECT calculate_vat(net_grosze, vat_rate) FROM invoices``

    Args:
        conn: DuckDB connection.
    """
    conn.create_function(
        "calculate_vat",
        calculate_vat_udf,
        [int, str],  # argument types
        int,  # return type
        type="native",
        side_effects=False,
        null_handling="strict",
    )

    # UDF dla zaokrąglania groszy (HALF_UP)
    def _round_half_up(value: int, precision: int = 1) -> int:
        """Zaokrąglij do najbliższej jednostki precision z HALF_UP."""
        d = Decimal(value) / Decimal(str(precision))
        return int(d.to_integral_value(rounding=ROUND_HALF_UP)) * precision

    conn.create_function(
        "round_half_up_grosze",
        _round_half_up,
        [int, int],
        int,
        type="native",
        side_effects=False,
    )


def to_zlotowki(grosze: int) -> Decimal:
    """Convert grosze back to Decimal (złotówki) for display."""
    if _HAS_NATIVE_RUST:
        # Rust returns string; convert back to Decimal for API compat
        return Decimal(_rust_to_zlotowki(grosze))
    return (Decimal(grosze) / Decimal("100")).quantize(_GROSZ, rounding=ROUND_HALF_UP)


def multiply_net_by_vat(net_grosze: int, vat_rate: Decimal | str) -> int:
    """Multiply net amount (grosze) by VAT rate, rounded to full grosze."""
    if _HAS_NATIVE_RUST:
        rate_str = str(vat_rate) if isinstance(vat_rate, Decimal) else vat_rate
        return _rust_multiply_net_by_vat(net_grosze, rate_str)

    rate = _parse_rate_or_raise(str(vat_rate))
    vat_decimal = Decimal(str(net_grosze)) * rate
    return int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))


def add_tax(net_grosze: int, vat_grosze: int) -> int:
    """Sum net and VAT in grosze to get brutto."""
    if _HAS_NATIVE_RUST:
        return _rust_add_tax(net_grosze, vat_grosze)
    return net_grosze + vat_grosze


# ── Money-aware functions ───────────────────────────────────────────────────


def money_to_grosze(money: _Money) -> int:
    """Convert a Money amount to grosze (int)."""
    return money.amount_cents


def to_money(grosze: int, currency: str = "PLN") -> _Money:
    """Convert grosze (int) to a Money amount."""
    return _Money(amount_cents=grosze, currency=currency)


def _require_same_currency(a: _Money, b: _Money, operation: str = "operate") -> None:
    """Validate that two Money objects have the same currency."""
    if a.currency_code != b.currency_code:
        raise _CurrencyMismatchError(a.currency_code, b.currency_code, operation)


def multiply_net_by_vat_money(net: _Money, vat_rate: Decimal | str) -> _Money:
    """Multiply net Money amount by VAT rate, return VAT as Money."""
    vat_grosze = multiply_net_by_vat(money_to_grosze(net), vat_rate)
    return to_money(vat_grosze, net.currency_code)


def add_tax_money(net: _Money, vat: _Money) -> _Money:
    """Add net and VAT as Money, return gross as Money."""
    _require_same_currency(net, vat, "add_tax_money")
    gross_grosze = add_tax(money_to_grosze(net), money_to_grosze(vat))
    return to_money(gross_grosze, net.currency_code)


# ── Rounding Policy ─────────────────────────────────────────────────────────


def calculate_vat_by_policy(
    positions: list[InvoicePositions],
    vat_rate: Decimal | str,
    rounding_level: str,
) -> int:
    """Calculate total VAT according to the chosen rounding strategy.

    ``position`` — round per line, then sum (precise per-item VAT).
    ``total``    — sum net first, then round once (matches total-invoice math).

    Args:
        positions: List of invoice line items (net in grosze).
        vat_rate: VAT rate.
        rounding_level: Must be ``"position"`` or ``"total"``.

    Returns:
        Total VAT amount in grosze.
    """
    if _HAS_NATIVE_RUST:
        rust_positions = [_RustInvoicePositions(p.net_grosze, str(p.vat_rate)) for p in positions]
        rate_str = str(vat_rate) if isinstance(vat_rate, Decimal) else vat_rate
        return _rust_calculate_vat_by_policy(rust_positions, rate_str, rounding_level)

    rate = _parse_rate_or_raise(str(vat_rate))
    if rounding_level == "position":
        total_vat = 0
        for pos in positions:
            total_vat += multiply_net_by_vat(pos.net_grosze, rate)
        return total_vat
    if rounding_level == "total":
        total_net = sum(pos.net_grosze for pos in positions)
        return multiply_net_by_vat(total_net, rate)
    raise ValueError(f"Unknown rounding_level: {rounding_level!r}; expected 'position' or 'total'")


def calculate_vat_by_policy_money(
    positions: list[InvoicePositions],
    vat_rate: Decimal | str,
    rounding_level: str,
    currency: str = "PLN",
) -> _Money:
    """Calculate total VAT as Money according to the chosen rounding strategy."""
    total_vat_grosze = calculate_vat_by_policy(positions, vat_rate, rounding_level)
    return to_money(total_vat_grosze, currency)


@final
class RoundingPolicy:
    """Convenience wrapper around rounding strategy constants and logic."""

    POSITION = "position"
    TOTAL = "total"

    @staticmethod
    def calculate(
        positions: list[InvoicePositions],
        vat_rate: Decimal | str,
        rounding_level: str,
    ) -> int:
        """Delegate to :func:`calculate_vat_by_policy`."""
        return calculate_vat_by_policy(positions, vat_rate, rounding_level)

    @staticmethod
    def calculate_money(
        positions: list[InvoicePositions],
        vat_rate: Decimal | str,
        rounding_level: str,
        currency: str = "PLN",
    ) -> _Money:
        """Calculate total VAT as Money."""
        return calculate_vat_by_policy_money(positions, vat_rate, rounding_level, currency)


# ── Invariant Guard ─────────────────────────────────────────────────────────


def validate_invariants(
    positions: list[InvoicePositions],
    summary: InvoiceSummary,
) -> ValidationResult:
    """Validate the three mathematical invariants of an invoice.

    **Invariant 1**: ``sum(positions.net_grosze) == summary.netto_grosze``
    **Invariant 2**: ``sum(positions.vat_grosze) == summary.vat_grosze``
    **Invariant 3**: ``netto_grosze + vat_grosze == brutto_grosze``

    Args:
        positions: List of invoice line items.
        summary: Invoice summary totals in grosze.

    Returns:
        :class:`ValidationResult` — ``is_valid=True`` iff all pass.
    """
    if _HAS_NATIVE_RUST:
        rust_positions = [
            _RustInvoicePositions(p.net_grosze, str(p.vat_rate)) for p in positions
        ]
        return _rust_validate_invariants(
            rust_positions,
            _RustInvoiceSummary(summary.netto_grosze, summary.vat_grosze, summary.brutto_grosze),
        )

    errors: list[str] = []

    # Invariant 1
    sum_net = sum(p.net_grosze for p in positions)
    if sum_net != summary.netto_grosze:
        diff = sum_net - summary.netto_grosze
        errors.append(
            f"Invariant 1: sum(position netto)={sum_net} gr "
            f"\u2260 summary netto={summary.netto_grosze} gr, "
            f"diff={diff:+d} gr"
        )

    # Invariant 2
    sum_vat = sum(multiply_net_by_vat(p.net_grosze, p.vat_rate) for p in positions)
    if sum_vat != summary.vat_grosze:
        diff = sum_vat - summary.vat_grosze
        errors.append(
            f"Invariant 2: sum(position VAT)={sum_vat} gr "
            f"\u2260 summary VAT={summary.vat_grosze} gr, "
            f"diff={diff:+d} gr"
        )

    # Invariant 3
    calculated_brutto = summary.netto_grosze + summary.vat_grosze
    if calculated_brutto != summary.brutto_grosze:
        diff = calculated_brutto - summary.brutto_grosze
        errors.append(
            f"Invariant 3: netto ({summary.netto_grosze} gr) + "
            f"VAT ({summary.vat_grosze} gr) = {calculated_brutto} gr "
            f"\u2260 brutto ({summary.brutto_grosze} gr), "
            f"diff={diff:+d} gr"
        )

    if errors:
        return ValidationResult(is_valid=False, error_message="; ".join(errors))
    return ValidationResult(is_valid=True)


# ── Convenience Engine ──────────────────────────────────────────────────────


@final
class TaxMathEngine:
    """Infallible tax math — integer-only, ROUND_HALF_UP, no floats.

    All methods are static. Use as a namespace for clarity.
    Powered by Rust + rust_decimal when native module is available.
    """

    # ── Grosze-based API (legacy, fully backward-compatible) ─────────────

    to_grosze = staticmethod(to_grosze)
    to_zlotowki = staticmethod(to_zlotowki)
    multiply_net_by_vat = staticmethod(multiply_net_by_vat)
    add_tax = staticmethod(add_tax)
    parse_rate = staticmethod(parse_rate)
    validate_invariants = staticmethod(validate_invariants)

    @staticmethod
    def calculate_positions_vat(
        positions_net: list[int],
        vat_rate: Decimal | str,
        rounding_level: str,
    ) -> tuple[int, list[InvoicePositions]]:
        """Calculate total VAT and return position data for auditing."""
        inv_positions = [
            InvoicePositions(net_grosze=int(net), vat_rate=str(vat_rate))
            for net in positions_net
        ]
        total_vat = calculate_vat_by_policy(inv_positions, vat_rate, rounding_level)
        return total_vat, inv_positions

    # ── Money-aware API ──────────────────────────────────────────────────

    money_to_grosze = staticmethod(money_to_grosze)
    to_money = staticmethod(to_money)
    multiply_net_by_vat_money = staticmethod(multiply_net_by_vat_money)
    add_tax_money = staticmethod(add_tax_money)

    @staticmethod
    def calculate_positions_vat_money(
        positions_net: list[_Money],
        vat_rate: Decimal | str,
        rounding_level: str,
    ) -> tuple[_Money, list[InvoicePositions]]:
        """Calculate total VAT from Money net amounts, return as Money."""
        if not positions_net:
            zero = _Money(0, "PLN")
            return zero, []

        for i, amt in enumerate(positions_net):
            if not isinstance(amt, _Money):
                raise TypeError(f"positions_net[{i}]: expected Money, got {type(amt).__name__}")
        for amt in positions_net[1:]:
            _require_same_currency(positions_net[0], amt, "calculate_positions_vat_money")

        currency = positions_net[0].currency_code
        grosze_list = [m.amount_cents for m in positions_net]
        total_vat_grosze, inv_positions = TaxMathEngine.calculate_positions_vat(
            grosze_list, vat_rate, rounding_level
        )
        total_vat_money = to_money(total_vat_grosze, currency)
        return total_vat_money, inv_positions

    @staticmethod
    def sum_positions_net_money(
        positions_net: list[_Money],
    ) -> _Money:
        """Sum a list of Money amounts (same currency)."""
        if not positions_net:
            return _Money(0, "PLN")

        for i, amt in enumerate(positions_net):
            if not isinstance(amt, _Money):
                raise TypeError(f"positions_net[{i}]: expected Money, got {type(amt).__name__}")
        for amt in positions_net[1:]:
            _require_same_currency(positions_net[0], amt, "sum_positions_net_money")

        currency = positions_net[0].currency_code
        total_grosze = sum(m.amount_cents for m in positions_net)
        return to_money(total_grosze, currency)
