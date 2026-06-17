"""
NexusCache — multi-level caching layer with pluggable CacheBackend.

Zgodnie z aa3fvcx.txt (Punkt 13) + AUDYT:
- dyscache / diskcache → pluggable CacheBackend (InMemoryBackend L1 + SqliteBackend L2)
- Natywnie asynchroniczny (anyio-native wrapper)
- Dwupoziomowy: RAM (L1) + SQLite (L2) przez CacheBackend
- Integracja z msgspec dla serializacji
- Zero dodatkowej infrastruktury — wykorzystuje istniejące SQLite
- RedisBackend dla rozproszonego cache

SUPERMOCE Z AUDYTU:
  - Pluggable backend przez CacheBackend ABC
  - get_or_compute_sync() — synchroniczna wersja ze stampede protection
  - warm() — cache warming dla cold start
  - size() — liczba wpisów L1
  - clear_l1_sync() — czyszczenie L1 bez L2
  - Batch delete_many L2 przez delete_batch()
"""

from __future__ import annotations

import os
import threading
import time
from pathlib import Path
from typing import Any, Callable

import anyio
import msgspec
from structlog import get_logger

from nexus_ai.core.cache.backends import CacheBackend, InMemoryBackend, create_backend

# ── Próba importu OpenTelemetry Metrics API (opcjonalne) ─────────────────

try:
    from opentelemetry import metrics as _otel_metrics

    HAS_OTEL = True
except ImportError:
    HAS_OTEL = False

logger = get_logger("nexus.core.cache")


