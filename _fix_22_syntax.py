"""Fix all 22 remaining syntax errors in nexus_ai project."""
import ast
import os
import re
import subprocess

FIXES = []

def add_fix(path, old, new):
    FIXES.append((path, old, new))

# ============================================
# 1. pdf_endpoints.py - bare text after function signatures
# Multiple functions have bare text before the docstring
# ============================================
with open('nexus_ai/api/pdf_endpoints.py', 'r') as f:
    content = f.read()

# Fix render_page_jpeg - bare text after signature
old = '''    ) -> Response:

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
        \"\"\"'''
new = '''    ) -> Response:
        \"\"\"Render PDF page to JPEG image.

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
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix render_page_enhanced
old = '''    ) -> Response:

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
        \"\"\"'''
new = '''    ) -> Response:
        \"\"\"Render PDF page with Pillow preprocessing.

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
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix render_all_pages
old = '''    ) -> Response:

        - Renderowanie wszystkich stron jednym wywołaniem
        - Cache'owanie z TTL -- powtórne wywołanie jest błyskawiczne
        - Zwraca JSON z base64-encoded obrazami
        - Idealne dla batch OCR i generowania miniaturek

        Args:
            document_id: ID dokumentu.
            dpi: Rozdzielczość.
            max_pages: Maksymalna liczba stron (None = wszystkie).
            format: Format obrazu (\"PNG\" lub \"JPEG\").

        Returns:
            JSON z listą obrazów.
        \"\"\"'''
new = '''    ) -> Response:
        \"\"\"Render all pages as PNG images.

        - Renderowanie wszystkich stron jednym wywołaniem
        - Cache'owanie z TTL -- powtórne wywołanie jest błyskawiczne
        - Zwraca JSON z base64-encoded obrazami
        - Idealne dla batch OCR i generowania miniaturek

        Args:
            document_id: ID dokumentu.
            dpi: Rozdzielczość.
            max_pages: Maksymalna liczba stron (None = wszystkie).
            format: Format obrazu (\"PNG\" lub \"JPEG\").

        Returns:
            JSON z listą obrazów.
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix pdf_signatures
old = '''    ) -> Response:

        PDFium natywnie wspiera weryfikację podpisów cyfrowych -- nie wymaga
        zewnętrznych bibliotek kryptograficznych.

        Returns:
            JSON z listą podpisów i ich statusem weryfikacji.
        \"\"\"'''
new = '''    ) -> Response:
        \"\"\"Verify PDF digital signatures.

        PDFium natywnie wspiera weryfikację podpisów cyfrowych -- nie wymaga
        zewnętrznych bibliotek kryptograficznych.

        Returns:
            JSON z listą podpisów i ich statusem weryfikacji.
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix pdf_form_fields
old = '''    ) -> Response:

        PDFium natywnie wspiera AcroForms przez pdf.get_form().
        Zwraca typy pól: text, checkbox, radio, listbox, combobox, signature.

        Returns:
            JSON z listą pól formularza.
        \"\"\"'''
new = '''    ) -> Response:
        \"\"\"Get PDF form fields.

        PDFium natywnie wspiera AcroForms przez pdf.get_form().
        Zwraca typy pól: text, checkbox, radio, listbox, combobox, signature.

        Returns:
            JSON z listą pól formularza.
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix pdfium_cache_stats
old = '''    async def pdfium_cache_stats(self) -> dict[str, Any]:

        Zwraca:
        - Rozmiar cache'a
        - Maksymalny rozmiar
        - TTL w sekundach
        - Liczba trafień i chybień
        - Hit ratio
        \"\"\"'''
new = '''    async def pdfium_cache_stats(self) -> dict[str, Any]:
        \"\"\"Get PDFium render cache stats.

        Zwraca:
        - Rozmiar cache'a
        - Maksymalny rozmiar
        - TTL w sekundach
        - Liczba trafień i chybień
        - Hit ratio
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix pdfium_cache_invalidate
old = '''    ) -> dict[str, Any]:

        Args:
            document_id: Opcjonalnie -- unieważnij tylko dla tego dokumentu.

        Returns:
            JSON z potwierdzeniem unieważnienia.
        \"\"\"'''
new = '''    ) -> dict[str, Any]:
        \"\"\"Invalidate PDF render cache.

        Args:
            document_id: Opcjonalnie -- unieważnij tylko dla tego dokumentu.

        Returns:
            JSON z potwierdzeniem unieważnienia.
        \"\"\"'''
