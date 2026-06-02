"""
Tax Math Engine — Infallible integer-only arithmetic.

Część II matematycznego stosu nieomylności.

Zasady:
  - Całkowity zakaz float — wszystkie kwoty w groszach (int).
  - Globalnie ROUND_HALF_UP, precyzja 28 miejsc.
  - Każde zaokrąglenie jawne — nigdy ukryte.
  - Trzy niezmienniki przed zapisem do księgi.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

# ── Global rounding context ─────────────────────────────────────────────────
# Nigdy nie zmieniaj lokalnie — zawsze ROUND_HALF_UP, 2 miejsca po przecinku

_GROSZ = Decimal("0.01")


# ── Exceptions ──────────────────────────────────────────────────────────────


class InvalidRateError(ValueError):
    """Raised when a rate string cannot be parsed as a valid Decimal.

    This enforces the Rozdział Ról principle: all numeric values from
    the rule engine must be valid strings, never floats.
    """

    def __init__(self, rate_str: str) -> None:
        super().__init__(
            f"Invalid rate value: {rate_str!r}. "
            f"Rates must be valid decimal strings (e.g. '0.23')."
        )
        self.rate_str = rate_str


# ── Data structures ──────────────────────────────────────────────────────────


@dataclass(frozen=True)
class InvoicePositions:
    """A single invoice line item in grosze.

    Attributes:
        net_grosze: Net amount in grosze (integer).
        vat_rate: VAT rate as Decimal (e.g. Decimal(\"0.23\")).
    """

    net_grosze: int
    vat_rate: Decimal

    @property
    def vat_grosze(self) -> int:
        """VAT for this line, rounded to full grosze."""
        return multiply_net_by_vat(self.net_grosze, self.vat_rate)


@dataclass(frozen=True)
class InvoiceSummary:
    """Invoice totals in grosze.

    All three fields are integers (grosze) — never floats.
    """

    netto_grosze: int
    vat_grosze: int
    brutto_grosze: int


@dataclass(frozen=True)
class ValidationResult:
    """Result of invariant validation.

    Attributes:
        is_valid: True if all invariants pass.
        error_message: Human-readable description on failure.
    """

    is_valid: bool
    error_message: str = ""


# ── Rate parsing (Rozdział Ról: Zen-Engine → Decimal) ──────────────────────


def parse_rate(rate_str: str) -> Decimal:
    """Parse a rate string to Decimal with validation.

    This is the ONLY entry point for converting rule engine verdict
    values (strings) to Decimal for arithmetic. Never use ``float()``
    on rate values — JSON numbers would lose precision.

    Args:
        rate_str: Rate as string (e.g. ``"0.23"``, ``"0.08"``).

    Returns:
        Decimal value for use in arithmetic.

    Raises:
        InvalidRateError: If the string is not a valid decimal number.

    Example:
        >>> parse_rate("0.23")
        Decimal('0.23')
        >>> parse_rate("0.23.5")  # doctest: +IGNORE_EXCEPTION_DETAIL
        Traceback (most recent call last):
        ...
        InvalidRateError
    """
    if not isinstance(rate_str, str):
        raise InvalidRateError(str(rate_str))
    try:
        return Decimal(rate_str)
    except Exception as exc:
        raise InvalidRateError(rate_str) from exc


# ── Core math functions ──────────────────────────────────────────────────────


def to_grosze(amount: Decimal | str | float | int) -> int:
    """Convert any numeric representation to grosze (int) with ROUND_HALF_UP.

    Args:
        amount: Amount in złotówki (Decimal, str, float, or int).

    Returns:
        Amount in grosze, always rounded to nearest integer.

    Raises:
        TypeError: If amount type is not supported.
    """
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


def to_zlotowki(grosze: int) -> Decimal:
    """Convert grosze back to Decimal (złotówki) for display.

    Args:
        grosze: Amount in grosze.

    Returns:
        Decimal amount in złotówki with 2 decimal places.
    """
    return (Decimal(grosze) / Decimal("100")).quantize(
        _GROSZ, rounding=ROUND_HALF_UP
    )


def multiply_net_by_vat(net_grosze: int, vat_rate: Decimal) -> int:
    """Multiply net amount (grosze) by VAT rate, rounded to full grosze.

    This is the ONLY place where VAT multiplication happens.
    Never reimplement this logic elsewhere.

    Args:
        net_grosze: Net amount in grosze.
        vat_rate: VAT rate (e.g. Decimal(\"0.23\")).

    Returns:
        VAT amount in grosze, rounded to nearest integer.
    """
    # Convert int to Decimal for precise multiplication
    vat_decimal = Decimal(str(net_grosze)) * vat_rate
    return int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))


def add_tax(net_grosze: int, vat_grosze: int) -> int:
    """Sum net and VAT in grosze to get brutto.

    Args:
        net_grosze: Net amount in grosze.
        vat_grosze: VAT amount in grosze.

    Returns:
        Gross (brutto) amount in grosze.
    """
    return net_grosze + vat_grosze


# ── Rounding Policy ──────────────────────────────────────────────────────────


def calculate_vat_by_policy(
    positions: list[InvoicePositions],
    vat_rate: Decimal,
    rounding_level: str,
) -> int:
    """Calculate total VAT according to the chosen rounding strategy.

    ``position`` — round per line, then sum (precise per-item VAT).
    ``total``    — sum net first, then round once (matches total-invoice math).

    Args:
        positions: List of invoice line items (net in grosze).
        vat_rate: VAT rate to apply.
        rounding_level: Must be ``\"position\"`` or ``\"total\"``.

    Returns:
        Total VAT amount in grosze.
    """
    if rounding_level == "position":
        total_vat = 0
        for pos in positions:
            total_vat += multiply_net_by_vat(pos.net_grosze, vat_rate)
        return total_vat

    if rounding_level == "total":
        total_net = sum(pos.net_grosze for pos in positions)
        return multiply_net_by_vat(total_net, vat_rate)

    raise ValueError(
        f"Unknown rounding_level: {rounding_level!r}; "
        f"expected 'position' or 'total'"
    )


class RoundingPolicy:
    """Convenience wrapper around rounding strategy constants and logic."""

    POSITION = "position"
    TOTAL = "total"

    @staticmethod
    def calculate(
        positions: list[InvoicePositions],
        vat_rate: Decimal,
        rounding_level: str,
    ) -> int:
        """Delegate to :func:`calculate_vat_by_policy`."""
        return calculate_vat_by_policy(positions, vat_rate, rounding_level)


# ── Invariant Guard ──────────────────────────────────────────────────────────


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


# ── Convenience Engine ───────────────────────────────────────────────────────


class TaxMathEngine:
    """Infallible tax math — integer-only, ROUND_HALF_UP, no floats.

    All methods are static. Use as a namespace for clarity.
    """

    to_grosze = staticmethod(to_grosze)
    to_zlotowki = staticmethod(to_zlotowki)
    multiply_net_by_vat = staticmethod(multiply_net_by_vat)
    add_tax = staticmethod(add_tax)
    parse_rate = staticmethod(parse_rate)
    validate_invariants = staticmethod(validate_invariants)

    @staticmethod
    def calculate_positions_vat(
        positions_net: list[int],
        vat_rate: Decimal,
        rounding_level: str,
    ) -> tuple[int, list[InvoicePositions]]:
        """Calculate total VAT and return position data for auditing.

        Args:
            positions_net: List of net amounts in grosze.
            vat_rate: VAT rate as Decimal.
            rounding_level: ``\"position\"`` or ``\"total\"``.

        Returns:
            Tuple of ``(total_vat_grosze, list[InvoicePositions])``.
        """
        inv_positions = [
            InvoicePositions(net_grosze=int(net), vat_rate=vat_rate)
            for net in positions_net
        ]
        total_vat = calculate_vat_by_policy(inv_positions, vat_rate, rounding_level)
        return total_vat, inv_positions
