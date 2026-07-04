"""ML helpers — TimedModelCache, vector store, CPU affinity.

Shared between invoice.py and scheduled.py tasks.
"""

from __future__ import annotations

import os
import threading
from typing import Any

import anyio
import psutil

from nexus_ai.core.cache import get_cache
from nexus_ai.core.logger import get_logger

logger = get_logger()

_DEFAULT_OCR_CONCURRENCY = os.cpu_count() or 4
OCR_INFERENCE_LIMITER = anyio.CapacityLimiter(
    int(os.getenv("NEXUS_MAX_PARALLEL_OCR", str(_DEFAULT_OCR_CONCURRENCY)))
)


class TimedModelCache:
    """Cache instancji modeli ML z TTL, thread-safe dla free-threaded Python."""

    __slots__ = ("_lock", "_models", "_nexus", "_ttl")

    def __init__(self, ttl_seconds: int = 600):
        self._nexus = get_cache(default_ttl=ttl_seconds)
        self._models: dict[str, object] = {}
        self._lock = threading.Lock()
        self._ttl = ttl_seconds

    async def get(self, key: str, loader):
        now = anyio.current_time()
        ttl_key = f"_model_cache_ttl:{key}"
        ttl_entry = self._nexus.get_sync(ttl_key)
        if ttl_entry is not None:
            with self._lock:
                if key in self._models and now - ttl_entry < self._ttl:
                    self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
                    return self._models[key]
                self._models.pop(key, None)
        model = await loader()
        with self._lock:
            self._models[key] = model
        self._nexus.set_sync(ttl_key, now, ttl=self._ttl)
        return model

    def evict_expired(self) -> None:
        with self._lock:
            self._models.clear()

    def release(self, key: str) -> None:
        with self._lock:
            self._models.pop(key, None)
        self._nexus.clear_l1_sync(f"_model_cache_ttl:{key}")


_MODEL_CACHE = TimedModelCache(ttl_seconds=int(os.getenv("NEXUS_MODEL_CACHE_TTL_SEC", "600")))


def pin_worker_cpu_affinity(reserve_core0: bool = True) -> list[int]:
    """Pin worker process to non-UI CPU cores to protect Flet responsiveness."""
    process = psutil.Process()
    all_cores = list(range(psutil.cpu_count(logical=False) or psutil.cpu_count() or 1))
    target = [c for c in all_cores if c != 0] if reserve_core0 and len(all_cores) > 1 else all_cores
    try:
        with process.oneshot():
            current = process.cpu_affinity()
            process.cpu_affinity(target)
        logger.info("[CPU-AFFINITY] Pinned from %s to %s (reserve_core0=%s)", current, target, reserve_core0)
    except (psutil.AccessDenied, psutil.NoSuchProcess) as exc:
        logger.warning("[CPU-AFFINITY] Cannot set affinity: %s", exc)
    except Exception as exc:
        logger.error("[CPU-AFFINITY] Failed: %s", exc)
    return target


def _get_vector_store() -> Any:
    """Get or create vector store (sqlite-vec)."""
    from nexus_ai.db.vector_store import VectorStore
    store = VectorStore("app_data/vectors.db")
    conn = store._get_conn()
    conn.execute("""CREATE TABLE IF NOT EXISTS invoice_vectors (
        id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, contractor_id TEXT NOT NULL,
        vector BLOB NOT NULL, checksum TEXT DEFAULT '', created_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_preferred INTEGER DEFAULT 0)""")
    conn.commit()
    return store


def _simple_features(raw_text: str) -> list[float]:
    """Small dense vector placeholder; replace with embedding model output."""
    return [
        float(len(raw_text)),
        float(sum(ch.isdigit() for ch in raw_text)),
        float(sum(ch.isalpha() for ch in raw_text)),
        float(max(raw_text.count("\n"), 1)),
    ]