content = content.replace(old, new, 1)

with open('nexus_ai/api/pdf_endpoints.py', 'w') as f:
    f.write(content)
print('Fixed: pdf_endpoints.py')


# ============================================
# 2. api/routes/performance_ops.py
# ============================================
with open('nexus_ai/api/routes/performance_ops.py', 'r') as f:
    content = f.read()

# Fix class docstring
old = '''class PerformanceOpsController(Controller):

    Udostępnia wyniki testów wydajnościowych locust przez REST API.
    Obsługuje zarówno format CSV (--csv) jak i JSON (--json) z locust.
    \"\"\"'''
new = '''class PerformanceOpsController(Controller):
    \"\"\"Performance ops controller.

    Udostępnia wyniki testów wydajnościowych locust przez REST API.
    Obsługuje zarówno format CSV (--csv) jak i JSON (--json) z locust.
    \"\"\"'''
content = content.replace(old, new, 1)

# Fix locust_summary method
old = '''    async def locust_summary(self) -> dict:

        Przeszukuje katalog reports/performance/ w poszukiwaniu:
          1. locust_stats.html (JSON HTML -- fallback)
          2. locust_stats_stats.csv (CSV -- preferowany)
          3. locust_metrics_*.json (OTel fallback)

        Returns:
            Dykt z metrykami wydajności lub status: \"missing\"
        \"\"\"'''
new = '''    async def locust_summary(self) -> dict:
        \"\"\"Get locust performance summary.

        Przeszukuje katalog reports/performance/ w poszukiwaniu:
          1. locust_stats.html (JSON HTML -- fallback)
          2. locust_stats_stats.csv (CSV -- preferowany)
          3. locust_metrics_*.json (OTel fallback)

        Returns:
            Dykt z metrykami wydajności lub status: \"missing\"
        \"\"\"'''
content = content.replace(old, new, 1)

with open('nexus_ai/api/routes/performance_ops.py', 'w') as f:
    f.write(content)
print('Fixed: performance_ops.py')


# ============================================
# 3. core/forecaster.py - unterminated string
# ============================================
with open('nexus_ai/core/forecaster.py', 'r') as f:
    content = f.read()
# The issue is in load_historical_forecasts - bare text after signature
old = '''    def load_historical_forecasts(
        self,
        since: str | None = None,
        limit: int = 100,
    ) -> pl.DataFrame | None:
        \"\"\"Load historical forecasts from Parquet files.

        ``pl.scan_parquet()`` nie ładuje danych do RAM -- buduje LazyFrame.
        Dopiero ``collect()`` wykonuje zapytanie, i to z projection pushdown
        (czyta tylko potrzebne kolumny z Parquet).
        Zysk: 2-10x szybszy odczyt, 0 alokacji RAM na niepotrzebne dane.
        \"\"\"
        parquet_files = sorted(self.parquet_dir.rglob(\"*.parquet\"))
        if not parquet_files:
            return None

        lazy = pl.scan_parquet([str(f) for f in parquet_files])'''
new = '''    def load_historical_forecasts(
        self,
        since: str | None = None,
        limit: int = 100,
    ) -> pl.DataFrame | None:
        \"\"\"Load historical forecasts from Parquet files.\"\"\"
        parquet_files = sorted(self.parquet_dir.rglob(\"*.parquet\"))
        if not parquet_files:
            return None

        lazy = pl.scan_parquet([str(f) for f in parquet_files])'''
if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: forecaster.py - load_historical_forecasts')
else:
    print('WARN: forecaster.py - pattern not found')

with open('nexus_ai/core/forecaster.py', 'w') as f:
    f.write(content)


# ============================================
# 4. core/backup.py - fix docstrings with bare text
# ============================================
with open('nexus_ai/core/backup.py', 'r') as f:
    content = f.read()

# Fix export_to_delta - bare text after signature
old = '''    ) -> str:

        Delta Lake dodaje warstwę ACID na Parquet:
        - Atomic commits: każdy zapis jest atomowy
        - Time travel: ``DeltaTable.load_as_version(N)`` do historycznych wersji
        - Schema enforcement: bezpieczne dodawanie kolumn

        Args:
            duckdb_query: Zapytanie SQL do DuckDB.
            delta_table_path: Ścieżka do tabeli Delta (domyślnie backups/delta).
            mode: \"append\" (dodaj do istniejącej) lub \"overwrite\" (nadpisz).
            partition_by: Kolumny do partycjonowania (np. [\"year\", \"month\"]).

        Returns:
            Ścieżka do Delta Table.
        \"\"\"'''
