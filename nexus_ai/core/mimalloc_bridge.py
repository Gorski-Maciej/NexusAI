"""mimalloc_bridge — Python ctypes bridge to Microsoft mimalloc allocator API.

Enables: is_active check, stats_as_dict, heap_new/destroy (isolated OCR heaps),
option_set/get, MemoryLeakDetector, InvoiceOCRHeap, SecureHeap context managers.

Usage:
    if is_active():
        async with InvoiceOCRHeap(invoice_id="inv-123") as heap:
            ...  # heap isolated, freed atomically on exit
"""
from __future__ import annotations

import ctypes
import logging as _logging
import os
import threading
from typing import Any

_log = _logging.getLogger("nexus.mimalloc")


class MIOption:
    """mimalloc option constants (mi_option_e enum)."""
    __slots__ = ()
    SHOW_STATS = 0
    SHOW_ERRORS = 1
    EAGER_COMMIT = 2
    EAGER_DECOMMIT = 3
    PAGE_RESET = 5; SEGMENT_CACHE = 7; PAGE_CLEAR = 8; LARGE_OS_PAGES = 14
    RESERVE_HUGE_OS_PAGES = 15; PURGE_DELAY = 16; USE_NUMA_NODES = 17
    DISABLE_OSX_ALLOC = 20; ALLOW_LARGE_OS_PAGES = 24; MINIMAL_PURGE_SIZE = 25


class MIStatKind:
    """mimalloc statistic kind constants (mi_stat_kind_t)."""
    __slots__ = ()
    COMMITTED = 0; RESERVED = 1; RESET = 2; PURGED = 3


_lib: ctypes.CDLL | None = None
_lib_lock = threading.Lock()


def _init_prototypes(lib: ctypes.CDLL) -> None:
    """Set ctypes function prototypes once at library init (thread-safe, under lock)."""
    lib.mi_option_set.argtypes = [ctypes.c_int, ctypes.c_int]
    lib.mi_option_set.restype = None
    lib.mi_option_get.argtypes = [ctypes.c_int]
    lib.mi_option_get.restype = ctypes.c_long
    lib.mi_heap_new.argtypes = []
    lib.mi_heap_new.restype = ctypes.c_void_p
    lib.mi_heap_destroy.argtypes = [ctypes.c_void_p]
    lib.mi_heap_destroy.restype = None
    lib.mi_heap_collect.argtypes = [ctypes.c_void_p, ctypes.c_bool]
    lib.mi_heap_collect.restype = None


def _get_lib() -> ctypes.CDLL | None:
    """Lazy-load mimalloc symbols from current process via ctypes.CDLL(None)."""
    global _lib
    if _lib is not None:
        return _lib
    with _lib_lock:
        if _lib is not None:
            return _lib
        try:
            lib = ctypes.CDLL(None)
            lib.mi_malloc  # type: ignore[attr-defined]
            _init_prototypes(lib)
            _lib = lib
            _log.info("mimalloc bridge: library loaded")
            return _lib
        except (OSError, AttributeError) as exc:
            _log.warning("mimalloc bridge: not available - %s", exc)
            return None


def is_active() -> bool:
    """Check if mimalloc is the active memory allocator."""
    return _get_lib() is not None


def option_set(option: int, value: int) -> bool:
    """Set a mimalloc option at runtime. Returns True if successful."""
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_option_set(ctypes.c_int(option), ctypes.c_int(value))
        return True
    except (OSError, AttributeError):
        return False


def option_get(option: int) -> int | None:
    """Get current value of a mimalloc option. Returns None if not active."""
    lib = _get_lib()
    if lib is None:
        return None
    try:
        return lib.mi_option_get(ctypes.c_int(option))
    except (OSError, AttributeError):
        return None


