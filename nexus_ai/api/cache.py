# api/cache.py
"""
Async multi-level cache (RAM in-memory + SQLite persistence).

Zgodnie z aa3fvcx.txt (Punkt 13): inteligentny, dwupoziomowy cache
(RAM L1 + SQLite L2), natywnie asynchroniczny (anyio).
Zastępuje: dyscache (nieopublikowany pakiet) → wbudowana implementacja
oparta na anyio + słowniku w pamięci (SQLite L2 w przyszłości).

Użycie:
    from nexus_ai.api.cache import nexus_cache

    await nexus_cache.set("kurs:eur", money_data, ttl=3600)
    cached = await nexus_cache.get("kurs:eur")
"""

from __future__ import annotations

import time
from collections.abc import Callable
from functools import wraps
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.api.cache")


class _MemoryFallback:
    """Async-native in-memory cache with TTL support.

    Domyślna implementacja cache — dwupoziomowa:
    - L1 (RAM): Błyskawiczny, ulotny cache dla najczęściej używanych danych
    - L2 (SQLite): Opcjonalny, trwały cache na dysku (w przyszłości)

    Zastępuje: dyscache (nieistniejący pakiet PyPI) oraz poprzednią
    implementację opartą na cashews.
    """

    def __init__(self):
        self._cache: dict[str, tuple[float, Any]] = {}
        self._max_items = 5000

    async def get(self, key: str) -> Any | None:
        now = time.time()
        hit = self._cache.get(key)
        if hit and now <= hit[0]:  # hit[0] = expiry timestamp
            return hit[1]
        if hit:
            del self._cache[key]
        return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        if len(self._cache) >= self._max_items:
            now = time.time()
            stale = [k for k, (exp, _) in self._cache.items() if now > exp]
            for k in stale[:100]:
                del self._cache[k]
        self._cache[key] = (time.time() + ttl, value)

    async def delete(self, key: str) -> None:
        self._cache.pop(key, None)

    async def clear(self, prefix: str | None = None) -> None:
        if prefix is None:
            self._cache.clear()
        else:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            keys_to_delete = [k for k in self._cache if k.startswith(pattern)]
            for k in keys_to_delete:
                del self._cache[k]

    async def keys(self, prefix: str = "") -> list[str]:
        return [k for k in self._cache if k.startswith(prefix.rstrip("*"))]

    async def delete_many(self, *keys: str) -> None:
        for key in keys:
            self._cache.pop(key, None)

    async def close(self) -> None:
        self._cache.clear()


# ── Global singleton ──────────────────────────────────────────────────────

class NexusCache:
    """Async multi-level cache (RAM in-memory + SQLite in future).

    Zgodnie z aa3fvcx.txt (Punkt 13):
    - L1 (RAM): Błyskawiczny, ulotny cache dla najczęściej używanych danych
    - L2 (future): Opcjonalnie SQLite dla trwałości między restartami

    W pełni asynchroniczny (anyio-native), idealnie współgra z resztą
    stosu (Litestar, Granian).
    """

    def __init__(self, db_path: Path | None = None):
        self._cache = _MemoryFallback()
        self._db_path = db_path or Path("app_data/cache/nexus_cache.sqlite")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        logger.info("[Cache] NexusCache initialized (in-memory L1)")

    async def get(self, key: str) -> Any | None:
        try:
            return await self._cache.get(key)
        except Exception as exc:
            logger.warning("[Cache] get failed for %s: %s", key, exc)
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        try:
            await self._cache.set(key, value, ttl=ttl)
        except Exception as exc:
            logger.warning("[Cache] set failed for %s: %s", key, exc)

    async def delete(self, key: str) -> None:
        try:
            await self._cache.delete(key)
        except Exception as exc:
            logger.warning("[Cache] delete failed for %s: %s", key, exc)

    async def clear(self, prefix: str | None = None) -> None:
        try:
            await self._cache.clear(prefix=prefix)
        except Exception as exc:
            logger.warning("[Cache] clear failed: %s", exc)

    async def close(self) -> None:
        if hasattr(self._cache, "close"):
            try:
                await self._cache.close()
            except Exception as exc:
                logger.warning("[Cache] close failed: %s", exc)


nexus_cache = NexusCache()


# ── Decorator ─────────────────────────────────────────────────────────────


def ttl_cache(seconds: int = 60):
    """Decorator that caches async function results using nexus_cache.

    Używa nexus_cache (wbudowany cache) zamiast dyscache/cashews.
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