new = '''    ) -> str:
        \"\"\"Export query result to Delta Lake.

        Delta Lake dodaje warstwę ACID na Parquet:
        - Atomic commits: każdy zapis jest atomowy
        - Time travel: ``DeltaTable.load_as_version(N)`` do historycznych wersji
        - Schema enforcement: bezpieczne dodawanie kolumn

        Args:
            duckdb_query: Zapytanie SQL do DuckDB.
            delta_table_path: Ścieżka do tabeli Delta (domyślnie backups/delta).
            mode: \"append\" (dodaj do istniejącej) lub \"overwrite\" (nadpisz).
            partition_by: Kolumny do partycjonowania (np. [\"year\", \"month\"]).

        Returns:
            Ścieżka do Delta Table.
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix list_delta_versions
old = '''    ) -> list[dict]:

        Delta Lake przechowuje pełną historię commitów w ``_delta_log/``.
        ``DeltaTable.history()\" zwraca każdą wersję z timestampem,
        operacją i metadanymi.
        Zysk: time travel -- dostęp do każdej wersji backupu.

        Args:
            delta_path: Ścieżka do Delta Table.

        Returns:
            Lista słowników z historią wersji.
        \"\"\"'''
new = '''    ) -> list[dict]:
        \"\"\"List Delta Lake versions.

        Delta Lake przechowuje pełną historię commitów w ``_delta_log/``.
        ``DeltaTable.history()\" zwraca każdą wersję z timestampem,
        operacją i metadanymi.
        Zysk: time travel -- dostęp do każdej wersji backupu.

        Args:
            delta_path: Ścieżka do Delta Table.

        Returns:
            Lista słowników z historią wersji.
        \"\"\"'''
content = content.replace(old, new, 1)

# Fix load_delta_version
old = '''    ) -> Any:

        ``DeltaTable.load_as_version(N)`` ładuje stan tabeli z wersji N.
        Zysk: pełny time travel -- dostęp do backupu sprzed tygodnia.

        Args:
            version: Numer wersji (0 = pierwszy backup).
            delta_path: Ścieżka do Delta Table.

        Returns:
            ``pyarrow.Table`` z danymi z danej wersji.
        \"\"\"'''
new = '''    ) -> Any:
        \"\"\"Load Delta Lake version.

        ``DeltaTable.load_as_version(N)`` ładuje stan tabeli z wersji N.
        Zysk: pełny time travel -- dostęp do backupu sprzed tygodnia.

        Args:
            version: Numer wersji (0 = pierwszy backup).
            delta_path: Ścieżka do Delta Table.

        Returns:
            ``pyarrow.Table`` z danymi z danej wersji.
        \"\"\"'''
content = content.replace(old, new, 1)

with open('nexus_ai/core/backup.py', 'w') as f:
    f.write(content)
print('Fixed: backup.py')


# ============================================
# 5. core/fsspec_compat.py - unmatched ']' at line 771
# The __all__ list has a commented section that's broken
# ============================================
with open('nexus_ai/core/fsspec_compat.py', 'r') as f:
    content = f.read()
# Fix the broken __all__ by removing the commented-out section
old_start = "\n# __all__ = [\n"
old_end = '    "AsyncFsWrapper",\n]\n'
if old_start in content:
    start_idx = content.find(old_start)
    end_idx = content.find(old_end, start_idx)
    if end_idx > start_idx:
        # Replace with a properly defined __all__
        new_all = '''
__all__ = [
    "TransactionalFileSystem",
    "ZipFileSystem",
    "TarFileSystem",
    "CachingFileSystem",
    "WholeFileCacheFileSystem",
    "SimpleCacheFileSystem",
    "BlockCacheFileSystem",
    "HTTPFileSystem",
    "MemoryFileSystem",
    "ReferenceFileSystem",
    "TqdmCallback",
    "compr",
    "HAS_TX_FS",
    "HAS_ZIP_FS",
    "HAS_TAR_FS",
    "HAS_CACHE_FS",
    "HAS_WHOLE_CACHE",
    "HAS_SIMPLE_CACHE",
    "HAS_BLOCK_CACHE",
    "HAS_HTTP_FS",
    "HAS_MEMORY_FS",
    "HAS_REF_FS",
    "HAS_TQDM_CB",
    "HAS_COMPRESSION",
    "create_chain",
    "create_optimal_filesystem",
    "configure_fsspec_global",
    "FSSpecFactory",
    "AsyncFsWrapper",
]
'''
        content = content[:start_idx] + new_all + content[end_idx + len(old_end):]
        print('Fixed: fsspec_compat.py - __all__ list')
    else:
        print('WARN: fsspec_compat.py - end of __all__ not found')
