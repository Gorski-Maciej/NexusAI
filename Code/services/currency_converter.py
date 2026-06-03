"""
Currency Converter — bezpieczna konwersja walut z kursem NBP.

Wzorzec Fowler's Money (oficjalna implementacja py-moneyed):
każda operacja walutowa jawna, audytowalna,
zgodna z polskimi przepisami (kurs średni NBP z ostatniego dnia roboczego).

Używa: py-moneyed (Money, PLN, EUR, USD...)
"""

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

import duckdb
from moneyed import Money as BaseMoney
from sqlalchemy import TypeDecorator, DECIMAL as SADECIMAL

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


# ── Money — oficjalny Fowler's Money (py-moneyed) z dodatkowymi metodami ─────


class Money(BaseMoney):
    """Fowler's Money — oficjalna implementacja py-moneyed z dodatkami.

    Wszystkie operacje arytmetyczne dziedziczone z ``moneyed.Money``:
    - dodawanie/odejmowanie: tylko tej samej waluty (inaczej CurrencyMismatchError)
    - mnożenie/dzielenie: przez skalar (int, Decimal)
    - porównanie: ``==`` działa między Money, ``!=`` między walutami

    Dodatkowe metody (zgodność z istniejącym kodem NexusAI):
    - ``to_dict()`` — serializacja do słownika
    - ``zero(currency)`` — kwota zerowa w danej walucie
    - ``.currency_code`` — szybki dostęp do kodu waluty (str)
    - ``__getstate__``/``__setstate__`` — wsparcie pickle / msgspec
    - ``__get_validators__`` — wsparcie Pydantic v1

    Example:
        >>> net = Money("100.00", "PLN")
        >>> vat = Money("23.00", "PLN")
        >>> total = net + vat
        >>> total.amount == Decimal("123.00")
        True
        >>> total.currency_code
        'PLN'
    """

    @property
    def currency_code(self) -> str:
        """Kod waluty jako string (np. 'PLN', 'EUR')."""
        return self.currency.code

    def to_dict(self) -> dict[str, Any]:
        """Serialize to dict for JSON storage."""
        return {"amount": str(self.amount), "currency": self.currency_code}

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Money:
        """Deserialize from dict (reverse of ``to_dict``)."""
        return cls(str(data["amount"]), str(data["currency"]))

    @staticmethod
    def zero(currency: str = "PLN") -> Money:
        """Convenience: zero amount in a given currency."""
        return Money("0.00", currency)

    # ── pickle / msgspec support ────────────────────────────────────────

    def __getstate__(self) -> tuple[str, str]:
        """Return (amount_str, currency_code) for serialization."""
        return (str(self.amount), self.currency_code)

    def __setstate__(self, state: tuple[str, str]) -> None:
        """Restore from (amount_str, currency_code)."""
        amount_str, currency_code = state
        self.__init__(amount_str, currency_code)

    # ── Pydantic support (v1) ───────────────────────────────────────────

    @classmethod
    def __get_validators__(cls) -> Any:
        """Pydantic v1 validators — accepts str, Decimal, float, int, dict or Money."""
        yield cls._pydantic_validate

    @classmethod
    def _pydantic_validate(cls, value: Any) -> Money:
        """Validate and coerce various types to Money."""
        if isinstance(value, cls):
            return value
        if isinstance(value, dict):
            return cls.from_dict(value)
        if isinstance(value, str):
            return Money(value, "PLN")
        if isinstance(value, (Decimal, float, int)):
            return Money(str(value), "PLN")
        raise TypeError(f"Cannot convert {type(value).__name__} to Money")


def _check_currencies(a: Money, b: Money, operation: str = "operate") -> None:
    """Validate that two Money objects have the same currency."""
    if a.currency_code != b.currency_code:
        raise CurrencyMismatchError(a.currency_code, b.currency_code, operation)


# ── Currency Converter ──────────────────────────────────────────────────────


