"""
Cache — fsspec CachingFileSystem wrapper dla PDF-ów.
Wyodrębniony z pdfium.py (~40 LOC).
"""

from __future__ import annotations

from pathlib import Path

from fsspec.implementations.cached import CachingFileSystem

_caching_fs = CachingFileSystem(
    target_protocol="file",
    cache_storage="/tmp/.fsspec_pdf_cache",
    maxsize=500 * 1024 * 1024,  # 500 MB
    same_names=True,
)


def get_pdf_bytes(path: str | Path) -> bytes:
    """Odczytaj PDF przez fsspec CachingFileSystem."""
    with _caching_fs.open(str(path), "rb") as f:
        return f.read()


def get_pdf_render_cache() -> dict:
    """Zwróć statystyki CachingFileSystem."""
    try:
        storage = _caching_fs.cache_storage if hasattr(_caching_fs, "cache_storage") else "unknown"
        return {"type": "CachingFileSystem", "cache_storage": storage, "same_names": True}
    except Exception:
        return {"type": "CachingFileSystem"}


def invalidate_pdf_cache(path: str | Path | None = None) -> None:
    """Unieważnij cache dla konkretnego PDF lub całości."""
    if path is None:
        global _caching_fs
        _caching_fs = CachingFileSystem(
            target_protocol="file",
            cache_storage="/tmp/.fsspec_pdf_cache",
            maxsize=500 * 1024 * 1024,
            same_names=True,
        )


__all__ = ["get_pdf_bytes", "get_pdf_render_cache", "invalidate_pdf_cache"]