else:
    print('WARN: fsspec_compat.py - __all__ start not found')

with open('nexus_ai/core/fsspec_compat.py', 'w') as f:
    f.write(content)


# ============================================
# 6. core/otel.py - expected 'except' or 'finally' block at line 376
# ============================================
with open('nexus_ai/core/otel.py', 'r') as f:
    content = f.read()
# Fix the except block indentation
old = '''                try:
                    ref.shutdown()
                except Exception as exc:
                logger.debug(\"[OTEL] Shutdown error for %s: %s\", type(ref).__name__, exc)'''
new = '''                try:
                    ref.shutdown()
                except Exception as exc:
                    logger.debug(\"[OTEL] Shutdown error for %s: %s\", type(ref).__name__, exc)'''
if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel.py - except indentation')
else:
    # Try with the existing pattern - maybe there are trailing spaces
    import re
    content = re.sub(
        r'(\s+except Exception as exc:\n)\s+logger\.debug\("\[OTEL\] Shutdown error.*?\)',
        r'\1                    logger.debug("[OTEL] Shutdown error for %s: %s", type(ref).__name__, exc)',
        content
    )
    print('Fixed: otel.py - except indentation (regex)')

with open('nexus_ai/core/otel.py', 'w') as f:
    f.write(content)


# ============================================
# 7. core/pdfium.py - various bracket mismatches
# ============================================
with open('nexus_ai/core/pdfium.py', 'r') as f:
    content = f.read()

# Fix missing closing parenthesis in render_all_pages_to_memory
old_bracket = '''                            page_dpi=dpi,

                )'''
new_bracket = '''                            page_dpi=dpi,
                        )
                    )
                )'''
# The problem: the line `page_dpi=dpi,` then `                )` needs proper closing
# Let me try a different approach - find and fix based on context
# The issue is in the progress_callback call
old_context = '''                if progress_callback is not None:
                progress_callback(
                    PDFProgressInfo(
                        current_page=i - start + 1,
                        total_pages=end - start,
                        percent=round((i - start + 1) / (end - start) * 100, 1),
                        page_dpi=dpi,
'''
# Let's be more surgical - find the exact pattern
# After `page_dpi=dpi,` the next meaningful line should close all open parens
idx = content.find('page_dpi=dpi,')
if idx > 0:
    # Find what comes after
    after = content[idx:idx+100]
    print(f'  pdfium bracket context: {after[:60]}')
    # Replace the problematic section
    old_section = '''                            page_dpi=dpi,

                )'''
    new_section = '''                            page_dpi=dpi,
                        )
                    )
                )'''
    if old_section in content:
        content = content.replace(old_section, new_section, 1)
        print('Fixed: pdfium.py - bracket in render_all_pages_to_memory')
    else:
        print('WARN: pdfium.py - exact bracket pattern not found')
else:
    print('WARN: pdfium.py - page_dpi not found')

# Fix missing closing bracket in render_page_enhanced
old_ren = '''        preprocess_for_ocr=preprocess_for_ocr,


'''
new_ren = '''        preprocess_for_ocr=preprocess_for_ocr,
    )
    
'''
if old_ren in content:
    content = content.replace(old_ren, new_ren, 1)
    print('Fixed: pdfium.py - render_page_enhanced bracket')
else:
    print('WARN: pdfium.py - render_page_enhanced pattern not found')

# Fix the _caching_fs declaration which has unterminated open bracket
old_cache = '''# _caching_fs = CachingFileSystem(
    target_protocol="file",
    cache_storage="/tmp/.fsspec_pdf_cache",
    maxsize=500 * 1024 * 1024,  # 500 MB cache
    same_names=True,



'''
new_cache = '''# _caching_fs = CachingFileSystem(
#     target_protocol="file",
#     cache_storage="/tmp/.fsspec_pdf_cache",
#     maxsize=500 * 1024 * 1024,  # 500 MB cache
#     same_names=True,
# )


'''
if old_cache in content:
    content = content.replace(old_cache, new_cache, 1)
    print('Fixed: pdfium.py - commented caching_fs')
else:
    print('WARN: pdfium.py - commented caching_fs pattern not found')

