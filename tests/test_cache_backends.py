"""
Tests for NexusAI Cache Backends — InMemoryBackend, DiskBackend, NexusCache.

Zgodnie z decyzją optymalizacyjną: własne backendy zastąpione przez diskcache.
SqliteBackend → DiskBackend (oparty na diskcache.Cache).
"""

from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Any

import pytest

from nexus_ai.core.cache.backends import (
    CacheBackend,
    InMemoryBackend,
    DiskBackend,
    create_backend,
)


# ══════════════════════════════════════════════════════════════════════════
# CacheBackend ABC
# ══════════════════════════════════════════════════════════════════════════


class TestCacheBackendABC:
    """CacheBackend — abstrakcyjny interfejs musi wymuszać implementację metod."""

    def test_cannot_instantiate_abc(self):
        with pytest.raises(TypeError):
            CacheBackend()  # type: ignore[abstract]


# ══════════════════════════════════════════════════════════════════════════
# InMemoryBackend
# ══════════════════════════════════════════════════════════════════════════


class TestInMemoryBackend:
    """InMemoryBackend — tymczasowy katalog z diskcache."""

    def test_set_and_get(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=3600)
        assert cache.get("key1") == b"value1"
        cache.close()

    def test_get_missing(self):
        cache = InMemoryBackend(max_size=100)
        assert cache.get("nonexistent") is None
        cache.close()

    def test_expiry(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=0)
        import time
        time.sleep(0.01)
        assert cache.get("key1") is None
        cache.close()

    def test_get_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        results = cache.get_batch(["a", "b", "nonexistent"])
        assert results == [b"1", b"2", None]
        cache.close()

    def test_delete(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("key1", b"value1", expire=3600)
        cache.delete("key1")
        assert cache.get("key1") is None
        cache.close()

    def test_delete_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.delete_batch(["a", "b"])
        assert cache.get("a") is None
        assert cache.get("b") is None
        cache.close()

    def test_clear_all(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("a", b"1", expire=3600)
        cache.set("b", b"2", expire=3600)
        cache.clear()
        assert cache.size() == 0
        cache.close()

    def test_clear_prefix(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        cache.clear("test")
        assert cache.get("test:a") is None
        assert cache.get("test:b") is None
        assert cache.get("other:c") == b"3"
        cache.close()

    def test_size(self):
        cache = InMemoryBackend(max_size=100)
        assert cache.size() == 0
        cache.set("a", b"1", expire=3600)
        assert cache.size() == 1
        cache.close()

    def test_keys(self):
        cache = InMemoryBackend(max_size=100)
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        keys = cache.keys("test")
        assert sorted(keys) == ["test:a", "test:b"]
        cache.close()

    def test_set_batch(self):
        cache = InMemoryBackend(max_size=100)
        cache.set_batch({"a": b"1", "b": b"2"}, expire=3600)
        assert cache.get("a") == b"1"
        assert cache.get("b") == b"2"
        assert cache.size() == 2
        cache.close()


# ══════════════════════════════════════════════════════════════════════════
# DiskBackend (diskcache)
# ══════════════════════════════════════════════════════════════════════════


class TestDiskBackend:
    """DiskBackend — oparty na diskcache.Cache."""

    @pytest.fixture
    def cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            c = DiskBackend(cache_dir=tmpdir)
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

    def test_keys(self, cache):
        cache.set("test:a", b"1", expire=3600)
        cache.set("test:b", b"2", expire=3600)
        cache.set("other:c", b"3", expire=3600)
        keys = cache.keys("test")
        assert sorted(keys) == ["test:a", "test:b"]

    def test_expiry(self, cache):
        cache.set("key1", b"value1", expire=0)
        assert cache.get("key1") is None


# ══════════════════════════════════════════════════════════════════════════
# create_backend factory
# ══════════════════════════════════════════════════════════════════════════


class TestCreateBackend:
    """create_backend — fabryka backendów."""

    def test_in_memory(self):
        backend = create_backend("in_memory")
        assert isinstance(backend, InMemoryBackend)
        backend.close()

    def test_disk(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            backend = create_backend("disk", cache_dir=tmpdir)
            assert isinstance(backend, DiskBackend)
            backend.close()

    def test_unknown_type(self):
        with pytest.raises(ValueError, match="Unknown backend type"):
            create_backend("unknown")


# ══════════════════════════════════════════════════════════════════════════
# NexusCache (dyscache.py)
# ══════════════════════════════════════════════════════════════════════════


class TestNexusCache:
    """NexusCache — oparty na diskcache."""

    @pytest.fixture
    def nx(self):
        from nexus_ai.core.cache.dyscache import NexusCache
        with tempfile.TemporaryDirectory() as tmpdir:
            backend = DiskBackend(cache_dir=tmpdir)
            cache = NexusCache(backend=backend, default_ttl=3600)
            yield cache
            cache.close()

    def test_warm_sync(self, nx):
        imported = nx.warm_sync({"wk1": "val1", "wk2": "val2"}, ttl=3600)
        assert imported == 2
        assert nx.get_sync("wk1") == "val1"

    def test_get_or_compute_sync_stampede(self, nx):
        call_count = [0]

        def compute():
            call_count[0] += 1
            return "computed_val"

        result = nx.get_or_compute_sync("stampede_key", compute, ttl=3600)
        assert result == "computed_val"
        assert call_count[0] == 1

        result = nx.get_or_compute_sync("stampede_key", compute, ttl=3600)
        assert result == "computed_val"
        assert call_count[0] == 1

    def test_get_or_compute_sync_different_keys(self, nx):
        def make_compute(val: str):
            return lambda: val

        r1 = nx.get_or_compute_sync("key1", make_compute("a"), ttl=3600)
        r2 = nx.get_or_compute_sync("key2", make_compute("b"), ttl=3600)
        assert r1 == "a"
        assert r2 == "b"

    def test_clear_l1_sync(self, nx):
        nx.set_sync("key1", "value1")
        nx.clear_l1_sync("key1")
        assert nx.get_sync("key1") is None

    def test_delete_prefix_sync(self, nx):
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

    def test_get_sync(self, nx):
        nx.set_sync("key1", "value1")
        assert nx.get_sync("key1") == "value1"

    def test_close(self, nx):
        nx.close()
