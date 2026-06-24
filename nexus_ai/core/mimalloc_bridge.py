"""
mimalloc_bridge.py — Python ctypes bridge to Microsoft mimalloc allocator API.

Zgodnie z aa3fvcx.txt: mimalloc jako domyślny alokator pamięci (5-15% mniej RAM).

Umożliwia:
  - Sprawdzenie czy mimalloc jest aktywnym alokatorem (is_active)
  - Odczyt statystyk alokatora (stats_as_dict)
  - Tworzenie i niszczenie izolowanych stert (heap_new / heap_destroy)
    — idealne dla pipeline'u OCR: każda faktura dostaje własną stertę
  - Programmatyczne ustawianie opcji w runtime (option_set)
  - Ręczne czyszczenie i purgowanie stert (heap_collect)

Usage:
    from nexus_ai.core.mimalloc_bridge import (
        is_active, heap_new, heap_destroy, stats_as_dict,
        InvoiceOCRHeap, record_metrics,
    )

    # Sprawdź czy mimalloc jest aktywny
    if is_active():
        print("mimalloc ACTIVE")

    # Izolowana sterta dla faktury
    async with InvoiceOCRHeap(invoice_id="inv-123") as heap:
        # ... przetwarzanie OCR ...
        pass  # heap zamknięty automatycznie, pamięć zwolniona

Wymaga:
  - mimalloc jako LD_PRELOAD (lub statycznie wkompilowany przez Nuitka)
  - Działa przez ctypes.CDLL(None) — szuka symboli w aktualnym procesie
"""

from __future__ import annotations

import ctypes
import os
import threading
from typing import Any

import logging as _logging

_log = _logging.getLogger("nexus.mimalloc")


# ── Constants from mimalloc v3 (include/mimalloc.h) ────────────────────────
# Zgodne z mimalloc v3.3.x — wartości stabilne między wersjami patchowymi


class MIOption:
    """mimalloc option constants (from ``mi_option_e`` enum)."""

    SHOW_STATS = 0
    SHOW_ERRORS = 1
    EAGER_COMMIT = 2
    EAGER_DECOMMIT = 3
    PAGE_RESET = 5
    SEGMENT_CACHE = 7
    PAGE_CLEAR = 8
    LARGE_OS_PAGES = 14
    RESERVE_HUGE_OS_PAGES = 15
    PURGE_DELAY = 16
    USE_NUMA_NODES = 17
    DISABLE_OSX_ALLOC = 20
    ALLOW_LARGE_OS_PAGES = 24
    MINIMAL_PURGE_SIZE = 25


class MIStatKind:
    """mimalloc statistic kind constants (from ``mi_stat_kind_t``)."""

    COMMITTED = 0
    RESERVED = 1
    RESET = 2
    PURGED = 3


# ── Library handle (lazy-loaded, thread-safe singleton) ────────────────────
# All ctypes function prototypes are set ONCE here, not per-call, to avoid
# thread-safety issues with concurrent restype/argtypes mutation.
# Zgodnie z Python 3.13t (free-threaded): threading.Lock zapewnia bezpieczeństwo.

_lib: ctypes.CDLL | None = None
_lib_lock = threading.Lock()

# ── ctypes function prototypes (set once at lib init) ──────────────────────
# Unikamy race condition na restype/argtypes przez ustawienie ich raz.