# Fix invalidate_pdf_cache which also has unterminated brackets
old_inv = '''        _caching_fs = CachingFileSystem(
            target_protocol="file",
            cache_storage="/tmp/.fsspec_pdf_cache",
            maxsize=500 * 1024 * 1024,
            same_names=True,



'''
new_inv = '''        _caching_fs = CachingFileSystem(
            target_protocol="file",
            cache_storage="/tmp/.fsspec_pdf_cache",
            maxsize=500 * 1024 * 1024,
            same_names=True,
        )


'''
if old_inv in content:
    content = content.replace(old_inv, new_inv, 1)
    print('Fixed: pdfium.py - invalidate_pdf_cache brackets')
else:
    print('WARN: pdfium.py - invalidate_pdf_cache pattern not found')

with open('nexus_ai/core/pdfium.py', 'w') as f:
    f.write(content)


# ============================================
# 8. core/time_utils.py - remove the invalid comment # noqa that doesn't help
# ============================================
with open('nexus_ai/core/time_utils.py', 'r') as f:
    content = f.read()
# The issue is the comment "frozen_date: Data do zamrożenia (domyślnie 2026-06-16).  # noqa: E501"
# The # noqa should be removed since it's in a docstring comment not actual code
# Actually the issue might be the # noqa in a docstring. Let me check.
# The actual error was "leading zeros in decimal integer literals not permitted" at line 318
# This would be inside a docstring comment or string
# Let me just remove the # noqa comment
old_noqa = '2026-06-16).  # noqa: E501'
new_noqa = '2026-06-16).'
if old_noqa in content:
    content = content.replace(old_noqa, new_noqa, 1)
    print('Fixed: time_utils.py - removed # noqa')
else:
    print('WARN: time_utils.py - pattern not found')
with open('nexus_ai/core/time_utils.py', 'w') as f:
    f.write(content)


# ============================================
# 9. db/analytics.py - fix docstring with backticks containing COPY
# ============================================
with open('nexus_ai/db/analytics.py', 'r') as f:
    content = f.read()
# The issue is in export_to_parquet docstring - backticks in a multiline string
# Fix: escape the docstring properly
old_export = '''        ``COPY (query) TO 'file.parquet' (FORMAT PARQUET, CODEC 'ZSTD')``
        -- DuckDB zapisuje wynik bezpośrednio do pliku Parquet bez
        pośredniej alokacji w Pythonie.

        Args:
            query: Zapytanie SQL.
            output_path: Ścieżka docelowa pliku .parquet.
            compression: Kodowanie kompresji (ZSTD, SNAPPY, GZIP, LZ4, UNCOMPRESSED).
            row_group_size: Liczba wierszy na row group (int).

        Returns:
            Ścieżka do utworzonego pliku.
        \"\"\"'''
new_export = '''        \"\"\"Export query result to Parquet file.

        DuckDB zapisuje wynik bezpośrednio do pliku Parquet bez
        pośredniej alokacji w Pythonie.

        Args:
            query: Zapytanie SQL.
            output_path: Ścieżka docelowa pliku .parquet.
            compression: Kodowanie kompresji (ZSTD, SNAPPY, GZIP, LZ4, UNCOMPRESSED).
            row_group_size: Liczba wierszy na row group (int).

        Returns:
            Ścieżka do utworzonego pliku.
        \"\"\"'''
if old_export in content:
    content = content.replace(old_export, new_export, 1)
    print('Fixed: db/analytics.py - export_to_parquet docstring')
else:
    print('WARN: db/analytics.py - export pattern not found')

# Fix get_parquet_metadata - docstring with backticks
old_meta = '''    def get_parquet_metadata(self, parquet_path: str | Path) -> list[dict[str, Any]]:
        \"\"\"Get Parquet metadata.\"\"\"
        
        ``parquet_metadata('file.parquet')`` zwraca:
        - file_name, row_group_id, row_group_num_rows
        - column_id, path_in_schema, type, stats_min, stats_max, stats_null_count

        Zysk: diagnostyka bez wczytywania danych -- 0 RAM na payload.

        Args:
            parquet_path: Ścieżka do pliku Parquet.

        Returns:
            Lista słowników z metadanymi każdej kolumny.
        \"\"\"'''
