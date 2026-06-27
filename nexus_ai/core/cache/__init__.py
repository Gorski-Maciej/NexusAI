"""
NexusAI Cache — warstwa cache oparta na diskcache + NATS invalidation.
"""

from __future__ import annotations

import os
import threading
from pathlib import Path
from typing import Any, Callable

import anyio
import diskcache
import msgspec
from structlog import get_logger

from nexus_ai.core.cache.http_client import (
    CachedHttpClient,
    get_cache_stats,
    reset_cache_stats,
    warm_http_cache,
)
from nexus_ai.core.cache.invalidation import (
    invalidate_cache,
    subscribe_cache_invalidation,
)

logger = get_logger("nexus.core.cache")


# ═════════════════════════════════════════════════════════════════════════
# NexusCache — oparty bezpośrednio na diskcache.Cache
# ═════════════════════════════════════════════════════════════════════════


class NexusCache:
    """Cache oparty na diskcache z async wrapperem i msgspec serializacją.

    diskcache zapewnia:
    - SQLite-backed persistence (WAL mode)
    - Wbudowany TTL (expire parameter)
    - Thread-safe
    - LRU eviction

    Args:
        cache_dir: Katalog dla pliku SQLite.
        default_ttl: Domyślny TTL w sekundach.
        size_limit: Maksymalny rozmiar cache w bajtach.
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        default_ttl: int = 300,
        size_limit: int = 2**30,  # 1GB
    ) -> None:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "cache"
        self._cache_dir = Path(cache_dir)
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._cache = diskcache.Cache(
            directory=str(self._cache_dir),
            size_limit=size_limit,
        )
        self._default_ttl = default_ttl

        # Cache stampede protection — per-key anyio.Lock (async)
        self._compute_locks: dict[str, anyio.Lock] = {}
        self._compute_locks_lock = threading.Lock()
        # Cache stampede protection — per-key threading.Lock (sync)
        self._sync_compute_locks: dict[str, threading.Lock] = {}
        self._sync_compute_locks_lock = threading.Lock()

        logger.info(
            "[CACHE] Initialized: dir=%s default_ttl=%s size_limit=%d",
            self._cache_dir,
            default_ttl,
            size_limit,
        )

    # ══════════════════════════════════════════════════════════════════════
    # Core async API
    # ══════════════════════════════════════════════════════════════════════

    async def get(self, key: str) -> Any | None:
        """Pobierz wartość z cache'u."""
        raw = await anyio.to_thread.run_sync(self._cache.get, key)
        if raw is not None:
            try:
                return msgspec.msgpack.decode(raw)
            except Exception:
                return None
        return None

    async def get_many(self, *keys: str) -> list[Any | None]:
        """Pobierz wiele wartości z cache'u (batch)."""
        raw_results = await anyio.to_thread.run_sync(self._cache.get_many, list(keys))
        results = []
        for raw in raw_results:
            if raw is not None:
                try:
                    results.append(msgspec.msgpack.decode(raw))
                except Exception:
                    results.append(None)
            else:
                results.append(None)
        return results

    async def set(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Zapisz wartość w cache'u."""
        effective_ttl = ttl if ttl is not None else self._default_ttl
        try:
            data = msgspec.msgpack.encode(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return
        await anyio.to_thread.run_sync(self._cache.set, key, data, expire=effective_ttl)

    async def set_many(
        self,
        mapping: dict[str, Any],
        ttl: int | None = None,
    ) -> None:
        """Zapisz wiele wartości w cache'u (batch)."""
        effective_ttl = ttl if ttl is not None else self._default_ttl
        serialized: dict[str, bytes] = {}
        for key, value in mapping.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
        if serialized:
            await anyio.to_thread.run_sync(
                self._cache.set_many, serialized, expire=effective_ttl,
            )

    async def delete(self, key: str) -> None:
        """Usuń wartość z cache'u."""
        try:
            await anyio.to_thread.run_sync(self._cache.__delitem__, key)
        except KeyError:
            pass

    async def delete_many(self, *keys: str) -> None:
        """Usuń wiele wartości z cache'u (batch).

        Wydajność: jedna podróż do wątku (zamiast N) przez wrapper.
        """
        if not keys:
            return
        await anyio.to_thread.run_sync(self._delete_many_sync, keys)

    def _delete_many_sync(self, keys: tuple[str, ...]) -> None:
        """Sync wrapper dla delete_many — batch usuwanie w jednym wątku."""
        for key in keys:
            try:
                del self._cache[key]
            except KeyError:
                pass

    async def clear(self, prefix: str | None = None) -> None:
        """Wyczyść cache — całość lub tylko klucze z danym prefixem.

        Wydajność: jedna podróż do wątku (zamiast N) przez wrapper.
        """
        await anyio.to_thread.run_sync(self._clear_sync, prefix)

    def _clear_sync(self, prefix: str | None = None) -> None:
        """Sync wrapper dla clear — batch czyszczenie w jednym wątku."""
        if prefix is None:
            self._cache.clear()
        else:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            for key in list(self._cache.iterkeys()):
                if key.startswith(pattern):
                    try:
                        del self._cache[key]
                    except KeyError:
                        pass

    async def keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy cache z danym prefixem.

        Wydajność: jedna podróż do wątku przez wrapper.
        """
        return await anyio.to_thread.run_sync(self.l1_keys, prefix)

    async def delete_prefix_async(self, prefix: str) -> int:
        """Usuń wszystkie klucze z danym prefixem i zwróć liczbę usuniętych."""
        keys_before = await self.keys(prefix)
        await self.clear(prefix=prefix)
        return len(keys_before)

    # ══════════════════════════════════════════════════════════════════════
    # Sync methods
    # ══════════════════════════════════════════════════════════════════════

    def get_sync(self, key: str) -> Any | None:
        """Sync version: pobierz wartość z cache'u."""
        raw = self._cache.get(key)
        if raw is not None:
            try:
                return msgspec.msgpack.decode(raw)
            except Exception:
                pass
        return None

    def set_sync(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Sync version: zapisz wartość w cache'u."""
        effective_ttl = ttl if ttl is not None else self._default_ttl
        try:
            data = msgspec.msgpack.encode(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return
        self._cache.set(key, data, expire=effective_ttl)

    def delete_sync(self, key: str) -> None:
        """Sync version: usuń z cache'u."""
        try:
            del self._cache[key]
        except KeyError:
            pass

    def clear_l1_sync(self, prefix: str | None = None) -> None:
        """Sync version: czyści cache (odpowiednik poprzedniego clear_l1_sync)."""
        if prefix is None:
            self._cache.clear()
        else:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            for key in list(self._cache.iterkeys()):
                if key.startswith(pattern):
                    try:
                        del self._cache[key]
                    except KeyError:
                        pass

    def delete_prefix_sync(self, prefix: str) -> int:
        """Sync version: usuń wszystkie klucze z danym prefixem."""
        keys_before = self.l1_keys(prefix)
        self.clear_l1_sync(prefix)
        return len(keys_before)

    def size(self) -> int:
        """Zwróć liczbę wpisów w cache."""
        return len(self._cache)

    def l1_keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy z danym prefixem.

        Uwaga: nazwa l1_keys zachowana dla kompatybilności API.
        W nowej architekturze nie ma rozróżnienia L1/L2.
        """
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        if pattern:
            return [k for k in self._cache.iterkeys() if k.startswith(pattern)]
        return list(self._cache.iterkeys())

    # ══════════════════════════════════════════════════════════════════════
    # get_or_compute — async i sync, z cache stampede protection
    # ══════════════════════════════════════════════════════════════════════

    def _get_compute_lock(self, key: str) -> anyio.Lock:
        """Pobierz per-key anyio.Lock dla async stampede protection."""
        max_locks = 10_000
        with self._compute_locks_lock:
            if key not in self._compute_locks:
                if len(self._compute_locks) >= max_locks:
                    for old_key in list(self._compute_locks.keys())[:max_locks // 10]:
                        del self._compute_locks[old_key]
                self._compute_locks[key] = anyio.Lock()
            return self._compute_locks[key]

    def _get_sync_compute_lock(self, key: str) -> threading.Lock:
        """Pobierz per-key threading.Lock dla sync stampede protection."""
        max_locks = 10_000
        with self._sync_compute_locks_lock:
            if key not in self._sync_compute_locks:
                if len(self._sync_compute_locks) >= max_locks:
                    for old_key in list(self._sync_compute_locks.keys())[:max_locks // 10]:
                        del self._sync_compute_locks[old_key]
                self._sync_compute_locks[key] = threading.Lock()
            return self._sync_compute_locks[key]

    async def get_or_compute(
        self,
        key: str,
        compute_func: Callable[[], Any],
        ttl: int | None = None,
    ) -> Any:
        """Async version: pobierz z cache'u lub oblicz i zapisz.

        Z cache stampede protection: per-key anyio.Lock z double-check.
        """
        import inspect

        cached = await self.get(key)
        if cached is not None:
            return cached

        lock = self._get_compute_lock(key)
        async with lock:
            cached = await self.get(key)
            if cached is not None:
                return cached

            if inspect.iscoroutinefunction(compute_func):
                value = await compute_func()
            else:
                value = compute_func()
            await self.set(key, value, ttl=ttl)
            return value

    def get_or_compute_sync(
        self,
        key: str,
        compute_func: Callable[[], Any],
        ttl: int | None = None,
    ) -> Any:
        """Sync version z cache stampede protection."""
        cached = self.get_sync(key)
        if cached is not None:
            return cached

        lock = self._get_sync_compute_lock(key)
        with lock:
            cached = self.get_sync(key)
            if cached is not None:
                return cached

            value = compute_func()
            self.set_sync(key, value, ttl=ttl)
            return value

    # ══════════════════════════════════════════════════════════════════════
    # Cache warming
    # ══════════════════════════════════════════════════════════════════════

    async def warm(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        """Wypełnij cache danymi przy starcie (cold-start protection)."""
        if not entries:
            return 0
        effective_ttl = ttl if ttl is not None else self._default_ttl

        serialized: dict[str, bytes] = {}
        for key, value in entries.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE-WARM] Serialization failed for %s: %s", key, exc)

        if serialized:
            await anyio.to_thread.run_sync(self._cache.set_many, serialized, expire=effective_ttl)

        logger.info("[CACHE-WARM] Loaded %d entries", len(serialized))
        return len(serialized)

    def warm_sync(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        """Sync version: wypełnij cache danymi przy starcie."""
        if not entries:
            return 0
        effective_ttl = ttl if ttl is not None else self._default_ttl

        serialized: dict[str, bytes] = {}
        for key, value in entries.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE-WARM] Serialization failed for %s: %s", key, exc)

        if serialized:
            self._cache.set_many(serialized, expire=effective_ttl)

        logger.info("[CACHE-WARM] Loaded %d entries to cache", len(serialized))
        return len(serialized)

    def close(self) -> None:
        """Zamknij backend i zwolnij zasoby."""
        try:
            self._cache.close()
        except Exception:
            pass

    def __del__(self) -> None:
        self.close()


# ── Global singleton ──────────────────────────────────────────────────────

_default_cache: NexusCache | None = None
_default_cache_lock = threading.Lock()


def get_cache(
    cache_dir: str | Path | None = None,
    default_ttl: int = 300,
    use_l2: bool = True,
    l2_backend_type: str = "disk",
) -> NexusCache:
    """Zwraca globalną instancję NexusCache (singleton z thread-safe init).

    W nowej architekturze backend to bezpośrednio diskcache.Cache.
    Parametry use_l2 i l2_backend_type są zachowane dla kompatybilności API
    — w nowej implementacji nie ma rozróżnienia L1/L2.

    Args:
        cache_dir: Katalog dla cache.
        default_ttl: Domyślny TTL w sekundach.
        use_l2: Zachowane dla kompatybilności.
        l2_backend_type: Zachowane dla kompatybilności.

    Returns:
        Globalna instancja NexusCache.
    """
    global _default_cache
    if _default_cache is None:
        with _default_cache_lock:
            if _default_cache is None:
                _default_cache = NexusCache(
                    cache_dir=cache_dir,
                    default_ttl=default_ttl,
                )
    return _default_cache


__all__ = [
    # NexusCache
    "NexusCache",
    "get_cache",
    # HTTP cache (CachedHttpClient)
    "CachedHttpClient",
    "warm_http_cache",
    "get_cache_stats",
    "reset_cache_stats",
    # NATS distributed cache invalidation
    "invalidate_cache",
    "subscribe_cache_invalidation",
]
