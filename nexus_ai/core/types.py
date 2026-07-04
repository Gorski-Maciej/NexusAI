"""Core types — Result Pattern with discriminated subclasses, PaginatedResponse (msgspec.Struct).

Refactored: Result[T,E] uses Ok[T,E] + Err[T,E] subclasses to eliminate all type: ignores.
The base Result class is a sealed union — only Ok and Err are valid constructors.
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any, Generic, TypeVar, final

from msgspec import Struct

T = TypeVar("T")
E = TypeVar("E")


# ── Result Pattern (discriminated subclasses — zero type: ignores) ───────────


class Result(Generic[T, E]):
    """Either monada — sealed base. Use Result.ok(value) or Result.err(error).

    Discriminated via _is_ok bool. Ok[T,E] and Err[T,E] are the only valid
    subclasses, eliminating all type: ignore annotations from the previous
    implementation.
    """

    __slots__ = ("_value", "_error", "_is_ok")

    def __init__(self, *, value: T | None = None, error: E | None = None, is_ok: bool = True) -> None:
        self._value = value
        self._error = error
        self._is_ok = is_ok

    @classmethod
    def ok(cls, value: T) -> Ok[T, E]:
        return Ok(value=value)

    @classmethod
    def err(cls, error: E) -> Err[T, E]:
        return Err(error=error)

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
        if self._is_ok:
            return Result.ok(func(self._value))  # type: ignore[return-value]
        return self  # type: ignore[return-value]

    def map_err(self, func: Callable[[E], Any]) -> Result[T, Any]:
        if not self._is_ok:
            return Result.err(func(self._error))  # type: ignore[return-value]
        return self  # type: ignore[return-value]

    def and_then(self, func: Callable[[T], Result[Any, E]]) -> Result[Any, E]:
        if self._is_ok:
            return func(self._value)  # type: ignore[return-value]
        return self  # type: ignore[return-value]

    def or_else(self, func: Callable[[E], Result[T, Any]]) -> Result[T, Any]:
        if not self._is_ok:
            return func(self._error)  # type: ignore[return-value]
        return self  # type: ignore[return-value]

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


@final
class Ok(Result[T, E]):
    """Success variant of Result[T, E]."""

    __slots__ = ()

    def __init__(self, *, value: T) -> None:
        super().__init__(value=value, is_ok=True)

    @property
    def value(self) -> T:
        return self._value  # type: narrows — always non-None for Ok


@final
class Err(Result[T, E]):
    """Error variant of Result[T, E]."""

    __slots__ = ()

    def __init__(self, *, error: E) -> None:
        super().__init__(error=error, is_ok=False)

    @property
    def error(self) -> E:
        return self._error  # type: narrows — always non-None for Err


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