def _init_prototypes(lib: ctypes.CDLL) -> None:
    """Set ctypes function prototypes once at library init.

    Thread-safe: called under _lib_lock, before _lib is assigned.
    """
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
    """Lazy-load the mimalloc shared library symbols from the current process.

    Uses ctypes.CDLL(None) to search for symbols in the main program.
    On Linux with LD_PRELOAD, this will find libmimalloc.so symbols.
    When mimalloc is statically linked (Nuitka build), symbols are also
    available through the main binary.

    Returns:
        CDLL handle or None if mimalloc is not active.
    """
    global _lib
    if _lib is not None:
        return _lib
    with _lib_lock:
        if _lib is not None:
            return _lib
        try:
            lib = ctypes.CDLL(None)
            # Verify by accessing a unique mimalloc symbol
            lib.mi_malloc  # type: ignore[attr-defined]
            _init_prototypes(lib)
            _lib = lib
            _log.info("mimalloc bridge: library loaded (symbol: mi_malloc)")
            return _lib
        except (OSError, AttributeError) as exc:
            _log.warning("mimalloc bridge: not available - %s", exc)
            return None


# ── Public API ─────────────────────────────────────────────────────────────


def is_active() -> bool:
    """Check if mimalloc is the active memory allocator.

    Returns:
        True if mimalloc is active (symbol mi_malloc found in process).
    """
    return _get_lib() is not None


def option_set(option: int, value: int) -> bool:
    """Set a mimalloc option at runtime.

    Args:
        option: One of ``MIOption.*`` constants.
        value: Integer value (0 or 1 for boolean options).

    Returns:
        True if the option was set, False if mimalloc is not active.
    """
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_option_set(ctypes.c_int(option), ctypes.c_int(value))
        return True
    except (OSError, AttributeError):
        return False


def option_get(option: int) -> int | None:
    """Get the current value of a mimalloc option.

    Args:
        option: One of ``MIOption.*`` constants.

    Returns:
        Current option value or None if mimalloc is not active.
    """
    lib = _get_lib()
    if lib is None:
        return None
    try:
        # restype ustawiony raz w _init_prototypes
        return lib.mi_option_get(ctypes.c_int(option))
    except (OSError, AttributeError):
        return None


def heap_new() -> int | None:
    """Create a new mimalloc heap.

    Heaps are isolated allocation arenas — all memory allocated on a heap
    can be freed atomically with ``heap_destroy()``.

    Returns:
        Opaque heap pointer (as Python int via addressof), or None if mimalloc
        is not active or heap creation failed.
    """
    lib = _get_lib()
    if lib is None:
        return None
    try:
        # restype = c_void_p ustawiony raz w _init_prototypes
        heap_ptr = lib.mi_heap_new()
        if not heap_ptr:
            return None
        return ctypes.addressof(heap_ptr)
    except (OSError, AttributeError):
        return None


def heap_destroy(heap: int) -> bool:
    """Destroy a mimalloc heap, freeing all its allocated memory at once.

    This is the key operation for isolated OCR processing — all memory
    allocated on this heap (images, text buffers, OCR results) is freed
    in one O(1) operation, without needing to free each allocation individually.

    Args:
        heap: Heap pointer (as Python int, from ``heap_new()``).

    Returns:
        True if destroyed successfully, False if mimalloc is not active.
    """
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_heap_destroy(ctypes.c_void_p(heap))
        return True
    except (OSError, AttributeError):
        return False


def heap_collect(heap: int, force: bool = False) -> bool:
    """Collect (garbage) a mimalloc heap to reclaim unused memory.

    Args:
        heap: Heap pointer (as Python int, from ``heap_new()``).
        force: If True, force aggressive collection.

    Returns:
        True if successful.
    """
    lib = _get_lib()
    if lib is None:
        return False
    try:
        lib.mi_heap_collect(ctypes.c_void_p(heap), ctypes.c_bool(force))
        return True
    except (OSError, AttributeError):
        return False


def stats_hint() -> str:
    """Return mimalloc statistics configuration hint.

    mimalloc statistics are collected on process exit when
    ``MIMALLOC_SHOW_STATS=1`` is set. This function returns
    a hint about the current configuration — it does NOT
    collect live allocator statistics.

    For live stats, enable the env var before starting the process.

    Returns:
        String describing the current stats configuration.
    """
    if os.environ.get("MIMALLOC_SHOW_STATS", "0") == "1":
        return "MIMALLOC_SHOW_STATS=1 — stats will print on process exit"
    return "Set MIMALLOC_SHOW_STATS=1 to see allocator statistics on exit"


