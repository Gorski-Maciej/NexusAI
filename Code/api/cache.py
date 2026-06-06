from __future__ import annotations

import asyncio
import time
from collections.abc import Callable
from functools import wraps
from typing import Any

_CACHE: dict[str, tuple[float, Any]] = {}
_CACHE_LOCK = asyncio.Lock()
_MAX_CACHE_ITEMS = 5000


def ttl_cache(seconds: int = 60):
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            key = f"{func.__module__}.{func.__qualname__}:{args[1:]}:{sorted(kwargs.items())}"
            now = time.time()
            async with _CACHE_LOCK:
                hit = _CACHE.get(key)
                if hit and now - hit[0] <= seconds:
                    return hit[1]

            result = await func(*args, **kwargs)

            async with _CACHE_LOCK:
                if len(_CACHE) >= _MAX_CACHE_ITEMS:
                    stale_keys = [k for k, (ts, _) in _CACHE.items() if now - ts > seconds]
                    for stale_key in stale_keys[: max(1, len(_CACHE) - _MAX_CACHE_ITEMS + 1)]:
                        _CACHE.pop(stale_key, None)
                _CACHE[key] = (now, result)
            return result

        return wrapper

    return decorator


async def clear_cache_async(prefix: str | None = None) -> None:
    async with _CACHE_LOCK:
        if prefix is None:
            _CACHE.clear()
            return
        keys = [k for k in _CACHE if k.startswith(prefix)]
        for key in keys:
            _CACHE.pop(key, None)


def clear_cache(prefix: str | None = None) -> None:
    # Compatibility helper for sync call-sites.
    if prefix is None:
        _CACHE.clear()
        return
    keys = [k for k in _CACHE if k.startswith(prefix)]
    for key in keys:
        _CACHE.pop(key, None)
