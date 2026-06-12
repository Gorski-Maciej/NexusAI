"""
NexusCache — diskcache-based multi-level caching layer.

Zgodnie z aa3fvcx.txt (Punkt 13):
- diskcache (poprawna nazwa, zamiast nieistniejącego dyscache)
- Natywnie asynchroniczny (anyio-native wrapper wokół synchronicznego diskcache)
- Dwupoziomowy: RAM (L1) + SQLite (L2 przez diskcache)
- Integracja z msgspec dla serializacji
- Zero dodatkowej infrastruktury — wykorzystuje istniejące SQLite
"""

from __future__ import annotations

import os
import threading
import time
from collections import OrderedDict
from pathlib import Path
from typing import Any

import anyio
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_dumps_bytes, msgspec_loads

# ── Próba importu OpenTelemetry Metrics API (opcjonalne) ─────────────────

try:
    from opentelemetry import metrics as _otel_metrics

    HAS_OTEL = True
except ImportError:
    HAS_OTEL = False

logger = get_logger("nexus.core.cache")

# ── Próba importu diskcache (opcjonalne) ────────────────────────────────

try:
    from diskcache import Cache as _DiskcacheCache

    HAS_DISKCACHE = True
except ImportError:
    HAS_DISKCACHE = False
    logger.warning(
        "[CACHE] diskcache not installed — using simple in-memory fallback. "
        "Install: pip install diskcache"
    )


