"""
Currency Converter — bezpieczna konwersja walut z kursem NBP.

Zastępuje: py-moneyed (Money, Fowler's Money pattern) → Nexus-Money (msgspec.Struct)
Zgodnie z aa3fvcx.txt: Nexus-Money to minimalistyczna reprezentacja pieniędzy
oparta na msgspec.Struct, z amount_cents: int i currency: str.

Każda operacja walutowa jawna, audytowalna,
zgodna z polskimi przepisami (kurs średni NBP z ostatniego dnia roboczego).
"""

from __future__ import annotations

from structlog import get_logger
import pendulum
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

import duckdb
import msgspec
from sqlalchemy import DECIMAL as SADECIMAL
from sqlalchemy import TypeDecorator

logger = get_logger("nexus.currency")


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


# ── Nexus-Money — minimalistyczna reprezentacja pieniędzy (msgspec.Struct) ───
# Zgodnie z aa3fvcx.txt, Punkt 9: Nexus-Money zastępuje py-moneyed.
# amount_cents: int — kwota w najmniejszej jednostce (grosze)
# currency: str — kod waluty (np. "PLN", "EUR")


class Money(msgspec.Struct, frozen=True):
    """Nexus-Money — minimalistyczna reprezentacja pieniędzy.

    Zastępuje: py-moneyed.Money
    Nowy:     msgspec.Struct z amount_cents i currency

    Wszystkie operacje arytmetyczne na poziomie groszy (int),
    co eliminuje błędy zaokrągleń zmiennoprzecinkowych.

    Attributes:
        amount_cents: Kwota w groszach (int). Np. 12345 = 123.45 PLN.
        currency: Kod waluty (str). Np. "PLN", "EUR", "USD".

    Uwaga: Główny konstruktor to ``Money(amount_cents=..., currency=...)``.
    Dla kompatybilności wstecznej z py-moneyed, użyj ``Money.from_string()``.
    """

    amount_cents: int
    currency: str = "PLN"

    @property
    def amount(self) -> Decimal:
        """Kwota w jednostkach waluty (Decimal z 2 miejscami)."""
        return Decimal(self.amount_cents) / Decimal("100")

    @property
    def currency_code(self) -> str:
        """Kod waluty jako string (np. 'PLN', 'EUR')."""
        return self.currency

    def to_dict(self) -> dict[str, Any]:
        """Serialize to dict for JSON storage."""
        return {"amount_cents": self.amount_cents, "currency": self.currency}

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Money:
        """Deserialize from dict (reverse of ``to_dict``)."""
        return cls(amount_cents=int(data["amount_cents"]), currency=str(data.get("currency", "PLN")))

    @classmethod
    def from_decimal(cls, amount: Decimal | str | float, currency: str = "PLN") -> Money:
        """Create Money from a decimal amount (e.g. "123.45" → amount_cents=12345)."""
        if isinstance(amount, float):
            amount = str(amount)
        if isinstance(amount, str):
            amount = Decimal(amount)
        cents = int((amount * Decimal("100")).to_integral_value(rounding=ROUND_HALF_UP))
        return cls(amount_cents=cents, currency=currency)

    @classmethod
    def from_string(cls, amount: str, currency: str = "PLN") -> Money:
        """Create Money from a decimal string (kompatybilność z py-moneyed API).

        Zastępuje: ``Money("123.45", "PLN")`` (py-moneyed)
        Nowy:     ``Money.from_string("123.45", "PLN")``

        Args:
            amount: Kwota jako string (np. "123.45").
            currency: Kod waluty (default "PLN").

        Returns:
            Money z amount_cents obliczonym z stringa.
        """
        return cls.from_decimal(amount, currency)

    @classmethod
    def zero(cls, currency: str = "PLN") -> Money:
        """Convenience: zero amount in a given currency."""
        return cls(amount_cents=0, currency=currency)

    def __add__(self, other: Money) -> Money:
        """Add two Money objects (same currency required)."""
        if self.currency != other.currency:
            raise CurrencyMismatchError(self.currency, other.currency, "add")
        return Money(self.amount_cents + other.amount_cents, self.currency)

    def __sub__(self, other: Money) -> Money:
        """Subtract two Money objects (same currency required)."""
        if self.currency != other.currency:
            raise CurrencyMismatchError(self.currency, other.currency, "subtract")
        return Money(self.amount_cents - other.amount_cents, self.currency)

    def __mul__(self, scalar: int | Decimal) -> Money:
        """Multiply by scalar (int or Decimal)."""
        if isinstance(scalar, Decimal):
            cents = int((Decimal(self.amount_cents) * scalar).to_integral_value(rounding=ROUND_HALF_UP))
        else:
            cents = self.amount_cents * scalar
        return Money(cents, self.currency)

    def __rmul__(self, scalar: int | Decimal) -> Money:
        return self.__mul__(scalar)

    def __neg__(self) -> Money:
        return Money(-self.amount_cents, self.currency)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Money):
            return NotImplemented
        return self.amount_cents == other.amount_cents and self.currency == other.currency

    def __str__(self) -> str:
        return f"{self.amount:.2f} {self.currency}"

    def __repr__(self) -> str:
        return f"Money(amount_cents={self.amount_cents}, currency={self.currency!r})"


