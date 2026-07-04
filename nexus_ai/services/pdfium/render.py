"""
Renderowanie — konwersja stron PDF do obrazów (PIL, bytes, JPEG, PNG).
Wyodrębniony z pdfium.py (~400 LOC → ~250 LOC przez konsolidację aliasów).
"""

from __future__ import annotations

from collections.abc import Callable
from enum import IntEnum
from io import BytesIO
from pathlib import Path
from typing import Any

import fsspec
from PIL import Image
from structlog import get_logger

from nexus_ai.services.pdfium.cache import _caching_fs
from nexus_ai.services.pdfium.structs import PDFProgressInfo

logger = get_logger("nexus.core.pdfium")

PDFIUM_BASE_DPI = 72.0
DEFAULT_DPI = 300
DEFAULT_SCALE = DEFAULT_DPI / PDFIUM_BASE_DPI  # ≈ 4.1667


class RenderFlags(IntEnum):
    """Flagi renderowania PDFium."""
    NONE = 0
    LCD_TEXT = 1 << 0
    NO_SMOOTHTEXT = 1 << 1
    NO_SMOOTHIMAGE = 1 << 2
    NO_SMOOTHPATH = 1 << 3
    GRAYSCALE = 1 << 4
    FORCE_HALFTONE = 1 << 5
    RENDER_TO_BITMAP = 1 << 6
    ANNOTATIONS = 1 << 7


# ── Helfer: otwieranie PDF przez fsspec ──────────────────────────────────

def _open_pdf(source: str | Path | bytes) -> Any:
    """Otwórz dokument PDF przez pypdfium2."""
    import pypdfium2 as pdfium
    if isinstance(source, bytes):
        return pdfium.PdfDocument(source)
    with fsspec.open(str(source), "rb") as f:
        return pdfium.PdfDocument(f.read())


def _open_pdf_and_render(
    source: str | Path | bytes,
    scale: float,
    page_num: int = 0,
    rotation: int = 0,
    flags: int = RenderFlags.LCD_TEXT,
) -> Image.Image:
    """Otwórz PDF, renderuj stronę, zwróć PIL Image."""
    import pypdfium2 as pdfium
    if isinstance(source, bytes):
        pdf = pdfium.PdfDocument(source)
    else:
        with fsspec.open(str(source), "rb") as f:
            pdf = pdfium.PdfDocument(f.read())
    try:
        page = pdf[page_num]
        bitmap = page.render(scale=scale, rotation=rotation, flags=flags)
        return bitmap.to_pil()
    finally:
        pdf.close()


# ── Core rendering API ──────────────────────────────────────────────────

def open_pdf(source: str | Path | bytes) -> Any:
    """Otwórz dokument PDF przez pypdfium2 (z fsspec)."""
    return _open_pdf(source)