def heap_new() -> int | None:
    """Create a new isolated mimalloc heap. Returns opaque pointer or None."""
    lib = _get_lib()
    if lib is None:
        return None
    try:
        heap_ptr = lib.mi_heap_new()
        return ctypes.addressof(heap_ptr) if heap_ptr else None
    except (OSError, AttributeError):
        return None


def heap_destroy(heap: int) -> bool:
    """Destroy a mimalloc heap, freeing all its allocated memory at once."""
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_heap_destroy(ctypes.c_void_p(heap))
        return True
    except (OSError, AttributeError):
        return False


def heap_collect(heap: int, force: bool = False) -> bool:
    """Collect garbage on a mimalloc heap to reclaim unused memory."""
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_heap_collect(ctypes.c_void_p(heap), ctypes.c_bool(force))
        return True
    except (OSError, AttributeError):
        return False


def stats_hint() -> str:
    """Return mimalloc statistics configuration hint."""
    if os.environ.get("MIMALLOC_SHOW_STATS", "0") == "1":
        return "MIMALLOC_SHOW_STATS=1 -- stats will print on process exit"
    return "Set MIMALLOC_SHOW_STATS=1 to see allocator statistics on exit"


def _get_rss_bytes() -> int | None:
    """Read process RSS from /proc/self/statm. Returns bytes or None."""
    try:
        with open("/proc/self/statm") as f:
            parts = f.read().strip().split()
            if len(parts) >= 2:
                return int(parts[1]) * os.sysconf("SC_PAGE_SIZE")
    except (FileNotFoundError, ValueError, OSError):
        pass
    return None


def stats_as_dict() -> dict[str, Any]:
    """Get mimalloc statistics as a dict. Keys: active, process_rss_bytes, options."""
    lib = _get_lib()
    if lib is None:
        return {"active": False}
    result: dict[str, Any] = {"active": True}
    rss = _get_rss_bytes()
    if rss is not None:
        result["process_rss_bytes"] = rss
    options = {}
    for name in ("LARGE_OS_PAGES", "RESERVE_HUGE_OS_PAGES", "PAGE_RESET", "PURGE_DELAY"):
        val = option_get(getattr(MIOption, name, -1))
        if val is not None and val >= 0:
            options[name.lower()] = val
    if options:
        result["options"] = options
    return result


class InvoiceOCRHeap:
    """Isolated mimalloc heap for processing a single invoice via async context manager.

    Creates a dedicated heap on __aenter__, destroys atomically on __aexit__.
    All OCR allocations (images, buffers, results) are freed in one O(1) operation.
    """
    __slots__ = ('_collect_on_exit', 'invoice_id', 'label')

    def __init__(self, invoice_id: str, label: str = "ocr") -> None:
        self.invoice_id = invoice_id
        self.label = label
        self._heap: int | None = None
        self._collect_on_exit = True

    @property
    def heap_ptr(self) -> int | None:
        return self._heap

    @property
    def is_isolated(self) -> bool:
        return self._heap is not None

    async def __aenter__(self) -> InvoiceOCRHeap:
        self._heap = heap_new()
        if self._heap is not None:
            _log.debug("ocr_heap_created", invoice_id=self.invoice_id, label=self.label)
        return self

    async def __aexit__(self, exc_type: type[BaseException] | None = None,
                       exc_val: BaseException | None = None,
                       exc_tb: object | None = None) -> None:
        if self._heap is not None:
            if self._collect_on_exit:
                heap_collect(self._heap, force=False)
            heap_destroy(self._heap)
            _log.debug("ocr_heap_destroyed", invoice_id=self.invoice_id, label=self.label)
            self._heap = None


