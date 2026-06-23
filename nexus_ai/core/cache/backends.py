"""
CacheBackend — backend cache oparty na diskcache.

Zastępuje poprzednie własne backendy (InMemoryBackend, SqliteBackend).
diskcache zapewnia:
- SQLite-backed storage z WAL mode
- Wbudowany TTL (expire)
- Thread-safe
- LRU eviction (size_limit)
- Setting tag dla prefix-based operations

CacheBackend ABC zachowany dla zgodności API.
"""

from __future__ import annotations

import os
import tempfile
import threading
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

import diskcache
from structlog import get_logger

logger = get_logger("nexus.core.cache.backend")


class CacheBackend(ABC):
    """Abstrakcyjna klasa bazowa dla backendów cache.

    Zachowana dla zgodności API z NexusCache.
    """

    @abstractmethod
    def get(self, key: str) -> bytes | None:
        ...

    @abstractmethod
    def get_batch(self, keys: list[str]) -> list[bytes | None]:
        return [self.get(k) for k in keys]

    @abstractmethod
    def set(self, key: str, value: bytes, expire: int | None = None) -> None:
        ...

    @abstractmethod
    def set_batch(self, mapping: dict[str, bytes], expire: int | None = None) -> None:
        for key, value in mapping.items():
            self.set(key, value, expire=expire)

    @abstractmethod
    def delete(self, key: str) -> None:
        ...

    @abstractmethod
    def delete_batch(self, keys: list[str]) -> None:
        for key in keys:
            self.delete(key)

    @abstractmethod
    def clear(self, prefix: str | None = None) -> None:
        ...

    @abstractmethod
    def size(self) -> int:
        ...

    @abstractmethod
    def keys(self, prefix: str = "") -> list[str]:
        ...

    def close(self) -> None:
        pass


# ═════════════════════════════════════════════════════════════════════════
# DiskBackend — oparty na diskcache.Cache
# ═════════════════════════════════════════════════════════════════════════


