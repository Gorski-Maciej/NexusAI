"""
AsyncDBPool — centralny pool synchronicznych połączeń sqlite3 (free-threaded).

Python 3.13t (free-threaded, brak GIL) pozwala bezpiecznie używać
synchronicznego sqlite3 z wielu wątków. Pool zarządza jednym połączeniem
na plik DB, współdzielonym między serwisami.

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 3: Centralny pool dla sqlite3 (zamiast aiosqlite)
- Wspiera SQLCipher przez PRAGMA key
- Współdzielenie połączeń w free-threaded Python 3.13t

UWAGA: SQLCipher PRAGMA key musi być PIERWSZĄ operacją po connect().
PRAGMY przed PRAGMA key rzucają DatabaseError.

Usage:
    pool = AsyncDBPool()
    conn = pool.get_conn("app_data/databases/nexus_oltp.db")
    cursor = conn.execute("SELECT 1")
    rows = cursor.fetchall()
"""

from __future__ import annotations

import sqlite3
from typing import Any


# ── AsyncDBPool ──────────────────────────────────────────────────────────


class AsyncDBPool:
    """Centralny pool sync połączeń sqlite3.

    Zarządza jednym połączeniem na ścieżkę pliku DB.
    WSZYSTKIE metody są SYNCHRONICZNE — callery używają
    ``asyncio.to_thread()`` dla async wrappera (free-threaded safe).

    SUPERMOCE:
    - Współdzielenie połączeń między serwisami
    - Automatyczne PRAGMY przy pierwszym połączeniu
    - Leniwe tworzenie — połączenie tworzone przy pierwszym użyciu
    - Bezpieczne zamykanie wszystkich połączeń
    - Wsparcie dla SQLCipher (PRAGMA key FIRST!)
    - check_same_thread=False dla free-threaded Python 3.13t
    """

    def __init__(self) -> None:
        self._connections: dict[str, sqlite3.Connection] = {}
        self._closed = False

    def get_conn(
        self,
        db_path: str,
        *,
        row_factory: type[sqlite3.Row] | None = None,
        wal_mode: bool = True,
        synchronous: str = "NORMAL",
        sqlcipher_key: str | None = None,
        enable_extensions: bool = False,
    ) -> sqlite3.Connection:
        """Pobierz synchroniczne połączenie dla ścieżki DB.

        Python 3.13t (free-threaded): ``check_same_thread=False`` pozwala
        współdzielić połączenie między wątkami bez GIL.

        SUPERMOC: SQLCipher PRAGMA key jest ustawiany PIERWSZY,
        zaraz po connect(), przed wszystkimi innymi PRAGMAMI.

        Args:
            db_path: Ścieżka do pliku SQLite.
            row_factory: Row factory (domyślnie None = sqlite3.Row).
            wal_mode: Włącz WAL mode.
            synchronous: Tryb synchronizacji.
            sqlcipher_key: Opcjonalny klucz SQLCipher.
            enable_extensions: Włącz ładowanie rozszerzeń (sqlite-vec).

        Returns:
            sqlite3.Connection z ustawionymi PRAGMAMI.
        """
        if self._closed:
            raise RuntimeError("AsyncDBPool has been closed")

        if db_path not in self._connections or self._is_closed(db_path):
            conn = sqlite3.connect(db_path, check_same_thread=False)

            # ── 🔴 SUPERMOC: SQLCipher PRAGMA key FIRST! ─────────────
            # SQLCipher wymaga PRAGMA key jako PIERWSZEJ operacji po connect().
            if sqlcipher_key:
                key_hex = sqlcipher_key.encode("utf-8").hex()
                conn.execute(f"PRAGMA key = x'{key_hex}';")
                conn.execute("PRAGMA cipher_page_size = 4096;")
                conn.execute("PRAGMA kdf_iter = 64000;")

            # SUPERMOC: Ładowanie rozszerzeń (sqlite-vec)
            if enable_extensions:
                conn.execute("PRAGMA enable_load_extension = ON;")

            # Row factory — domyślnie sqlite3.Row (dict-like dostęp)
            if row_factory is None:
                conn.row_factory = sqlite3.Row
            else:
                conn.row_factory = row_factory

            # SUPERMOC: WAL mode dla współbieżności
            if wal_mode:
                conn.execute("PRAGMA journal_mode=WAL;")

            # SUPERMOC: Synchronous NORMAL
            conn.execute(f"PRAGMA synchronous={synchronous};")

            self._connections[db_path] = conn

        return self._connections[db_path]

    def _is_closed(self, db_path: str) -> bool:
        """Sprawdź czy połączenie jest zamknięte."""
        conn = self._connections.get(db_path)
        if conn is None:
            return True
        try:
            conn.execute("SELECT 1")
            return False
        except (sqlite3.ProgrammingError, sqlite3.OperationalError):
            return True

    def close_all(self) -> None:
        """Zamknij wszystkie połączenia."""
        self._closed = True
        for db_path, conn in list(self._connections.items()):
            try:
                conn.close()
            except Exception:
                pass
        self._connections.clear()

    def close_conn(self, db_path: str) -> None:
        """Zamknij połączenie dla konkretnej ścieżki."""
        conn = self._connections.pop(db_path, None)
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass

    def __len__(self) -> int:
        return len(self._connections)


# ── Global singleton ─────────────────────────────────────────────────────

_default_pool: AsyncDBPool | None = None


def get_async_db_pool() -> AsyncDBPool:
    """Zwróć globalną instancję AsyncDBPool."""
    global _default_pool
    if _default_pool is None:
        _default_pool = AsyncDBPool()
    return _default_pool
