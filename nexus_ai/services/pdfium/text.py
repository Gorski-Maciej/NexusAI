"""
Tekst — ekstrakcja tekstu, wyszukiwanie, detekcja tabel z PDF.
Wyodrębniony z pdfium.py (~250 LOC → ~150 LOC).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import fsspec
from structlog import get_logger

from nexus_ai.services.pdfium.structs import PDFSearchResult, PDFTextRange

logger = get_logger("nexus.core.pdfium")


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


def extract_text_from_page(pdf_path: str | Path, page_num: int = 0) -> str:
    """Ekstrahuj czysty tekst ze strony z layoutem."""
    import pypdfium2.raw as pdfium_raw
    try:
        layout_flag = pdfium_raw.FPDF_TEXTPAGE_TEXT_FLAGS.PDFTEXT_PRESERVE_LAYOUT
    except (ImportError, AttributeError):
        layout_flag = 2

    def _extract(pdf):
        page = pdf[page_num]
        text_page = page.get_textpage()
        return text_page.get_text(flags=layout_flag).strip() or ""

    return _with_pdf(pdf_path, _extract)


def extract_text_simple(pdf_path: str | Path, page_num: int = 0) -> str:
    """Szybka ekstrakcja tekstu bez layoutu."""
    def _extract(pdf):
        page = pdf[page_num]
        return page.get_textpage().get_text().strip()
    return _with_pdf(pdf_path, _extract)


def extract_text_ranges(pdf_path: str | Path, page_num: int = 0) -> list[dict[str, Any]]:
    """Ekstrahuj tekst z pozycjami (bounding boxy)."""
    def _extract(pdf):
        page = pdf[page_num]
        text_page = page.get_textpage()
        ranges = text_page.get_text_ranges()
        if not ranges:
            return []
        return [{
            "text": r.text, "left": float(r.left), "top": float(r.top),
            "right": float(r.right), "bottom": float(r.bottom),
            "font_size": float(getattr(r, "font_size", 0.0)),
        } for r in ranges if r.text and r.text.strip()]
    return _with_pdf(pdf_path, _extract)


def extract_text_ranges_typed(pdf_path: str | Path, page_num: int = 0) -> list[PDFTextRange]:
    """Ekstrahuj tekst jako listę PDFTextRange."""
    def _extract(pdf):
        page = pdf[page_num]
        text_page = page.get_textpage()
        ranges = text_page.get_text_ranges()
        if not ranges:
            return []
        return [PDFTextRange(
            text=r.text, left=float(r.left), top=float(r.top),
            right=float(r.right), bottom=float(r.bottom),
            font_size=float(getattr(r, "font_size", 0.0)),
        ) for r in ranges if r.text and r.text.strip()]
    return _with_pdf(pdf_path, _extract)


def search_in_pdf(
    pdf_path: str | Path, query: str, page_num: int = 0,
    *, match_case: bool = False, whole_words: bool = False,
) -> list[PDFSearchResult]:
    """Search for text in a PDF page."""
    flags = 0
    if match_case:
        flags |= 1
    if whole_words:
        flags |= 2
    def _search(pdf):
        page = pdf[page_num]
        text_page = page.get_textpage()
        results = []
        try:
            search = text_page.search(query, flags=flags)
            for match in search:
                results.append(PDFSearchResult(
                    text=match.text, left=float(match.left), top=float(match.top),
                    right=float(match.right), bottom=float(match.bottom),
                    char_index=getattr(match, "char_index", 0), count=1,
                ))
        except (AttributeError, Exception) as exc:
            logger.debug("Search API fallback: %s", exc)
            ranges = extract_text_ranges(pdf_path, page_num)
            query_lower = query.lower()
            for r in ranges:
                text = r.get("text", "")
                if (match_case and query in text) or (not match_case and query_lower in text.lower()):
                    results.append(PDFSearchResult(
                        text=text, left=r.get("left", 0), top=r.get("top", 0),
                        right=r.get("right", 0), bottom=r.get("bottom", 0),
                    ))
        return results
    return _with_pdf(pdf_path, _search)


def detect_table_regions(pdf_path: str | Path, page_num: int = 0) -> list[dict[str, Any]]:
    """Detekcja potencjalnych tabel przez analizę bounding boxów tekstu."""
    ranges = extract_text_ranges(pdf_path, page_num)
    if not ranges:
        return []

    rows: dict[int, list[dict]] = {}
    for r in ranges:
        y_center = round((r["top"] + r["bottom"]) / 2 / 5) * 5
        rows.setdefault(y_center, []).append(r)

    tables = []
    for y, items in sorted(rows.items()):
        if len(items) >= 3:
            sorted_items = sorted(items, key=lambda x: x["left"])
            tables.append({
                "row_y": y,
                "columns": [{"text": item["text"], "x": round(item["left"], 1)} for item in sorted_items],
                "column_count": len(sorted_items),
            })
    return tables


__all__ = [
    "extract_text_from_page", "extract_text_simple",
    "extract_text_ranges", "extract_text_ranges_typed",
    "search_in_pdf", "detect_table_regions",
]
