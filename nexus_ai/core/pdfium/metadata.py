"""
Metadane — metadane PDF, podpisy cyfrowe, zgodność PDF/A.
Wyodrębniony z pdfium.py (~200 LOC → ~120 LOC).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import fsspec
from structlog import get_logger

from nexus_ai.core.pdfium.cache import _caching_fs
from nexus_ai.core.pdfium.structs import PDFACompliance, PDFSignature

logger = get_logger("nexus.core.pdfium")


def _with_pdf(pdf_path: str | Path, fn, *, close: bool = True):
    """Otwórz PDF, wykonaj fn(pdf), opcjonalnie zamknij."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    try:
        return fn(pdf)
    finally:
        if close:
            pdf.close()


def get_pdf_metadata(pdf_path: str | Path) -> dict[str, str]:
    """Pobierz metadane PDF."""
    def _meta(pdf):
        meta = pdf.get_metadata()
        return {k: str(v) for k, v in meta.items() if v}
    return _with_pdf(pdf_path, _meta)


def _get_signatures_internal(pdf) -> list[dict[str, Any]]:
    try:
        sigs = pdf.get_signatures()
        if not sigs:
            return []
        return [{
            "author": s.get("author", ""), "reason": s.get("reason", ""),
            "location": s.get("location", ""), "is_verified": s.get("is_verified", False),
            "signed_at": s.get("signed_at", ""), "field_name": s.get("field_name", ""),
            "page_num": s.get("page_num", 0),
        } for s in sigs]
    except Exception as exc:
        logger.debug("Signatures not available: %s", exc)
        return []


def verify_pdf_signatures(pdf_path: str | Path) -> list[PDFSignature]:
    """Verify PDF digital signatures."""
    def _verify(pdf):
        raw = _get_signatures_internal(pdf)
        return [PDFSignature(**s) for s in raw]
    return _with_pdf(pdf_path, _verify)


def _get_bookmarks_internal(pdf) -> list[dict[str, Any]]:
    try:
        bms = pdf.get_bookmarks()
        if not bms:
            return []

        def _bm_to_dict(bm):
            result = {"title": getattr(bm, "title", str(getattr(getattr(bm, "get", lambda k: ""), "__call__", lambda k: "")("title"))),
                       "page_index": getattr(bm, "page_index", 0), "children": []}
            children = getattr(bm, "children", [])
            if children:
                result["children"] = [_bm_to_dict(c) for c in children]
            return result
        return [_bm_to_dict(bm) for bm in bms]
    except (AttributeError, Exception):
        return []


def _get_attachment_count_internal(pdf) -> int:
    try:
        return pdf.count_attachments()
    except (AttributeError, Exception):
        return 0


def _get_pdfa_compliance_internal(pdf) -> PDFACompliance:
    try:
        version = pdf.get_pdfa_pdf_version() if hasattr(pdf, "get_pdfa_pdf_version") else 0
        version_str = {0: "none", 1: "PDF/A-1", 2: "PDF/A-2", 3: "PDF/A-3"}.get(version, f"unknown_{version}")
        return PDFACompliance(is_pdfa=version > 0, pdfa_version=version, pdfa_version_str=version_str)
    except (AttributeError, Exception):
        return PDFACompliance(is_pdfa=False, pdfa_version=0, pdfa_version_str="unavailable")


def pdfa_check(pdf_path: str | Path) -> PDFACompliance:
    """Check PDF/A compliance."""
    return _with_pdf(pdf_path, _get_pdfa_compliance_internal)


def get_pdf_info(pdf_path: str | Path) -> dict[str, Any]:
    """Kompletna informacja o PDF — jednowywołaniowe API."""
    def _info(pdf):
        metadata = pdf.get_metadata()
        page_count = len(pdf)
        first_page_size = pdf[0].get_size() if page_count > 0 else None
        try:
            info = _caching_fs.info(str(pdf_path))
            file_size = info.get("size", 0) if info else Path(str(pdf_path)).stat().st_size
        except Exception:
            file_size = Path(str(pdf_path)).stat().st_size

        signatures = _get_signatures_internal(pdf)
        bookmarks = _get_bookmarks_internal(pdf)
        attachment_count = _get_attachment_count_internal(pdf)
        pdfa = _get_pdfa_compliance_internal(pdf)
        return {
            "path": str(pdf_path), "page_count": page_count,
            "file_size_bytes": file_size, "file_size_mb": round(file_size / (1024 * 1024), 2),
            "metadata": {k: str(v) for k, v in metadata.items() if v},
            "first_page_size": {"width": round(first_page_size[0], 1), "height": round(first_page_size[1], 1)} if first_page_size else None,
            "signatures": signatures or None, "has_signatures": bool(signatures),
            "bookmarks": bookmarks or None, "has_bookmarks": bool(bookmarks),
            "attachment_count": attachment_count, "has_attachments": attachment_count > 0,
            "pdfa_compliance": {"is_pdfa": pdfa.is_pdfa, "version": pdfa.pdfa_version, "version_str": pdfa.pdfa_version_str},
        }
    return _with_pdf(pdf_path, _info)


__all__ = ["get_pdf_metadata", "get_pdf_info", "verify_pdf_signatures", "pdfa_check"]
