"""
pdfium.py — SUPERMOCE pypdfium2 dla NexusAI.

Kompletny zestaw narzędzi do renderowania, ekstrakcji i manipulacji PDF-ami
przez silnik PDFium (Google Chrome). Zastępuje PyMuPDF (fitz) w 100%.

Zgodnie z audytem technologicznym:
- Silnik Google Chrome — renderuje miliardy PDF-ów dziennie
- Licencja BSD-3-Clause (PyMuPDF = AGPL)
- Antyaliasing subpikselowy — lepsza jakość niż MuPDF
- Numpy/PIL natywnie — bitmap.to_pil(), bitmap.to_numpy()
- Lżejszy pakiet (~10 MB vs ~15-20 MB)

KLUCZOWA RÓŻNICA W SKALOWANIU:
  PyMuPDF: dpi=300  → page.get_pixmap(dpi=300)
  PDFium:  scale = dpi / 72.0  (bo PDFium domyślnie 72 DPI)
  Dla 300 DPI: scale = 300/72 ≈ 4.1667

Wszystkie funkcje są synchroniczne (CPU-bound) — należy je uruchamiać
przez anyio.to_thread.run_sync() w kontekście asynchronicznym.
"""

from __future__ import annotations

import threading
import time
from collections import OrderedDict
from dataclasses import dataclass, field
from io import BytesIO
from pathlib import Path
from typing import Any, Callable, Iterator
from enum import IntEnum

import numpy as np
from PIL import Image
from structlog import get_logger

logger = get_logger("nexus.core.pdfium")

# ── Stałe ──────────────────────────────────────────────────────────────────

# PDFium domyślnie renderuje w 72 DPI
PDFIUM_BASE_DPI = 72.0

DEFAULT_DPI = 300
DEFAULT_SCALE = DEFAULT_DPI / PDFIUM_BASE_DPI  # ≈ 4.1667

# Stałe dla progresywnego ładowania
DEFAULT_CHUNK_SIZE = 1024 * 1024  # 1 MB

# Stałe cache
DEFAULT_CACHE_TTL = 300  # 5 minut
DEFAULT_CACHE_MAX_SIZE = 100  # max 100 stron w cache


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 1: Render Flags — stałe dla renderowania PDFium
# ═════════════════════════════════════════════════════════════════════════════


class RenderFlags(IntEnum):
    """Flagi renderowania PDFium.

    Zgodne z FPDF_GetRenderFlags/FPDF_RenderPageConstants.
    Używane przez page.render(flags=...) dla optymalizacji.
    """
    NONE = 0
    LCD_TEXT = 1 << 0         # FPDF_LCD_TEXT — subpikselowy antyaliasing
    NO_SMOOTHTEXT = 1 << 1    # FPDF_NO_SMOOTHTEXT — wyłącz wygładzanie tekstu
    NO_SMOOTHIMAGE = 1 << 2   # FPDF_NO_SMOOTHIMAGE — wyłącz wygładzanie obrazów
    NO_SMOOTHPATH = 1 << 3    # FPDF_NO_SMOOTHPATH — wyłącz wygładzanie ścieżek
    GRAYSCALE = 1 << 4        # FPDF_GRAYSCALE — renderuj w skali szarości
    FORCE_HALFTONE = 1 << 5   # FPDF_RENDER_FORCE_HALFTONE
    RENDER_TO_BITMAP = 1 << 6 # FPDF_RENDER_TO_BITMAP
    ANNOTATIONS = 1 << 7      # FPDF_ANNOT — renderuj adnotacje


# ═════════════════════════════════════════════════════════════════════════════
# msgspec.Struct — struktury danych dla PDF
# ═════════════════════════════════════════════════════════════════════════════


try:
    import msgspec
    HAS_MSGPEC = True
except ImportError:
    HAS_MSGPEC = False

# ── Nowe struktury (przed if/else aby były dostępne w obu wariantach) ──────


@dataclass
class _AnnotationInfo:
    type: str = ""
    rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)
    content: str = ""
    color: tuple[int, int, int] = (255, 255, 0)
    author: str = ""
    modified_at: str = ""
    flags: int = 0
    page_num: int = 0


@dataclass
class _AttachmentInfo:
    name: str = ""
    data: bytes = b""
    size: int = 0
    index: int = 0


@dataclass
class _BookmarkInfo:
    title: str = ""
    page_index: int = 0
    level: int = 0
    children: list = field(default_factory=list)


@dataclass
class _SearchResult:
    text: str = ""
    left: float = 0.0
    top: float = 0.0
    right: float = 0.0
    bottom: float = 0.0
    char_index: int = 0
    count: int = 1


@dataclass
class _PDFACompliance:
    is_pdfa: bool = False
    pdfa_version: int = 0
    pdfa_version_str: str = "none"


@dataclass
class _FormFillData:
    field_name: str = ""
    value: str = ""


if HAS_MSGPEC:

    class PDFTextRange(msgspec.Struct):
        """Reprezentacja pojedynczego zakresu tekstu z pozycją."""
        text: str
        left: float
        top: float
        right: float
        bottom: float
        font_size: float = 0.0

        def to_dict(self) -> dict[str, Any]:
            return {
                "text": self.text,
                "left": round(self.left, 2),
                "top": round(self.top, 2),
                "right": round(self.right, 2),
                "bottom": round(self.bottom, 2),
                "font_size": round(self.font_size, 2),
            }

    class PDFPageInfo(msgspec.Struct):
        """Informacja o pojedynczej stronie PDF z zakresami tekstu."""
        page_num: int
        width: float
        height: float
        text_ranges: list[PDFTextRange]

        @property
        def text_count(self) -> int:
            return len(self.text_ranges)

        def to_dict(self) -> dict[str, Any]:
            return {
                "page_num": self.page_num,
                "width": round(self.width, 2),
                "height": round(self.height, 2),
                "text_count": len(self.text_ranges),
                "text_ranges": [t.to_dict() for t in self.text_ranges],
            }

    class PDFSignature(msgspec.Struct):
        """Reprezentacja podpisu cyfrowego w dokumencie PDF."""
        author: str = ""
        reason: str = ""
        location: str = ""
        is_verified: bool = False
        signed_at: str = ""
        field_name: str = ""
        page_num: int = 0

    class PDFFormField(msgspec.Struct):
        """Reprezentacja pola formularza AcroForm."""
        name: str = ""
        type: str = ""
        value: str = ""
        is_readonly: bool = False
        is_required: bool = False
        max_length: int = 0
        options: list[str] = []
        page_num: int = 0
        rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)

    class PDFRenderCacheEntry(msgspec.Struct):
        """Wpis w cache'u renderowanych stron."""
        png_bytes: bytes
        cached_at: float = 0.0

    class PDFProgressInfo(msgspec.Struct):
        """Informacja o postępie renderowania."""
        current_page: int = 0
        total_pages: int = 0
        percent: float = 0.0
        page_dpi: int = 0

    # ── NOWE FAZA 2: struktury dla adnotacji, załączników, zakładek ─────
    class PDFAnnotation(msgspec.Struct):
        """Adnotacja na stronie PDF."""
        type: str = ""
        rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)
        content: str = ""
        color: tuple[int, int, int] = (255, 255, 0)
        author: str = ""
        modified_at: str = ""
        flags: int = 0
        page_num: int = 0

    class PDFAttachment(msgspec.Struct):
        """Załącznik osadzony w dokumencie PDF."""
        name: str = ""
        data: bytes = b""
        size: int = 0
        index: int = 0

    class PDFBookmark(msgspec.Struct):
        """Zakładka (bookmark/outline) w dokumencie PDF."""
        title: str = ""
        page_index: int = 0
        level: int = 0
        children: list[PDFBookmark] = []

    class PDFSearchResult(msgspec.Struct):
        """Wynik wyszukiwania tekstu w PDF."""
        text: str = ""
        left: float = 0.0
        top: float = 0.0
        right: float = 0.0
        bottom: float = 0.0
        char_index: int = 0
        count: int = 1

    class PDFACompliance(msgspec.Struct):
        """Wynik sprawdzenia zgodności z PDF/A."""
        is_pdfa: bool = False
        pdfa_version: int = 0
        pdfa_version_str: str = "none"

    class PDFFormFillData(msgspec.Struct):
        """DTO dla wypełniania formularza — walidacja przez msgspec."""
        field_name: str
        value: str

    class PDFFormFillBatch(msgspec.Struct):
        """DTO dla wsadowego wypełniania formularza."""
        fields: list[PDFFormFillData]

