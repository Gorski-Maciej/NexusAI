"""BaseService[T, CreateDTO] -- generyczny CRUD dla wszystkich modeli SQLModel.

Eliminuje ~4 700 linii powtarzalnego kodu CRUD w serwisach.
Wystarczy: class InvoiceService(BaseService[Invoice, InvoiceCreate]): pass
Zyskuje create(), get(), update(), delete(), list(), count(), exists(), paginate().

BaseService deleguje count/exists/paginate do BaseRepository aby wyeliminować
duplikację tych samych implementacji w obu klasach.
"""

from __future__ import annotations

from typing import Any, TypeVar

from msgspec import Struct, to_builtins
from sqlmodel import Session, SQLModel, select

from nexus_ai.core.foundation.base_repository import BaseRepository
from nexus_ai.core.types import PaginatedResponse

T = TypeVar("T", bound=SQLModel)
CreateDTO = TypeVar("CreateDTO", bound=Struct)
UpdateDTO = TypeVar("UpdateDTO", bound=Struct)


class BaseService[T: SQLModel, CreateDTO: Struct, UpdateDTO: Struct]:
    """Generyczny serwis CRUD -- sync (dopasowany do istniejącego kodu SQLModel).

    Zastępuje 15+ osobnych implementacji. Używa sync Session (nie AsyncSession)
    bo tak działa istniejący kod: ``db/repository.py`` używa ``session.flush()``.

    Metody count(), exists(), paginate() delegują do wewnętrznego BaseRepository
    eliminując ~35 linii zduplikowanego kodu.
    """

    __slots__ = ("_session", "_model", "_repo")

    def __init__(self, session: Session, model: type[T] | None = None) -> None:
        self._session = session
        self._model = model or self._infer_model()
        self._repo: BaseRepository[T] | None = None

    @property
    def _repository(self) -> BaseRepository[T]:
        """Lazy-inicjalizowany BaseRepository do metod współdzielonych."""
        if self._repo is None:
            self._repo = BaseRepository(self._session, self._model)
        return self._repo

    @classmethod
    def _infer_model(cls) -> type[T]:
        """Wywnioskuj model z nazwy klasy (np. InvoiceService -> Invoice)."""
        name = cls.__name__.replace("Service", "").replace("Repository", "")
        from nexus_ai.db.models import Base

        for mapper in Base.registry.mappers:
            if mapper.class_.__name__ == name:
                return mapper.class_
        raise TypeError(f"Cannot infer model for {cls.__name__}. Pass model= explicitly.")

    def create(self, data: CreateDTO | dict[str, Any]) -> T:
        """Utwórz nowy rekord z DTO lub dict."""
        entity = self._model(**data) if isinstance(data, dict) else self._model(**to_builtins(data))
        self._session.add(entity)
        self._session.flush()
        return entity

    def get(self, id_: str) -> T | None:
        """Pobierz rekord po ID."""
        return self._session.get(self._model, id_)

    def list(self, limit: int = 100, offset: int = 0, order_by: str = "id", **filters: Any) -> list[T]:
        """Pobierz rekordy z limitem, offsetem, sortowaniem i filtrami."""
        stmt = select(self._model)
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                stmt = stmt.where(getattr(self._model, key) == value)
        return list(self._session.execute(stmt.order_by(order_by).limit(limit).offset(offset)).scalars().all())

    def update(self, id_: str, data: UpdateDTO | dict[str, Any]) -> T | None:
        """Zaktualizuj rekord po ID z DTO lub dict."""
        if (entity := self.get(id_)) is None:
            return None
        for key, value in (data if isinstance(data, dict) else to_builtins(data)).items():
            if hasattr(entity, key):
                setattr(entity, key, value)
        self._session.flush()
        return entity

    def delete(self, id_: str) -> bool:
        """Usuń rekord po ID. Zwraca True jeśli usunięto."""
        if (entity := self.get(id_)) is None:
            return False
        self._session.delete(entity)
        self._session.flush()
        return True

    # ── Delegowane do BaseRepository (współdzielona implementacja) ──

    def count(self, **filters: Any) -> int:
        """Policz rekordy spełniające filtry. Deleguje do BaseRepository."""
        return self._repository.count(**filters)

    def exists(self, id_: str) -> bool:
        """Sprawdź czy rekord istnieje. Deleguje do BaseRepository."""
        return self._repository.exists(id_)

    def paginate(self, page: int = 1, page_size: int = 20, order_by: str = "id", **filters: Any) -> PaginatedResponse[T]:
        """Paginated list z PaginatedResponse. Deleguje do BaseRepository."""
        return self._repository.paginate(page=page, page_size=page_size, order_by=order_by, **filters)

    def find_one(self, **filters: Any) -> T | None:
        """Znajdź pierwszy rekord spełniający filtry. Deleguje do BaseRepository."""
        return self._repository.find_one(**filters)

    def find_all(self, **filters: Any) -> list[T]:
        """Znajdź wszystkie rekordy spełniające filtry. Deleguje do BaseRepository."""
        return self._repository.find_all(**filters)
