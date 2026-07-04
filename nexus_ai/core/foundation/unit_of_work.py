"""Unit of Work -- zarządzanie transakcjami z atomowym zapisem agregatów.

Używa SQLModel Session do zarządzania transakcjami.
Każda operacja biznesowa używa UoW jako kontekstu transakcyjnego.

Usage:
    uow = UnitOfWork(session)
    async with uow:
        repo = uow.repository(Invoice)
        repo.add(invoice)
        # commit automatyczny na exit
"""

from __future__ import annotations

from collections.abc import Callable
from contextlib import asynccontextmanager
from types import TracebackType
from typing import Any, TypeVar

from sqlmodel import Session
from structlog import get_logger

from nexus_ai.core.foundation.base_repository import BaseRepository

logger = get_logger("nexus.services.uow")

T = TypeVar("T")


class UnitOfWork:
    """Koordynuje transakcje i repozytoria.

    Wzorzec Unit of Work gwarantuje atomowość:
    - Wszystkie zmiany w jednej transakcji
    - Rollback przy błędzie
    - Automatyczny commit przy sukcesie
    """
    __slots__ = ("_committed", "_repos", "_session")

    def __init__(self, session: Session) -> None:
        self._session = session
        self._repos: dict[type, BaseRepository[Any]] = {}
        self._committed = False

    def repository(self, model: type[T]) -> BaseRepository[T]:
        """Zwróć repozytorium dla modelu, tworząc je leniwie."""
        if model not in self._repos:
            self._repos[model] = BaseRepository(self._session, model)
        return self._repos[model]

    def commit(self) -> None:
        """Zatwierdź transakcję."""
        if not self._committed:
            self._session.commit()
            self._committed = True

    def rollback(self) -> None:
        """Wycofaj transakcję."""
        self._session.rollback()
        self._repos.clear()

    def __enter__(self) -> UnitOfWork:
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> bool:
        if exc_type is None:
            self.commit()
        else:
            self.rollback()
            logger.warning("[UOW] Transaction rolled back: %s", exc_val)
        return False

    async def __aenter__(self) -> UnitOfWork:
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> bool:
        if exc_type is None:
            self.commit()
        else:
            self.rollback()
            logger.warning("[UOW] Transaction rolled back: %s", exc_val)
        return False


@asynccontextmanager
async def uow_context(session_factory: Callable[[], Session]):
    """Async context manager dla Unit of Work z factory sesji.

    Usage:
        async with uow_context(session_factory) as uow:
            repo = uow.repository(Invoice)
            ...
    """
    session = session_factory()
    uow = UnitOfWork(session)
    try:
        yield uow
    except Exception:
        uow.rollback()
        raise
    else:
        uow.commit()
