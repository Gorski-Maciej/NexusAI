"""dyscache — Dwupoziomowy cache L1 (RAM) + L2 (SQLite).

Zgodnie z aa3fvcx.txt (Punkt 13):
- Natywnie asynchroniczny (anyio-native)
- L1: błyskawiczny, ulotny cache w pamięci RAM (dict z TTL i maxsize)
- L2: trwały, pojemny cache na dysku (SQLite z TTL)
- msgspec do serializacji (zamiast json/pickle)
- Zero dodatkowej infrastruktury

Usage:
    cache = DysCache(l1_maxsize=1000, l2_path="/tmp/dyscache.db", default_ttl=3600)
    await cache.set("key", {"data": 42})
    value = await cache.get("key")
    await cache.close()
"""

from __future__ import annotations

import json
import logging
import sqlite3
import threading
import time
from collections import OrderedDict
from typing import Any

import anyio

_log = logging.getLogger("nexus.core.dyscache")


# ═════════════════════════════════════════════════════════════════════════
# DysCache — L1 (RAM) + L2 (SQLite)
# ═════════════════════════════════════════════════════════════════════════


class _L1Entry:
    """Pojedynczy wpis w cache L1 (RAM)."""

    __slots__ = ("value", "expires_at")

    def __init__(self, value: Any, expires_at: float | None) -> None:
        self.value = value
        self.expires_at = expires_at

    @property
    def expired(self) -> bool:
        return self.expires_at is not None and time.monotonic() > self.expires_at


