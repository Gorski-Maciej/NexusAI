"""fsspec_compat.py — SUPERMOC: Moduł kompatybilności fsspec dla NexusAI.

Automatycznie wykrywa dostępne moduły fsspec i dostarcza fallbacki
dla brakujących implementacji (np. TransactionalFileSystem).

SUPERMOCE:
- Auto-detection dostępnych modułów fsspec
- Uniwersalny TransactionWrapper jako fallback dla TransactionalFileSystem
- Jeden import zamiast rozrzuconych po całym projekcie
"""

from __future__ import annotations

import logging
from contextlib import contextmanager
from typing import Any

logger = logging.getLogger("nexus.fsspec_compat")

# ── Próba importu TransactionalFileSystem ────────────────────────────────
try:
    from fsspec.implementations.transactional import TransactionalFileSystem
    HAS_TX_FS = True
    logger.debug("[fsspec] TransactionalFileSystem available")
except ImportError:
    HAS_TX_FS = False

    class TransactionalFileSystem:  # type: ignore[no-redef]
        """SUPERMOC: Uniwersalny fallback dla TransactionalFileSystem.

        Gdy fsspec.implementations.transactional nie jest dostępny,
        ten wrapper zapewnia ten sam interfejs API:
        - transaction() → context manager
        - Wszystkie operacje delegowane do bazowego FS
        - Brak atomiczności (fallback), ale kompatybilny API
        """

        def __init__(self, fs: Any, **kwargs: Any):
            self.fs = fs
            self._kwargs = kwargs
            logger.debug("[fsspec] Using TransactionalFileSystem fallback (no atomicity)")

        def transaction(self):
            """SUPERMOC Context manager dla grupowych operacji.

            W wersji fallback — wykonuje operacje natychmiast (bez deferowania).
            Zachowuje ten sam interfejs API co prawdziwy TransactionalFileSystem.
            """
            return self._noop_transaction()

        @contextmanager
        def _noop_transaction(self):
            """No-op transaction — wykonuje wszystko natychmiast."""
            try:
                yield
            except Exception:
                raise

        def __getattr__(self, name: str) -> Any:
            """Deleguj wszystkie inne atrybuty do bazowego FS."""
            return getattr(self.fs, name)

        def open(self, *args: Any, **kwargs: Any):
            return self.fs.open(*args, **kwargs)

        def exists(self, path: str) -> bool:
            return self.fs.exists(path)

        def info(self, path: str) -> dict:
            return self.fs.info(path)

        def ls(self, path: str, detail: bool = True) -> list:
            return self.fs.ls(path, detail=detail)

        def find(self, path: str) -> list[str]:
            return self.fs.find(path)

        def makedirs(self, path: str, exist_ok: bool = True) -> None:
            return self.fs.makedirs(path, exist_ok=exist_ok)

        def rm(self, path: str, recursive: bool = True) -> None:
            return self.fs.rm(path, recursive=recursive)

    logger.info("[fsspec] Created TransactionalFileSystem fallback")


# ── Próba importu pozostałych modułów ────────────────────────────────────

# ZipFileSystem
try:
    from fsspec.implementations.zip import ZipFileSystem
    HAS_ZIP_FS = True
except ImportError:
    HAS_ZIP_FS = False
    ZipFileSystem = None  # type: ignore[assignment]

# CachingFileSystem
try:
    from fsspec.implementations.cached import CachingFileSystem
    HAS_CACHE_FS = True
except ImportError:
    HAS_CACHE_FS = False
    CachingFileSystem = None  # type: ignore[assignment]

# MemoryFileSystem
try:
    from fsspec.implementations.memory import MemoryFileSystem
    HAS_MEMORY_FS = True
except ImportError:
    HAS_MEMORY_FS = False
    MemoryFileSystem = None  # type: ignore[assignment]

# TqdmCallback
try:
    from fsspec.callbacks import TqdmCallback
    HAS_TQDM_CB = True
except ImportError:
    HAS_TQDM_CB = False
    TqdmCallback = None  # type: ignore[assignment]


__all__ = [
    "TransactionalFileSystem",
    "ZipFileSystem",
    "CachingFileSystem",
    "MemoryFileSystem",
    "TqdmCallback",
    "HAS_TX_FS",
    "HAS_ZIP_FS",
    "HAS_CACHE_FS",
    "HAS_MEMORY_FS",
    "HAS_TQDM_CB",
]
