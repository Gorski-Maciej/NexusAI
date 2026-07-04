"""Domain Value Objects -- DDD dla NexusAI.

Zgodnie z wymaganiami Enterprise §1:
- Wszystkie Value Object są msgspec.Struct z frozen=True (immutable)
- Każdy VO ma własną walidację w __post_init__
- Money używa Decimal (NIE float) dla bezpieczeństwa finansowego
- NIP, IBAN, PESEL mają pełną walidację (checksum, format)

Value Objects:
    Money          -- kwota + waluta (ISO 4217)
    MoneyNet       -- netto + VAT = brutto (niezmiennik)
    NIP            -- identyfikator podatkowy z sumą kontrolną
    IBAN           -- numer rachunku bankowego
    PESEL          -- identyfikator PESEL z sumą kontrolną
    InvoiceNumber  -- numer faktury (seria/rok/miesiąc/seq)
    TaxPeriod      -- okres rozliczeniowy
    VatRate        -- stawka VAT z walidacją
    AccountCode    -- kod konta księgowego (ZK)
    BusinessKind   -- rodzaj działalności
    KSeFMetadata   -- metadane e-faktury KSeF
"""

from __future__ import annotations

import re
from decimal import ROUND_HALF_UP, Decimal
from typing import ClassVar

import msgspec
import pendulum

# ═══════════════════════════════════════════════════════════════════════════
# Money -- Value Object dla kwot finansowych (NIE float!)
# ═══════════════════════════════════════════════════════════════════════════


class CurrencyMismatchError(ValueError):
    """Rzucany gdy próbujemy operować na różnych walutach."""

    def __init__(self, a: str, b: str) -> None:
        super().__init__(f"Cannot operate on different currencies: {a} vs {b}")
        self.code = "CURRENCY_MISMATCH"


# ── Backward-compat error aliases (zachowane z poprzedniej wersji) ───────
class InvalidIBANError(ValueError):
    """Rzucany gdy IBAN jest nieprawidłowy."""


class InvalidNIPError(ValueError):
    """Rzucany gdy NIP jest nieprawidłowy."""


class InvalidPESELError(ValueError):
    """Rzucany gdy PESEL jest nieprawidłowy."""


