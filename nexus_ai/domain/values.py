"""Domain Value Objects — DDD dla NexusAI.

Zgodnie z wymaganiami Enterprise §1:
- Wszystkie Value Object są msgspec.Struct z frozen=True (immutable)
- Każdy VO ma własną walidację w __post_init__
- Money używa Decimal (NIE float) dla bezpieczeństwa finansowego
- NIP, IBAN mają pełną walidację (checksum, format)

Usage:
    price = Money("1234.56", "PLN")
    nip = NIP("1234567890")
    price_net = MoneyNet(gross=Money("1230.00"), vat_rate=Decimal("0.23"))
"""

from __future__ import annotations

import re
from decimal import ROUND_HALF_UP, Decimal
from typing import ClassVar

import msgspec
import pendulum


# ═══════════════════════════════════════════════════════════════════════════
# Money — Value Object dla kwot finansowych (NIE float!)
# ═══════════════════════════════════════════════════════════════════════════


class CurrencyMismatchError(ValueError):
    """Rzucany gdy próbujemy operować na różnych walutach."""

    def __init__(self, a: str, b: str) -> None:
        super().__init__(f"Cannot operate on different currencies: {a} vs {b}")
        self.code = "CURRENCY_MISMATCH"


class Money(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Pieniądze z walutą.

    Attributes:
        amount: Kwota w Decimal (NIE float!).
        currency: Kod waluty ISO 4217 (domyślnie PLN).

    Usage:
        price = Money(amount=Decimal("1234.56"), currency="PLN")
        total = price + other_price  # TypeError jeśli różne waluty
        vat = price * Decimal("0.23")  # VAT = 283.95
    """

    amount: Decimal
    currency: str = "PLN"

    def __post_init__(self) -> None:
        """Walidacja: kwota >= 0, waluta 3 litery."""
        if self.amount < Decimal("0"):
            raise ValueError(f"Money amount cannot be negative: {self.amount}")
        if len(self.currency) != 3 or not self.currency.isalpha():
            raise ValueError(f"Currency must be ISO 4217 (3 letters): {self.currency}")

    def __add__(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise CurrencyMismatchError(self.currency, other.currency)
        return Money(amount=self.amount + other.amount, currency=self.currency)

    def __sub__(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise CurrencyMismatchError(self.currency, other.currency)
        return Money(amount=self.amount - other.amount, currency=self.currency)

    def __mul__(self, factor: Decimal | int | float) -> Money:
        return Money(
            amount=(self.amount * Decimal(str(factor))).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
            currency=self.currency,
        )

    def __neg__(self) -> Money:
        return Money(amount=-self.amount, currency=self.currency)

    def __str__(self) -> str:
        return f"{self.amount:.2f} {self.currency}"

    def __repr__(self) -> str:
        return f"Money({self.amount:.2f}, {self.currency})"

    @property
    def is_zero(self) -> bool:
        """Sprawdź czy kwota = 0."""
        return self.amount == Decimal("0")

    @property
    def is_positive(self) -> bool:
        """Sprawdź czy kwota > 0."""
        return self.amount > Decimal("0")

    def round(self, places: int = 2) -> Money:
        """Zaokrąglij do podanej liczby miejsc po przecinku."""
        return Money(
            amount=self.amount.quantize(Decimal("0." + "0" * places), rounding=ROUND_HALF_UP),
            currency=self.currency,
        )

    def to_dict(self) -> dict[str, str | Decimal]:
        """Konwersja do dict dla serializacji przez msgspec enc_hook."""
        return {"amount": self.amount, "currency": self.currency}

    @classmethod
    def zero(cls, currency: str = "PLN") -> Money:
        """Zwróć zero w podanej walucie."""
        return cls(amount=Decimal("0.00"), currency=currency)

    @classmethod
    def from_float(cls, value: float, currency: str = "PLN") -> Money:
        """Utwórz z float (z konwersją na Decimal). Uwaga: straty precyzji."""
        return cls(amount=Decimal(str(value)), currency=currency)


# ═══════════════════════════════════════════════════════════════════════════
# MoneyNet — kwota netto + VAT
# ═══════════════════════════════════════════════════════════════════════════


class MoneyNet(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Kwota netto + VAT = brutto.

    Zapewnia niezmiennik: netto + VAT = brutto.

    Usage:
        inv = MoneyNet(amount_net=Money("1000.00"), vat_rate=Decimal("0.23"))
        assert inv.amount_gross == Money("1230.00")
    """

    amount_net: Money
    vat_rate: Decimal

    def __post_init__(self) -> None:
        if self.vat_rate < Decimal("0") or self.vat_rate > Decimal("1"):
            raise ValueError(f"VAT rate must be between 0 and 1: {self.vat_rate}")

    @property
    def amount_vat(self) -> Money:
        """Kwota VAT = netto * stawka."""
        return self.amount_net * self.vat_rate

    @property
    def amount_gross(self) -> Money:
        """Kwota brutto = netto + VAT."""
        return self.amount_net + self.amount_vat

    @classmethod
    def from_gross(cls, amount_gross: Money, vat_rate: Decimal) -> MoneyNet:
        """Utwórz z kwoty brutto i stawki VAT.

        Netto = brutto / (1 + vat_rate)
        """
        if vat_rate >= Decimal("1"):
            raise ValueError(f"VAT rate too high for gross calculation: {vat_rate}")
        net = Money(
            amount=(amount_gross.amount / (Decimal("1") + vat_rate)).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            ),
            currency=amount_gross.currency,
        )
        return cls(amount_net=net, vat_rate=vat_rate)