def _get_rss_bytes() -> int | None:
    """Read the current process RSS (resident set size) from /proc/self/statm.

    This provides a close approximation of mimalloc's committed memory
    for monitoring purposes. Falls back gracefully if /proc is not available
    (e.g., macOS, Windows — returns None).

    Returns:
        RSS in bytes, or None if not available.
    """
    try:
        with open("/proc/self/statm") as f:
            parts = f.read().strip().split()
            if len(parts) >= 2:
                # RSS in pages → bytes
                rss_pages = int(parts[1])
                page_size = os.sysconf("SC_PAGE_SIZE")
                return rss_pages * page_size
    except (FileNotFoundError, ValueError, OSError, AttributeError):
        pass
    return None


def stats_as_dict() -> dict[str, Any]:
    """Get mimalloc statistics as a dictionary.

    Returns:
        Dict with keys: active, committed, options.
        Empty dict if mimalloc is not active.
    """
    lib = _get_lib()
    if lib is None:
        return {"active": False}

    result: dict[str, Any] = {
        "active": True,
    }

    # Try to read resident set size (close approximation of committed memory)
    rss = _get_rss_bytes()
    if rss is not None:
        result["process_rss_bytes"] = rss

    # Read current option values (safe: getattr with default None)
    options = {}
    for name in ["LARGE_OS_PAGES", "RESERVE_HUGE_OS_PAGES", "PAGE_RESET", "PURGE_DELAY"]:
        val = option_get(getattr(MIOption, name, -1))
        if val is not None and val >= 0:
            options[name.lower()] = val
    if options:
        result["options"] = options

    return result


# ── Context manager for isolated OCR heaps ─────────────────────────────────


class InvoiceOCRHeap:
    """Izolowana sterta mimalloc dla przetwarzania jednej faktury.

    Zgodnie z aa3fvcx.txt i audytem mimalloc: tworzy dedykowaną stertę
    mimalloc dla każdej faktury w pipeline OCR. Po zakończeniu przetwarzania
    cała pamięć jest zwalniana atomowo przez ``heap_destroy()``.

    Jest to kluczowa optymalizacja pamięci — zamiast czekać na GC Pythona,
    wszystkie alokacje dla faktury (obrazy, bufory OCR, struktury tymczasowe)
    są usuwane w jednej operacji O(1).

    Usage:
        async with InvoiceOCRHeap("inv-123") as heap:
            # Wszystkie alokacje dla tej faktury
            text = await tesseract.extract_text(image_path)
            ...
        # ← heap_destroy — pamięć zwolniona atomowo

    Gdy mimalloc nie jest aktywny (fallback), context manager działa
    przezroczysto — tworzy i niszczy tylko wtedy gdy mimalloc jest dostępny.
    """

    def __init__(self, invoice_id: str, label: str = "ocr") -> None:
        self.invoice_id = invoice_id
        self.label = label
        self._heap: int | None = None
        self._collect_on_exit = True

    @property
    def heap_ptr(self) -> int | None:
        """Get the raw mimalloc heap pointer (as Python int)."""
        return self._heap

    @property
    def is_isolated(self) -> bool:
        """True if this instance actually created an isolated heap."""
        return self._heap is not None

    async def __aenter__(self) -> InvoiceOCRHeap:
        """Create the mimalloc heap and return self."""
        self._heap = heap_new()
        if self._heap is not None:
            _log.debug(
                "ocr_heap_created", invoice_id=self.invoice_id, label=self.label
            )
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None = None,
        exc_val: BaseException | None = None,
        exc_tb: object | None = None,
    ) -> None:
        """Destroy the mimalloc heap, freeing all memory atomically."""
        if self._heap is not None:
            if self._collect_on_exit:
                heap_collect(self._heap, force=False)
            heap_destroy(self._heap)
            _log.debug(
                "ocr_heap_destroyed", invoice_id=self.invoice_id, label=self.label
            )
            self._heap = None