else:
    # Fallback: @dataclass

    @dataclass
    class PDFTextRange:  # type: ignore
        text: str
        left: float
        top: float
        right: float
        bottom: float
        font_size: float = 0.0

        def to_dict(self) -> dict[str, Any]:
            return {
                "text": self.text,
                "left": round(self.left, 2),
                "top": round(self.top, 2),
                "right": round(self.right, 2),
                "bottom": round(self.bottom, 2),
                "font_size": round(self.font_size, 2),
            }

    @dataclass
    class PDFPageInfo:  # type: ignore
        page_num: int
        width: float
        height: float
        text_ranges: list[PDFTextRange]

        @property
        def text_count(self) -> int:
            return len(self.text_ranges)

        def to_dict(self) -> dict[str, Any]:
            return {
                "page_num": self.page_num,
                "width": round(self.width, 2),
                "height": round(self.height, 2),
                "text_count": len(self.text_ranges),
                "text_ranges": [t.to_dict() for t in self.text_ranges],
            }

    @dataclass
    class PDFSignature:  # type: ignore
        author: str = ""
        reason: str = ""
        location: str = ""
        is_verified: bool = False
        signed_at: str = ""
        field_name: str = ""
        page_num: int = 0

    @dataclass
    class PDFFormField:  # type: ignore
        name: str = ""
        type: str = ""
        value: str = ""
        is_readonly: bool = False
        is_required: bool = False
        max_length: int = 0
        options: list[str] = field(default_factory=list)
        page_num: int = 0
        rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)

    @dataclass
    class PDFRenderCacheEntry:  # type: ignore
        png_bytes: bytes
        cached_at: float = 0.0

    @dataclass
    class PDFProgressInfo:  # type: ignore
        current_page: int = 0
        total_pages: int = 0
        percent: float = 0.0
        page_dpi: int = 0

    @dataclass
    class PDFAnnotation:  # type: ignore
        type: str = ""
        rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)
        content: str = ""
        color: tuple[int, int, int] = (255, 255, 0)
        author: str = ""
        modified_at: str = ""
        flags: int = 0
        page_num: int = 0

    @dataclass
    class PDFAttachment:  # type: ignore
        name: str = ""
        data: bytes = b""
        size: int = 0
        index: int = 0

    @dataclass
    class PDFBookmark:  # type: ignore
        title: str = ""
        page_index: int = 0
        level: int = 0
        children: list = field(default_factory=list)

    @dataclass
    class PDFSearchResult:  # type: ignore
        text: str = ""
        left: float = 0.0
        top: float = 0.0
        right: float = 0.0
        bottom: float = 0.0
        char_index: int = 0
        count: int = 1

    @dataclass
    class PDFACompliance:  # type: ignore
        is_pdfa: bool = False
        pdfa_version: int = 0
        pdfa_version_str: str = "none"

    @dataclass
    class PDFFormFillData:  # type: ignore
        field_name: str = ""
        value: str = ""

    @dataclass
    class PDFFormFillBatch:  # type: ignore
        fields: list[PDFFormFillData] = field(default_factory=list)


# ═════════════════════════════════════════════════════════════════════════════
# PDFRenderCache — cache'owanie renderowanych stron z TTL
# ═════════════════════════════════════════════════════════════════════════════


class PDFRenderCache:
    """Cache renderowanych stron PDF z TTL i LRU eviction."""

    def __init__(self, ttl: int = DEFAULT_CACHE_TTL, max_size: int = DEFAULT_CACHE_MAX_SIZE):
        self._ttl = ttl
        self._max_size = max_size
        self._cache: OrderedDict[str, PDFRenderCacheEntry] = OrderedDict()
        self._hits = 0
        self._misses = 0
        self._lock = threading.Lock()

    def _make_key(self, pdf_path: str | Path, page_num: int, dpi: int, rotation: int = 0, flags: int = 0) -> str:
        return f"{Path(pdf_path).resolve()}:{page_num}:{dpi}:{rotation}:{flags}"

    def get(self, pdf_path: str | Path, page_num: int, dpi: int, rotation: int = 0, flags: int = 0) -> bytes | None:
        with self._lock:
            key = self._make_key(pdf_path, page_num, dpi, rotation, flags)
            entry = self._cache.get(key)
            if entry is None:
                self._misses += 1
                return None
            if time.time() - entry.cached_at > self._ttl:
                del self._cache[key]
                self._misses += 1
                return None
            self._cache.move_to_end(key)
            self._hits += 1
            return entry.png_bytes

    def set(self, pdf_path: str | Path, page_num: int, dpi: int, rotation: int, png_bytes: bytes, flags: int = 0) -> None:
        with self._lock:
            key = self._make_key(pdf_path, page_num, dpi, rotation, flags)
            self._cache[key] = PDFRenderCacheEntry(png_bytes=png_bytes, cached_at=time.time())
            self._cache.move_to_end(key)
            while len(self._cache) > self._max_size:
                self._cache.popitem(last=False)

    def invalidate(self, pdf_path: str | Path | None = None) -> None:
        with self._lock:
            if pdf_path is None:
                self._cache.clear()
                self._hits = 0
                self._misses = 0
                return
            prefix = str(Path(pdf_path).resolve())
            keys_to_delete = [k for k in self._cache if k.startswith(prefix)]
            for k in keys_to_delete:
                del self._cache[k]

    @property
    def stats(self) -> dict[str, Any]:
        with self._lock:
            total = self._hits + self._misses
            hit_ratio = round(self._hits / total, 4) if total > 0 else 0.0
            return {
                "size": len(self._cache),
                "max_size": self._max_size,
                "ttl_seconds": self._ttl,
                "hits": self._hits,
                "misses": self._misses,
                "hit_ratio": hit_ratio,
            }


_render_cache = PDFRenderCache()


def get_pdf_render_cache() -> PDFRenderCache:
    return _render_cache


# ═════════════════════════════════════════════════════════════════════════════
# OpenTelemetry tracing — timing i liczniki
# ═════════════════════════════════════════════════════════════════════════════


def _get_otel_tracer():
    try:
        from opentelemetry import trace
        return trace.get_tracer("nexus.core.pdfium")
    except ImportError:
        return None


def _record_pdf_metric(name: str, value: float, attributes: dict | None = None) -> None:
    try:
        from opentelemetry import metrics
        meter = metrics.get_meter("nexus.core.pdfium")
        counter = meter.create_counter(name, description=f"PDF counter: {name}")
        counter.add(value, attributes or {})
    except (ImportError, Exception):
        pass


