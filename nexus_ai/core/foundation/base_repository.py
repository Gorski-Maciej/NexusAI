"""BaseRepository[T] — Generic data access layer for SQLModel entities.

Separates data access from business logic (Repository pattern).
BaseService delegates CRUD to BaseRepository.

Usage:
    repo = BaseRepository[Invoice](session)
    invoice = repo.get_by_id("inv-123")
    all_invoices = repo.find(limit=50, status="PAID")

Reduction: removes duplicate SQL queries across services (~800 lines).
"""

from __future__ import annotations

from typing import Any, TypeVar

from sqlalchemy import func
from sqlmodel import Session, SQLModel, select

from nexus_ai.core.types import PaginatedResponse

T = TypeVar("T", bound=SQLModel)


class BaseRepository[T: SQLModel]:
    """Generic synchronous repository for SQLModel entities.

    Provides standard CRUD operations on a single SQLModel entity.
    All methods use the synchronous SQLAlchemy Session.
    For async usage, wrap calls with anyio.to_thread.run_sync().
    """

    __slots__ = ("_model", "_session")

    def __init__(self, session: Session, model: type[T]) -> None:
        if not hasattr(model, "id"):
            raise TypeError(f"Model {model.__name__} must have an 'id' column for BaseRepository")
        self._session = session
        self._model = model

    # ── Create ──

    def add(self, entity: T) -> T:
        """Add a new entity to the session (flush but don't commit)."""
        self._session.add(entity)
        self._session.flush()
        return entity

    def create(self, **kwargs: Any) -> T:
        """Create and persist a new entity from keyword arguments."""
        entity = self._model(**kwargs)
        self._session.add(entity)
        self._session.flush()
        return entity

    # ── Read ──

    def get_by_id(self, id_: str) -> T | None:
        """Get entity by primary key ID."""
        return self._session.get(self._model, id_)

    def find_one(self, **filters: Any) -> T | None:
        """Find first entity matching filters."""
        stmt = select(self._model).limit(1)
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                stmt = stmt.where(getattr(self._model, key) == value)
        return self._session.execute(stmt).scalar_one_or_none()

    def find(
        self,
        limit: int = 100,
        offset: int = 0,
        order_by: str = "id",
        **filters: Any,
    ) -> list[T]:
        """Find entities with pagination, sorting, and filters."""
        stmt = select(self._model)
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                stmt = stmt.where(getattr(self._model, key) == value)
        order_col = getattr(self._model, order_by, self._model.id)
        if order_by.startswith("-"):
            order_col = getattr(self._model, order_by[1:], self._model.id).desc()
        stmt = stmt.order_by(order_col).limit(limit).offset(offset)
        return list(self._session.execute(stmt).scalars().all())

    def find_all(self, **filters: Any) -> list[T]:
        """Find all entities matching filters (no pagination)."""
        stmt = select(self._model)
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                stmt = stmt.where(getattr(self._model, key) == value)
        return list(self._session.execute(stmt).scalars().all())

    # ── Update ──

    def update(self, entity: T, **kwargs: Any) -> T:
        """Update an existing entity with keyword arguments."""
        for key, value in kwargs.items():
            if hasattr(entity, key):
                setattr(entity, key, value)
        self._session.flush()
        return entity

    def update_by_id(self, id_: str, **kwargs: Any) -> T | None:
        """Update entity by ID with keyword arguments."""
        entity = self.get_by_id(id_)
        if entity is None:
            return None
        return self.update(entity, **kwargs)

    # ── Delete ──

    def delete(self, entity: T) -> bool:
        """Delete an entity from the session."""
        self._session.delete(entity)
        self._session.flush()
        return True

    def delete_by_id(self, id_: str) -> bool:
        """Delete entity by ID. Returns True if deleted."""
        entity = self.get_by_id(id_)
        if entity is None:
            return False
        return self.delete(entity)

    # ── Aggregate ──

    def count(self, **filters: Any) -> int:
        """Count entities matching filters."""
        stmt = select(func.count()).select_from(self._model)
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                stmt = stmt.where(getattr(self._model, key) == value)
        return self._session.execute(stmt).scalar() or 0

    def exists(self, id_: str) -> bool:
        """Check if entity with given ID exists."""
        stmt = select(self._model.id).where(self._model.id == id_).limit(1)
        return self._session.execute(stmt).scalar_one_or_none() is not None

    # ── Paginate ──

    def paginate(
        self,
        page: int = 1,
        page_size: int = 20,
        order_by: str = "id",
        **filters: Any,
    ) -> PaginatedResponse[T]:
        """Paginated query with total count."""
        total = self.count(**filters)
        items = self.find(
            limit=page_size,
            offset=(page - 1) * page_size,
            order_by=order_by,
            **filters,
        )
        return PaginatedResponse.create(items, total, page=page, page_size=page_size)
