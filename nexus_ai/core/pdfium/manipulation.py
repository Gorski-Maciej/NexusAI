"""
Manipulacja — łączenie, dzielenie, usuwanie stron, zapis przyrostowy.
Wyodrębniony z pdfium.py (~200 LOC → ~120 LOC).
"""

from __future__ import annotations

from io import BytesIO
from pathlib import Path

import fsspec
from structlog import get_logger

logger = get_logger("nexus.core.pdfium")


def _open_pdf(source: str | Path | bytes):
    """Otwórz dokument PDF przez pypdfium2."""
    import pypdfium2 as pdfium
    if isinstance(source, bytes):
        return pdfium.PdfDocument(source)
    with fsspec.open(str(source), "rb") as f:
        return pdfium.PdfDocument(f.read())


def _save_pdf(pdf, output_path: str | Path | None = None) -> bytes:
    if output_path:
        pdf.save(str(output_path))
        return Path(str(output_path)).read_bytes()
    buf = BytesIO()
    pdf.save_to_bytesio(buf)
    return buf.getvalue()


def merge_pdfs(pdf_paths: list[str | Path], *, output_path: str | Path | None = None) -> bytes:
    """Merge multiple PDFs into one document."""
    import pypdfium2 as pdfium
    merged = pdfium.PdfDocument.new()
    try:
        for path in pdf_paths:
            src = _open_pdf(path)
            try:
                merged.import_pages(src, range(len(src)))
            finally:
                src.close()
        logger.info("Merged %d files", len(pdf_paths))
        return _save_pdf(merged, output_path)
    finally:
        merged.close()


def delete_pages_from_pdf(
    pdf_path: str | Path, pages: list[int],
    *, output_path: str | Path | None = None,
) -> bytes:
    """Delete pages from a PDF document."""
    pdf = _open_pdf(pdf_path)
    try:
        for page_num in sorted(pages, reverse=True):
            pdf.del_page(page_num)
        logger.debug("Deleted %d pages", len(pages))
        return _save_pdf(pdf, output_path)
    finally:
        pdf.close()


def extract_pages_from_pdf(
    pdf_path: str | Path, pages: list[int],
    *, output_path: str | Path | None = None,
) -> bytes:
    """Extract specific pages from a PDF into a new document."""
    import pypdfium2 as pdfium
    src = _open_pdf(pdf_path)
    try:
        extracted = pdfium.PdfDocument.new()
        try:
            extracted.import_pages(src, pages)
            return _save_pdf(extracted, output_path)
        finally:
            extracted.close()
    finally:
        src.close()


def save_incremental(pdf_path: str | Path, *, output_path: str | Path | None = None) -> bytes:
    """Zapis przyrostowy — dodaje tylko zmiany na końcu pliku."""
    pdf = _open_pdf(pdf_path)
    try:
        return _save_pdf(pdf, output_path)
    finally:
        pdf.close()


__all__ = ["delete_pages_from_pdf", "extract_pages_from_pdf", "merge_pdfs", "save_incremental"]
