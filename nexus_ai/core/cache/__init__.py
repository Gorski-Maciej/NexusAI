"""
NexusAI Cache — multi-level caching layer + hishel HTTP cache.

Zgodnie z aa3fvcx.txt (Punkt 13) + AUDYT:
- CacheBackend ABC z InMemoryBackend, SqliteBackend, RedisBackend
- NexusCache z pluggable backend (L1 RAM + L2 SQLite/Redis)
- hishel — inteligentny cache HTTP przez CachedHttpClient
- NATS distributed cache invalidation

SUPERMOCE Z AUDYTU:
  - Pluggable backend przez CacheBackend ABC
  - InMemoryBackend — thread-safe L1 z LRU eviction
  - SqliteBackend — async SQLite L2 (prawdziwy async-native)
  - RedisBackend — rozproszony cache dla multi-instancji
  - get_or_compute() / get_or_compute_sync() — stampede protection
  - warm() / warm_sync() — cache warming dla cold start
  - invalidate_cache() / subscribe_cache_invalidation() — NATS distributed invalidation
"""

from nexus_ai.core.cache.backends import (
    CacheBackend,
    InMemoryBackend,
    SqliteBackend,
    create_backend,
)
from nexus_ai.core.cache.dyscache import NexusCache, get_cache
from nexus_ai.core.cache.http_client import (
    CachedHttpClient,
    create_cached_client,
    create_cached_transport,
    get_cache_stats,
    reset_cache_stats,
    warm_http_cache,
)
from nexus_ai.core.cache.invalidation import (
    invalidate_cache,
    subscribe_cache_invalidation,
)
from nexus_ai.core.cache.backends_redis import RedisBackend

__all__ = [
    # CacheBackend ABC + implementacje
    "CacheBackend",
    "InMemoryBackend",
    "SqliteBackend",
    "RedisBackend",
    "create_backend",
    # NexusCache (L1 RAM + L2 SQLite/Redis)
    "NexusCache",
    "get_cache",
    # hishel HTTP cache (CachedHttpClient)
    "CachedHttpClient",
    "create_cached_client",
    "create_cached_transport",
    "warm_http_cache",
    "get_cache_stats",
    "reset_cache_stats",
    # NATS distributed cache invalidation
    "invalidate_cache",
    "subscribe_cache_invalidation",
]
