"""Core types — Result Pattern with proper type narrowing via cast(), PaginatedResponse.

Result[T,E] uses Ok[T,E] + Err[T,E] subclasses with cast()-based type narrowing,
eliminating all type: ignore annotations while keeping mypy strict-mode compliant.
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any, Generic, TypeVar, cast, final

from msgspec import Struct

T = TypeVar("T")
E = TypeVar("E")
U = TypeVar("U")
F = TypeVar("F")


# ── Result Pattern (cast-based type narrowing — zero type: ignores) ──────────


class Result(Generic[T, E]):
    """Either monada — sealed base. Use Result.ok(value) or Result.err(error).

    Uses typing.cast() for type narrowing instead of type: ignore.
    Ok[T,E] and Err[T,E] are the only valid subclasses.
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
            return cast(T, self._value)
        raise ValueError(f"unwrap() on error Result: {self._error}")

    def unwrap_or(self, default: T) -> T:
        return cast(T, self._value) if self._is_ok else default

    def unwrap_err(self) -> E:
        if not self._is_ok:
            return cast(E, self._error)
        raise ValueError(f"unwrap_err() on ok Result: {self._value}")

    def map(self, func: Callable[[T], U]) -> Result[U, E]:
        if self._is_ok:
            return Result.ok(func(cast(T, self._value)))
        return cast(Result[U, E], self)

    def map_err(self, func: Callable[[E], F]) -> Result[T, F]:
        if not self._is_ok:
            return Result.err(func(cast(E, self._error)))
        return cast(Result[T, F], self)

    def and_then(self, func: Callable[[T], Result[U, E]]) -> Result[U, E]:
        if self._is_ok:
            return func(cast(T, self._value))
        return cast(Result[U, E], self)

    def or_else(self, func: Callable[[E], Result[T, F]]) -> Result[T, F]:
        if not self._is_ok:
            return func(cast(E, self._error))
        return cast(Result[T, F], self)

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
        return cast(T, self._value)


@final
class Err(Result[T, E]):
    """Error variant of Result[T, E]."""

    __slots__ = ()

    def __init__(self, *, error: E) -> None:
        super().__init__(error=error, is_ok=False)

    @property
    def error(self) -> E:
        return cast(E, self._error)


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

