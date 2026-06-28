"""
BaseRepository[T] — generyczne repozytorium CRUD dla wszystkich modeli SQLModel.

Eliminuje powtarzalny boilerplate CRUD w serwisach (create, get, get_all, update, delete).
Wystarczy: class InvoiceRepository(BaseRepository[Invoice]): pass

Usage:
    repo = InvoiceRepository(session)
    invoice = await repo.create(InvoiceCreate(...))
    found = await repo.get(invoice_id)
    updated = await repo.update(invoice_id, InvoiceUpdate(...))
    await repo.delete(invoice_id)
    all_invoices = await repo.get_all()
"""

from typing import Any, Generic, TypeVar

from sqlalchemy import func
from sqlmodel import select, Session, SQLModel

T = TypeVar("T", bound=SQLModel)
CreateDTO = TypeVar("CreateDTO")
UpdateDTO = TypeVar("UpdateDTO")


class BaseRepository(Generic[T]):
    """Generyczne repozytorium CRUD dla modeli SQLModel.

    Zapewnia standardowe operacje: create, get, get_all, update, delete, count.
    Dla zaawansowanych zapytań, użyj bezpośrednio session.execute().
    """

    def __init__(self, session: Session, model: type[T] | None = None) -> None:
        self._session = session
        self._model = model or self._infer_model()

    @classmethod
    def _infer_model(cls) -> type[T]:
        """Wywnioskuj model z nazwy klasy (np. InvoiceRepository -> Invoice)."""
        name = cls.__name__.replace("Repository", "")
        from nexus_ai.db.models import Base

        for mapper in Base.registry.mappers:
            if mapper.class_.__name__ == name:
                return mapper.class_
        raise TypeError(f"Cannot infer model for {cls.__name__}. Pass model= explicitly.")

    def create(self, data: CreateDTO | dict[str, Any]) -> T:
        """Utwórz nowy rekord z danych wejściowych."""
        if isinstance(data, dict):
            entity = self._model(**data)
        else:
            entity = self._model(**data.model_dump())
        self._session.add(entity)
        self._session.flush()
        return entity

    def get(self, id: str) -> T | None:
        """Pobierz rekord po ID."""
        return self._session.get(self._model, id)

    def get_all(self, limit: int = 100, offset: int = 0, order_by: str = "id") -> list[T]:
        """Pobierz wszystkie rekordy z limitem, offsetem i sortowaniem."""
        return (
            self._session.execute(
                select(self._model).order_by(order_by).limit(limit).offset(offset)
            )
            .scalars()
            .all()
        )

    def update(self, id: str, data: UpdateDTO | dict[str, Any]) -> T | None:
        """Zaktualizuj rekord po ID z danych wejściowych."""
        if (entity := self.get(id)) is None:
            return None
        update_data = (
            data if isinstance(data, dict) else getattr(data, "model_dump", lambda: data.__dict__)()
        )
        for key, value in update_data.items():
            if hasattr(entity, key):
                setattr(entity, key, value)
        self._session.flush()
        return entity

    def delete(self, id: str) -> bool:
        """Usuń rekord po ID. Zwraca True jeśli usunięto."""
        if (entity := self.get(id)) is None:
            return False
        self._session.delete(entity)
        self._session.flush()
        return True

    def count(self) -> int:
        """Policz wszystkie rekordy."""
        return self._session.execute(select(func.count()).select_from(self._model)).scalar() or 0

    def exists(self, id: str) -> bool:
        """Sprawdź czy rekord istnieje."""
        return (
            self._session.execute(
                select(self._model).where(self._model.id == id).limit(1)
            ).scalar_one_or_none()
            is not None
        )