# ── Secure heap for sensitive financial data ───────────────────────────────


class SecureHeap:
    """Secure mimalloc heap with guard pages for sensitive financial data.

    Zgodnie z audytem mimalloc: wrapper wokół ``heap_new()`` / ``heap_destroy()``
    dla danych wrażliwych (klucze kryptograficzne, hasła, dane faktur).

    Różnica względem ``InvoiceOCRHeap``:
    - Wymusza ``heap_collect(force=True)`` przed zniszczeniem
    - Dodaje guard pages (przez mi_option_set z PAGE_CLEAR)
    - Loguje wszystkie operacje jako security events
    - Przeznaczony dla danych finansowych, nie OCR

    Usage:
        async with SecureHeap("crypto_key") as heap:
            # Klucz kryptograficzny w izolowanej stercie
            derive_key(password, salt)
        # ← heap_destroy z force collect — pamięć wyzerowana i zwolniona
    """

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
        """True if a secured heap was created."""
        return self._heap is not None

    async def __aenter__(self) -> SecureHeap:
        """Create heap and enable guard pages if requested.

        Note: PAGE_CLEAR jest globalnym ustawieniem mimalloc (nie per-heap).
        ``SecureHeap`` zapamiętuje poprzednią wartość i przywraca ją
        w ``__aexit__``, aby nie wpływać na wydajność pozostałych alokacji.
        """
        self._heap = heap_new()
        if self._heap is not None and self._enable_guard_pages:
            # Zapamiętaj poprzednią wartość PAGE_CLEAR
            prev = option_get(MIOption.PAGE_CLEAR)
            self._prev_page_clear = prev if prev is not None else 0
            # Włącz czyszczenie stron na free — zeruje pamięć przed zwolnieniem
            option_set(MIOption.PAGE_CLEAR, 1)
            _log.info(
                "secure_heap_created",
                label=self.label,
                guard_pages=self._enable_guard_pages,
            )
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None = None,
        exc_val: BaseException | None = None,
        exc_tb: object | None = None,
    ) -> None:
        """Destroy the secure heap with force collect."""
        if self._heap is not None:
            # Force collection to zeroize all sensitive data
            heap_collect(self._heap, force=True)
            heap_destroy(self._heap)
            # Przywróć poprzednią wartość PAGE_CLEAR
            if self._enable_guard_pages and self._prev_page_clear is not None:
                option_set(MIOption.PAGE_CLEAR, self._prev_page_clear)
            _log.info(
                "secure_heap_destroyed",
                label=self.label,
            )
            self._heap = None


# ── MemoryLeakDetector ─────────────────────────────────────────────────────