class NexusCache:
    """Multi-level cache z RAM (L1) + SQLite (L2) przez pluggable CacheBackend.

    Zgodnie z aa3fvcx.txt + AUDYT:
    - Pluggable backend przez CacheBackend ABC
    - Fallback do InMemoryBackend gdy brak backendu
    - Automatyczna serializacja przez msgspec
    - Thread-safe L1 (threading.Lock dla free-threaded Python 3.13t)
    - LRU eviction przez InMemoryBackend
    - Cache stampede protection (async get_or_compute + sync get_or_compute_sync)

    Serializacja używa msgspec.msgpack — 2-5× szybsza niż JSON,
    mniejsze payloady.

    Args:
        l1_backend: Backend dla L1 (RAM). Domyślnie InMemoryBackend.
        l2_backend: Backend dla L2 (SQLite/Redis). None = brak L2.
        default_ttl: Domyślny TTL w sekundach.
    """

    def __init__(
        self,
        l1_backend: CacheBackend | None = None,
        l2_backend: CacheBackend | None = None,
        default_ttl: int = 300,
    ) -> None:
        self._default_ttl = default_ttl
        self._l1: CacheBackend = l1_backend or InMemoryBackend(max_size=10_000)
        self._l2: CacheBackend | None = l2_backend

        # Cache stampede protection — per-key anyio.Lock (async)
        self._compute_locks: dict[str, anyio.Lock] = {}
        self._compute_locks_lock = threading.Lock()
        # Cache stampede protection — per-key threading.Lock (sync)
        self._sync_compute_locks: dict[str, threading.Lock] = {}
        self._sync_compute_locks_lock = threading.Lock()

        # OTEL metrics (lazy — init przy pierwszym użyciu get/set)
        self._meter: Any = None
        self._cache_hits_total: Any = None
        self._cache_misses_total: Any = None
        self._cache_l2_latency_seconds: Any = None
        self._cache_evictions_total: Any = None
        self._cache_size: Any = None

        logger.info(
            "[CACHE] Initialized: L1=%s L2=%s default_ttl=%s",
            type(self._l1).__name__,
            type(self._l2).__name__ if self._l2 else "None",
            default_ttl,
        )

    @property
    def has_l2(self) -> bool:
        """Czy L2 backend jest dostępny."""
        return self._l2 is not None

    # ══════════════════════════════════════════════════════════════════════
    # OTEL metrics helpers
    # ══════════════════════════════════════════════════════════════════════

    def _init_otel_metrics(self) -> None:
        if self._meter is not None or not HAS_OTEL:
            return
        try:
            meter = _otel_metrics.get_meter("nexus-cache", "2.0.0")
            self._cache_hits_total = meter.create_counter(
                name="cache_hits_total",
                description="Total cache hits by level (L1/L2)",
                unit="1",
            )
            self._cache_misses_total = meter.create_counter(
                name="cache_misses_total",
                description="Total cache misses",
                unit="1",
            )
            self._cache_l2_latency_seconds = meter.create_histogram(
                name="cache_l2_latency_seconds",
                description="L2 operation latency in seconds",
                unit="s",
            )
            self._cache_evictions_total = meter.create_counter(
                name="cache_evictions_total",
                description="Total L1 cache evictions",
                unit="1",
            )
            from opentelemetry.metrics import Observation

            def _cache_size_callback():
                yield Observation(self._l1.size())

            self._cache_size = meter.create_observable_gauge(
                name="cache_size",
                description="Current L1 cache size",
                unit="1",
                callbacks=[_cache_size_callback],
            )

            if self._l2 is not None:
                def _l2_size_callback():
                    try:
                        yield Observation(self._l2.size())
                    except Exception:
                        pass

                meter.create_observable_gauge(
                    name="cache_l2_size",
                    description="Total entries in L2 cache",
                    unit="1",
                    callbacks=[_l2_size_callback],
                )
            self._meter = meter
        except Exception:
            pass

    def _record_hit(self, level: str = "L1") -> None:
        if self._cache_hits_total is not None:
            self._cache_hits_total.add(1, {"level": level})

    def _record_miss(self) -> None:
        if self._cache_misses_total is not None:
            self._cache_misses_total.add(1)

    def _record_l2_latency(self, operation: str, duration: float) -> None:
        if self._cache_l2_latency_seconds is not None:
            self._cache_l2_latency_seconds.record(
                duration, {"operation": operation},
            )

    def _record_evictions(self, count: int) -> None:
        if self._cache_evictions_total is not None:
            self._cache_evictions_total.add(count)

    def _get_compute_lock(self, key: str) -> anyio.Lock:
        """Pobierz lub utwórz per-key anyio.Lock dla async stampede protection.

        LRU cleanup: po przekroczeniu max_locks=10_000 usuwa najstarsze locki.
        """
        max_locks = 10_000
        with self._compute_locks_lock:
            if key not in self._compute_locks:
                if len(self._compute_locks) >= max_locks:
                    # LRU cleanup — usuń 10% najstarszych
                    for old_key in list(self._compute_locks.keys())[:max_locks // 10]:
                        del self._compute_locks[old_key]
                self._compute_locks[key] = anyio.Lock()
            return self._compute_locks[key]

    def _get_sync_compute_lock(self, key: str) -> threading.Lock:
        """Pobierz lub utwórz per-key threading.Lock dla sync stampede protection.

        LRU cleanup: po przekroczeniu max_locks=10_000 usuwa najstarsze locki.
        """
        max_locks = 10_000
        with self._sync_compute_locks_lock:
            if key not in self._sync_compute_locks:
                if len(self._sync_compute_locks) >= max_locks:
                    for old_key in list(self._sync_compute_locks.keys())[:max_locks // 10]:
                        del self._sync_compute_locks[old_key]
                self._sync_compute_locks[key] = threading.Lock()
            return self._sync_compute_locks[key]

    # ══════════════════════════════════════════════════════════════════════
    # Core async API
    # ══════════════════════════════════════════════════════════════════════

    async def get(self, key: str) -> Any | None:
        """Pobierz wartość z cache'u (L1 → L2).

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        self._init_otel_metrics()

        # L1
        raw = self._l1.get(key)
        if raw is not None:
            self._record_hit("L1")
            try:
                return msgspec.msgpack.decode(raw)
            except Exception:
                return None

        # L2
        if self._l2 is not None:
            try:
                t0 = anyio.current_time()
                raw = self._l2.get(key)
                elapsed = anyio.current_time() - t0
                self._record_l2_latency("get", elapsed)
                if raw is not None:
                    self._l1.set(key, raw, self._default_ttl)
                    self._record_hit("L2")
                    return msgspec.msgpack.decode(raw)
            except Exception as exc:
                logger.debug("[CACHE] L2 get failed for %s: %s", key, exc)

        self._record_miss()
        return None

    async def get_many(self, *keys: str) -> list[Any | None]:
        """Pobierz wiele wartości z cache'u (batch L1 + L2)."""
        self._init_otel_metrics()

        # L1 batch
        raw_results = self._l1.get_batch(list(keys))
        results: list[Any | None] = []
        l2_keys: list[str] = []
        l2_indices: list[int] = []

        for i, (key, raw) in enumerate(zip(keys, raw_results)):
            if raw is not None:
                self._record_hit("L1")
                try:
                    results.append(msgspec.msgpack.decode(raw))
                except Exception:
                    results.append(None)
            else:
                results.append(None)
                l2_keys.append(key)
                l2_indices.append(i)

        if not l2_keys or self._l2 is None:
            for _ in l2_keys:
                self._record_miss()
            return results

        # L2 batch
        try:
            t0 = anyio.current_time()
            l2_raw = self._l2.get_batch(l2_keys)
            elapsed = anyio.current_time() - t0
            self._record_l2_latency("get_many", elapsed)

            for idx, key, raw in zip(l2_indices, l2_keys, l2_raw):
                if raw is not None:
                    self._record_hit("L2")
                    self._l1.set(key, raw, self._default_ttl)
                    try:
                        results[idx] = msgspec.msgpack.decode(raw)
                    except Exception:
                        pass
                else:
                    self._record_miss()
        except Exception as exc:
            logger.debug("[CACHE] L2 get_many failed: %s", exc)
            for _ in l2_keys:
                self._record_miss()

        return results

    async def set(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Zapisz wartość w cache'u (L1 + L2).

        Args:
            key: Klucz cache.
            value: Wartość (serializowana przez msgspec.msgpack).
            ttl: TTL w sekundach.
        """
        self._init_otel_metrics()
        effective_ttl = ttl if ttl is not None else self._default_ttl

        try:
            data = msgspec.msgpack.encode(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return

        self._l1.set(key, data, effective_ttl)

        if self._l2 is not None:
            try:
                t0 = anyio.current_time()
                self._l2.set(key, data, effective_ttl)
                self._record_l2_latency("set", anyio.current_time() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 set failed for %s: %s", key, exc)

    async def set_many(
        self,
        mapping: dict[str, Any],
        ttl: int | None = None,
    ) -> None:
        """Zapisz wiele wartości w cache'u (batch L1 + L2)."""
        self._init_otel_metrics()
        effective_ttl = ttl if ttl is not None else self._default_ttl

        serialized: dict[str, bytes] = {}
        for key, value in mapping.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE] Serialization failed for %s: %s", key, exc)

        if serialized:
            self._l1.set_batch(serialized, effective_ttl)

        if self._l2 is not None and serialized:
            try:
                t0 = anyio.current_time()
                self._l2.set_batch(serialized, effective_ttl)
                self._record_l2_latency("set_many", anyio.current_time() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 set_many failed: %s", exc)

    async def delete(self, key: str) -> None:
        """Usuń wartość z cache'u (L1 + L2)."""
        self._init_otel_metrics()
        self._l1.delete(key)
        if self._l2 is not None:
            try:
                t0 = anyio.current_time()
                self._l2.delete(key)
                self._record_l2_latency("delete", anyio.current_time() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def delete_many(self, *keys: str) -> None:
        """Usuń wiele wartości z cache'u (batch L1 + L2)."""
        self._init_otel_metrics()
        key_list = list(keys)
        self._l1.delete_batch(key_list)
        if self._l2 is not None:
            try:
                t0 = anyio.current_time()
                self._l2.delete_batch(key_list)
                self._record_l2_latency("delete_many", anyio.current_time() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 delete_many failed: %s", exc)

    async def clear(self, prefix: str | None = None) -> None:
        """Wyczyść cache — całość lub tylko klucze z danym prefixem.

        Args:
            prefix: Jeśli podany, usuwa tylko klucze zaczynające się od prefixu.
                    Jeśli None, czyści cały cache (L1 + L2).
        """
        self._init_otel_metrics()
        old_size = self._l1.size()
        self._l1.clear(prefix)
        if prefix is None and old_size > 0:
            self._record_evictions(old_size)
        if self._l2 is not None:
            try:
                self._l2.clear(prefix)
            except Exception as exc:
                logger.debug("[CACHE] L2 clear failed: %s", exc)

    async def keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy cache z danym prefixem (tylko L1)."""
        return self._l1.keys(prefix)

    async def delete_prefix_async(self, prefix: str) -> int:
        """Async version: usuwa wszystkie klucze z danym prefixem (L1 + L2)."""
        self._init_otel_metrics()
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        deleted_keys = self._l1.keys(pattern)
        self._l1.clear(pattern)
        if deleted_keys:
            self._record_evictions(len(deleted_keys))
        if self._l2 is not None:
            try:
                self._l2.clear(pattern)
            except Exception as exc:
                logger.debug("[CACHE] L2 prefix delete failed for %s: %s", pattern, exc)
        return len(deleted_keys)

    # ══════════════════════════════════════════════════════════════════════
    # Sync methods (L1 only)
    # ══════════════════════════════════════════════════════════════════════

    def delete_sync(self, key: str) -> None:
        """Sync version: usuwa tylko z L1."""
        self._init_otel_metrics()
        self._l1.delete(key)

    def get_sync(self, key: str) -> Any | None:
        """Sync version: sprawdza tylko L1 (RAM) cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        self._init_otel_metrics()
        raw = self._l1.get(key)
        if raw is not None:
            self._record_hit("L1")
            try:
                return msgspec.msgpack.decode(raw)
            except Exception:
                pass
        self._record_miss()
        return None

    def set_sync(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Sync version: zapisuje tylko w L1.

        Thread-safe przez InMemoryBackend.
        """
        effective_ttl = ttl if ttl is not None else self._default_ttl
        try:
            data = msgspec.msgpack.encode(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return
        self._l1.set(key, data, effective_ttl)

    def delete_prefix_sync(self, prefix: str) -> int:
        """Sync version: usuwa wszystkie klucze z danym prefixem (L1 + L2).

        Args:
            prefix: Prefiks kluczy do usunięcia.

        Returns:
            Liczba usuniętych wpisów z L1.
        """
        self._init_otel_metrics()
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        deleted_keys = self._l1.keys(pattern)
        self._l1.clear(pattern)
        if deleted_keys:
            self._record_evictions(len(deleted_keys))
        if self._l2 is not None:
            try:
                self._l2.clear(pattern)
            except Exception as exc:
                logger.debug("[CACHE] L2 prefix clear failed for %s: %s", prefix, exc)
        return len(deleted_keys)

    def clear_l1_sync(self, prefix: str | None = None) -> None:
        """SUPERMOC: Sync version — czyści TYLKO L1 (RAM), bez L2.

        SUPERMOC: Używane przez TimedModelCache.release() zamiast
        bezpośredniego dostępu do _ram_cache (naruszanie enkapsulacji).

        Args:
            prefix: Prefiks kluczy do usunięcia. None = cały L1.
        """
        self._init_otel_metrics()
        old_size = self._l1.size()
        self._l1.clear(prefix)
        if prefix is None and old_size > 0:
            self._record_evictions(old_size)

    def size(self) -> int:
        """Zwróć liczbę wpisów w L1 cache.

        SUPERMOC: Publiczne API dla monitorowania rozmiaru cache.
        Zastępuje bezpośredni dostęp do _ram_cache.
        """
        return self._l1.size()

    def l1_keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy L1 z danym prefixem.

        SUPERMOC: Publiczne API dla diagnostyki.
        """
        return self._l1.keys(prefix)

    # ══════════════════════════════════════════════════════════════════════
    # get_or_compute — async i sync, z cache stampede protection
    # ══════════════════════════════════════════════════════════════════════

    async def get_or_compute(
        self,
        key: str,
        compute_func: Callable[[], Any],
        ttl: int | None = None,
    ) -> Any:
        """Async version: pobierz z cache'u lub oblicz i zapisz.

        Z cache stampede protection: per-key anyio.Lock z double-check.
        Gdy wiele współbieżnych zadań żąda tego samego klucza, tylko jedno
        wywołuje compute_func() — pozostałe czekają na wynik.

        SUPERMOC: Poprawna detekcja async przez inspect.iscoroutinefunction().

        Args:
            key: Klucz cache.
            compute_func: Async funkcja do obliczenia wartości.
            ttl: TTL w sekundach.

        Returns:
            Wartość z cache'u lub świeżo obliczona.
        """
        import inspect

        # Fast path
        cached = await self.get(key)
        if cached is not None:
            return cached

        # Stampede protection
        lock = self._get_compute_lock(key)
        async with lock:
            cached = await self.get(key)
            if cached is not None:
                return cached

            if inspect.iscoroutinefunction(compute_func):
                value = await compute_func()
            else:
                value = compute_func()
            await self.set(key, value, ttl=ttl)
            return value

    def get_or_compute_sync(
        self,
        key: str,
        compute_func: Callable[[], Any],
        ttl: int | None = None,
    ) -> Any:
        """SUPERMOC: Sync version z cache stampede protection.

        Używa per-key threading.Lock z double-check.
        Gdy wiele synchronicznych wątków żąda tego samego klucza,
        tylko jeden wywołuje compute_func().

        Args:
            key: Klucz cache.
            compute_func: Synchroniczna funkcja do obliczenia wartości.
            ttl: TTL w sekundach.

        Returns:
            Wartość z cache'u lub świeżo obliczona.
        """
        # Fast path
        cached = self.get_sync(key)
        if cached is not None:
            return cached

        # Stampede protection
        lock = self._get_sync_compute_lock(key)
        with lock:
            cached = self.get_sync(key)
            if cached is not None:
                return cached

            value = compute_func()
            self.set_sync(key, value, ttl=ttl)
            return value

    # ══════════════════════════════════════════════════════════════════════
    # Cache warming — SUPERMOC: cold-start protection
    # ══════════════════════════════════════════════════════════════════════

    async def warm(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        """SUPERMOC: Wypełnij cache danymi przy starcie (cold-start protection).

        SUPERMOC AUDYT: L2 set_batch jest synchroniczny (SqliteBackend),
        więc używamy anyio.to_thread.run_sync żeby nie blokować event loop.

        Args:
            entries: Słownik {klucz: wartość} do załadowania do cache.
            ttl: TTL w sekundach. Domyślnie self._default_ttl.

        Returns:
            Liczba załadowanych wpisów.
        """
        if not entries:
            return 0
        effective_ttl = ttl if ttl is not None else self._default_ttl

        serialized: dict[str, bytes] = {}
        for key, value in entries.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE-WARM] Serialization failed for %s: %s", key, exc)

        if serialized:
            self._l1.set_batch(serialized, effective_ttl)
            if self._l2 is not None:
                try:
                    # L2 w wątku — nie blokuje event loop
                    _l2 = self._l2
                    _ser = serialized
                    _ttl = effective_ttl
                    await anyio.to_thread.run_sync(
                        lambda: _l2.set_batch(_ser, _ttl)
                    )
                except Exception as exc:
                    logger.debug("[CACHE-WARM] L2 warm failed: %s", exc)

        logger.info("[CACHE-WARM] Loaded %d entries", len(serialized))
        return len(serialized)

    def warm_sync(self, entries: dict[str, Any], ttl: int | None = None) -> int:
        """SUPERMOC: Sync version — wypełnij L1 cache danymi przy starcie.

        Args:
            entries: Słownik {klucz: wartość}.
            ttl: TTL w sekundach.

        Returns:
            Liczba załadowanych wpisów.
        """
        if not entries:
            return 0
        effective_ttl = ttl if ttl is not None else self._default_ttl

        serialized: dict[str, bytes] = {}
        for key, value in entries.items():
            try:
                serialized[key] = msgspec.msgpack.encode(value)
            except Exception as exc:
                logger.error("[CACHE-WARM] Serialization failed for %s: %s", key, exc)

        if serialized:
            self._l1.set_batch(serialized, effective_ttl)

        logger.info("[CACHE-WARM] Loaded %d entries to L1", len(serialized))
        return len(serialized)

    def close(self) -> None:
        """Zamknij backendy i zwolnij zasoby."""
        close_l1 = getattr(self._l1, 'close', None)
        if callable(close_l1):
            close_l1()
        if self._l2 is not None:
            close_l2 = getattr(self._l2, 'close', None)
            if callable(close_l2):
                close_l2()


# ── Global singleton (thread-safe dla free-threaded Python) ──────────────

_default_cache: NexusCache | None = None
_default_cache_lock = threading.Lock()


def get_cache(
    cache_dir: str | Path | None = None,
    default_ttl: int = 300,
    use_l2: bool = True,
    l2_backend_type: str = "sqlite",
) -> NexusCache:
    """Zwraca globalną instancję NexusCache (singleton z thread-safe init).

    SUPERMOC: Pluggable backend przez CacheBackend.
    L1 zawsze InMemoryBackend (RAM). L2 opcjonalny:
    - "sqlite" → SqliteBackend (domyślny)
    - "redis" → RedisBacked (wymaga redis-py + NEXUS_REDIS_URL)

    Args:
        cache_dir: Katalog dla SQLite L2 backendu.
        default_ttl: Domyślny TTL w sekundach.
        use_l2: Czy używać L2.
        l2_backend_type: Typ backendu L2 ("sqlite" | "redis").

    Returns:
        Globalna instancja NexusCache.
    """
    global _default_cache
    if _default_cache is None:
        with _default_cache_lock:
            if _default_cache is None:
                l1 = InMemoryBackend(max_size=10_000)
                l2: CacheBackend | None = None
                if use_l2:
                    if l2_backend_type == "redis":
                        try:
                            from nexus_ai.core.cache.backends_redis import RedisBackend
                            l2 = RedisBackend()
                            logger.info("[CACHE] L2 RedisBackend initialized")
                        except Exception as exc:
                            logger.warning("[CACHE] RedisBackend init failed: %s — fallback to SQLite", exc)
                            l2 = _create_sqlite_l2(cache_dir)
                    else:
                        l2 = _create_sqlite_l2(cache_dir)

                _default_cache = NexusCache(
                    l1_backend=l1,
                    l2_backend=l2,
                    default_ttl=default_ttl,
                )
    return _default_cache


def _create_sqlite_l2(cache_dir: str | Path | None) -> SqliteBackend:
    """Helper: tworzy SqliteBackend w podanym katalogu."""
    if cache_dir is None:
        cache_dir = Path(os.getcwd()) / "app_data" / "cache"
    cache_path = Path(cache_dir) / "nexus_cache.db"
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    from nexus_ai.core.cache.backends import SqliteBackend
    backend = SqliteBackend(db_path=str(cache_path))
    logger.info("[CACHE] L2 SqliteBackend initialized: %s", cache_path)
    return backend
    global _default_cache
    if _default_cache is None:
        with _default_cache_lock:
            if _default_cache is None:
                l1 = InMemoryBackend(max_size=10_000)
                l2: CacheBackend | None = None
                if use_l2:
                    if cache_dir is None:
                        cache_dir = Path(os.getcwd()) / "app_data" / "cache"
                    cache_path = Path(cache_dir) / "nexus_cache.db"
                    cache_path.parent.mkdir(parents=True, exist_ok=True)
                    from nexus_ai.core.cache.backends import SqliteBackend
                    l2 = SqliteBackend(db_path=str(cache_path))
                    logger.info("[CACHE] L2 SqliteBackend initialized: %s", cache_path)

                _default_cache = NexusCache(
                    l1_backend=l1,
                    l2_backend=l2,
                    default_ttl=default_ttl,
                )
    return _default_cache
