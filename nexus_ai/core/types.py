"""
Core types — PaginatedResponse (Generic msgspec.Struct) and validation helpers.

SUPERMOCE msgspec:
- Struct z typami → zero narzutu walidacji
- Generics przez Generic[T] na Struct
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, Generic, TypeVar

from msgspec import Struct


T = TypeVar("T")


class PaginatedResponse(Struct, Generic[T]):
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


