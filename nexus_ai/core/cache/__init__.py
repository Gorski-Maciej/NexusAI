"""
NexusAI Cache — dyscache multi-level caching layer + hishel HTTP cache.

Zgodnie z aa3fvcx.txt (Punkt 13):
- dyscache zamiast cachetools / diskcache
- Natywnie asynchroniczny (anyio)
- Dwupoziomowy: RAM (L1) + SQLite (L2)
- Integracja z msgspec dla ultraszybkiej serializacji
- hishel — inteligentny cache HTTP przez CachedHttpClient

SUPERMOCE HISHEL (Punkt 6):
  - CachedHttpClient — prekonfigurowany klient z cache'em
  - create_cached_client() — tworzenie klienta z konfiguracją
  - create_cached_transport() — transport dla istniejących httpx.AsyncClient
  - warm_http_cache() — wypełnienie cache przy starcie
  - get_cache_stats() — monitoring hit/miss ratio
"""

from nexus_ai.core.cache.dyscache import NexusCache, get_cache
from nexus_ai.core.cache.http_client import (
    CachedHttpClient,
    create_cached_client,
    create_cached_transport,
    get_cache_stats,
    reset_cache_stats,
    warm_http_cache,
)

__all__ = [
    # NexusCache (L1 RAM + L2 SQLite)
    "NexusCache",
    "get_cache",
    # hishel HTTP cache (CachedHttpClient)
    "CachedHttpClient",
    "create_cached_client",
    "create_cached_transport",
    "warm_http_cache",
    "get_cache_stats",
    "reset_cache_stats",
]
