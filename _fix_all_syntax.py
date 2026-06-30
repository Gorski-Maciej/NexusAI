#!/usr/bin/env python3
"""Fix ALL remaining syntax errors in nexus_ai/ - comprehensive batch fix."""
import ast
import os
import re

fixed = 0
total_files = 0

def fix_file(path, old, new, desc=""):
    global fixed
    with open(path, 'r') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new, 1)
        with open(path, 'w') as f:
            f.write(content)
        fixed += 1
        print(f'  OK: {os.path.basename(path)} - {desc}')
        return True
    # Try case-insensitive or partial match for debugging
    if desc:
        pass  # skip verbose debugging
    return False

print("="*60)
print("FAZA 1: Fix bare text before docstrings in functions")
print("="*60)

# 1. api/pdf_endpoints.py - bare text in render_page_jpeg
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def render_page_jpeg(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 150,\n        rotation: int = 0,\n        quality: int = 85,\n    ) -> Response:\n\n        - JPEG z progressive=True dla lepszego UX w przegladarce\n        - Mniejszy rozmiar niz PNG (idealne dla fotografii i skanow)\n        - EXIF transpose dla PDF z embedded rotation\n\n        Args:',
    '    async def render_page_jpeg(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 150,\n        rotation: int = 0,\n        quality: int = 85,\n    ) -> Response:\n        """Render PDF page to JPEG.\n\n        - JPEG z progressive=True dla lepszego UX w przegladarce\n        - Mniejszy rozmiar niz PNG (idealne dla fotografii i skanow)\n        - EXIF transpose dla PDF z embedded rotation\n\n        Args:',
    "render_page_jpeg"
)

# 2. api/pdf_endpoints.py - bare text in render_page_enhanced
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def render_page_enhanced(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 300,\n        rotation: int = 0,\n    ) -> Response:\n\n        - ImageOps.autocontrast -- automatyczne zwiekszenie kontrastu\n        - ImageFilter.MedianFilter -- denoising (szumy skanera)\n        - ImageFilter.UnsharpMask -- wyostrzenie krawedzi znakow\n        - EXIF transpose -- korekcja orientacji\n        - Idealne dla OCR -- obraz gotowy do Tesseract/PaddleOCR\n\n        Args:',
    '    async def render_page_enhanced(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 300,\n        rotation: int = 0,\n    ) -> Response:\n        """Render enhanced PDF page with Pillow preprocessing.\n\n        - ImageOps.autocontrast -- automatyczne zwiekszenie kontrastu\n        - ImageFilter.MedianFilter -- denoising (szumy skanera)\n        - ImageFilter.UnsharpMask -- wyostrzenie krawedzi znakow\n        - EXIF transpose -- korekcja orientacji\n        - Idealne dla OCR -- obraz gotowy do Tesseract/PaddleOCR\n\n        Args:',
    "render_page_enhanced"
)

# 3. api/pdf_endpoints.py - bare text in render_all_pages
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def render_all_pages(\n        self,\n        document_id: str,\n        dpi: int = 150,\n        max_pages: int | None = None,\n        format: str = "PNG",\n    ) -> Response:\n\n        - Renderowanie wszystkich stron jednym wywolaniem\n        - Cache\'owanie z TTL -- powtorne wywolanie jest blyskawiczne\n        - Zwraca JSON z base64-encoded obrazami\n        - Idealne dla batch OCR i generowania miniaturek\n\n        Args:',
    '    async def render_all_pages(\n        self,\n        document_id: str,\n        dpi: int = 150,\n        max_pages: int | None = None,\n        format: str = "PNG",\n    ) -> Response:\n        """Render all pages as PNG/JPEG images.\n\n        - Renderowanie wszystkich stron jednym wywolaniem\n        - Cache\'owanie z TTL -- powtorne wywolanie jest blyskawiczne\n        - Zwraca JSON z base64-encoded obrazami\n        - Idealne dla batch OCR i generowania miniaturek\n\n        Args:',
    "render_all_pages"
)

