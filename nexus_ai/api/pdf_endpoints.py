"""
pdf_endpoints.py — Endpointy Litestar do renderowania i ekstrakcji PDF przez PDFium.

Zgodnie z audytem technologicznym:
- Renderowanie stron PDF do PNG/JPEG na żądanie — zero zapisu na dysk
- Streaming response przez Litestar + Granian
- Ekstrakcja tekstu i metadanych
- Integracja z msgspec dla szybkiej serializacji
- Wszystkie operacje CPU-bound przez anyio.to_thread.run_sync()

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
from litestar import Controller, get
from litestar.response import Response
from structlog import get_logger

from nexus_ai.core.pdfium import (
    get_pdf_info,
    render_page_to_png_bytes,
    extract_text_from_page,
    extract_text_ranges,
    detect_table_regions,
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

    tags = ["pdf"]

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

        SUPERMOC PDFium:
        - Renderowanie przez silnik Chrome — najwyższa jakość
        - Streaming response — zero zapisu na dysk
        - Cache przez Cache-Control: public
        - Obsługa rotacji i DPI

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

    @get(
        path="/api/v1/documents/{document_id:str}/info",
        summary="Get PDF document info",
        description="Get metadata, page count, and file info for a PDF document",
    )
    async def pdf_info(
        self,
        document_id: str,
    ) -> Response:
        """Pobierz metadane i informacje o dokumencie PDF.

        SUPERMOC:
        - Jedno wywołanie PDFium zwraca wszystko
        - Serializacja przez msgspec (10-100× szybciej niż json)
        - Zwraca: page_count, file_size, metadata, first_page_size
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
                extract_text_ranges, pdf_path, page_num,
            )
            return Response(
                content=msgspec.json.encode({
                    "page": page_num,
                    "text_ranges": ranges,
                    "engine": "PDFium",
                }),
                media_type="application/json",
            )

        text = await anyio.to_thread.run_sync(
            extract_text_from_page, pdf_path, page_num,
        )
        return Response(
            content=msgspec.json.encode({
                "page": page_num,
                "text": text,
                "engine": "PDFium",
            }),
            media_type="application/json",
        )

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

        SUPERMOC:
        - Szybsze niż OCR (ms vs sekundy)
        - Analizuje struktury kolumn bez zewnętrznych modeli
        - PDFium daje precyzyjne pozycje tekstu
        """
        pdf_path = _resolve_document_path(document_id)

        tables = await anyio.to_thread.run_sync(
            detect_table_regions, pdf_path, page_num,
        )

        return Response(
            content=msgspec.json.encode({
                "page": page_num,
                "tables": tables,
                "table_count": len(tables),
                "engine": "PDFium",
            }),
            media_type="application/json",
        )

    @get(
        path="/api/v1/health/pdfium",
        summary="PDFium health check",
        description="Check if pypdfium2 is properly installed and working",
    )
    async def pdfium_health(self) -> dict[str, Any]:
        """Health check dla silnika PDFium.

        Sprawdza czy pypdfium2 jest zainstalowane i działa.
        """
        from nexus_ai.core.pdfium import verify_pdfium_available, verify_pdfium_version

        available = verify_pdfium_available()
        version = verify_pdfium_version()

        return {
            "status": "ok" if available else "unavailable",
            "engine": "PDFium (Google Chrome)",
            "library": "pypdfium2",
            "version": version,
            "note": "Zastępuje PyMuPDF (fitz) — licencja BSD-3-Clause, silnik Chrome",
        }