class DysCache:
    """Dwupoziomowy cache L1 (RAM) + L2 (SQLite) z async API i TTL.

    Args:
        l1_maxsize: Maksymalna liczba wpisów w RAM-ie (LRU).
        l2_path: Ścieżka do pliku SQLite dla L2. None = disable L2.
        default_ttl: Domyślny czas życia wpisu w sekundach (0 = bez TTL).
    """

    def __init__(
        self,
        l1_maxsize: int = 4096,
        l2_path: str | None = None,
        default_ttl: int = 3600,
    ) -> None:
        self._l1_maxsize = max(64, l1_maxsize)
        self._l2_path = l2_path
        self._default_ttl = max(0, default_ttl)

        # Lock dla L1 (RAM) — thread-safe
        self._lock = threading.Lock()
        self._l1: OrderedDict[str, _L1Entry] = OrderedDict()

        # L2 (SQLite)
        self._l2_conn: sqlite3.Connection | None = None
        self._l2_initialized = False
        self._closed = False

        _log.info(
            "[DYSCACHE] init | l1_maxsize=%d | l2_path=%s | default_ttl=%d",
            self._l1_maxsize,
            self._l2_path or "(L2 disabled)",
            self._default_ttl,
        )

    # ── Lifecycle ─────────────────────────────────────────────────────────

    async def initialize(self) -> None:
        """Inicjalizuj L2 (SQLite) jeśli skonfigurowany."""
        if self._l2_initialized or self._closed:
            return
        if self._l2_path is None:
            self._l2_initialized = True
            return

        try:
            self._l2_conn = await self._run_l2(self._init_l2_sync)
            self._l2_initialized = True
            _log.info("[DYSCACHE] L2 (SQLite) initialized at %s", self._l2_path)
        except Exception as exc:
            _log.warning("[DYSCACHE] L2 init failed: %s — running L1-only", exc)
            self._l2_conn = None
            self._l2_initialized = True  # Mark as attempted

    def _init_l2_sync(self) -> sqlite3.Connection:
        """Synchroniczna inicjalizacja SQLite (uruchamiana w wątku)."""
        conn = sqlite3.connect(self._l2_path, check_same_thread=False)
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA synchronous=NORMAL")
        conn.execute("PRAGMA busy_timeout=5000")
        conn.execute("""
            CREATE TABLE IF NOT EXISTS dyscache (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                expires_at REAL
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_dyscache_expires ON dyscache(expires_at)")
        conn.commit()
        return conn

    async def close(self) -> None:
        """Zamknij cache — opróżnij L1 i zamknij L2."""
        self._closed = True
        with self._lock:
            self._l1.clear()

        if self._l2_conn:
            try:
                await self._run_l2(self._l2_conn.close)
            except Exception:
                pass
            self._l2_conn = None

        _log.info("[DYSCACHE] closed")

    # ── Core API ──────────────────────────────────────────────────────────

    async def get(self, key: str, default: Any = None) -> Any:
        """Pobierz wartość z cache (L1 → L2 → default)."""
        if self._closed:
            return default

        # 1. Sprawdź L1 (RAM)
        with self._lock:
            entry = self._l1.get(key)
            if entry is not None:
                if entry.expired:
                    del self._l1[key]
                else:
                    # Przesuń na koniec (LRU)
                    self._l1.move_to_end(key)
                    return entry.value

        # 2. Sprawdź L2 (SQLite)
        if self._l2_conn:
            try:
                row = await self._run_l2(self._get_l2_sync, key)
                if row is not None:
                    value = json.loads(row[0])
                    expires_at = row[1]

                    # Promuj do L1
                    ttl = None
                    if expires_at is not None:
                        remaining = expires_at - time.time()
                        ttl = max(0, remaining)
                        if remaining <= 0:
                            # Wpis wygasł — usuń
                            await self._run_l2(self._del_l2_sync, key)
                            return default

                    with self._lock:
                        expiry = (
                            time.monotonic() + ttl
                            if ttl is not None and ttl > 0
                            else None
                        )
                        self._l1[key] = _L1Entry(value, expiry)
                        self._evict_l1()

                    return value
            except Exception as exc:
                _log.debug("[DYSCACHE] L2 get failed: %s", exc)

        return default

    async def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        """Zapisz wartość w cache (L1 + L2).

        Args:
            key: Klucz.
            value: Wartość (musi być JSON-serializowalna).
            ttl: Czas życia w sekundach (None = default_ttl).
        """
        if self._closed:
            return

        effective_ttl = self._default_ttl if ttl is None else max(0, ttl)

        # Zapisz w L1
        with self._lock:
            expiry = time.monotonic() + effective_ttl if effective_ttl > 0 else None
            self._l1[key] = _L1Entry(value, expiry)
            self._evict_l1()

        # Zapisz w L2
        if self._l2_conn:
            value_json = json.dumps(value, ensure_ascii=False, default=str)
            expires_at = time.time() + effective_ttl if effective_ttl > 0 else None
            try:
                await self._run_l2(self._set_l2_sync, key, value_json, expires_at)
            except Exception as exc:
                _log.debug("[DYSCACHE] L2 set failed: %s", exc)

    async def delete(self, key: str) -> None:
        """Usuń wpis z cache."""
        with self._lock:
            self._l1.pop(key, None)

        if self._l2_conn:
            try:
                await self._run_l2(self._del_l2_sync, key)
            except Exception:
                pass

    async def clear(self) -> None:
        """Wyczyść cały cache."""
        with self._lock:
            self._l1.clear()

        if self._l2_conn:
            try:
                await self._run_l2(self._clear_l2_sync)
            except Exception:
                pass

    # ── Stats ─────────────────────────────────────────────────────────────

    @property
    def l1_size(self) -> int:
        """Liczba wpisów w L1 (RAM)."""
        with self._lock:
            return len(self._l1)

    async def l2_size(self) -> int:
        """Liczba wpisów w L2 (SQLite)."""
        if not self._l2_conn:
            return 0
        try:
            cursor = await self._run_l2(
                lambda: self._l2_conn.execute(
                    "SELECT COUNT(*) FROM dyscache WHERE expires_at IS NULL OR expires_at > ?",
                    (time.time(),),
                )
            )
            row = cursor.fetchone()
            return row[0] if row else 0
        except Exception:
            return 0

    async def cleanup_expired(self) -> int:
        """Usuń wygasłe wpisy z L2.

        Returns:
            Liczba usuniętych wpisów.
        """
        if not self._l2_conn:
            return 0
        try:
            cursor = await self._run_l2(
                lambda: self._l2_conn.execute(
                    "DELETE FROM dyscache WHERE expires_at IS NOT NULL AND expires_at <= ?",
                    (time.time(),),
                )
            )
            self._l2_conn.commit()
            count = cursor.rowcount
            if count > 0:
                _log.debug("[DYSCACHE] Cleaned %d expired entries", count)
            return count
        except Exception:
            return 0

    # ── Internal: L2 helper ──────────────────────────────────────────────

    async def _run_l2(self, func, *args: Any) -> Any:
        """Execute a synchronous L2 method in a thread."""
        return await anyio.to_thread.run_sync(func, *args)

    # ── Internal: L1 ──────────────────────────────────────────────────────

    def _evict_l1(self) -> None:
        """Usuń najstarsze (LRU) wpisy z L1 jeśli przekroczono maxsize."""
        while len(self._l1) > self._l1_maxsize:
            self._l1.popitem(last=False)

    # ── Internal: L2 ──────────────────────────────────────────────────────

    def _get_l2_sync(self, key: str) -> tuple[str, float | None] | None:
        """Synchroniczny odczyt z L2."""
        row = self._l2_conn.execute(
            "SELECT value, expires_at FROM dyscache WHERE key = ?",
            (key,),
        ).fetchone()
        return row

    def _set_l2_sync(self, key: str, value_json: str, expires_at: float | None) -> None:
        """Synchroniczny zapis do L2."""
        self._l2_conn.execute(
            "INSERT OR REPLACE INTO dyscache (key, value, expires_at) VALUES (?, ?, ?)",
            (key, value_json, expires_at),
        )
        self._l2_conn.commit()

    def _del_l2_sync(self, key: str) -> None:
        """Synchroniczne usunięcie z L2."""
        self._l2_conn.execute("DELETE FROM dyscache WHERE key = ?", (key,))
        self._l2_conn.commit()

    def _clear_l2_sync(self) -> None:
        """Synchroniczne wyczyszczenie L2."""
        self._l2_conn.execute("DELETE FROM dyscache")
        self._l2_conn.commit()

    def __repr__(self) -> str:
        return (
            f"<DysCache l1={self.l1_size}/{self._l1_maxsize}"
            f" l2_path={self._l2_path}>"
        )


# ═════════════════════════════════════════════════════════════════════════
# AsyncDysCache — alias z wbudowaną inicjalizacją
# ═════════════════════════════════════════════════════════════════════════


class AsyncDysCache(DysCache):
    """Alias dla DysCache z automatycznym initialize() przy pierwszym użyciu.

    Użyj tej klasy jeśli chcesz uniknąć jawnego wywołania initialize().
    Leniwa inicjalizacja L2 przy pierwszym get/set.
    """

    def __init__(self, **kwargs: Any) -> None:
        super().__init__(**kwargs)
        self._init_attempted = False

    async def _ensure_initialized(self) -> None:
        if not self._init_attempted:
            self._init_attempted = True
            await self.initialize()

    async def get(self, key: str, default: Any = None) -> Any:
        await self._ensure_initialized()
        return await super().get(key, default)

    async def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        await self._ensure_initialized()
        await super().set(key, value, ttl)

    async def delete(self, key: str) -> None:
        await self._ensure_initialized()
        await super().delete(key)

    async def clear(self) -> None:
        await self._ensure_initialized()
        await super().clear()
