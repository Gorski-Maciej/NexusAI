"""
NexusCache — dyscache-based multi-level caching layer.

Zgodnie z aa3fvcx.txt (Punkt 13):
- dyscache zastępuje cachetools / diskcache
- Natywnie asynchroniczny (anyio-native)
- Dwupoziomowy: RAM (L1) + SQLite (L2)
- Integracja z msgspec dla serializacji
- Zero dodatkowej infrastruktury — wykorzystuje istniejące SQLite
"""

from __future__ import annotations

import os
import time
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_dumps_bytes, msgspec_loads

logger = get_logger("nexus.core.cache")

# ── Próba importu dyscache (opcjonalne) ──────────────────────────────────

try:
    from dyscache import Cache as _DyscacheCache
    HAS_DYSCACHE = True
except ImportError:
    HAS_DYSCACHE = False
    logger.warning(
        "[CACHE] dyscache not installed — using simple in-memory fallback. "
        "Install: pip install dyscache"
    )


class NexusCache:
    """Multi-level cache z RAM (L1) + SQLite (L2) przez dyscache.

    Zgodnie z aa3fvcx.txt:
    - Używa dyscache gdy dostępny
    - Fallback do prostego słownika w RAM
    - Automatyczna serializacja przez msgspec

    Args:
        cache_dir: Katalog dla cache'u SQLite (L2).
        default_ttl: Domyślny TTL w sekundach.
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        default_ttl: int = 300,
    ) -> None:
        self._default_ttl = default_ttl
        self._ram_cache: dict[str, tuple[float, bytes]] = {}  # (expiry, serialized_data)

        if HAS_DYSCACHE and cache_dir is not None:
            cache_path = Path(cache_dir) / "nexus_cache.db"
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            self._dyscache = _DyscacheCache(str(cache_path))
            logger.info("[CACHE] dyscache initialized: %s", cache_path)
        else:
            self._dyscache = None
            if not HAS_DYSCACHE:
                logger.info("[CACHE] Using in-memory fallback (dyscache not available)")
            else:
                logger.info("[CACHE] Using in-memory fallback (no cache_dir provided)")

    async def get(self, key: str) -> Any | None:
        """Pobierz wartość z cache'u.

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        # Sprawdź L1 (RAM)
        if key in self._ram_cache:
            expiry, data = self._ram_cache[key]
            if expiry > time.time():
                try:
                    return msgspec_loads(data)
                except Exception:
                    pass
            else:
                del self._ram_cache[key]

        # Sprawdź L2 (dyscache/SQLite)
        if self._dyscache is not None:
            try:
                raw = await self._dyscache.get(key)
                if raw is not None:
                    # Zapisz w L1 (RAM) dla szybszego dostępu
                    data = raw if isinstance(raw, bytes) else str(raw).encode()
                    self._ram_cache[key] = (time.time() + self._default_ttl, data)
                    return msgspec_loads(data)
            except Exception as exc:
                logger.debug("[CACHE] L2 get failed for %s: %s", key, exc)

        return None

    async def set(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Zapisz wartość w cache'u.

        Args:
            key: Klucz cache.
            value: Wartość do zapisania (serializowana przez msgspec).
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        effective_ttl = ttl if ttl is not None else self._default_ttl

        try:
            data = msgspec_dumps_bytes(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return

        # Zapisz w L1 (RAM)
        self._ram_cache[key] = (time.time() + effective_ttl, data)

        # Zapisz w L2 (dyscache/SQLite)
        if self._dyscache is not None:
            try:
                await self._dyscache.set(key, data, ttl=effective_ttl)
            except Exception as exc:
                logger.debug("[CACHE] L2 set failed for %s: %s", key, exc)

    async def delete(self, key: str) -> None:
        """Usuń wartość z cache'u."""
        self._ram_cache.pop(key, None)
        if self._dyscache is not None:
            try:
                await self._dyscache.delete(key)
            except Exception as exc:
                logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def delete_many(self, *keys: str) -> None:
        """Usuń wiele wartości z cache'u.

        Args:
            *keys: Klucze do usunięcia.
        """
        for key in keys:
            self._ram_cache.pop(key, None)
        if self._dyscache is not None:
            for key in keys:
                try:
                    await self._dyscache.delete(key)
                except Exception as exc:
                    logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def clear(self, prefix: str | None = None) -> None:
        """Wyczyść cache — całość lub tylko klucze z danym prefixem.

        Gdy ``prefix`` jest podany, czyści tylko L1 (RAM) klucze zaczynające
        się od prefixu. L2 (dyscache/SQLite) jest pomijane — wygasłe wpisy
        w L2 będą pominięte przy następnym ``get()`` (TTL ich wyczyści).

        Gdy ``prefix`` jest None, czyści cały L1 RAM oraz L2 dyscache.

        Args:
            prefix: Jeśli podany, usuwa tylko klucze zaczynające się od prefixu.
                    Jeśli None, czyści cały cache (L1 + L2).
        """
        if prefix is not None:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            keys_to_delete = [k for k in self._ram_cache if k.startswith(pattern)]
            for k in keys_to_delete:
                del self._ram_cache[k]
            # L2 (dyscache/SQLite) nie wspiera prefix-delete, ale
            # nieaktualne wpisy w L2 zostaną pominięte przez TTL.
            return

        self._ram_cache.clear()
        if self._dyscache is not None:
            try:
                await self._dyscache.clear()
            except Exception as exc:
                logger.debug("[CACHE] L2 clear failed: %s", exc)

    async def keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy cache z danym prefixem.

        Sprawdza tylko L1 (RAM) — L2 (dyscache/SQLite) nie wspiera
        kwerend po prefiksie.

        Args:
            prefix: Prefiks do filtrowania kluczy (np. ``"risk_threshold:"``).
                    Domyślnie "" = wszystkie klucze.

        Returns:
            Lista kluczy (str) w L1 RAM zaczynających się od prefixu.
        """
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        return [k for k in self._ram_cache if k.startswith(pattern)]

    # ── Sync methods (L1 RAM only — for use in sync services) ─────────────

    def delete_prefix_sync(self, prefix: str) -> int:
        """Sync version: removes all keys with given prefix from L1 (RAM) cache.

        Przydatne dla event-based cache invalidation gdy cache zawiera
        wiele kluczy z tym samym prefixem (np. risk_threshold:{*} → "risk_threshold:").
        Nie wpływa na L2 (dyscache/SQLite).

        Args:
            prefix: Prefiks kluczy do usunięcia (np. "risk_threshold:").

        Returns:
            Liczba usuniętych wpisów.
        """
        keys_to_delete = [k for k in self._ram_cache if k.startswith(prefix)]
        for k in keys_to_delete:
            del self._ram_cache[k]
        return len(keys_to_delete)

    def delete_sync(self, key: str) -> None:
        """Sync version: removes only from L1 (RAM) cache.

        Zgodnie z wzorcem get_sync/set_sync — operuje tylko na L1 RAM.
        Przydatne dla event-based cache invalidation w serwisach
        synchronicznych (DecisionEngine, RiskGuard).

        Args:
            key: Klucz cache do usunięcia.
        """
        self._ram_cache.pop(key, None)

    def get_sync(self, key: str) -> Any | None:
        """Sync version: checks only L1 (RAM) cache.

        Przydatne dla synchronicznych serwisów jak CurrencyConverter.
        L2 (dyscache/SQLite) jest pomijane, bo wymaga async.

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        if key in self._ram_cache:
            expiry, data = self._ram_cache[key]
            if expiry > time.time():
                try:
                    return msgspec_loads(data)
                except Exception:
                    pass
            else:
                del self._ram_cache[key]
        return None

    def set_sync(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Sync version: writes only to L1 (RAM) cache.

        Args:
            key: Klucz cache.
            value: Wartość do zapisania (serializowana przez msgspec).
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        effective_ttl = ttl if ttl is not None else self._default_ttl
        try:
            data = msgspec_dumps_bytes(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return
        self._ram_cache[key] = (time.time() + effective_ttl, data)

    async def get_or_compute(
        self,
        key: str,
        compute_func,
        ttl: int | None = None,
    ) -> Any:
        """Pobierz z cache'u lub oblicz i zapisz.

        Args:
            key: Klucz cache.
            compute_func: Async funkcja do obliczenia wartości.
            ttl: TTL w sekundach.

        Returns:
            Wartość z cache'u lub świeżo obliczona.
        """
        cached = await self.get(key)
        if cached is not None:
            return cached

        value = await compute_func()
        await self.set(key, value, ttl=ttl)
        return value


# ── Global singleton ──────────────────────────────────────────────────────

_default_cache: NexusCache | None = None


def get_cache(
    cache_dir: str | Path | None = None,
    default_ttl: int = 300,
) -> NexusCache:
    """Zwraca globalną instancję NexusCache (singleton).

    Args:
        cache_dir: Katalog dla cache'u SQLite.
        default_ttl: Domyślny TTL w sekundach.

    Returns:
        Globalna instancja NexusCache.
    """
    global _default_cache
    if _default_cache is None:
        if cache_dir is None:
            cache_dir = Path(os.getcwd()) / "app_data" / "cache"
        _default_cache = NexusCache(cache_dir=cache_dir, default_ttl=default_ttl)
    return _default_cache
