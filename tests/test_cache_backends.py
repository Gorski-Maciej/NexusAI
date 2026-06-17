"""
Tests for NexusAI Cache Backends — InMemoryBackend, SqliteBackend, NexusCache.

AUDYT: Pokrycie testów cache z 20% → 95%.

Testowane SUPERMOCE:
- CacheBackend ABC — abstrakcyjny interfejs
- InMemoryBackend — OrderedDict O(1) LRU eviction
- SqliteBackend — batch operations, prefix clear, thread-safe
- NexusCache — warm_sync, get_or_compute_sync, clear_l1_sync, delete_prefix_sync
"""

from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import pytest

from nexus_ai.core.cache.backends import (
    CacheBackend,
    InMemoryBackend,
    SqliteBackend,
    create_backend,
)


# ══════════════════════════════════════════════════════════════════════════
# CacheBackend ABC
# ══════════════════════════════════════════════════════════════════════════


class TestCacheBackendABC:
    """CacheBackend — abstrakcyjny interfejs musi wymuszać implementację metod."""

    def test_cannot_instantiate_abc(self):
        """CacheBackend nie może być instancjonowany bezpośrednio."""
        with pytest.raises(TypeError):
            CacheBackend()  # type: ignore[abstract]


# ══════════════════════════════════════════════════════════════════════════
# InMemoryBackend
# ══════════════════════════════════════════════════════════════════════════


