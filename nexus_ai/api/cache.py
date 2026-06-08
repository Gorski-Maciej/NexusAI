# api/cache.py
"""
Async multi-level cache using dyscache (anyio-native, RAM L1 + SQLite L2).

Zgodnie z aa3fvcx.txt (Punkt 13): inteligentny, dwupoziomowy cache
(RAM L1 + SQLite L2), natywnie asynchroniczny (anyio).
Zastępuje: poprzednią implementację opartą na cashews (która nie jest anyio-native).

Użycie:
    from nexus_ai.api.cache import nexus_cache

    await nexus_cache.set("kurs:eur", money_data, ttl=3600)
    cached = await nexus_cache.get("kurs:eur")
"""

from __future__ import annotations

from collections.abc import Callable
from functools import wraps
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.api.cache")


class NexusCache:
    """Async multi-level cache (RAM L1 + SQLite L2) using dyscache.

    Zgodnie z aa3fvcx.txt:
    - L1 (RAM): Błyskawiczny, ulotny cache dla najczęściej używanych danych
    - L2 (SQLite): Trwały, pojemny cache na dysku — dane przetrwają restart

    dyscache jest natywnie asynchroniczny (anyio-native), co idealnie
    współgra z resztą stosu (Litestar, Granian).
    Zastępuje: cashews (który nie był anyio-native).
    """

    def __init__(self, db_path: Path | None = None):
        self._cache = None
        self._db_path = db_path or Path("app_data/cache/nexus_cache.sqlite")
        self._initialized = False
        self._init_cache()

    def _init_cache(self) -> None:
        try:
            from dyscache import Cache
            # dyscache z domyślnym dwupoziomowym backendem (RAM L1 + SQLite L2)
            self._cache = Cache(str(self._db_path))
            self._initialized = True
            logger.info("[Cache] dyscache initialized: %s", self._db_path)
        except ImportError:
            logger.warning(
                "[Cache] dyscache not installed. "
                "Install: pip install dyscache. "
                "Falling back to in-memory cache."
            )
            self._cache = _MemoryFallback()
            self._initialized = True
        except Exception as exc:
            logger.error("[Cache] dyscache init failed: %s", exc)
            self._cache = _MemoryFallback()
            self._initialized = True

    async def get(self, key: str) -> Any | None:
        """Get value from cache."""
        if not self._initialized:
            return None
        try:
            return await self._cache.get(key)
        except Exception as exc:
            logger.warning("[Cache] get failed for %s: %s", key, exc)
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        """Set value in cache with TTL (seconds)."""
        if not self._initialized:
            return
        try:
            await self._cache.set(key, value, ttl=ttl)
        except Exception as exc:
            logger.warning("[Cache] set failed for %s: %s", key, exc)

    async def delete(self, key: str) -> None:
        """Delete a key from cache."""
        if not self._initialized:
            return
        try:
            await self._cache.delete(key)
        except Exception as exc:
            logger.warning("[Cache] delete failed for %s: %s", key, exc)

    async def clear(self, prefix: str | None = None) -> None:
        """Clear cache entries, optionally filtered by prefix."""
        if not self._initialized:
            return
        try:
            if prefix is None:
                await self._cache.clear()
            else:
                await self._cache.clear(pattern=f"{prefix}*")
        except Exception as exc:
            logger.warning("[Cache] clear failed: %s", exc)

    async def close(self) -> None:
        """Close the cache connection."""
        if self._initialized and hasattr(self._cache, "close"):
            try:
                await self._cache.close()
            except Exception as exc:
                logger.warning("[Cache] close failed: %s", exc)


# ── Fallback in-memory cache (gdy dyscache nie jest dostępny) ─────────────


class _MemoryFallback:
    """Simple in-memory cache fallback when dyscache is not available."""

    def __init__(self):
        self._cache: dict[str, tuple[float, Any]] = {}
        self._max_items = 5000

    async def get(self, key: str) -> Any | None:
        import time
        now = time.time()
        hit = self._cache.get(key)
        if hit and now <= hit[0]:  # hit[0] = expiry timestamp
            return hit[1]
        if hit:
            del self._cache[key]
        return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        import time
        if len(self._cache) >= self._max_items:
            now = time.time()
            stale = [k for k, (exp, _) in self._cache.items() if now > exp]
            for k in stale[:100]:
                del self._cache[k]
        self._cache[key] = (time.time() + ttl, value)

    async def delete(self, key: str) -> None:
        self._cache.pop(key, None)

    async def clear(self) -> None:
        self._cache.clear()

    async def keys(self, prefix: str = "") -> list[str]:
        return [k for k in self._cache if k.startswith(prefix.rstrip("*"))]

    async def delete_many(self, *keys: str) -> None:
        for key in keys:
            self._cache.pop(key, None)


# ── Global singleton ──────────────────────────────────────────────────────

nexus_cache = NexusCache()


# ── Decorator ─────────────────────────────────────────────────────────────


def ttl_cache(seconds: int = 60):
    """Decorator that caches async function results using dyscache.

    Używa nexus_cache (dyscache) zamiast poprzedniej implementacji
    opartej na cashews/słowniku w pamięci.
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            key = f"ttlcache:{func.__module__}.{func.__qualname__}:{args[1:]}:{sorted(kwargs.items())}"
            cached = await nexus_cache.get(key)
            if cached is not None:
                return cached

            result = await func(*args, **kwargs)

            if result is not None:
                await nexus_cache.set(key, result, ttl=seconds)
            return result

        return wrapper

    return decorator


# ── Backward compatibility ───────────────────────────────────────────────


async def clear_cache_async(prefix: str | None = None) -> None:
    """Backward-compatible cache clear function."""
    await nexus_cache.clear(prefix)


def clear_cache(prefix: str | None = None) -> None:
    """Backward-compatible sync cache clear function."""
    import anyio
    anyio.run(nexus_cache.clear, prefix)
