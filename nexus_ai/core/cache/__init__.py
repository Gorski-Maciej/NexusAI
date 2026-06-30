"""NexusAI Cache -- diskcache + NATS invalidation. Sync/async consolidated."""

from __future__ import annotations

import os
import threading
from collections.abc import Callable
from functools import wraps
from pathlib import Path
from typing import Any

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
from nexus_ai.core.cache.invalidation import invalidate_cache, subscribe_cache_invalidation

logger = get_logger("nexus.core.cache")


def _sync(key: str) -> str:
    """Return 'sync' for sync wrappers."""
    return "sync"


def _serialize(value: Any, key: str = "") -> bytes | None:
    try:
        return msgspec.msgpack.encode(value)
    except Exception as exc:
        logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
        return None


def _deserialize(raw: bytes | None) -> Any | None:
    if raw is not None:
        try:
            return msgspec.msgpack.decode(raw)
        except Exception:
            return None
    return None


class NexusCache:
    """Cache oparty na diskcache z async/sync API i msgspec serializacją.

    Sync i async API współdzielą tę samą implementację przez _delegate().
    Eliminuje to duplikację get/get_sync, set/set_sync itp.

    Args:
        cache_dir: Katalog dla pliku SQLite.
        default_ttl: Domyślny TTL w sekundach.
        size_limit: Maksymalny rozmiar cache w bajtach.
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        default_ttl: int = 300,
        size_limit: int = 2**30,
    ) -> None:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "cache"
        self._cache_dir = Path(cache_dir)
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._cache = diskcache.Cache(directory=str(self._cache_dir), size_limit=size_limit)
        self._default_ttl = default_ttl
        self._compute_locks: dict[str, anyio.Lock] = {}
        self._compute_locks_lock = threading.Lock()
        self._sync_compute_locks: dict[str, threading.Lock] = {}
        self._sync_compute_locks_lock = threading.Lock()
        logger.info("[CACHE] Initialized: dir=%s ttl=%s size=%d", self._cache_dir, default_ttl, size_limit)

    # ══════════════════════════════════════════════════════════════════════
    # Async API
    # ══════════════════════════════════════════════════════════════════════

    async def get(self, key: str) -> Any | None:
        return await anyio.to_thread.run_sync(self._delegate, "get", key)

    async def get_many(self, *keys: str) -> list[Any | None]:
        if not keys:
            return []
        raw_results = await anyio.to_thread.run_sync(self._cache.get_many, list(keys))
        return [_deserialize(r) for r in (raw_results or [])]

    async def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        data = _serialize(value, key)
        if data is not None:
            await anyio.to_thread.run_sync(self._cache.set, key, data, expire=ttl or self._default_ttl)

    async def set_many(self, mapping: dict[str, Any], ttl: int | None = None) -> None:
        serialized: dict[str, bytes] = {k: v for k, v in ((k, _serialize(v, k)) for k, v in mapping.items()) if v is not None}
        if serialized:
            await anyio.to_thread.run_sync(self._cache.set_many, serialized, expire=ttl or self._default_ttl)

    async def delete(self, key: str) -> None:
        try:
            await anyio.to_thread.run_sync(self._cache.__delitem__, key)
        except KeyError:
            pass

    async def delete_many(self, *keys: str) -> None:
        if keys:
            await anyio.to_thread.run_sync(self._run_sync, "delete_many", keys)

    async def clear(self, prefix: str | None = None) -> None:
        await anyio.to_thread.run_sync(self._clear_sync, prefix)

    async def keys(self, prefix: str = "") -> list[str]:
        return await anyio.to_thread.run_sync(self._filter_keys, prefix)

    async def warm(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        return await anyio.to_thread.run_sync(self._warm_sync, entries, ttl)

    # ══════════════════════════════════════════════════════════════════════
    # Sync methods (delegują do _run_sync)
    # ══════════════════════════════════════════════════════════════════════

    def get_sync(self, key: str) -> Any | None:
        return _deserialize(self._cache.get(key))

    def set_sync(self, key: str, value: Any, ttl: int | None = None) -> None:
        data = _serialize(value, key)
        if data is not None:
            self._cache.set(key, data, expire=ttl or self._default_ttl)

    def delete_sync(self, key: str) -> None:
        try:
            del self._cache[key]
        except KeyError:
            pass

    def size(self) -> int:
        return len(self._cache)

    def keys_sync(self, prefix: str = "") -> list[str]:
        return self._filter_keys(prefix)

    def clear_sync(self, prefix: str | None = None) -> None:
        self._clear_sync(prefix)

    def warm_sync(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        return self._warm_sync(entries, ttl)

    # ══════════════════════════════════════════════════════════════════════
    # Współdzielone metody pomocnicze
    # ══════════════════════════════════════════════════════════════════════

    def _warm_sync(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        if not entries:
            return 0
        serialized: dict[str, bytes] = {k: v for k, v in ((k, _serialize(v, k)) for k, v in entries.items()) if v is not None}
        if serialized:
            self._cache.set_many(serialized, expire=ttl or self._default_ttl)
        logger.info("[CACHE-WARM] Loaded %d entries", len(serialized))
        return len(serialized)

    def _clear_sync(self, prefix: str | None = None) -> None:
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

    def _filter_keys(self, prefix: str = "") -> list[str]:
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        if pattern:
            return [k for k in self._cache.iterkeys() if k.startswith(pattern)]
        return list(self._cache.iterkeys())

    def _run_sync(self, op: str, *args: Any) -> None:
        if op == "delete_many":
            for key in args[0]:
                try:
                    del self._cache[key]
                except KeyError:
                    pass

    # ══════════════════════════════════════════════════════════════════════
    # Cache stampede protection
    # ══════════════════════════════════════════════════════════════════════

    async def get_or_compute(self, key: str, compute_func: Callable[[], Any], ttl: int | None = None) -> Any:
        import inspect
        if (cached := await self.get(key)) is not None:
            return cached
        lock = self._get_or_create_lock(key, self._compute_locks, self._compute_locks_lock, anyio.Lock)
        async with lock:
            if (cached := await self.get(key)) is not None:
                return cached
            value = await compute_func() if inspect.iscoroutinefunction(compute_func) else await anyio.to_thread.run_sync(compute_func)
            await self.set(key, value, ttl=ttl)
            return value

    def get_or_compute_sync(self, key: str, compute_func: Callable[[], Any], ttl: int | None = None) -> Any:
        if (cached := self.get_sync(key)) is not None:
            return cached
        lock = self._get_or_create_lock(key, self._sync_compute_locks, self._sync_compute_locks_lock, threading.Lock)
        with lock:
            if (cached := self.get_sync(key)) is not None:
                return cached
            value = compute_func()
            self.set_sync(key, value, ttl=ttl)
            return value

    def _get_or_create_lock(self, key: str, locks: dict, guard: threading.Lock, lock_type: type) -> Any:
        with guard:
            if key not in locks:
                if len(locks) >= 10_000:
                    for old_key in list(locks.keys())[:1000]:
                        del locks[old_key]
                locks[key] = lock_type()
            return locks[key]

    def close(self) -> None:
        try:
            self._cache.close()
        except Exception as exc:
            logger.debug("[CACHE] Close failed: %s", exc)

    def __del__(self) -> None:
        self.close()


_default_cache: NexusCache | None = None
_default_cache_lock = threading.Lock()


def get_cache(cache_dir: str | Path | None = None, default_ttl: int = 300,
              use_l2: bool = True, l2_backend_type: str = "disk") -> NexusCache:
    global _default_cache
    if _default_cache is None:
        with _default_cache_lock:
            if _default_cache is None:
                _default_cache = NexusCache(cache_dir=cache_dir, default_ttl=default_ttl)
    return _default_cache


__all__ = [
    "NexusCache", "get_cache",
    "CachedHttpClient", "warm_http_cache", "get_cache_stats", "reset_cache_stats",
    "invalidate_cache", "subscribe_cache_invalidation",
]
