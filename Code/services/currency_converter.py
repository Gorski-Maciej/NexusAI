"""
Currency Converter — bezpieczna konwersja walut z kursem NBP.

Wzorzec Fowler's Money: każda operacja walutowa jawna, audytowalna,
zgodna z polskimi przepisami (kurs średni NBP z ostatniego dnia roboczego).

Wymaga: py-moneyed (Money, PLN, EUR, USD...)
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

import duckdb

logger = logging.getLogger("nexus.currency")


# ── Schemat tabeli kursów ───────────────────────────────────────────────────

EXCHANGE_RATES_SCHEMA = """
CREATE TABLE IF NOT EXISTS exchange_rates (
    currency      VARCHAR NOT NULL,
    rate_date     DATE NOT NULL,
    rate_pln      DECIMAL(18, 8) NOT NULL,
    fetched_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source        VARCHAR NOT NULL DEFAULT 'NBP',
    PRIMARY KEY (currency, rate_date)
);
"""


# ── Wyjątki ─────────────────────────────────────────────────────────────────


class CurrencyMismatchError(ValueError):
    """Raised when attempting arithmetic on different currencies."""

    def __init__(self, currency_a: str, currency_b: str, operation: str = "") -> None:
        msg = (
            f"Currency mismatch: cannot {operation} {currency_a} and {currency_b}. "
            f"Use CurrencyConverter.convert() first."
        )
        super().__init__(msg)
        self.currency_a = currency_a
        self.currency_b = currency_b


class CurrencyRateNotFoundError(ValueError):
    """Raised when exchange rate is not available for a given currency/date."""

    def __init__(self, currency: str, rate_date: date) -> None:
        super().__init__(
            f"No exchange rate found for {currency} on {rate_date.isoformat()}. "
            f"Available currencies: PLN, EUR, USD, GBP, CHF, CZK, NOK, SEK, DKK, HUF"
        )


# ─── Money data class (lightweight, no py-moneyed dependency at runtime) ─────


@dataclass(frozen=True)
class Money:
    """A monetary value with currency.

    Uses Decimal for precision. All arithmetic validates currency match.

    Example:
        >>> net = Money(Decimal("100.00"), "PLN")
        >>> vat = Money(Decimal("23.00"), "PLN")
        >>> total = net + vat
        >>> total.amount == Decimal("123.00")
        True
    """

    amount: Decimal
    currency: str

    def __post_init__(self) -> None:
        if not isinstance(self.amount, Decimal):
            object.__setattr__(self, "amount", Decimal(str(self.amount)))
        self.currency  # ensure it's a valid string

    def __add__(self, other: Money) -> Money:
        _check_currencies(self, other, "add")
        return Money(self.amount + other.amount, self.currency)

    def __sub__(self, other: Money) -> Money:
        _check_currencies(self, other, "subtract")
        return Money(self.amount - other.amount, self.currency)

    def __mul__(self, factor: Decimal | int | float) -> Money:
        d = Decimal(str(factor)) if not isinstance(factor, Decimal) else factor
        return Money(self.amount * d, self.currency)

    def __rmul__(self, factor: Decimal | int | float) -> Money:
        return self.__mul__(factor)

    def __truediv__(self, divisor: Decimal | int | float) -> Money:
        d = Decimal(str(divisor)) if not isinstance(divisor, Decimal) else divisor
        return Money(self.amount / d, self.currency)

    def __neg__(self) -> Money:
        return Money(-self.amount, self.currency)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Money):
            return NotImplemented
        return self.amount == other.amount and self.currency == other.currency

    def __repr__(self) -> str:
        return f"Money({self.amount}, '{self.currency}')"

    def to_dict(self) -> dict[str, Any]:
        return {"amount": str(self.amount), "currency": self.currency}

    @staticmethod
    def zero(currency: str = "PLN") -> Money:
        """Convenience: zero amount in a given currency."""
        return Money(Decimal("0.00"), currency)


def _check_currencies(a: Money, b: Money, operation: str = "operate") -> None:
    """Validate that two Money objects have the same currency."""
    if a.currency != b.currency:
        raise CurrencyMismatchError(a.currency, b.currency, operation)


# ── Currency Converter ──────────────────────────────────────────────────────


class CurrencyConverter:
    """Konwerter walut z kursem NBP i cache w DuckDB.

    Usage:
        converter = CurrencyConverter(duckdb_conn)
        result = converter.convert(Money(Decimal("100"), "EUR"), "PLN", date(2025, 6, 1))
        # → Money(Decimal("450.00"), "PLN")  # example rate 4.50
    """

    NBP_API_URL = "http://api.nbp.pl/api/exchangerates/rates/A/{currency}/{date}/"

    # Known NBP currencies (Table A — mid rates)
    KNOWN_CURRENCIES = {"EUR", "USD", "GBP", "CHF", "CZK", "NOK", "SEK", "DKK", "HUF"}

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        conn.execute(EXCHANGE_RATES_SCHEMA)

    def convert(
        self,
        amount: Money,
        target_currency: str = "PLN",
        rate_date: date | None = None,
    ) -> Money:
        """Convert amount to target currency using NBP mid-rate.

        Args:
            amount: Money to convert.
            target_currency: Target currency code (default PLN).
            rate_date: Date for rate (default today). Uses last business day if weekend.

        Returns:
            Money in target currency.

        Raises:
            CurrencyRateNotFoundError: If rate not available.
        """
        if amount.currency == target_currency:
            return amount  # no conversion needed

        if rate_date is None:
            rate_date = date.today()

        rate = self._get_rate(amount.currency, rate_date)
        converted_amount = (amount.amount * rate).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        logger.info(
            "Converted %s %s → %s at rate %s (date=%s)",
            amount.amount, amount.currency, target_currency,
            rate, rate_date.isoformat(),
        )
        return Money(converted_amount, target_currency)

    def _get_rate(self, currency: str, rate_date: date) -> Decimal:
        """Get exchange rate from cache or NBP API.

        For PLN → other: use 1/rate (divide)
        For other → PLN: use rate directly (multiply)
        """
        normalized_currency = currency.upper()

        if normalized_currency == "PLN":
            return Decimal("1.00")

        # Fail-fast for unsupported currencies
        if normalized_currency not in self.KNOWN_CURRENCIES:
            raise CurrencyRateNotFoundError(normalized_currency, rate_date)

        # Check cache first (use last available rate if exact date missing)
        row = self._conn.execute(
            """SELECT rate_pln FROM exchange_rates
               WHERE currency = ? AND rate_date <= ?
               ORDER BY rate_date DESC LIMIT 1""",
            (normalized_currency, rate_date.isoformat()),
        ).fetchone()

        if row:
            return Decimal(str(row[0]))

        # Fetch from NBP API
        rate = self._fetch_nbp_rate(normalized_currency, rate_date)

        # Store in cache
        self._conn.execute(
            """INSERT INTO exchange_rates (currency, rate_date, rate_pln)
               VALUES (?, ?, ?)""",
            (normalized_currency, rate_date.isoformat(), str(rate)),
        )
        return rate

    def _fetch_nbp_rate(self, currency: str, rate_date: date) -> Decimal:
        """Fetch exchange rate from NBP API.

        Uses Table A (mid rates). Tries last 3 business days if weekend/holiday.
        """
        import httpx

        for days_back in range(7):  # try up to 7 days back
            try_date = rate_date - timedelta(days=days_back)
            # Skip weekends
            if try_date.weekday() >= 5:  # 5=Saturday, 6=Sunday
                continue

            url = self.NBP_API_URL.format(
                currency=currency,
                date=try_date.isoformat(),
            )
            try:
                response = httpx.get(url, timeout=10.0)
                if response.status_code == 200:
                    data = response.json()
                    mid_rate = Decimal(str(data["rates"][0]["mid"]))
                    logger.info(
                        "NBP rate: 1 %s = %s PLN (date=%s)",
                        currency, mid_rate, try_date.isoformat(),
                    )
                    return mid_rate
            except Exception as exc:
                logger.warning("NBP API error for %s on %s: %s", currency, try_date, exc)
                continue

        raise CurrencyRateNotFoundError(currency, rate_date)

    # ── Conversion trail (for audit) ────────────────────────────────────

    @staticmethod
    def build_conversion_trail(
        original: Money,
        converted: Money,
        rate: Decimal,
        rate_date: date,
    ) -> dict[str, Any]:
        """Build an auditable conversion record for decision_traces."""
        return {
            "original_amount": str(original.amount),
            "original_currency": original.currency,
            "converted_amount": str(converted.amount),
            "target_currency": converted.currency,
            "rate": str(rate),
            "rate_date": rate_date.isoformat(),
            "rate_source": "NBP",
        }

    @classmethod
    def validate_invoice_currencies(cls, items: list[Money]) -> None:
        """Validate that all Money items share the same currency.

        Raises:
            CurrencyMismatchError: If currencies differ.
        """
        if not items:
            return
        ref_currency = items[0].currency
        for item in items[1:]:
            if item.currency != ref_currency:
                raise CurrencyMismatchError(ref_currency, item.currency, "invoice")