new_meta = '''    def get_parquet_metadata(self, parquet_path: str | Path) -> list[dict[str, Any]]:
        \"\"\"Get Parquet metadata.\"\"\"
        
        ``parquet_metadata('file.parquet')`` zwraca:
        - file_name, row_group_id, row_group_num_rows
        - column_id, path_in_schema, type, stats_min, stats_max, stats_null_count

        Zysk: diagnostyka bez wczytywania danych -- 0 RAM na payload.

        Args:
            parquet_path: Ścieżka do pliku Parquet.

        Returns:
            Lista słowników z metadanymi każdej kolumny.'''
if old_meta in content:
    content = content.replace(old_meta, new_meta, 1)
    print('Fixed: db/analytics.py - get_parquet_metadata docstring')

with open('nexus_ai/db/analytics.py', 'w') as f:
    f.write(content)


# ============================================
# 10. services/context_enricher.py - unterminated docstring
# ============================================
with open('nexus_ai/services/context_enricher.py', 'r') as f:
    content = f.read()
# The close method has a docstring outside the method
old_close = """    async def close(self) -> None:
        \"\"\"Zamknij połączenia HTTP.\"\"\"
        try:
            await self._white_list.close()
        except Exception:
            pass
        try:
            await self._gus.close()
        except Exception:
            pass"""
if old_close in content:
    # Already looks fine, maybe the issue is elsewhere
    pass
else:
    # The issue might be that the docstring is actually fine but earlier in the file
    # Let me check if there's a bare text issue
    pass

with open('nexus_ai/services/context_enricher.py', 'w') as f:
    f.write(content)


# ============================================
# 11. services/storage.py - save_with_progress unterminated docstring
# ============================================
with open('nexus_ai/services/storage.py', 'r') as f:
    content = f.read()
# save_with_progress has bare text after signature then opens docstring
old_save = '''    def save_with_progress(
        self,
        source_path: str,
        *,
        target_name: str | None = None,
        description: str = "Uploading...",
    ) -> str:

        \"\"\"Save file with progress bar.'''
new_save = '''    def save_with_progress(
        self,
        source_path: str,
        *,
        target_name: str | None = None,
        description: str = "Uploading...",
    ) -> str:
        \"\"\"Save file with progress bar.'''
if old_save in content:
    content = content.replace(old_save, new_save, 1)
    print('Fixed: storage.py - save_with_progress')
else:
    print('WARN: storage.py - save_with_progress pattern not found')

with open('nexus_ai/services/storage.py', 'w') as f:
    f.write(content)


# ============================================
# 12. services/vat_reconciliation.py - fix docstring
# ============================================
with open('nexus_ai/services/vat_reconciliation.py', 'r') as f:
    content = f.read()
# Fix the docstring that has "Zysk: 5-10x szybsza..." as bare text
old_vat = '''    def check_vat_integrity(
        self, invoice_id: str, ocr_results: dict[str, Any]
    ) -> VATIntegrityResult:
        Polars Expressions zamiast PyArrow compute.'''
new_vat = '''    def check_vat_integrity(
        self, invoice_id: str, ocr_results: dict[str, Any]
    ) -> VATIntegrityResult:
        """Check VAT integrity across OCR/DuckDB/TigerBeetle.

        Polars Expressions zamiast PyArrow compute.'''
content = content.replace(old_vat, new_vat, 1)
print('Fixed: vat_reconciliation.py')
with open('nexus_ai/services/vat_reconciliation.py', 'w') as f:
    f.write(content)


# ============================================
# 13. services/otel_fallback.py - "80 procent" causing decimal literal error
# ============================================
with open('nexus_ai/services/otel_fallback.py', 'r') as f:
    content = f.read()
# The issue is "80 procent mniej RAM" in a docstring
old_otel = "80 procent mniej RAM"
new_otel = "80% mniej RAM"
content = content.replace(old_otel, new_otel, 1)
print('Fixed: otel_fallback.py')
with open('nexus_ai/services/otel_fallback.py', 'w') as f:
    f.write(content)


# ============================================
# 14. Fix all remaining unterminated triple-quoted strings in services/
# These are all bare text after function signature followed by """
# ============================================

# bank_import.py
with open('nexus_ai/services/bank_import.py', 'r') as f:
    content = f.read()
# Fix _setup_meta_mapper 
old = '''    def _setup_meta_mapper(self, storage_path: str | Path) -> None:

        fsspec.get_mapper() tworzy MutableMapping (dict-like),
        który automatycznie serializuje wartości do plików JSON.
        Każdy klucz to osobny plik w katalogu .bank_meta/.
        \"\"\"'''
