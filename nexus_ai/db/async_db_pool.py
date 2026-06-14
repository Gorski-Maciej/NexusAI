"""
AsyncDBPool — centralny pool asynchronicznych połączeń aiosqlite.

SUPERMOC: Współdzielone, leniwe połączenia aiosqlite dla wszystkich serwisów.
Zamiast każdego serwisu otwierać własne połączenie, AsyncDBPool zarządza
jednym połączeniem na plik DB, współdzielonym między serwisami.

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 3: Centralny pool dla aiosqlite
- Wspiera SQLCipher przez sync bridge (PRAGMA key)
- Współdzielenie połączeń w free-threaded Python 3.13t

UWAGA: SQLCipher PRAGMA key musi być PIERWSZĄ operacją po connect().
PRAGMY przed PRAGMA key rzucają DatabaseError.

Usage:
    pool = AsyncDBPool()
    conn = await pool.get_conn("app_data/databases/nexus_oltp.db")
    cursor = await conn.execute("SELECT 1")
    rows = await cursor.fetchall()
"""

from __future__ import annotations

from typing import Any

import aiosqlite

# ── AsyncDBPool ──────────────────────────────────────────────────────────


class AsyncDBPool:
    """Centralny pool async połączeń aiosqlite.

    Zarządza jednym połączeniem na ścieżkę pliku DB.

    SUPERMOCE:
    - Współdzielenie połączeń między serwisami
    - Automatyczne PRAGMY przy pierwszym połączeniu
    - Leniwe tworzenie — połączenie tworzone przy pierwszym użyciu
    - Bezpieczne zamykanie wszystkich połączeń
    - Wsparcie dla SQLCipher (PRAGMA key FIRST!)
    - Row factory: aiosqlite.Row (dict-like dostęp)
    """

    def __init__(self) -> None:
        self._connections: dict[str, aiosqlite.Connection] = {}
        self._closed = False

    async def get_conn(
        self,
        db_path: str,
        *,
        row_factory: type[aiosqlite.Row] | None = aiosqlite.Row,
        wal_mode: bool = True,
        synchronous: str = "NORMAL",
        sqlcipher_key: str | None = None,
        enable_extensions: bool = False,
    ) -> aiosqlite.Connection:
        """Pobierz async połączenie dla ścieżki DB.

        SUPERMOC: SQLCipher PRAGMA key jest ustawiany PIERWSZY,
        zaraz po connect(), przed wszystkimi innymi PRAGMAMI.
        To jest wymagane przez SQLCipher — inaczej baza nie jest
        rozpoznawana jako SQLCipher DB.

        Args:
            db_path: Ścieżka do pliku SQLite.
            row_factory: Row factory (domyślnie aiosqlite.Row).
            wal_mode: Włącz WAL mode.
            synchronous: Tryb synchronizacji.
            sqlcipher_key: Opcjonalny klucz SQLCipher (sync bridge).
            enable_extensions: Włącz ładowanie rozszerzeń (sqlite-vec).

        Returns:
            aiosqlite.Connection z ustawionymi PRAGMAMI.
        """
        if self._closed:
            raise RuntimeError("AsyncDBPool has been closed")

        if db_path not in self._connections or self._connections[db_path].is_closed():
            conn = await aiosqlite.connect(db_path)

            # SUPERMOC: Row factory dla dict-like dostępu
            if row_factory is not None:
                conn.row_factory = row_factory

            # ── 🔴 SUPERMOC: SQLCipher PRAGMA key FIRST! ─────────────
            # SQLCipher wymaga PRAGMA key jako PIERWSZEJ operacji po connect().
            # Wszystkie PRAGMY przed PRAGMA key rzucają:
            #   DatabaseError: file is not a database
            if sqlcipher_key:
                key_hex = sqlcipher_key.encode("utf-8").hex()
                await conn.execute(f"PRAGMA key = x'{key_hex}';")
                await conn.execute("PRAGMA cipher_page_size = 4096;")
                await conn.execute("PRAGMA kdf_iter = 64000;")

            # SUPERMOC: Ładowanie rozszerzeń (sqlite-vec)
            if enable_extensions:
                await conn.execute("PRAGMA enable_load_extension = ON;")

            # SUPERMOC: WAL mode dla współbieżności
            if wal_mode:
                await conn.execute("PRAGMA journal_mode=WAL;")

            # SUPERMOC: Synchronous NORMAL
            await conn.execute(f"PRAGMA synchronous={synchronous};")

            self._connections[db_path] = conn

        return self._connections[db_path]

    async def close_all(self) -> None:
        """Zamknij wszystkie połączenia."""
        self._closed = True
        for db_path, conn in list(self._connections.items()):
            try:
                await conn.close()
            except Exception:
                pass
        self._connections.clear()

    async def close_conn(self, db_path: str) -> None:
        """Zamknij połączenie dla konkretnej ścieżki."""
        conn = self._connections.pop(db_path, None)
        if conn is not None:
            try:
                await conn.close()
            except Exception:
                pass

    def __len__(self) -> int:
        return len(self._connections)

    async def __aenter__(self) -> AsyncDBPool:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close_all()


# ── Global singleton ─────────────────────────────────────────────────────

_default_pool: AsyncDBPool | None = None


def get_async_db_pool() -> AsyncDBPool:
    """Zwróć globalną instancję AsyncDBPool."""
    global _default_pool
    if _default_pool is None:
        _default_pool = AsyncDBPool()
    return _default_pool