# 4. api/pdf_endpoints.py - bare text in pdf_signatures
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def pdf_signatures(\n        self,\n        document_id: str,\n    ) -> Response:\n\n        PDFium natywnie wspiera weryfikacje podpisow cyfrowych -- nie wymaga\n        zewnetrznych bibliotek kryptograficznych.\n\n        Returns:',
    '    async def pdf_signatures(\n        self,\n        document_id: str,\n    ) -> Response:\n        """Verify PDF digital signatures.\n\n        PDFium natywnie wspiera weryfikacje podpisow cyfrowych -- nie wymaga\n        zewnetrznych bibliotek kryptograficznych.\n\n        Returns:',
    "pdf_signatures"
)

# 5. api/pdf_endpoints.py - bare text in pdf_form_fields
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def pdf_form_fields(\n        self,\n        document_id: str,\n    ) -> Response:\n\n        PDFium natywnie wspiera AcroForms przez pdf.get_form().\n        Zwraca typy pol: text, checkbox, radio, listbox, combobox, signature.\n\n        Returns:',
    '    async def pdf_form_fields(\n        self,\n        document_id: str,\n    ) -> Response:\n        """Get PDF form fields.\n\n        PDFium natywnie wspiera AcroForms przez pdf.get_form().\n        Zwraca typy pol: text, checkbox, radio, listbox, combobox, signature.\n\n        Returns:',
    "pdf_form_fields"
)

# 6. api/pdf_endpoints.py - bare text in pdf_fill_form
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def pdf_fill_form(\n        self,\n        document_id: str,\n        data: dict[str, str],\n    ) -> Response:\n\n        Przyjmuje JSON z mapowaniem field_name -> value.\n        Zwraca zmodyfikowany PDF jako bytes.\n\n        Args:',
    '    async def pdf_fill_form(\n        self,\n        document_id: str,\n        data: dict[str, str],\n    ) -> Response:\n        """Fill PDF form fields.\n\n        Przyjmuje JSON z mapowaniem field_name -> value.\n        Zwraca zmodyfikowany PDF jako bytes.\n\n        Args:',
    "pdf_fill_form"
)

# 7. api/pdf_endpoints.py - bare text in pdfium_cache_stats
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def pdfium_cache_stats(self) -> dict[str, Any]:\n\n        Zwraca:\n        - Rozmiar cache\'a\n        - Maksymalny rozmiar\n        - TTL w sekundach\n        - Liczba trafien i chybien\n        - Hit ratio\n        """',
    '    async def pdfium_cache_stats(self) -> dict[str, Any]:\n        """Get PDFium render cache stats.\n\n        Zwraca:\n        - Rozmiar cache\'a\n        - Maksymalny rozmiar\n        - TTL w sekundach\n        - Liczba trafien i chybien\n        - Hit ratio\n        """',
    "pdfium_cache_stats"
)

# 8. api/pdf_endpoints.py - bare text in pdfium_cache_invalidate
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '    async def pdfium_cache_invalidate(\n        self,\n        document_id: str | None = None,\n    ) -> dict[str, Any]:\n\n        Args:\n            document_id: Opcjonalnie -- uniewaznij tylko dla tego dokumentu.\n\n        Returns:\n            JSON z potwierdzeniem uniewaznienia.\n        """',
    '    async def pdfium_cache_invalidate(\n        self,\n        document_id: str | None = None,\n    ) -> dict[str, Any]:\n        """Invalidate PDFium render cache.\n\n        Args:\n            document_id: Opcjonalnie -- uniewaznij tylko dla tego dokumentu.\n\n        Returns:\n            JSON z potwierdzeniem uniewaznienia.\n        """',
    "pdfium_cache_invalidate"
)

print("\n" + "="*60)
print("FAZA 2: Fix other syntax errors")
print("="*60)

# 9. api/schemas.py - LocustSummaryResponse bare text
fix_file(
    'nexus_ai/api/schemas.py',
    'class LocustSummaryResponse(msgspec.Struct, kw_only=True):\n\n    Zgodnie z aa3fvcx.txt:',
    'class LocustSummaryResponse(msgspec.Struct, kw_only=True):\n    """\n    Zgodnie z aa3fvcx.txt:',
    "LocustSummaryResponse"
)

