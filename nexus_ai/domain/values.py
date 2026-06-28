"""
Domain Value Objects for financial domain — msgspec.Struct with validation.

Zgodnie z wymaganiami Enterprise (DDD, Value Objects):
- Money: kwota w walucie z kontrolą precyzji (grosze)
- NIP: polski NIP z walidacją sumy kontrolnej
- IBAN: międzynarodowy numer rachunku bankowego
- PESEL: polski PESEL z walidacją

Wszystkie Value Objects są:
- Niezmienne (frozen=True)
- Typowane (msgspec.Struct z type hints)
- Z walidacją w __post_init__
- Z serializacją przez msgspec (zero-copy)
"""

from __future__ import annotations

import re
from decimal import ROUND_HALF_UP, Decimal
from typing import final

from msgspec import Struct


# ── Wyjątki domenowe ────────────────────────────────────────────────────────


class DomainValidationError(ValueError):
    """Base exception for domain validation errors."""


class InvalidNIPError(DomainValidationError):
    """NIP has invalid checksum or format."""


class InvalidIBANError(DomainValidationError):
    """IBAN has invalid checksum or format."""


class InvalidPESELError(DomainValidationError):
    """PESEL has invalid checksum or format."""


class CurrencyMismatchError(DomainValidationError):
    """Cannot perform arithmetic on different currencies."""


# ── Value Objects ───────────────────────────────────────────────────────────


