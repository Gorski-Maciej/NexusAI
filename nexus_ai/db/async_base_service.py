"""
AsyncBaseService — bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

Python 3.13t (free-threaded): synchroniczne sqlite3 bezpieczne z wielu wątków.
Używa jednej generycznej metody ``sql()`` zamiast 8 osobnych (execute, executescript,
executemany, fetchone, fetchall) — match/case dispatch na typie zapytania.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import anyio
import sqlite3
from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool

logger = get_logger("nexus.db.async_base")


class AsyncBaseService:
    """Bazowa klasa dla serwisów DB (sync sqlite3 + async wrapper).

    Jedna generyczna metoda ``sql()`` zamiast 8 osobnych:
    - execute, executescript, executemany, fetchone, fetchall.
    - match/case dispatch na pierwszym słowie SQL.

    Args:
        db_path: Ścieżka do pliku SQLite.
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
        if self._conn is None:
            self._conn = await anyio.to_thread.run_sync(
                self._pool.get_conn, self._db_path,
                enable_extensions=self._enable_extensions,
                sqlcipher_key=self._sqlcipher_key, wal_mode=self._wal_mode,
            )
            await self._on_connect(self._conn)
        return self._conn

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        pass

    async def sql(self, sql: str, params: Any = None, mode: str = "auto") -> Any:
        """Generyczna metoda SQL — match/case dispatch.

        Args:
            sql: Zapytanie SQL.
            params: Parametry (None, tuple, list[tuple] dla executemany).
            mode: "auto" (dispatch po typie), "execute", "script",
                  "many", "one" (fetchone), "all" (fetchall).

        Returns:
            sqlite3.Cursor, dict, list[dict] lub None w zależności od mode.
        """
        conn = await self.get_conn()

        async def _sync() -> Any:
            effective_mode = mode
            if effective_mode == "auto":
                match sql.strip().upper().split():
                    case ["SELECT" | "PRAGMA" as kw, *_]:
                        effective_mode = "all" if kw == "SELECT" else "execute"
                    case ["INSERT" | "REPLACE", *_] if isinstance(params, list):
                        effective_mode = "many"
                    case _:
                        effective_mode = "execute"

            match effective_mode:
                case "execute":
                    return conn.execute(sql, params) if params else conn.execute(sql)
                case "script":
                    conn.executescript(sql)
                    return None
                case "many":
                    return conn.executemany(sql, params)
                case "one":
                    if (row := conn.execute(sql, params or ()).fetchone()) is not None:
                        return dict(row)
                    return None
                case "all":
                    return [dict(r) for r in conn.execute(sql, params or ()).fetchall()]
            return None

        return await anyio.to_thread.run_sync(_sync)

    # ── Backward-compat helpers ──
    # Mapują stare API (execute, fetchall, fetchone, executemany, executescript)
    # na nową metodę sql() z odpowiednim trybem

    async def execute(self, sql: str, params: Any = None) -> Any:
        return await self.sql(sql, params=params, mode="execute")

    async def fetchall(self, sql: str, params: Any = None) -> list[dict[str, Any]]:
        return await self.sql(sql, params=params, mode="all") or []

    async def fetchone(self, sql: str, params: Any = None) -> dict[str, Any] | None:
        return await self.sql(sql, params=params, mode="one")

    async def executemany(self, sql: str, params: list[Any]) -> Any:
        return await self.sql(sql, params=params, mode="many")

    async def executescript(self, sql: str) -> None:
        await self.sql(sql, mode="script")

    async def commit(self) -> None:
        if self._conn is not None:
            await anyio.to_thread.run_sync(self._conn.commit)

    async def rollback(self) -> None:
        if self._conn is not None:
            await anyio.to_thread.run_sync(self._conn.rollback)

    async def close(self) -> None:
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