class DiskBackend(CacheBackend):
    """Backend cache oparty na diskcache.Cache.

    diskcache zapewnia:
    - SQLite-backed persistence (WAL mode)
    - Wbudowany TTL (expire parameter)
    - Thread-safe
    - LRU eviction (size_limit)
    - Setting tag dla prefix-based clear

    Args:
        cache_dir: Katalog dla pliku SQLite.
        size_limit: Maksymalny rozmiar cache w bajtach.
        eviction_policy: Polityka usuwania ("least-recently-used" domyślnie).
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        size_limit: int = 2**30,  # 1GB
        eviction_policy: str = "least-recently-used",
    ) -> None:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "cache"
        self._cache_dir = Path(cache_dir)
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._cache = diskcache.Cache(
            directory=str(self._cache_dir),
            size_limit=size_limit,
            eviction_policy=eviction_policy,
            disk=diskcache.Disk,
        )
        self._lock = threading.Lock()
        logger.info("[CACHE-BACKEND] DiskBackend initialized: %s (size_limit=%d)", self._cache_dir, size_limit)

    def _make_key(self, key: str) -> str:
        """Normalizacja klucza dla diskcache."""
        return key

    def get(self, key: str) -> bytes | None:
        try:
            value = self._cache.get(self._make_key(key))
            if value is not None and isinstance(value, bytes):
                return value
            return None
        except Exception:
            return None

    def get_batch(self, keys: list[str]) -> list[bytes | None]:
        results = self._cache.get_many([self._make_key(k) for k in keys])
        return [r if isinstance(r, bytes) else None for r in results]

    def set(self, key: str, value: bytes, expire: int | None = None) -> None:
        self._cache.set(self._make_key(key), value, expire=expire)

    def set_batch(self, mapping: dict[str, bytes], expire: int | None = None) -> None:
        self._cache.set_many(
            {self._make_key(k): v for k, v in mapping.items()},
            expire=expire,
        )

    def delete(self, key: str) -> None:
        try:
            del self._cache[self._make_key(key)]
        except KeyError:
            pass

    def delete_batch(self, keys: list[str]) -> None:
        for key in keys:
            try:
                del self._cache[self._make_key(key)]
            except KeyError:
                pass

    def clear(self, prefix: str | None = None) -> None:
        if prefix is None:
            self._cache.clear()
        else:
            # diskcache nie wspiera prefix clear natywnie — używamy tag
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            for key in list(self._cache.iterkeys()):
                if key.startswith(pattern):
                    try:
                        del self._cache[key]
                    except KeyError:
                        pass

    def size(self) -> int:
        return len(self._cache)

    def keys(self, prefix: str = "") -> list[str]:
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        if pattern:
            return [k for k in self._cache.iterkeys() if k.startswith(pattern)]
        return list(self._cache.iterkeys())

    def close(self) -> None:
        try:
            self._cache.close()
        except Exception:
            pass

    def __del__(self) -> None:
        self.close()


# ═════════════════════════════════════════════════════════════════════════
# InMemoryBackend — dla testów i sytuacji bez dysku
# ═════════════════════════════════════════════════════════════════════════


class InMemoryBackend(CacheBackend):
    """Lekki backend in-memory dla testów.

    Używa tymczasowego katalogu z diskcache dla pełnej zgodności API.
    """

    def __init__(self, max_size: int | None = 10_000) -> None:
        self._tmpdir = tempfile.mkdtemp(prefix="nexus_cache_")
        self._cache = diskcache.Cache(
            directory=self._tmpdir,
            size_limit=int(max_size * 1024) if max_size else 2**30,
        )

    def get(self, key: str) -> bytes | None:
        val = self._cache.get(key)
        return val if isinstance(val, bytes) else None

    def get_batch(self, keys: list[str]) -> list[bytes | None]:
        results = self._cache.get_many(keys)
        return [r if isinstance(r, bytes) else None for r in results]

    def set(self, key: str, value: bytes, expire: int | None = None) -> None:
        self._cache.set(key, value, expire=expire)

    def set_batch(self, mapping: dict[str, bytes], expire: int | None = None) -> None:
        self._cache.set_many(mapping, expire=expire)

    def delete(self, key: str) -> None:
        try:
            del self._cache[key]
        except KeyError:
            pass

    def delete_batch(self, keys: list[str]) -> None:
        for key in keys:
            try:
                del self._cache[key]
            except KeyError:
                pass

    def clear(self, prefix: str | None = None) -> None:
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

    def size(self) -> int:
        return len(self._cache)

    def keys(self, prefix: str = "") -> list[str]:
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        if pattern:
            return [k for k in self._cache.iterkeys() if k.startswith(pattern)]
        return list(self._cache.iterkeys())

    def close(self) -> None:
        try:
            self._cache.close()
            import shutil
            shutil.rmtree(self._tmpdir, ignore_errors=True)
        except Exception:
            pass


# ═════════════════════════════════════════════════════════════════════════
# Factory
# ═════════════════════════════════════════════════════════════════════════


def create_backend(
    backend_type: str = "disk",
    cache_dir: str | Path | None = None,
    max_size: int | None = 10_000,
    **kwargs: Any,
) -> CacheBackend:
    """Fabryka backendów.

    Args:
        backend_type: "disk" (domyślnie) | "in_memory" | "redis"
        cache_dir: Katalog dla cache.
        max_size: Maksymalny rozmiar.
        **kwargs: Dodatkowe argumenty.
    """
    if backend_type in ("disk", "sqlite"):  # "sqlite" zachowane dla kompatybilności
        return DiskBackend(cache_dir=cache_dir)

    if backend_type == "in_memory":
        return InMemoryBackend(max_size=max_size)

    if backend_type == "redis":
        try:
            from nexus_ai.core.cache.backends_redis import RedisBackend
            redis_url = kwargs.get("redis_url", os.environ.get("NEXUS_REDIS_URL"))
            return RedisBackend(redis_url=redis_url)
        except ImportError:
            logger.warning("[CACHE-BACKEND] RedisBackend not available — falling back to disk")
            return DiskBackend(cache_dir=cache_dir)

    raise ValueError(f"Unknown backend type: {backend_type!r}")


__all__ = [
    "CacheBackend",
    "DiskBackend",
    "InMemoryBackend",
    "create_backend",
]