def _check_currencies(a: Money, b: Money, operation: str = "operate") -> None:
    """Validate that two Money objects have the same currency."""
    if a.currency != b.currency:
        raise CurrencyMismatchError(a.currency, b.currency, operation)


# ── Currency Converter ──────────────────────────────────────────────────────


class CurrencyConverter:
    """Konwerter walut z kursem NBP i cache w DuckDB.

    Usage:
        converter = CurrencyConverter(duckdb_conn)
        result = converter.convert(Money.from_decimal("100", "EUR"), "PLN")
        # → Money(amount_cents=45000, currency='PLN')  # example rate 4.50
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
            rate_date = pendulum.now().date()

        rate = self._get_rate(amount.currency, rate_date)
        converted_cents = int(
            (Decimal(amount.amount_cents) * rate / Decimal("100")).to_integral_value(
                rounding=ROUND_HALF_UP
            )
        )
        logger.info(
            "Converted %s %s → %s at rate %s (date=%s)",
            amount.amount, amount.currency, target_currency,
            rate, rate_date.isoformat(),
        )
        return Money(converted_cents, target_currency)

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
            try_date = rate_date - pendulum.duration(days=days_back)
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
            "original_amount_cents": original.amount_cents,
            "original_currency": original.currency,
            "converted_amount_cents": converted.amount_cents,
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


# ── SQLAlchemy Money Type ────────────────────────────────────────────────────


class MoneyType(TypeDecorator):
    """SQLAlchemy type that stores ``Money.amount_cents`` as DECIMAL.

    Waluta jest przechowywana w osobnej kolumnie (``currency: str``).

    Usage:

        .. code-block:: python

            from sqlalchemy import Column
            from services.currency_converter import MoneyType

            amount_net = Column(MoneyType(12, 2), default=0)
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
            return Decimal(value.amount_cents) / Decimal("100")
        if isinstance(value, int):
            return Decimal(value)
        if isinstance(value, Decimal):
            return value
        if isinstance(value, (float,)):
            return Decimal(str(value))
        raise TypeError(f"Expected Money, int, or Decimal, got {type(value).__name__}")

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

    Zgodny wstecz: klienci nadal otrzymują ``{"amount_net": 100.00}``.

    Usage:

        .. code-block:: python

            import msgspec
            encoder = msgspec.json.Encoder(enc_hook=msgspec_money_enc_hook)
            data = encoder.encode(invoice_response)
    """
    if isinstance(obj, Money):
        return float(obj.amount)
    raise TypeError(f"Cannot encode {type(obj).__name__}")
