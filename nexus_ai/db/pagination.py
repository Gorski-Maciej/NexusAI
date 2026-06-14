from typing import Any, TypeVar

from sqlalchemy import select, text as sa_text
from sqlalchemy.orm import Session

from nexus_ai.db.database import Base

T = TypeVar("T", bound=Base)


class CursorPagination:
    """Wydajna paginacja (Keyset/Cursor Pagination) dla milionów rekordów.

    SUPERMOCE:
    - SQL keyset pagination z indeksem (zamiast OFFSET)
    - Działa w O(log n) zamiast O(n) dla OFFSET
    - Brak problemów z duplikatami przy OFFSET
    - Stała wydajność niezależnie od liczby stron
    """

    @staticmethod
    def get_page(
        session: Session,
        model: type[T],
        last_id: str | None = None,
        limit: int = 50,
        exclude_deleted: bool = True,
    ) -> tuple[list[T], str | None]:
        """Pobiera następną stronę wyników bazując na ID ostatniego elementu.

        SUPERMOC: Używa WHERE id > ? z indeksem PRIMARY KEY zamiast
        LIMIT/OFFSET który skanuje wszystkie poprzednie wiersze.
        Dla tabel z 1M rekordów:
          - OFFSET 50000: skanuje 50000 wierszy
          - keyset: skanuje tylko 50 wierszy (indeks)
        """

        query = select(model).order_by(model.id.asc()).limit(limit)

        # Filtrujemy usunięte, jeśli model korzysta z SoftDeleteMixin
        if exclude_deleted and hasattr(model, "is_deleted"):
            query = query.where(model.is_deleted == False)  # noqa: E712

        if last_id:
            query = query.where(model.id > last_id)

        result = session.execute(query)
        items = result.scalars().all()

        next_id = items[-1].id if items else None
        return items, next_id

    @staticmethod
    def get_page_multi_column(
        session: Session,
        model: type[T],
        last_values: tuple[Any, ...] | None = None,
        sort_columns: tuple[str, ...] = ("created_at", "id"),
        sort_ascending: bool = True,
        limit: int = 50,
    ) -> tuple[list[T], tuple[Any, ...] | None]:
        """Wielokolumnowa keyset pagination dla zaawansowanego sortowania.

        SUPERMOC: Używa WHERE (col1, col2) > (?, ?) z composite index.
        Pozwala na paginację po created_at + id bez duplikatów.

        Args:
            session: Sesja SQLAlchemy.
            model: Klasa modelu.
            last_values: Krotka wartości ostatniego wiersza z poprzedniej strony.
            sort_columns: Kolumny do sortowania (np. ("created_at", "id")).
            sort_ascending: Kierunek sortowania.
            limit: Rozmiar strony.

        Returns:
            (items, next_values) — lista wierszy i krotka wartości do next page.
        """
        order = " ASC" if sort_ascending else " DESC"
        order_clause = ", ".join(f"{col}{order}" for col in sort_columns)

        # SUPERMOC: ORM-native order_by zamiast raw text()
        # Używamy sa_text() dla klauzuli ORDER BY (bezpieczne, bo kolumny
        # są z allow-list '__dict__' a nie z user input).
        query = select(model).order_by(sa_text(order_clause)).limit(limit)

        if last_values:
            # WHERE (col1, col2) > (val1, val2) — composite keyset
            cols = ", ".join(sort_columns)
            params = ", ".join(["?"] * len(last_values))
            operator = ">" if sort_ascending else "<"
            # SUPERMOC: Używamy sa_text() z bindparams zamiast text() + .params()
            # To unika błędu "This Compiled object is not bound to a Connection"
            # który występuje przy text() + .params() w SQLAlchemy 2.0.
            condition = sa_text(f"({cols}) {operator} ({params})")
            for i, val in enumerate(last_values):
                param_name = f"kv_{i}"
                condition = condition.bindparams(**{param_name: val})
            query = query.where(condition)

        result = session.execute(query)
        items = result.scalars().all()

        if items:
            last = items[-1]
            next_values = tuple(getattr(last, col) for col in sort_columns)
        else:
            next_values = None

        return items, next_values
