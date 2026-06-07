from typing import TypeVar

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from nexus_ai.db.database import Base

T = TypeVar('T', bound=Base)

class CursorPagination:
    """Wydajna paginacja (Keyset/Cursor Pagination) dla milionów rekordów."""

    @staticmethod
    async def get_page(
        session: AsyncSession,
        model: type[T],
        last_id: str | None = None,
        limit: int = 50,
        exclude_deleted: bool = True
    ) -> tuple[list[T], str | None]:
        """Pobiera następną stronę wyników bazując na ID ostatniego elementu."""

        query = select(model).order_by(model.id.asc()).limit(limit)

        # Filtrujemy usunięte, jeśli model korzysta z SoftDeleteMixin
        if exclude_deleted and hasattr(model, 'is_deleted'):
            query = query.where(model.is_deleted == False)  # noqa: E712

        if last_id:
            query = query.where(model.id > last_id)

        result = await session.execute(query)
        items = result.scalars().all()

        next_id = items[-1].id if items else None
        return items, next_id
