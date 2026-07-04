"""
pdf_endpoints.py -- Endpointy Litestar do renderowania i ekstrakcji PDF przez PDFium.

Zgodnie z audytem technologicznym:
- Renderowanie stron PDF do PNG/JPEG na żądanie -- zero zapisu na dysk
- Streaming response przez Litestar + Granian
- Ekstrakcja tekstu i metadanych
- Integracja z msgspec dla szybkiej serializacji
- Wszystkie operacje CPU-bound przez anyio.to_thread.run_sync()

FAZA 5 (nowe endpointy):
  GET /api/v1/documents/{id}/pages/render-all -- streaming wszystkich stron
  GET /api/v1/documents/{id}/signatures -- podpisy cyfrowe
  GET /api/v1/documents/{id}/form-fields -- pola formularza
  POST /api/v1/documents/{id}/form-fields/fill -- wypełnianie formularza
  GET /api/v1/documents/{id}/pages/{num}/render-enhanced -- z preprocessingiem Pillow
  GET /api/v1/documents/{id}/pages/{num}/render-jpeg -- jako JPEG
  GET /api/v1/health/pdfium/cache -- statystyki cache'a

Wszystkie endpointy są dostępne pod:
  GET /api/v1/documents/{document_id}/pages/{page_num}/render
  GET /api/v1/documents/{document_id}/info
  GET /api/v1/documents/{document_id}/pages/{page_num}/text
  GET /api/v1/documents/{document_id}/pages/{page_num}/tables
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import anyio
import msgspec
from litestar import Controller, get, post
from litestar.response import Response
from structlog import get_logger

from nexus_ai.services.pdfium import (
    detect_table_regions,
    extract_text_from_page,
    extract_text_ranges,
    get_pdf_form_fields,
    get_pdf_info,
    get_pdf_render_cache,
    render_all_pages_to_memory,
    render_page_to_jpeg_bytes,
    render_page_to_pil_enhanced,
    render_page_to_png_bytes,
    save_pdf_with_filled_fields,
    verify_pdf_signatures,
)

logger = get_logger("nexus.api.pdf")


def _resolve_document_path(document_id: str) -> Path:
    """Rozwiąż document_id na ścieżkę pliku PDF.

    TODO: Zintegruj z ContentAddressableStorage dla prawdziwych dokumentów.
    Obecnie zakładamy, że document_id to nazwa pliku w app_data/invoices/.
    """
    base = Path("app_data/invoices")
    base.mkdir(parents=True, exist_ok=True)

    # Sprawdź czy to pełna ścieżka
    candidate = Path(document_id)
    if candidate.exists() and candidate.suffix.lower() == ".pdf":
        return candidate

    # Szukaj w katalogu invoices
    pdf_path = base / f"{document_id}.pdf"
    if pdf_path.exists():
        return pdf_path

    # Szukaj w katalogu uploads
    upload_path = Path("app_data/uploads") / f"{document_id}.pdf"
    if upload_path.exists():
        return upload_path

    raise FileNotFoundError(f"Document not found: {document_id}")


class PDFController(Controller):
    """Kontroler API dla operacji na PDF-ach przez silnik PDFium.

    Wszystkie endpointy używają anyio.to_thread.run_sync() do oddelegowania
    CPU-bound operacji PDFium do wątku roboczego, nie blokując pętli zdarzeń.
    """

    tags = ("pdf",)

    # ═══════════════════════════════════════════════════════════════════════
    # Renderowanie strony do PNG (podstawowe)
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/{page_num:int}/render",
        summary="Render PDF page to image",
        description="Render a single PDF page to PNG image using PDFium engine",
        media_type="image/png",
    )
    async def render_page(
        self,
        document_id: str,
        page_num: int,
        dpi: int = 150,
        rotation: int = 0,
    ) -> Response:
        """Renderuj stronę PDF do obrazu PNG.

        - Renderowanie przez silnik Chrome -- najwyższa jakość
        - Streaming response -- zero zapisu na dysk
        - Cache przez Cache-Control: public
        - Obsługa rotacji i DPI
        - Automatyczne cache'owanie z TTL (FAZA 4)

        Args:
            document_id: ID dokumentu lub ścieżka.
            page_num: Numer strony (0-indexed).
            dpi: Rozdzielczość (domyślnie 150 dla szybkiego preview).
            rotation: Rotacja w stopniach (0, 90, 180, 270).

        Returns:
            Response z PNG image.
        """
        pdf_path = _resolve_document_path(document_id)

        png_bytes = await anyio.to_thread.run_sync(
            render_page_to_png_bytes,
            pdf_path,
            page_num,
            dpi,
            rotation,
        )

        return Response(
            content=png_bytes,
            media_type="image/png",
            headers={
                "Cache-Control": "public, max-age=86400",
                "X-PDF-Engine": "PDFium",
                "X-Page-Num": str(page_num),
                "X-DPI": str(dpi),
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Renderowanie strony do JPEG (mniejszy rozmiar)
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/{page_num:int}/render-jpeg",
        summary="Render PDF page to JPEG image",
        description="Render a single PDF page to JPEG image (smaller file size)",
        media_type="image/jpeg",
    )
    async def render_page_jpeg(
        self,
        document_id: str,
        page_num: int,
        dpi: int = 150,
        rotation: int = 0,
        quality: int = 85,
    ) -> Response:
        """Render PDF page to JPEG image.

        - JPEG z progressive=True dla lepszego UX w przeglądarce
        - Mniejszy rozmiar niż PNG (idealne dla fotografii i skanów)
        - EXIF transpose dla PDF z embedded rotation

        Args:
            document_id: ID dokumentu.
            page_num: Numer strony.
            dpi: Rozdzielczość.
            rotation: Rotacja.
            quality: Jakość JPEG (0-100, domyślnie 85).

        Returns:
            Response z JPEG image.
        """
        pdf_path = _resolve_document_path(document_id)

        jpeg_bytes = await anyio.to_thread.run_sync(
            render_page_to_jpeg_bytes,
            pdf_path,
            page_num,
            dpi,
            rotation,
            quality=quality,
        )

        return Response(
            content=jpeg_bytes,
            media_type="image/jpeg",
            headers={
                "Cache-Control": "public, max-age=86400",
                "X-PDF-Engine": "PDFium",
                "X-Page-Num": str(page_num),
                "X-DPI": str(dpi),
                "X-Format": "JPEG",
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Renderowanie strony z preprocessingiem Pillow dla OCR
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/{page_num:int}/render-enhanced",
        summary="Render PDF page with Pillow preprocessing",
        description="Render PDF page with contrast enhancement, sharpening, and denoising for OCR",
        media_type="image/png",
    )
    async def render_page_enhanced(
        self,
        document_id: str,
        page_num: int,
        dpi: int = 300,
        rotation: int = 0,
    ) -> Response:
        """Render PDF page with Pillow preprocessing.

        - ImageOps.autocontrast -- automatyczne zwiększenie kontrastu
        - ImageFilter.MedianFilter -- denoising (szumy skanera)
        - ImageFilter.UnsharpMask -- wyostrzenie krawędzi znaków
        - EXIF transpose -- korekcja orientacji
        - Idealne dla OCR -- obraz gotowy do Tesseract/PaddleOCR

        Args:
            document_id: ID dokumentu.
            page_num: Numer strony.
            dpi: Rozdzielczość (domyślnie 300 dla OCR).
            rotation: Rotacja.

        Returns:
            Response z preprocessowanym PNG.
        """
        pdf_path = _resolve_document_path(document_id)

        pil_image = await anyio.to_thread.run_sync(
            render_page_to_pil_enhanced,
            pdf_path,
            page_num,
            dpi,
            rotation,
            preprocess_for_ocr=True,
        )

        import io

        buf = io.BytesIO()
        pil_image.save(buf, format="PNG", optimize=True)

        return Response(
            content=buf.getvalue(),
            media_type="image/png",
            headers={
                "Cache-Control": "public, max-age=86400",
                "X-PDF-Engine": "PDFium",
                "X-Page-Num": str(page_num),
                "X-DPI": str(dpi),
                "X-Enhanced": "true",
                "X-Preprocess": "autocontrast+median+unsharp",
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Streaming wszystkich stron jako PNG
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/render-all",
        summary="Render all pages as PNG images",
        description="Render all pages of a PDF as PNG images (returns JSON array of base64 images)",
    )
    async def render_all_pages(
        self,
        document_id: str,
        dpi: int = 150,
        max_pages: int | None = None,
        format: str = "PNG",
    ) -> Response:
        """Render all pages as PNG images.

        - Renderowanie wszystkich stron jednym wywołaniem
        - Cache'owanie z TTL -- powtórne wywołanie jest błyskawiczne
        - Zwraca JSON z base64-encoded obrazami
        - Idealne dla batch OCR i generowania miniaturek

        Args:
            document_id: ID dokumentu.
            dpi: Rozdzielczość.
            max_pages: Maksymalna liczba stron (None = wszystkie).
            format: Format obrazu ("PNG" lub "JPEG").

        Returns:
            JSON z listą obrazów.
        """
        pdf_path = _resolve_document_path(document_id)

        images = await anyio.to_thread.run_sync(
            render_all_pages_to_memory,
            pdf_path,
            dpi,
            0,
            max_pages=max_pages,
            format=format,
        )

        import base64

        result = {
            "document_id": document_id,
            "page_count": len(images),
            "dpi": dpi,
            "format": format,
            "pages": [
                {
                    "page_num": i,
                    "image_base64": base64.b64encode(img_bytes).decode("ascii"),
                    "size_bytes": len(img_bytes),
                }
                for i, img_bytes in enumerate(images)
            ],
        }

        return Response(
            content=msgspec.json.encode(result),
            media_type="application/json",
            headers={
                "X-PDF-Engine": "PDFium",
                "X-Page-Count": str(len(images)),
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Informacje o dokumencie (z sygnaturami)
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/info",
        summary="Get PDF document info",
        description="Get metadata, page count, file info, and signatures for a PDF document",
    )
    async def pdf_info(
        self,
        document_id: str,
    ) -> Response:
        """Pobierz metadane i informacje o dokumencie PDF.

        - Jedno wywołanie PDFium zwraca wszystko
        - Serializacja przez msgspec (10-100x szybciej niż json)
        - Zwraca: page_count, file_size, metadata, first_page_size, signatures

        Returns:
            JSON z pełną informacją o dokumencie.
        """
        pdf_path = _resolve_document_path(document_id)

        info = await anyio.to_thread.run_sync(get_pdf_info, pdf_path)

        return Response(
            content=msgspec.json.encode(info),
            media_type="application/json",
            headers={
                "X-PDF-Engine": "PDFium",
                "X-Page-Count": str(info["page_count"]),
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Ekstrakcja tekstu
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/{page_num:int}/text",
        summary="Extract text from PDF page",
        description="Extract text with layout from a single PDF page",
    )
    async def pdf_text(
        self,
        document_id: str,
        page_num: int = 0,
        with_positions: bool = False,
    ) -> Response:
        """Ekstrahuj tekst ze strony PDF.

        Args:
            document_id: ID dokumentu.
            page_num: Numer strony (0-indexed).
            with_positions: Jeśli True, zwraca tekst z pozycjami (bounding boxy).

        Returns:
            JSON z tekstem (lub tekstem z pozycjami).
        """
        pdf_path = _resolve_document_path(document_id)

        if with_positions:
            ranges = await anyio.to_thread.run_sync(
                extract_text_ranges,
                pdf_path,
                page_num,
            )
            return Response(
                content=msgspec.json.encode(
                    {
                        "page": page_num,
                        "text_ranges": ranges,
                        "engine": "PDFium",
                    }
                ),
                media_type="application/json",
            )

        text = await anyio.to_thread.run_sync(
            extract_text_from_page,
            pdf_path,
            page_num,
        )
        return Response(
            content=msgspec.json.encode(
                {
                    "page": page_num,
                    "text": text,
                    "engine": "PDFium",
                }
            ),
            media_type="application/json",
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Detekcja tabel
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/pages/{page_num:int}/tables",
        summary="Detect tables in PDF page",
        description="Detect table regions using bounding box analysis",
    )
    async def pdf_tables(
        self,
        document_id: str,
        page_num: int = 0,
    ) -> Response:
        """Wykrywaj tabele w stronie PDF przez analizę bounding boxów.

        - Szybsze niż OCR (ms vs sekundy)
        - Analizuje struktury kolumn bez zewnętrznych modeli
        - PDFium daje precyzyjne pozycje tekstu
        """
        pdf_path = _resolve_document_path(document_id)

        tables = await anyio.to_thread.run_sync(
            detect_table_regions,
            pdf_path,
            page_num,
        )

        return Response(
            content=msgspec.json.encode(
                {
                    "page": page_num,
                    "tables": tables,
                    "table_count": len(tables),
                    "engine": "PDFium",
                }
            ),
            media_type="application/json",
        )

    # ═══════════════════════════════════════════════════════════════════════
    # FAZA 2: Podpisy cyfrowe
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/signatures",
        summary="Verify PDF digital signatures",
        description="Get and verify digital signatures in a PDF document",
    )
    async def pdf_signatures(
        self,
        document_id: str,
    ) -> Response:
        """Verify PDF digital signatures.

        PDFium natywnie wspiera weryfikację podpisów cyfrowych -- nie wymaga
        zewnętrznych bibliotek kryptograficznych.

        Returns:
            JSON z listą podpisów i ich statusem weryfikacji.
        """
        pdf_path = _resolve_document_path(document_id)

        signatures = await anyio.to_thread.run_sync(
            verify_pdf_signatures,
            pdf_path,
        )

        return Response(
            content=msgspec.json.encode(
                {
                    "document_id": document_id,
                    "signature_count": len(signatures),
                    "signatures": [
                        {
                            "author": sig.author,
                            "reason": sig.reason,
                            "location": sig.location,
                            "is_verified": sig.is_verified,
                            "signed_at": sig.signed_at,
                            "field_name": sig.field_name,
                            "page_num": sig.page_num,
                        }
                        for sig in signatures
                    ],
                    "engine": "PDFium (native)",
                }
            ),
            media_type="application/json",
        )

    # ═══════════════════════════════════════════════════════════════════════
    # FAZA 3: Formularze AcroForms
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/documents/{document_id:str}/form-fields",
        summary="Get PDF form fields",
        description="Get all AcroForm fields in a PDF document",
    )
    async def pdf_form_fields(
        self,
        document_id: str,
    ) -> Response:
        """Get PDF form fields.

        PDFium natywnie wspiera AcroForms przez pdf.get_form().
        Zwraca typy pól: text, checkbox, radio, listbox, combobox, signature.

        Returns:
            JSON z listą pól formularza.
        """
        pdf_path = _resolve_document_path(document_id)

        fields = await anyio.to_thread.run_sync(
            get_pdf_form_fields,
            pdf_path,
        )

        return Response(
            content=msgspec.json.encode(
                {
                    "document_id": document_id,
                    "field_count": len(fields),
                    "fields": [
                        {
                            "name": f.name,
                            "type": f.type,
                            "value": f.value,
                            "is_readonly": f.is_readonly,
                            "is_required": f.is_required,
                            "max_length": f.max_length,
                            "options": f.options,
                            "page_num": f.page_num,
                        }
                        for f in fields
                    ],
                    "engine": "PDFium (AcroForm)",
                }
            ),
            media_type="application/json",
        )

    @post(
        path="/api/v1/documents/{document_id:str}/form-fields/fill",
        summary="Fill PDF form fields",
        description="Fill one or more AcroForm fields in a PDF document",
    )
    async def pdf_fill_form(
        self,
        document_id: str,
        data: dict[str, str],
    ) -> Response:
        """Fill PDF form fields.

        Przyjmuje JSON z mapowaniem field_name -> value.
        Zwraca zmodyfikowany PDF jako bytes.

        Args:
            document_id: ID dokumentu.
            data: Słownik {field_name: value}.

        Returns:
            Response z zmodyfikowanym PDF jako application/pdf.
        """
        pdf_path = _resolve_document_path(document_id)

        pdf_bytes = await anyio.to_thread.run_sync(
            save_pdf_with_filled_fields,
            pdf_path,
            data,
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "X-PDF-Engine": "PDFium",
                "X-Fields-Filled": str(len(data)),
                "Content-Disposition": f'attachment; filename="filled_{Path(document_id).stem}.pdf"',
            },
        )

    # ═══════════════════════════════════════════════════════════════════════
    # Health check + statystyki cache'a
    # ═══════════════════════════════════════════════════════════════════════

    @get(
        path="/api/v1/health/pdfium",
        summary="PDFium health check",
        description="Check if pypdfium2 is properly installed and working",
    )
    async def pdfium_health(self) -> dict[str, Any]:
        """Health check dla silnika PDFium.

        Sprawdza czy pypdfium2 jest zainstalowane i działa.
        """
        from nexus_ai.services.pdfium import verify_pdfium_available, verify_pdfium_version

        available = verify_pdfium_available()
        version = verify_pdfium_version()

        return {
            "status": "ok" if available else "unavailable",
            "engine": "PDFium (Google Chrome)",
            "library": "pypdfium2",
            "version": version,
            "note": "Silnik Chrome, licencja BSD-3-Clause",
        }

    @get(
        path="/api/v1/health/pdfium/cache",
        summary="PDFium render cache stats",
        description="Get statistics of the PDF page render cache",
    )
    async def pdfium_cache_stats(self) -> dict[str, Any]:
        """Get PDFium render cache stats.

        Zwraca:
        - Rozmiar cache'a
        - Maksymalny rozmiar
        - TTL w sekundach
        - Liczba trafień i chybień
        - Hit ratio
        """
        cache = get_pdf_render_cache()
        return {
            "status": "ok",
            "engine": "PDFium",
            "cache": cache.stats,
        }

    @post(
        path="/api/v1/health/pdfium/cache/invalidate",
        summary="Invalidate PDF render cache",
        description="Invalidate the PDF page render cache (optionally for a specific document)",
    )
    async def pdfium_cache_invalidate(
        self,
        document_id: str | None = None,
    ) -> dict[str, Any]:
        """Invalidate PDF render cache.

        Args:
            document_id: Opcjonalnie -- unieważnij tylko dla tego dokumentu.

        Returns:
            JSON z potwierdzeniem unieważnienia.
        """
        cache = get_pdf_render_cache()
        if document_id:
            pdf_path = _resolve_document_path(document_id)
            cache.invalidate(pdf_path)
            return {
                "status": "ok",
                "action": "invalidate",
                "document_id": document_id,
                "cache_size": len(cache._cache),
            }
        else:
            cache.invalidate()
            return {
                "status": "ok",
                "action": "invalidate_all",
                "cache_size": 0,
            }