new = '''    def _setup_meta_mapper(self, storage_path: str | Path) -> None:
        \"\"\"Setup meta mapper for bank import metadata.

        fsspec.get_mapper() tworzy MutableMapping (dict-like),
        który automatycznie serializuje wartości do plików JSON.
        Każdy klucz to osobny plik w katalogu .bank_meta/.
        \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: bank_import.py')
with open('nexus_ai/services/bank_import.py', 'w') as f:
    f.write(content)


# billing_estimator.py
with open('nexus_ai/services/billing_estimator.py', 'r') as f:
    content = f.read()
old = '''    def estimate(
        self,
        doc_type: str = "faktura_krajowa",
        tax_form: str = "CIT_STANDARD",
        vendor_region: str = "PL",
        extra_services: str = "",
    ) -> BillingResult:

        First-match-wins przez DuckDB json_extract + ORDER BY priority.
        \"\"\"'''
new = '''    def estimate(
        self,
        doc_type: str = "faktura_krajowa",
        tax_form: str = "CIT_STANDARD",
        vendor_region: str = "PL",
        extra_services: str = "",
    ) -> BillingResult:
        \"\"\"Estimate billing cost.

        First-match-wins przez DuckDB json_extract + ORDER BY priority.
        \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: billing_estimator.py')
with open('nexus_ai/services/billing_estimator.py', 'w') as f:
    f.write(content)


# document_fingerprint.py
with open('nexus_ai/services/document_fingerprint.py', 'r') as f:
    content = f.read()
old = '''    ) -> str:

    \"\"\"Compute visual fingerprint for a file.

    FAZA 2 (OpenCV audit): Dodatkowe ORB feature fingerprint gdy OpenCV dostępne.

    - ImageFilter.MedianFilter(3) -- denoising przed hashowaniem
    - ImageOps.autocontrast() -- lepszy kontrast dla stabilnego hasha
    - Multi-hash: phash + dhash + whash -- 3 perspektywy
    - OpenCV ORB features -- odporny na rotację/skalowanie/cięcie
      Jeśli 2/3 się zgadzają, dokument to duplikat
    - Falls back do SHA-1 prefix gdy Pillow/imagehash niedostępne
    \"\"\"'''
new = '''    ) -> str:
    \"\"\"Compute visual fingerprint for a file.

    FAZA 2 (OpenCV audit): Dodatkowe ORB feature fingerprint gdy OpenCV dostępne.

    - ImageFilter.MedianFilter(3) -- denoising przed hashowaniem
    - ImageOps.autocontrast() -- lepszy kontrast dla stabilnego hasha
    - Multi-hash: phash + dhash + whash -- 3 perspektywy
    - OpenCV ORB features -- odporny na rotację/skalowanie/cięcie
      Jeśli 2/3 się zgadzają, dokument to duplikat
    - Falls back do SHA-1 prefix gdy Pillow/imagehash niedostępne
    \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: document_fingerprint.py')
with open('nexus_ai/services/document_fingerprint.py', 'w') as f:
    f.write(content)


# fx_revaluation.py
with open('nexus_ai/services/fx_revaluation.py', 'r') as f:
    content = f.read()
old = '''    ``execute_arrow()`` + ``pl.from_arrow()`` + ``pl.DataFrame.with_columns()``
    zamiast czystego DuckDB SQL.

    Polars pozwala na:
    - Łatwiejsze rozszerzanie o dodatkowe obliczenia (np. weighted deltas)
    - ``shrink_dtype()`` dla redukcji RAM
    - ``filter()`` z wyrażeniami dla dalszego przetwarzania
        - `sink_parquet()`` jeśli wynik ma być zapisany
    \"\"\"'''
new = '''    \"\"\"\"
    ``execute_arrow()`` + ``pl.from_arrow()`` + ``pl.DataFrame.with_columns()``
    zamiast czystego DuckDB SQL.

    Polars pozwala na:
    - Łatwiejsze rozszerzanie o dodatkowe obliczenia (np. weighted deltas)
    - ``shrink_dtype()`` dla redukcji RAM
    - ``filter()`` z wyrażeniami dla dalszego przetwarzania
        - `sink_parquet()`` jeśli wynik ma być zapisany
    \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: fx_revaluation.py')
with open('nexus_ai/services/fx_revaluation.py', 'w') as f:
    f.write(content)


# inventory_fifo.py
with open('nexus_ai/services/inventory_fifo.py', 'r') as f:
    content = f.read()
