"""
Tax Math Engine — Infallible integer-only arithmetic + Fowler's Money.

Zintegrowany z DecisionEngine (DuckDB/SQL) — integer-only math,
zgodny z Nexus-Money (msgspec.Struct) i aa3fvcx.txt (Punkt 9).

Zasady:    - Całkowity zakaz float — wszystkie kwoty w groszach (int).
  - Globalnie ROUND_HALF_UP, precyzja 28 miejsc.
  - Każde zaokrąglenie jawne — nigdy ukryte.
  - Trzy niezmienniki przed zapisem do księgi.
  - Nexus-Money (msgspec.Struct: amount_cents: int + currency: str) dla bezpieczeństwa walutowego.
    Zgodnie z aa3fvcx.txt (Punkt 9): Nexus-Money zastępuje py-moneyed.
"""

from __future__ import annotations

from msgspec import Struct
from decimal import ROUND_HALF_UP, Decimal
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from nexus_ai.services.currency_converter import Money as _Money

# ── Global rounding context ─────────────────────────────────────────────────
# Nigdy nie zmieniaj lokalnie — zawsze ROUND_HALF_UP, 2 miejsca po przecinku

_GROSZ = Decimal("0.01")

# ── Lazy import helpers ─────────────────────────────────────────────────────

def _get_money_class():
    """Lazy import of Money to avoid circular dependencies at module load."""
    from nexus_ai.services.currency_converter import Money
    return Money

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

class InvoicePositions(Struct, frozen=True):
    """A single invoice line item in grosze.

    Attributes:
        net_grosze: Net amount in grosze (integer).
        vat_rate: VAT rate as Decimal (e.g. Decimal("0.23")).
    """

    net_grosze: int
    vat_rate: Decimal

    @property
    def vat_grosze(self) -> int:
        """VAT for this line, rounded to full grosze."""
        return multiply_net_by_vat(self.net_grosze, self.vat_rate)

    # ── Money-aware constructors and properties ──────────────────────────

    @classmethod
    def from_money(cls, net: _Money, vat_rate: Decimal) -> InvoicePositions:
        """Create an InvoicePositions from a Money amount.

        Args:
            net: Net amount as Money (e.g. Money("100.00", "PLN")).
            vat_rate: VAT rate as Decimal.

        Returns:
            InvoicePositions with net_grosze extracted from Money.
        """
        from nexus_ai.services.currency_converter import Money
        if not isinstance(net, Money):
            raise TypeError(f"Expected Money, got {type(net).__name__}")
        return cls(net_grosze=money_to_grosze(net), vat_rate=vat_rate)

    def to_net_money(self, currency: str = "PLN") -> _Money:
        """Return the net amount as Money."""
        _get_money_class()
        return to_money(self.net_grosze, currency)

    def to_vat_money(self, currency: str = "PLN") -> _Money:
        """Return the VAT amount as Money."""
        _get_money_class()
        return to_money(self.vat_grosze, currency)

