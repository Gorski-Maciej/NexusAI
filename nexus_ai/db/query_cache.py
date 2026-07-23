"""
query_cache.py — F2 v7.0.1: Query Plan Cache z LRU i auto-detekcją podobnych SQL.

Raport v7.0 Rec #4: Query Plan Cache — cache planów zapytań dla często
używanych SQL patterns. Auto-detekcja podobnych zapytań przez parametryzację.
Integracja z DuckDBManager.execute() i execute_arrow().

Enterprise v7.0.1:
  - LRU cache: max 256 wpisów, TTL 300s
  - SQL fingerprint: normalizacja literałów → szablon
  - Auto-fingerprint: wykrywanie podobnych zapytań
  - Stats: hit rate, miss rate, memory usage
  - Thread-safe: threading.Lock
  - DuckDB prepared statement integration
"""
from __future__ import annotations

import re
import threading
import time
from collections import OrderedDict
from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.query_cache")


# ── SQL Fingerprint ────────────────────────────────────────────────────────

# Wzorce do normalizacji literałów w SQL
_LITERAL_PATTERNS = [
    (re.compile(r"'[^']*'"), "?"),           # String literals: 'foo' → ?
    (re.compile(r"\"[^\"]*\""), "?"),         # Double-quoted: "foo" → ?
    (re.compile(r"\b\d+\.?\d*\b"), "?"),     # Numbers: 123, 45.67 → ?
    (re.compile(r"\bIN\s*\([^)]+\)", re.I), "IN (?)"),  # IN clauses
]


def sql_fingerprint(query: str) -> str:
    """Generuj odcisk palca zapytania SQL przez normalizację literałów.

    'SELECT * FROM invoices WHERE amount > 1000 AND nip = '1234567890''
    →
    'SELECT * FROM invoices WHERE amount > ? AND nip = ?'

    Args:
        query: Surowe zapytanie SQL.

    Returns:
        Znormalizowany szablon (fingerprint).
    """
    normalized = query.strip()
    for pattern, replacement in _LITERAL_PATTERNS:
        normalized = pattern.sub(replacement, normalized)
    # Normalizuj whitespace
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized




# ── Cache Entry ────────────────────────────────────────────────────────────


@dataclass
class CachedPlan:
    """Wpis w cache planów zapytań."""
    fingerprint: str
    original_query: str
    plan: Any  # DuckDB prepared statement / query plan
    created_at: float = field(default_factory=time.monotonic)
    last_used: float = field(default_factory=time.monotonic)
    hit_count: int = 1
    total_time_saved_ms: float = 0.0

    @property
    def age_seconds(self) -> float:
        return time.monotonic() - self.created_at

    def touch(self) -> None:
        self.last_used = time.monotonic()
        self.hit_count += 1


# ── Query Plan Cache ───────────────────────────────────────────────────────