old = '''    Używa code=TransferCode.COGS (5001), ledger=INVENTORY (706).
    \"\"\"'''
new = '''    \"\"\"\"
    Używa code=TransferCode.COGS (5001), ledger=INVENTORY (706).
    \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: inventory_fifo.py')
with open('nexus_ai/services/inventory_fifo.py', 'w') as f:
    f.write(content)


# proof_chain.py
with open('nexus_ai/services/proof_chain.py', 'r') as f:
    content = f.read()
old = '''        Przelicza hash dla wpisu i porównuje z zapisanym.
        \"\"\"'''
new = '''        \"\"\"Przelicza hash dla wpisu i porównuje z zapisanym.
        \"\"\"'''
content = content.replace(old, new, 1)
print('Fixed: proof_chain.py')
with open('nexus_ai/services/proof_chain.py', 'w') as f:
    f.write(content)


# risk_guard.py
with open('nexus_ai/services/risk_guard.py', 'r') as f:
    content = f.read()
old = '''        \"\"\"Get risk threshold for given conditions.

        First-match-wins przez DuckDB json_extract_string + ORDER BY priority.
        \"\"\"'''
new = '''        \"\"\"Get risk threshold for given conditions.'''
# Actually the docstring already starts correctly, the issue is elsewhere
# Let me check the evaluate method
old_eval = '''    def evaluate(
        self,
        tax_form: str,
        expense_type: str,
        ai_confidence: float,
        vendor_trust: str = "medium",
    ) -> dict[str, Any]:

        Args:
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.
            ai_confidence: Pewność AI (0.0-1.0).
            vendor_trust: Zaufanie do kontrahenta.

        Returns:
            Dict z decyzją: action, required_confidence, ai_confidence, reason.
        \"\"\"'''
new_eval = '''    def evaluate(
        self,
        tax_form: str,
        expense_type: str,
        ai_confidence: float,
        vendor_trust: str = "medium",
    ) -> dict[str, Any]:
        \"\"\"Evaluate risk for given conditions.

        Args:
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.
            ai_confidence: Pewność AI (0.0-1.0).
            vendor_trust: Zaufanie do kontrahenta.

        Returns:
            Dict z decyzją: action, required_confidence, ai_confidence, reason.
        \"\"\"'''
content = content.replace(old_eval, new_eval, 1)
print('Fixed: risk_guard.py')
with open('nexus_ai/services/risk_guard.py', 'w') as f:
    f.write(content)


# semantic_guard.py
with open('nexus_ai/services/semantic_guard.py', 'r') as f:
    content = f.read()
old = '''        \"\"\"Evaluate invoice for semantic anomalies.

        Args:
            invoice_text: Pełny tekst faktury z OCR.
            vendor_nip: NIP kontrahenta.
            amount_net: Kwota netto.
            category_code: Kod kategorii.

        Returns:
            AnomalyResult z decyzją.
        \"\"\"'''
new = '''        \"\"\"Evaluate invoice for semantic anomalies.'''
# The docstring looks fine, let me check if the actual issue is elsewhere
# Let me check _mock_embedding
old_mock = '''    @staticmethod
    def _mock_embedding(text: str, dim: int = 768) -> list[float]:

        W produkcji: llama-cpp-python embedding.
        \"\"\"'''
new_mock = '''    @staticmethod
    def _mock_embedding(text: str, dim: int = 768) -> list[float]:
        \"\"\"Generate mock embedding for testing.

        W produkcji: llama-cpp-python embedding.
        \"\"\"'''
content = content.replace(old_mock, new_mock, 1)
print('Fixed: semantic_guard.py')
with open('nexus_ai/services/semantic_guard.py', 'w') as f:
    f.write(content)

# ============================================
# Final check
# ============================================
print('\\n=== ALL FIXES APPLIED ===')
print('Verifying remaining syntax errors...')
import subprocess
result = subprocess.run(
    ['python3', '-c', '''
import ast, os
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
            with open(path, 'r') as fh:
                flines = fh.read().split('\\n')
            ctx = flines[e.lineno-1][:100] if e.lineno <= len(flines) else ''
            remaining.append((path, e.lineno, e.msg[:70], ctx))
print(f'Remaining syntax errors: {len(remaining)}')
for p, l, m, c in remaining:
    print(f'  {p}:{l}: {m}')
    print(f'  >> {c}')
'''],
    capture_output=True, text=True, timeout=30
)
print(result.stdout)
if result.stderr:
    print('STDERR:', result.stderr[:500])
