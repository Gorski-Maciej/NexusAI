"""
NexusAI Cache — dyscache multi-level caching layer.

Zgodnie z aa3fvcx.txt (Punkt 13):
- dyscache zamiast cachetools / diskcache
- Natywnie asynchroniczny (anyio)
- Dwupoziomowy: RAM (L1) + SQLite (L2)
- Integracja z msgspec dla ultraszybkiej serializacji
"""

from nexus_ai.core.cache.dyscache import NexusCache, get_cache

__all__ = ["NexusCache", "get_cache"]
