"""
NexusAI Cache — warstwa cache oparta na diskcache + hishel HTTP cache + NATS invalidation.

Zgodnie z decyzją optymalizacyjną:
- Własne backendy (InMemoryBackend, SqliteBackend) → diskcache.Cache
- hishel — inteligentny cache HTTP przez CachedHttpClient
- NATS distributed cache invalidation
"""

from nexus_ai.core.cache.backends import (
    CacheBackend,
    InMemoryBackend,
    DiskBackend,
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
    "DiskBackend",
    "RedisBackend",
    "create_backend",
    # NexusCache
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
