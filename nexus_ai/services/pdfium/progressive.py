"""
ProgressivePDFLoader — progresywny ładowacz PDF z możliwością anulowania.
Wyodrębniony z pdfium.py (~200 LOC → ~120 LOC).
"""

from __future__ import annotations

from collections.abc import Callable, Iterator
from io import BytesIO
from pathlib import Path
from typing import Any

import fsspec
from structlog import get_logger

from nexus_ai.services.pdfium.structs import PDFProgressInfo

logger = get_logger("nexus.core.pdfium")

DEFAULT_CHUNK_SIZE = 1024 * 1024  # 1 MB
PDFIUM_BASE_DPI = 72.0


class ProgressivePDFLoader:
    """Progresywny ładowacz PDF — renderuj strony bez pełnego parsowania.

    Usage:
        with ProgressivePDFLoader("invoice.pdf") as loader:
            first_page = loader.render_first_page(dpi=150)
            for page_bytes in loader.render_all(dpi=150):
                process(page_bytes)
    """
    __slots__ = ("_cancelled", "_chunk_size", "_data", "_lazy", "_path", "_pdf", "_progress_callback")

    def __init__(
        self, path: str | Path | None = None, *,
        lazy: bool = True, chunk_size: int = DEFAULT_CHUNK_SIZE,
        progress_callback: Callable[[PDFProgressInfo], None] | None = None,
    ):
        self._path = str(path) if path else None
        self._data: bytes | None = None
        self._pdf = None
        self._lazy = lazy
        self._chunk_size = chunk_size
        self._progress_callback = progress_callback
        self._cancelled = False
        if not lazy and path is not None:
            self._ensure_loaded()

    @classmethod
    def from_bytes(cls, data: bytes, *, lazy: bool = True, chunk_size: int = DEFAULT_CHUNK_SIZE) -> ProgressivePDFLoader:
        loader = cls(lazy=lazy, chunk_size=chunk_size)
        loader._data = data
        if not lazy:
            loader._ensure_loaded()
        return loader

    def _ensure_loaded(self):
        if self._pdf is not None:
            return
        import pypdfium2 as pdfium
        if self._data is not None:
            self._pdf = pdfium.PdfDocument(self._data)
        elif self._path is not None:
            with fsspec.open(self._path, "rb") as f:
                self._pdf = pdfium.PdfDocument(f.read())
        else:
            raise ValueError("No path or data provided")

    @property
    def pdf(self):
        self._ensure_loaded()
        return self._pdf

    @property
    def page_count(self) -> int:
        self._ensure_loaded()
        return len(self._pdf)

    def cancel(self):
        self._cancelled = True
        logger.debug("Progressive loader cancelled")

    @property
    def is_cancelled(self) -> bool:
        return self._cancelled

    def _render_page(self, page_num: int, dpi: int, fmt: str = "JPEG", quality: int = 85) -> bytes:
        self._ensure_loaded()
        page = self._pdf[page_num]
        scale = dpi / PDFIUM_BASE_DPI
        bitmap = page.render(scale=scale, rotation=0)
        pil_image = bitmap.to_pil()
        buf = BytesIO()
        pil_image.save(buf, format=fmt, quality=quality)
        return buf.getvalue()

    def render_first_page(self, dpi: int = 150) -> bytes:
        return self._render_page(0, dpi)

    def render_page(self, page_num: int, dpi: int = 150) -> bytes:
        return self._render_page(page_num, dpi)

    def render_all(
        self, dpi: int = 150, fmt: str = "JPEG", quality: int = 85,
        progress_callback: Callable[[PDFProgressInfo], None] | None = None,
    ) -> Iterator[bytes]:
        self._ensure_loaded()
        total = self.page_count
        cb = progress_callback or self._progress_callback
        for i in range(total):
            if self._cancelled:
                break
            yield self._render_page(i, dpi, fmt, quality)
            if cb is not None:
                cb(PDFProgressInfo(current_page=i + 1, total_pages=total, percent=round((i + 1) / total * 100, 1), page_dpi=dpi))

    def get_page_size(self, page_num: int = 0) -> tuple[float, float]:
        self._ensure_loaded()
        return self._pdf[page_num].get_size()

    def close(self):
        if self._pdf is not None:
            self._pdf.close()
            self._pdf = None

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


__all__ = ["ProgressivePDFLoader", "DEFAULT_CHUNK_SIZE"]
