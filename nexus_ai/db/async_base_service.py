"""
AsyncBaseService — bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

Python 3.13t (free-threaded): synchroniczne sqlite3 bezpieczne z wielu wątków.
Używa @sync_wrapper dekoratora zamiast 7× powtarzania anyio.to_thread.run_sync().
"""

from __future__ import annotations

from functools import wraps
from pathlib import Path
from typing import Any, Callable

import anyio
import sqlite3
from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool

logger = get_logger("nexus.db.async_base")


def sync_wrapper(func: Callable[..., R]) -> Callable[..., Any]:
    """Dekorator: wykonuje synchroniczną funkcję DB w wątku przez anyio.

    Eliminuje boilerplate: zamiast 7× ``def _sync() + await anyio.to_thread.run_sync()``
    wystarczy jeden @sync_wrapper na metodę.

    Automatycznie pobiera połączenie przez ``self.get_conn()`` i przekazuje
    jako pierwszy argument ``conn`` do wrapped funkcji.
    """

    @wraps(func)
    async def wrapper(self, *args: Any, **kwargs: Any) -> Any:
        conn = await self.get_conn()
        return await anyio.to_thread.run_sync(func, self, conn, *args, **kwargs)

    return wrapper


class AsyncBaseService:
    """Bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

    Wszystkie operacje sqlite3 wykonywane w wątku przez ``anyio.to_thread.run_sync()``
    — Python 3.13t (free-threaded) nie ma GIL, więc synchroniczne API nie blokuje.

    Args:
        db_path: Ścieżka do pliku SQLite.
        pool: Opcjonalny AsyncDBPool (domyślnie globalny).
        enable_extensions: Włącz ładowanie rozszerzeń (sqlite-vec).
        sqlcipher_key: Opcjonalny klucz SQLCipher.
        wal_mode: Włącz WAL mode (domyślnie True).
    """

    def __init__(
        self,
        db_path: str | Path,
        *,
        pool: Any = None,
        enable_extensions: bool = False,
        sqlcipher_key: str | None = None,
        wal_mode: bool = True,
    ) -> None:
        self._db_path = str(db_path)
        self._pool = pool or get_async_db_pool()
        self._enable_extensions = enable_extensions
        self._sqlcipher_key = sqlcipher_key
        self._wal_mode = wal_mode
        self._conn: sqlite3.Connection | None = None

    async def get_conn(self) -> sqlite3.Connection:
        """Pobierz sync połączenie przez AsyncDBPool (w wątku)."""
        if self._conn is None:
            self._conn = await anyio.to_thread.run_sync(
                self._pool.get_conn,
                self._db_path,
                enable_extensions=self._enable_extensions,
                sqlcipher_key=self._sqlcipher_key,
                wal_mode=self._wal_mode,
            )
            await self._on_connect(self._conn)
        return self._conn

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook dla subklas do dodania dodatkowych PRAGM po pobraniu połączenia."""

    @sync_wrapper
    def _execute(
        self, conn: sqlite3.Connection, sql: str, parameters: Any = None
    ) -> sqlite3.Cursor:
        return conn.execute(sql, parameters) if parameters is not None else conn.execute(sql)

    @sync_wrapper
    def _executescript(self, conn: sqlite3.Connection, sql: str) -> None:
        conn.executescript(sql)

    @sync_wrapper
    def _executemany(
        self, conn: sqlite3.Connection, sql: str, parameters: list[tuple[Any, ...]]
    ) -> None:
        conn.executemany(sql, parameters)

    @sync_wrapper
    def _fetchone(
        self, conn: sqlite3.Connection, sql: str, parameters: Any = None
    ) -> dict[str, Any] | None:
        if (row := conn.execute(sql, parameters or ()).fetchone()) is not None:
            return dict(row)
        return None

    @sync_wrapper
    def _fetchall(
        self, conn: sqlite3.Connection, sql: str, parameters: Any = None
    ) -> list[dict[str, Any]]:
        return [dict(r) for r in conn.execute(sql, parameters or ()).fetchall()]

    async def execute(self, sql: str, parameters: Any = None) -> sqlite3.Cursor:
        """Wykonaj zapytanie SQL (w wątku)."""
        return await self._execute(sql, parameters)

    async def executescript(self, sql: str) -> None:
        """Wykonaj skrypt SQL (multi-statement, w wątku)."""
        await self._executescript(sql)

    async def executemany(self, sql: str, parameters: list[tuple[Any, ...]]) -> None:
        """Wykonaj batch INSERT/UPDATE (w wątku)."""
        await self._executemany(sql, parameters)

    async def fetchone(self, sql: str, parameters: Any = None) -> dict[str, Any] | None:
        """Pobierz jeden wiersz jako słownik (w wątku)."""
        return await self._fetchone(sql, parameters)

    async def fetchall(self, sql: str, parameters: Any = None) -> list[dict[str, Any]]:
        """Pobierz wszystkie wiersze jako listę słowników (w wątku)."""
        return await self._fetchall(sql, parameters)

    async def commit(self) -> None:
        """Wykonaj commit (w wątku)."""
        if self._conn is not None:
            await anyio.to_thread.run_sync(self._conn.commit)

    async def rollback(self) -> None:
        """Wykonaj rollback (w wątku)."""
        if self._conn is not None:
            await anyio.to_thread.run_sync(self._conn.rollback)

    async def close(self) -> None:
        """Zamknij połączenie (w wątku)."""
        if self._conn is not None:
            try:
                await anyio.to_thread.run_sync(self._conn.execute, "PRAGMA optimize;")
            except Exception:
                pass
            await anyio.to_thread.run_sync(self._pool.close_conn, self._db_path)
            self._conn = None

    async def __aenter__(self) -> AsyncBaseService:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