def pdf_page_count(pdf_path: str | Path) -> int:
    """Zwróć liczbę stron w dokumencie PDF."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    count = len(pdf)
    pdf.close()
    return count


def render_page_to_pil(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    flags: int = RenderFlags.LCD_TEXT,
) -> Image.Image:
    """Renderuj stronę PDF do PIL Image."""
    return _open_pdf_and_render(pdf_path, dpi / PDFIUM_BASE_DPI, page_num, rotation, flags)


def render_page_to_pil_enhanced(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    preprocess_for_ocr: bool = False,
) -> Image.Image:
    """Renderuj stronę z opcjonalnym preprocessingiem Pillow."""
    pil = render_page_to_pil(pdf_path, page_num, dpi, rotation)
    if preprocess_for_ocr:
        from nexus_ai.core.image_utils import preprocess_for_ocr as _preprocess
        return _preprocess(pil) or pil
    return pil


# Alias dla kompatybilności
render_page = render_page_to_pil
render_page_enhanced = render_page_to_pil_enhanced


def render_page_to_jpeg_bytes(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    quality: int = 85,
) -> bytes:
    """Renderuj stronę PDF do JPEG bytes."""
    pil = render_page_to_pil(pdf_path, page_num, dpi, rotation)
    buf = BytesIO()
    pil.save(buf, format="JPEG", quality=quality, optimize=True, progressive=True)
    return buf.getvalue()


def render_page_to_png_bytes(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    optimize: bool = True,
    flags: int = RenderFlags.LCD_TEXT,
) -> bytes:
    """Renderuj stronę PDF do PNG bytes."""
    pil = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=flags)
    buf = BytesIO()
    pil.save(buf, format="PNG", optimize=optimize)
    return buf.getvalue()


def render_page_to_png_grayscale(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
) -> bytes:
    """Renderuj stronę do grayscale PNG bytes."""
    pil = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=RenderFlags.GRAYSCALE)
    buf = BytesIO()
    pil.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def render_all_pages(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    max_pages: int | None = None,
    page_range: tuple[int, int] | None = None,
    flags: int = RenderFlags.LCD_TEXT,
    progress_callback: Callable[[PDFProgressInfo], None] | None = None,
) -> list[Image.Image]:
    """Renderuj wszystkie strony PDF (lub zakres) z callbackiem postępu."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)

    start = 0 if page_range is None else page_range[0]
    end = total if page_range is None else min(page_range[1], total)
    if max_pages is not None:
        end = min(start + max_pages, end)

    results: list[Image.Image] = []
    try:
        for i in range(start, end):
            page = pdf[i]
            bitmap = page.render(scale=scale, rotation=rotation, flags=flags)
            if progress_callback is not None:
                progress_callback(PDFProgressInfo(
                    current_page=i - start + 1,
                    total_pages=end - start,
                    percent=round((i - start + 1) / (end - start) * 100, 1),
                    page_dpi=dpi,
                ))
            results.append(bitmap.to_pil())
    finally:
        pdf.close()
    return results


def render_all_pages_to_memory(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    max_pages: int | None = None,
    page_range: tuple[int, int] | None = None,
    format: str = "PNG",
    quality: int = 85,
    progress_callback: Callable[[PDFProgressInfo], None] | None = None,
) -> list[bytes]:
    """Renderuj wszystkie strony do pamięci jako bytes."""
    import pypdfium2 as pdfium
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)

    start = 0 if page_range is None else page_range[0]
    end = total if page_range is None else min(page_range[1], total)
    if max_pages is not None:
        end = min(start + max_pages, end)

    results: list[bytes] = []
    try:
        for i in range(start, end):
            page = pdf[i]
            bitmap = page.render(scale=scale, rotation=rotation)
            pil_image = bitmap.to_pil()
            buf = BytesIO()
            pil_image.save(buf, format=format, optimize=(format == "PNG"), quality=quality)
            results.append(buf.getvalue())
            if progress_callback is not None:
                progress_callback(PDFProgressInfo(
                    current_page=i - start + 1,
                    total_pages=end - start,
                    percent=round((i - start + 1) / (end - start) * 100, 1),
                    page_dpi=dpi,
                ))
    finally:
        pdf.close()
    return results


# ── Async-friendly variants (zero I/O na dysk) ──────────────────────────

def pdf_to_images_memory(pdf_path: str | Path, dpi: int = DEFAULT_DPI) -> list[bytes]:
    """Konwertuj strony PDF na PNG bytes w pamięci."""
    return render_all_pages_to_memory(pdf_path, dpi=dpi, fmt="PNG")


def pdf_to_pil_images(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    *,
    max_pages: int | None = None,
) -> list[Image.Image]:
    """Renderuj strony PDF do PIL Images."""
    return render_all_pages(pdf_path, dpi=dpi, max_pages=max_pages)


__all__ = [
    "PDFIUM_BASE_DPI", "DEFAULT_DPI", "DEFAULT_SCALE", "RenderFlags",
    "open_pdf", "pdf_page_count",
    "render_page_to_pil", "render_page_to_pil_enhanced",
    "render_page", "render_page_enhanced",
    "render_page_to_jpeg_bytes", "render_page_to_png_bytes",
    "render_page_to_png_grayscale",
    "render_all_pages", "render_all_pages_to_memory",
    "pdf_to_images_memory", "pdf_to_pil_images",
]