# ═══════════════════════════════════════════════════════════════════════════
# NIP — Value Object z walidacją checksum
# ═══════════════════════════════════════════════════════════════════════════


class NIP(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: NIP (10 cyfr + suma kontrolna).

    Usage:
        nip = NIP(value="1234563218")
        assert nip.is_valid
    """

    value: str
    # Wagi dla sumy kontrolnej (stałe)
    _WEIGHTS: ClassVar[tuple[int, ...]] = (6, 5, 7, 2, 3, 4, 5, 6, 7)

    def __post_init__(self) -> None:
        normalized = "".join(ch for ch in self.value if ch.isdigit())
        if len(normalized) != 10:
            raise ValueError(f"NIP must be exactly 10 digits, got {len(normalized)}: {self.value}")
        # Suma kontrolna
        checksum = sum(int(d) * w for d, w in zip(normalized[:9], self._WEIGHTS)) % 11
        if checksum == 10 or checksum != int(normalized[9]):
            raise ValueError(f"Invalid NIP checksum: {self.value}")

    def __str__(self) -> str:
        return self.value

    @property
    def normalized(self) -> str:
        """Zwróć NIP tylko jako cyfry."""
        return "".join(ch for ch in self.value if ch.isdigit())

    @property
    def formatted(self) -> str:
        """Sformatowany NIP: XXX-XXX-XX-XX."""
        v = self.normalized
        return f"{v[:3]}-{v[3:6]}-{v[6:8]}-{v[8:]}"


# ═══════════════════════════════════════════════════════════════════════════
# InvoiceNumber — numer faktury
# ═══════════════════════════════════════════════════════════════════════════


class InvoiceNumber(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Numer faktury z ekstrakcją roku/miesiąca/serii.

    Usage:
        num = InvoiceNumber(value="FV/2026/06/001")
        assert num.year == "2026"
        assert num.series == "FV"
    """

    value: str
    _PATTERN: ClassVar[re.Pattern] = re.compile(
        r"^(?P<series>[A-Za-z0-9]+)/(?P<year>\d{4})/(?P<month>\d{2})/(?P<seq>\d+)$"
    )

    def __post_init__(self) -> None:
        if not self._PATTERN.match(self.value):
            raise ValueError(
                f"Invalid invoice number format: {self.value}. "
                f"Expected: SERIES/YYYY/MM/SEQ (e.g., FV/2026/06/001)"
            )

    @property
    def _match(self):
        return self._PATTERN.match(self.value)

    @property
    def series(self) -> str:
        return self._match.group("series")

    @property
    def year(self) -> str:
        return self._match.group("year")

    @property
    def seq(self) -> str:
        return self._match.group("seq")


# ═══════════════════════════════════════════════════════════════════════════
# IBAN — walidacja numeru rachunku bankowego
# ═══════════════════════════════════════════════════════════════════════════


class IBAN(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: IBAN z walidacją długości i checksum.

    Usage:
        iban = IBAN(value="PL61109010140000071219812874")
        assert iban.country == "PL"
    """

    value: str

    def __post_init__(self) -> None:
        normalized = self.value.replace(" ", "").upper()
        if len(normalized) < 15 or len(normalized) > 34:
            raise ValueError(f"IBAN length must be 15-34 chars: {len(normalized)}")
        if not normalized[:2].isalpha():
            raise ValueError(f"IBAN must start with country code: {normalized}")
        # Prosta walidacja checksum IBAN
        rearranged = normalized[4:] + normalized[:4]
        numeric = "".join(str(ord(c) - 55) if c.isalpha() else c for c in rearranged)
        if int(numeric) % 97 != 1:
            raise ValueError(f"Invalid IBAN checksum: {self.value}")

    @property
    def country(self) -> str:
        return self.value.replace(" ", "").upper()[:2]


# ═══════════════════════════════════════════════════════════════════════════
# TaxPeriod — okres rozliczeniowy
# ═══════════════════════════════════════════════════════════════════════════


class TaxPeriod(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Okres rozliczeniowy (miesiąc/rok/kwartał).

    Usage:
        period = TaxPeriod(year=2026, month=6)
        assert period.is_month
        assert period.month_name == "June"

        q = TaxPeriod(year=2026, quarter=2)
        assert q.months == [4, 5, 6]
    """

    year: int
    month: int | None = None
    quarter: int | None = None

    def __post_init__(self) -> None:
        if self.month is None and self.quarter is None:
            raise ValueError("Either month or quarter must be specified")
        if self.month is not None and not 1 <= self.month <= 12:
            raise ValueError(f"Month must be 1-12: {self.month}")
        if self.quarter is not None and not 1 <= self.quarter <= 4:
            raise ValueError(f"Quarter must be 1-4: {self.quarter}")

    @property
    def is_month(self) -> bool:
        return self.month is not None

    @property
    def is_quarter(self) -> bool:
        return self.quarter is not None

    @property
    def months(self) -> list[int]:
        if self.month is not None:
            return [self.month]
        return list(range((self.quarter - 1) * 3 + 1, self.quarter * 3 + 1))

    @property
    def month_name(self) -> str | None:
        if self.month is not None:
            return pendulum.Date(self.year, self.month, 1).format("MMMM")
        return None


# ═══════════════════════════════════════════════════════════════════════════
# Eksport — wszystkie klasy dostępne z nexus_ai.domain
# ═══════════════════════════════════════════════════════════════════════════

__all__ = [
    "Money",
    "MoneyNet",
    "NIP",
    "InvoiceNumber",
    "IBAN",
    "TaxPeriod",
    "CurrencyMismatchError",
]
