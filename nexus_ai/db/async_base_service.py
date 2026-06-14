"""
AsyncBaseService — bazowa klasa dla serwisów używających aiosqlite.

SUPERMOC: DRY dla async serwisów DB. Każdy serwis dziedziczy po AsyncBaseService
i dostaje automatycznie:
- AsyncDBPool zarządzanie połączeniami
- WAL mode, synchronous=NORMAL
- Automatyczne PRAGMY przy pierwszym połączeniu
- Bezpieczne close()/zamykanie

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 3: AsyncBaseService dla DRY
- Współdzielenie AsyncDBPool między serwisami

Usage:
    class MyService(AsyncBaseService):
        def __init__(self, db_path: str) -> None:
            super().__init__(db_path)

        async def query(self) -> list[dict]:
            conn = await self.get_conn()
            cursor = await conn.execute("SELECT * FROM table")
            return await cursor.fetchall()
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import aiosqlite
from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool

logger = get_logger("nexus.db.async_base")


class AsyncBaseService:
    """Bazowa klasa dla serwisów używających aiosqlite.

    Zapewnia:
    - Leniwe połączenie przez AsyncDBPool
    - Automatyczne PRAGMY
    - Bezpieczne zamykanie
    - Row factory (aiosqlite.Row)
    - Dedicated pool na serwis (lub można użyć globalnego)

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
        self._conn: aiosqlite.Connection | None = None

    async def get_conn(self) -> aiosqlite.Connection:
        """Pobierz async połączenie przez AsyncDBPool.

        SUPERMOC: Połączenie jest współdzielone między serwisami
        przez globalny AsyncDBPool. Po pobraniu nowego połączenia,
        woła ``_on_connect()`` hook dla dodatkowych PRAGM subklas.

        Returns:
            aiosqlite.Connection z ustawionymi PRAGMAMI.
        """
        if self._conn is None or self._conn.is_closed():
            self._conn = await self._pool.get_conn(
                self._db_path,
                enable_extensions=self._enable_extensions,
                sqlcipher_key=self._sqlcipher_key,
                wal_mode=self._wal_mode,
            )
            # SUPERMOC: Hook dla subklas do dodania dodatkowych PRAGM
            await self._on_connect(self._conn)
        return self._conn

    async def _on_connect(self, conn: aiosqlite.Connection) -> None:
        """Hook wołany po uzyskaniu nowego połączenia z pool.

        Nadpisz w podklasie, aby dodać dodatkowe PRAGMY
        (np. cache_size, temp_store, mmap_size) po pobraniu połączenia.

        Args:
            conn: aiosqlite.Connection gotowe do użycia.
        """
        pass  # Domyślnie brak dodatkowych PRAGM

    async def execute(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> aiosqlite.Cursor:
        """Wykonaj async zapytanie SQL.

        Args:
            sql: Zapytanie SQL.
            parameters: Parametry bind (krotka lub słownik).

        Returns:
            aiosqlite.Cursor z wynikami.
        """
        conn = await self.get_conn()
        if parameters is not None:
            return await conn.execute(sql, parameters)
        return await conn.execute(sql)

    async def executescript(self, sql: str) -> None:
        """Wykonaj async skrypt SQL (multi-statement).

        Args:
            sql: Skrypt SQL (może zawierać wiele zapytań).
        """
        conn = await self.get_conn()
        await conn.executescript(sql)

    async def executemany(
        self,
        sql: str,
        parameters: list[tuple[Any, ...]],
    ) -> None:
        """Wykonaj async batch INSERT/UPDATE.

        Args:
            sql: SQL z placeholderami.
            parameters: Lista krotek parametrów.
        """
        conn = await self.get_conn()
        await conn.executemany(sql, parameters)

    async def fetchone(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> dict[str, Any] | None:
        """Pobierz jeden wiersz jako słownik."""
        conn = await self.get_conn()
        cursor = await conn.execute(sql, parameters or ())
        row = await cursor.fetchone()
        return dict(row) if row else None

    async def fetchall(
        self,
        sql: str,
        parameters: Any | None = None,
    ) -> list[dict[str, Any]]:
        """Pobierz wszystkie wiersze jako listę słowników."""
        conn = await self.get_conn()
        cursor = await conn.execute(sql, parameters or ())
        rows = await cursor.fetchall()
        return [dict(r) for r in rows]

    async def commit(self) -> None:
        """Wykonaj async commit."""
        if self._conn is not None and not self._conn.is_closed():
            await self._conn.commit()

    async def rollback(self) -> None:
        """Wykonaj async rollback."""
        if self._conn is not None and not self._conn.is_closed():
            await self._conn.rollback()

    async def close(self) -> None:
        """Zamknij połączenie (usuwa z pool)."""
        if self._conn is not None:
            try:
                await self._conn.execute("PRAGMA optimize;")
            except Exception:
                pass
            await self._pool.close_conn(self._db_path)
            self._conn = None

    async def __aenter__(self) -> AsyncBaseService:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
