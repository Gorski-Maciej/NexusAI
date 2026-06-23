"""
NexusAI core types — msgspec.Struct based value objects and paginated response.

Replaces pydantic RootModel/TypeAdapter with msgspec.Struct for maximum
performance and zero pydantic dependency in the API layer.

SUPERMOCE msgspec:
- Struct z typami → zero narzutu walidacji
- Generics przez Generic[T] na Struct
- Własne metody validate() zamiast pydantic validators
- __post_init__ dla automatycznej walidacji po utworzeniu
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, Generic, TypeVar

from msgspec import Struct


# ── Value Objects ──────────────────────────────────────────────────


class Money(Struct, frozen=True):
    """Money value — auto-rounds to 2 decimal places.

    Użycie:
        price = Money(amount=Decimal("123.456"))  # → Money(amount=Decimal('123.46'))
        price.amount  # → Decimal('123.46')

    Zamiast RootModel[Decimal]: msgspec.Struct z jednym polem.
    """

    amount: Decimal

    def __post_init__(self) -> None:
        """Auto-round to 2 decimal places after creation."""
        if self.amount is not None:
            object.__setattr__(self, "amount", self.amount.quantize(Decimal("0.01")))

    @classmethod
    def validate(cls, value: str | float | Decimal) -> Money:
        """Utwórz Money z autmatycznym round do 2 miejsc.

        Args:
            value: Wartość pieniężna (str, float, lub Decimal).

        Returns:
            Zwalidowany Money.
        """
        return cls(amount=Decimal(str(value)).quantize(Decimal("0.01")))

    def __str__(self) -> str:
        return f"{self.amount:.2f}"


class OperationId(Struct, frozen=True):
    """UUID-based operation identifier — walidacja długości.

    Zamiast RootModel[str]: msgspec.Struct z jednym polem.
    """

    value: str

    @classmethod
    def validate(cls, value: str) -> OperationId:
        """Utwórz OperationId z walidacją długości.

        Args:
            value: Identyfikator operacji (UUID hex lub inny string).

        Returns:
            Zwalidowany OperationId.
        """
        if not value or len(value) < 8:
            raise ValueError(f"OperationId must be at least 8 chars, got {len(value)}")
        return cls(value=value)


class Nip(Struct, frozen=True):
    """NIP — 10-cyfrowy identyfikator z autmatycznym czyszczeniem.

    Zamiast RootModel[str]: msgspec.Struct z jednym polem.
    """

    value: str

    @classmethod
    def validate(cls, value: str) -> Nip:
        """Utwórz Nip z czyszczeniem i walidacją.

        Args:
            value: NIP (może zawierać myślniki/spacje).

        Returns:
            Zwalidowany Nip (10 cyfr).
        """
        cleaned = value.replace("-", "").replace(" ", "")
        if not cleaned.isdigit() or len(cleaned) != 10:
            raise ValueError(f"NIP must be 10 digits, got {value!r}")
        return cls(value=cleaned)

    def __str__(self) -> str:
        return self.value


# ── Type Adapters (functions instead of pydantic TypeAdapter) ──────


def validate_money_list(values: list[str | float | Decimal]) -> list[Decimal]:
    """Validate a list of money values.

    Replaces: TypeAdapter[list[Decimal]]

    Args:
        values: List of money values as str, float, or Decimal.

    Returns:
        List of validated Decimal values.

    Raises:
        ValueError: If any value cannot be converted to Decimal.
    """
    result: list[Decimal] = []
    for v in values:
        try:
            result.append(Decimal(str(v)).quantize(Decimal("0.01")))
        except Exception as e:
            raise ValueError(f"Invalid money value: {v!r}") from e
    return result


def validate_status_counter(values: dict[str, int]) -> dict[str, int]:
    """Validate a status counter dict (string→int).

    Replaces: TypeAdapter[dict[str, int]]

    Args:
        values: Dict of status→count.

    Returns:
        Validated dict.
    """
    for k, v in values.items():
        if not isinstance(k, str):
            raise ValueError(f"Status key must be string, got {type(k).__name__}")
        if not isinstance(v, int) or v < 0:
            raise ValueError(f"Status count must be non-negative int, got {v!r}")
    return dict(values)


def validate_role_set(values: list[str]) -> set[str]:
    """Validate a set of role strings.

    Replaces: TypeAdapter[set[str]]

    Args:
        values: List of role strings.

    Returns:
        Deduplicated set of role strings.
    """
    return set(str(v) for v in values)


def validate_snapshot(values: dict[str, Any]) -> dict[str, Any]:
    """Validate an EventStore snapshot dict.

    Replaces: TypeAdapter[dict[str, Any]]

    Args:
        values: Snapshot dict.

    Returns:
        Validated dict.
    """
    if not isinstance(values, dict):
        raise ValueError(f"Snapshot must be a dict, got {type(values).__name__}")
    return dict(values)


# ── Generic Paginated Response ─────────────────────────────────────────

T = TypeVar("T")


class PaginatedResponse(Struct, Generic[T]):
    """Generic paginated API response z total/page/page_size.

    Replaces: RootModel[list[T]] with Pydantic Generic.

    Użycie:
        response = PaginatedResponse[str](
            root=["a", "b"],
            total=10,
            page=1,
            page_size=20,
        )
        # response.root → ["a", "b"]
        # response.total → 10
    """

    root: list[T] = []
    total: int = 0
    page: int = 1
    page_size: int = 20

    @property
    def total_pages(self) -> int:
        """Liczba stron (ceil division)."""
        if self.page_size <= 0:
            return 0
        return (self.total + self.page_size - 1) // self.page_size

    @property
    def has_next(self) -> bool:
        """Czy istnieje następna strona."""
        return self.page < self.total_pages

    @property
    def has_prev(self) -> bool:
        """Czy istnieje poprzednia strona."""
        return self.page > 1

    @classmethod
    def create(
        cls,
        items: list[T],
        total: int,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedResponse[T]:
        """Utwórz PaginatedResponse z walidacją zakresów.

        Args:
            items: Lista elementów na stronie.
            total: Całkowita liczba elementów.
            page: Numer strony (1-based).
            page_size: Rozmiar strony.

        Returns:
            Zwalidowany PaginatedResponse.
        """
        if page < 1:
            raise ValueError(f"page must be >= 1, got {page}")
        if page_size < 1:
            raise ValueError(f"page_size must be >= 1, got {page_size}")
        if total < 0:
            raise ValueError(f"total must be >= 0, got {total}")
        return cls(root=items, total=total, page=page, page_size=page_size)


# ── Backward compatibility aliases ─────────────────────────────────

# Keep old names for backward compatibility during migration
# These will be removed in a future version
MoneyRO = Money
OperationIdRO = OperationId
NipRO = Nip

# For paginated_adapter, provide a function that works differently
# (returns the class instead of a pydantic TypeAdapter)
def paginated_adapter(item_type: type[T]) -> type[PaginatedResponse[T]]:
    """Get PaginatedResponse class parameterized with item_type.

    Replaces: TypeAdapter[PaginatedResponse[T]]

    Args:
        item_type: Typ elementu na liście.

    Returns:
        PaginatedResponse class for the given item type.
    """
    return PaginatedResponse[item_type]  # type: ignore[valid-type]