class QueryPlanCache:
    """LRU cache planów zapytań DuckDB z auto-detekcją podobnych SQL.

    Raport v7.0 Rec #4 + INNOWACJA #3 (Query Accelerator):
    - Cache'uje plany zapytań dla często używanych wzorców SQL
    - Auto-detekcja podobnych zapytań przez fingerprint
    - LRU eviction przy przekroczeniu limitu
    - TTL dla nieużywanych wpisów
    - Statystyki hit/miss rate

    Usage:
        cache = QueryPlanCache(max_entries=256, ttl_seconds=300)
        plan = cache.get("SELECT * FROM invoices WHERE nip = ?")
        if not plan:
            plan = duckdb.execute("EXPLAIN ...")
            cache.put(query, plan)
    """

    def __init__(
        self,
        max_entries: int = 256,
        ttl_seconds: float = 300.0,
        enable_fingerprint: bool = True,
    ) -> None:
        self._max_entries = max_entries
        self._ttl_seconds = ttl_seconds
        self._enable_fingerprint = enable_fingerprint
        self._cache: OrderedDict[str, CachedPlan] = OrderedDict()
        self._lock = threading.Lock()
        self._stats = {
            "hits": 0, "misses": 0, "evictions": 0,
            "total_time_saved_ms": 0.0, "fingerprint_matches": 0,
        }

    # ── Core API ──────────────────────────────────────────────────────

    def get(self, query: str) -> CachedPlan | None:
        """Pobierz plan zapytania z cache.

        Najpierw szuka dokładnego dopasowania, potem przez fingerprint.
        """
        with self._lock:
            # 1. Dokładne dopasowanie
            if query in self._cache:
                plan = self._cache[query]
                if self._is_expired(plan):
                    self._evict(query)
                    self._stats["misses"] += 1
                    return None
                plan.touch()
                self._cache.move_to_end(query)
                self._stats["hits"] += 1
                self._stats["total_time_saved_ms"] += plan.total_time_saved_ms
                return plan

            # 2. Dopasowanie przez fingerprint
            if self._enable_fingerprint:
                fp = sql_fingerprint(query)
                for cached_query, plan in reversed(list(self._cache.items())):
                    if sql_fingerprint(cached_query) == fp and not self._is_expired(plan):
                        plan.touch()
                        self._cache.move_to_end(cached_query)
                        self._stats["hits"] += 1
                        self._stats["fingerprint_matches"] += 1
                        self._stats["total_time_saved_ms"] += plan.total_time_saved_ms
                        return plan

            self._stats["misses"] += 1
            return None

    def put(self, query: str, plan: Any, avg_time_ms: float = 0.0) -> CachedPlan:
        """Dodaj plan zapytania do cache."""
        fp = sql_fingerprint(query) if self._enable_fingerprint else query
        entry = CachedPlan(
            fingerprint=fp,
            original_query=query,
            plan=plan,
            total_time_saved_ms=avg_time_ms,
        )

        with self._lock:
            # Evict jeśli pełny
            if len(self._cache) >= self._max_entries:
                self._evict_lru()
                self._stats["evictions"] += 1

            self._cache[query] = entry
            return entry

    def invalidate(self, query: str | None = None) -> int:
        """Unieważnij wpisy w cache.

        Args:
            query: Konkretne zapytanie do unieważnienia, lub None = wszystkie.

        Returns:
            Liczba usuniętych wpisów.
        """
        with self._lock:
            if query is None:
                count = len(self._cache)
                self._cache.clear()
                return count
            if query in self._cache:
                del self._cache[query]
                return 1
            return 0

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki cache."""
        with self._lock:
            total = self._stats["hits"] + self._stats["misses"]
            hit_rate = (self._stats["hits"] / max(total, 1)) * 100
            return {
                "entries": len(self._cache),
                "max_entries": self._max_entries,
                "hits": self._stats["hits"],
                "misses": self._stats["misses"],
                "hit_rate_pct": round(hit_rate, 1),
                "evictions": self._stats["evictions"],
                "fingerprint_matches": self._stats["fingerprint_matches"],
                "total_time_saved_ms": round(self._stats["total_time_saved_ms"], 1),
                "ttl_seconds": self._ttl_seconds,
                "fingerprint_enabled": self._enable_fingerprint,
            }

    # ── Internal ───────────────────────────────────────────────────────

    def _is_expired(self, plan: CachedPlan) -> bool:
        """Sprawdź czy wpis wygasł (TTL)."""
        return (time.monotonic() - plan.last_used) > self._ttl_seconds

    def _evict(self, query: str) -> None:
        """Usuń konkretny wpis."""
        self._cache.pop(query, None)

    def _evict_lru(self) -> None:
        """Usuń najstarszy wpis (Least Recently Used)."""
        try:
            self._cache.popitem(last=False)
        except KeyError:
            pass

    def clear(self) -> None:
        """Wyczyść cały cache."""
        with self._lock:
            self._cache.clear()
            logger.info("[QUERY-CACHE] Cleared all entries")


# ── Global singleton ───────────────────────────────────────────────────────

_global_cache: QueryPlanCache | None = None
_cache_lock = threading.Lock()


def get_query_cache(
    max_entries: int = 256,
    ttl_seconds: float = 300.0,
) -> QueryPlanCache:
    """Pobierz globalny singleton QueryPlanCache."""
    global _global_cache
    if _global_cache is None:
        with _cache_lock:
            if _global_cache is None:
                _global_cache = QueryPlanCache(
                    max_entries=max_entries,
                    ttl_seconds=ttl_seconds,
                )
                logger.info(
                    "[QUERY-CACHE] Initialized | max=%d | ttl=%.0fs",
                    max_entries, ttl_seconds,
                )
    return _global_cache
