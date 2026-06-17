"""
RedisBackend — Redis implementation of CacheBackend for distributed caching.

SUPERMOCE:
- Używa synchronicznego redis.Redis (nie redis.asyncio) — zero problemów z event loop
- Thread-safe przez connection pool
- Pipeline dla batch operations
- SCAN dla prefixowych operacji

Usage:
    from nexus_ai.core.cache.backends import create_backend
    backend = create_backend("redis", redis_url="redis://localhost:6379/0")
    backend.set("key", b"value", expire=3600)
    value = backend.get("key")
"""

from __future__ import annotations

import os
import threading
from typing import Any

from nexus_ai.core.cache.backends import CacheBackend
from structlog import get_logger

logger = get_logger("nexus.core.cache.redis")


class RedisBackend(CacheBackend):
    """Redis-based cache backend — synchroniczny redis.Redis.

    SUPERMOC: Rozproszony cache dla multi-instancji.
    Używa synchronicznego redis.Redis (redis-py) z connection pool,
    co jest bezpieczne w threadach i nie wymaga event loop.

    Args:
        redis_url: Redis connection URL. Domyślnie z NEXUS_REDIS_URL env.
        socket_timeout: Timeout w sekundach.
    """

    def __init__(
        self,
        redis_url: str | None = None,
        socket_timeout: float = 2.0,
    ) -> None:
        self._redis_url = redis_url or os.environ.get(
            "NEXUS_REDIS_URL", "redis://localhost:6379/0"
        )
        self._socket_timeout = socket_timeout
        self._client: Any = None
        self._lock = threading.Lock()

    def _get_client(self) -> Any:
        """Get or create Redis connection (sync, thread-safe)."""
        if self._client is not None:
            return self._client
        with self._lock:
            if self._client is not None:
                return self._client
            try:
                import redis

                self._client = redis.from_url(
                    self._redis_url,
                    socket_timeout=self._socket_timeout,
                    socket_connect_timeout=self._socket_timeout,
                    decode_responses=False,
                )
                self._client.ping()
                logger.info("[CACHE-REDIS] Connected to %s", self._redis_url)
            except Exception as exc:
                logger.warning(
                    "[CACHE-REDIS] Connection failed: %s — using in-memory dict fallback",
                    exc,
                )
                self._client = {}  # fallback in-memory
        return self._client

    def get(self, key: str) -> bytes | None:
        client = self._get_client()
        if isinstance(client, dict):
            return client.get(key)
        return client.get(key)

    def get_batch(self, keys: list[str]) -> list[bytes | None]:
        client = self._get_client()
        if isinstance(client, dict):
            return [client.get(k) for k in keys]
        results = client.mget(keys)
        return list(results) if results else [None] * len(keys)

    def set(self, key: str, value: bytes, expire: int | None = None) -> None:
        client = self._get_client()
        if isinstance(client, dict):
            client[key] = value
            return
        if expire:
            client.setex(key, expire, value)
        else:
            client.set(key, value)

    def set_batch(self, mapping: dict[str, bytes], expire: int | None = None) -> None:
        client = self._get_client()
        if isinstance(client, dict):
            client.update(mapping)
            return
        pipe = client.pipeline()
        for key, value in mapping.items():
            if expire:
                pipe.setex(key, expire, value)
            else:
                pipe.set(key, value)
        pipe.execute()

    def delete(self, key: str) -> None:
        client = self._get_client()
        if isinstance(client, dict):
            client.pop(key, None)
            return
        client.delete(key)

    def delete_batch(self, keys: list[str]) -> None:
        client = self._get_client()
        if isinstance(client, dict):
            for k in keys:
                client.pop(k, None)
            return
        client.delete(*keys)

    def clear(self, prefix: str | None = None) -> None:
        client = self._get_client()
        if isinstance(client, dict):
            if prefix is None:
                client.clear()
            else:
                pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
                for k in list(client.keys()):
                    if k.startswith(pattern):
                        del client[k]
            return
        if prefix is None:
            client.flushdb()
        else:
            pattern = (prefix.rstrip("*") if prefix.endswith("*") else prefix) + "*"
            cursor = 0
            while True:
                cursor, keys = client.scan(cursor, match=pattern, count=100)
                if keys:
                    client.delete(*keys)
                if cursor == 0:
                    break

    def size(self) -> int:
        client = self._get_client()
        if isinstance(client, dict):
            return len(client)
        return client.dbsize()

    def keys(self, prefix: str = "") -> list[str]:
        client = self._get_client()
        if isinstance(client, dict):
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            return [k for k in client if k.startswith(pattern)]
        pattern = (prefix.rstrip("*") if prefix.endswith("*") else prefix) + "*"
        keys = []
        cursor = 0
        while True:
            cursor, batch = client.scan(cursor, match=pattern)
            keys.extend(batch)
            if cursor == 0:
                break
        return keys

    def close(self) -> None:
        client = self._client
        if client and not isinstance(client, dict):
            try:
                client.close()
            except Exception:
                pass
        self._client = None
