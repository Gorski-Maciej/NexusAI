"""Core types — Result Pattern, PaginatedResponse (msgspec.Struct)."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any, Generic, TypeVar

from msgspec import Struct

T = TypeVar("T")
E = TypeVar("E")


# ── Result Pattern ────────────────────────────────────────────────────────────
class Result(Generic[T, E]):
    """Either monada — Result.ok(value) lub Result.err(error)."""

    __slots__ = ("_value", "_error", "_is_ok")

    def __init__(self, *, value: T | None = None, error: E | None = None, is_ok: bool = True):
        self._value = value
        self._error = error
        self._is_ok = is_ok

    @classmethod
    def ok(cls, value: T) -> Result[T, E]:
        return cls(value=value, is_ok=True)

    @classmethod
    def err(cls, error: E) -> Result[T, E]:
        return cls(error=error, is_ok=False)

    @property
    def is_ok(self) -> bool:
        return self._is_ok

    @property
    def is_err(self) -> bool:
        return not self._is_ok

    def unwrap(self) -> T:
        if self._is_ok:
            return self._value  # type: ignore[return-value]
        raise ValueError(f"unwrap() on error Result: {self._error}")

    def unwrap_or(self, default: T) -> T:
        return self._value if self._is_ok else default  # type: ignore[return-value]

    def unwrap_err(self) -> E:
        if not self._is_ok:
            return self._error  # type: ignore[return-value]
        raise ValueError(f"unwrap_err() on ok Result: {self._value}")

    def map(self, func: Callable[[T], Any]) -> Result[Any, E]:
        return Result.ok(func(self._value)) if self._is_ok else self  # type: ignore[return-value]

    def map_err(self, func: Callable[[E], Any]) -> Result[T, Any]:
        return Result.err(func(self._error)) if not self._is_ok else self  # type: ignore[return-value]

    def and_then(self, func: Callable[[T], Result[Any, E]]) -> Result[Any, E]:
        return func(self._value) if self._is_ok else self  # type: ignore[return-value]

    def or_else(self, func: Callable[[E], Result[T, Any]]) -> Result[T, Any]:
        return func(self._error) if not self._is_ok else self  # type: ignore[return-value]

    def __bool__(self) -> bool:
        return self._is_ok

    def __repr__(self) -> str:
        return f"Ok({self._value!r})" if self._is_ok else f"Err({self._error!r})"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Result):
            return NotImplemented
        if self._is_ok != other._is_ok:
            return False
        return (self._value == other._value) if self._is_ok else (self._error == other._error)


# ── PaginatedResponse ────────────────────────────────────────────────────────
class PaginatedResponse[T](Struct):
    """Generic paginated API response."""

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