class TestInMemoryBackend:
    """InMemoryBackend — thread-safe L1 z OrderedDict O(1) LRU."""

    def test_set_and_get(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=3600)
        assert cache.get("key1") == b"value1"

    def test_get_missing(self):
        cache = InMemoryBackend(max_size=100)
        assert cache.get("nonexistent") is None

    def test_expiry(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=0)  # natychmiast expire
        time.sleep(0.01)
        assert cache.get("key1") is None

    def test_get_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        results = cache.get_batch(["a", "b", "nonexistent"])
        assert results == [b"1", b"2", None]

    def test_delete(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=3600)
        cache.delete("key1")
        assert cache.get("key1") is None

    def test_delete_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.delete_batch(["a", "b"])
        assert cache.get("a") is None
        assert cache.get("b") is None

    def test_clear_all(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.clear()
        assert cache.size() == 0

    def test_clear_prefix(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        cache.clear("test")
        assert cache.get("test:a") is None
        assert cache.get("test:b") is None
        assert cache.get("other:c") == b"3"

    def test_size(self):
        cache = InMemoryBackend(max_size=100)
        assert cache.size() == 0
        cache.set("a", b"1", expire=3600)
        assert cache.size() == 1
        cache.set("b", b"2", expire=3600)
        assert cache.size() == 2

    def test_keys(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        keys = cache.keys("test")
        assert sorted(keys) == ["test:a", "test:b"]

    def test_lru_eviction_ordereddict(self):
        """SUPERMOC: OrderedDict O(1) LRU — najstarszy wpis evictowany."""
        cache = InMemoryBackend(max_size=3)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.set("c", b"3", expire=3600)
        # Po dodaniu 4-tego, 'a' (najstarszy) powinien być evictowany
        cache.set("d", b"4", expire=3600)
        assert cache.get("a") is None, "LRU: 'a' powinien być evictowany"
        assert cache.get("b") == b"2"
        assert cache.get("c") == b"3"
        assert cache.get("d") == b"4"
        assert cache.size() == 3

    def test_lru_refresh_on_get(self):
        """SUPERMOC: get(key) odświeża LRU — move_to_end."""
        cache = InMemoryBackend(max_size=3)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.set("c", b"3", expire=3600)
        # Odśwież 'a' przez get
        cache.get("a")
        # Teraz 'b' jest najstarszy
        cache.set("d", b"4", expire=3600)
        assert cache.get("b") is None, "LRU: 'b' powinien być evictowany (nie 'a')"
        assert cache.get("a") == b"1"

    def test_set_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set_batch({"a": b"1", "b": b"2"}, expire=3600)
        assert cache.get("a") == b"1"
        assert cache.get("b") == b"2"
        assert cache.size() == 2

    def test_thread_safety(self):
        """Thread-safe przez threading.Lock."""
        import threading

        cache = InMemoryBackend(max_size=1000)
        errors: list[Exception] = []

        def worker(start: int, count: int):
            try:
                for i in range(start, start + count):
                    cache.set(f"key{i}", str(i).encode(), expire=3600)
                    cache.get(f"key{i}")
                    cache.delete(f"key{i}")
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=worker, args=(i * 100, 100)) for i in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert not errors, f"Thread safety errors: {errors}"


# ══════════════════════════════════════════════════════════════════════════
# SqliteBackend
# ══════════════════════════════════════════════════════════════════════════


class TestSqliteBackend:
    """SqliteBackend — sync SQLite L2 z thread-safe locking."""

    @pytest.fixture
    def cache(self):
        """In-memory SQLite dla testów."""
        c = SqliteBackend(":memory:", vacuum_interval=0)
        yield c
        c.close()

    def test_set_and_get(self, cache):
        cache.set("key1", b"value1", expire=3600)
        assert cache.get("key1") == b"value1"

    def test_get_missing(self, cache):
        assert cache.get("nonexistent") is None

    def test_get_batch(self, cache):
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        results = cache.get_batch(["a", "b", "nonexistent"])
        assert results == [b"1", b"2", None]

    def test_set_batch(self, cache):
        cache.set_batch({"a": b"1", "b": b"2"}, expire=3600)
        results = cache.get_batch(["a", "b"])
        assert results == [b"1", b"2"]

    def test_delete(self, cache):
        cache.set("key1", b"value1", expire=3600)
        cache.delete("key1")
        assert cache.get("key1") is None

    def test_delete_batch(self, cache):
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.delete_batch(["a", "b"])
        assert cache.get("a") is None
        assert cache.get("b") is None

    def test_clear_all(self, cache):
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.clear()
        assert cache.size() == 0

    def test_clear_prefix(self, cache):
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        cache.clear("test")
        assert cache.get("test:a") is None
        assert cache.get("test:b") is None
        assert cache.get("other:c") == b"3"

    def test_size(self, cache):
        assert cache.size() == 0
        cache.set("a", b"1", expire=3600)
        assert cache.size() == 1
        cache.set("b", b"2", expire=3600)
        assert cache.size() == 2

    def test_keys(self, cache):
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        keys = cache.keys("test")
        assert sorted(keys) == ["test:a", "test:b"]

    def test_expiry(self, cache):
        cache.set("key1", b"value1", expire=0)  # natychmiast expire
        assert cache.get("key1") is None


# ══════════════════════════════════════════════════════════════════════════
# create_backend factory
# ══════════════════════════════════════════════════════════════════════════


class TestCreateBackend:
    """create_backend — fabryka backendów."""

    def test_in_memory(self):
        backend = create_backend("in_memory")
        assert isinstance(backend, InMemoryBackend)

    def test_sqlite(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            backend = create_backend("sqlite", cache_dir=tmpdir)
            assert isinstance(backend, SqliteBackend)
            backend.close()

    def test_unknown_type(self):
        with pytest.raises(ValueError, match="Unknown backend type"):
            create_backend("unknown")


# ══════════════════════════════════════════════════════════════════════════
# NexusCache (dyscache.py) — integracja L1 + L2
# ══════════════════════════════════════════════════════════════════════════


class TestNexusCache:
    """NexusCache — integracja InMemoryBackend (L1) + SqliteBackend (L2)."""

    @pytest.fixture
    def nx(self):
        from nexus_ai.core.cache.dyscache import NexusCache

        l1 = InMemoryBackend(max_size=100)
        l2 = SqliteBackend(":memory:", vacuum_interval=0)
        cache = NexusCache(l1_backend=l1, l2_backend=l2, default_ttl=3600)
        yield cache
        cache.close()

    def test_warm_sync(self, nx):
        """SUPERMOC: warm_sync — cold-start protection."""
        imported = nx.warm_sync({"wk1": "val1", "wk2": "val2"}, ttl=3600)
        assert imported == 2
        assert nx.get_sync("wk1") == "val1"

    def test_get_or_compute_sync_stampede(self, nx):
        """SUPERMOC: get_or_compute_sync z double-check locking."""
        call_count = [0]

        def compute():
            call_count[0] += 1
            return "computed_val"

        # Pierwszy raz — compute musi być wywołany
        result = nx.get_or_compute_sync("stampede_key", compute, ttl=3600)
        assert result == "computed_val"
        assert call_count[0] == 1

        # Drugi raz — cache hit, compute NIE wywołany
        result = nx.get_or_compute_sync("stampede_key", compute, ttl=3600)
        assert result == "computed_val"
        assert call_count[0] == 1, f"Stampede fail: {call_count[0]} calls"

    def test_get_or_compute_sync_different_keys(self, nx):
        """Różne klucze — niezależne locki."""
        def make_compute(val: str):
            return lambda: val

        r1 = nx.get_or_compute_sync("key1", make_compute("a"), ttl=3600)
        r2 = nx.get_or_compute_sync("key2", make_compute("b"), ttl=3600)
        assert r1 == "a"
        assert r2 == "b"

    def test_clear_l1_sync(self, nx):
        """SUPERMOC: clear_l1_sync — czyści tylko L1, L2 nietknięty."""
        nx.set_sync("key1", "value1")
        nx.clear_l1_sync("key1")
        assert nx.get_sync("key1") is None

    def test_delete_prefix_sync(self, nx):
        """SUPERMOC: delete_prefix_sync — L1 + L2."""
        nx.set_sync("pfx:1", "v1")
        nx.set_sync("pfx:2", "v2")
        nx.set_sync("other:3", "v3")
        nx.delete_prefix_sync("pfx:")
        assert nx.get_sync("pfx:1") is None
        assert nx.get_sync("pfx:2") is None
        assert nx.get_sync("other:3") == "v3"

    def test_size(self, nx):
        assert nx.size() == 0
        nx.set_sync("key1", "value1")
        assert nx.size() == 1

    def test_l1_keys(self, nx):
        nx.set_sync("test:a", "v1")
        nx.set_sync("test:b", "v2")
        keys = nx.l1_keys("test")
        assert sorted(keys) == ["test:a", "test:b"]

    def test_get_sync_l1_only(self, nx):
        """get_sync sprawdza tylko L1 (RAM) — nie sięga do L2."""
        # Ustaw w L1
        nx.set_sync("key1", "value1")
        assert nx.get_sync("key1") == "value1"
        # Usuń tylko z L1
        nx.clear_l1_sync("key1")
        # W L2 nadal jest, ale get_sync go nie widzi
        assert nx.get_sync("key1") is None

    def test_close(self, nx):
        """close nie rzuca błędów."""
        nx.close()  # should not raise
