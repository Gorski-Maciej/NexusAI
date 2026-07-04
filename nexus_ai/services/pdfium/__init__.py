"""
PDFium — kompletny zestaw narzędzi do renderowania, ekstrakcji i manipulacji PDF
=================================================================================

Podzielony na moduły funkcjonalne (zamiast jednego 2016-liniowego pliku):

    pdfium/render.py       — Renderowanie stron → PIL/bytes/JPEG/PNG
    pdfium/text.py         — Ekstrakcja tekstu, wyszukiwanie, tabele
    pdfium/forms.py        — AcroForm: odczyt, wypełnianie, zapis
    pdfium/metadata.py     — Metadane, podpisy cyfrowe, PDF/A
    pdfium/annotations.py  — Adnotacje, załączniki, bookmarki
    pdfium/structs.py      — msgspec.Struct (DTO) dla wszystkich typów PDF
    pdfium/cache.py        — fsspec CachingFileSystem wrapper
    pdfium/session.py      — PdfDocumentSession context manager
    pdfium/manipulation.py — Merge, split, delete pages
    pdfium/progressive.py  — ProgressivePDFLoader

Wszystkie symbole są re-eksportowane dla kompatybilności wstecznej.
"""

from __future__ import annotations

from nexus_ai.services.pdfium.cache import get_pdf_bytes, get_pdf_render_cache, invalidate_pdf_cache
from nexus_ai.services.pdfium.render import (
    DEFAULT_DPI,
    DEFAULT_SCALE,
    PDFIUM_BASE_DPI,
    RenderFlags,
    open_pdf,
    pdf_page_count,
    render_all_pages,
    render_all_pages_to_memory,
    render_page,
    render_page_enhanced,
    render_page_to_jpeg_bytes,
    render_page_to_pil,
    render_page_to_pil_enhanced,
    render_page_to_png_bytes,
    render_page_to_png_grayscale,
    pdf_to_images_memory,
    pdf_to_pil_images,
)
from nexus_ai.services.pdfium.text import (
    detect_table_regions,
    extract_text_from_page,
    extract_text_ranges,
    extract_text_ranges_typed,
    extract_text_simple,
    search_in_pdf,
)
from nexus_ai.services.pdfium.forms import (
    fill_pdf_form_field,
    get_pdf_form_fields,
    save_pdf_with_filled_fields,
)
from nexus_ai.services.pdfium.metadata import (
    get_pdf_info,
    get_pdf_metadata,
    pdfa_check,
    verify_pdf_signatures,
)
from nexus_ai.services.pdfium.annotations import (
    add_pdf_attachment,
    count_page_annotations,
    get_page_annotations,
    get_pdf_attachments,
    get_pdf_bookmarks,
)
from nexus_ai.services.pdfium.session import PdfDocumentSession
from nexus_ai.services.pdfium.manipulation import (
    delete_pages_from_pdf,
    extract_pages_from_pdf,
    merge_pdfs,
    save_incremental,
)
from nexus_ai.services.pdfium.progressive import ProgressivePDFLoader
from nexus_ai.services.pdfium.verification import verify_pdfium_available, verify_pdfium_version
from nexus_ai.services.pdfium.structs import (
    PDFACompliance,
    PDFAnnotation,
    PDFAttachment,
    PDFBookmark,
    PDFFormField,
    PDFFormFillBatch,
    PDFFormFillData,
    PDFPageInfo,
    PDFProgressInfo,
    PDFRenderCacheEntry,
    PDFSearchResult,
    PDFSignature,
    PDFTextRange,
)

__all__ = [
    "PDFIUM_BASE_DPI", "DEFAULT_DPI", "DEFAULT_SCALE", "RenderFlags",
    "PDFTextRange", "PDFPageInfo", "PDFSignature", "PDFFormField",
    "PDFRenderCacheEntry", "PDFProgressInfo", "PDFAnnotation", "PDFAttachment",
    "PDFBookmark", "PDFSearchResult", "PDFACompliance", "PDFFormFillData", "PDFFormFillBatch",
    "get_pdf_bytes", "get_pdf_render_cache", "invalidate_pdf_cache",
    "PdfDocumentSession",
    "open_pdf", "render_page_to_pil", "render_page_to_pil_enhanced",
    "render_page", "render_page_enhanced", "render_page_to_jpeg_bytes",
    "render_page_to_png_bytes", "render_page_to_png_grayscale",
    "render_all_pages", "pdf_page_count",
    "pdf_to_images_memory", "pdf_to_pil_images",
    "render_all_pages_to_memory",
    "ProgressivePDFLoader",
    "extract_text_from_page", "extract_text_simple",
    "extract_text_ranges", "extract_text_ranges_typed",
    "search_in_pdf", "detect_table_regions",
    "get_pdf_metadata", "get_pdf_info",
    "verify_pdf_signatures",
    "get_pdf_form_fields", "fill_pdf_form_field", "save_pdf_with_filled_fields",
    "get_page_annotations", "count_page_annotations",
    "get_pdf_attachments", "add_pdf_attachment",
    "get_pdf_bookmarks",
    "save_incremental",
    "merge_pdfs", "delete_pages_from_pdf", "extract_pages_from_pdf",
    "pdfa_check",
    "verify_pdfium_available", "verify_pdfium_version",
]
