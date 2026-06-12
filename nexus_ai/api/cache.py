"""
api/cache.py — API-level cache using core NexusCache.

Provides:
- ``nexus_cache``: Global NexusCache singleton (via ``core.cache.get_cache()``)
- ``ttl_cache(seconds)``: Decorator for caching async function results
- ``clear_cache_async(prefix)``: Backward-compatible cache clear
- ``clear_cache(prefix)``: Sync version of ``clear_cache_async``

Uses ``core.cache.NexusCache`` (L1 RAM + L2 SQLite/dyscache, msgspec serialization)
zamiast osobnej implementacji ``_MemoryFallback``. Spójne z resztą stacku cache
— ten sam singleton co ``DecisionEngine``, ``ForexEngine``, ``SemanticGuard`` itp.

Użycie:
    from nexus_ai.api.cache import nexus_cache

    await nexus_cache.set("kurs:eur", money_data, ttl=3600)
    cached = await nexus_cache.get("kurs:eur")
"""

from __future__ import annotations

from collections.abc import Callable
from functools import wraps
from typing import Any

from structlog import get_logger

from nexus_ai.core.cache import get_cache

logger = get_logger("nexus.api.cache")

# Global NexusCache singleton (core.cache singleton via get_cache())
# Współdzielony z DecisionEngine, ForexEngine, SemanticGuard itp.
# Klucze API mają prefix "ttlcache:" — brak kolizji z innymi podsystemami.
nexus_cache = get_cache()


# ── Decorator ─────────────────────────────────────────────────────────────


def ttl_cache(seconds: int = 60):
    """Decorator that caches async function results using nexus_cache.

    Używa ``nexus_cache`` (core NexusCache) z L1 RAM + L2 SQLite/dyscache.

    Klucz cache: ``ttlcache:{func.__module__}.{func.__qualname__}:{args[1:]}:{sorted(kwargs.items())}``

    Args:
        seconds: TTL w sekundach (domyślnie 60).

    Example:
        .. code-block:: python

            @ttl_cache(seconds=60)
            async def get_dashboard_summary(self, duckdb: DuckDBManager) -> ...:
                ...
    """

    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            # args[1:] dla metod (pomija self/cls), args[:] dla funkcji modułowych
            # Sprawdzamy po qualname: metody mają "ClassName.method_name"
            _parts = func.__qualname__.split(".")
            _is_method = len(_parts) > 1
            _key_args = args[1:] if _is_method else args
            key = (
                f"ttlcache:{func.__module__}.{func.__qualname__}:"
                f"{_key_args}:{sorted(kwargs.items())}"
            )
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
    """Backward-compatible cache clear function.

    Czyści L1 (RAM) + L2 (diskcache/SQLite) dla kluczy z danym prefixem.
    Jeśli prefix jest None, czyści cały cache (L1 + L2).

    Args:
        prefix: Prefiks kluczy do usunięcia (np. ``"api.routes.analytics"``).
    """
    await nexus_cache.clear(prefix)


def clear_cache(prefix: str | None = None) -> None:
    """Backward-compatible sync cache clear function.

    Args:
        prefix: Prefiks kluczy do usunięcia.
    """
    import anyio

    anyio.run(nexus_cache.clear, prefix)
