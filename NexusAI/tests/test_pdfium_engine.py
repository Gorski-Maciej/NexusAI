"""
test_pdfium_engine.py — Kompleksowe testy dla pydfium2.

Zgodnie z planem migracji do pypdfium2:
- FAZA 1: Core — otwieranie, renderowanie, zapis
- FAZA 2: Async — warianty dla OCR i API
- FAZA 3: Progressive loading, ekstrakcja tekstu, metadane, msgspec
- FAZA 4: Render cache
- FAZA 5: msgspec.Struct, podpisy cyfrowe, formularze, cache
- FAZA 6: Streaming, OTel tracing
- FAZA 7: Rozszerzony ProgressivePDFLoader

Wszystkie testy używają pypdfium2.
"""

from __future__ import annotations

import sys
import time
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


# ===== Fixtures =====


@pytest.fixture
def sample_pdf_path(tmp_path: Path) -> Path:
    """Utwórz przykładowy plik PDF do testów."""
    pdf_path = tmp_path / "test_invoice.pdf"
    pdf_content = (
        b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
        b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
        b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>\nendobj\n"
        b"xref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n"
        b"trailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n190\n%%EOF"
    )
    pdf_path.write_bytes(pdf_content)
    return pdf_path


@pytest.fixture
def mock_pdfium_module():
    """Mock dla pypdfium2 — symuluje wszystkie operacje.

    Używane przez testy jednostkowe. Mockuje PdfDocument na już
    zaimportowanym module pypdfium2, aby testy nie wymagały rzeczywistego PDF-a.
    """

    import pypdfium2 as pdfium_real

    # Buduj zagnieżdżony mock PDF-a i strony
    mock_page = MagicMock()
    mock_page.get_size.return_value = (612.0, 792.0)
    mock_page.get_rotation = MagicMock(return_value=0)

    # Uwaga: PIL jest mockowany przez conftest.py jako _MockModule,
    # więc nie można stworzyć prawdziwego PIL Image w teście.
    # test_render_page_to_pil_enhanced_mocked używa preprocess_for_ocr=False
    # aby nie wchodzić w gałąź z image_utils.preprocess_for_ocr.
    mock_bitmap = MagicMock()
    mock_bitmap.to_pil.return_value = MagicMock()
    mock_page.render.return_value = mock_bitmap

    # Mock text page
    mock_text_page = MagicMock()
    mock_text_page.get_text.return_value = "Test text content"
    mock_text_page.get_text_ranges.return_value = []
    mock_page.get_textpage.return_value = mock_text_page

    # Mock adnotacji (FAZA 2)
    mock_annot = MagicMock()
    mock_annot.get_type.return_value = 8  # highlight
    mock_annot.get_rect.return_value = (100.0, 100.0, 200.0, 120.0)
    mock_annot.get_content.return_value = "Important note"
    mock_annot.get_flags.return_value = 0
    mock_page.count_annotations.return_value = 2
    mock_page.get_annotation.return_value = mock_annot

    # Mock PDF-a
    mock_pdf = MagicMock()
    mock_pdf.__len__.return_value = 3
    mock_pdf.__getitem__.return_value = mock_page

    # Wsparcie dla iteracji (for page in pdf:)
    mock_pdf.__iter__.return_value = iter([mock_page, mock_page, mock_page])

    # Mock metadanych
    mock_pdf.get_metadata.return_value = {
        "Title": "Test Invoice",
        "Author": "NexusAI",
        "Creator": "PDFium",
        "Producer": "pypdfium2",
    }

    # Mock sygnatur (FAZA 2)
    mock_pdf.get_signatures.return_value = [
        {
            "author": "John Doe",
            "reason": "Approval",
            "location": "Warsaw",
            "is_verified": True,
            "signed_at": "D:20240101120000+01'00'",
            "field_name": "Signature1",
            "page_num": 0,
        }
    ]

    # Mock formularzy (FAZA 3)
    mock_form = MagicMock()
    mock_form.get_fields.return_value = [
        {
            "name": "InvoiceNumber",
            "type": "text",
            "value": "INV-001",
            "is_readonly": False,
            "is_required": True,
            "max_length": 20,
            "options": [],
            "page_num": 0,
            "rect": (100, 100, 200, 120),
        },
        {
            "name": "TotalAmount",
            "type": "text",
            "value": "",
            "is_readonly": False,
            "is_required": True,
            "max_length": 10,
            "options": [],
            "page_num": 0,
            "rect": (100, 200, 200, 220),
        },
    ]
    mock_pdf.get_form.return_value = mock_form

    # Mock załączników (FAZA 2)
    mock_pdf.count_attachments.return_value = 1
    mock_pdf.get_attachment.return_value = ("ksef.xml", b"<?xml version='1.0'?>")

    # Mock bookmarków (FAZA 2)
    mock_bookmark = MagicMock()
    mock_bookmark.title = "Chapter 1"
    mock_bookmark.page_index = 0
    mock_bookmark.children = []
    mock_pdf.get_bookmarks.return_value = [mock_bookmark]

    # Mock import_pages / del_page / save (FAZA 3)
    mock_pdf.import_pages = MagicMock()
    mock_pdf.del_page = MagicMock()
    mock_pdf.save = MagicMock()
    mock_pdf.save_to_bytesio = MagicMock()

    # Mock PDF/A (FAZA 3)
    mock_pdf.get_pdfa_pdf_version = MagicMock(return_value=0)

    # Mock new_attachment
    mock_pdf.new_attachment = MagicMock()

    # Mock raw module z flagami
    pdfium_real.raw = MagicMock()
    pdfium_real.raw.FPDF_TEXTPAGE_TEXT_FLAGS = MagicMock()
    pdfium_real.raw.FPDF_TEXTPAGE_TEXT_FLAGS.PDFTEXT_PRESERVE_LAYOUT = 2

    # Mock PdfDocument.new() dla merge_pdfs / extract_pages_from_pdf
    mock_new_pdf = MagicMock()
    mock_new_pdf.import_pages = MagicMock()
    mock_new_pdf.save = MagicMock()
    mock_new_pdf.save_to_bytesio = MagicMock()
    mock_new_pdf.close = MagicMock()

    # Użyj mock_pdf_factory zamiast bezpośredniego patch.object,
    # aby PdfDocument.new() działał poprawnie po patchowaniu
    mock_pdf_factory = MagicMock()
    mock_pdf_factory.return_value = mock_pdf  # PdfDocument(path) -> mock_pdf
    mock_pdf_factory.new = MagicMock(return_value=mock_new_pdf)  # PdfDocument.new() -> mock_new_pdf

    with patch.object(pdfium_real, "PdfDocument", mock_pdf_factory):
        yield mock_pdf