@final
class Money(Struct, frozen=True, kw_only=True):
    """Value Object: kwota w walucie z kontrolą precyzji (grosze).

    Args:
        amount: Kwota (zaokrąglana do 2 miejsc po przecinku).
        currency: Kod waluty ISO 4217 (domyślnie PLN).

    Raises:
        CurrencyMismatchError: Przy próbie dodania różnych walut.
        ValueError: Gdy amount jest ujemne.
    """

    amount: Decimal
    currency: str = "PLN"

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError(f"Amount cannot be negative: {self.amount}")
        if not re.match(r"^[A-Z]{3}$", self.currency):
            raise ValueError(f"Invalid currency code: {self.currency}")
        # Zaokrąglenie do groszy (2 miejsca po przecinku)
        object.__setattr__(
            self, "amount", self.amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        )

    def __add__(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise CurrencyMismatchError(f"Cannot add {self.currency} and {other.currency}")
        return Money(amount=self.amount + other.amount, currency=self.currency)

    def __sub__(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise CurrencyMismatchError(f"Cannot subtract {self.currency} and {other.currency}")
        result = self.amount - other.amount
        # W księgowości korekty (storna) mogą dać ujemne saldo przejściowo
        # Dopuszczamy do -0.01 (błąd zaokrąglenia)
        if result < -Decimal("0.01"):
            raise ValueError(f"Result would be negative: {result}")
        return Money(amount=max(result, Decimal("0.00")), currency=self.currency)

    def __mul__(self, factor: Decimal | int) -> Money:
        """Pomnóż kwotę przez współczynnik.

        Args:
            factor: Mnożnik (Decimal lub int). Float nie jest akceptowany
                    ze względu na utratę precyzji.

        Raises:
            TypeError: Gdy factor jest float.
        """
        if isinstance(factor, float):
            raise TypeError(
                "Use Decimal for multiplication to avoid precision loss. "
                "Convert: factor = Decimal(str(factor))"
            )
        return Money(
            amount=self.amount * Decimal(str(factor)),
            currency=self.currency,
        )

    def __neg__(self) -> Money:
        raise ValueError("Money cannot be negative")

    def __repr__(self) -> str:
        return f"{self.amount:.2f} {self.currency}"

    def to_grosze(self) -> int:
        """Zwróć kwotę w groszach (int) dla TigerBeetle."""
        return int(self.amount * 100)

    @classmethod
    def from_grosze(cls, grosze: int, currency: str = "PLN") -> Money:
        """Utwórz Money z kwoty w groszach."""
        return cls(amount=Decimal(grosze) / 100, currency=currency)

    @classmethod
    def zero(cls, currency: str = "PLN") -> Money:
        """Zwróć zero dla danej waluty."""
        return cls(amount=Decimal("0.00"), currency=currency)


@final
class NIP(Struct, frozen=True, kw_only=True):
    """Value Object: polski NIP z walidacją sumy kontrolnej.

    Format: 10 cyfr (XXX-XXX-XX-XX lub XXXXXXXXXX).

    Raises:
        InvalidNIPError: Gdy NIP ma nieprawidłową sumę kontrolną.
    """

    value: str

    def __post_init__(self) -> None:
        # Normalizacja: usuń myślniki i spacje
        normalized = re.sub(r"[\s-]", "", self.value)
        if not self._validate(normalized):
            raise InvalidNIPError(
                f"Invalid NIP: {self.value}. Must be 10 digits with valid checksum."
            )
        object.__setattr__(self, "value", normalized)

    @staticmethod
    def _validate(nip: str) -> bool:
        """Walidacja sumy kontrolnej NIP."""
        if len(nip) != 10 or not nip.isdigit():
            return False
        weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
        total = sum(int(d) * w for d, w in zip(nip, weights))
        return total % 11 == int(nip[-1])

    def __str__(self) -> str:
        return f"{self.value[:3]}-{self.value[3:6]}-{self.value[6:8]}-{self.value[8:]}"


@final
class IBAN(Struct, frozen=True, kw_only=True):
    """Value Object: międzynarodowy numer rachunku bankowego (IBAN).

    Format: 2 litery (kraj) + 2 cyfry (checksum) + do 30 cyfr/liter.
    Dla Polski: PL + 2 cyfry + 26 cyfr (łącznie 28 znaków).

    Raises:
        InvalidIBANError: Gdy IBAN ma nieprawidłową sumę kontrolną.
    """

    value: str

    def __post_init__(self) -> None:
        # Normalizacja: usuń spacje, zamień na uppercase
        normalized = re.sub(r"\s", "", self.value).upper()
        if not self._validate(normalized):
            raise InvalidIBANError(
                f"Invalid IBAN: {self.value}. Must pass IBAN checksum validation."
            )
        object.__setattr__(self, "value", normalized)

    @staticmethod
    def _validate(iban: str) -> bool:
        """Walidacja sumy kontrolnej IBAN (ISO 13616)."""
        if len(iban) < 4 or len(iban) > 34:
            return False
        if not re.match(r"^[A-Z]{2}\d{2}[A-Z0-9]+$", iban):
            return False
        # Przesuń pierwsze 4 znaki na koniec i zamień litery na cyfry
        rearranged = iban[4:] + iban[:4]
        numeric = ""
        for ch in rearranged:
            if ch.isdigit():
                numeric += ch
            else:
                numeric += str(ord(ch) - 55)
        return int(numeric) % 97 == 1

    def __str__(self) -> str:
        """Zwróć IBAN w grupach po 4 znaki."""
        groups = [self.value[i : i + 4] for i in range(0, len(self.value), 4)]
        return " ".join(groups)


@final
class PESEL(Struct, frozen=True, kw_only=True):
    """Value Object: polski PESEL z walidacją sumy kontrolnej.

    Format: 11 cyfr.

    Raises:
        InvalidPESELError: Gdy PESEL ma nieprawidłową sumę kontrolną.
    """

    value: str

    def __post_init__(self) -> None:
        if not self._validate(self.value):
            raise InvalidPESELError(
                f"Invalid PESEL: {self.value}. Must be 11 digits with valid checksum."
            )

    @staticmethod
    def _validate(pesel: str) -> bool:
        """Walidacja sumy kontrolnej PESEL."""
        if len(pesel) != 11 or not pesel.isdigit():
            return False
        weights = [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]
        total = sum(int(d) * w for d, w in zip(pesel, weights))
        checksum = (10 - (total % 10)) % 10
        return checksum == int(pesel[-1])

    def get_birth_date(self) -> str:
        """Wyodrębnij datę urodzenia z PESEL (YYYY-MM-DD)."""
        year = int(self.value[:2])
        month = int(self.value[2:4])
        day = int(self.value[4:6])

        # Określenie wieku na podstawie miesiąca
        if month > 80:
            year += 1800
            month -= 80
        elif month > 60:
            year += 2200
            month -= 60
        elif month > 40:
            year += 2100
            month -= 40
        elif month > 20:
            year += 2000
            month -= 20
        else:
            year += 1900

        return f"{year:04d}-{month:02d}-{day:02d}"

    def get_gender(self) -> str:
        """Określ płeć na podstawie PESEL."""
        return "male" if int(self.value[9]) % 2 == 1 else "female"


__all__ = [
    "Money",
    "NIP",
    "IBAN",
    "PESEL",
    "DomainValidationError",
    "InvalidNIPError",
    "InvalidIBANError",
    "InvalidPESELError",
    "CurrencyMismatchError",
]