class Money(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Pieniądze z walutą.

    Attributes:
        amount: Kwota w Decimal (NIE float!).
        currency: Kod waluty ISO 4217 (domyślnie PLN).
    """

    amount: Decimal
    currency: str = "PLN"

    def __post_init__(self) -> None:
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
        if isinstance(factor, float):
            raise TypeError("Cannot multiply Money by float, use Decimal")
        return Money(
            amount=(self.amount * Decimal(str(factor))).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            ),
            currency=self.currency,
        )

    def __neg__(self) -> Money:
        return Money(amount=-self.amount, currency=self.currency)

    def __str__(self) -> str:
        return f"{self.amount:.2f} {self.currency}"

    def __repr__(self) -> str:
        return f"{self.amount:.2f} {self.currency}"

    def to_grosze(self) -> int:
        """Konwertuj kwotę na grosze (int)."""
        return int(self.amount * Decimal("100"))

    @classmethod
    def from_grosze(cls, grosze: int, currency: str = "PLN") -> Money:
        """Utwórz Money z liczby groszy."""
        return cls(amount=Decimal(str(grosze)) / Decimal("100"), currency=currency)

    @property
    def is_zero(self) -> bool:
        return self.amount == Decimal("0")

    @property
    def is_positive(self) -> bool:
        return self.amount > Decimal("0")

    def round(self, places: int = 2) -> Money:
        return Money(
            amount=self.amount.quantize(
                Decimal("0." + "0" * places), rounding=ROUND_HALF_UP
            ),
            currency=self.currency,
        )

    def to_dict(self) -> dict[str, str | Decimal]:
        return {"amount": self.amount, "currency": self.currency}

    @classmethod
    def zero(cls, currency: str = "PLN") -> Money:
        return cls(amount=Decimal("0.00"), currency=currency)

    @classmethod
    def from_float(cls, value: float, currency: str = "PLN") -> Money:
        return cls(amount=Decimal(str(value)), currency=currency)


# ═══════════════════════════════════════════════════════════════════════════
# MoneyNet -- kwota netto + VAT
# ═══════════════════════════════════════════════════════════════════════════


class MoneyNet(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Kwota netto + VAT = brutto.

    Zapewnia niezmiennik: netto + VAT = brutto.
    """

    amount_net: Money
    vat_rate: Decimal

    def __post_init__(self) -> None:
        if self.vat_rate < Decimal("0") or self.vat_rate > Decimal("1"):
            raise ValueError(f"VAT rate must be between 0 and 1: {self.vat_rate}")

    @property
    def amount_vat(self) -> Money:
        return self.amount_net * self.vat_rate

    @property
    def amount_gross(self) -> Money:
        return self.amount_net + self.amount_vat

    @classmethod
    def from_gross(cls, amount_gross: Money, vat_rate: Decimal) -> MoneyNet:
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
# NIP -- Value Object z walidacją checksum
# ═══════════════════════════════════════════════════════════════════════════


class NIP(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: NIP (10 cyfr + suma kontrolna)."""

    value: str
    _WEIGHTS: ClassVar[tuple[int, ...]] = (6, 5, 7, 2, 3, 4, 5, 6, 7)

    def __post_init__(self) -> None:
        normalized = "".join(ch for ch in self.value if ch.isdigit())
        if len(normalized) != 10:
            raise ValueError(f"NIP must be exactly 10 digits, got {len(normalized)}: {self.value}")
        checksum = sum(int(d) * w for d, w in zip(normalized[:9], self._WEIGHTS, strict=True)) % 11
        if checksum == 10 or checksum != int(normalized[9]):
            raise ValueError(f"Invalid NIP checksum: {self.value}")

    def __str__(self) -> str:
        return self.formatted

    @property
    def normalized(self) -> str:
        return "".join(ch for ch in self.value if ch.isdigit())

    @property
    def formatted(self) -> str:
        v = self.normalized
        return f"{v[:3]}-{v[3:6]}-{v[6:8]}-{v[8:]}"


# ═══════════════════════════════════════════════════════════════════════════
# InvoiceNumber -- numer faktury
# ═══════════════════════════════════════════════════════════════════════════


class InvoiceNumber(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Numer faktury z ekstrakcją roku/miesiąca/serii."""

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
# IBAN -- walidacja numeru rachunku bankowego
# ═══════════════════════════════════════════════════════════════════════════


class IBAN(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: IBAN z walidacją długości i checksum."""

    value: str

    def __post_init__(self) -> None:
        normalized = self.value.replace(" ", "").upper()
        if len(normalized) < 15 or len(normalized) > 34:
            raise ValueError(f"IBAN length must be 15-34 chars: {len(normalized)}")
        if not normalized[:2].isalpha():
            raise ValueError(f"IBAN must start with country code: {normalized}")
        rearranged = normalized[4:] + normalized[:4]
        numeric = "".join(str(ord(c) - 55) if c.isalpha() else c for c in rearranged)
        if int(numeric) % 97 != 1:
            raise ValueError(f"Invalid IBAN checksum: {self.value}")

    def __str__(self) -> str:
        v = self.value.replace(" ", "").upper()
        return " ".join(v[i:i+4] for i in range(0, len(v), 4))

    @property
    def country(self) -> str:
        return self.value.replace(" ", "").upper()[:2]


# ═══════════════════════════════════════════════════════════════════════════
# PESEL -- identyfikator PESEL z walidacją
# ═══════════════════════════════════════════════════════════════════════════


class PESEL(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: PESEL (11 cyfr + suma kontrolna)."""

    value: str
    _WEIGHTS: ClassVar[tuple[int, ...]] = (1, 3, 7, 9, 1, 3, 7, 9, 1, 3)

    def __post_init__(self) -> None:
        normalized = "".join(ch for ch in self.value if ch.isdigit())
        if len(normalized) != 11:
            raise InvalidPESELError(f"PESEL must be exactly 11 digits, got {len(normalized)}")
        checksum = sum(int(d) * w for d, w in zip(normalized[:10], self._WEIGHTS, strict=True))
        expected = (10 - (checksum % 10)) % 10
        if expected != int(normalized[10]):
            raise InvalidPESELError(f"Invalid PESEL checksum: {self.value}")

    def get_gender(self) -> str:
        """Zwróć płeć ('male' lub 'female') na podstawie 10. cyfry."""
        digit = int(self.value[-2]) if len(self.value) >= 10 else 0
        return "male" if digit % 2 != 0 else "female"

    def get_birth_date(self) -> str:
        """Zwróć datę urodzenia jako YYYY-MM-DD."""
        normalized = "".join(ch for ch in self.value if ch.isdigit())
        if len(normalized) < 6:
            return ""
        yy = int(normalized[0:2])
        mm = int(normalized[2:4])
        dd = int(normalized[4:6])
        if 1 <= mm <= 12:
            century = 1900
        elif 21 <= mm <= 32:
            century = 2000
            mm -= 20
        elif 41 <= mm <= 52:
            century = 2100
            mm -= 40
        elif 61 <= mm <= 72:
            century = 2200
            mm -= 60
        elif 81 <= mm <= 92:
            century = 1800
            mm -= 80
        else:
            century = 1900
        year = century + yy
        return f"{year}-{mm:02d}-{dd:02d}"


# ═══════════════════════════════════════════════════════════════════════════
# TaxPeriod -- okres rozliczeniowy
# ═══════════════════════════════════════════════════════════════════════════


class TaxPeriod(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Okres rozliczeniowy (miesiąc/rok/kwartał)."""

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
# VatRate -- stawka VAT z walidacją
# ═══════════════════════════════════════════════════════════════════════════


class VatRate(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Stawka VAT z nazwą i kodem.

    Usage:
        vat = VatRate(value=Decimal("0.23"), code="23")
        assert vat.label == "23%"
        assert vat.rate_23
    """

    value: Decimal
    code: str = ""

    # Standardowe stawki VAT
    STANDARD_23: ClassVar[Decimal] = Decimal("0.23")
    REDUCED_8: ClassVar[Decimal] = Decimal("0.08")
    REDUCED_5: ClassVar[Decimal] = Decimal("0.05")
    ZERO: ClassVar[Decimal] = Decimal("0.00")
    EXEMPT: ClassVar[Decimal] = Decimal("0.00")
    _ALLOWED: ClassVar[frozenset[Decimal]] = frozenset({
        STANDARD_23, REDUCED_8, REDUCED_5, ZERO, EXEMPT,
    })

    def __post_init__(self) -> None:
        if self.value < Decimal("0") or self.value > Decimal("1"):
            raise ValueError(f"VAT rate must be 0-1: {self.value}")
        if self.value not in self._ALLOWED:
            raise ValueError(
                f"VAT rate {self.value} not in standard rates: "
                f"{[str(r) for r in self._ALLOWED]}"
            )

    @property
    def label(self) -> str:
        return f"{int(self.value * 100)}%"

    @property
    def rate_23(self) -> bool:
        return self.value == self.STANDARD_23

    @property
    def rate_8(self) -> bool:
        return self.value == self.REDUCED_8

    @property
    def rate_5(self) -> bool:
        return self.value == self.REDUCED_5

    @property
    def rate_0(self) -> bool:
        return self.value == self.ZERO

    @classmethod
    def from_percent(cls, percent: int) -> VatRate:
        mapping = {23: cls.STANDARD_23, 8: cls.REDUCED_8, 5: cls.REDUCED_5, 0: cls.ZERO}
        if percent not in mapping:
            raise ValueError(f"Unknown VAT percent: {percent}")
        return cls(value=mapping[percent], code=str(percent))


# ═══════════════════════════════════════════════════════════════════════════
# AccountCode -- kod konta księgowego
# ═══════════════════════════════════════════════════════════════════════════


class AccountCode(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Kod konta księgowego z zespołem.

    Usage:
        acct = AccountCode(value="401-1")
        assert acct.team == "4"
        assert acct.is_expense
    """

    value: str
    _PATTERN: ClassVar[re.Pattern] = re.compile(r"^(\d)(\d{2})(?:-(\d+))?$")

    def __post_init__(self) -> None:
        if not self._PATTERN.match(self.value):
            raise ValueError(
                f"Invalid account code: {self.value}. Expected format: XXX or XXX-X"
            )

    @property
    def team(self) -> str:
        m = self._PATTERN.match(self.value)
        return m.group(1) if m else ""

    @property
    def is_expense(self) -> bool:
        return self.team in ("4", "5")

    @property
    def is_revenue(self) -> bool:
        return self.team == "7"

    @property
    def is_asset(self) -> bool:
        return self.team in ("0", "1")

    @property
    def is_liability(self) -> bool:
        return self.team in ("2", "3", "8")


# ═══════════════════════════════════════════════════════════════════════════
# BusinessKind -- rodzaj działalności
# ═══════════════════════════════════════════════════════════════════════════


class BusinessKind(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Rodzaj działalności dla księgowań.

    Usage:
        kind = BusinessKind(value="it")
        assert kind.is_service
    """

    value: str = "other"

    _SERVICE_KINDS: ClassVar[frozenset[str]] = frozenset({
        "it", "consulting", "legal", "accounting",
        "marketing", "construction", "transport",
    })

    _TRADE_KINDS: ClassVar[frozenset[str]] = frozenset({
        "retail", "wholesale", "ecommerce",
    })

    _PRODUCTION_KINDS: ClassVar[frozenset[str]] = frozenset({
        "manufacturing", "food", "pharma",
    })

    _ALL_KINDS: ClassVar[frozenset[str]] = (
        _SERVICE_KINDS | _TRADE_KINDS | _PRODUCTION_KINDS | {"other"}
    )

    def __post_init__(self) -> None:
        if self.value not in self._ALL_KINDS:
            raise ValueError(f"Unknown business kind: {self.value}")

    @property
    def is_service(self) -> bool:
        return self.value in self._SERVICE_KINDS

    @property
    def is_trade(self) -> bool:
        return self.value in self._TRADE_KINDS

    @property
    def is_production(self) -> bool:
        return self.value in self._PRODUCTION_KINDS

    @classmethod
    def default(cls) -> BusinessKind:
        return cls(value="other")


# ═══════════════════════════════════════════════════════════════════════════
# KSeFMetadata -- metadane e-faktury KSeF
# ═══════════════════════════════════════════════════════════════════════════


class KSeFMetadata(msgspec.Struct, frozen=True, kw_only=True):
    """Value Object: Metadane faktury w systemie KSeF.

    Usage:
        meta = KSeFMetadata(ksef_id="1234567890ABCDEF", qr_code_url="https://...")
        assert meta.is_registered
    """

    ksef_id: str | None = None
    qr_code_url: str | None = None
    acquisition_timestamp: str | None = None
    schema_version: str = "FA2"

    def __post_init__(self) -> None:
        if self.ksef_id and len(self.ksef_id) < 10:
            raise ValueError(f"KSeF ID too short: {self.ksef_id}")

    @property
    def is_registered(self) -> bool:
        return self.ksef_id is not None and len(self.ksef_id) >= 10

    @property
    def verification_url(self) -> str | None:
        if not self.ksef_id:
            return None
        return f"https://ksef.mf.gov.pl/web/api/verify/{self.ksef_id}"


# ═══════════════════════════════════════════════════════════════════════════
# Eksport
# ═══════════════════════════════════════════════════════════════════════════

__all__ = [
    "AccountCode",
    "BusinessKind",
    "CurrencyMismatchError",
    "IBAN",
    "InvalidIBANError",
    "InvalidNIPError",
    "InvalidPESELError",
    "InvoiceNumber",
    "KSeFMetadata",
    "Money",
    "MoneyNet",
    "NIP",
    "PESEL",
    "TaxPeriod",
    "VatRate",
]