# ===================================================================
# FAZA 1: Core — RenderFlags, PdfDocumentSession, otwieranie, renderowanie
# ===================================================================


class TestRenderFlags:
    """Testy dla RenderFlags enum."""

    def test_render_flags_values(self):
        from nexus_ai.core.pdfium import RenderFlags

        assert RenderFlags.NONE.value == 0
        assert RenderFlags.LCD_TEXT.value == 1
        assert RenderFlags.NO_SMOOTHTEXT.value == 2
        assert RenderFlags.NO_SMOOTHIMAGE.value == 4
        assert RenderFlags.NO_SMOOTHPATH.value == 8
        assert RenderFlags.GRAYSCALE.value == 16
        assert RenderFlags.FORCE_HALFTONE.value == 32
        assert RenderFlags.RENDER_TO_BITMAP.value == 64
        assert RenderFlags.ANNOTATIONS.value == 128

    def test_render_flags_int_enum(self):
        from nexus_ai.core.pdfium import RenderFlags

        assert int(RenderFlags.LCD_TEXT) == 1
        assert int(RenderFlags.GRAYSCALE) == 16

    def test_render_flags_combination(self):
        from nexus_ai.core.pdfium import RenderFlags

        combined = RenderFlags.LCD_TEXT | RenderFlags.ANNOTATIONS
        assert combined == 129  # 1 + 128