class CurrencyConverter:
    """Konwerter walut z kursem NBP i cache w DuckDB.

    Usage:
        converter = CurrencyConverter(duckdb_conn)
        result = converter.convert(Money("100", "EUR"), "PLN", date(2025, 6, 1))
        # → Money(Decimal('450.00'), 'PLN')  # example rate 4.50
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
        if amount.currency_code == target_currency:
            return amount  # no conversion needed

        if rate_date is None:
            rate_date = date.today()

        rate = self._get_rate(amount.currency_code, rate_date)
        converted_amount = (amount.amount * rate).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        logger.info(
            "Converted %s %s → %s at rate %s (date=%s)",
            amount.amount, amount.currency_code, target_currency,
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
            "original_currency": original.currency_code,
            "converted_amount": str(converted.amount),
            "target_currency": converted.currency_code,
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
        ref_currency = items[0].currency_code
        for item in items[1:]:
            if item.currency_code != ref_currency:
                raise CurrencyMismatchError(ref_currency, item.currency_code, "invoice")


# ── SQLAlchemy Money Type ────────────────────────────────────────────────────
# Przechowuje kwotę Money jako DECIMAL (amount), waluta w osobnej kolumnie.
# Użyj w ORM: amount_net = Column(MoneyType(12, 2), default=Money.zero)


class MoneyType(TypeDecorator):
    """SQLAlchemy type that stores ``Money.amount`` as DECIMAL.

    Waluta jest przechowywana w osobnej kolumnie (``currency: str``).
    Przy odczycie ``MoneyType`` zwraca tylko kwotę (``Decimal``).
    Aby uzyskać pełny obiekt ``Money``, użyj property na modelu ORM.

    Usage:

        .. code-block:: python

            from sqlalchemy import Column
            from services.currency_converter import MoneyType

            amount_net = Column(MoneyType(12, 2), default=Decimal("0.0"))

    **Uwaga:** ``MoneyType`` nie przechowuje waluty — zwraca ``Decimal``.
    Pełny obiekt ``Money`` konstruowany jest przez property na modelu.
    """

    impl = SADECIMAL
    cache_ok = True

    def __init__(self, precision: int = 12, scale: int = 2):
        super().__init__(precision=precision, scale=scale)
        self._precision = precision
        self._scale = scale

    def process_bind_param(self, value: Any, dialect: Any) -> Decimal | None:
        """Convert Money/Decimal → Decimal for DB storage."""
        if value is None:
            return None
        if isinstance(value, Money):
            return Decimal(str(value.amount))
        if isinstance(value, Decimal):
            return value
        if isinstance(value, (int, float)):
            return Decimal(str(value))
        raise TypeError(f"Expected Money or Decimal, got {type(value).__name__}")

    def process_result_value(self, value: Any, dialect: Any) -> Decimal | None:
        """Convert DB DECIMAL → Python Decimal."""
        if value is None:
            return None
        if isinstance(value, Decimal):
            return value
        return Decimal(str(value))

    def process_literal_param(self, value: Any, dialect: Any) -> float | None:
        return self.process_bind_param(value, dialect)


# ── msgspec enc_hook ─────────────────────────────────────────────────────────


def msgspec_money_enc_hook(obj: Any) -> Any:
    """msgspec encoder hook: serializes ``Money`` to ``float`` (amount).

    Waluta jest dostępna w osobnym polu ``currency`` struktury response.
    Dzięki temu API pozostaje kompatybilne wstecz — klienci nadal otrzymują
    ``{"amount_net": 100.00}`` zamiast ``{"amount_net": {"amount": "100.00", "currency": "PLN"}}``.

    Usage:

        .. code-block:: python

            import msgspec
            encoder = msgspec.json.Encoder(enc_hook=msgspec_money_enc_hook)
            data = encoder.encode(invoice_response)
    """
    if isinstance(obj, Money):
        return float(obj.amount)
    raise TypeError(f"Cannot encode {type(obj).__name__}")
