"""
NexusAI HTTP Cache Layer — hishel integration.

Zgodnie z aa3fvcx.txt (Punkt 6):
- hishel — inteligentny cache HTTP rozumiejący Cache-Control, ETag
- Automatyczne przyspieszenie bez kodowania
- Działanie offline i odporność na awarie
- Cache w SQLite (zero dodatkowej infrastruktury)
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import httpx
from structlog import get_logger

from nexus_ai.core.cache import get_cache

logger = get_logger("nexus.http.cache")

# ── Próba importu hishel ─────────────────────────────────────────────────

try:
    import hishel

    HAS_HISHEL = True
except ImportError:
    HAS_HISHEL = False
    logger.warning(
        "[HTTP-CACHE] hishel not installed — HTTP caching disabled. "
        "Install: pip install hishel"
    )


def create_cached_client(
    cache_dir: str | Path | None = None,
    **kwargs: Any,
) -> httpx.AsyncClient:
    """Utwórz httpx.AsyncClient z inteligentnym cache'em HTTP (hishel).

    Zgodnie z aa3fvcx.txt:
    - hishel zapisuje odpowiedzi w lokalnym SQLite
    - Respektuje Cache-Control, ETag, Stale-While-Revalidate
    - Działa offline jako fallback

    Args:
        cache_dir: Katalog dla cache'u SQLite.
        **kwargs: Dodatkowe argumenty dla httpx.AsyncClient.

    Returns:
        httpx.AsyncClient z wbudowanym cache'em HTTP.
    """
    if HAS_HISHEL:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "http_cache"
        cache_path = Path(cache_dir)
        cache_path.mkdir(parents=True, exist_ok=True)

        # hishel Controller z polityką cache
        controller = hishel.Controller(
            # Respektuj Cache-Control z serwera
            allow_stale=True,
            # Offline fallback — używaj cache'u gdy brak sieci
            allow_stale_on_revalidation=True,
        )

        # hishel CacheStorage w SQLite
        storage = hishel.SQLiteStorage(
            database=str(cache_path / "http_cache.db"),
            ttl=3600,  # Domyślny TTL 1h
        )

        client = hishel.AsyncCacheClient(
            controller=controller,
            storage=storage,
            **kwargs,
        )
        logger.info("[HTTP-CACHE] hishel client initialized (cache=%s)", cache_path)
        return client
    else:
        # Fallback: zwykły httpx.AsyncClient bez cache
        logger.info("[HTTP-CACHE] hishel not available — using plain httpx")
        return httpx.AsyncClient(**kwargs)


# ── Prekonfigurowane klienty dla zewnętrznych API ────────────────────────

class CachedHttpClient:
    """Prekonfigurowany klient HTTP z cache'em dla zewnętrznych API.

    Używany przez CurrencyConverter, WhiteListService, GusBirClient.
    Cache przechowuje odpowiedzi API przez określony czas.
    """

    def __init__(self, cache_dir: str | Path | None = None) -> None:
        self._client = create_cached_client(
            cache_dir=cache_dir,
            timeout=30.0,
            max_keepalive_connections=5,
        )

    async def get(self, url: str, **kwargs: Any) -> httpx.Response:
        """Wykonaj GET z cache'em HTTP."""
        return await self._client.get(url, **kwargs)

    async def post(self, url: str, **kwargs: Any) -> httpx.Response:
        """Wykonaj POST z cache'em HTTP."""
        return await self._client.post(url, **kwargs)

    async def close(self) -> None:
        """Zamknij klienta."""
        await self._client.aclose()