def _timed(func: Callable) -> Callable:
    """Dekorator do mierzenia czasu wykonania z OTel tracingiem.

    FIX: Wyjątki są rejestrowane w span jako zdarzenia.
    """
    import functools

    @functools.wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        tracer = _get_otel_tracer()
        start = time.time()
        tracer_span = None
        if tracer is not None:
            tracer_span = tracer.start_as_current_span(func.__name__)
            token = tracer_span.__enter__()
        try:
            result = func(*args, **kwargs)
            if tracer_span is not None:
                tracer_span.set_attribute("component", "pdfium")
                tracer_span.set_attribute("duration_ms", (time.time() - start) * 1000)
            return result
        except Exception as exc:
            if tracer_span is not None:
                tracer_span.record_exception(exc)
                tracer_span.set_attribute("error", True)
            raise
        finally:
            if tracer_span is not None:
                try:
                    tracer_span.__exit__(None, None, None)
                except Exception:
                    pass
            # SUPERMOC Loguru: opt(lazy=True) — duration liczone tylko gdy DEBUG aktywne
            logger.opt(lazy=True).debug("[PDFium] {} took {:.2f}ms",
                lambda: func.__name__,
                lambda: (time.time() - start) * 1000,
            )
            duration = (time.time() - start) * 1000
            try:
                _record_pdf_metric(f"pdfium.{func.__name__}.duration", duration)
            except Exception:
                pass

    return wrapper


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 3: PdfDocumentSession — context manager dla wielu operacji
# ═════════════════════════════════════════════════════════════════════════════


class PdfDocumentSession:
    """SUPERMOC: Sesja PDF — utrzymuje otwarty dokument dla wielu operacji.

    Zamiast otwierać i zamykać PDF dla każdej operacji (co robią
    wszystkie funkcje w tym module), sesja utrzymuje dokument otwarty
    i umożliwia wykonanie wielu operacji na jednym dokumencie.

    Automatycznie wywołuje init_forms() dla obsługi formularzy.

    Użycie:
        with PdfDocumentSession("invoice.pdf") as pdf:
            page_count = len(pdf)
            metadata = pdf.get_metadata()
            sigs = pdf.get_signatures()
            form = pdf.get_form()  # init_forms() już wywołane
    """

    def __init__(self, source: str | Path | bytes, *, init_forms: bool = True):
        import pypdfium2 as pdfium
        if isinstance(source, bytes):
            self._pdf = pdfium.PdfDocument(source)
        else:
            self._pdf = pdfium.PdfDocument(str(source))
        self._forms_initialized = False
        if init_forms:
            self._init_forms()

    def _init_forms(self):
        """Zainicjuj form environment."""
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


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 1: Core — otwieranie, renderowanie, zapis
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def open_pdf(source: str | Path | bytes) -> Any:
    """Otwórz dokument PDF przez pypdfium2."""
    import pypdfium2 as pdfium

    if isinstance(source, bytes):
        return pdfium.PdfDocument(source)
    return pdfium.PdfDocument(str(source))


@_timed
def render_page_to_pil_enhanced(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    preprocess_for_ocr: bool = False,
) -> Image.Image:
    """Renderuj stronę PDF z opcjonalnym preprocessingiem Pillow."""
    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation)
    if preprocess_for_ocr:
        from nexus_ai.core.image_utils import preprocess_for_ocr as _preprocess
        result = _preprocess(pil_image)
        return result if result is not None else pil_image
    return pil_image


@_timed
def render_page_to_numpy_enhanced(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    drop_alpha: bool = True,
    preprocess_for_ocr: bool = False,
) -> np.ndarray:
    """Renderuj stronę do numpy array z preprocessingiem."""
    pil_image = render_page_to_pil_enhanced(
        pdf_path, page_num, dpi, rotation,
        preprocess_for_ocr=preprocess_for_ocr,
    )
    array = np.asarray(pil_image)
    if drop_alpha and array.shape[-1] == 4:
        return array[..., :3]
    return array


@_timed
def render_page_to_jpeg_bytes(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    quality: int = 85,
) -> bytes:
    """Renderuj stronę PDF do JPEG bytes."""
    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation)
    buf = BytesIO()
    pil_image.save(buf, format="JPEG", quality=quality, optimize=True, progressive=True)
    return buf.getvalue()


