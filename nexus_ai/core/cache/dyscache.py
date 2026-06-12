"""
NexusCache — diskcache-based multi-level caching layer.

Zgodnie z aa3fvcx.txt (Punkt 13):
- diskcache (poprawna nazwa, zamiast nieistniejącego dyscache)
- Natywnie asynchroniczny (anyio-native wrapper wokół synchronicznego diskcache)
- Dwupoziomowy: RAM (L1) + SQLite (L2 przez diskcache)
- Integracja z msgspec dla serializacji
- Zero dodatkowej infrastruktury — wykorzystuje istniejące SQLite
"""

from __future__ import annotations

import os
import time
from pathlib import Path
from typing import Any

import anyio
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_dumps_bytes, msgspec_loads

logger = get_logger("nexus.core.cache")

# ── Próba importu diskcache (opcjonalne) ────────────────────────────────

try:
    from diskcache import Cache as _DiskcacheCache
    HAS_DISKCACHE = True
except ImportError:
    HAS_DISKCACHE = False
    logger.warning(
        "[CACHE] diskcache not installed — using simple in-memory fallback. "
        "Install: pip install diskcache"
    )


class NexusCache:
    """Multi-level cache z RAM (L1) + SQLite (L2) przez diskcache.

    Zgodnie z aa3fvcx.txt:
    - Używa diskcache gdy dostępny (zamiast nieistniejącego dyscache)
    - Fallback do prostego słownika w RAM
    - Automatyczna serializacja przez msgspec
    - Ograniczenie rozmiaru L1 RAM przez ``max_size`` (LRU-eviction)

    Args:
        cache_dir: Katalog dla cache'u SQLite (L2).
        default_ttl: Domyślny TTL w sekundach.
        max_size: Maksymalna liczba wpisów w L1 RAM (LRU).
                  ``None`` = brak limitu.
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        default_ttl: int = 300,
        max_size: int | None = 10_000,
    ) -> None:
        self._default_ttl = default_ttl
        self._max_size = max_size
        self._ram_cache: dict[str, tuple[float, bytes]] = {}  # (expiry, serialized_data)
        self._access_order: list[str] = []  # LRU tracking

        if HAS_DISKCACHE and cache_dir is not None:
            cache_path = Path(cache_dir) / "nexus_cache.db"
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            self._diskcache = _DiskcacheCache(str(cache_path))
            logger.info("[CACHE] diskcache initialized: %s", cache_path)
        else:
            self._diskcache = None
            if not HAS_DISKCACHE:
                logger.info("[CACHE] Using in-memory fallback (diskcache not available)")
            else:
                logger.info("[CACHE] Using in-memory fallback (no cache_dir provided)")

    # ── LRU helpers ────────────────────────────────────────────────────

    def _touch(self, key: str) -> None:
        """Oznacz klucz jako ostatnio użyty (dla LRU eviction)."""
        if key in self._access_order:
            self._access_order.remove(key)
        self._access_order.append(key)

    def _enforce_max_size(self) -> None:
        """Usuń najstarsze wpisy z L1 RAM jeśli przekroczono max_size."""
        if self._max_size is None:
            return
        while len(self._ram_cache) > self._max_size and self._access_order:
            oldest = self._access_order.pop(0)
            self._ram_cache.pop(oldest, None)

    async def get(self, key: str) -> Any | None:
        """Pobierz wartość z cache'u.

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        # Sprawdź L1 (RAM)
        if key in self._ram_cache:
            expiry, data = self._ram_cache[key]
            if expiry > time.time():
                self._touch(key)
                try:
                    return msgspec_loads(data)
                except Exception:
                    pass
            else:
                del self._ram_cache[key]

        # Sprawdź L2 (diskcache/SQLite)
        if self._diskcache is not None:
            try:
                raw = await anyio.to_thread.run_sync(self._diskcache.get, key)
                if raw is not None:
                    # Zapisz w L1 (RAM) dla szybszego dostępu
                    data = raw if isinstance(raw, bytes) else str(raw).encode()
                    self._ram_cache[key] = (time.time() + self._default_ttl, data)
                    self._touch(key)
                    self._enforce_max_size()
                    return msgspec_loads(data)
            except Exception as exc:
                logger.debug("[CACHE] L2 get failed for %s: %s", key, exc)

        return None

    async def set(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Zapisz wartość w cache'u.

        Args:
            key: Klucz cache.
            value: Wartość do zapisania (serializowana przez msgspec).
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        effective_ttl = ttl if ttl is not None else self._default_ttl

        try:
            data = msgspec_dumps_bytes(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return

        # Zapisz w L1 (RAM)
        self._ram_cache[key] = (time.time() + effective_ttl, data)
        self._touch(key)
        self._enforce_max_size()

        # Zapisz w L2 (diskcache/SQLite)
        if self._diskcache is not None:
            try:
                # diskcache używa `expire` zamiast `ttl`
                await anyio.to_thread.run_sync(
                    lambda: self._diskcache.set(key, data, expire=effective_ttl),
                )
            except Exception as exc:
                logger.debug("[CACHE] L2 set failed for %s: %s", key, exc)

    def _delete_from_lru(self, key: str) -> None:
        """Usuń klucz z listy LRU (jeśli istnieje)."""
        if key in self._access_order:
            self._access_order.remove(key)

    async def delete(self, key: str) -> None:
        """Usuń wartość z cache'u."""
        self._ram_cache.pop(key, None)
        self._delete_from_lru(key)
        if self._diskcache is not None:
            try:
                await anyio.to_thread.run_sync(self._diskcache.delete, key)
            except Exception as exc:
                logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def delete_many(self, *keys: str) -> None:
        """Usuń wiele wartości z cache'u.

        Args:
            *keys: Klucze do usunięcia.
        """
        for key in keys:
            self._ram_cache.pop(key, None)
            self._delete_from_lru(key)
        if self._diskcache is not None:
            for key in keys:
                try:
                    await anyio.to_thread.run_sync(self._diskcache.delete, key)
                except Exception as exc:
                    logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def clear(self, prefix: str | None = None) -> None:
        """Wyczyść cache — całość lub tylko klucze z danym prefixem.

        Gdy ``prefix`` jest podany, czyści tylko L1 (RAM) klucze zaczynające
        się od prefixu. L2 (diskcache/SQLite) jest pomijane — wygasłe wpisy
        w L2 będą pominięte przy następnym ``get()`` (TTL ich wyczyści).

        Gdy ``prefix`` jest None, czyści cały L1 RAM oraz L2 diskcache.

        Args:
            prefix: Jeśli podany, usuwa tylko klucze zaczynające się od prefixu.
                    Jeśli None, czyści cały cache (L1 + L2).
        """
        if prefix is not None:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            keys_to_delete = [k for k in self._ram_cache if k.startswith(pattern)]
            for k in keys_to_delete:
                del self._ram_cache[k]
                self._delete_from_lru(k)
            # L2 (diskcache/SQLite) nie wspiera prefix-delete, ale
            # nieaktualne wpisy w L2 zostaną pominięte przez TTL.
            return

        self._ram_cache.clear()
        if self._diskcache is not None:
            try:
                await anyio.to_thread.run_sync(self._diskcache.clear)
            except Exception as exc:
                logger.debug("[CACHE] L2 clear failed: %s", exc)

    async def keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy cache z danym prefixem.

        Sprawdza tylko L1 (RAM) — L2 (diskcache/SQLite) nie wspiera
        kwerend po prefiksie.

        Args:
            prefix: Prefiks do filtrowania kluczy (np. ``"risk_threshold:"``).
                    Domyślnie "" = wszystkie klucze.

        Returns:
            Lista kluczy (str) w L1 RAM zaczynających się od prefixu.
        """
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        return [k for k in self._ram_cache if k.startswith(pattern)]

    # ── Sync methods (L1 RAM only — for use in sync services) ─────────────

    def delete_prefix_sync(self, prefix: str) -> int:
        """Sync version: removes all keys with given prefix from L1 (RAM) cache.

        Przydatne dla event-based cache invalidation gdy cache zawiera
        wiele kluczy z tym samym prefixem (np. risk_threshold:{*} -> "risk_threshold:").
        Nie wpływa na L2 (diskcache/SQLite).

        Args:
            prefix: Prefiks kluczy do usunięcia (np. "risk_threshold:").

        Returns:
            Liczba usuniętych wpisów.
        """
        keys_to_delete = [k for k in self._ram_cache if k.startswith(prefix)]
        for k in keys_to_delete:
            del self._ram_cache[k]
            self._delete_from_lru(k)
        return len(keys_to_delete)

    def delete_sync(self, key: str) -> None:
        """Sync version: removes only from L1 (RAM) cache.

        Zgodnie z wzorcem get_sync/set_sync — operuje tylko na L1 RAM.
        Przydatne dla event-based cache invalidation w serwisach
        synchronicznych (DecisionEngine, RiskGuard).

        Args:
            key: Klucz cache do usunięcia.
        """
        self._ram_cache.pop(key, None)
        self._delete_from_lru(key)

    def get_sync(self, key: str) -> Any | None:
        """Sync version: checks only L1 (RAM) cache.

        Przydatne dla synchronicznych serwisów jak CurrencyConverter.
        L2 (diskcache/SQLite) jest pomijane, bo wymaga async.

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        if key in self._ram_cache:
            expiry, data = self._ram_cache[key]
            if expiry > time.time():
                self._touch(key)
                try:
                    return msgspec_loads(data)
                except Exception:
                    pass
            else:
                del self._ram_cache[key]
        return None

    def set_sync(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Sync version: writes only to L1 (RAM) cache.

        Args:
            key: Klucz cache.
            value: Wartość do zapisania (serializowana przez msgspec).
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        effective_ttl = ttl if ttl is not None else self._default_ttl
        try:
            data = msgspec_dumps_bytes(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return
        self._ram_cache[key] = (time.time() + effective_ttl, data)
        self._touch(key)
        self._enforce_max_size()

    async def get_or_compute(
        self,
        key: str,
        compute_func,
        ttl: int | None = None,
    ) -> Any:
        """Pobierz z cache'u lub oblicz i zapisz.

        Args:
            key: Klucz cache.
            compute_func: Async funkcja do obliczenia wartości.
            ttl: TTL w sekundach.

        Returns:
            Wartość z cache'u lub świeżo obliczona.
        """
        cached = await self.get(key)
        if cached is not None:
            return cached

        value = await compute_func()
        await self.set(key, value, ttl=ttl)
        return value


# ── Global singleton ──────────────────────────────────────────────────────

_default_cache: NexusCache | None = None


def get_cache(
    cache_dir: str | Path | None = None,
    default_ttl: int = 300,
) -> NexusCache:
    """Zwraca globalną instancję NexusCache (singleton).

    Args:
        cache_dir: Katalog dla cache'u SQLite.
        default_ttl: Domyślny TTL w sekundach.

    Returns:
        Globalna instancja NexusCache.
    """
    global _default_cache
    if _default_cache is None:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "cache"
        _default_cache = NexusCache(cache_dir=cache_dir, default_ttl=default_ttl)
    return _default_cache
