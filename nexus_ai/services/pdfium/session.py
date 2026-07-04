"""
Session — PdfDocumentSession context manager dla wielu operacji na jednym PDF.
Wyodrębniony z pdfium.py (~60 LOC).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.pdfium")


class PdfDocumentSession:
    """Session for multiple PDF operations on a single open document.

    Usage:
        with PdfDocumentSession("invoice.pdf") as pdf:
            page_count = len(pdf)
            metadata = pdf.get_metadata()
            sigs = pdf.get_signatures()
    """
    __slots__ = ("_forms_initialized", "_pdf")

    def __init__(self, source: str | Path | bytes, *, init_forms: bool = True):
        import pypdfium2 as pdfium
        if isinstance(source, bytes):
            self._pdf = pdfium.PdfDocument(source)
        else:
            import fsspec
            with fsspec.open(str(source), "rb") as f:
                self._pdf = pdfium.PdfDocument(f.read())
        self._forms_initialized = False
        if init_forms:
            self._init_forms()

    def _init_forms(self):
        try:
            self._pdf.init_forms()
            self._forms_initialized = True
        except (RuntimeError, Exception):
            self._forms_initialized = False

    @property
    def pdf(self):
        return self._pdf

    @property
    def forms_initialized(self) -> bool:
        return self._forms_initialized

    def close(self):
        if self._pdf is not None:
            self._pdf.close()
            self._pdf = None

    def __enter__(self):
        return self._pdf

    def __exit__(self, *args):
        self.close()


__all__ = ["PdfDocumentSession"]