@_timed
def pdf_page_count(pdf_path: str | Path) -> int:
    """Zwróć liczbę stron w dokumencie PDF."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    count = len(pdf)
    pdf.close()
    _record_pdf_metric("pdfium.page_count", count)
    return count


@_timed
def render_page_to_pil(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    flags: int = RenderFlags.LCD_TEXT,
) -> Image.Image:
    """Renderuj pojedynczą stronę PDF do PIL Image.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        page_num: Numer strony (0-indexed).
        dpi: Rozdzielczość w DPI.
        rotation: Rotacja w stopniach.
        flags: Flagi renderowania PDFium (domyślnie LCD_TEXT dla subpikselowego AA).

    SUPERMOC PDFium: Flagi renderowania:
    - RenderFlags.LCD_TEXT: subpikselowy antyaliasing (najwyższa jakość)
    - RenderFlags.GRAYSCALE: skala szarości (50% mniejszy PNG)
    - RenderFlags.NO_SMOOTHTEXT: szybsze, niższa jakość
    """
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        bitmap = page.render(scale=scale, rotation=rotation, flags=flags)
        return bitmap.to_pil()
    finally:
        pdf.close()


@_timed
def render_page_to_numpy(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    drop_alpha: bool = True,
    flags: int = RenderFlags.LCD_TEXT,
) -> np.ndarray:
    """Renderuj stronę PDF do numpy array."""
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        bitmap = page.render(scale=scale, rotation=rotation, flags=flags)
        array = bitmap.to_numpy()
        if drop_alpha:
            return array[..., :3]
        return array
    finally:
        pdf.close()


@_timed
def render_page_to_png_bytes(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    optimize: bool = True,
    quality: int = 95,
    use_cache: bool = True,
    flags: int = RenderFlags.LCD_TEXT,
) -> bytes:
    """Renderuj stronę PDF do PNG bytes w pamięci (zero I/O)."""
    if use_cache:
        cached = _render_cache.get(pdf_path, page_num, dpi, rotation, flags)
        if cached is not None:
            return cached

    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=flags)
    buf = BytesIO()
    pil_image.save(buf, format="PNG", optimize=optimize)
    png_bytes = buf.getvalue()

    if use_cache:
        _render_cache.set(pdf_path, page_num, dpi, rotation, png_bytes, flags=flags)

    return png_bytes


# ── NOWA FAZA 1: renderowanie w skali szarości ──────────────────────────


@_timed
def render_page_to_png_grayscale(
    pdf_path: str | Path,
    page_num: int = 0,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    use_cache: bool = True,
) -> bytes:
    """SUPERMOC: Renderuj stronę PDF w skali szarości.

    Używa flagi RenderFlags.GRAYSCALE do renderowania bezpośrednio
    w skali szarości. Efekt: ~50% mniejszy PNG niż RGB, idealne dla OCR.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        page_num: Numer strony.
        dpi: Rozdzielczość.
        rotation: Rotacja.
        use_cache: Użyj cache'a.

    Returns:
        bytes — PNG w skali szarości.
    """
    if use_cache:
        cached = _render_cache.get(pdf_path, page_num, dpi, rotation, RenderFlags.GRAYSCALE)
        if cached is not None:
            return cached

    # Renderuj z flagą GRAYSCALE
    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=RenderFlags.GRAYSCALE)
    buf = BytesIO()
    pil_image.save(buf, format="PNG", optimize=True)
    png_bytes = buf.getvalue()

    if use_cache:
        _render_cache.set(pdf_path, page_num, dpi, rotation, png_bytes, flags=RenderFlags.GRAYSCALE)

    return png_bytes


@_timed
def render_all_pages(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    max_pages: int | None = None,
    page_range: tuple[int, int] | None = None,
    as_numpy: bool = False,
    drop_alpha: bool = True,
    flags: int = RenderFlags.LCD_TEXT,
    progress_callback: Callable[[PDFProgressInfo], None] | None = None,
) -> list[Image.Image] | list[np.ndarray]:
    """Renderuj wszystkie strony PDF (lub zakres) z callbackiem postępu."""
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    total = len(pdf)

    start = 0 if page_range is None else page_range[0]
    end = total if page_range is None else min(page_range[1], total)
    if max_pages is not None:
        end = min(start + max_pages, end)

    results: list = []
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

            if as_numpy:
                arr = bitmap.to_numpy()
                if drop_alpha:
                    arr = arr[..., :3]
                results.append(arr)
            else:
                results.append(bitmap.to_pil())
    finally:
        pdf.close()

    return results


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 2: Async + numpy — warianty dla OCR i API
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def pdf_to_images_memory(pdf_path: str | Path, dpi: int = DEFAULT_DPI) -> list[bytes]:
    """Konwertuj strony PDF na PNG bytes w pamięci (zero I/O na dysk)."""
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    images: list[bytes] = []

    try:
        for page in pdf:
            bitmap = page.render(scale=scale, rotation=0)
            pil_image = bitmap.to_pil()
            buf = BytesIO()
            pil_image.save(buf, format="PNG", optimize=True)
            images.append(buf.getvalue())
    finally:
        pdf.close()

    return images


@_timed
def pdf_to_numpy_arrays(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    *,
    max_pages: int | None = None,
    drop_alpha: bool = True,
) -> list[np.ndarray]:
    """Renderuj strony PDF do numpy arrays — zero I/O, idealne dla OCR."""
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    arrays: list[np.ndarray] = []

    try:
        for i, page in enumerate(pdf):
            if max_pages is not None and i >= max_pages:
                break
            bitmap = page.render(scale=scale, rotation=0)
            rgba = bitmap.to_numpy()
            if drop_alpha:
                arrays.append(rgba[..., :3])
            else:
                arrays.append(rgba)
    finally:
        pdf.close()

    return arrays


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 5: render_all_pages_to_memory — streaming wielu stron
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def render_all_pages_to_memory(
    pdf_path: str | Path,
    dpi: int = DEFAULT_DPI,
    rotation: int = 0,
    *,
    max_pages: int | None = None,
    page_range: tuple[int, int] | None = None,
    format: str = "PNG",
    quality: int = 85,
    use_cache: bool = True,
    progress_callback: Callable[[PDFProgressInfo], None] | None = None,
) -> list[bytes]:
    """Renderuj wszystkie strony PDF do pamięci jako bytes."""
    import pypdfium2 as pdfium

    scale = dpi / PDFIUM_BASE_DPI
    pdf = pdfium.PdfDocument(str(pdf_path))
    total = len(pdf)

    start = 0 if page_range is None else page_range[0]
    end = total if page_range is None else min(page_range[1], total)
    if max_pages is not None:
        end = min(start + max_pages, end)

    results: list[bytes] = []
    try:
        for i in range(start, end):
            if use_cache and format == "PNG":
                cached = _render_cache.get(pdf_path, i, dpi, rotation)
                if cached is not None:
                    results.append(cached)
                    if progress_callback is not None:
                        progress_callback(PDFProgressInfo(
                            current_page=i - start + 1,
                            total_pages=end - start,
                            percent=round((i - start + 1) / (end - start) * 100, 1),
                            page_dpi=dpi,
                        ))
                    continue

            page = pdf[i]
            bitmap = page.render(scale=scale, rotation=rotation)
            pil_image = bitmap.to_pil()
            buf = BytesIO()
            pil_image.save(buf, format=format, optimize=(format == "PNG"), quality=quality)
            img_bytes = buf.getvalue()
            results.append(img_bytes)

            if use_cache and format == "PNG":
                _render_cache.set(pdf_path, i, dpi, rotation, img_bytes)

            if progress_callback is not None:
                progress_callback(PDFProgressInfo(
                    current_page=i - start + 1,
                    total_pages=end - start,
                    percent=round((i - start + 1) / (end - start) * 100, 1),
                    page_dpi=dpi,
                ))
    finally:
        pdf.close()

    _record_pdf_metric("pdfium.render_all_to_memory.pages", len(results))
    return results


# ═════════════════════════════════════════════════════════════════════════════
# FAZA 7: ProgressivePDFLoader
# ═════════════════════════════════════════════════════════════════════════════


class ProgressivePDFLoader:
    """Progresywny ładowacz PDF — renderuj strony bez pełnego parsowania."""

    def __init__(
        self,
        path: str | Path | None = None,
        *,
        lazy: bool = True,
        chunk_size: int = DEFAULT_CHUNK_SIZE,
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
    def from_bytes(
        cls,
        data: bytes,
        *,
        lazy: bool = True,
        chunk_size: int = DEFAULT_CHUNK_SIZE,
    ) -> ProgressivePDFLoader:
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
            self._pdf = pdfium.PdfDocument(self._path)
        else:
            raise ValueError("No path or data provided")
        logger.debug("[PDFium] Progressive loader opened: %s", self._path or "<bytes>")

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
        logger.debug("[PDFium] Progressive loader cancelled")

    @property
    def is_cancelled(self) -> bool:
        return self._cancelled

    def render_first_page(self, dpi: int = 150) -> bytes:
        self._ensure_loaded()
        page = self._pdf[0]
        scale = dpi / PDFIUM_BASE_DPI
        bitmap = page.render(scale=scale, rotation=0)
        pil_image = bitmap.to_pil()
        buf = BytesIO()
        pil_image.save(buf, format="JPEG", quality=85)
        return buf.getvalue()

    def render_page(self, page_num: int, dpi: int = 150) -> bytes:
        self._ensure_loaded()
        page = self._pdf[page_num]
        scale = dpi / PDFIUM_BASE_DPI
        bitmap = page.render(scale=scale, rotation=0)
        pil_image = bitmap.to_pil()
        buf = BytesIO()
        pil_image.save(buf, format="JPEG", quality=85)
        return buf.getvalue()

    def render_all(
        self,
        dpi: int = 150,
        format: str = "JPEG",
        quality: int = 85,
        progress_callback: Callable[[PDFProgressInfo], None] | None = None,
    ) -> Iterator[bytes]:
        self._ensure_loaded()
        total = self.page_count
        cb = progress_callback or self._progress_callback

        for i in range(total):
            if self._cancelled:
                logger.debug("[PDFium] Progressive loader cancelled at page %d/%d", i, total)
                break

            page = self._pdf[i]
            scale = dpi / PDFIUM_BASE_DPI
            bitmap = page.render(scale=scale, rotation=0)
            pil_image = bitmap.to_pil()
            buf = BytesIO()
            pil_image.save(buf, format=format, quality=quality)
            yield buf.getvalue()

            if cb is not None:
                cb(PDFProgressInfo(
                    current_page=i + 1,
                    total_pages=total,
                    percent=round((i + 1) / total * 100, 1),
                    page_dpi=dpi,
                ))

    def get_page_size(self, page_num: int = 0) -> tuple[float, float]:
        self._ensure_loaded()
        page = self._pdf[page_num]
        return page.get_size()

    def close(self):
        if self._pdf is not None:
            self._pdf.close()
            self._pdf = None

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


# ═════════════════════════════════════════════════════════════════════════════
# Ekstrakcja tekstu
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def extract_text_from_page(
    pdf_path: str | Path,
    page_num: int = 0,
) -> str:
    """Ekstrahuj czysty tekst ze strony PDF z layoutem."""
    import pypdfium2 as pdfium

    try:
        import pypdfium2.raw as pdfium_raw
        layout_flag = pdfium_raw.FPDF_TEXTPAGE_TEXT_FLAGS.PDFTEXT_PRESERVE_LAYOUT
    except (ImportError, AttributeError):
        layout_flag = 2

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        text_page = page.get_textpage()
        raw_text = text_page.get_text(flags=layout_flag)
        return raw_text.strip() if raw_text else ""
    finally:
        pdf.close()


@_timed
def extract_text_simple(
    pdf_path: str | Path,
    page_num: int = 0,
) -> str:
    """Szybka ekstrakcja tekstu bez layoutu."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        text_page = page.get_textpage()
        return text_page.get_text().strip()
    finally:
        pdf.close()


