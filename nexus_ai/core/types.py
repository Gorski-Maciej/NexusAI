"""
Core types -- Result Pattern, PaginatedResponse (Generic msgspec.Struct).

- Result[T, E] -- zamiast rzucania wyjątków dla kontroli przepływu
- Struct z typami -> zero narzutu walidacji
- Generics przez Generic[T] na Struct
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any, TypeVar

from msgspec import Struct

T = TypeVar("T")
E = TypeVar("E")


# ═══════════════════════════════════════════════════════════════════════════
# Result Pattern -- zamiast rzucania wyjątków dla kontroli przepływu
# ═══════════════════════════════════════════════════════════════════════════


class Result(Generic[T, E]):
    """Result[T, E] -- monada Either dla operacji które mogą się nie udać.

    Zamiast rzucania wyjątków (try/except rozrzucony po całym kodzie),
    Result zmusza do jawnego obsłużenia obu przypadków: sukcesu i błędu.

    Użycie:
        ok_result: Result[int, str] = Result.ok(42)
        err_result: Result[int, str] = Result.err("Nie znaleziono")

        # Pattern matching
        match result:
            case Result(status=True, value=v):
                print(f"Success: {v}")
            case Result(status=False, error=e):
                print(f"Error: {e}")

        # Lub przez metody
        if result.is_ok:
            do_something(result.unwrap())
    """

    __slots__ = ("_value", "_error", "_is_ok")

    def __init__(self, *, value: T | None = None, error: E | None = None, is_ok: bool = True):
        self._value = value
        self._error = error
        self._is_ok = is_ok

    @classmethod
    def ok(cls, value: T) -> Result[T, E]:
        """Utwórz Result w stanie sukcesu."""
        return cls(value=value, is_ok=True)

    @classmethod
    def err(cls, error: E) -> Result[T, E]:
        """Utwórz Result w stanie błędu."""
        return cls(error=error, is_ok=False)

    @property
    def is_ok(self) -> bool:
        return self._is_ok

    @property
    def is_err(self) -> bool:
        return not self._is_ok

    def unwrap(self) -> T:
        """Zwróć wartość lub rzuć wyjątkiem jeśli to błąd."""
        if self._is_ok:
            return self._value  # type: ignore[return-value]
        raise ValueError(f"Called unwrap() on error Result: {self._error}")

    def unwrap_or(self, default: T) -> T:
        """Zwróć wartość lub domyślną jeśli to błąd."""
        if self._is_ok:
            return self._value  # type: ignore[return-value]
        return default

    def unwrap_err(self) -> E:
        """Zwróć błąd lub rzuć wyjątkiem jeśli to sukces."""
        if not self._is_ok:
            return self._error  # type: ignore[return-value]
        raise ValueError(f"Called unwrap_err() on ok Result: {self._value}")

    def map(self, func: Callable[[T], Any]) -> Result[Any, E]:
        """Aplikuj funkcję na wartości jeśli Result jest OK."""
        if self._is_ok:
            return Result.ok(func(self._value))
        return self  # type: ignore[return-value]

    def map_err(self, func: Callable[[E], Any]) -> Result[T, Any]:
        """Aplikuj funkcję na błędzie jeśli Result jest Err."""
        if not self._is_ok:
            return Result.err(func(self._error))
        return self  # type: ignore[return-value]

    def and_then(self, func: Callable[[T], Result[Any, E]]) -> Result[Any, E]:
        """Chain: jeśli OK, aplikuj funkcję zwracającą Result."""
        if self._is_ok:
            return func(self._value)
        return self  # type: ignore[return-value]

    def or_else(self, func: Callable[[E], Result[T, Any]]) -> Result[T, Any]:
        """Chain: jeśli Err, aplikuj funkcję naprawczą."""
        if not self._is_ok:
            return func(self._error)
        return self  # type: ignore[return-value]

    def __bool__(self) -> bool:
        return self._is_ok

    def __repr__(self) -> str:
        if self._is_ok:
            return f"Ok({self._value!r})"
        return f"Err({self._error!r})"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Result):
            return NotImplemented
        if self._is_ok != other._is_ok:
            return False
        if self._is_ok:
            return self._value == other._value
        return self._error == other._error


# Alias dla często używanych errorów
DomainError = str  # Prosty błąd domenowy jako string
ValidationError = str  # Błąd walidacji
NotFound = str  # Zasób nie znaleziony


class PaginatedResponse[T](Struct):
    """Generic paginated API response z total/page/page_size.

    Użycie:
        response = PaginatedResponse[str](root=["a", "b"], total=10, page=1, page_size=20)
    """

    root: list[T] = []
    total: int = 0
    page: int = 1
    page_size: int = 20

    @property
    def total_pages(self) -> int:
        return (self.total + self.page_size - 1) // self.page_size if self.page_size > 0 else 0

    @property
    def has_next(self) -> bool:
        return self.page < self.total_pages

    @property
    def has_prev(self) -> bool:
        return self.page > 1

    @classmethod
    def create(cls, items: list[T], total: int, page: int = 1, page_size: int = 20) -> PaginatedResponse[T]:
        if page < 1 or page_size < 1 or total < 0:
            raise ValueError(f"Invalid pagination: page={page}, page_size={page_size}, total={total}")
        return cls(root=items, total=total, page=page, page_size=page_size)


