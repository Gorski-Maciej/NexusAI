"""Testy dla UnitOfWork i BaseRepository."""

from unittest.mock import MagicMock, patch

import pytest

from nexus_ai.core.foundation.base_repository import BaseRepository
from nexus_ai.core.foundation.unit_of_work import UnitOfWork, uow_context


class FakeModel:
    """Fake model for testing."""
    id: int = 0


class TestUnitOfWork:
    """Testy dla UnitOfWork."""

    def test_commit_calls_session_commit(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        uow.commit()
        session.commit.assert_called_once()

    def test_double_commit_only_commits_once(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        uow.commit()
        uow.commit()
        assert session.commit.call_count == 1

    def test_rollback_calls_session_rollback(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        uow.rollback()
        session.rollback.assert_called_once()

    def test_repository_creates_base_repository(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        repo = uow.repository(FakeModel)
        assert isinstance(repo, BaseRepository)
        assert repo._model is FakeModel

    def test_repository_is_cached(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        repo1 = uow.repository(FakeModel)
        repo2 = uow.repository(FakeModel)
        assert repo1 is repo2

    def test_context_manager_commits_on_success(self):
        session = MagicMock()
        with UnitOfWork(session) as uow:
            uow.repository(FakeModel)
        session.commit.assert_called_once()
        session.rollback.assert_not_called()

    def test_context_manager_rollbacks_on_exception(self):
        session = MagicMock()
        try:
            with UnitOfWork(session) as uow:
                uow.repository(FakeModel)
                raise ValueError("test error")
        except ValueError:
            pass
        session.rollback.assert_called_once()
        session.commit.assert_not_called()

    def test_rollback_clears_repos(self):
        session = MagicMock()
        uow = UnitOfWork(session)
        uow.repository(FakeModel)
        assert len(uow._repos) == 1
        uow.rollback()
        assert len(uow._repos) == 0


class TestUnitOfWorkAsync:
    """Testy async UnitOfWork."""

    @pytest.mark.anyio
    async def test_async_context_manager_commits_on_success(self):
        session = MagicMock()
        async with UnitOfWork(session) as uow:
            uow.repository(FakeModel)
        session.commit.assert_called_once()

    @pytest.mark.anyio
    async def test_async_context_manager_rollbacks_on_exception(self):
        session = MagicMock()
        try:
            async with UnitOfWork(session) as uow:
                uow.repository(FakeModel)
                raise ValueError("test error")
        except ValueError:
            pass
        session.rollback.assert_called_once()

    @pytest.mark.anyio
    async def test_uow_context_commits(self):
        factory = MagicMock(return_value=MagicMock())
        async with uow_context(factory) as uow:
            assert isinstance(uow, UnitOfWork)
        factory.return_value.commit.assert_called_once()

    @pytest.mark.anyio
    async def test_uow_context_rollbacks_on_error(self):
        factory = MagicMock(return_value=MagicMock())
        try:
            async with uow_context(factory) as uow:
                raise ValueError("test")
        except ValueError:
            pass
        factory.return_value.rollback.assert_called_once()
