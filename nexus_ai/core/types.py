""""
Pydantic v2 utility types — RootModel, TypeAdapter, Generic paginated response.

SUPERMOCE Pydantic v2:
- RootModel: opakowuje pojedynczy typ w model Pydantic (walidacja + serializacja)
- TypeAdapter: ad-hoc walidacja dla typów bez pełnego modelu
- Generic: type-safe paginowane odpowiedzi API
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, Generic, TypeVar

from pydantic import RootModel, TypeAdapter, GetCoreSchemaHandler
from pydantic_core import CoreSchema, core_schema

# ── RootModel — typy dla podstawowych wartości ──────────────────────────


class MoneyRO(RootModel[Decimal]):
    """Money value — auto-rounds to 2 decimal places, walidacja przy tworzeniu.

    Użycie:
        price = MoneyRO(Decimal("123.456"))  # → MoneyRO(root=Decimal('123.46'))
        price.root  # → Decimal('123.46')

    SUPERMOC: RootModel daje full Pydantic walidację dla pojedyńczej wartości.
    """

    @classmethod
    def validate(cls, value: str | float | Decimal) -> MoneyRO:
        """Utwórz MoneyRO z autmatycznym round do 2 miejsc.

        Args:
            value: Wartość pieniężna (str, float, lub Decimal).

        Returns:
            Zwalidowany MoneyRO.
        """
        return cls(Decimal(str(value)).quantize(Decimal("0.01")))

    def __str__(self) -> str:
        return f"{self.root:.2f}"


class OperationIdRO(RootModel[str]):
    """UUID-based operation identifier — walidacja formatu.

    Użycie:
        op_id = OperationIdRO("abc123")
        op_id.root  # → "abc123"

    SUPERMOC: RootModel z walidacją dla identyfikatorów.
    """

    @classmethod
    def validate(cls, value: str) -> OperationIdRO:
        """Utwórz OperationIdRO z walidacją długości.

        Args:
            value: Identyfikator operacji (UUID hex lub inny string).

        Returns:
            Zwalidowany OperationIdRO.
        """
        if not value or len(value) < 8:
            raise ValueError(f"OperationId must be at least 8 chars, got {len(value)}")
        return cls(value)


class NipRO(RootModel[str]):
    """NIP — 10-cyfrowy identyfikator z autmatycznym czyszczeniem.

    Użycie:
        nip = NipRO("123-456-32-18")  # → NipRO(root='1234563218')
        nip.root  # → '1234563218'
    """

    @classmethod
    def validate(cls, value: str) -> NipRO:
        """Utwórz NipRO z czyszczeniem i walidacją.

        Args:
            value: NIP (może zawierać myślniki/spacje).

        Returns:
            Zwalidowany NipRO (10 cyfr).
        """
        cleaned = value.replace("-", "").replace(" ", "")
        if not cleaned.isdigit() or len(cleaned) != 10:
            raise ValueError(f"NIP must be 10 digits, got {value!r}")
        return cls(cleaned)

    def __str__(self) -> str:
        return self.root


# ── TypeAdapter — ad-hoc walidacja dla list/dict/set ────────────────────

# TypeAdapter dla listy Decimal
MoneyListAdapter: TypeAdapter[list[Decimal]] = TypeAdapter(list[Decimal])
"""Walidacja listy kwot: TypeAdapter(list[Decimal]).

Użycie:
    prices = MoneyListAdapter.validate_python(["10.50", "20.00", "invalid"])
    # → ValidationError: Input should be a valid decimal
"""

# TypeAdapter dla mapy string→int (np. licznik statusów)
StatusCounterAdapter: TypeAdapter[dict[str, int]] = TypeAdapter(dict[str, int])
"""Walidacja słownika string→int.

Użycie:
    counters = StatusCounterAdapter.validate_python({"NEW": 5, "APPROVED": 3})
    # → {"NEW": 5, "APPROVED": 3}
"""

# TypeAdapter dla zbioru stringów (np. dozwolone role)
RoleSetAdapter: TypeAdapter[set[str]] = TypeAdapter(set[str])
"""Walidacja zbioru stringów.

Użycie:
    roles = RoleSetAdapter.validate_python(["admin", "worker", "admin"])
    # → {"admin", "worker"}
"""


# ── Generic Paginated Response ─────────────────────────────────────────

T = TypeVar("T")


class PaginatedResponse(RootModel[list[T]], Generic[T]):
    """Generic paginated API response z total/page/page_size.

    SUPERMOC Pydantic: Generic + RootModel w jednym.

    Użycie:
        class UserResponse(BaseModel):
            id: str
            name: str

        response = PaginatedResponse[UserResponse](
            root=[UserResponse(id="1", name="Alice")],
            total=1,
            page=1,
            page_size=20,
        )
        # response.root → [UserResponse(id='1', name='Alice')]
        # response.total → 1
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


# ── TypeAdapter dla paginowanych odpowiedzi ────────────────────────────

def paginated_adapter(item_type: type[T]) -> TypeAdapter[PaginatedResponse[T]]:
    """Utwórz TypeAdapter dla PaginatedResponse[T] z konkretnym typem.

    SUPERMOC: TypeAdapter z Generic — pozwala na ad-hoc walidację
    paginowanych odpowiedzi bez pełnego modelu.

    Args:
        item_type: Typ elementu na liście.

    Returns:
        TypeAdapter dla PaginatedResponse[item_type].
    """
    return TypeAdapter(PaginatedResponse[item_type])  # type: ignore[valid-type]


# ── TypeAdapter dla EventStore snapshotów ──────────────────────────────

SnapshotAdapter: TypeAdapter[dict[str, Any]] = TypeAdapter(dict[str, Any])
"""Walidacja snapshotów EventStore.

Użycie:
    snapshot = SnapshotAdapter.validate_json('{"version": 5, "state": {...}}')
"""
"