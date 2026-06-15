"""
AsyncBaseService — bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

Python 3.13t (free-threaded, brak GIL): wywołania synchronicznego sqlite3
są bezpieczne z wielu wątków. Każda operacja DB jest delegowana do wątku
przez ``asyncio.to_thread()``.

Zgodnie z decyzją architektoniczną: rezygnujemy z aiosqlite na rzecz
natywnego sqlite3 + asyncio.to_thread.

Każdy serwis dziedziczy po AsyncBaseService i dostaje automatycznie:
- AsyncDBPool zarządzanie połączeniami
- WAL mode, synchronous=NORMAL
- Automatyczne PRAGMY przy pierwszym połączeniu
- Bezpieczne close()/zamykanie

Usage:
    class MyService(AsyncBaseService):
        def __init__(self, db_path: str) -> None:
            super().__init__(db_path)

        async def query(self) -> list[dict]:
            return await self.fetchall("SELECT * FROM table")
"""

from __future__ import annotations

import asyncio
import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool

logger = get_logger("nexus.db.async_base")


class AsyncBaseService:
    """Bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

    Wszystkie operacje sqlite3 są wykonywane w wątku przez
    ``asyncio.to_thread()`` — Python 3.13t (free-threaded) nie ma GIL,
    więc synchroniczne API nie blokuje pętli zdarzeń.

    Zapewnia:
    - Leniwe połączenie przez AsyncDBPool
    - Automatyczne PRAGMY
    - Bezpieczne zamykanie
    - Row factory (sqlite3.Row)

    Args:
        db_path: Ścieżka do pliku SQLite.
        pool: Opcjonalny AsyncDBPool do współdzielenia (domyślnie globalny).
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
        """Pobierz sync połączenie przez AsyncDBPool (w wątku).

        SUPERMOC: Połączenie jest współdzielone między serwisami
        przez globalny AsyncDBPool. ``check_same_thread=False`` pozwala
        na użycie z różnych wątków (free-threaded Python 3.13t).

        Po pobraniu nowego połączenia, woła ``_on_connect()`` hook
        dla dodatkowych PRAGM subklas.

        Returns:
            sqlite3.Connection z ustawionymi PRAGMAMI.
        """
        if self._conn is None:
            self._conn = await asyncio.to_thread(
                self._pool.get_conn,
                self._db_path,
                enable_extensions=self._enable_extensions,
                sqlcipher_key=self._sqlcipher_key,
                wal_mode=self._wal_mode,
            )
            # SUPERMOC: Hook dla subklas do dodania dodatkowych PRAGM
            await self._on_connect(self._conn)
        return self._conn

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook wołany po uzyskaniu nowego połączenia z pool.

        Nadpisz w podklasie, aby dodać dodatkowe PRAGMY
        (np. cache_size, temp_store, mmap_size) po pobraniu połączenia.

        Args:
            conn: sqlite3.Connection gotowe do użycia.
        """
        pass  # Domyślnie brak dodatkowych PRAGM

    async def execute(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> sqlite3.Cursor:
        """Wykonaj zapytanie SQL (w wątku przez asyncio.to_thread)."""
        conn = await self.get_conn()

        def _sync_execute() -> sqlite3.Cursor:
            if parameters is not None:
                return conn.execute(sql, parameters)
            return conn.execute(sql)

        return await asyncio.to_thread(_sync_execute)

    async def executescript(self, sql: str) -> None:
        """Wykonaj skrypt SQL (multi-statement, w wątku)."""
        conn = await self.get_conn()

        def _sync() -> None:
            conn.executescript(sql)

        await asyncio.to_thread(_sync)

    async def executemany(
        self,
        sql: str,
        parameters: list[tuple[Any, ...]],
    ) -> None:
        """Wykonaj batch INSERT/UPDATE (w wątku)."""
        conn = await self.get_conn()

        def _sync() -> None:
            conn.executemany(sql, parameters)

        await asyncio.to_thread(_sync)

    async def fetchone(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> dict[str, Any] | None:
        """Pobierz jeden wiersz jako słownik (w wątku)."""
        conn = await self.get_conn()

        def _sync_fetch() -> dict[str, Any] | None:
            cursor = conn.execute(sql, parameters or ())
            row = cursor.fetchone()
            return dict(row) if row else None

        return await asyncio.to_thread(_sync_fetch)

    async def fetchall(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> list[dict[str, Any]]:
        """Pobierz wszystkie wiersze jako listę słowników (w wątku)."""
        conn = await self.get_conn()

        def _sync_fetch() -> list[dict[str, Any]]:
            cursor = conn.execute(sql, parameters or ())
            rows = cursor.fetchall()
            return [dict(r) for r in rows]

        return await asyncio.to_thread(_sync_fetch)

    async def commit(self) -> None:
        """Wykonaj commit (w wątku)."""
        if self._conn is not None:
            def _sync() -> None:
                self._conn.commit()
            await asyncio.to_thread(_sync)

    async def rollback(self) -> None:
        """Wykonaj rollback (w wątku)."""
        if self._conn is not None:
            def _sync() -> None:
                self._conn.rollback()
            await asyncio.to_thread(_sync)

    async def close(self) -> None:
        """Zamknij połączenie (w wątku)."""
        if self._conn is not None:
            try:
                def _optimize() -> None:
                    try:
                        self._conn.execute("PRAGMA optimize;")
                    except Exception:
                        pass
                await asyncio.to_thread(_optimize)
            except Exception:
                pass
            await asyncio.to_thread(self._pool.close_conn, self._db_path)
            self._conn = None

    async def __aenter__(self) -> AsyncBaseService:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