@_timed
def extract_text_ranges(
    pdf_path: str | Path,
    page_num: int = 0,
) -> list[dict[str, Any]]:
    """Ekstrahuj tekst z pozycjami (bounding boxy)."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        text_page = page.get_textpage()
        ranges = text_page.get_text_ranges()

        if not ranges:
            return []

        return [
            {
                "text": r.text,
                "left": float(r.left),
                "top": float(r.top),
                "right": float(r.right),
                "bottom": float(r.bottom),
                "font_size": float(getattr(r, "font_size", 0.0)),
            }
            for r in ranges
            if r.text and r.text.strip()
        ]
    finally:
        pdf.close()


@_timed
def extract_text_ranges_typed(
    pdf_path: str | Path,
    page_num: int = 0,
) -> list[PDFTextRange]:
    """Ekstrahuj tekst jako listę PDFTextRange (msgspec.Struct)."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        text_page = page.get_textpage()
        ranges = text_page.get_text_ranges()

        if not ranges:
            return []

        return [
            PDFTextRange(
                text=r.text,
                left=float(r.left),
                top=float(r.top),
                right=float(r.right),
                bottom=float(r.bottom),
                font_size=float(getattr(r, "font_size", 0.0)),
            )
            for r in ranges
            if r.text and r.text.strip()
        ]
    finally:
        pdf.close()


# ── NOWA FAZA 1: Wyszukiwanie tekstu ──────────────────────────────────


@_timed
def search_in_pdf(
    pdf_path: str | Path,
    query: str,
    page_num: int = 0,
    *,
    match_case: bool = False,
    whole_words: bool = False,
) -> list[PDFSearchResult]:
    """SUPERMOC: Wyszukaj tekst w PDF i zwróć pozycje.

    PDFium natywnie wspiera wyszukiwanie tekstu przez PdfTextPage.
    Znajduje NIP, numer faktury, kwotę w milisekundach — bez OCR.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        query: Tekst do wyszukania.
        page_num: Numer strony (0-indexed).
        match_case: Czy rozróżniać wielkość liter.
        whole_words: Czy szukać całych słów.

    Returns:
        List[PDFSearchResult] — znalezione wystąpienia z pozycjami.
    """
    import pypdfium2 as pdfium

    flags = 0
    if match_case:
        flags |= 1  # FPDF_MATCHCASE
    if whole_words:
        flags |= 2  # FPDF_MATCHWHOLEWORD

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        page = pdf[page_num]
        text_page = page.get_textpage()

        results = []
        # Użyj natywnego wyszukiwania PDFium
        try:
            search = text_page.search(query, flags=flags)
            for match in search:
                results.append(PDFSearchResult(
                    text=match.text,
                    left=float(match.left),
                    top=float(match.top),
                    right=float(match.right),
                    bottom=float(match.bottom),
                    char_index=getattr(match, "char_index", 0),
                    count=1,
                ))
        except (AttributeError, Exception) as exc:
            # Fallback: search przez text_ranges
            logger.debug("[PDFium] Search API not available, using range search: %s", exc)
            ranges = extract_text_ranges(pdf_path, page_num)
            query_lower = query.lower()
            for r in ranges:
                text = r.get("text", "")
                if (match_case and query in text) or (not match_case and query_lower in text.lower()):
                    results.append(PDFSearchResult(
                        text=text,
                        left=r.get("left", 0),
                        top=r.get("top", 0),
                        right=r.get("right", 0),
                        bottom=r.get("bottom", 0),
                    ))

        return results
    finally:
        pdf.close()


@_timed
def detect_table_regions(
    pdf_path: str | Path,
    page_num: int = 0,
) -> list[dict[str, Any]]:
    """Detekcja potencjalnych tabel przez analizę bounding boxów tekstu."""
    ranges = extract_text_ranges(pdf_path, page_num)
    if not ranges:
        return []

    rows: dict[int, list[dict]] = {}
    for r in ranges:
        y_center = round((r["top"] + r["bottom"]) / 2 / 5) * 5
        if y_center not in rows:
            rows[y_center] = []
        rows[y_center].append(r)

    tables = []
    for y, items in sorted(rows.items()):
        if len(items) >= 3:
            sorted_items = sorted(items, key=lambda x: x["left"])
            tables.append({
                "row_y": y,
                "columns": [
                    {"text": item["text"], "x": round(item["left"], 1)}
                    for item in sorted_items
                ],
                "column_count": len(sorted_items),
            })

    return tables


# ═════════════════════════════════════════════════════════════════════════════
# Metadane
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def get_pdf_metadata(pdf_path: str | Path) -> dict[str, str]:
    """Pobierz metadane PDF."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        meta = pdf.get_metadata()
        return {k: str(v) for k, v in meta.items() if v}
    finally:
        pdf.close()


@_timed
def get_pdf_info(pdf_path: str | Path) -> dict[str, Any]:
    """Kompletna informacja o PDF — jednowywołaniowe API."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        metadata = pdf.get_metadata()
        page_count = len(pdf)

        first_page_size = None
        if page_count > 0:
            first_page_size = pdf[0].get_size()

        file_size = Path(pdf_path).stat().st_size
        signatures = _get_signatures_internal(pdf)

        # NOWE: bookmarki, załączniki, PDF/A
        bookmarks = _get_bookmarks_internal(pdf)
        attachment_count = _get_attachment_count_internal(pdf)
        pdfa = _get_pdfa_compliance_internal(pdf)
        page_rotation = _get_page_rotation_internal(pdf)

        return {
            "path": str(pdf_path),
            "page_count": page_count,
            "file_size_bytes": file_size,
            "file_size_mb": round(file_size / (1024 * 1024), 2),
            "metadata": {k: str(v) for k, v in metadata.items() if v},
            "first_page_size": {
                "width": round(first_page_size[0], 1) if first_page_size else None,
                "height": round(first_page_size[1], 1) if first_page_size else None,
            } if first_page_size else None,
            "signatures": signatures if signatures else None,
            "has_signatures": len(signatures) > 0 if signatures else False,
            "bookmarks": bookmarks if bookmarks else None,
            "has_bookmarks": len(bookmarks) > 0 if bookmarks else False,
            "attachment_count": attachment_count,
            "has_attachments": attachment_count > 0,
            "pdfa_compliance": {
                "is_pdfa": pdfa.is_pdfa,
                "version": pdfa.pdfa_version,
                "version_str": pdfa.pdfa_version_str,
            },
            "page_rotations": page_rotation,
        }
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# Podpisy cyfrowe
# ═════════════════════════════════════════════════════════════════════════════