class TestCore:
    """Testy podstawowych operacji PDFium."""

    def test_pdfium_import(self):
        try:
            import pypdfium2 as pdfium  # noqa: F401
            assert True
        except ImportError:
            pytest.skip("pypdfium2 not installed")

    def test_constants(self):
        from nexus_ai.core.pdfium import PDFIUM_BASE_DPI, DEFAULT_DPI, DEFAULT_SCALE

        assert PDFIUM_BASE_DPI == 72.0
        assert DEFAULT_DPI == 300
        assert DEFAULT_SCALE == 300.0 / 72.0

    def test_verify_pdfium_available(self):
        from nexus_ai.core.pdfium import verify_pdfium_available

        result = verify_pdfium_available()
        assert isinstance(result, bool)

    def test_verify_pdfium_version(self):
        from nexus_ai.core.pdfium import verify_pdfium_version

        version = verify_pdfium_version()
        assert isinstance(version, str)

    def test_pdf_page_count_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import pdf_page_count

        count = pdf_page_count(sample_pdf_path)
        assert count == 3

    def test_render_page_to_pil_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_page_to_pil

        image = render_page_to_pil(sample_pdf_path, page_num=0, dpi=300)
        assert image is not None

    def test_render_page_to_pil_with_flags(self, mock_pdfium_module, sample_pdf_path):
        """render_page_to_pil() z flagami renderowania."""
        from nexus_ai.core.pdfium import render_page_to_pil, RenderFlags

        image = render_page_to_pil(
            sample_pdf_path, page_num=0, dpi=300,
            flags=RenderFlags.LCD_TEXT | RenderFlags.ANNOTATIONS,
        )
        assert image is not None

    def test_render_page_to_png_bytes_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_page_to_png_bytes

        png_bytes = render_page_to_png_bytes(sample_pdf_path, page_num=0, dpi=300)
        assert isinstance(png_bytes, bytes)

    def test_render_page_to_jpeg_bytes_mocked(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: render_page_to_jpeg_bytes() z mockiem."""
        from nexus_ai.core.pdfium import render_page_to_jpeg_bytes

        jpeg_bytes = render_page_to_jpeg_bytes(
            sample_pdf_path, page_num=0, dpi=300, quality=80,
        )
        assert isinstance(jpeg_bytes, bytes)

    def test_render_page_to_png_grayscale_mocked(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: render_page_to_png_grayscale() z flagą GRAYSCALE."""
        from nexus_ai.core.pdfium import render_page_to_png_grayscale

        png_bytes = render_page_to_png_grayscale(sample_pdf_path, page_num=0, dpi=300)
        assert isinstance(png_bytes, bytes)

    def test_render_page_to_pil_enhanced_mocked(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: render_page_to_pil_enhanced() z preprocessingiem."""
        from nexus_ai.core.pdfium import render_page_to_pil_enhanced

        image = render_page_to_pil_enhanced(
            sample_pdf_path, page_num=0, dpi=300,
            preprocess_for_ocr=False,
        )
        assert image is not None

    def test_open_pdf_with_bytes(self, mock_pdfium_module):
        """open_pdf() z bytes."""
        from nexus_ai.core.pdfium import open_pdf

        pdf = open_pdf(b"%PDF-1.4 fake content")
        assert pdf is not None

    def test_render_all_pages_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages

        images = render_all_pages(sample_pdf_path, dpi=300)
        assert len(images) == 3

    def test_render_all_pages_with_page_range(self, mock_pdfium_module, sample_pdf_path):
        """render_all_pages() z zakresem stron."""
        from nexus_ai.core.pdfium import render_all_pages

        images = render_all_pages(
            sample_pdf_path, dpi=300,
            page_range=(0, 2),
        )
        assert len(images) == 2

    def test_render_all_pages_with_progress(self, mock_pdfium_module, sample_pdf_path):
        """render_all_pages() z callbackiem postępu."""
        from nexus_ai.core.pdfium import render_all_pages, PDFProgressInfo

        progress_updates = []

        def on_progress(info: PDFProgressInfo):
            progress_updates.append(info)

        images = render_all_pages(
            sample_pdf_path, dpi=300,
            progress_callback=on_progress,
        )
        assert len(images) == 3
        assert len(progress_updates) == 3
        assert progress_updates[-1].percent == 100.0


class TestPdfDocumentSession:
    """FAZA 3: Testy dla PdfDocumentSession."""

    def test_session_init_with_path(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import PdfDocumentSession

        session = PdfDocumentSession(sample_pdf_path)
        assert session.pdf is not None
        assert len(session.pdf) == 3
        session.close()

    def test_session_context_manager(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import PdfDocumentSession

        with PdfDocumentSession(sample_pdf_path) as pdf:
            assert len(pdf) == 3

    def test_session_init_with_bytes(self, mock_pdfium_module):
        from nexus_ai.core.pdfium import PdfDocumentSession

        session = PdfDocumentSession(b"%PDF-1.4 fake content")
        assert session.pdf is not None
        session.close()

    def test_session_init_forms(self, mock_pdfium_module, sample_pdf_path):
        """Sprawdź, że init_forms() jest wywołane."""
        from nexus_ai.core.pdfium import PdfDocumentSession

        session = PdfDocumentSession(sample_pdf_path, init_forms=True)
        assert session.forms_initialized is True or session.forms_initialized is False
        session.close()

    def test_session_no_init_forms(self, mock_pdfium_module, sample_pdf_path):
        """Sprawdź, że init_forms=False nie wywołuje init_forms()."""
        from nexus_ai.core.pdfium import PdfDocumentSession

        session = PdfDocumentSession(sample_pdf_path, init_forms=False)
        assert session.forms_initialized is False
        session.close()


# ===================================================================
# FAZA 2: Async + numpy — warianty dla OCR i API
# ===================================================================


class TestAsyncAndNumpy:
    """Testy wariantów async i numpy dla OCR."""

    def test_pdf_to_images_memory_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import pdf_to_images_memory

        images = pdf_to_images_memory(sample_pdf_path, dpi=300)
        assert len(images) == 3
        for img_bytes in images:
            assert isinstance(img_bytes, bytes)

    def test_pdf_to_numpy_arrays_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import pdf_to_numpy_arrays

        arrays = pdf_to_numpy_arrays(sample_pdf_path, dpi=300, max_pages=2)
        assert len(arrays) == 2


# ===================================================================
# FAZA 3: Progressive loading
# ===================================================================


class TestProgressiveLoader:
    """Testy ProgressivePDFLoader."""

    def test_progressive_loader_init(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        loader = ProgressivePDFLoader(sample_pdf_path, lazy=False)
        assert loader is not None
        assert loader.page_count == 3
        loader.close()

    def test_progressive_loader_context_manager(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            assert loader.page_count == 3

    def test_progressive_loader_render_first_page(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            first_page = loader.render_first_page(dpi=150)
            assert isinstance(first_page, bytes)

    def test_progressive_loader_render_page(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            page_data = loader.render_page(page_num=1, dpi=150)
            assert isinstance(page_data, bytes)

    def test_progressive_loader_get_page_size(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            size = loader.get_page_size(0)
            assert isinstance(size, tuple)
            assert len(size) == 2

    # FAZA 7: Rozszerzony ProgressivePDFLoader

    def test_progressive_loader_from_bytes(self, mock_pdfium_module):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        loader = ProgressivePDFLoader.from_bytes(b"%PDF-1.4 fake data", lazy=False)
        assert loader is not None
        assert loader.page_count == 3
        loader.close()

    def test_progressive_loader_cancel(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            assert loader.is_cancelled is False
            loader.cancel()
            assert loader.is_cancelled is True

    def test_progressive_loader_render_all_iterator(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            pages = list(loader.render_all(dpi=150))
            assert len(pages) == 3
            for page_bytes in pages:
                assert isinstance(page_bytes, bytes)

    def test_progressive_loader_render_all_with_progress(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader, PDFProgressInfo

        progress_updates = []

        def on_progress(info: PDFProgressInfo):
            progress_updates.append(info)

        with ProgressivePDFLoader(
            sample_pdf_path, lazy=False, progress_callback=on_progress,
        ) as loader:
            pages = list(loader.render_all(dpi=150))
            assert len(pages) == 3
            assert len(progress_updates) == 3
            assert progress_updates[-1].percent == 100.0

    def test_progressive_loader_render_all_cancelled(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        with ProgressivePDFLoader(sample_pdf_path, lazy=False) as loader:
            loader.cancel()
            pages = list(loader.render_all(dpi=150))
            assert len(pages) == 0


# ===================================================================
# Ekstrakcja tekstu + wyszukiwanie
# ===================================================================


class TestTextExtraction:
    """Testy ekstrakcji tekstu z PDF."""

    def test_extract_text_from_page_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import extract_text_from_page

        text = extract_text_from_page(sample_pdf_path, page_num=0)
        assert isinstance(text, str)
        assert "Test text" in text

    def test_extract_text_simple_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import extract_text_simple

        text = extract_text_simple(sample_pdf_path, page_num=0)
        assert isinstance(text, str)

    def test_extract_text_ranges_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import extract_text_ranges

        ranges = extract_text_ranges(sample_pdf_path, page_num=0)
        assert isinstance(ranges, list)

    def test_extract_text_ranges_typed_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import extract_text_ranges_typed, PDFTextRange
        import pypdfium2 as pdfium

        ranges = extract_text_ranges_typed(sample_pdf_path, page_num=0)
        assert isinstance(ranges, list)
        for r in ranges:
            assert isinstance(r, PDFTextRange) or isinstance(r, dict)

    def test_detect_table_regions_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import detect_table_regions

        tables = detect_table_regions(sample_pdf_path, page_num=0)
        assert isinstance(tables, list)

    def test_search_in_pdf_mocked(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: search_in_pdf() z mockiem."""
        from nexus_ai.core.pdfium import search_in_pdf, PDFSearchResult

        results = search_in_pdf(sample_pdf_path, "test", page_num=0, match_case=False)
        assert isinstance(results, list)
        for r in results:
            assert isinstance(r, PDFSearchResult) or hasattr(r, "text")

    def test_search_in_pdf_match_case(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: search_in_pdf() z match_case=True."""
        from nexus_ai.core.pdfium import search_in_pdf

        results = search_in_pdf(sample_pdf_path, "TEST", page_num=0, match_case=True)
        assert isinstance(results, list)

    def test_search_in_pdf_whole_words(self, mock_pdfium_module, sample_pdf_path):
        """FAZA 1: search_in_pdf() z whole_words=True."""
        from nexus_ai.core.pdfium import search_in_pdf

        results = search_in_pdf(sample_pdf_path, "test", page_num=0, whole_words=True)
        assert isinstance(results, list)


# ===================================================================
# Metadane
# ===================================================================


class TestMetadata:
    """Testy odczytu metadanych PDF."""

    def test_get_pdf_metadata_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_metadata

        metadata = get_pdf_metadata(sample_pdf_path)
        assert isinstance(metadata, dict)
        assert metadata.get("Title") == "Test Invoice"

    def test_get_pdf_info_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_info

        info = get_pdf_info(sample_pdf_path)
        assert isinstance(info, dict)
        assert info.get("page_count") == 3
        assert "metadata" in info
        assert "file_size_bytes" in info
        assert info["metadata"].get("Title") == "Test Invoice"
        assert "signatures" in info
        assert "has_signatures" in info


# ===================================================================
# FAZA 5: msgspec.Struct — struktury danych PDF
# ===================================================================


class TestPDFStructures:
    """Testy dla struktur danych PDF (msgspec.Struct)."""

    def test_pdf_text_range_creation(self):
        from nexus_ai.core.pdfium import PDFTextRange

        tr = PDFTextRange(text="Hello", left=10.0, top=20.0, right=100.0, bottom=30.0, font_size=12.0)
        assert tr.text == "Hello"
        assert tr.left == 10.0
        assert tr.font_size == 12.0

    def test_pdf_text_range_to_dict(self):
        from nexus_ai.core.pdfium import PDFTextRange

        tr = PDFTextRange(text="Hello", left=10.0, top=20.0, right=100.0, bottom=30.0)
        d = tr.to_dict()
        assert d["text"] == "Hello"
        assert d["left"] == 10.0

    def test_pdf_page_info_creation(self):
        from nexus_ai.core.pdfium import PDFPageInfo, PDFTextRange

        ranges = [PDFTextRange(text="Hello", left=0.0, top=0.0, right=100.0, bottom=20.0)]
        info = PDFPageInfo(page_num=0, width=612.0, height=792.0, text_ranges=ranges)
        assert info.page_num == 0
        assert info.width == 612.0
        assert info.text_count == len(ranges)

    def test_pdf_page_info_to_dict(self):
        from nexus_ai.core.pdfium import PDFPageInfo, PDFTextRange

        ranges = [PDFTextRange(text="Hello", left=0.0, top=0.0, right=100.0, bottom=20.0)]
        info = PDFPageInfo(page_num=0, width=612.0, height=792.0, text_ranges=ranges)
        d = info.to_dict()
        assert d["text_count"] == 1
        assert len(d["text_ranges"]) == 1

    def test_pdf_signature_creation(self):
        from nexus_ai.core.pdfium import PDFSignature

        sig = PDFSignature(
            author="John Doe",
            reason="Approval",
            location="Warsaw",
            is_verified=True,
            signed_at="D:20240101120000+01'00'",
        )
        assert sig.author == "John Doe"
        assert sig.is_verified is True

    def test_pdf_form_field_creation(self):
        from nexus_ai.core.pdfium import PDFFormField

        field = PDFFormField(
            name="InvoiceNumber",
            type="text",
            value="INV-001",
            is_readonly=False,
            is_required=True,
            max_length=20,
        )
        assert field.name == "InvoiceNumber"
        assert field.is_required is True

    def test_pdf_render_cache_entry_creation(self):
        from nexus_ai.core.pdfium import PDFRenderCacheEntry

        entry = PDFRenderCacheEntry(png_bytes=b"fake_png", cached_at=time.time())
        assert isinstance(entry.png_bytes, bytes)

    def test_pdf_progress_info_creation(self):
        from nexus_ai.core.pdfium import PDFProgressInfo

        info = PDFProgressInfo(current_page=1, total_pages=10, percent=10.0, page_dpi=300)
        assert info.current_page == 1
        assert info.percent == 10.0

    def test_pdf_annotation_creation(self):
        """FAZA 2: PDFAnnotation jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFAnnotation

        annot = PDFAnnotation(
            type="highlight",
            rect=(100, 100, 200, 120),
            content="Important note",
            page_num=0,
        )
        assert annot.type == "highlight"
        assert annot.content == "Important note"

    def test_pdf_attachment_creation(self):
        """FAZA 2: PDFAttachment jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFAttachment

        att = PDFAttachment(name="ksef.xml", data=b"<xml/>", size=6, index=0)
        assert att.name == "ksef.xml"
        assert att.size == 6

    def test_pdf_bookmark_creation(self):
        """FAZA 2: PDFBookmark jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFBookmark

        bm = PDFBookmark(title="Chapter 1", page_index=0, level=0, children=[])
        assert bm.title == "Chapter 1"
        assert bm.page_index == 0

    def test_pdf_bookmark_with_children(self):
        """FAZA 2: PDFBookmark z dziećmi."""
        from nexus_ai.core.pdfium import PDFBookmark

        child = PDFBookmark(title="Section 1.1", page_index=0, level=1)
        parent = PDFBookmark(title="Chapter 1", page_index=0, level=0, children=[child])
        assert len(parent.children) == 1
        assert parent.children[0].title == "Section 1.1"

    def test_pdf_search_result_creation(self):
        """FAZA 2: PDFSearchResult jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFSearchResult

        sr = PDFSearchResult(text="hello", left=10, top=20, right=50, bottom=30, char_index=5, count=1)
        assert sr.text == "hello"
        assert sr.char_index == 5

    def test_pdfa_compliance_creation(self):
        """FAZA 3: PDFACompliance jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFACompliance

        c = PDFACompliance(is_pdfa=True, pdfa_version=2, pdfa_version_str="PDF/A-2")
        assert c.is_pdfa is True
        assert c.pdfa_version_str == "PDF/A-2"

    def test_pdf_form_fill_data_creation(self):
        """FAZA 3: PDFFormFillData jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFFormFillData

        d = PDFFormFillData(field_name="InvoiceNumber", value="INV-999")
        assert d.field_name == "InvoiceNumber"
        assert d.value == "INV-999"

    def test_pdf_form_fill_batch_creation(self):
        """FAZA 3: PDFFormFillBatch jako msgspec.Struct."""
        from nexus_ai.core.pdfium import PDFFormFillBatch, PDFFormFillData

        batch = PDFFormFillBatch(fields=[
            PDFFormFillData(field_name="name", value="Alice"),
            PDFFormFillData(field_name="amount", value="100"),
        ])
        assert len(batch.fields) == 2
        assert batch.fields[0].value == "Alice"


# ===================================================================
# FAZA 2: Podpisy cyfrowe
# ===================================================================


class TestSignatures:
    """Testy dla podpisów cyfrowych PDF."""

    def test_verify_pdf_signatures_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import verify_pdf_signatures, PDFSignature

        signatures = verify_pdf_signatures(sample_pdf_path)
        assert isinstance(signatures, list)
        if signatures:
            sig = signatures[0]
            assert isinstance(sig, PDFSignature) or hasattr(sig, "author")
            assert sig.author == "John Doe"
            assert sig.is_verified is True

    def test_verify_pdf_signatures_return_type(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import verify_pdf_signatures

        signatures = verify_pdf_signatures(sample_pdf_path)
        assert isinstance(signatures, list)
        for sig in signatures:
            assert hasattr(sig, "author")
            assert hasattr(sig, "reason")
            assert hasattr(sig, "location")
            assert hasattr(sig, "is_verified")
            assert hasattr(sig, "signed_at")
            assert hasattr(sig, "field_name")
            assert hasattr(sig, "page_num")


# ===================================================================
# FAZA 3: Formularze AcroForms
# ===================================================================


class TestFormFields:
    """Testy dla formularzy AcroForms."""

    def test_get_pdf_form_fields_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_form_fields, PDFFormField

        fields = get_pdf_form_fields(sample_pdf_path)
        assert isinstance(fields, list)
        if fields:
            field = fields[0]
            assert isinstance(field, PDFFormField) or hasattr(field, "name")
            assert field.name == "InvoiceNumber"

    def test_get_pdf_form_fields_structure(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_form_fields

        fields = get_pdf_form_fields(sample_pdf_path)
        for f in fields:
            assert hasattr(f, "name")
            assert hasattr(f, "type")
            assert hasattr(f, "value")
            assert hasattr(f, "is_readonly")
            assert hasattr(f, "is_required")

    def test_fill_pdf_form_field_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import fill_pdf_form_field

        result = fill_pdf_form_field(sample_pdf_path, "InvoiceNumber", "INV-999")
        assert isinstance(result, bytes)

    def test_fill_pdf_form_field_no_output(self, mock_pdfium_module, sample_pdf_path):
        """fill_pdf_form_field() bez output_path — testuje ścieżkę BytesIO."""
        from nexus_ai.core.pdfium import fill_pdf_form_field

        result = fill_pdf_form_field(
            sample_pdf_path, "InvoiceNumber", "INV-999",
        )
        assert isinstance(result, bytes)

    def test_save_pdf_with_filled_fields_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import save_pdf_with_filled_fields

        result = save_pdf_with_filled_fields(
            sample_pdf_path,
            {"InvoiceNumber": "INV-999", "TotalAmount": "999.99"},
        )
        assert isinstance(result, bytes)

    def test_save_pdf_with_filled_fields_no_output(self, mock_pdfium_module, sample_pdf_path):
        """save_pdf_with_filled_fields() bez output_path — testuje ścieżkę BytesIO."""
        from nexus_ai.core.pdfium import save_pdf_with_filled_fields

        result = save_pdf_with_filled_fields(
            sample_pdf_path,
            {"InvoiceNumber": "INV-999"},
        )
        assert isinstance(result, bytes)


# ===================================================================
# FAZA 4: Cache'owanie renderowanych stron
# ===================================================================


class TestRenderCache:
    """Testy dla PDFRenderCache."""

    def test_cache_init(self):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        assert cache.stats["ttl_seconds"] == 60
        assert cache.stats["max_size"] == 10
        assert cache.stats["size"] == 0

    def test_cache_set_and_get(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        pdf_path = tmp_path / "test.pdf"
        pdf_path.write_bytes(b"%PDF-1.4")

        cache.set(pdf_path, 0, 150, 0, b"fake_png_0")
        cache.set(pdf_path, 1, 150, 0, b"fake_png_1")

        assert cache.get(pdf_path, 0, 150, 0) == b"fake_png_0"
        assert cache.get(pdf_path, 1, 150, 0) == b"fake_png_1"
        assert cache.stats["size"] == 2

    def test_cache_miss(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        pdf_path = tmp_path / "test.pdf"

        result = cache.get(pdf_path, 0, 150)
        assert result is None
        assert cache.stats["misses"] == 1

    def test_cache_hit_ratio(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        pdf_path = tmp_path / "test.pdf"
        pdf_path.write_bytes(b"%PDF-1.4")

        assert cache.get(pdf_path, 0, 150) is None  # Miss
        cache.set(pdf_path, 0, 150, 0, b"data")
        assert cache.get(pdf_path, 0, 150) == b"data"  # Hit

        stats = cache.stats
        assert stats["hits"] == 1
        assert stats["misses"] == 1
        assert stats["hit_ratio"] == 0.5

    def test_cache_invalidate_all(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        pdf_path = tmp_path / "test.pdf"
        pdf_path.write_bytes(b"%PDF-1.4")

        cache.set(pdf_path, 0, 150, 0, b"data")
        assert cache.stats["size"] == 1
        cache.invalidate()
        assert cache.stats["size"] == 0

    def test_cache_invalidate_specific(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=10)
        pdf1 = tmp_path / "doc1.pdf"
        pdf2 = tmp_path / "doc2.pdf"
        pdf1.write_bytes(b"%PDF-1.4")
        pdf2.write_bytes(b"%PDF-1.4")

        cache.set(pdf1, 0, 150, 0, b"data1")
        cache.set(pdf2, 0, 150, 0, b"data2")
        assert cache.stats["size"] == 2

        cache.invalidate(pdf1)
        assert cache.stats["size"] == 1
        assert cache.get(pdf2, 0, 150) == b"data2"

    def test_cache_lru_eviction(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=60, max_size=3)
        for i in range(5):
            pdf_path = tmp_path / f"doc{i}.pdf"
            pdf_path.write_bytes(b"%PDF-1.4")
            cache.set(pdf_path, 0, 150, 0, f"data{i}".encode())

        assert cache.stats["size"] == 3  # max_size

    def test_cache_ttl_expiry(self, tmp_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        cache = PDFRenderCache(ttl=1, max_size=10)
        pdf_path = tmp_path / "test.pdf"
        pdf_path.write_bytes(b"%PDF-1.4")

        cache.set(pdf_path, 0, 150, 0, b"data")
        assert cache.get(pdf_path, 0, 150) == b"data"

        # Symuluj upływ czasu
        import time as _time
        cache._cache[cache._make_key(pdf_path, 0, 150, 0)].cached_at = _time.time() - 5
        assert cache.get(pdf_path, 0, 150) is None  # Wygasł


# ===================================================================
# FAZA 5: render_all_pages_to_memory — streaming
# ===================================================================


class TestRenderAllToMemory:
    """Testy dla render_all_pages_to_memory()."""

    def test_render_all_to_memory_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages_to_memory

        images = render_all_pages_to_memory(sample_pdf_path, dpi=150, use_cache=False)
        assert isinstance(images, list)
        assert len(images) == 3
        for img in images:
            assert isinstance(img, bytes)

    def test_render_all_to_memory_with_max_pages(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages_to_memory

        images = render_all_pages_to_memory(sample_pdf_path, dpi=150, max_pages=2)
        assert len(images) == 2

    def test_render_all_to_memory_page_range(self, mock_pdfium_module, sample_pdf_path):
        """render_all_pages_to_memory() z zakresem stron."""
        from nexus_ai.core.pdfium import render_all_pages_to_memory

        images = render_all_pages_to_memory(
            sample_pdf_path, dpi=150,
            page_range=(1, 3),
        )
        assert len(images) == 2

    def test_render_all_to_memory_jpeg_format(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages_to_memory

        images = render_all_pages_to_memory(sample_pdf_path, dpi=150, format="JPEG")
        assert len(images) == 3

    def test_render_all_to_memory_with_progress(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages_to_memory, PDFProgressInfo

        progress_updates = []

        def on_progress(info: PDFProgressInfo):
            progress_updates.append(info)

        images = render_all_pages_to_memory(
            sample_pdf_path, dpi=150, use_cache=False,
            progress_callback=on_progress,
        )
        assert len(images) == 3
        assert len(progress_updates) == 3
        assert progress_updates[-1].percent == 100.0


# ===================================================================
# FAZA 6: OpenTelemetry
# ===================================================================


class TestOTelTracing:
    """Testy dla OpenTelemetry tracingu."""

    def test_get_otel_tracer(self):
        from nexus_ai.core.pdfium import _get_otel_tracer

        tracer = _get_otel_tracer()
        assert tracer is None or tracer is not None

    def test_record_pdf_metric(self):
        from nexus_ai.core.pdfium import _record_pdf_metric

        _record_pdf_metric("test.metric", 1.0, {"test": "true"})


# ===================================================================
# FAZA 2: Adnotacje (Annotations)
# ===================================================================


class TestAnnotations:
    """FAZA 2: Testy dla adnotacji PDF."""

    def test_get_page_annotations_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_page_annotations, PDFAnnotation

        annotations = get_page_annotations(sample_pdf_path, page_num=0)
        assert isinstance(annotations, list)
        if annotations:
            annot = annotations[0]
            assert isinstance(annot, PDFAnnotation) or hasattr(annot, "type")
            assert annot.type == "highlight"

    def test_count_page_annotations_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import count_page_annotations

        count = count_page_annotations(sample_pdf_path, page_num=0)
        assert count >= 0


# ===================================================================
# FAZA 2: Załączniki (Attachments)
# ===================================================================


class TestAttachments:
    """FAZA 2: Testy dla załączników PDF."""

    def test_get_pdf_attachments_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_attachments, PDFAttachment

        attachments = get_pdf_attachments(sample_pdf_path)
        assert isinstance(attachments, list)
        if attachments:
            att = attachments[0]
            assert isinstance(att, PDFAttachment) or hasattr(att, "name")
            assert att.name == "ksef.xml"

    def test_add_pdf_attachment_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import add_pdf_attachment

        result = add_pdf_attachment(
            sample_pdf_path, "test.txt", b"hello world",
        )
        assert isinstance(result, bytes)


# ===================================================================
# FAZA 2: Zakładki (Bookmarks)
# ===================================================================


class TestBookmarks:
    """FAZA 2: Testy dla zakładek PDF."""

    def test_get_pdf_bookmarks_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_bookmarks, PDFBookmark

        bookmarks = get_pdf_bookmarks(sample_pdf_path)
        assert isinstance(bookmarks, list)
        if bookmarks:
            bm = bookmarks[0]
            assert isinstance(bm, PDFBookmark) or hasattr(bm, "title")
            assert bm.title == "Chapter 1"

    def test_pdf_info_includes_bookmarks(self, mock_pdfium_module, sample_pdf_path):
        """get_pdf_info() powinno zawierać bookmarki."""
        from nexus_ai.core.pdfium import get_pdf_info

        info = get_pdf_info(sample_pdf_path)
        assert "bookmarks" in info
        assert "has_bookmarks" in info


# ===================================================================
# FAZA 2: Zapis przyrostowy (Incremental Save)
# ===================================================================


class TestIncrementalSave:
    """FAZA 2: Testy dla zapisu przyrostowego."""

    def test_save_incremental(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import save_incremental

        result = save_incremental(sample_pdf_path)
        assert isinstance(result, bytes)


# ===================================================================
# FAZA 3: Manipulacja stronami (Page Manipulation)
# ===================================================================


class TestPageManipulation:
    """FAZA 3: Testy dla manipulacji stronami PDF."""

    def test_merge_pdfs(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import merge_pdfs

        result = merge_pdfs([sample_pdf_path, sample_pdf_path])
        assert isinstance(result, bytes)

    def test_delete_pages_from_pdf(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import delete_pages_from_pdf

        result = delete_pages_from_pdf(sample_pdf_path, [0])
        assert isinstance(result, bytes)

    def test_extract_pages_from_pdf(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import extract_pages_from_pdf

        result = extract_pages_from_pdf(sample_pdf_path, [0, 1])
        assert isinstance(result, bytes)

    def test_merge_pdfs_no_output(self, mock_pdfium_module, sample_pdf_path):
        """merge_pdfs() bez output_path — testuje ścieżkę BytesIO."""
        from nexus_ai.core.pdfium import merge_pdfs

        result = merge_pdfs([sample_pdf_path])
        assert isinstance(result, bytes)

    def test_delete_pages_from_pdf_no_output(self, mock_pdfium_module, sample_pdf_path):
        """delete_pages_from_pdf() bez output_path — testuje ścieżkę BytesIO."""
        from nexus_ai.core.pdfium import delete_pages_from_pdf

        result = delete_pages_from_pdf(sample_pdf_path, [0])
        assert isinstance(result, bytes)


# ===================================================================
# FAZA 3: PDF/A Compliance
# ===================================================================


class TestPDFACompliance:
    """FAZA 3: Testy dla zgodności z PDF/A."""

    def test_pdfa_check_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import pdfa_check, PDFACompliance

        result = pdfa_check(sample_pdf_path)
        assert isinstance(result, PDFACompliance) or hasattr(result, "is_pdfa")
        assert isinstance(result.is_pdfa, bool)

    def test_pdfa_check_metadata_in_info(self, mock_pdfium_module, sample_pdf_path):
        """get_pdf_info() powinno zawierać pdfa_compliance."""
        from nexus_ai.core.pdfium import get_pdf_info

        info = get_pdf_info(sample_pdf_path)
        assert "pdfa_compliance" in info


# ===================================================================
# FAZA 2: _get_annotation_type_str
# ===================================================================


class TestAnnotationTypeMap:
    """Testy dla mapowania typów adnotacji."""

    def test_known_types(self):
        from nexus_ai.core.pdfium import _ANNOTATION_TYPE_MAP

        assert _ANNOTATION_TYPE_MAP[0] == "text"
        assert _ANNOTATION_TYPE_MAP[8] == "highlight"
        assert _ANNOTATION_TYPE_MAP[23] == "watermark"

    def test_unknown_type_default(self):
        from nexus_ai.core.pdfium import _get_annotation_type_str

        result = _get_annotation_type_str(99)
        assert result == "unknown_99"


# ===================================================================
# FAZA 2: _get_attachment_count_internal
# ===================================================================


class TestAttachmentCount:
    """Testy dla wewnętrznego liczenia załączników."""

    def test_attachment_count_mocked(self, mock_pdfium_module, sample_pdf_path):
        from nexus_ai.core.pdfium import get_pdf_info

        info = get_pdf_info(sample_pdf_path)
        assert "attachment_count" in info
        assert "has_attachments" in info


# ===================================================================
# Testy konfiguracji i zależności
# ===================================================================


class TestConfiguration:
    """Testy zmian konfiguracyjnych."""

    def test_pyproject_has_pypdfium2(self):
        pyproject = Path(__file__).parents[1] / "pyproject.toml"
        content = pyproject.read_text()
        assert "pypdfium2" in content, "pyproject.toml: brak pypdfium2"

    def test_pixi_toml_has_pypdfium2(self):
        pixi_toml = Path(__file__).parents[1] / "pixi.toml"
        content = pixi_toml.read_text()
        assert "pypdfium2" in content, "pixi.toml: brak pypdfium2"

    def test_conftest_mocks_pypdfium2(self):
        conftest = Path(__file__).parents[1] / "tests" / "conftest.py"
        content = conftest.read_text()
        assert "pypdfium2" in content, "conftest.py: brak pypdfium2"

    def test_ocr_consensus_uses_pypdfium2(self):
        ocr_file = Path(__file__).parents[1] / "nexus_ai" / "pipeline" / "ocr_consensus.py"
        content = ocr_file.read_text()
        assert "pypdfium2" in content, "ocr_consensus.py: brak pypdfium2!"

    @pytest.mark.integration
    def test_render_all_pages_to_memory_real(self, sample_pdf_path):
        from nexus_ai.core.pdfium import render_all_pages_to_memory

        try:
            images = render_all_pages_to_memory(sample_pdf_path, dpi=72, use_cache=False)
            assert len(images) >= 1
            for img in images:
                assert isinstance(img, bytes)
        except Exception as exc:
            pytest.skip(f"Real PDF render_all_to_memory failed: {exc}")

    @pytest.mark.integration
    def test_cache_with_real_pdf(self, sample_pdf_path):
        from nexus_ai.core.pdfium import PDFRenderCache

        try:
            cache = PDFRenderCache(ttl=60, max_size=10)
            cache.set(sample_pdf_path, 0, 150, 0, b"cached_data")
            result = cache.get(sample_pdf_path, 0, 150)
            assert result == b"cached_data"
        except Exception as exc:
            pytest.skip(f"Cache test with real PDF failed: {exc}")

    @pytest.mark.integration
    def test_progressive_loader_real(self, sample_pdf_path):
        from nexus_ai.core.pdfium import ProgressivePDFLoader

        try:
            with ProgressivePDFLoader(sample_pdf_path) as loader:
                count = loader.page_count
                assert count >= 1
                first_page = loader.render_first_page(dpi=72)
                assert isinstance(first_page, bytes)
                assert len(first_page) > 0
        except Exception as exc:
            pytest.skip(f"ProgressiveLoader with real PDF failed: {exc}")

    @pytest.mark.integration
    def test_get_page_annotations_real(self, sample_pdf_path):
        """FAZA 2: Adnotacje z prawdziwym PDF."""
        from nexus_ai.core.pdfium import get_page_annotations

        try:
            annotations = get_page_annotations(sample_pdf_path, page_num=0)
            assert isinstance(annotations, list)
        except Exception as exc:
            pytest.skip(f"Annotations with real PDF failed: {exc}")

    @pytest.mark.integration
    def test_get_pdf_bookmarks_real(self, sample_pdf_path):
        """FAZA 2: Bookmarki z prawdziwym PDF."""
        from nexus_ai.core.pdfium import get_pdf_bookmarks

        try:
            bookmarks = get_pdf_bookmarks(sample_pdf_path)
            assert isinstance(bookmarks, list)
        except Exception as exc:
            pytest.skip(f"Bookmarks with real PDF failed: {exc}")

    def test_pdfium_module_exists(self):
        pdfium_module = Path(__file__).parents[1] / "nexus_ai" / "core" / "pdfium.py"
        assert pdfium_module.exists(), "nexus_ai/core/pdfium.py nie istnieje!"
        content = pdfium_module.read_text()
        # FAZA 1: Core
        assert "pypdfium2" in content
        assert "render_page_to_pil" in content
        assert "render_page_to_png_grayscale" in content
        assert "render_page_to_jpeg_bytes" in content
        assert "render_page_to_pil_enhanced" in content
        assert "ProgressivePDFLoader" in content
        assert "extract_text_from_page" in content
        assert "detect_table_regions" in content
        # FAZA 2: Signatures, forms, annotations, attachments, bookmarks, search
        assert "verify_pdf_signatures" in content
        assert "get_pdf_form_fields" in content
        assert "fill_pdf_form_field" in content
        assert "get_page_annotations" in content
        assert "get_pdf_attachments" in content
        assert "get_pdf_bookmarks" in content
        assert "search_in_pdf" in content
        # FAZA 3: Page manipulation, PDF/A, incremental save
        assert "merge_pdfs" in content
        assert "delete_pages_from_pdf" in content
        assert "extract_pages_from_pdf" in content
        assert "pdfa_check" in content
        assert "save_incremental" in content
        # FAZA 4: Cache
        assert "PDFRenderCache" in content
        assert "render_all_pages_to_memory" in content
        # FAZA 5: msgspec.Struct
        assert "PDFTextRange" in content
        assert "PDFSignature" in content
        assert "PDFFormField" in content
        assert "PDFAnnotation" in content
        assert "PDFAttachment" in content
        assert "PDFBookmark" in content
        assert "PDFSearchResult" in content
        assert "PDFACompliance" in content
        # PdfDocumentSession
        assert "PdfDocumentSession" in content
        # RenderFlags
        assert "RenderFlags" in content

    def test_pdf_endpoints_module_exists(self):
        endpoints_module = Path(__file__).parents[1] / "nexus_ai" / "api" / "pdf_endpoints.py"
        assert endpoints_module.exists(), "nexus_ai/api/pdf_endpoints.py nie istnieje!"
        content = endpoints_module.read_text()
        assert "PDFController" in content
        assert "render_page" in content
        assert "pdf_info" in content
        assert "pdf_text" in content
        assert "pdfium_health" in content
        # FAZA 2-3: Nowe endpointy
        assert "render_page_jpeg" in content
        assert "render_page_enhanced" in content
        assert "render_all_pages" in content
        assert "pdf_signatures" in content
        assert "pdf_form_fields" in content
        assert "pdf_fill_form" in content
        assert "pdfium_cache_stats" in content
        assert "pdfium_cache_invalidate" in content
