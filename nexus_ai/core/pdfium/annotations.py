"""
Adnotacje, załączniki, bookmarki — operacje na elementach PDF.
Wyodrębniony z pdfium.py (~250 LOC → ~140 LOC).
"""

from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any

import fsspec
from structlog import get_logger

from nexus_ai.core.pdfium.structs import PDFAnnotation, PDFAttachment, PDFBookmark

logger = get_logger("nexus.core.pdfium")

_ANNOTATION_TYPE_MAP = {
    0: "text", 1: "link", 2: "freetext", 3: "line", 4: "square", 5: "circle",
    6: "polygon", 7: "polyline", 8: "highlight", 9: "underline", 10: "squiggly",
    11: "strikeout", 12: "stamp", 13: "caret", 14: "ink", 15: "popup",
    16: "file_attachment", 17: "sound", 18: "movie", 19: "widget", 20: "screen",
    21: "printermark", 22: "trap_net", 23: "watermark", 24: "3d", 25: "rich_media",
    26: "web_media", 27: "unknown",
}


def _with_pdf(pdf_path: str | Path, fn):
    """Otwórz PDF, wykonaj fn(pdf), zamknij."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    try:
        return fn(pdf)
    finally:
        pdf.close()


# ── Adnotacje ───────────────────────────────────────────────────────────

def get_page_annotations(pdf_path: str | Path, page_num: int = 0) -> list[PDFAnnotation]:
    """Get page annotations."""
    def _get(pdf):
        page = pdf[page_num]
        count = page.count_annotations()
        if count == 0:
            return []
        results = []
        for i in range(count):
            try:
                annot = page.get_annotation(i)
                annot_type = annot.get_type()
                results.append(PDFAnnotation(
                    type=_ANNOTATION_TYPE_MAP.get(annot_type, f"unknown_{annot_type}"),
                    rect=annot.get_rect() if hasattr(annot, "get_rect") else (0.0, 0.0, 0.0, 0.0),
                    content=annot.get_content() if hasattr(annot, "get_content") else "",
                    flags=annot.get_flags() if hasattr(annot, "get_flags") else 0,
                    page_num=page_num,
                ))
            except Exception as exc:
                logger.debug("Error reading annotation %d: %s", i, exc)
                continue
        return results
    return _with_pdf(pdf_path, _get)


def count_page_annotations(pdf_path: str | Path, page_num: int = 0) -> int:
    """Policz adnotacje na stronie."""
    def _count(pdf):
        return pdf[page_num].count_annotations()
    return _with_pdf(pdf_path, _count)


# ── Załączniki ─────────────────────────────────────────────────────────

def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:
    """Get PDF embedded files/attachments."""
    def _get(pdf):
        count = pdf.count_attachments()
        if count == 0:
            return []
        results = []
        for i in range(count):
            try:
                name, data = pdf.get_attachment(i)
                results.append(PDFAttachment(name=name, data=data, size=len(data), index=i))
            except Exception as exc:
                logger.debug("Error reading attachment %d: %s", i, exc)
                continue
        return results
    return _with_pdf(pdf_path, _get)


def add_pdf_attachment(
    pdf_path: str | Path, name: str, data: bytes,
    *, output_path: str | Path | None = None,
) -> bytes:
    """Add an attachment to a PDF document."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        pdf_bytes = f.read()
    pdf = pdfium.PdfDocument(pdf_bytes)
    try:
        pdf.new_attachment(name, data)
        logger.info("Added attachment: %s (%d bytes)", name, len(data))
        if output_path:
            pdf.save(str(output_path))
            return Path(str(output_path)).read_bytes()
        buf = BytesIO()
        pdf.save_to_bytesio(buf)
        return buf.getvalue()
    finally:
        pdf.close()


# ── Zakładki ────────────────────────────────────────────────────────────

def _extract_bookmarks_recursive(bookmarks: list, level: int = 0) -> list[PDFBookmark]:
    results = []
    for bm in bookmarks:
        try:
            title = bm.title if hasattr(bm, "title") else str(bm.get("title", ""))
            page_index = bm.page_index if hasattr(bm, "page_index") else int(bm.get("page_index", 0))
            children = bm.children if hasattr(bm, "children") else bm.get("children", [])
            results.append(PDFBookmark(
                title=title, page_index=page_index, level=level,
                children=_extract_bookmarks_recursive(children, level + 1) if children else [],
            ))
        except Exception as exc:
            logger.debug("Error parsing bookmark: %s", exc)
            continue
    return results


def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:
    """Get PDF bookmarks/outline."""
    def _get(pdf):
        bms = pdf.get_bookmarks()
        if not bms:
            return []
        return _extract_bookmarks_recursive(bms, level=0)
    return _with_pdf(pdf_path, _get)


__all__ = [
    "get_page_annotations", "count_page_annotations",
    "get_pdf_attachments", "add_pdf_attachment",
    "get_pdf_bookmarks",
]