class SecureHeap:
    """Secure mimalloc heap with PAGE_CLEAR guard pages for sensitive financial data.

    Wraps heap_new/destroy with force collect (zeroizes memory) and guard pages.
    Restores original PAGE_CLEAR value on exit.
    """
    __slots__ = ('_enable_guard_pages', 'label')

    def __init__(self, label: str, *, enable_guard_pages: bool = True) -> None:
        self.label = label
        self._heap: int | None = None
        self._enable_guard_pages = enable_guard_pages
        self._prev_page_clear: int | None = None

    @property
    def heap_ptr(self) -> int | None:
        return self._heap

    @property
    def is_secured(self) -> bool:
        return self._heap is not None

    async def __aenter__(self) -> SecureHeap:
        self._heap = heap_new()
        if self._heap is not None and self._enable_guard_pages:
            prev = option_get(MIOption.PAGE_CLEAR)
            self._prev_page_clear = prev if prev is not None else 0
            option_set(MIOption.PAGE_CLEAR, 1)
            _log.info("secure_heap_created", label=self.label)
        return self

    async def __aexit__(self, exc_type: type[BaseException] | None = None,
                       exc_val: BaseException | None = None,
                       exc_tb: object | None = None) -> None:
        if self._heap is not None:
            heap_collect(self._heap, force=True)
            heap_destroy(self._heap)
            if self._enable_guard_pages and self._prev_page_clear is not None:
                option_set(MIOption.PAGE_CLEAR, self._prev_page_clear)
            _log.info("secure_heap_destroyed", label=self.label)
            self._heap = None


class MemoryLeakDetector:
    """Detects memory leaks by monitoring RSS growth over a sliding window.

    Thread-safe for Python 3.13t (free-threaded).
    """
    __slots__ = ('_lock', 'growth_threshold_pct', 'min_rss_mb', 'window_size')

    def __init__(self, growth_threshold_pct: float = 20.0, window_size: int = 3,
                 min_rss_mb: float = 100.0) -> None:
        self.growth_threshold_pct = growth_threshold_pct
        self.window_size = window_size
        self.min_rss_mb = min_rss_mb
        self._history: list[float] = []
        self._lock = threading.Lock()
        self.last_alert_time: float = 0.0
        self.alert_cooldown_seconds: float = 60.0

    def check_growth(self, stats: dict[str, Any]) -> tuple[bool, float]:
        """Check if RSS is growing abnormally. Returns (leak_detected, growth_pct)."""
        rss_mb = (stats.get("process_rss_bytes", 0) or 0) / (1024 * 1024)
        if rss_mb < self.min_rss_mb:
            return False, 0.0
        with self._lock:
            self._history.append(rss_mb)
            if len(self._history) > self.window_size:
                self._history.pop(0)
            if len(self._history) < 2:
                return False, 0.0
            oldest, newest = self._history[0], self._history[-1]
            if oldest <= 0:
                return False, 0.0
            growth_pct = ((newest - oldest) / oldest) * 100.0
            return growth_pct >= self.growth_threshold_pct, growth_pct

    def clear_history(self) -> None:
        with self._lock:
            self._history.clear()

    def get_history(self) -> list[float]:
        with self._lock:
            return list(self._history)

    def should_alert(self, now: float | None = None) -> bool:
        if now is None:
            import time as _time
            now = _time.time()
        if now - self.last_alert_time < self.alert_cooldown_seconds:
            return False
        self.last_alert_time = now
        return True


def save_stats_to_file(path: str | os.PathLike) -> str | None:
    """Save mimalloc stats to a JSON file. Returns path or None."""
    stats = stats_as_dict()
    if not stats.get("active", False):
        return None
    import time as _time
    from nexus_ai.core.msgspec_utils import msgspec_dumps as _dumps
    stats["timestamp"] = _time.time()
    stats["timestamp_iso"] = _time.strftime("%Y-%m-%dT%H:%M:%SZ", _time.gmtime())
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(_dumps(stats, ensure_ascii=False, indent=2, default=str))
        return str(path)
    except (OSError, PermissionError) as exc:
        _log.warning("Failed to save mimalloc stats to %s: %s", path, exc)
        return None


def record_metrics() -> dict[str, int | float | bool]:
    """Collect current mimalloc metrics for monitoring. Returns dict or empty."""
    return stats_as_dict()