class InvoiceSummary(Struct, frozen=True):
    """Invoice totals in grosze.

    All three fields are integers (grosze) — never floats.
    """

    netto_grosze: int
    vat_grosze: int
    brutto_grosze: int

    # ── Money-aware constructors and properties ──────────────────────────

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

        Returns:
            InvoiceSummary with all amounts converted to grosze.

        Raises:
            ValueError: If currencies differ between amounts.
        """
        from nexus_ai.services.currency_converter import Money
        if not all(isinstance(x, Money) for x in (netto, vat, brutto)):
            raise TypeError("All amounts must be Money instances")
        _require_same_currency(netto, vat, "InvoiceSummary")
        _require_same_currency(netto, brutto, "InvoiceSummary")
        return cls(
            netto_grosze=money_to_grosze(netto),
            vat_grosze=money_to_grosze(vat),
            brutto_grosze=money_to_grosze(brutto),
        )

    def to_netto_money(self, currency: str = "PLN") -> _Money:
        """Return the netto as Money."""
        return to_money(self.netto_grosze, currency)

    def to_vat_money(self, currency: str = "PLN") -> _Money:
        """Return the VAT as Money."""
        return to_money(self.vat_grosze, currency)

    def to_brutto_money(self, currency: str = "PLN") -> _Money:
        """Return the brutto as Money."""
        return to_money(self.brutto_grosze, currency)

class ValidationResult(Struct, frozen=True):
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

# ── Core math functions (grosze-based, int in/out) ─────────────────────────

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
        vat_rate: VAT rate (e.g. Decimal("0.23")).

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

# ── Money-aware functions (Fowler's Money wrappers) ────────────────────────

def money_to_grosze(money: _Money) -> int:
    """Convert a Money amount to grosze (int).

    Nowy Nexus-Money (msgspec.Struct): przechowuje kwotę bezpośrednio
    jako ``amount_cents: int`` — nie ma potrzeby konwersji.

    Args:
        money: Money amount (any currency).

    Returns:
        Amount in grosze as integer.

    Raises:
        TypeError: If argument is not a Money instance.

    Example:
        >>> money_to_grosze(Money(amount_cents=12345, currency="PLN"))
        12345
    """
    Money = _get_money_class()  # noqa: N806
    if not isinstance(money, Money):
        raise TypeError(
            f"Expected Money, got {type(money).__name__}. "
            f"Use to_grosze() for plain Decimal/str/float."
        )
    # Nexus-Money: bezpośredni dostęp do amount_cents (int)
    return money.amount_cents

def to_money(grosze: int, currency: str = "PLN") -> _Money:
    """Convert grosze (int) to a Money amount.

    Nowy Nexus-Money (msgspec.Struct): konstruktor przyjmuje
    ``amount_cents: int`` zamiast ``(str_amount: str, currency: str)``.

    Args:
        grosze: Amount in grosze.
        currency: Target currency code (default "PLN").

    Returns:
        Money object representing the amount.

    Example:
        >>> to_money(12345)
        Money(amount_cents=12345, currency='PLN')
    """
    Money = _get_money_class()  # noqa: N806
    return Money(amount_cents=grosze, currency=currency)

def _require_same_currency(a: _Money, b: _Money, operation: str = "operate") -> None:
    """Validate that two Money objects have the same currency."""
    if a.currency_code != b.currency_code:
        from nexus_ai.services.currency_converter import CurrencyMismatchError
        raise CurrencyMismatchError(a.currency_code, b.currency_code, operation)

def multiply_net_by_vat_money(net: _Money, vat_rate: Decimal) -> _Money:
    """Multiply net Money amount by VAT rate, return VAT as Money.

    Args:
        net: Net amount as Money (e.g. Money("100.00", "PLN")).
        vat_rate: VAT rate (e.g. Decimal("0.23")).

    Returns:
        VAT amount as Money in the same currency as net.
    """
    Money = _get_money_class()  # noqa: N806
    if not isinstance(net, Money):
        raise TypeError(f"Expected Money, got {type(net).__name__}")
    vat_grosze = multiply_net_by_vat(money_to_grosze(net), vat_rate)
    return to_money(vat_grosze, net.currency_code)

def add_tax_money(net: _Money, vat: _Money) -> _Money:
    Money = _get_money_class()  # noqa: N806
    if not isinstance(net, Money) or not isinstance(vat, Money):
        raise TypeError("Both arguments must be Money instances")
    _require_same_currency(net, vat, "add_tax_money")
    gross_grosze = add_tax(money_to_grosze(net), money_to_grosze(vat))
    return to_money(gross_grosze, net.currency_code)

def calculate_vat_by_policy_money(
    positions: list[InvoicePositions],
    vat_rate: Decimal,
    rounding_level: str,
    currency: str = "PLN",
) -> _Money:
    """Calculate total VAT as Money according to the chosen rounding strategy.

    Same logic as :func:`calculate_vat_by_policy` but returns a Money object.

    Args:
        positions: List of invoice line items.
        vat_rate: VAT rate to apply.
        rounding_level: ``"position"`` or ``"total"``.
        currency: Currency for the result (default "PLN").

    Returns:
        Total VAT amount as Money.
    """
    total_vat_grosze = calculate_vat_by_policy(positions, vat_rate, rounding_level)
    return to_money(total_vat_grosze, currency)

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
        rounding_level: Must be ``"position"`` or ``"total"``.

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

    @staticmethod
    def calculate_money(
        positions: list[InvoicePositions],
        vat_rate: Decimal,
        rounding_level: str,
        currency: str = "PLN",
    ) -> _Money:
        """Calculate total VAT as Money.

        Same as :meth:`calculate` but returns a ``Money`` object.
        """
        return calculate_vat_by_policy_money(positions, vat_rate, rounding_level, currency)

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
        vat_rate: Decimal,
        rounding_level: str,
    ) -> tuple[int, list[InvoicePositions]]:
        """Calculate total VAT and return position data for auditing.

        Args:
            positions_net: List of net amounts in grosze.
            vat_rate: VAT rate as Decimal.
            rounding_level: ``"position"`` or ``"total"``.

        Returns:
            Tuple of ``(total_vat_grosze, list[InvoicePositions])``.
        """
        inv_positions = [
            InvoicePositions(net_grosze=int(net), vat_rate=vat_rate)
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
        vat_rate: Decimal,
        rounding_level: str,
    ) -> tuple[_Money, list[InvoicePositions]]:
        """Calculate total VAT from Money net amounts, return as Money.

        Args:
            positions_net: List of net amounts as Money (must all be same currency).
            vat_rate: VAT rate as Decimal.
            rounding_level: ``"position"`` or ``"total"``.

        Returns:
            Tuple of ``(total_vat_money, list[InvoicePositions])``.

        Raises:
            TypeError: If any amount is not Money.
            CurrencyMismatchError: If currencies differ.
        """
        Money = _get_money_class()  # noqa: N806

        if not positions_net:
            zero = Money.zero()
            return zero, []

        # Validate all are Money and same currency
        for i, amt in enumerate(positions_net):
            if not isinstance(amt, Money):
                raise TypeError(
                    f"positions_net[{i}]: expected Money, got {type(amt).__name__}"
                )
        for amt in positions_net[1:]:
            _require_same_currency(positions_net[0], amt, "calculate_positions_vat_money")

        currency = positions_net[0].currency_code
        grosze_list = [money_to_grosze(m) for m in positions_net]
        total_vat_grosze, inv_positions = TaxMathEngine.calculate_positions_vat(
            grosze_list, vat_rate, rounding_level
        )
        total_vat_money = to_money(total_vat_grosze, currency)
        return total_vat_money, inv_positions

    @staticmethod
    def sum_positions_net_money(
        positions_net: list[_Money],
    ) -> _Money:
        """Sum a list of Money amounts (same currency).

        Args:
            positions_net: List of Money amounts (same currency).

        Returns:
            Total as Money.

        Raises:
            CurrencyMismatchError: If currencies differ.
        """
        Money = _get_money_class()  # noqa: N806

        if not positions_net:
            return Money.zero()

        for i, amt in enumerate(positions_net):
            if not isinstance(amt, Money):
                raise TypeError(
                    f"positions_net[{i}]: expected Money, got {type(amt).__name__}"
                )
        for amt in positions_net[1:]:
            _require_same_currency(positions_net[0], amt, "sum_positions_net_money")

        currency = positions_net[0].currency_code
        total_grosze = sum(money_to_grosze(m) for m in positions_net)
        return to_money(total_grosze, currency)