class NexusCache:
    """Multi-level cache z RAM (L1) + SQLite (L2) przez diskcache.

    Zgodnie z aa3fvcx.txt:
    - Używa diskcache gdy dostępny (zamiast nieistniejącego dyscache)
    - Fallback do prostego słownika w RAM
    - Automatyczna serializacja przez msgspec
    - Ograniczenie rozmiaru L1 RAM przez ``max_size`` (LRU-eviction)
    - Thread-safe L1 (``threading.Lock`` dla free-threaded Python 3.13t)
    - O(1) LRU przez ``OrderedDict`` zamiast ręcznej listy

    Args:
        cache_dir: Katalog dla cache'u SQLite (L2).
        default_ttl: Domyślny TTL w sekundach.
        max_size: Maksymalna liczba wpisów w L1 RAM (LRU).
                  ``None`` = brak limitu.
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        default_ttl: int = 300,
        max_size: int | None = 10_000,
    ) -> None:
        self._default_ttl = default_ttl
        self._max_size = max_size
        # OrderedDict zamiast dict + ręczna lista — O(1) LRU touch/eviction
        self._ram_cache: OrderedDict[str, tuple[float, bytes]] = OrderedDict()
        # Thread-safe L1 dla free-threaded Python 3.13t
        self._lock = threading.Lock()
        # Cache stampede protection — per-key anyio.Lock
        self._compute_locks: dict[str, anyio.Lock] = {}
        self._compute_locks_lock = threading.Lock()

        # OTEL metrics (lazy — init przy pierwszym użyciu get/set)
        self._meter: Any = None
        self._cache_hits_total: Any = None  # Counter
        self._cache_misses_total: Any = None  # Counter
        self._cache_l2_latency_seconds: Any = None  # Histogram
        self._cache_evictions_total: Any = None  # Counter
        self._cache_size: Any = None  # Gauge

        if HAS_DISKCACHE and cache_dir is not None:
            cache_path = Path(cache_dir) / "nexus_cache.db"
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            self._diskcache = _DiskcacheCache(str(cache_path))
            logger.info("[CACHE] diskcache initialized: %s", cache_path)
        else:
            self._diskcache = None
            if not HAS_DISKCACHE:
                logger.info("[CACHE] Using in-memory fallback (diskcache not available)")
            else:
                logger.info("[CACHE] Using in-memory fallback (no cache_dir provided)")

    # ══════════════════════════════════════════════════════════════════════
    # L1 helpers (thread-safe, must be called with self._lock held)
    # ══════════════════════════════════════════════════════════════════════

    def _touch_locked(self, key: str) -> None:
        """O(1) move-to-end dla OrderedDict (najświeższy wpis)."""
        self._ram_cache.move_to_end(key)

    def _enforce_max_size_locked(self) -> int:
        """O(1) LRU eviction — usuwa najstarsze wpisy przez popitem(last=False).

        Returns:
            Liczba usuniętych wpisów.
        """
        if self._max_size is None:
            return 0
        evicted = 0
        while len(self._ram_cache) > self._max_size:
            self._ram_cache.popitem(last=False)
            evicted += 1
        return evicted

    def _get_l1(self, key: str) -> tuple[Any | None, bool]:
        """Pobierz z L1 (RAM) pod blokadą.

        Args:
            key: Klucz cache.

        Returns:
            (zdeserializowana wartość, True) jeśli znaleziono i nie wygasł.
            (None, False) jeśli brak lub wygasł.
        """
        if key in self._ram_cache:
            expiry, data = self._ram_cache[key]
            if expiry > time.time():
                self._touch_locked(key)
                try:
                    return msgspec_loads(data), True
                except Exception:
                    pass
            else:
                del self._ram_cache[key]
        return None, False

    def _set_l1(self, key: str, data: bytes, effective_ttl: int) -> None:
        """Zapisz w L1 (RAM) pod blokadą."""
        self._ram_cache[key] = (time.time() + effective_ttl, data)
        self._touch_locked(key)
        evicted = self._enforce_max_size_locked()
        # Metryki poza blokadą — OTEL instruments są thread-safe
        if evicted > 0:
            self._record_evictions(evicted)
        self._update_cache_size_gauge()

    def _delete_l1(self, key: str) -> None:
        """Usuń z L1 (RAM) pod blokadą."""
        self._ram_cache.pop(key, None)

    # ══════════════════════════════════════════════════════════════════════
    # OTEL metrics helpers
    # ══════════════════════════════════════════════════════════════════════

    def _init_otel_metrics(self) -> None:
        """Lazy init OpenTelemetry metric instruments.

        Wywoływane przy pierwszym get/set — nie blokuje importu.
        Gdy opentelemetry nie jest zainstalowane, wszystkie instrumenty
        pozostają None i metryki są no-op.
        """
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
                description="L2 (diskcache) operation latency in seconds",
                unit="s",
            )
            self._cache_evictions_total = meter.create_counter(
                name="cache_evictions_total",
                description="Total L1 cache evictions",
                unit="1",
            )
            self._cache_size = meter.create_gauge(
                name="cache_size",
                description="Current L1 cache size",
                unit="1",
            )
            self._meter = meter
        except Exception:
            pass

    def _record_hit(self, level: str = "L1") -> None:
        """Record a cache hit."""
        if self._cache_hits_total is not None:
            self._cache_hits_total.add(1, {"level": level})

    def _record_miss(self) -> None:
        """Record a cache miss."""
        if self._cache_misses_total is not None:
            self._cache_misses_total.add(1)

    def _record_l2_latency(self, operation: str, duration: float) -> None:
        """Record L2 operation latency."""
        if self._cache_l2_latency_seconds is not None:
            self._cache_l2_latency_seconds.record(duration, {"operation": operation})

    def _record_evictions(self, count: int) -> None:
        """Record eviction count."""
        if self._cache_evictions_total is not None:
            self._cache_evictions_total.add(count)

    def _update_cache_size_gauge(self) -> None:
        """Update cache size gauge to current L1 size."""
        if self._cache_size is not None:
            self._cache_size.set(len(self._ram_cache))

    def _get_compute_lock(self, key: str) -> anyio.Lock:
        """Pobierz lub utwórz per-key anyio.Lock dla cache stampede protection.

        Używa osobnej blokady (self._compute_locks_lock) do ochrony słownika
        locków, aby uniknąć deadlocka z self._lock.
        """
        with self._compute_locks_lock:
            if key not in self._compute_locks:
                self._compute_locks[key] = anyio.Lock()
            return self._compute_locks[key]

    # ══════════════════════════════════════════════════════════════════════
    # Core async API
    # ══════════════════════════════════════════════════════════════════════

    async def get(self, key: str) -> Any | None:
        """Pobierz wartość z cache'u (L1 + L2).

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        self._init_otel_metrics()

        # L1 (RAM) pod blokadą
        with self._lock:
            value, found = self._get_l1(key)
        if found:
            self._record_hit("L1")
            return value

        # L2 (diskcache/SQLite) — bez blokady, bo anyio.to_thread.run_sync
        if self._diskcache is not None:
            try:
                t0 = time.monotonic()
                raw = await anyio.to_thread.run_sync(self._diskcache.get, key)
                elapsed = time.monotonic() - t0
                self._record_l2_latency("get", elapsed)
                if raw is not None:
                    data = raw if isinstance(raw, bytes) else str(raw).encode()
                    # L1 write-back pod blokadą
                    with self._lock:
                        self._set_l1(key, data, self._default_ttl)
                    self._record_hit("L2")
                    return msgspec_loads(data)
            except Exception as exc:
                logger.debug("[CACHE] L2 get failed for %s: %s", key, exc)

        self._record_miss()
        return None

    async def get_many(self, *keys: str) -> list[Any | None]:
        """Pobierz wiele wartości z cache'u jednocześnie.

        Batchuje L1 i L2 lookupy dla lepszej wydajności przy wielu kluczach.
        L2 lookupy są batchowane w jednym ``anyio.to_thread.run_sync``.

        Args:
            *keys: Klucze cache.

        Returns:
            Lista zdeserializowanych wartości (None dla brakujących).
        """
        self._init_otel_metrics()

        results: list[Any | None] = []
        l2_keys: list[str] = []
        l2_indices: list[int] = []
        l1_hits = 0

        # L1 batch pod blokadą
        with self._lock:
            for i, key in enumerate(keys):
                value, found = self._get_l1(key)
                if found:
                    results.append(value)
                    l1_hits += 1
                else:
                    results.append(None)
                    l2_keys.append(key)
                    l2_indices.append(i)

        # Metryki L1
        if l1_hits:
            self._record_hit("L1")
        l2_lookups = len(l2_keys)

        # L2 batch — jeden anyio.to_thread.run_sync
        l2_hits = 0
        if self._diskcache is not None and l2_keys:
            try:
                t0 = time.monotonic()
                raw_values = await anyio.to_thread.run_sync(
                    self._get_diskcache_batch, l2_keys,
                )
                elapsed = time.monotonic() - t0
                self._record_l2_latency("get_many", elapsed)
                for original_idx, key, raw in zip(l2_indices, l2_keys, raw_values):
                    if raw is not None:
                        l2_hits += 1
                        data = raw if isinstance(raw, bytes) else str(raw).encode()
                        with self._lock:
                            self._set_l1(key, data, self._default_ttl)
                        try:
                            results[original_idx] = msgspec_loads(data)
                        except Exception:
                            pass
            except Exception as exc:
                logger.debug("[CACHE] L2 get_many failed: %s", exc)

        # Metryki L2 hit/miss
        if l2_hits:
            self._record_hit("L2")
        l2_misses = l2_lookups - l2_hits
        if l2_misses:
            for _ in range(l2_misses):
                self._record_miss()

        return results

    def _get_diskcache_batch(self, keys: list[str]) -> list[Any | None]:
        """Batch get z diskcache (synchroniczny, wołany w wątku)."""
        return [self._diskcache.get(k) for k in keys] if self._diskcache else [None] * len(keys)

    async def set(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Zapisz wartość w cache'u (L1 + L2).

        Args:
            key: Klucz cache.
            value: Wartość do zapisania (serializowana przez msgspec).
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        self._init_otel_metrics()

        effective_ttl = ttl if ttl is not None else self._default_ttl

        try:
            data = msgspec_dumps_bytes(value)
        except Exception as exc:
            logger.error("[CACHE] Serialization failed for %s: %s", key, exc)
            return

        # L1 pod blokadą
        with self._lock:
            self._set_l1(key, data, effective_ttl)

        # L2
        if self._diskcache is not None:
            try:
                t0 = time.monotonic()
                await anyio.to_thread.run_sync(
                    lambda: self._diskcache.set(key, data, expire=effective_ttl),
                )
                elapsed = time.monotonic() - t0
                self._record_l2_latency("set", elapsed)
            except Exception as exc:
                logger.debug("[CACHE] L2 set failed for %s: %s", key, exc)

    async def set_many(
        self,
        mapping: dict[str, Any],
        ttl: int | None = None,
    ) -> None:
        """Zapisz wiele wartości w cache'u jednocześnie.

        Batchuje L1 i L2 operacje. L2 sety są batchowane w jednym
        ``anyio.to_thread.run_sync``.

        Args:
            mapping: Słownik {klucz: wartość} do zapisania.
            ttl: TTL w sekundach. Domyślnie self._default_ttl.
        """
        self._init_otel_metrics()

        effective_ttl = ttl if ttl is not None else self._default_ttl

        # Serializacja poza blokadą
        serialized: dict[str, bytes] = {}
        for key, value in mapping.items():
            try:
                serialized[key] = msgspec_dumps_bytes(value)
            except Exception as exc:
                logger.error("[CACHE] Serialization failed for %s: %s", key, exc)

        # L1 batch pod blokadą (_set_l1 zapisuje evictions + size gauge)
        with self._lock:
            for key, data in serialized.items():
                self._set_l1(key, data, effective_ttl)

        # L2 batch
        if self._diskcache is not None and serialized:
            try:
                t0 = time.monotonic()
                await anyio.to_thread.run_sync(
                    lambda: self._set_diskcache_batch(serialized, effective_ttl),
                )
                self._record_l2_latency("set_many", time.monotonic() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 set_many failed: %s", exc)

    def _set_diskcache_batch(self, mapping: dict[str, bytes], expire: int) -> None:
        """Batch set w diskcache (synchroniczny, wołany w wątku)."""
        if self._diskcache is None:
            return
        for key, data in mapping.items():
            self._diskcache.set(key, data, expire=expire)

    async def delete(self, key: str) -> None:
        """Usuń wartość z cache'u (L1 + L2)."""
        self._init_otel_metrics()
        with self._lock:
            self._delete_l1(key)
            self._update_cache_size_gauge()
        if self._diskcache is not None:
            try:
                t0 = time.monotonic()
                await anyio.to_thread.run_sync(self._diskcache.delete, key)
                self._record_l2_latency("delete", time.monotonic() - t0)
            except Exception as exc:
                logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    async def delete_many(self, *keys: str) -> None:
        """Usuń wiele wartości z cache'u (L1 + L2)."""
        self._init_otel_metrics()
        with self._lock:
            for key in keys:
                self._delete_l1(key)
            self._update_cache_size_gauge()
        if self._diskcache is not None:
            for key in keys:
                try:
                    await anyio.to_thread.run_sync(self._diskcache.delete, key)
                except Exception as exc:
                    logger.debug("[CACHE] L2 delete failed for %s: %s", key, exc)

    # ══════════════════════════════════════════════════════════════════════
    # Prefix operations
    # ══════════════════════════════════════════════════════════════════════

    def _clear_diskcache_prefix(self, pattern: str) -> None:
        """Usuń z L2 (diskcache) wszystkie klucze zaczynające się od patternu.

        Iteruje po wszystkich kluczach w diskcache i usuwa pasujące.
        Wydajność: O(n) gdzie n = liczba kluczy w L2.
        Dla typowych rozmiarów cache (<100k kluczy) jest to akceptowalne.
        """
        if self._diskcache is None:
            return
        for key in list(self._diskcache):
            if isinstance(key, str) and key.startswith(pattern):
                del self._diskcache[key]

    def _delete_l1_prefix(self, pattern: str) -> list[str]:
        """Usuń z L1 (RAM) wszystkie klucze zaczynające się od patternu.

        Musi być wywołane z self._lock.

        Returns:
            Lista usuniętych kluczy.
        """
        keys_to_delete = [k for k in self._ram_cache if k.startswith(pattern)]
        for k in keys_to_delete:
            del self._ram_cache[k]
        return keys_to_delete

    async def clear(self, prefix: str | None = None) -> None:
        """Wyczyść cache — całość lub tylko klucze z danym prefixem.

        Gdy ``prefix`` jest podany, czyści L1 (RAM) + L2 (diskcache/SQLite)
        klucze zaczynające się od prefixu.

        Gdy ``prefix`` jest None, czyści cały L1 RAM oraz L2 diskcache.

        Args:
            prefix: Jeśli podany, usuwa tylko klucze zaczynające się od prefixu.
                    Jeśli None, czyści cały cache (L1 + L2).
        """
        self._init_otel_metrics()

        if prefix is not None:
            pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
            # L1 (RAM) cleanup pod blokadą
            with self._lock:
                self._delete_l1_prefix(pattern)
                self._update_cache_size_gauge()
            # L2 (diskcache/SQLite) cleanup
            if self._diskcache is not None:
                try:
                    await anyio.to_thread.run_sync(self._clear_diskcache_prefix, pattern)
                except Exception as exc:
                    logger.debug("[CACHE] L2 prefix clear failed for %s: %s", pattern, exc)
            return

        # Full clear
        with self._lock:
            old_size = len(self._ram_cache)
            self._ram_cache.clear()
            self._update_cache_size_gauge()
        if old_size > 0:
            self._record_evictions(old_size)
        if self._diskcache is not None:
            try:
                await anyio.to_thread.run_sync(self._diskcache.clear)
            except Exception as exc:
                logger.debug("[CACHE] L2 clear failed: %s", exc)

    async def keys(self, prefix: str = "") -> list[str]:
        """Zwróć listę kluczy cache z danym prefixem (tylko L1 RAM).

        Args:
            prefix: Prefiks do filtrowania kluczy (np. ``"risk_threshold:"``).
                    Domyślnie "" = wszystkie klucze.

        Returns:
            Lista kluczy (str) w L1 RAM zaczynających się od prefixu.
        """
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        with self._lock:
            return [k for k in self._ram_cache if k.startswith(pattern)]

    async def delete_prefix_async(self, prefix: str) -> int:
        """Async version: usuwa wszystkie klucze z danym prefixem (L1 + L2).

        Czyści L1 (RAM) i L2 (diskcache/SQLite) dla wszystkich kluczy
        zaczynających się od podanego prefixu.

        Args:
            prefix: Prefiks kluczy do usunięcia (np. "risk_threshold:").

        Returns:
            Liczba usuniętych wpisów z L1 (RAM).
        """
        self._init_otel_metrics()
        pattern = prefix.rstrip("*") if prefix.endswith("*") else prefix
        # L1 (RAM) cleanup pod blokadą
        with self._lock:
            deleted = self._delete_l1_prefix(pattern)
            self._update_cache_size_gauge()
        # L2 (diskcache/SQLite) cleanup
        if self._diskcache is not None:
            try:
                await anyio.to_thread.run_sync(self._clear_diskcache_prefix, pattern)
            except Exception as exc:
                logger.debug("[CACHE] L2 prefix delete failed for %s: %s", pattern, exc)
        if deleted:
            self._record_evictions(len(deleted))
        return len(deleted)

    def delete_prefix_sync(self, prefix: str) -> int:
        """Sync version: usuwa wszystkie klucze z danym prefixem (L1 + L2).

        Czyści L1 (RAM) i L2 (diskcache/SQLite) przez ``_clear_diskcache_prefix``.

        Args:
            prefix: Prefiks kluczy do usunięcia (np. "risk_threshold:").

        Returns:
            Liczba usuniętych wpisów z L1 (RAM).
        """
        self._init_otel_metrics()
        with self._lock:
            deleted = self._delete_l1_prefix(prefix)
            self._update_cache_size_gauge()
            if deleted:
                self._record_evictions(len(deleted))
        if self._diskcache is not None:
            try:
                self._clear_diskcache_prefix(prefix)
            except Exception as exc:
                logger.debug("[CACHE] L2 prefix clear failed for %s: %s", prefix, exc)
        return len(deleted)

    # ══════════════════════════════════════════════════════════════════════
    # Sync methods (L1 RAM only — for use in sync services)
    # ══════════════════════════════════════════════════════════════════════

    def delete_sync(self, key: str) -> None:
        """Sync version: usuwa z L1 (RAM) cache.

        Zgodnie z wzorcem get_sync/set_sync — operuje tylko na L1 RAM.
        Thread-safe przez ``self._lock``.

        Args:
            key: Klucz cache do usunięcia.
        """
        self._init_otel_metrics()
        with self._lock:
            self._delete_l1(key)
            self._update_cache_size_gauge()

    def get_sync(self, key: str) -> Any | None:
        """Sync version: sprawdza tylko L1 (RAM) cache.

        Przydatne dla synchronicznych serwisów jak CurrencyConverter.
        L2 (diskcache/SQLite) jest pomijane, bo wymaga async.
        Thread-safe przez ``self._lock``.

        Args:
            key: Klucz cache.

        Returns:
            Zdeserializowana wartość lub None.
        """
        self._init_otel_metrics()
        with self._lock:
            value, found = self._get_l1(key)
        if found:
            self._record_hit("L1")
            return value
        self._record_miss()
        return None

    def set_sync(
        self,
        key: str,
        value: Any,
        ttl: int | None = None,
    ) -> None:
        """Sync version: zapisuje tylko w L1 (RAM) cache.

        Thread-safe przez ``self._lock``.

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
        with self._lock:
            self._set_l1(key, data, effective_ttl)

    # ══════════════════════════════════════════════════════════════════════
    # get_or_compute — z cache stampede protection
    # ══════════════════════════════════════════════════════════════════════

    async def get_or_compute(
        self,
        key: str,
        compute_func,
        ttl: int | None = None,
    ) -> Any:
        """Pobierz z cache'u lub oblicz i zapisz.

        Z cache stampede protection: per-key ``anyio.Lock`` z double-check.
        Gdy wiele współbieżnych zadań żąda tego samego klucza, tylko jedno
        wywołuje ``compute_func()`` — pozostałe czekają na wynik.

        Args:
            key: Klucz cache.
            compute_func: Async funkcja do obliczenia wartości (``Callable[[], Awaitable[Any]]``).
            ttl: TTL w sekundach.

        Returns:
            Wartość z cache'u lub świeżo obliczona.
        """
        # Fast path — już w cache'u
        cached = await self.get(key)
        if cached is not None:
            return cached

        # Cache stampede protection — per-key anyio.Lock
        lock = self._get_compute_lock(key)
        async with lock:
            # Double-check po przejęciu locka
            cached = await self.get(key)
            if cached is not None:
                return cached

            # Oblicz i zapisz
            value = await compute_func()
            await self.set(key, value, ttl=ttl)
            return value


# ── Global singleton (thread-safe dla free-threaded Python) ──────────────

_default_cache: NexusCache | None = None
_default_cache_lock = threading.Lock()


def get_cache(
    cache_dir: str | Path | None = None,
    default_ttl: int = 300,
) -> NexusCache:
    """Zwraca globalną instancję NexusCache (singleton z thread-safe init).

    Args:
        cache_dir: Katalog dla cache'u SQLite.
        default_ttl: Domyślny TTL w sekundach.

    Returns:
        Globalna instancja NexusCache.
    """
    global _default_cache
    if _default_cache is None:
        with _default_cache_lock:
            if _default_cache is None:
                if cache_dir is None:
                    cache_dir = Path(os.getcwd()) / "app_data" / "cache"
                _default_cache = NexusCache(cache_dir=cache_dir, default_ttl=default_ttl)
    return _default_cache