# 10. core/analytics.py - collect_with_streaming bare text
fix_file(
    'nexus_ai/core/analytics.py',
    'def collect_with_streaming(lazy: pl.LazyFrame, streaming: bool = True) -> pl.DataFrame:\n\n    ``collect(streaming=True)`` wykonuje zapytanie w batchach,',
    'def collect_with_streaming(lazy: pl.LazyFrame, streaming: bool = True) -> pl.DataFrame:\n    """Collect LazyFrame with optional streaming.\n\n    ``collect(streaming=True)`` wykonuje zapytanie w batchach,',
    "collect_with_streaming"
)

# 11. core/analytics.py - > 1M
fix_file(
    'nexus_ai/core/analytics.py',
    '> 1M wierszy',
    'wiecej niz 1M wierszy',
    "'> 1M'"
)

# 12. core/time_utils.py - leading zeros
fix_file(
    'nexus_ai/core/time_utils.py',
    '(domyslnie 2026-06-16).',
    '(domyslnie 2026-06-16).  # noqa: E501',
    "leading zeros"
)

# 13. services/otel_fallback.py - 80%
fix_file(
    'nexus_ai/services/otel_fallback.py',
    '80% mniej RAM.',
    '80 procent mniej RAM.',
    "'80%'"
)

# 14. services/vat_reconciliation.py - > 1M
fix_file(
    'nexus_ai/services/vat_reconciliation.py',
    'dla > 1M wierszy',
    'dla wiecej niz 1M wierszy',
    "'> 1M'"
)

# 15. core/forecaster.py - unterminated docstring
fix_file(
    'nexus_ai/core/forecaster.py',
    '    def _save_forecast_to_parquet(self, df: pl.DataFrame) -> str:\n        """Save forecast to Parquet using sink_parquet().\n\n        Uzywa ``sink_parquet()`` z Polars',
    '    def _save_forecast_to_parquet(self, df: pl.DataFrame) -> str:\n        """Save forecast to Parquet.\n\n        Uzywa ``sink_parquet()`` z Polars',
    "forecaster sink_parquet"
)

# 16. db/analytics.py - get_parquet_metadata bare text
fix_file(
    'nexus_ai/db/analytics.py',
    '    def get_parquet_metadata(self, parquet_path: str | Path) -> list[dict[str, Any]]:\n\n        ``parquet_metadata(\'file.parquet\')`` zwraca:',
    '    def get_parquet_metadata(self, parquet_path: str | Path) -> list[dict[str, Any]]:\n        """Get Parquet metadata.\\n\\n        ``parquet_metadata(\'file.parquet\')`` zwraca:',
    "get_parquet_metadata"
)

# 17. core/backup.py - prune_old_backups
fix_file(
    'nexus_ai/core/backup.py',
    '    def prune_old_backups(self, keep_days: int = 30) -> int:\n        """Remove backups older than keep_days and return deleted count.\\n\n        Args:',
    '    def prune_old_backups(self, keep_days: int = 30) -> int:\n        """Remove backups older than keep_days and return deleted count.\\n\n        Returns:',
    "prune_old_backups"
)

print(f"\n{'='*60}")
print(f"Total fixes applied: {fixed}")
print(f"{'='*60}")

# Count remaining
remaining = []
for root, dirs, files in os.walk('nexus_ai'):
    if '__pycache__' in root or 'rust' in root or 'target' in root:
        continue
    for f in files:
        if not f.endswith('.py'):
            continue
        path = os.path.join(root, f)
        try:
            with open(path, 'r') as fh:
                ast.parse(fh.read())
        except SyntaxError as e:
            remaining.append((path, e.lineno, str(e)[:60]))

print(f"Remaining syntax errors: {len(remaining)}")
for p, l, m in remaining[:15]:
    print(f"  {p}:{l}: {m}")
if len(remaining) > 15:
    print(f"  ... and {len(remaining)-15} more")