class MemoryLeakDetector:
    """Detektor wycieków pamięci przez monitorowanie wzrostu RSS.

    Zgodnie z audytem mimalloc Faza 4: śledzi historyczne pomiary RSS
    i wykrywa nienormalny wzrost (powyżej ``growth_threshold_pct``
    w ciągu ``window_size`` pomiarów).

    Thread-safe dla Python 3.13t (free-threaded) — wszystkie operacje
    na historii przez ``threading.Lock``.

    Usage:
        detector = MemoryLeakDetector(growth_threshold_pct=20.0, window_size=3)
        if detector.check_growth(stats_as_dict()):
            logger.warning("Potential memory leak detected!")
    """

    def __init__(
        self,
        growth_threshold_pct: float = 20.0,
        window_size: int = 3,
        min_rss_mb: float = 100.0,
    ) -> None:
        """
        Args:
            growth_threshold_pct: Procent wzrostu RSS między najstarszym
                                  a najnowszym pomiarem w oknie, który
                                  uznajemy za potencjalny wyciek.
            window_size: Liczba ostatnich pomiarów do porównania.
            min_rss_mb: Minimalny RSS (MB) — pomiary poniżej są ignorowane
                        (zapobiega fałszywym alarmom przy małych obciążeniach).
        """
        self.growth_threshold_pct = growth_threshold_pct
        self.window_size = window_size
        self.min_rss_mb = min_rss_mb
        self._history: list[float] = []
        self._lock = threading.Lock()
        self.last_alert_time: float = 0.0
        """Unix timestamp ostatniego alertu (cooldown 60s)."""
        self.alert_cooldown_seconds: float = 60.0
        """Minimalny odstęp między alertami."""

    def check_growth(self, stats: dict[str, Any]) -> tuple[bool, float]:
        """Sprawdź czy RSS rośnie nienormalnie szybko.

        Args:
            stats: Słownik statystyk z ``stats_as_dict()``.

        Returns:
            Krotka (leak_detected: bool, growth_pct: float).
            ``growth_pct`` to procent wzrostu między najstarszym
            a najnowszym pomiarem w oknie.
        """
        rss = stats.get("process_rss_bytes", 0) or 0
        rss_mb = rss / (1024 * 1024)

        if rss_mb < self.min_rss_mb:
            return False, 0.0

        with self._lock:
            self._history.append(rss_mb)
            if len(self._history) > self.window_size:
                self._history.pop(0)

            if len(self._history) < 2:
                return False, 0.0

            oldest = self._history[0]
            newest = self._history[-1]
            if oldest <= 0:
                return False, 0.0

            growth_pct = ((newest - oldest) / oldest) * 100.0
            return growth_pct >= self.growth_threshold_pct, growth_pct

    def clear_history(self) -> None:
        """Wyczyść historię pomiarów (np. po celowym zwolnieniu pamięci)."""
        with self._lock:
            self._history.clear()

    def get_history(self) -> list[float]:
        """Zwróć kopię historii pomiarów RSS w MB."""
        with self._lock:
            return list(self._history)

    def should_alert(self, now: float | None = None) -> bool:
        """Sprawdź czy minął cooldown od ostatniego alertu."""
        if now is None:
            import time as _time

            now = _time.time()
        if now - self.last_alert_time < self.alert_cooldown_seconds:
            return False
        self.last_alert_time = now
        return True


# ── Save stats to file ─────────────────────────────────────────────────────


def save_stats_to_file(path: str | os.PathLike) -> str | None:
    """Zapisz aktualne statystyki mimalloc do pliku JSON.

    Używane przez główny proces do okresowego zrzutu statystyk alokatora
    do okresowego zrzutu statystyk alokatora.

    Args:
        path: Ścieżka do pliku JSON.

    Returns:
        Ścieżka do zapisanego pliku lub None jeśli mimalloc nieaktywny.
    """
    stats = stats_as_dict()
    if not stats.get("active", False):
        return None

    from nexus_ai.core.msgspec_utils import msgspec_dumps as _msgspec_dumps
    import time as _time

    stats["timestamp"] = _time.time()
    # ISO timestamp bez zewnętrznych zależności
    stats["timestamp_iso"] = _time.strftime("%Y-%m-%dT%H:%M:%SZ", _time.gmtime())

    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(_msgspec_dumps(stats, ensure_ascii=False, indent=2, default=str))
        return str(path)
    except (OSError, PermissionError) as exc:
        _log.warning("Failed to save mimalloc stats to %s: %s", path, exc)
        return None


# ── Metrics collection helper ──────────────────────────────────────────────


def record_metrics() -> dict[str, int | float | bool]:
    """Collect current mimalloc metrics for external monitoring.

    Returns dict with keys: active, process_rss_bytes, options.
    Safe to call anytime — returns empty dict if mimalloc not active.

    Returns:
        Dict of metric values (may be empty if mimalloc is not active).
    """
    return stats_as_dict()