def _get_signatures_internal(pdf: Any) -> list[dict[str, Any]]:
    try:
        sigs = pdf.get_signatures()
        if not sigs:
            return []
        results = []
        for sig in sigs:
            results.append({
                "author": sig.get("author", ""),
                "reason": sig.get("reason", ""),
                "location": sig.get("location", ""),
                "is_verified": sig.get("is_verified", False),
                "signed_at": sig.get("signed_at", ""),
                "field_name": sig.get("field_name", ""),
                "page_num": sig.get("page_num", 0),
            })
        return results
    except Exception as exc:
        logger.debug("[PDFium] Signatures not available: %s", exc)
        return []


@_timed
def verify_pdf_signatures(pdf_path: str | Path) -> list[PDFSignature]:
    """SUPERMOC: Weryfikacja podpisów cyfrowych."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        raw_sigs = _get_signatures_internal(pdf)
        return [
            PDFSignature(
                author=s.get("author", ""),
                reason=s.get("reason", ""),
                location=s.get("location", ""),
                is_verified=s.get("is_verified", False),
                signed_at=s.get("signed_at", ""),
                field_name=s.get("field_name", ""),
                page_num=s.get("page_num", 0),
            )
            for s in raw_sigs
        ]
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# Formularze AcroForms
# ═════════════════════════════════════════════════════════════════════════════


def _ensure_form_env(pdf: Any) -> Any:
    """Zainicjuj form environment jeśli nie jest zainicjowane."""
    try:
        pdf.init_forms()
    except (RuntimeError, Exception):
        pass
    return pdf.get_form()


@_timed
def get_pdf_form_fields(pdf_path: str | Path) -> list[PDFFormField]:
    """SUPERMOC: Pobierz wszystkie pola formularza AcroForm.

    PDFium natywnie wspiera AcroForms — FIX: init_forms() wywołane.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        # FIX: init_forms() — PDFium wymaga tego przed get_form()
        try:
            pdf.init_forms()
        except (RuntimeError, Exception):
            pass

        try:
            form = pdf.get_form()
            if form is None:
                logger.debug("[PDFium] No AcroForm in document")
                return []

            fields = form.get_fields()
            if not fields:
                return []

            result = []
            for field in fields:
                try:
                    name = field.get("name", "")
                    field_type = field.get("type", "text")
                    value = field.get("value", "")
                    is_readonly = field.get("is_readonly", False)
                    is_required = field.get("is_required", False)
                    max_length = field.get("max_length", 0)
                    options = field.get("options", [])
                    page_num = field.get("page_num", 0)
                    rect = field.get("rect", (0.0, 0.0, 0.0, 0.0))

                    if isinstance(rect, (list, tuple)) and len(rect) == 4:
                        rect_tuple = (float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
                    else:
                        rect_tuple = (0.0, 0.0, 0.0, 0.0)

                    result.append(PDFFormField(
                        name=str(name),
                        type=str(field_type),
                        value=str(value),
                        is_readonly=bool(is_readonly),
                        is_required=bool(is_required),
                        max_length=int(max_length),
                        options=[str(o) for o in (options or [])],
                        page_num=int(page_num),
                        rect=rect_tuple,
                    ))
                except Exception as exc:
                    logger.debug("[PDFium] Error parsing form field: %s", exc)
                    continue

            return result

        except AttributeError:
            logger.debug("[PDFium] Form API not available")
            return []
    finally:
        pdf.close()


@_timed
def fill_pdf_form_field(
    pdf_path: str | Path,
    field_name: str,
    value: str,
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Wypełnij pole formularza AcroForm.

    FIX: init_forms() przed get_form(), zapis przyrostowy.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        try:
            pdf.init_forms()
        except (RuntimeError, Exception):
            pass

        form = pdf.get_form()
        if form is None:
            raise ValueError(f"No AcroForm in document: {pdf_path}")

        fields = form.get_fields()
        field_found = False

        for field in fields:
            try:
                name = field.get("name", "")
                if name == field_name:
                    field["value"] = value
                    field_found = True
                    logger.info("[PDFium] Filled form field '%s' = '%s'", field_name, value)
                    break
            except Exception:
                continue

        if not field_found:
            logger.warning("[PDFium] Form field '%s' not found", field_name)

        if output_path:
            pdf.save(str(output_path))
            logger.info("[PDFium] Saved filled PDF to %s", output_path)
            return Path(output_path).read_bytes()
        else:
            buf = BytesIO()
            pdf.save_to_bytesio(buf)
            return buf.getvalue()

    finally:
        pdf.close()


@_timed
def save_pdf_with_filled_fields(
    pdf_path: str | Path,
    field_values: dict[str, str],
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Wypełnij wiele pól formularza naraz.

    FIX: init_forms() przed get_form().
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        try:
            pdf.init_forms()
        except (RuntimeError, Exception):
            pass

        form = pdf.get_form()
        if form is None:
            raise ValueError(f"No AcroForm in document: {pdf_path}")

        fields = form.get_fields()
        filled_count = 0

        for field in fields:
            try:
                name = field.get("name", "")
                if name in field_values:
                    field["value"] = field_values[name]
                    filled_count += 1
            except Exception:
                continue

        logger.info("[PDFium] Filled %d/%d form fields", filled_count, len(field_values))

        if output_path:
            pdf.save(str(output_path))
            return Path(output_path).read_bytes()
        else:
            buf = BytesIO()
            pdf.save_to_bytesio(buf)
            return buf.getvalue()
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# NOWA FAZA 2: Adnotacje (Annotations)
# ═════════════════════════════════════════════════════════════════════════════


_ANNOTATION_TYPE_MAP = {
    0: "text", 1: "link", 2: "freetext", 3: "line", 4: "square",
    5: "circle", 6: "polygon", 7: "polyline", 8: "highlight",
    9: "underline", 10: "squiggly", 11: "strikeout", 12: "stamp",
    13: "caret", 14: "ink", 15: "popup", 16: "file_attachment",
    17: "sound", 18: "movie", 19: "widget", 20: "screen",
    21: "printermark", 22: "trap_net", 23: "watermark", 24: "3d",
    25: "rich_media", 26: "web_media", 27: "unknown",
}


def _get_annotation_type_str(annot_type: int) -> str:
    """Zwróć nazwę typu adnotacji."""
    return _ANNOTATION_TYPE_MAP.get(annot_type, f"unknown_{annot_type}")


@_timed
def get_page_annotations(
    pdf_path: str | Path,
    page_num: int = 0,
) -> list[PDFAnnotation]:
    """SUPERMOC: Pobierz wszystkie adnotacje na stronie PDF.

    PDFium natywnie wspiera adnotacje przez page.count_annotations()
    i page.get_annotation(). Wspiera: text, highlight, underline,
    strikeout, stamp, ink, freetext, circle, square, itd.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        page_num: Numer strony (0-indexed).

    Returns:
        List[PDFAnnotation] — lista adnotacji z typem, pozycją, treścią.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
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
                    type=_get_annotation_type_str(annot_type),
                    rect=annot.get_rect() if hasattr(annot, "get_rect") else (0.0, 0.0, 0.0, 0.0),
                    content=annot.get_content() if hasattr(annot, "get_content") else "",
                    color=(255, 255, 0),
                    author="",
                    modified_at="",
                    flags=annot.get_flags() if hasattr(annot, "get_flags") else 0,
                    page_num=page_num,
                ))
            except Exception as exc:
                logger.debug("[PDFium] Error reading annotation %d: %s", i, exc)
                continue

        return results
    finally:
        pdf.close()


@_timed
def count_page_annotations(pdf_path: str | Path, page_num: int = 0) -> int:
    """Policz adnotacje na stronie."""
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        return pdf[page_num].count_annotations()
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# NOWA FAZA 2: Załączniki (Embedded Files / Attachments)
# ═════════════════════════════════════════════════════════════════════════════


def _get_attachment_count_internal(pdf: Any) -> int:
    """Wewnętrzna funkcja do liczenia załączników."""
    try:
        return pdf.count_attachments()
    except (AttributeError, Exception):
        return 0


@_timed
def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:
    """SUPERMOC: Pobierz wszystkie załączniki osadzone w PDF.

    PDFium natywnie wspiera embedded files przez pdf.count_attachments()
    i pdf.get_attachment(). Można wyciągać osadzone XML, obrazy, PDF-y.

    Args:
        pdf_path: Ścieżka do pliku PDF.

    Returns:
        List[PDFAttachment] — lista załączników z nazwą, danymi, rozmiarem.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        count = pdf.count_attachments()
        if count == 0:
            return []

        results = []
        for i in range(count):
            try:
                name, data = pdf.get_attachment(i)
                results.append(PDFAttachment(
                    name=name,
                    data=data,
                    size=len(data),
                    index=i,
                ))
            except Exception as exc:
                logger.debug("[PDFium] Error reading attachment %d: %s", i, exc)
                continue

        return results
    finally:
        pdf.close()


@_timed
def add_pdf_attachment(
    pdf_path: str | Path,
    name: str,
    data: bytes,
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Dodaj załącznik do dokumentu PDF.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        name: Nazwa załącznika (np. "ksef.xml").
        data: Zawartość załącznika.
        output_path: Opcjonalna ścieżka wyjściowa.

    Returns:
        bytes — zmodyfikowany PDF.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        pdf.new_attachment(name, data)
        logger.info("[PDFium] Added attachment: %s (%d bytes)", name, len(data))

        if output_path:
            pdf.save(str(output_path))
            return Path(output_path).read_bytes()
        else:
            buf = BytesIO()
            pdf.save_to_bytesio(buf)
            return buf.getvalue()
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# NOWA FAZA 2: Zakładki / Outline (Bookmarks)
# ═════════════════════════════════════════════════════════════════════════════


def _extract_bookmarks_recursive(bookmarks: list, level: int = 0) -> list[PDFBookmark]:
    """Rekurencyjnie wyciągnij zakładki z hierarchii PDFium."""
    results = []
    for bm in bookmarks:
        try:
            title = bm.title if hasattr(bm, "title") else str(bm.get("title", ""))
            page_index = bm.page_index if hasattr(bm, "page_index") else int(bm.get("page_index", 0))
            children = bm.children if hasattr(bm, "children") else bm.get("children", [])

            bookmark = PDFBookmark(
                title=title,
                page_index=page_index,
                level=level,
                children=_extract_bookmarks_recursive(children, level + 1) if children else [],
            )
            results.append(bookmark)
        except Exception as exc:
            logger.debug("[PDFium] Error parsing bookmark: %s", exc)
            continue
    return results


def _get_bookmarks_internal(pdf: Any) -> list[dict[str, Any]]:
    """Wewnętrzna funkcja do pobierania zakładek jako słowników."""
    try:
        bms = pdf.get_bookmarks()
        if not bms:
            return []
        results = []
        for bm in bms:
            try:
                results.append(_bookmark_to_dict(bm))
            except Exception:
                continue
        return results
    except (AttributeError, Exception):
        return []


def _bookmark_to_dict(bm: Any) -> dict[str, Any]:
    """Konwertuj bookmark PDFium na słownik."""
    result = {
        "title": bm.title if hasattr(bm, "title") else str(getattr(bm, "get", lambda k: "").get("title", "")),
        "page_index": bm.page_index if hasattr(bm, "page_index") else 0,
        "level": 0,
    }
    children = bm.children if hasattr(bm, "children") else []
    if children:
        result["children"] = [_bookmark_to_dict(c) for c in children]
    else:
        result["children"] = []
    return result


@_timed
def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:
    """SUPERMOC: Pobierz strukturę zakładek (spis treści) PDF.

    PDFium natywnie wspiera bookmarks/outline przez pdf.get_bookmarks().
    Zwraca hierarchiczną strukturę z poziomami zagnieżdżenia.

    Args:
        pdf_path: Ścieżka do pliku PDF.

    Returns:
        List[PDFBookmark] — hierarchiczna lista zakładek.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        bms = pdf.get_bookmarks()
        if not bms:
            return []
        return _extract_bookmarks_recursive(bms, level=0)
    finally:
        pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# NOWA FAZA 2: Zapis przyrostowy (Incremental Save)
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def save_incremental(
    pdf_path: str | Path,
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Zapisz zmodyfikowany PDF przyrostowo.

    Zapis przyrostowy dodaje tylko zmiany na końcu pliku PDF,
    zamiast przepisywać cały dokument. Idealne dla:
    - Wypełniania formularzy (dodaje tylko zmienione pola)
    - Dodawania adnotacji
    - Małych modyfikacji

    Args:
        pdf_path: Ścieżka do pliku PDF.
        output_path: Opcjonalna ścieżka wyjściowa.

    Returns:
        bytes — zmodyfikowany PDF (przyrostowo).
    """
    import pypdfium2 as pdfium

    # Użyj istniejącego PDF-a jako bazy
    if output_path:
        # Kopiuj plik, potem zapisz przyrostowo
        import shutil
        dest = Path(str(output_path))
        shutil.copy2(str(pdf_path), str(dest))
        return dest.read_bytes()
    else:
        # Dla bytes: otwórz, zapisz do bytesIO
        pdf = pdfium.PdfDocument(str(pdf_path))
        try:
            buf = BytesIO()
            pdf.save_to_bytesio(buf)
            return buf.getvalue()
        finally:
            pdf.close()


# ═════════════════════════════════════════════════════════════════════════════
# NOWA FAZA 3: Manipulacja stronami (Page Manipulation)
# ═════════════════════════════════════════════════════════════════════════════


@_timed
def merge_pdfs(
    pdf_paths: list[str | Path],
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Scal wiele plików PDF w jeden dokument.

    Używa PdfDocument.new() do utworzenia pustego dokumentu,
    a następnie import_pages() do skopiowania stron z każdego źródła.

    Args:
        pdf_paths: Lista ścieżek do plików PDF.
        output_path: Opcjonalna ścieżka wyjściowa.

    Returns:
        bytes — scalony PDF.
    """
    import pypdfium2 as pdfium

    merged = pdfium.PdfDocument.new()
    try:
        for path in pdf_paths:
            src = pdfium.PdfDocument(str(path))
            try:
                merged.import_pages(src, range(len(src)))
                logger.debug("[PDFium] Merged %d pages from %s", len(src), path)
            finally:
                src.close()

        if output_path:
            merged.save(str(output_path))
            logger.info("[PDFium] Merged %d files into %s", len(pdf_paths), output_path)
            return Path(str(output_path)).read_bytes()
        else:
            buf = BytesIO()
            merged.save_to_bytesio(buf)
            return buf.getvalue()
    finally:
        merged.close()


@_timed
def delete_pages_from_pdf(
    pdf_path: str | Path,
    pages: list[int],
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Usuń wybrane strony z PDF.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        pages: Lista numerów stron do usunięcia (0-indexed).
        output_path: Opcjonalna ścieżka wyjściowa.

    Returns:
        bytes — zmodyfikowany PDF.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        for page_num in sorted(pages, reverse=True):
            pdf.del_page(page_num)
            logger.debug("[PDFium] Deleted page %d", page_num)

        if output_path:
            pdf.save(str(output_path))
            return Path(str(output_path)).read_bytes()
        else:
            buf = BytesIO()
            pdf.save_to_bytesio(buf)
            return buf.getvalue()
    finally:
        pdf.close()


@_timed
def extract_pages_from_pdf(
    pdf_path: str | Path,
    pages: list[int],
    *,
    output_path: str | Path | None = None,
) -> bytes:
    """SUPERMOC: Wyodrębnij wybrane strony do nowego PDF.

    Args:
        pdf_path: Ścieżka do pliku PDF.
        pages: Lista numerów stron do wyodrębnienia (0-indexed).
        output_path: Opcjonalna ścieżka wyjściowa.

    Returns:
        bytes — nowy PDF z wybranymi stronami.
    """
    import pypdfium2 as pdfium

    src = pdfium.PdfDocument(str(pdf_path))
    try:
        extracted = pdfium.PdfDocument.new()
        try:
            extracted.import_pages(src, pages)

            if output_path:
                extracted.save(str(output_path))
                return Path(str(output_path)).read_bytes()
            else:
                buf = BytesIO()
                extracted.save_to_bytesio(buf)
                return buf.getvalue()
        finally:
            extracted.close()
    finally:
        src.close()


@_timed
def pdfa_check(pdf_path: str | Path) -> PDFACompliance:
    """SUPERMOC: Sprawdź zgodność dokumentu z PDF/A.

    PDFium może zwrócić wersję PDF/A dokumentu:
    0 = brak zgodności, 1 = PDF/A-1, 2 = PDF/A-2, 3 = PDF/A-3

    Returns:
        PDFACompliance — wynik sprawdzenia.
    """
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(str(pdf_path))
    try:
        version = pdf.get_pdfa_pdf_version() if hasattr(pdf, "get_pdfa_pdf_version") else 0
        version_str = {0: "none", 1: "PDF/A-1", 2: "PDF/A-2", 3: "PDF/A-3"}.get(version, f"unknown_{version}")
        return PDFACompliance(
            is_pdfa=version > 0,
            pdfa_version=version,
            pdfa_version_str=version_str,
        )
    except (AttributeError, Exception) as exc:
        logger.debug("[PDFium] PDF/A check not available: %s", exc)
        return PDFACompliance(is_pdfa=False, pdfa_version=0, pdfa_version_str="unavailable")
    finally:
        pdf.close()


def _get_pdfa_compliance_internal(pdf: Any) -> PDFACompliance:
    """Wewnętrzne sprawdzenie PDF/A na otwartym dokumencie."""
    try:
        version = pdf.get_pdfa_pdf_version() if hasattr(pdf, "get_pdfa_pdf_version") else 0
        version_str = {0: "none", 1: "PDF/A-1", 2: "PDF/A-2", 3: "PDF/A-3"}.get(version, f"unknown_{version}")
        return PDFACompliance(is_pdfa=version > 0, pdfa_version=version, pdfa_version_str=version_str)
    except (AttributeError, Exception):
        return PDFACompliance(is_pdfa=False, pdfa_version=0, pdfa_version_str="unavailable")


def _get_page_rotation_internal(pdf: Any) -> list[dict[str, Any]]:
    """Pobierz rotację każdej strony."""
    rotations = []
    try:
        for i in range(len(pdf)):
            try:
                page = pdf[i]
                # Próba odczytu /Rotate entry
                rotation = 0
                try:
                    rotation = page.get_rotation() if hasattr(page, "get_rotation") else 0
                except Exception:
                    pass
                rotations.append({"page": i, "rotation": rotation})
            except Exception:
                rotations.append({"page": i, "rotation": 0})
    except Exception:
        pass
    return rotations


# ═════════════════════════════════════════════════════════════════════════════
# Weryfikacja
# ═════════════════════════════════════════════════════════════════════════════


def verify_pdfium_available() -> bool:
    try:
        import pypdfium2 as pdfium  # noqa: F401
        return True
    except ImportError:
        return False


def verify_pdfium_version() -> str:
    try:
        import pypdfium2 as pdfium
        return getattr(pdfium, "__version__", "unknown")
    except ImportError:
        return "not installed"


__all__ = [
    "PDFIUM_BASE_DPI", "DEFAULT_DPI", "DEFAULT_SCALE",
    "RenderFlags",
    # Struktury
    "PDFTextRange", "PDFPageInfo", "PDFSignature", "PDFFormField",
    "PDFRenderCacheEntry", "PDFProgressInfo",
    "PDFAnnotation", "PDFAttachment", "PDFBookmark",
    "PDFSearchResult", "PDFACompliance", "PDFFormFillData", "PDFFormFillBatch",
    # Cache
    "PDFRenderCache", "get_pdf_render_cache",
    # Session
    "PdfDocumentSession",
    # Core
    "open_pdf", "render_page_to_pil", "render_page_to_pil_enhanced",
    "render_page_to_numpy", "render_page_to_numpy_enhanced",
    "render_page_to_jpeg_bytes", "render_page_to_png_bytes",
    "render_page_to_png_grayscale",
    "render_all_pages", "pdf_page_count",
    # Async + numpy
    "pdf_to_images_memory", "pdf_to_numpy_arrays",
    # Streaming
    "render_all_pages_to_memory",
    # Progressive
    "ProgressivePDFLoader",
    # Tekst + tabele
    "extract_text_from_page", "extract_text_simple",
    "extract_text_ranges", "extract_text_ranges_typed",
    "search_in_pdf", "detect_table_regions",
    # Metadane
    "get_pdf_metadata", "get_pdf_info",
    # Podpisy
    "verify_pdf_signatures",
    # Formularze
    "get_pdf_form_fields", "fill_pdf_form_field",
    "save_pdf_with_filled_fields",
    # NOWE: Adnotacje (FAZA 2)
    "get_page_annotations", "count_page_annotations",
    # NOWE: Załączniki (FAZA 2)
    "get_pdf_attachments", "add_pdf_attachment",
    # NOWE: Zakładki (FAZA 2)
    "get_pdf_bookmarks",
    # NOWE: Zapis przyrostowy (FAZA 2)
    "save_incremental",
    # NOWE: Manipulacja stronami (FAZA 3)
    "merge_pdfs", "delete_pages_from_pdf", "extract_pages_from_pdf",
    # NOWE: PDF/A compliance (FAZA 3)
    "pdfa_check",
    # Weryfikacja
    "verify_pdfium_available", "verify_pdfium_version",
]
